# Package

version       = "0.1.0"
author        = "Pascal Le Merrer"
description   = "A tool for organizing files quickly"
license       = "MIT"

srcDir = "src"

# Deps
requires "nim >= 1.6.6"

task test, "Run tests":
  exec "nim r --run tests/tfilemanipulation.nim"
  # exec "nim c --debuginfo --linedir:on --run tests/tfilemanipulation.nim"