import illwill
import system
import std/os
import std/strformat
import std/unicode
import modules/[entry, file]

const checkSymbol = $Rune(0x2705)
const rightArrow = $Rune(0x2794)
const folder = $Rune(0x1F4C1)

type View = enum
  Home, SourceSelection

type
  State = object
    filteredFiles: seq[Entry] # the files in the current source dir matching the current filter
    sourceSubDirectories: seq[Entry] # the directories into the current source directory
    view: View # the visible screen
    sourceDirectoryPath: string

var state = State(
    view: Home,
    sourceDirectoryPath: getHomeDir()
  )

proc exitProc() {.noconv.} =
  illwillDeinit()
  showCursor()
  quit(0)

proc loadCurrentDirectoryContent() =
  state.sourceSubDirectories = file.getSubDirectories(state.sourceDirectoryPath)
  let files = file.getFiles(state.sourceDirectoryPath) # factorize
  state.filteredFiles = filter(files, "") # TODO: read filter value from stdin

proc init() =
  illwillInit(fullscreen = true)
  setControlCHook(exitProc)
  hideCursor()
  loadCurrentDirectoryContent()

proc update() =
  var key = getKey()
  case key
  of Key.Down:
    case state.view
    of Home:
      state.sourceSubDirectories = entry.selectNext(state.sourceSubDirectories)
    else:
      discard
  of Key.Up:
    case state.view
    of Home:
      state.sourceSubDirectories = entry.selectPrevious(
          state.sourceSubDirectories)
    else:
      discard
  of Key.Enter:
    case state.view
      of Home:
        state.sourceDirectoryPath = file.getSelectedDirectoryPath(
            state.sourceDirectoryPath, state.sourceSubDirectories)
        loadCurrentDirectoryContent()
      else:
        discard
  of Key.Escape:
    if state.view == Home:
      exitProc()
    else:
      state.view = Home
  of Key.Q:
    exitProc()
  else:
    discard

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


proc getDirectorySelectionSymbol*(entry: Entry): string =
  # width is the max number of digits for the index value; for example if the list contains 10 to 99 items, it's 2
  result = if entry.selected: rightArrow else: " "

proc renderFile(tb: var TerminalBuffer, entries: seq[Entry], x: int, y: int): int =

  var currentY = y

  let maxDigitsForIndex = ($len(entries)).len
  for index, entry in entries:
    currentY = currentY + 1
    if entry.selected:
      tb.setBackgroundColor(BackgroundColor.bgBlack)
      tb.setForegroundColor(ForegroundColor.fgBlue, bright = true)
    else:
      tb.resetAttributes()
    let line = formatIndex(index + 1, maxDigitsForIndex) & " " & entry.name
    tb.write(x, currentY, line)

  return currentY + 1

proc renderDirectory(tb: var TerminalBuffer, entries: seq[Entry], x: int, y: int): int =

  var currentY = y

  let maxDigitsForIndex = ($len(entries)).len
  for index, entry in entries:
    currentY = currentY + 1
    if entry.selected:
      tb.setBackgroundColor(BackgroundColor.bgBlack)
      tb.setForegroundColor(ForegroundColor.fgBlue, bright = true)
    else:
      tb.resetAttributes()
    let line = getDirectorySelectionSymbol(entry) & " " & folder & " " & entry.name

    tb.write(x, currentY, line)

  return currentY + 1


proc render() =
  var tb = newTerminalBuffer(terminalWidth(), terminalHeight())

  let rightColumnX = int(terminalWidth() / 2)

  tb.fill(0, 0, terminalWidth() - 1, terminalHeight() - 1, " ")

  tb.setForegroundColor(ForegroundColor.fgYellow)
  tb.drawRect(0, 0, tb.width-1, tb.height-1)

  tb.setBackgroundColor(BackgroundColor.bgWhite)
  tb.setForegroundColor(ForegroundColor.fgBlack)
  tb.write(rightColumnX, 1, " Destination ")

  tb.setBackgroundColor(BackgroundColor.bgGreen)
  tb.setForegroundColor(ForegroundColor.fgBlack)
  tb.write(2, 1, " Source directory ")
  var nextY = tb.renderDirectory(state.sourceSubDirectories, 2, 2)

  inc nextY
  tb.setBackgroundColor(BackgroundColor.bgGreen)
  tb.setForegroundColor(ForegroundColor.fgBlack)
  tb.write(2, nextY, " Files ")
  inc nextY
  discard tb.renderFile(state.filteredFiles, 2, nextY)

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

