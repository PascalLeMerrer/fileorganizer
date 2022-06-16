import std/os
import std/terminal
import std/exitprocs
import system

import modules/[entry, file]

type View = enum
  Home, SourceSelection

let rightColumnX = int(terminalWidth() / 2)

type
  State = object
    view : View

var state = State(
    view: Home
  )

var sourceDirectory = getHomeDir()


proc clearScreen() =
    stdout.eraseScreen()
    stdout.setCursorPos(0,0)



proc exit() =
      stdout.eraseScreen()
      echo "Good bye!\n"
      exitprocs.addExitProc(resetAttributes)
      system.quit()

proc selectSourceDirectory() =
  state.view = SourceSelection
  clearScreen()
  let directories = getSubDirectories(sourceDirectory)
  entry.render((@[], directories))


proc main() =

  clearScreen()
  let entries = getDirectoryContent(sourceDirectory)
  let filteredEntries = filter(entries, "è")
  entry.render(filteredEntries)

  stdout.setCursorPos(rightColumnX,0)
  echo "Destination"

  while true:
    let command = terminal.getch()
    case command

    of 's':
      selectSourceDirectory()
    of 'q':
      exit()
    else:
      echo "'", int(command)  , "'"


when isMainModule:
  main()

