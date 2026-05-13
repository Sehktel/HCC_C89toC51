-- | Упрощённый препроцессор C89: директивы, include, условная компиляция, объектные макросы.
--
-- Ограничения (намеренно, для первой итерации):
-- * только объектные @#define ИМЯ [тело]@ — функциональные @#define F(...)@ не поддерживаются;
-- * подстановка не затрагивает содержимое строковых и символьных литералов;
-- * нет @#if@ с выражениями, @defined@, строковой склейки и оператора @##@.
module Preprocessor
  ( PreprocessConfig (..),
    defaultPreprocessConfig,
    preprocess,
    replaceTrigraphs,
    LogLevel (..),
    Logger (..),
    silentLogger,
    stderrLogger,
    stderrLoggerWarn,
    stderrLoggerInfo,
    logMsg,
  )
where

import Control.Monad (when)
import Control.Monad.IO.Class (liftIO)
import Control.Monad.Trans.State.Strict (StateT, execStateT, get, modify)
import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import Data.Char (isAlpha, isAlphaNum, isSpace)
import Data.Foldable (traverse_)
import Data.List (dropWhileEnd, intercalate)
import Logger
  ( LogLevel (..),
    Logger (..),
    logMsg,
    silentLogger,
    stderrLogger,
    stderrLoggerInfo,
    stderrLoggerWarn,
  )
import System.Directory (canonicalizePath, doesFileExist)
import System.FilePath (normalise, takeDirectory, (</>))
import qualified System.IO.Error as IOErr

-- | Каталоги поиска: угловые скобки и дополнительные для кавычек (после каталога текущего файла).
-- По умолчанию @pcLogger = silentLogger@ — без шума в @cabal test@; в CLI задайте, например, @stderrLoggerInfo@.
data PreprocessConfig = PreprocessConfig
  { pcAngleIncludeDirs :: [FilePath],
    pcQuoteIncludeDirs :: [FilePath],
    pcLogger :: !Logger
  }

defaultPreprocessConfig :: PreprocessConfig
defaultPreprocessConfig =
  PreprocessConfig
    { pcAngleIncludeDirs = [],
      pcQuoteIncludeDirs = [],
      pcLogger = silentLogger
    }

