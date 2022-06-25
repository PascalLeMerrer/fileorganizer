import illwill
import system
import std/os
import std/strformat
import std/tables
import std/unicode
import modules/[commands, entry, file]
from std/sugar import dump
import std/options

# TODO
# CTRL+UP to go to the first item
# CTRL+DOWN to go to the last item
# Integrated Help (H)
# Delete file
# highlight moved files in dest dir
# select file by number
# scrollbar
# remove all magic numbers
# O for opening file
# Display file size
# Display last modification date of files
# Rename files
# Move all command (A)
# undo command which modified multiple files

const rightArrow = $Rune(0x2192)
const yLimitBetweenDirAndFiles = 22
const leftColumnX = 2

let characters = {
  Key.Space: " ",
  Key.ExclamationMark: "!",
  Key.DoubleQuote: "\"",
  Key.Hash: "#",
  Key.Dollar: "$",
  Key.Percent: "%",
  Key.Ampersand: "&",
  Key.SingleQuote: "'",
  Key.LeftParen: "(",
  Key.RightParen: ")",
  Key.Asterisk: "*",
  Key.Plus: "+",
  Key.Comma: ",",
  Key.Minus: "-",
  Key.Dot: ".",
  Key.Slash: "/",
  Key.Zero: "0",
  Key.One: "1",
  Key.Two: "2",
  Key.Three: "3",
  Key.Four: "4",
  Key.Five: "5",
  Key.Six: "6",
  Key.Seven: "7",
  Key.Eight: "8",
  Key.Nine: "9",
  Key.Colon: ":",
  Key.Semicolon: ";",
  Key.LessThan: "<",
  Key.Equals: "=",
  Key.GreaterThan: ">",
  Key.QuestionMark: "?",
  Key.At: "@",
  Key.ShiftA: "A",
  Key.ShiftB: "B",
  Key.ShiftC: "C",
  Key.ShiftD: "D",
  Key.ShiftE: "E",
  Key.ShiftF: "F",
  Key.ShiftG: "G",
  Key.ShiftH: "H",
  Key.ShiftI: "I",
  Key.ShiftJ: "J",
  Key.ShiftK: "K",
  Key.ShiftL: "L",
  Key.ShiftM: "M",
  Key.ShiftN: "N",
  Key.ShiftO: "O",
  Key.ShiftP: "P",
  Key.ShiftQ: "Q",
  Key.ShiftR: "R",
  Key.ShiftS: "S",
  Key.ShiftT: "T",
  Key.ShiftU: "U",
  Key.ShiftV: "V",
  Key.ShiftW: "W",
  Key.ShiftX: "X",
  Key.ShiftY: "Y",
  Key.ShiftZ: "Z",
  Key.LeftBracket: "[",
  Key.Backslash: "\"",
  Key.RightBracket: "]",
  Key.Caret: "^",
  Key.Underscore: "_",
  Key.GraveAccent: "`",
  Key.A: "a",
  Key.B: "b",
  Key.C: "c",
  Key.D: "d",
  Key.E: "e",
  Key.F: "f",
  Key.G: "g",
  Key.H: "h",
  Key.I: "i",
  Key.J: "j",
  Key.K: "k",
  Key.L: "l",
  Key.M: "m",
  Key.N: "n",
  Key.O: "o",
  Key.P: "p",
  Key.Q: "q",
  Key.R: "r",
  Key.S: "s",
  Key.T: "t",
  Key.U: "u",
  Key.V: "v",
  Key.W: "w",
  Key.X: "x",
  Key.Y: "y",
  Key.Z: "z",
  Key.LeftBrace: "{",
  Key.Pipe: "|",
  Key.RightBrace: "}",
  Key.Tilde: "~"
}.toTable

type FocusZone = enum
  DestinationFileSelection
  DestinationSelection,
  Filtering,
  SourceFileSelection
  SourceSelection,

type
  PressedKey =
    tuple[code: int, name: string]

