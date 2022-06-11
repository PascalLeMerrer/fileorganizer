import os
import terminal
import strutils
import strformat
import fuzzy
import unicode

type
  Entries* = tuple[files, directories: seq[string]]

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

func containsLetters(text:string, lettersToSearch:string):bool =
  let lowercaseText = toLower(text)
  let lowercaseLettersToSearch = toLower(lettersToSearch)
  if lowercaseLettersToSearch.len == 0:
    return true

  let letterToSearch = $runeAtPos(lowercaseLettersToSearch, 0)
  let index = find(lowercaseText, letterToSearch)
  if index < 0:
    return false

  if lowercaseLettersToSearch.len > 1:
    let remainingLetters = runeSubStr(lowercaseLettersToSearch, 1)
    let remainingText = runeSubStr(lowercaseText, index + 1)
    return containsLetters(remainingText, remainingLetters)

  return true

func filter*(entries:Entries, lettersToSearch:string) : Entries =
  var filteredFiles : seq[string] = @[]
  var filteredDirectories : seq[string] = @[]

  for file in entries.files:
    if containsLetters(file, lettersToSearch):
      filteredFiles.add(file)

  for directory in entries.directories:
    if containsLetters(directory, lettersToSearch):
      filteredDirectories.add(directory)

  return (filteredFiles, filteredDirectories)

func formatIndex*(index:int): string =
  return fmt"{index: 4}"

proc display(entries:Entries) =
  styledEcho bgGreen, fgBlack, "- Directories -"

  for index, dirPath in entries.directories:
    styledEcho formatIndex(index + 1), " ", dirPath

  styledEcho bgBlue, fgWhite, "- Files -"

  for index, filePath in entries.files:
    styledEcho fgBlue, formatIndex(index + 1), " ", filePath


proc main() =
  let currentDir = getHomeDir()
  let entries = getDirectoryContent(currentDir)
  let filteredEntries = filter(entries, "è")
  display(filteredEntries)

when isMainModule:
  main()