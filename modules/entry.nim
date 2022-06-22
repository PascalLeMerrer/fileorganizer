import std/sequtils
import std/strutils
import std/unicode
import std/unidecode
from std/os import Pardir

type
  Entry* = object
    name*: string
    path*: string
    selected*: bool

func select*(entry: Entry): Entry =
  return Entry(name: entry.name, path: entry.path, selected: true)

func unselect*(entry: Entry): Entry =
  return Entry(name: entry.name, path: entry.path, selected: false)

func isAnySelected*(entries: seq[Entry]): bool =
  return sequtils.any(entries, func (entry:Entry):bool = return entry.selected)

func getSelectedItemIndex*(entries:seq[Entry]):int =
  # return the rank of the selected entry, or -1 if no enry is selected
  for index, entry in entries:
    if entry.selected:
      return index
  return -1

func selectFirst*(entries: seq[Entry]): seq[Entry] =
  if entries.len == 0:
    return entries
  let firstEntry = select(entries[0])
  if entries.len == 1:
    return @[firstEntry]
  return concat(@[firstEntry], entries[1..^1])

func selectNext*(entries: seq[Entry]): seq[Entry] =
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

func selectPrevious*(entries: seq[Entry]): seq[Entry] =
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

proc filter*(entries: seq[Entry], lettersToSearch: string): seq[Entry] =
  result = @[]

  # ignore diacritics; For example, é and è and transformed to e
  let asciiLettersToSearch = unidecode(lettersToSearch)

  for entry in entries:
    let asciiFilename = unidecode(entry.name)
    if containsLetters(asciiFilename, asciiLettersToSearch):
      result.add(entry)


func cmp*(x: Entry, y: Entry): int =
  if x.path == ParDir:
    return -1
  if y.path == ParDir:
    return 1
  return cmp(x.name.toLower, y.name.toLower)