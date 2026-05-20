-- | Минимальный уровневый логгер для фаз компилятора (препроцессор и далее).
--
-- Две независимые «ручки»:
--
-- 1. __Глобальная__ (на старт тулчейна): порог @loggerMin@ в одном @Logger@, создаётся из конфига
--    (@stderrLoggerFor@, @silentLogger@) и передаётся в препроцессор / лексер / парсер.
-- 2. __На месте вызова__: уровень в @logMsg@ / @logMsgLazy@ (@LogDebug@, @LogWarn@, …) —
--    семантика сообщения; глобальный порог решает, дойдёт ли оно до вывода.
--
-- Пример: порог @LogWarn@ отсекает @LogDebug@ и @LogInfo@, но @logMsg lg LogWarn@ всё равно пишет warn.
-- Локально ослабить порог на один прогон: @loggerWithMin LogDebug pipelineLog@.
--
-- @logMsg@ — готовая строка; @logMsgLazy@ — сборка строки только если уровень прошёл порог.
module Logger
  ( LogLevel (..),
    Logger (..),
    silentLogger,
    stderrLogger,
    stderrLoggerFor,
    stderrLoggerWarn,
    stderrLoggerInfo,
    loggerWithMin,
    logMsg,
    logMsgLazy,
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

-- | Логгер на @stderr@ с порогом из глобальной настройки тулчейна (конфиг / CLI при старте).
stderrLoggerFor :: LogLevel -> Logger
stderrLoggerFor = flip stderrLogger stderr

-- | Тот же @loggerEmit@, другой порог — подкрутка болтливости «на месте» без смены доставки.
loggerWithMin :: LogLevel -> Logger -> Logger
loggerWithMin newMin (Logger _ emit) = Logger newMin emit

-- | Отправить сообщение, если уровень не ниже порога логгера (строка уже собрана).
logMsg :: Logger -> LogLevel -> String -> IO ()
logMsg (Logger minLvl emit) lvl msg =
  when (lvl >= minLvl) $ emit lvl msg

-- | Как 'logMsg', но @mk@ вызывается только при прохождении порога (удобно для @show@ в Debug).
logMsgLazy :: Logger -> LogLevel -> (() -> String) -> IO ()
logMsgLazy (Logger minLvl emit) lvl mk =
  when (lvl >= minLvl) $ emit lvl (mk ())
