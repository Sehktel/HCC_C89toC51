Param(
  [switch]$SkipTests,
  [switch]$SkipDocs
)

$ErrorActionPreference = "Stop"

# Создаем ожидаемую структуру каталогов проекта.
New-Item -ItemType Directory -Path "bin" -Force | Out-Null
New-Item -ItemType Directory -Path "docs" -Force | Out-Null
New-Item -ItemType Directory -Path "tests" -Force | Out-Null

Write-Host "==> Сборка проекта"
cabal build all

Write-Host "==> Установка бинарника в ./bin"
cabal install exe:hcc-c89toc51 --installdir=bin --overwrite-policy=always

if (-not $SkipTests) {
  Write-Host "==> Запуск тестов"
  cabal test all
}

if (-not $SkipDocs) {
  Write-Host "==> Генерация документации в ./docs"
  cabal haddock all --haddock-option=--odir=docs
}

Write-Host "Готово: бинарники в ./bin, документация в ./docs"
