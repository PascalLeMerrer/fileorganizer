import os
import strformat
import strutils
import std/terminal
import unicode
import unidecode
import std/exitprocs
import system

type
  Entry* = object
    name*: string
    path*: string
    selected*: bool

proc select*(entry: var Entry) =
  entry.selected = true

type
  Entries* = tuple[files, directories: seq[Entry]]

type View = enum
  Home, SourceSelection

let rightColumnX = int(terminalWidth() / 2)

type
  State = object
    view : View

var state = State(
    view: Home
  )

var sourceDirectory = getHomeDir()

proc clearScreen() =
    stdout.eraseScreen()
    stdout.setCursorPos(0,0)

proc getDirectoryContent(directoryPath:string, includeFiles:bool=true):Entries =
  var directories : seq[Entry]
  var files : seq[Entry]

  for kind, path in walkDir(directoryPath):
    let filename = splitPath(path).tail
    if filename.startsWith('.'):
      continue
    case kind:
    of pcFile:
      if includeFiles:
        let entry = Entry(
          path: path,
          name: filename,
          selected: false
        )
        files.add(entry)
    of pcDir:
      let entry = Entry(
        path: path,
        name: filename,
        selected: false
      )
      directories.add(entry)
    else:
      discard
  return (files, directories)

# Returns the list of directories in the current one, plus the link to the parent (..)
proc getSubDirectories(): seq[Entry] =
  var parentDirectory = Entry(
        path: "..",
        name: "..",
        selected: false
  )
  select(parentDirectory)
  result = @[parentDirectory]
  let subDirectories = getDirectoryContent(sourceDirectory, includeFiles=false).directories
  result.add(subDirectories)

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

proc filter*(entries:Entries, lettersToSearch:string) : Entries =
  var filteredFiles : seq[Entry] = @[]
  var filteredDirectories : seq[Entry] = @[]

  # ignore diacritics; For example, é and è and transformed to e
  let asciiLettersToSearch = unidecode(lettersToSearch)

  for entry in entries.files:
    let asciiFilename = unidecode(entry.name)
    if containsLetters(asciiFilename, asciiLettersToSearch):
      filteredFiles.add(entry)

  for entry in entries.directories:
    let asciiDirectoryName = unidecode(entry.name)
    if containsLetters(asciiDirectoryName, asciiLettersToSearch):
      filteredDirectories.add(entry)

  return (filteredFiles, filteredDirectories)

func formatIndex*(index:int): string =
  return fmt"{index: 4}"

proc display(entries:Entries) =
  styledEcho bgGreen, fgBlack, "- Directories -"

  for index, entry in entries.directories:
    styledEcho formatIndex(index + 1), " ", entry.name

  styledEcho bgBlue, fgWhite, "- Files -"

  for index, entry in entries.files:
    styledEcho fgBlue, formatIndex(index + 1), " ", entry.name

proc exit() =
      stdout.eraseScreen()
      echo "Good bye!\n"
      exitprocs.addExitProc(resetAttributes)
      system.quit()

proc selectSourceDirectory() =
  state.view = SourceSelection
  clearScreen()
  let directories = getSubDirectories()
  display((@[], directories))

proc main() =
  clearScreen()
  let entries = getDirectoryContent(sourceDirectory)
  let filteredEntries = filter(entries, "è")
  display(filteredEntries)

  stdout.setCursorPos(rightColumnX,0)
  echo "Destination"

  while true:
    let command = terminal.getch()
    case command

    of 's':
      selectSourceDirectory()
    of 'q':
      exit()

    else:
      discard


when isMainModule:

  main()

