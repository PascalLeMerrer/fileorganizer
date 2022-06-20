import illwill
import system
import std/os
import std/strformat
import std/unicode
import modules/[entry, file]

const checkSymbol = $Rune(0x2705)
const rightArrow = $Rune(0x2192)

type View = enum
  Home, Filtering

type
  PressedKey =
    tuple[code: int, name: string]

type
  State = object
    filter: string
    filteredFiles: seq[Entry] # the files in the current source dir matching the current filter
    sourceSubDirectories: seq[Entry] # the directories into the current source directory
    view: View # the visible screen
    sourceDirectoryPath: string


var state = State(
    filter: "",
    view: Home,
    sourceDirectoryPath: getHomeDir()
  )

proc exitProc() {.noconv.} =
  illwillDeinit()
  showCursor()
  quit(0)

proc loadCurrentDirectoryContent() =
  state.sourceSubDirectories = file.getSubDirectories(state.sourceDirectoryPath)
  let files = file.getFiles(state.sourceDirectoryPath)

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
      state.view = Filtering
    else:
      discard


proc updateFilteringView() =
  let key = getKey()

  case key
  of Key.Escape:
    state.view = Home
  of Key.Backspace:
    if state.filter.len > 0:
      state.filter = state.filter[0 .. ^2]
  else:
    if key >= Key.A and key <= Key.Z:
      state.filter.add(($key).toLower())


proc update() =
  case state.view
  of Home:
    updateHomeView()
  of Filtering:
    updateFilteringView()

  let files = file.getFiles(state.sourceDirectoryPath) # factorize
  state.filteredFiles = filter(files, state.filter)



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
  if state.view == Filtering:
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

