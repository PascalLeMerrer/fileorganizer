import std/strformat
import std/strutils
import std/unicode
import std/unidecode
import illwill

const checkSymbol = $Rune(0x2705)
const rightArrow = $Rune(0x2794)

type
  Entry* = object
    name*: string
    path*: string
    selected*: bool

type
  Entries* = tuple[files, directories: seq[Entry]]

func select*(entry: Entry): Entry =
  return Entry(name: entry.name, path: entry.path, selected: true)

func unselect*(entry: Entry): Entry =
  return Entry(name: entry.name, path: entry.path, selected: false)

proc selectNext*(entries: seq[Entry]): seq[Entry] =
  result = @[]
  var shouldSelectNextEntry = false
  var shouldSelectFirstEntry = false
  let lastIndex = entries.len - 1
  for index, entry in entries:
    if entry.selected:
      shouldSelectNextEntry = true
      shouldSelectFirstEntry = index == lastIndex
      let newEntry = unselect(entry)
      result.add(newEntry)
    else:
      if shouldSelectNextEntry:
        shouldSelectNextEntry = false
        let newEntry = select(entry)
        result.add(newEntry)
      else:
        result.add(entry)
  if shouldSelectFirstEntry:
    let firstEntry = result[0]
    let newEntry = select(firstEntry)
    result[0] = newEntry


func reverse*(entries: seq[Entry]): seq[Entry] =
  for i in countdown(entries.len - 1, 0):
    result.add(entries[i])

proc selectPrevious*(entries: seq[Entry]): seq[Entry] =
  reverse(selectNext(reverse(entries)))

func containsLetters(text: string, lettersToSearch: string): bool =
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

proc filter*(entries: Entries, lettersToSearch: string): Entries =
  var filteredFiles: seq[Entry] = @[]
  var filteredDirectories: seq[Entry] = @[]

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


func formatIndex*(index: int, width: int): string =
  # formatting string cannot be defined dynamically

  case width
  of 2:
    return fmt("{index:>2}")
  of 3:
    return fmt("{index:>3}")
  of 4:
    return fmt("{index:>4}")
  of 5:
    return fmt("{index:>5}")
  else:
    return $index

proc addPrefix(index: int, entry: Entry, width: int, ): string =
  # width is the max number of digits for the index value; for example if the list contains 10 to 99 items, it's 2
  let formattedIndex = formatIndex(index, width)
  result = if entry.selected: rightArrow & $formattedIndex else: " " & $formattedIndex

proc render*(entries: Entries, tb: var TerminalBuffer, x: int) =

  var y = 4
  tb.setBackgroundColor(BackgroundColor.bgGreen)
  tb.setForegroundColor(ForegroundColor.fgBlack)
  tb.write(x, y, "- Directories -")
  let maxDigitsForDirectoryIndex = ($len(entries.directories)).len
  for index, entry in entries.directories:
    y = y + 1
    if entry.selected:
      tb.setBackgroundColor(BackgroundColor.bgBlack)
      tb.setForegroundColor(ForegroundColor.fgBlue, bright = true)
    else:
      tb.resetAttributes()
    let line = addPrefix(index + 1, entry, maxDigitsForDirectoryIndex) & " " & entry.name
    tb.write(x, y, line)

  tb.setBackgroundColor(BackgroundColor.bgGreen)
  tb.setForegroundColor(ForegroundColor.fgBlack)

  y = y + 1
  tb.write(x, y, "- Files -")
  tb.resetAttributes()

  let maxDigitsForFileIndex = ($len(entries.files)).len
  for index, entry in entries.files:
    y = y + 1
    let line = addPrefix(index + 1, entry, maxDigitsForFileIndex) & " " & entry.name
    tb.write(x, y, line)
