import std/strutils
import std/unittest

from ../modules/entry import Entry, Entries, filter, formatIndex, select, selectNext
import ../modules/file

func e(filename: string, path:string="", selected:bool=false): Entry =
  return Entry(name: filename,
               path: if path == "": filename else: path,
               selected: selected
  )

include tentryselection
include tfile
include tfiltering
include tformatting






