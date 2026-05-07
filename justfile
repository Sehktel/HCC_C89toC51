set shell := ["powershell.exe", "-NoProfile", "-Command"]

default:
  @just --list

build:
  cabal build all

run:
  cabal run exe:hcc-c89toc51

test:
  cabal test all

test-component name:
  cabal test "test-{{name}}"

test-lexer:
  cabal test test-lexer

test-parser:
  cabal test test-parser

test-preprocessor:
  cabal test test-preprocessor

test-ast:
  cabal test test-ast

test-ir:
  cabal test test-ir

test-pipeline:
  cabal test test-pipeline

test-high-ir:
  cabal test test-high-ir

test-medium-ir:
  cabal test test-medium-ir

test-low-ir:
  cabal test test-low-ir

test-tree-destroyer:
  cabal test test-tree-destroyer

test-peephole:
  cabal test test-peephole

test-system-pipeline:
  cabal test test-system-pipeline

test-manifest:
  cabal test test-manifest-runner

test-manifest-file manifest:
  $env:TEST_MANIFEST="{{manifest}}"; cabal test test-manifest-runner

test-toolchain:
  cabal test test-preprocessor
  cabal test test-lexer
  cabal test test-parser
  cabal test test-ast
  cabal test test-high-ir
  cabal test test-medium-ir
  cabal test test-low-ir
  cabal test test-tree-destroyer
  cabal test test-peephole
  cabal test test-system-pipeline

test-web-report:
  New-Item -ItemType Directory -Force -Path artifacts | Out-Null
  $manifest = if ($env:TEST_MANIFEST) { $env:TEST_MANIFEST } else { "tests/test-manifest.json" }; $reportPath = (Get-Content $manifest -Raw | ConvertFrom-Json).reportPath; if (-not $reportPath) { $reportPath = "artifacts/test-report.html" }; cabal test test-web-report --test-options="--html=$reportPath"; if ($LASTEXITCODE -ne 0) { Write-Output "test-web-report finished with failing/pending tests. HTML report was still generated." }; Write-Output "Web report: $reportPath"

test-web-report-file manifest:
  $env:TEST_MANIFEST="{{manifest}}"; just test-web-report

open-report:
  $manifest = if ($env:TEST_MANIFEST) { $env:TEST_MANIFEST } else { "tests/test-manifest.json" }; $reportPath = (Get-Content $manifest -Raw | ConvertFrom-Json).reportPath; if (-not $reportPath) { $reportPath = "artifacts/test-report.html" }; if (-not (Test-Path $reportPath)) { just test-web-report }; if (Test-Path $reportPath) { Start-Process $reportPath } else { Write-Error "Failed to generate report: $reportPath" }

test-coverage:
  cabal test all --enable-coverage

test-coverage-report:
  cabal test all --enable-coverage
  @Write-Output "Coverage HTML reports are generated under dist-newstyle (hpc)."

docs:
  cabal haddock lib:hcc-c89toc51

makedoc: docs

install:
  cabal install exe:hcc-c89toc51 --installdir=bin --overwrite-policy=always

ci:
  cabal build all
  cabal test all
  cabal haddock lib:hcc-c89toc51