type
  State = object
    commands: seq[Command] # the last command, which may by canceled
    error: string
    filter: string
    filteredSourceFiles: seq[Entry] # the files in the current source dir matching the current filter
    sourceSubDirectories: seq[Entry] # the directories into the current source directory
    focus: FocusZone            # the part of the screen with the focus
    sourceDirectoryPath: string
    destinationDirectoryPath: string
    destinationSubDirectories: seq[Entry] # the directories into the current destination directory
    filteredDestinationFiles: seq[Entry] # the files in the current destination dir matching the current filter

var state = State(
    error: "",
    filter: "",
    focus: SourceSelection,
    sourceDirectoryPath: getHomeDir(),
    destinationDirectoryPath: getHomeDir()
  )

proc getHalfWidth(): int =
  int(terminalWidth() / 2) - 1

proc getMaxColumnContentWidth(): int =
  getHalfWidth() - 3

proc exitProc() {.noconv.} =
  illwillDeinit()
  showCursor()
  quit(0)

proc loadSourceDirectoryContent() =
  let sourceSubDirectories = file.getSubDirectories(state.sourceDirectoryPath)
  state.sourceSubDirectories = filter(sourceSubDirectories, state.filter)
  if not entry.isAnySelected(state.sourceSubDirectories):
    # the previously selected entry is excluded of selection
    state.sourceSubDirectories = entry.selectFirst(state.sourceSubDirectories)
  let files = file.getFiles(state.sourceDirectoryPath)
  let filteredFiles = filter(files, state.filter)
  state.filteredSourceFiles = selectFirst(filteredFiles)

proc loadDestinationDirectoryContent() =
  let destinationSubDirectories = file.getSubDirectories(
      state.destinationDirectoryPath)
  state.destinationSubDirectories = filter(destinationSubDirectories, state.filter)
  if not entry.isAnySelected(state.destinationSubDirectories):
    # the previously selected entry is excluded of selection
    state.destinationSubDirectories = entry.selectFirst(
        state.destinationSubDirectories)

  let files = file.getFiles(state.destinationDirectoryPath)
  let filteredFiles = filter(files, state.filter)
  state.filteredDestinationFiles = selectFirst(filteredFiles)

proc reload() =
  loadSourceDirectoryContent()
  loadDestinationDirectoryContent()

proc focusNextZone() =
  # todo use a map
  case state.focus
  of SourceSelection:
    state.focus = DestinationSelection
  of DestinationSelection:
    state.focus = SourceFileSelection
  of SourceFileSelection:
    state.focus = DestinationFileSelection
  of DestinationFileSelection:
    state.focus = Filtering
  of Filtering:
    state.focus = SourceSelection

proc init() =
  illwillInit(fullscreen = true)
  setControlCHook(exitProc)
  hideCursor()
  reload()

proc processGlobalKeyPress(key: Key) =
  # execute the action linked to a keybard shortcut available in all focus zones except input fields
    case key
    of Key.C:
      state.filter = ""
      reload()
    of Key.D:
      state.focus = DestinationSelection
    of Key.Escape, Key.Q:
      exitProc()
    of Key.F:
      state.focus = Filtering
    of Key R:
      reload()
    of Key.S:
      state.focus = SourceSelection
    of Key.Tab:
      focusNextZone()
    of Key.U:
      if state.commands.len > 0:
        let lastExecutedCommand = state.commands[^1]
        lastExecutedCommand.undo()
        reload()
    else:
      discard
    if key != Key.None:
      state.error = ""

proc updateSourceDirectoriesView() =
  let key = getKey()
  case key
  of Key.Down:
    state.sourceSubDirectories = entry.selectNext(state.sourceSubDirectories)
  of Key.Up:
    state.sourceSubDirectories = entry.selectPrevious(
        state.sourceSubDirectories)
  of Key.Enter:
    state.sourceDirectoryPath = file.getSelectedDirectoryPath(
        state.sourceDirectoryPath, state.sourceSubDirectories)
    loadSourceDirectoryContent()
  else:
    processGlobalKeyPress(key)

