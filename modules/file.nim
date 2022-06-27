import std/os
import std/strutils
import std/unidecode
import ./entry
from std/algorithm import sort
from std/sugar import dump
import std/sequtils

const maxFiles* = 5000

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
  result.sort do (x, y: Entry) -> int:
    return entry.cmp(x, y)

# Returns the list of directories in the current one, plus the link to the parent (..)
proc getSubDirectories*(directoryPath: string): seq[Entry] =
  result = @[Entry(path: ParDir, name: ParDir, selected: true)]
  for kind, path in os.walkDir(directoryPath):
    # ignore hidden subdirectories
    let pathParts = path.split(os.AltSep)
    if sequtils.any(pathParts, func (dirName: string): bool = return dirName.startsWith('.')):
      continue
    let dirName = splitPath(path).tail
    case kind:
    of pcDir:
      let entry = Entry(
        path: path,
        name: unidecode(dirName), # Illwill does not support non ASCII chars
        selected: false
      )
      result.add(entry)
    else:
      discard
  result.sort do (x, y: Entry) -> int:
    return entry.cmp(x, y)

# Returns the list of directories in the current one, plus the link to the parent (..)
proc getSubDirectoriesRecursively*(rootPath: string, destinationDirectoryPath: string, subDirectories: var seq[Entry]) =
  let rootPathLen = rootPath.len
  for kind, path in os.walkDir(dir = destinationDirectoryPath, checkDir = true):
    if os.isHidden(path) or kind != pcDir:
      continue
    let relativePath = path[(rootPathLen + 1)..^1]
    let entry = Entry(
      path: path,
      name: unidecode(relativePath), # Illwill does not support non ASCII chars
      selected: false
    )
    subDirectories.add(entry)
    if subDirectories.len >= maxFiles:
      break
    getSubDirectoriesRecursively(rootPath, path, subDirectories)

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


