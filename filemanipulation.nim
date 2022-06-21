import illwill
import system
import std/os
import std/strformat
import std/unicode
import modules/[entry, file]

const checkSymbol = $Rune(0x2705)
const rightArrow = $Rune(0x2192)

type View = enum
  SourceSelection, Filtering

type
  PressedKey =
    tuple[code: int, name: string]

type
  State = object
    filter: string
    filteredFiles: seq[Entry] # the files in the current source dir matching the current filter
    sourceSubDirectories: seq[Entry] # the directories into the current source directory
    focus: View # the part of the screen with the focus
    sourceDirectoryPath: string


var state = State(
    filter: "",
    focus: SourceSelection,
    sourceDirectoryPath: getHomeDir()
  )

proc exitProc() {.noconv.} =
  illwillDeinit()
  showCursor()
  quit(0)

proc loadCurrentDirectoryContent() =
  let sourceSubDirectories = file.getSubDirectories(state.sourceDirectoryPath)
  state.sourceSubDirectories = filter(sourceSubDirectories, state.filter)
  if not entry.isAnySelected(state.sourceSubDirectories):
    # the .. entry is excluded of selection
    state.sourceSubDirectories = entry.selectFirst(state.sourceSubDirectories)
  let files = file.getFiles(state.sourceDirectoryPath)
  state.filteredFiles = filter(files, state.filter)

proc focusNextZone() =
  case state.focus
  of SourceSelection:
    state.focus = Filtering
  of Filtering:
    state.focus = SourceSelection

proc init() =
  illwillInit(fullscreen = true)
  setControlCHook(exitProc)
  hideCursor()
  loadCurrentDirectoryContent()

proc updateHomeView() =
    let key = getKey()
    case key
    of Key.Down:
      state.sourceSubDirectories = entry.selectNext(state.sourceSubDirectories)
    of Key.Up:
      state.sourceSubDirectories = entry.selectPrevious(state.sourceSubDirectories)
    of Key.Enter:
      state.sourceDirectoryPath = file.getSelectedDirectoryPath(
          state.sourceDirectoryPath, state.sourceSubDirectories)
      loadCurrentDirectoryContent()
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
  of SourceSelection:
    updateHomeView()
  of Filtering:
    updateFilteringView()
    loadCurrentDirectoryContent()

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


proc renderFiles(tb: var TerminalBuffer, entries: seq[Entry], x: int, y: int): int =

  var currentY = y

  let maxDigitsForIndex = ($len(entries)).len
  for index, entry in entries:
    inc currentY
    if entry.selected:
      tb.setBackgroundColor(BackgroundColor.bgBlack)
      tb.setForegroundColor(ForegroundColor.fgBlue, bright = true)
    else:
      tb.resetAttributes()
    let line = formatIndex(index + 1, maxDigitsForIndex) & " " & entry.name
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


proc render() =
  var tb = newTerminalBuffer(terminalWidth(), terminalHeight())

  let rightColumnX = int(terminalWidth() / 2)

  tb.setForegroundColor(ForegroundColor.fgYellow)
  tb.drawRect(0, 0, tb.width-1, tb.height-1)

  var nextY: int = 1
  var filter = " Filter: " & state.filter
  if state.focus == Filtering:
    filter.add("|")
  tb.write(2, nextY, filter)
  inc nextY

  tb.setBackgroundColor(BackgroundColor.bgWhite)
  tb.setForegroundColor(ForegroundColor.fgBlack)
  tb.write(rightColumnX, nextY, " Destination ")
  tb.setBackgroundColor(BackgroundColor.bgGreen)
  tb.setForegroundColor(ForegroundColor.fgBlack)
  tb.write(2, nextY, " Source directory")

  nextY = tb.renderDirectories(state.sourceSubDirectories, 2, nextY)

  inc nextY
  tb.setBackgroundColor(BackgroundColor.bgGreen)
  tb.setForegroundColor(ForegroundColor.fgBlack)
  tb.write(2, nextY, " Files ")
  inc nextY
  discard tb.renderFiles(state.filteredFiles, 2, nextY)

  tb.resetAttributes()
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

