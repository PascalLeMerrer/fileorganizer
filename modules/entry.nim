import std/strformat
import std/strutils
import std/unicode
import std/unidecode
import illwill

const check = $Rune(0x2705)
const rightArrow = $Rune(0x2794)

type
  Entry* = object
    name*: string
    path*: string
    selected*: bool

type
  Entries* = tuple[files, directories: seq[Entry]]

proc select*(entry: var Entry) =
  entry.selected = true

proc unselect*(entry: var Entry) =
  entry.selected = false

func selectNext*(entries: seq[Entry]): seq[Entry] =
  result = @[]
  var nextEntryIsToBeSelected = false
  for entry in entries:
    if entry.selected:
      nextEntryIsToBeSelected = true
      let newEntry = Entry(name:entry.name, path:entry.path, selected:false)
      result.add(newEntry)
    else:
      if nextEntryIsToBeSelected:
        nextEntryIsToBeSelected = false
        let newEntry = Entry(name:entry.name, path:entry.path, selected:true)
        result.add(newEntry)
      else:
        result.add(entry)

func containsLetters(text:string, lettersToSearch:string):bool =
  let lowercaseText = toLower(text)
  let lowercaseLettersToSearch = toLower(lettersToSearch)
  if lowercaseLettersToSearch.len == 0:
    return true

  let letterToSearch = $runeAtPos(lowercaseLettersToSearch, 0)
  let index = strutils.find(lowercaseText, letterToSearch)
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

# TODO rename
proc formatIndex*(index:int, entry:Entry, width:int): string =
  # formatting string cannot be defined dynamically
  let strIndex = if entry.selected: rightArrow & $index else: " " & $index
  case width
  of 2:
    return fmt("{strIndex:>2}")
  of 3:
    return fmt("{strIndex:>3}")
  of 4:
    return fmt("{strIndex:>4}")
  of 5:
    return fmt("{strIndex:>5}")
  else:
    return  $index


proc render*(entries:Entries, tb: var TerminalBuffer, x: int) =

  var y  = 4
  tb.setBackgroundColor(BackgroundColor.bgGreen)
  tb.setForegroundColor(ForegroundColor.fgBlack)
  tb.write(x, y, "- Directories -")
  let directoriesCount = ($len(entries.directories)).len
  for index, entry in entries.directories:
    y = y + 1
    if entry.selected:
      tb.setBackgroundColor(BackgroundColor.bgBlack)
      tb.setForegroundColor(ForegroundColor.fgBlue, bright=true)
    else:
      tb.resetAttributes()
    let line = formatIndex(index + 1, entry, directoriesCount) & " " & entry.name
    tb.write(x, y, line)

  tb.setBackgroundColor(BackgroundColor.bgGreen)
  tb.setForegroundColor(ForegroundColor.fgBlack)

  y = y + 1
  tb.write(x, y, "- Files -")
  tb.resetAttributes()
  
  let filesCount = ($len(entries.files)).len
  for index, entry in entries.files:
    y = y + 1
    let line = formatIndex(index + 1, entry, filesCount) & " " & entry.name
    tb.write(x, y, line)