proc updateDestinationDirectoriesView() =
  let key = getKey()
  case key
  of Key.Down:
    state.destinationSubDirectories = entry.selectNext(
        state.destinationSubDirectories)
  of Key.Up:
    state.destinationSubDirectories = entry.selectPrevious(
        state.destinationSubDirectories)
  of Key.Enter:
    state.destinationDirectoryPath = file.getSelectedDirectoryPath(
        state.destinationDirectoryPath, state.destinationSubDirectories)
    loadDestinationDirectoryContent()
  else:
    processGlobalKeyPress(key)

proc updateSourceFilesView() =
  let key = getKey()
  case key
  of Key.Down:
    state.filteredSourceFiles = entry.selectNext(state.filteredSourceFiles)
  of Key.Up:
    state.filteredSourceFiles = entry.selectPrevious(state.filteredSourceFiles)
  of Key.M:
    let selectedFile = entry.getSelectedItem(state.filteredSourceFiles)
    if selectedFile.isSome:
      let command = MoveCommand(file: selectedFile.get(),
          directory: state.destinationDirectoryPath)
      command.execute()
      state.commands.add(command)
      reload()
    else:
      state.error = "ERROR: Move command failed because no file is selected."
  else:
    processGlobalKeyPress(key)

proc updateDestinationFilesView() =
  let key = getKey()
  case key
  of Key.Down:
    state.filteredDestinationFiles = entry.selectNext(
        state.filteredDestinationFiles)
  of Key.Up:
    state.filteredDestinationFiles = entry.selectPrevious(
        state.filteredDestinationFiles)
  of Key.M:
    let selectedFile = entry.getSelectedItem(state.filteredDestinationFiles)
    if selectedFile.isSome:
      let command = MoveCommand(file: selectedFile.get(),
          directory: state.sourceDirectoryPath)
      command.execute()
      state.commands.add(command)
      reload()
    else:
      state.error = "ERROR: Move command failed because no file is selected."
  else:
    processGlobalKeyPress(key)


proc updateFilteringView() =
  let key = getKey()
  case key
  of Key.Escape:
    state.focus = SourceSelection
  of Key.Backspace:
    if state.filter.len > 0:
      state.filter = state.filter[0 .. ^2]
  of Key.Tab:
    focusNextZone()
  else:
    if key in characters:
      state.filter.add(characters[key])


proc update() =
  case state.focus
  of DestinationSelection:
    updateDestinationDirectoriesView()
  of SourceSelection:
    updateSourceDirectoriesView()
  of SourceFileSelection:
    updateSourceFilesView()
  of DestinationFileSelection:
    updateDestinationFilesView()
  of Filtering:
    updateFilteringView()
    reload()

proc renderFilter(tb: var TerminalBuffer, x: int, y: int, maxWidth: int): int =
  var nextY = y

  let bgColor = if state.focus == Filtering: BackgroundColor.bgGreen else: BackgroundColor.bgWhite
  tb.setBackgroundColor(bgColor)
  tb.setForegroundColor(ForegroundColor.fgBlack)

  var filter = state.filter
  if filter.len > maxWidth - 10:
    filter = filter[0..maxWidth-11]

  tb.write(x + 1, nextY, " Filter ")
  tb.resetAttributes()
  tb.write(x+10, nextY, filter)
  if state.focus == Filtering:
    tb.setForegroundColor(ForegroundColor.fgRed)
    tb.write(x + 10 + filter.len, nextY, "|")
    tb.resetAttributes()
  inc nextY
  inc nextY
  return nextY

