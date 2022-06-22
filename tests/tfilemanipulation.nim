import std/strutils
import std/unittest
import std/options

from ../modules/entry import Entry, filter
import ../modules/file

func e(filename: string, path:string="", selected:bool=false): Entry =
  return Entry(name: filename,
               path: if path == "": filename else: path,
               selected: selected
  )

include tentry
include tfile
include tfiltering






