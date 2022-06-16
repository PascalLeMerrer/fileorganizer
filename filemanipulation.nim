import illwill
import std/[exitprocs, os, strformat, strutils]
import system
import modules/[entry, file]

type View = enum
  Home, SourceSelection


type
  State = object
    view : View
    sourceDirectories : seq[Entry]
    filteredEntries: Entries

var state = State(
    view: Home
  )

var sourceDirectory = getHomeDir()

proc selectSourceDirectory(): seq[Entry] =
  state.view = SourceSelection
  return getSubDirectories(sourceDirectory)


proc exitProc() {.noconv.} =
  illwillDeinit()
  showCursor()
  quit(0)

proc init() =
  illwillInit(fullscreen=true)
  setControlCHook(exitProc)
  hideCursor()
  let entries = getDirectoryContent(sourceDirectory)
  state.filteredEntries = filter(entries, "è")

proc update() =
  var key = getKey()
  case key
  of Key.Escape, Key.Q:
    exitProc()
  of Key.S:
    state.view = SourceSelection
    state.sourceDirectories = selectSourceDirectory()
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
    entry.render((@[], state.sourceDirectories), tb, 1)

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

