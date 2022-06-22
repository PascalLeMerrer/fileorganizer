import illwill
import system
import std/os
import std/strformat
import std/tables
import std/unicode
import modules/[entry, file]

# TODO
# scroll when content is high than container
# display separation lines between dirs and files
# diplay files in destination dir
# Move command
# Move all command (A)
# Undo command
# Integrated Help (H)
# highlight moved files in dest dir


const rightArrow = $Rune(0x2192)
const yLimitBetweenDirAndFiles = 22

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

type View = enum
  DestinationSelection,
  FileSelection
  Filtering,
  SourceSelection,

type
  PressedKey =
    tuple[code: int, name: string]

type
  State = object
    filter: string
    filteredSourceFiles: seq[Entry] # the files in the current source dir matching the current filter
    sourceSubDirectories: seq[Entry] # the directories into the current source directory
    focus: View # the part of the screen with the focus
    sourceDirectoryPath: string
    destinationDirectoryPath: string
    destinationSubDirectories: seq[Entry] # the directories into the current destination directory
    filteredDestinationFiles: seq[Entry] # the files in the current destination dir matching the current filter


var state = State(
    filter: "",
    focus: SourceSelection,
    sourceDirectoryPath: getHomeDir(),
    destinationDirectoryPath: getHomeDir()
  )

proc getHalfWidth(): int =
  int(terminalWidth() / 2) - 1

proc getMaxColumnContentWidth():int =
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
  let destinationSubDirectories = file.getSubDirectories(state.destinationDirectoryPath)
  state.destinationSubDirectories = filter(destinationSubDirectories, state.filter)
  if not entry.isAnySelected(state.destinationSubDirectories):
    # the previously selected entry is excluded of selection
    state.destinationSubDirectories = entry.selectFirst(state.destinationSubDirectories)

  let files = file.getFiles(state.destinationDirectoryPath)
  let filteredFiles = filter(files, state.filter)
  state.filteredDestinationFiles = selectFirst(filteredFiles)

proc focusNextZone() =
  # todo use a map
  case state.focus
  of SourceSelection:
    state.focus = DestinationSelection
  of DestinationSelection:
    state.focus = FileSelection
  of FileSelection:
    state.focus = Filtering
  of Filtering:
    state.focus = SourceSelection

proc init() =
  illwillInit(fullscreen = true)
  setControlCHook(exitProc)
  hideCursor()
  loadSourceDirectoryContent()
  loadDestinationDirectoryContent()

proc updateSourceDirectoriesView() =
    let key = getKey()
    case key
    of Key.Down:
      state.sourceSubDirectories = entry.selectNext(state.sourceSubDirectories)
    of Key.Up:
      state.sourceSubDirectories = entry.selectPrevious(state.sourceSubDirectories)
    of Key.Enter:
      state.sourceDirectoryPath = file.getSelectedDirectoryPath(
          state.sourceDirectoryPath, state.sourceSubDirectories)
      loadSourceDirectoryContent()
    of Key.C:
      state.filter = ""
      loadSourceDirectoryContent()
      loadDestinationDirectoryContent()
    of Key.D:
      state.focus = DestinationSelection
    of Key.Escape, Key.Q:
      exitProc()
    of Key.F:
      state.focus = Filtering
    of Key.S:
      state.focus = SourceSelection
    of Key.Tab:
      focusNextZone()
    else:
      discard

proc updateDestinationDirectoriesView() =
    let key = getKey()
    case key
    of Key.Down:
      state.destinationSubDirectories = entry.selectNext(state.destinationSubDirectories)
    of Key.Up:
      state.destinationSubDirectories = entry.selectPrevious(state.destinationSubDirectories)
    of Key.Enter:
      state.destinationDirectoryPath = file.getSelectedDirectoryPath(
          state.destinationDirectoryPath, state.destinationSubDirectories)
      loadDestinationDirectoryContent()
    of Key.C:
      state.filter = ""
      loadSourceDirectoryContent()
      loadDestinationDirectoryContent()
    of Key.D:
      state.focus = DestinationSelection
    of Key.Escape, Key.Q:
      exitProc()
    of Key.F:
      state.focus = Filtering
    of Key.S:
      state.focus = SourceSelection
    of Key.Tab:
      focusNextZone()
    else:
      discard

proc updateSourceFilesView() =
    let key = getKey()
    case key
    of Key.Down:
      state.filteredSourceFiles = entry.selectNext(state.filteredSourceFiles)
    of Key.Up:
      state.filteredSourceFiles = entry.selectPrevious(state.filteredSourceFiles)
    of Key.C:
      state.filter = ""
      loadSourceDirectoryContent()
      loadDestinationDirectoryContent()
    of Key.D:
      state.focus = DestinationSelection
    of Key.Escape, Key.Q:
      exitProc()
    of Key.F:
      state.focus = Filtering
    of Key.S:
      state.focus = SourceSelection
    of Key.Tab:
      focusNextZone()
    else:
      discard


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
  of FileSelection:
    updateSourceFilesView()
  of Filtering:
    updateFilteringView()
    loadSourceDirectoryContent()
    loadDestinationDirectoryContent()

func formatIndex*(index: int, width: int): string =
  # formatting string cannot be defined dynamically

  case width
  of 2:
    return fmt("{index:>2}")
  of 3:
    return fmt("{index:>3}")
  of 4:
    return fmt("{index:>4}")
  of 5:
    return fmt("{index:>5}")
  else:
    return $index

