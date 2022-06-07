import os
import terminal
import strutils

var currentDir = getCurrentDir()

var directories : seq[string]
var files : seq[string]

for kind, path in walkDir(currentDir):
  var filename = splitPath(path).tail
  if filename.startsWith('.'):
    continue

  case kind:
  of pcFile:
    files.add(filename)
  of pcDir:
    directories.add(filename)
  else:
    discard

for dirPath in directories:
  styledEcho fgGreen, styleBright, dirPath

for filePath in files:
  styledEcho fgBlue, filePath
