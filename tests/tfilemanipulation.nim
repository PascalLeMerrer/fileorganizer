from ../src/filemanipulation import formatIndex, filter, Entries, Entry

import unittest

func e(filename: string): Entry =
  return Entry(name: filename,
               path: filename,
               selected: false
  )

suite "fomatting":
  test "format numbers":
    assert formatIndex(42)  == "  42"

suite "filtering":
  test "Files with searched character must pass through filter":
    let entries : Entries = (@[e("aaa"), e("bbb")], @[e("ccc"), e("ddd")])
    let expected : Entries = (@[e("aaa")], @[])
    assert filter(entries, "a") == expected

  test "Directories with searched character must pass through filter":
    let entries : Entries = (@[e("aaa"), e("bbb")], @[e("ccc"), e("ddd")])
    let expected : Entries = (@[], @[e("ddd")])
    assert filter(entries, "d") == expected

  test "Files with 2 non consecutives searched characters must pass through filter":
    let entries : Entries = (@[e("abc"), e("bbb")], @[e("ccc"), e("eee")])
    let expected : Entries = (@[e("abc")], @[])
    assert filter(entries, "ac") == expected

  test "Directories with 2 non consecutives searched characters must pass through filter":
    let entries : Entries = (@[e("silk"), e("selenium")], @[e("silence"), e("steel")])
    let expected : Entries = (@[], @[e("silence")])
    assert filter(entries, "ien") == expected

  test "filtering works both on files and directories":
    let entries : Entries = (@[e("silk"), e("selenium"), e("silently")], @[e("silence"), e("steel")])
    let expected : Entries = (@[e("silently")], @[e("silence")])
    assert filter(entries, "ien") == expected

  test "filtering returns all when search string is empty":
    let entries : Entries = (@[e("silk"), e("selenium"), e("silently")], @[e("silence"), e("steel")])
    let expected : Entries = (@[e("silk"), e("selenium"), e("silently")], @[e("silence"), e("steel")])
    assert filter(entries, "") == expected

  test "filtering empty lists returns empty lists":
    let entries : Entries = (@[], @[])
    let expected : Entries = (@[], @[])
    assert filter(entries, "a") == expected

  test "filtering retrieves lowercase letters into uppercase strings":
    let entries : Entries = (@[e("SILKY"), e("SELENIUM"), e("SILENTLY")], @[e("SILENCE"), e("STEEL"), e("SILLY")])
    let expected : Entries = (@[e("SILKY"), e("SILENTLY")], @[e("SILLY")])
    assert filter(entries, "sly") == expected

  test "filtering retrieves uppercase letters into lowercase strings":
    let entries : Entries = (@[e("silky"), e("selenium"), e("silently")], @[e("silence"), e("steel"), e("silly")])
    let expected : Entries = (@[e("silky"), e("silently")], @[e("silly")])
    assert filter(entries, "SLY") == expected

  test "filtering ignores diacritics in file names":
    let entries : Entries = (@[e("Bibliothè̀que"), e("Applications")], @[e("Work"), e("près"), e("Hack")])
    let expected : Entries = (@[e("Bibliothè̀que")], @[e("près")])
    let actual = filter(entries, "e")
    assert actual == expected, $actual

  test "filtering ignores diacritics in search string":
      let entries : Entries = (@[e("Bibliothè̀que"), e("Applications")], @[e("Work"), e("près"), e("Hack")])
      let expected : Entries = (@[e("Applications")], @[e("Hack")])
      let actual = filter(entries, "à")
      assert actual == expected, $actual
