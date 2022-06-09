import os
import terminal
import strutils
import strformat
import fuzzy

type
  Entries = tuple[files, directories: seq[string]]

proc getDirectoryContent(directoryPath:string):Entries =
  var directories : seq[string]
  var files : seq[string]

  for kind, path in walkDir(directoryPath):
    let filename = splitPath(path).tail
    if filename.startsWith('.'):
      continue

    case kind:
    of pcFile:
      files.add(filename)
    of pcDir:
      directories.add(filename)
    else:
      discard
  return (files, directories)

func filter(entries:Entries) : Entries =
  return entries

func formatIndex*(index:int): string =
  return fmt"{index: 4}"

proc display(entries:Entries) =
  styledEcho bgGreen, fgBlack, "- Directories -"

  for index, dirPath in entries.directories:
    let score = fuzzyMatchSmart("oo", dirPath)
    let fgColor = if score > 0.5: fgGreen else: fgDefault

    let formattedScore = fmt "{score}"
    styledEcho fgColor, styleBright, formatIndex(index + 1), " ", dirPath, " : ", formattedScore


  styledEcho bgBlue, fgWhite, "- Files -"

  for index, filePath in entries.files:
    styledEcho fgBlue, formatIndex(index + 1), " ", filePath


proc main() =
  let currentDir = getHomeDir()
  let entries = getDirectoryContent(currentDir)
  let filteredEntries = filter(entries)
  display(filteredEntries)

when isMainModule:
  main()