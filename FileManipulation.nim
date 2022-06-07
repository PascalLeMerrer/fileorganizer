import os
import terminal
import sequtils

var currentDir = getCurrentDir()

var directories : seq[string]
var files : seq[string]

for kind, path in walkDir(currentDir):
  case kind:
  of pcFile:
    files.add(path)
  of pcDir:
    directories.add(path)
  else:
    discard

for dirPath in directories:
  styledEcho fgGreen, styleBright, "Dir:  ", dirPath

for filePath in files:
  styledEcho fgBlue, "File: ", filePath