proc renderFiles(tb: var TerminalBuffer, entries: seq[Entry], x: int, y: int,
    maxWidth: int, maxY: int): int =

  let maxDigitsForIndex = ($len(entries)).len
  var currentY = y
  var startIndex = 0
  let maxVisibleEntryCount = maxY - y

  if currentY + entries.len >= maxY:
    # scrolling required
    let selectedItemIndex = entry.getSelectedItemIndex(entries)
    if currentY + selectedItemIndex >= maxY:
      startIndex = selectedItemIndex - (maxY - currentY) + 1
  var maxVisibleIndex = min(entries.len - 1, startIndex + maxVisibleEntryCount - 1)

  for index in startIndex..maxVisibleIndex:
    let fileEntry = entries[index]
    inc currentY
    if fileEntry.selected:
      tb.setBackgroundColor(BackgroundColor.bgBlack)
      tb.setForegroundColor(ForegroundColor.fgBlue, bright = true)
    else:
      tb.resetAttributes()
    let selectionSymbol = if fileEntry.selected: rightArrow else: " "
    var line = selectionSymbol & " " & strutils.align($(index + 1),
        maxDigitsForIndex) & " " & fileEntry.name
    if line.len > maxWidth:
      line = line[0..maxWidth-1]
    tb.write(x, currentY, line)
  return currentY + 1

proc renderDirectories(tb: var TerminalBuffer, entries: seq[Entry], x: int,
    y: int, maxWidth: int, maxY: int): int =

  var currentY = y
  var startIndex = 0
  let maxVisibleEntryCount = maxY - y

  if currentY + entries.len >= maxY:
    # scrolling required
    let selectedItemIndex = entry.getSelectedItemIndex(entries)
    if currentY + selectedItemIndex >= maxY:
      startIndex = selectedItemIndex - (maxY - currentY) + 1
  var maxVisibleIndex = min(entries.len - 1, startIndex + maxVisibleEntryCount - 1)

  for index in startIndex..maxVisibleIndex:
    let directory = entries[index]

    inc currentY
    if currentY > maxY:
      break # avoid vertical overflow

    if directory.selected:
      tb.setBackgroundColor(BackgroundColor.bgBlack)
      tb.setForegroundColor(ForegroundColor.fgBlue, bright = true)
    else:
      tb.resetAttributes()
    let selectionSymbol = if directory.selected: rightArrow else: " "
    var line = selectionSymbol & " " & directory.name
    if line.len > maxWidth:
      line = line[0..maxWidth-1] # avoid horizontal overflow
    tb.write(x, currentY, line)

  return currentY + 1

proc renderSourceDirectories(tb: var TerminalBuffer, x: int, y: int,
    maxWidth: int): int =
  var nextY = y
  let bgColor = if state.focus == SourceSelection: BackgroundColor.bgGreen else: BackgroundColor.bgWhite
  tb.setBackgroundColor(bgColor)
  tb.setForegroundColor(ForegroundColor.fgBlack)
  var title = " Source: " & state.sourceDirectoryPath.lastPathPart
  if title.len > maxWidth:
    title = title[0..maxWidth-3] & "..."
  tb.write(x, nextY, title)
  tb.resetAttributes()
  nextY = renderDirectories(tb, state.sourceSubDirectories, x, nextY, maxWidth,
      maxY = yLimitBetweenDirAndFiles - 1)
  inc nextY
  return nextY

proc renderDestinationDirectories(tb: var TerminalBuffer, x: int, y: int,
    maxWidth: int): int =
  var nextY = y
  let bgColor = if state.focus == DestinationSelection: BackgroundColor.bgGreen else: BackgroundColor.bgWhite
  tb.setBackgroundColor(bgColor)
  tb.setForegroundColor(ForegroundColor.fgBlack)
  var title = " Destination: " & state.destinationDirectoryPath.lastPathPart
  if title.len > maxWidth:
    title = title[0..maxWidth-3] & "..."
  tb.write(x, nextY, title)
  tb.resetAttributes()

  nextY = renderDirectories(tb, state.destinationSubDirectories, x, nextY,
      maxWidth, maxY = yLimitBetweenDirAndFiles - 1)
  inc nextY
  return nextY

proc renderSourceFiles(tb: var TerminalBuffer, x: int, y: int,
    maxWidth: int): int =
  var nextY = y

  let bgColor = if state.focus == SourceFileSelection: BackgroundColor.bgGreen else: BackgroundColor.bgWhite
  tb.setBackgroundColor(bgColor)
  tb.setForegroundColor(ForegroundColor.fgBlack)

  tb.write(leftColumnX, nextY, " Source files ")
  let maxY = terminalHeight() - 4
  nextY = renderFiles(tb, state.filteredSourceFiles, leftColumnX, nextY,
      maxWidth, maxY)
  tb.resetAttributes()
  return nextY