proc renderFilter(tb: var TerminalBuffer, x: int, y: int, maxWidth: int): int =
  var nextY = y

  let bgColor = if state.focus == Filtering: BackgroundColor.bgGreen else:BackgroundColor.bgWhite
  tb.setBackgroundColor(bgColor)
  tb.setForegroundColor(ForegroundColor.fgBlack)

  var filter = state.filter
  if state.focus == Filtering:
    filter.add("|")
  if filter.len > maxWidth - 10:
    filter = filter[0..maxWidth-11]

  tb.write(x + 1, nextY, " Filter ")
  tb.resetAttributes()
  tb.write(x+10, nextY, filter)

  inc nextY
  inc nextY
  return nextY

proc renderFiles(tb: var TerminalBuffer, entries: seq[Entry], x: int, y: int, maxWidth: int): int =

  var currentY = y

  let maxDigitsForIndex = ($len(entries)).len
  for index, fileEntry in entries:
    inc currentY
    if fileEntry.selected:
      tb.setBackgroundColor(BackgroundColor.bgBlack)
      tb.setForegroundColor(ForegroundColor.fgBlue, bright = true)
    else:
      tb.resetAttributes()
    let selectionSymbol = if fileEntry.selected: rightArrow else: " "
    var line = selectionSymbol & " " & formatIndex(index + 1, maxDigitsForIndex) & " " & fileEntry.name
    if line.len > maxWidth:
      line = line[0..maxWidth-1]
    tb.write(x, currentY, line)
  return currentY + 1

proc renderDirectories(tb: var TerminalBuffer, entries: seq[Entry], x: int, y: int, maxWidth: int, maxY: int): int =

  var currentY = y
  var startIndex = 0
  var maxVisibleEntryCount = maxY - y

  if currentY + entries.len >= maxY:
    # scrolling required
    let selectedItemIndex = entry.getSelectedItemIndex(entries)
    if currentY + selectedItemIndex >= maxY:
      startIndex = selectedItemIndex - (maxY - currentY) + 1
  var maxVisibleIndex = startIndex + maxVisibleEntryCount - 1
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

proc renderSourceDirectories(tb: var TerminalBuffer, x: int, y: int, maxWidth: int): int =
  var nextY = y


  let bgColor = if state.focus == SourceSelection: BackgroundColor.bgGreen else:BackgroundColor.bgWhite
  tb.setBackgroundColor(bgColor)
  tb.setForegroundColor(ForegroundColor.fgBlack)
  var title = " Source: " & state.sourceDirectoryPath.lastPathPart
  if title.len > maxWidth:
    title = title[0..maxWidth-3] & "..."
  tb.write(x, nextY, title)
  tb.resetAttributes()
  nextY = renderDirectories(tb, state.sourceSubDirectories, x, nextY, maxWidth, maxY=yLimitBetweenDirAndFiles - 1 )
  inc nextY
  return nextY

proc renderDestinationDirectories(tb: var TerminalBuffer, x: int, y: int, maxWidth: int): int =
  var nextY = y
  let bgColor = if state.focus == DestinationSelection: BackgroundColor.bgGreen else:BackgroundColor.bgWhite
  tb.setBackgroundColor(bgColor)
  tb.setForegroundColor(ForegroundColor.fgBlack)
  var title = " Destination: " & state.destinationDirectoryPath.lastPathPart
  if title.len > maxWidth:
    title = title[0..maxWidth-3] & "..."
  tb.write(x, nextY, title)
  tb.resetAttributes()

  nextY = renderDirectories(tb, state.destinationSubDirectories, x, nextY, maxWidth, maxY=yLimitBetweenDirAndFiles - 1)
  inc nextY
  return nextY

proc renderSourceFiles(tb: var TerminalBuffer, x: int, y: int, maxWidth: int): int =
  var nextY = y

  let bgColor = if state.focus == FileSelection: BackgroundColor.bgGreen else:BackgroundColor.bgWhite
  tb.setBackgroundColor(bgColor)
  tb.setForegroundColor(ForegroundColor.fgBlack)

  tb.write(2, nextY, " Files ")
  inc nextY
  nextY = renderFiles(tb, state.filteredSourceFiles, 2, nextY, maxWidth)
  tb.resetAttributes()
  return nextY

proc renderGrid(tb: var TerminalBuffer, bb: var BoxBuffer) =
    tb.setForegroundColor(ForegroundColor.fgYellow)
    bb.drawRect(0, 0, tb.width-1, tb.height-1)

    # middle vertical separation
    let x = getHalfWidth() + 1
    bb.drawVertLine(x, 2, terminalHeight() - 3)


    # separator between directories and files
    bb.drawHorizLine(x1=0, x2=terminalWidth(), y=yLimitBetweenDirAndFiles)

    # filter input box
    bb.drawRect(0, 0, terminalWidth(), 2)

    # footer box
    bb.drawRect(0, terminalHeight() - 3, terminalWidth(), terminalHeight())

    tb.write(bb)

proc render() =
  var tb = newTerminalBuffer(terminalWidth(), terminalHeight())
  var bb = newBoxBuffer(tb.width, tb.height)
  renderGrid(tb, bb)

  var nextY: int = 1

  nextY = renderFilter(tb, 1, nextY, terminalWidth() - 4 )

  let maxWidth = getMaxColumnContentWidth()
  discard renderDestinationDirectories(tb, getHalfWidth() + 3, nextY, maxWidth)

  nextY = renderSourceDirectories(tb, 2, nextY, maxWidth)
  nextY = renderSourceFiles(tb, 2, nextY, maxWidth)

  tb.write(2, tb.height - 2, "Press Q, Esc or Ctrl-C to quit")

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