-- | @preprocess cfg mbSourcePath src@ — развернуть исходник.
-- @mbSourcePath@: путь к «виртуальному» файлу (для @#include \"...\"@ относительно его каталога); @Nothing@ — только каталоги из конфигурации.
preprocess :: PreprocessConfig -> Maybe FilePath -> String -> IO String
preprocess cfg mbPath raw = do
  let input = replaceTrigraphs raw
      ls = logicalLines input
      st0 = initialState cfg mbPath
  st1 <- execStateT (traverse_ processLine ls) st0
  pure (finalizeOutput (stOut st1))

-- * Внутреннее состояние

data Frame = Frame
  { -- | Условие «тогда-ветка» при активном родителе: для #ifdef — макрос задан; для #ifndef — не задан.
    frameThen :: !Bool,
    frameElse :: !Bool
  }
  deriving (Eq, Show)

data PPState = PPState
  { stMacros :: !(Map.Map String String),
    stCond :: ![Frame],
    stConfig :: !PreprocessConfig,
    stCurrentDir :: !(Maybe FilePath),
    stIncludeStack :: ![FilePath],
    stOut :: ![String]
  }

initialState :: PreprocessConfig -> Maybe FilePath -> PPState
initialState cfg mbPath =
  PPState
    { stMacros = Map.empty,
      stCond = [],
      stConfig = cfg,
      stCurrentDir = takeDirectory <$> mbPath,
      stIncludeStack = [],
      stOut = []
    }

type PPM = StateT PPState IO

-- | Сообщение в лог препроцессора (см. @pcLogger@ в конфигурации).
ppLog :: LogLevel -> String -> PPM ()
ppLog lvl msg = do
  lg <- pcLogger . stConfig <$> get
  liftIO $ logMsg lg lvl msg

emitting :: [Frame] -> Bool
emitting = all $ \(Frame th el) -> if el then not th else th

appendOut :: String -> PPM ()
appendOut line = modify $ \s -> s {stOut = stOut s ++ [line]}

-- * Логические строки и триграфы

-- | Замена C89 trigraph-последовательностей до токенизации.
replaceTrigraphs :: String -> String
replaceTrigraphs [] = []
replaceTrigraphs ('?' : '?' : '=' : rest) = '#' : replaceTrigraphs rest
replaceTrigraphs ('?' : '?' : '(' : rest) = '[' : replaceTrigraphs rest
replaceTrigraphs ('?' : '?' : '/' : rest) = '\\' : replaceTrigraphs rest
replaceTrigraphs ('?' : '?' : ')' : rest) = ']' : replaceTrigraphs rest
replaceTrigraphs ('?' : '?' : '\'' : rest) = '^' : replaceTrigraphs rest
replaceTrigraphs ('?' : '?' : '<' : rest) = '{' : replaceTrigraphs rest
replaceTrigraphs ('?' : '?' : '!' : rest) = '|' : replaceTrigraphs rest
replaceTrigraphs ('?' : '?' : '>' : rest) = '}' : replaceTrigraphs rest
replaceTrigraphs ('?' : '?' : '-' : rest) = '~' : replaceTrigraphs rest
replaceTrigraphs (ch : rest) = ch : replaceTrigraphs rest

-- | Склейка строк по @\\@ перед переводом строки и разбиение на логические строки.
logicalLines :: String -> [String]
logicalLines = go . normNewlines
  where
    normNewlines ('\r' : '\n' : xs) = '\n' : normNewlines xs
    normNewlines ('\r' : xs) = '\n' : normNewlines xs
    normNewlines (x : xs) = x : normNewlines xs
    normNewlines [] = []

    go [] = []
    go s =
      case break (== '\n') s of
        (line, []) ->
          let (merged, _) = mergeContinuations line []
           in [merged]
        (line, _ : rest) ->
          let (merged, rest') = mergeContinuations line rest
           in merged : go rest'

    mergeContinuations acc rs = case stripTrailingCr acc of
      xs
        | Just ys <- stripLineContinuation xs -> case break (== '\n') rs of
            (more, []) -> mergeContinuations (ys ++ more) []
            (more, _ : r2) -> mergeContinuations (ys ++ more) r2
      xs -> (xs, rs)

    stripTrailingCr xs = case reverse xs of
      '\r' : r -> reverse r
      _ -> xs

    stripLineContinuation xs
      | "\\" `isSuffix` xs =
          Just (take (length xs - 1) xs)
      | otherwise = Nothing

    isSuffix suf s = length s >= length suf && drop (length s - length suf) s == suf

finalizeOutput :: [String] -> String
finalizeOutput =
  unlines
    . filter (not . null)
    . map trim
  where
    trim = dropWhileEnd isSpace . dropWhile isSpace

-- * Разбор и выполнение директив

processLine :: String -> PPM ()
processLine rawLine = do
  st <- get
  let l = dropWhile isSpace rawLine
  case l of
    '#' : rest ->
      handleDirective (dropWhile isSpace rest)
    _
      | emitting (stCond st) ->
          appendOut (expandMacros (stMacros st) l)
      | otherwise -> pure ()

handleDirective :: String -> PPM ()
handleDirective raw = do
  let (kw, afterKw) = spanIdentKeyword raw
      rest = dropWhile isSpace afterKw
  st <- get
  case kw of
    "define" -> when (emitting (stCond st)) $ handleDefine rest
    "include" -> when (emitting (stCond st)) $ handleInclude rest
    "ifdef" -> handleIfDef rest True
    "ifndef" -> handleIfDef rest False
    "else" -> handleElse
    "endif" -> handleEndif
    _ -> pure () -- неизвестные директивы игнорируем (в т.ч. #if — вне scope)

-- Ключевое слово директивы: буквы/цифры/подчёркивание; для include/define достаточно.
spanIdentKeyword :: String -> (String, String)
spanIdentKeyword s =
  case span isIdentCont s of
    (a, b) -> (a, b)

isIdentStart :: Char -> Bool
isIdentStart c = isAlpha c || c == '_'

isIdentCont :: Char -> Bool
isIdentCont c = isAlphaNum c || c == '_'

handleDefine :: String -> PPM ()
handleDefine rest = do
  let rest' = stripLineComment rest
  case dropWhile isSpace rest' of
    [] -> pure ()
    c : cs
      | not (isIdentStart c) ->
          pure ()
      | otherwise ->
          let (name, afterName) = span isIdentCont (c : cs)
           in if isJustParenMacro (dropWhile isSpace afterName)
                then pure ()
                else
                  let body = trimDefineBody (dropWhile isSpace afterName)
                   in modify $ \s -> s {stMacros = Map.insert name body (stMacros s)}
  where
    isJustParenMacro ('(' : _) = True
    isJustParenMacro _ = False

trimDefineBody :: String -> String
trimDefineBody = dropWhile isSpace

handleIfDef :: String -> Bool -> PPM ()
handleIfDef rest isIfdef = do
  st <- get
  let rest' = stripLineComment rest
  case dropWhile isSpace rest' of
    [] -> modify $ \s -> s {stCond = Frame False False : stCond s}
    c : cs
      | not (isIdentStart c) ->
          modify $ \s -> s {stCond = Frame False False : stCond s}
      | otherwise ->
          let name = takeWhile isIdentCont (c : cs)
              defined = Map.member name (stMacros st)
              intr = if isIfdef then defined else not defined
           in modify $ \s -> s {stCond = Frame intr False : stCond s}

handleElse :: PPM ()
handleElse = do
  st <- get
  case stCond st of
    [] -> pure ()
    f : fs ->
      modify $ \s -> s {stCond = f {frameElse = True} : fs}

handleEndif :: PPM ()
handleEndif = do
  st <- get
  case stCond st of
    [] -> pure ()
    _ : fs -> modify $ \s -> s {stCond = fs}

stripLineComment :: String -> String
stripLineComment [] = []
stripLineComment ('/' : '/' : _) = []
stripLineComment (c : cs) = c : stripLineComment cs

-- * #include

handleInclude :: String -> PPM ()
handleInclude rest = do
  let t = dropWhile isSpace (stripLineComment rest)
  case t of
    '"' : _ ->
      case readQuoted '"' t of
        Just path -> includeFrom path False
        Nothing -> do
          ppLog LogWarn "Preprocessor: некорректный #include \"...\""
          liftIO (IOErr.ioError (IOErr.userError "Preprocessor: broken #include \"...\""))
    '<' : _ ->
      case readAngle t of
        Just path -> includeFrom path True
        Nothing -> do
          ppLog LogWarn "Preprocessor: некорректный #include <...>"
          liftIO (IOErr.ioError (IOErr.userError "Preprocessor: broken #include <...>"))
    _ -> do
      ppLog LogWarn "Preprocessor: ожидался #include \"...\" или <...>"
      liftIO (IOErr.ioError (IOErr.userError "Preprocessor: expected #include \"...\" or <...>"))

readQuoted :: Char -> String -> Maybe FilePath
readQuoted _ [] = Nothing
readQuoted q (_ : xs) =
  case break (== q) xs of
    (name, _ : _) -> Just name
    _ -> Nothing

readAngle :: String -> Maybe FilePath
readAngle ('<' : xs) =
  case break (== '>') xs of
    (name, _ : _) -> Just name
    _ -> Nothing
readAngle _ = Nothing

includeFrom :: FilePath -> Bool -> PPM ()
includeFrom relPath angle = do
  st <- get
  let cfg = stConfig st
      prevDir = stCurrentDir st
      stack = stIncludeStack st
      tried = candidates cfg prevDir angle relPath
  mAbs <- liftIO (searchInclude cfg prevDir angle relPath)
  case mAbs of
    Nothing -> do
      let detail =
            "Preprocessor: include не найден: "
              ++ relPath
              ++ " (пробовали: "
              ++ intercalate ", " tried
              ++ ")"
      ppLog LogWarn detail
      liftIO . IOErr.ioError . IOErr.userError $ detail
    Just absPath -> do
      cycleHit <- liftIO (checkIncludeCycle stack absPath)
      if cycleHit
        then
          ppLog LogWarn $
            "Preprocessor: пропуск циклического include: "
              ++ absPath
        else do
          ppLog LogDebug $ "Preprocessor: открыт include: " ++ absPath
          content <- liftIO (readFile absPath)
          let inner = replaceTrigraphs content
              ls = logicalLines inner
          modify $ \s ->
            s
              { stIncludeStack = absPath : stIncludeStack s,
                stCurrentDir = Just (takeDirectory absPath)
              }
          traverse_ processLine ls
          modify $ \s ->
            s
              { stIncludeStack = stack,
                stCurrentDir = prevDir
              }

checkIncludeCycle :: [FilePath] -> FilePath -> IO Bool
checkIncludeCycle stack path = do
  cPath <- canonicalizePath path
  stackCs <- mapM tryCanon stack
  pure (cPath `elem` concat stackCs)
  where
    tryCanon p = do
      r <- IOErr.tryIOError (canonicalizePath p)
      case r of
        Left _ -> pure []
        Right q -> pure [q]

searchInclude :: PreprocessConfig -> Maybe FilePath -> Bool -> FilePath -> IO (Maybe FilePath)
searchInclude cfg mbCur angle rel = tryCandidates (candidates cfg mbCur angle rel)
  where
    tryCandidates [] = pure Nothing
    tryCandidates (p : ps) = do
      ex <- doesFileExist p
      if ex then pure (Just p) else tryCandidates ps

candidates :: PreprocessConfig -> Maybe FilePath -> Bool -> FilePath -> [FilePath]
candidates cfg mbCur angle rel =
  map normalise $
    if angle
      then [d </> rel | d <- pcAngleIncludeDirs cfg]
      else
        localFirst
          ++ [d </> rel | d <- pcQuoteIncludeDirs cfg]
          ++ [d </> rel | d <- pcAngleIncludeDirs cfg]
  where
    localFirst = case mbCur of
      Nothing -> []
      Just d -> [d </> rel]

-- * Подстановка макросов

expandMacros :: Map.Map String String -> String -> String
expandMacros m s = go Set.empty s
  where
    go :: Set.Set String -> String -> String
    go _ [] = []
    go dis (c : cs)
      | c == '"' =
          let (blk, rest) = readStringLit (c : cs)
           in blk ++ go dis rest
      | c == '\'' =
          let (blk, rest) = readCharLit (c : cs)
           in blk ++ go dis rest
      | isIdentStart c =
          let (name, rest) = span isIdentCont (c : cs)
           in case Map.lookup name m of
                Just body
                  | Set.notMember name dis ->
                      go (Set.insert name dis) body ++ go dis rest
                _ -> name ++ go dis rest
      | otherwise = c : go dis cs

readStringLit :: String -> (String, String)
readStringLit [] = ("", "")
readStringLit ('"' : xs) = goStr ('"' : []) xs
  where
    goStr acc [] = (reverse acc, "")
    goStr acc ('"' : ys) = (reverse ('"' : acc), ys)
    goStr acc ('\\' : y : ys) = goStr (y : '\\' : acc) ys
    goStr acc (y : ys) = goStr (y : acc) ys
readStringLit s = (take 1 s, drop 1 s)

readCharLit :: String -> (String, String)
readCharLit [] = ("", "")
readCharLit ('\'' : xs) = goCh ('\'' : []) xs
  where
    goCh acc [] = (reverse acc, "")
    goCh acc ('\'' : ys) = (reverse ('\'' : acc), ys)
    goCh acc ('\\' : y : ys) = goCh (y : '\\' : acc) ys
    goCh acc (y : ys) = goCh (y : acc) ys
readCharLit s = (take 1 s, drop 1 s)
