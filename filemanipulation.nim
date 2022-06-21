import illwill
import system
import std/os
import std/strformat
import std/unicode
import modules/[entry, file]

const checkSymbol = $Rune(0x2705)
const rightArrow = $Rune(0x2192)

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

let rightColumnX = int(terminalWidth() / 2)

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
    of Key.Escape, Key.Q:
      exitProc()
    of Key.F:
      state.focus = Filtering
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
    of Key.Escape, Key.Q:
      exitProc()
    of Key.F:
      state.focus = Filtering
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
    of Key.Escape, Key.Q:
      exitProc()
    of Key.F:
      state.focus = Filtering
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
    if key >= Key.A and key <= Key.Z:
      state.filter.add(($key).toLower())


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

proc renderFilter(tb: var TerminalBuffer, x: int, y: int): int =
  var nextY = y

  let bgColor = if state.focus == Filtering: BackgroundColor.bgGreen else:BackgroundColor.bgWhite
  tb.setBackgroundColor(bgColor)
  tb.setForegroundColor(ForegroundColor.fgBlack)

  var filter = state.filter
  if state.focus == Filtering:
    filter.add("|")

  tb.write(x + 1, nextY, " Filter ")
  tb.resetAttributes()
  tb.write(x+10, nextY, filter)
  inc nextY
  tb.drawHorizLine(x, terminalWidth() - 2, nextY)
  inc nextY
  return nextY

proc renderFiles(tb: var TerminalBuffer, entries: seq[Entry], x: int, y: int): int =

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
    let line = selectionSymbol & " " & formatIndex(index + 1, maxDigitsForIndex) & " " & fileEntry.name
    tb.write(x, currentY, line)
  return currentY + 1

proc renderDirectories(tb: var TerminalBuffer, entries: seq[Entry], x: int, y: int): int =

  var currentY = y

  for index, directory in entries:
    inc currentY
    if directory.selected:
      tb.setBackgroundColor(BackgroundColor.bgBlack)
      tb.setForegroundColor(ForegroundColor.fgBlue, bright = true)
    else:
      tb.resetAttributes()
    let selectionSymbol = if directory.selected: rightArrow else: " "
    let line = selectionSymbol & " " & directory.name

    tb.write(x, currentY, line)

  return currentY + 1

proc renderSourceDirectories(tb: var TerminalBuffer, x: int, y: int): int =
  var nextY = y
  let bgColor = if state.focus == SourceSelection: BackgroundColor.bgGreen else:BackgroundColor.bgWhite
  tb.setBackgroundColor(bgColor)
  tb.setForegroundColor(ForegroundColor.fgBlack)
  tb.write(x, nextY, " Source directory")
  tb.resetAttributes()
  nextY = tb.renderDirectories(state.sourceSubDirectories, x, nextY)
  inc nextY
  return nextY

proc renderDestinationDirectories(tb: var TerminalBuffer, x: int, y: int): int =
  var nextY = y
  let bgColor = if state.focus == DestinationSelection: BackgroundColor.bgGreen else:BackgroundColor.bgWhite
  tb.setBackgroundColor(bgColor)
  tb.setForegroundColor(ForegroundColor.fgBlack)
  tb.write(x, nextY, " Destination directory")
  tb.resetAttributes()
  nextY = tb.renderDirectories(state.destinationSubDirectories, rightColumnX, nextY)
  inc nextY
  return nextY

proc renderSourceFiles(tb: var TerminalBuffer, x: int, y: int): int =
  var nextY = y

  let bgColor = if state.focus == FileSelection: BackgroundColor.bgGreen else:BackgroundColor.bgWhite
  tb.setBackgroundColor(bgColor)
  tb.setForegroundColor(ForegroundColor.fgBlack)

  tb.write(2, nextY, " Files ")
  inc nextY
  nextY = tb.renderFiles(state.filteredSourceFiles, 2, nextY)
  tb.resetAttributes()
  return nextY

proc render() =
  var tb = newTerminalBuffer(terminalWidth(), terminalHeight())

  tb.setForegroundColor(ForegroundColor.fgYellow)
  tb.drawRect(0, 0, tb.width-1, tb.height-1)

  var nextY: int = 1
  nextY = tb.renderFilter(1, nextY)
  discard tb.renderDestinationDirectories(rightColumnX, nextY)

  nextY = renderSourceDirectories(tb, 2, nextY)
  nextY = renderSourceFiles(tb, 2, nextY)

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

