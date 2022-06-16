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
        selected: false
  )
  select(parentDirectory)
  result = @[parentDirectory]
  let subDirectories = getDirectoryContent(directoryPath, includeFiles=false).directories
  result.add(subDirectories)
  result = selectNext(result)