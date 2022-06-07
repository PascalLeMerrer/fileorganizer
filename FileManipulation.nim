import os
import terminal
import strutils
import strformat

var currentDir = getHomeDir()

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

proc formatIndex(index:int): string =
  return fmt"{index:03}"

styledEcho bgGreen, fgBlack, "- Directories -"

for index, dirPath in directories:
  styledEcho fgGreen, styleBright, formatIndex(index + 1), " ", dirPath


styledEcho bgBlue, fgWhite, "- Files -"

for index, filePath in files:
  styledEcho fgBlue, formatIndex(index + 1), " ", filePath
