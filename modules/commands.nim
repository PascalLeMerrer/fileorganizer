import std/os
from ./entry import Entry

type Command* = ref object of RootObj
  file*: Entry
  directory*: string
method execute*(this: Command) {.base.} =
  discard
method undo*(this: Command) {.base.} =
  discard

type MoveCommand* = ref object of Command
method execute(this: MoveCommand) =
  let destinationPath = this.directory & os.DirSep & this.file.name
  os.moveFile(this.file.path, destinationPath)
method undo(this: MoveCommand) =
  let currentPath = this.directory & os.DirSep & this.file.name
  os.moveFile(currentPath, this.file.path)

type RenameCommand* = ref object of Command
  newName*: string
method execute(this: RenameCommand) =
  let destinationPath = this.directory & os.DirSep & this.newName
  os.moveFile(this.file.path, destinationPath)
method undo(this: RenameCommand) =
  let currentPath = this.directory & os.DirSep & this.newName
  os.moveFile(currentPath, this.file.path)
