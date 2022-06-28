import std/[options, os, sequtils, strutils, unicode, unidecode]

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
  return sequtils.any(entries, func (entry: Entry): bool = return entry.selected)

func getSelectedItemIndex*(entries: seq[Entry]): int =
  # return the rank of the selected entry, or -1 if no enry is selected
  for index, entry in entries:
    if entry.selected:
      return index
  return -1

func getSelectedItem*(entries: seq[Entry]): Option[Entry] =
  # return the selected entry
  for index, entry in entries:
    if entry.selected:
      return some(entry)
  return none(Entry)

func selectFirst*(entries: seq[Entry]): seq[Entry] =
  if entries.len == 0:
    return entries
  let firstEntry = select(entries[0])
  result = @[firstEntry]
  if entries.len > 1:
    for entry in entries[1..^1]:
      if entry.selected:
        result.add(unselect(entry))
      else:
        result.add(entry)

func selectLast*(entries: seq[Entry]): seq[Entry] =
  if entries.len == 0:
    return entries
  for entry in entries[0..^2]:
    if entry.selected:
      result.add(unselect(entry))
    else:
      result.add(entry)
  let lastEntry = select(entries[^1])
  result.add(lastEntry)

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

proc filter*(entries: seq[Entry], lettersToSearch: string): seq[Entry] =
  result = @[]

  # ignore diacritics; For example, é and è are transformed to e
  let wordsToSearch = strutils.split(unidecode(lettersToSearch).toLower)

  for entry in entries:
    let name = entry.name.toLower
    if sequtils.all(wordsToSearch, func (word: string): bool = name.contains(word)):
      result.add(entry)


func cmp*(x: Entry, y: Entry): int =
  # Comparison function for sorting entries in alphabetical order, ignoring the case
  # The ".." dir, if present, is always first
  if x.path == os.ParDir:
    return -1
  if y.path == os.ParDir:
    return 1
  return system.cmp(x.name.toLower, y.name.toLower)