proc renderDestinationFiles(tb: var TerminalBuffer, x: int, y: int,
    maxWidth: int): int =
  var nextY = y

  let bgColor = if state.focus == DestinationFileSelection: BackgroundColor.bgGreen else: BackgroundColor.bgWhite
  tb.setBackgroundColor(bgColor)
  tb.setForegroundColor(ForegroundColor.fgBlack)

  tb.write(x, nextY, " Destination files ")
  let maxY = terminalHeight() - 4
  nextY = renderFiles(tb, state.filteredDestinationFiles, x, nextY, maxWidth, maxY)
  tb.resetAttributes()
  return nextY

proc renderGrid(tb: var TerminalBuffer, bb: var BoxBuffer) =
  tb.setForegroundColor(ForegroundColor.fgYellow)
  bb.drawRect(0, 0, tb.width-1, tb.height-1, doubleStyle = true)

  # middle vertical separation
  let x = getHalfWidth() + 1
  bb.drawVertLine(x, leftColumnX, terminalHeight() - 3, doubleStyle = true)

  # separator between directories and files
  bb.drawHorizLine(x1 = 0, x2 = terminalWidth(), y = yLimitBetweenDirAndFiles, doubleStyle = true)

  # filter input box
  bb.drawRect(0, 0, terminalWidth(), 2, doubleStyle = true)

  # footer box
  bb.drawRect(0, terminalHeight() - 3, terminalWidth(), terminalHeight(), doubleStyle = true)

  tb.write(bb)

proc renderHelp(tb: var TerminalBuffer, x: int, y:int)=
  case state.focus
  of DestinationSelection, SourceSelection:
    tb.write(x, y,
      bgWhite, fgBlack, "TAB", resetStyle, " focus next zone ",
      bgWhite, fgBlack, "F", resetStyle, " edit filter ",
      bgWhite, fgBlack, "C", resetStyle, " clear filter ",
      bgWhite, fgBlack, "Q", resetStyle, " quit ",
      )
  of DestinationFileSelection, SourceFileSelection:
    tb.write(x, y,
      bgWhite, fgBlack, "TAB", resetStyle, " focus next zone ",
      bgWhite, fgBlack, "F", resetStyle, " edit filter ",
      bgWhite, fgBlack, "M", resetStyle, " move selected file ",
      bgWhite, fgBlack, "C", resetStyle, " clear filter ",
      bgWhite, fgBlack, "Q", resetStyle, " quit ",
      )
  of Filtering:
    tb.write(x, y, "Press ", bgWhite, fgBlack, "Esc", resetStyle, " to exit filter edition")

proc renderError(tb: var TerminalBuffer, x: int, y:int, msg:string)=
  tb.write(x, y, bgRed, fgWhite, msg)

proc render() =
  var tb = newTerminalBuffer(terminalWidth(), terminalHeight())
  var bb = newBoxBuffer(tb.width, tb.height)
  renderGrid(tb, bb)

  var nextY: int = 1

  nextY = renderFilter(tb, 1, nextY, terminalWidth() - 4)

  let maxWidth = getMaxColumnContentWidth()
  let rightColumnX = getHalfWidth() + 3
  discard renderDestinationDirectories(tb, rightColumnX, nextY, maxWidth)

  nextY = renderSourceDirectories(tb, leftColumnX, nextY, maxWidth)
  discard renderSourceFiles(tb, leftColumnX, yLimitBetweenDirAndFiles + 1, maxWidth)
  discard renderDestinationFiles(tb, rightColumnX, yLimitBetweenDirAndFiles + 1, maxWidth)

  if state.error == "":
    renderHelp(tb, leftColumnX, tb.height - 2)
  else:
    renderError(tb, leftColumnX, tb.height - 2, state.error)

  tb.display()

proc main() =
  init()
  while true:
    update()
    render()
    sleep(20)

main()

when isMainModule:
  main()
