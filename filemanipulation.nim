import illwill
import std/os
import system
import modules/[entry, file]

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

proc loadCurrentDirectoryContent()=
  state.sourceSubDirectories = file.getSubDirectories(state.sourceDirectoryPath)
  let files = file.getFiles(state.sourceDirectoryPath) # factorize
  state.filteredFiles = filter(files, "è")

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
        state.sourceDirectoryPath = file.getSelectedDirectoryPath(state.sourceDirectoryPath, state.sourceSubDirectories)
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

proc render() =
  var tb = newTerminalBuffer(terminalWidth(), terminalHeight())

  let rightColumnX = int(terminalWidth() / 2)
  tb.fill(0,0, terminalWidth() - 1, terminalHeight() - 1, " ")
  tb.setForegroundColor(ForegroundColor.fgYellow)
  tb.drawRect(0, 0, tb.width-1, tb.height-1)

  tb.setBackgroundColor(BackgroundColor.bgWhite)
  tb.setForegroundColor(ForegroundColor.fgBlack)
  tb.write(rightColumnX, 1, " Destination ")

  tb.setBackgroundColor(BackgroundColor.bgGreen)
  tb.setForegroundColor(ForegroundColor.fgBlack)
  tb.write(2, 1, " Source directory ")
  var nextY = entry.renderDirectory(state.sourceSubDirectories, tb, 2, 2)

  inc nextY
  tb.setBackgroundColor(BackgroundColor.bgGreen)
  tb.setForegroundColor(ForegroundColor.fgBlack)
  tb.write(2, nextY, " Files ")
  inc nextY
  discard entry.renderFile(state.filteredFiles, tb, 2, nextY)

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

