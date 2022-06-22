import std/os
import std/strutils
import std/unidecode
import ./entry
from std/algorithm import sort

proc getFiles*(directoryPath: string): seq[Entry] =
  for kind, path in os.walkDir(directoryPath):
    let filename = splitPath(path).tail
    if filename.startsWith('.'):
      continue
    case kind:
    of pcFile:
      let entry = Entry(
        path: path,
        name: unidecode(filename), # Illwill does not support non ASCII chars
        selected: false
      )
      result.add(entry)
    else:
      discard

# Returns the list of directories in the current one, plus the link to the parent (..)
proc getSubDirectories*(directoryPath: string): seq[Entry] =
  result = @[Entry(path: ParDir, name: ParDir, selected: true)]
  for kind, path in os.walkDir(directoryPath):
    let filename = splitPath(path).tail
    if filename.startsWith('.'):
      continue
    case kind:
    of pcDir:
      let entry = Entry(
        path: path,
        name: unidecode(filename), # Illwill does not support non ASCII chars
        selected: false
      )
      result.add(entry)
    else:
      discard
  result.sort do (x, y: Entry) -> int:
    if x.path == ParDir:
      return -1
    if y.path == ParDir:
      return 1
    return cmp(x.name.toLower, y.name.toLower)


proc getSelectedDirectoryPath*(currentDirectoryPath: string,
    subDirectories: seq[Entry]): string =
  for entry in subDirectories:
    if entry.selected:
      case entry.name
      of ParDir:
        let (parent, current) = splitPath(currentDirectoryPath)
        return parent
      else:
        return entry.path

  return ""
