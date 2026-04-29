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

docs:
  cabal haddock lib:hcc-c89toc51

makedoc: docs

install:
  cabal install exe:hcc-c89toc51 --installdir=bin --overwrite-policy=always

ci:
  cabal build all
  cabal test all
  cabal haddock lib:hcc-c89toc51
