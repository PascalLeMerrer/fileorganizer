import std/[strutils, unittest, options, unidecode]


from ../modules/entry import Entry, filter
import ../modules/file

func e(filename: string, path:string="", selected:bool=false): Entry =
  return Entry(name: unidecode(filename),
               path: if path == "": filename else: path,
               selected: selected
  )

include tentry
include tfile
include tfiltering






