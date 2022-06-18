import std/strutils
import std/unittest

from ../modules/entry import Entry, Entries, filter, formatIndex, select, selectNext

func e(filename: string, selected:bool=false): Entry =
  return Entry(name: filename,
               path: filename,
               selected: selected
  )

suite "formatting":
  test "format index takes in account the max len":
    check(formatIndex(4, 1)  == "4")
    check(formatIndex(42, 2)  == "42")
    check(formatIndex(42, 3)  == " 42")
    check(formatIndex(42, 4)  == "  42")
    check(formatIndex(42, 5)  == "   42")
    check(formatIndex(123456, 6)  == "123456")

suite "filtering":
  test "Files with searched character must pass through filter":
    let entries : Entries = (@[e("aaa"), e("bbb")], @[e("ccc"), e("ddd")])
    let expected : Entries = (@[e("aaa")], @[])
    check(filter(entries, "a") == expected)

  test "Directories with searched character must pass through filter":
    let entries : Entries = (@[e("aaa"), e("bbb")], @[e("ccc"), e("ddd")])
    let expected : Entries = (@[], @[e("ddd")])
    check(filter(entries, "d") == expected)

  test "Files with 2 non consecutives searched characters must pass through filter":
    let entries : Entries = (@[e("abc"), e("bbb")], @[e("ccc"), e("eee")])
    let expected : Entries = (@[e("abc")], @[])
    check(filter(entries, "ac") == expected)

  test "Directories with 2 non consecutives searched characters must pass through filter":
    let entries : Entries = (@[e("silk"), e("selenium")], @[e("silence"), e("steel")])
    let expected : Entries = (@[], @[e("silence")])
    check(filter(entries, "ien") == expected)

  test "filtering works both on files and directories":
    let entries : Entries = (@[e("silk"), e("selenium"), e("silently")], @[e("silence"), e("steel")])
    let expected : Entries = (@[e("silently")], @[e("silence")])
    check(filter(entries, "ien") == expected)

  test "filtering returns all when search string is empty":
    let entries : Entries = (@[e("silk"), e("selenium"), e("silently")], @[e("silence"), e("steel")])
    let expected : Entries = (@[e("silk"), e("selenium"), e("silently")], @[e("silence"), e("steel")])
    check(filter(entries, "") == expected)

  test "filtering empty lists returns empty lists":
    let entries : Entries = (@[], @[])
    let expected : Entries = (@[], @[])
    check(filter(entries, "a") == expected)

  test "filtering retrieves lowercase letters into uppercase strings":
    let entries : Entries = (@[e("SILKY"), e("SELENIUM"), e("SILENTLY")], @[e("SILENCE"), e("STEEL"), e("SILLY")])
    let expected : Entries = (@[e("SILKY"), e("SILENTLY")], @[e("SILLY")])
    check(filter(entries, "sly") == expected)

  test "filtering retrieves uppercase letters into lowercase strings":
    let entries : Entries = (@[e("silky"), e("selenium"), e("silently")], @[e("silence"), e("steel"), e("silly")])
    let expected : Entries = (@[e("silky"), e("silently")], @[e("silly")])
    check(filter(entries, "SLY") == expected)

  test "filtering ignores diacritics in file names":
    let entries : Entries = (@[e("Bibliothè̀que"), e("Applications")], @[e("Work"), e("près"), e("Hack")])
    let expected : Entries = (@[e("Bibliothè̀que")], @[e("près")])
    let actual = filter(entries, "e")
    check(actual == expected)

  test "filtering ignores diacritics in search string":
      let entries : Entries = (@[e("Bibliothè̀que"), e("Applications")], @[e("Work"), e("près"), e("Hack")])
      let expected : Entries = (@[e("Applications")], @[e("Hack")])
      let actual = filter(entries, "à")
      check(actual == expected)

suite "Entry selection":
  test "Entry may be selected":
    var entry = e("A")
    let actual = select(entry)
    check(actual.selected)

  test "Next entry in a sequence may be selected":
    let entries : seq[Entry] = @[e("aaa"), e("bbb", selected=true), e("ccc"), e("eee")]
    let expected : seq[Entry] = @[e("aaa"), e("bbb"), e("ccc", selected=true), e("eee")]
    check(selectNext(entries) == expected)

  test "First entry in a sequence is selected after the last one when calling selectNext":
    let entries : seq[Entry] = @[e("aaa"), e("bbb"), e("ccc"), e("eee", selected=true)]
    let expected : seq[Entry] = @[e("aaa", selected=true), e("bbb"), e("ccc"), e("eee")]
    check(selectNext(entries) == expected)
