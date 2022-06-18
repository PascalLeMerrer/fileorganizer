import std/os
import std/strutils
import ./entry

proc getDirectoryContent*(directoryPath:string, includeFiles:bool=true):Entries =
  var directories : seq[Entry]
  var files : seq[Entry]

  for kind, path in os.walkDir(directoryPath):
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
proc getSubDirectories*(directoryPath:string): seq[Entry] =
  var parentDirectory = Entry(
        path: "..",
        name: "..",
        selected: true
  )
  result = @[parentDirectory]
  let subDirectories = getDirectoryContent(directoryPath, includeFiles=false).directories
  result.add(subDirectories)

proc getSelectedDirectoryPath*(currentDirectoryPath:string, subDirectories: seq[Entry]): string =
  for entry in subDirectories:
    if entry.selected:
      case entry.name
      of ParDir:
         let (parent, current) = splitPath(currentDirectoryPath)
         return parent
      else:
        return entry.path

  return ""