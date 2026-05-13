-- | Минимальный уровневый логгер для фаз компилятора (препроцессор и далее).
--
-- Идея: один тип @Logger@ с порогом @loggerMin@; сообщения с уровнем ниже порога отбрасываются
-- без вызова @IO@ (кроме сравнения уровней).
module Logger
  ( LogLevel (..),
    Logger (..),
    silentLogger,
    stderrLogger,
    stderrLoggerWarn,
    stderrLoggerInfo,
    logMsg,
  )
where

import Control.Monad (when)
import System.IO (Handle, hFlush, hPutStrLn, stderr)

-- | Порядок важности: чем больше конструктор внизу списка, тем «серьёзнее» сообщение.
data LogLevel
  = LogDebug
  | LogInfo
  | LogWarn
  | LogError
  deriving (Eq, Ord, Show)

-- | @loggerMin@ — минимальный уровень, который ещё печатается; ниже — игнор.
-- @loggerEmit@ — фактическая доставка (stderr, файл, буфер для тестов и т.д.).
data Logger = Logger
  { loggerMin :: !LogLevel,
    loggerEmit :: !(LogLevel -> String -> IO ())
  }

-- | Ничего не пишет; подходит для @cabal test@ и библиотечного @defaultPreprocessConfig@.
silentLogger :: Logger
silentLogger = Logger LogError (\_ _ -> pure ())

-- | Печать на заданный поток с префиксом @[уровень]@; порог задаётся явно.
stderrLogger :: LogLevel -> Handle -> Logger
stderrLogger minLvl h = Logger minLvl emit
  where
    emit lvl msg =
      when (lvl >= minLvl) $ do
        hPutStrLn h $ "[" ++ show lvl ++ "] " ++ msg
        hFlush h

-- | Удобный вариант для CLI: stderr, порог @LogWarn@.
stderrLoggerWarn :: Logger
stderrLoggerWarn = stderrLogger LogWarn stderr

-- | CLI с более подробным выводом (включая открытые include на уровне Info).
stderrLoggerInfo :: Logger
stderrLoggerInfo = stderrLogger LogInfo stderr

-- | Отправить сообщение, если уровень не ниже порога логгера.
logMsg :: Logger -> LogLevel -> String -> IO ()
logMsg (Logger minLvl emit) lvl msg =
  when (lvl >= minLvl) $ emit lvl msg
