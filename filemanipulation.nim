import illwill
import std/os
import system
import modules/[entry, file]

type View = enum
  Home, SourceSelection

type
  State = object
    filteredEntries: Entries # the file and directories in the current source dir matching the current filter
    sourceSubDirectories : seq[Entry] # the directories into the current source directory
    view : View # the visible screen
    sourceDirectoryPath:string

var state = State(
    view: Home,
    sourceDirectoryPath: getHomeDir()
  )

proc exitProc() {.noconv.} =
  illwillDeinit()
  showCursor()
  quit(0)

proc init() =
  illwillInit(fullscreen=true)
  setControlCHook(exitProc)
  hideCursor()
  let entries = file.getDirectoryContent(state.sourceDirectoryPath)
  state.filteredEntries = filter(entries, "è")

proc update() =
  var key = getKey()
  case key
  of Key.Down:
    case state.view
    of SourceSelection:
      state.sourceSubDirectories = entry.selectNext(state.sourceSubDirectories)
    else:
      discard
  of Key.Up:
    case state.view
    of SourceSelection:
      state.sourceSubDirectories = entry.selectPrevious(state.sourceSubDirectories)
    else:
      discard
  of Key.Enter:
    state.view = Home
    state.sourceDirectoryPath = file.getSelectedDirectoryPath(state.sourceDirectoryPath  ,state.sourceSubDirectories)
    let entries = file.getDirectoryContent(state.sourceDirectoryPath) # factorize
    state.filteredEntries = filter(entries, "è")
  of Key.Escape:
    if state.view == Home:
      exitProc()
    else:
      state.view = Home
  of Key.Q:
    exitProc()
  of Key.S:
    state.view = SourceSelection
    state.sourceSubDirectories = file.getSubDirectories(state.sourceDirectoryPath)
  else:
    discard

proc render() =
  var tb = newTerminalBuffer(terminalWidth(), terminalHeight())
  let rightColumnX = int(terminalWidth() / 2)

  tb.setForegroundColor(ForegroundColor.fgYellow)
  tb.drawRect(0, 0, tb.width-1, tb.height-1)

  tb.setBackgroundColor(BackgroundColor.bgWhite)
  tb.setForegroundColor(ForegroundColor.fgBlack)
  tb.write(1, 1, "Source")
  tb.write(rightColumnX, 1, "Destination")

  tb.resetAttributes()
  case state.view
  of Home:
    entry.render(state.filteredEntries, tb, 1)
  of SourceSelection:
    entry.render((@[], state.sourceSubDirectories), tb, 1)

  tb.write(1, tb.height - 2, "Press Q, Esc or Ctrl-C to quit")

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

