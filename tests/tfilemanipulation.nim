from ../src/filemanipulation import formatIndex, filter, Entries, Entry

import unittest

func entry(filename: string): Entry =
  return Entry(name: filename,
               path: filename,
               selected: false
  )

suite "filemanipulation":

  test "format numbers":
    assert formatIndex(42)  == "  42"

suite "filtering":
  test "Files with searched character must pass through filter":
    let entries : Entries = (@[entry("aaa"), entry("bbb")], @[entry("ccc"), entry("ddd")])
    let expected : Entries = (@[entry("aaa")], @[])
    assert filter(entries, "a") == expected

  test "Directories with searched character must pass through filter":
    let entries : Entries = (@[entry("aaa"), entry("bbb")], @[entry("ccc"), entry("ddd")])
    let expected : Entries = (@[], @[entry("ddd")])
    assert filter(entries, "d") == expected

  test "Files with 2 non consecutives searched characters must pass through filter":
    let entries : Entries = (@[entry("abc"), entry("bbb")], @[entry("ccc"), entry("eee")])
    let expected : Entries = (@[entry("abc")], @[])
    assert filter(entries, "ac") == expected

  test "Directories with 2 non consecutives searched characters must pass through filter":
    let entries : Entries = (@[entry("silk"), entry("selenium")], @[entry("silence"), entry("steel")])
    let expected : Entries = (@[], @[entry("silence")])
    assert filter(entries, "ien") == expected

  test "filtering works both on files and directories":
    let entries : Entries = (@[entry("silk"), entry("selenium"), entry("silently")], @[entry("silence"), entry("steel")])
    let expected : Entries = (@[entry("silently")], @[entry("silence")])
    assert filter(entries, "ien") == expected

  test "filtering returns all when search string is empty":
    let entries : Entries = (@[entry("silk"), entry("selenium"), entry("silently")], @[entry("silence"), entry("steel")])
    let expected : Entries = (@[entry("silk"), entry("selenium"), entry("silently")], @[entry("silence"), entry("steel")])
    assert filter(entries, "") == expected

  test "filtering empty lists returns empty lists":
    let entries : Entries = (@[], @[])
    let expected : Entries = (@[], @[])
    assert filter(entries, "a") == expected

  test "filtering retrieves lowercase letters into uppercase strings":
    let entries : Entries = (@[entry("SILKY"), entry("SELENIUM"), entry("SILENTLY")], @[entry("SILENCE"), entry("STEEL"), entry("SILLY")])
    let expected : Entries = (@[entry("SILKY"), entry("SILENTLY")], @[entry("SILLY")])
    assert filter(entries, "sly") == expected

  test "filtering retrieves uppercase letters into lowercase strings":
    let entries : Entries = (@[entry("silky"), entry("selenium"), entry("silently")], @[entry("silence"), entry("steel"), entry("silly")])
    let expected : Entries = (@[entry("silky"), entry("silently")], @[entry("silly")])
    assert filter(entries, "SLY") == expected

  test "filtering ignores diacritics in file names":
    let entries : Entries = (@[entry("Bibliothè̀que"), entry("Applications")], @[entry("Work"), entry("près"), entry("Hack")])
    let expected : Entries = (@[entry("Bibliothè̀que")], @[entry("près")])
    let actual = filter(entries, "e")
    assert actual == expected, $actual

  test "filtering ignores diacritics in search string":
      let entries : Entries = (@[entry("Bibliothè̀que"), entry("Applications")], @[entry("Work"), entry("près"), entry("Hack")])
      let expected : Entries = (@[entry("Applications")], @[entry("Hack")])
      let actual = filter(entries, "à")
      assert actual == expected, $actual