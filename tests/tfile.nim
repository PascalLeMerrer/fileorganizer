import std/unittest

from ../modules/entry import Entry
import ../modules/file

func e(filename: string, path: string, selected:bool=false): Entry =
  return Entry(name: filename,
               path: path,
               selected: selected
  )

suite "getSelectedDirectoryPath":
  test "concatenates the parent dir path with the selected subdirectory name":
    let subDirectories: seq[Entry] = @[
        e(path="/root/subdir1", filename="subdir1"),
        e(path="/root/subdir2", filename="subdir2", selected=true),
        e(path="/root/subdir3", filename="subdir3")
      ]
    let actualPath = file.getSelectedDirectoryPath("/root", subDirectories)
    check(actualPath == "/root/subdir2")