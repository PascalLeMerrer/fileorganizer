from ../src/filemanipulation import formatIndex, filter, Entries

import unittest

suite "filemanipulation":

  test "format numbers":
    assert formatIndex(42)  == "  42"

suite "filtering":
  test "Files with searched character must pass through filter":
    let entries : Entries = (@["aaa", "bbb"], @["ccc", "ddd"])
    let expected : Entries = (@["aaa"], @[])
    assert filter(entries, "a") == expected

  test "Directories with searched character must pass through filter":
    let entries : Entries = (@["aaa", "bbb"], @["ccc", "ddd"])
    let expected : Entries = (@[], @["ddd"])
    assert filter(entries, "d") == expected

  test "Files with 2 non consecutives searched characters must pass through filter":
    let entries : Entries = (@["abc", "bbb"], @["ccc", "eee"])
    let expected : Entries = (@["abc"], @[])
    assert filter(entries, "ac") == expected

  test "Directories with 2 non consecutives searched characters must pass through filter":
    let entries : Entries = (@["silk", "selenium"], @["silence", "steel"])
    let expected : Entries = (@[], @["silence"])
    assert filter(entries, "ien") == expected

  test "filtering works both on files and directories":
    let entries : Entries = (@["silk", "selenium", "silently"], @["silence", "steel"])
    let expected : Entries = (@["silently"], @["silence"])
    assert filter(entries, "ien") == expected

  test "filtering returns all when search string is empty":
    let entries : Entries = (@["silk", "selenium", "silently"], @["silence", "steel"])
    let expected : Entries = (@["silk", "selenium", "silently"], @["silence", "steel"])
    assert filter(entries, "") == expected

  test "filtering empty lists returns empty lists":
    let entries : Entries = (@[], @[])
    let expected : Entries = (@[], @[])
    assert filter(entries, "a") == expected

  test "filtering retrieves lowercase letters into uppercase strings":
    let entries : Entries = (@["SILKY", "SELENIUM", "SILENTLY"], @["SILENCE", "STEEL", "SILLY"])
    let expected : Entries = (@["SILKY", "SILENTLY"], @["SILLY"])
    assert filter(entries, "sly") == expected

  test "filtering retrieves uppercase letters into lowercase strings":
    let entries : Entries = (@["silky", "selenium", "silently"], @["silence", "steel", "silly"])
    let expected : Entries = (@["silky", "silently"], @["silly"])
    assert filter(entries, "SLY") == expected

  test "search string not found returns empty results":
    let entries : Entries = (@["silky", "selenium", "silently"], @["silence", "steel", "silly"])
    let expected : Entries = (@[], @[])
    assert filter(entries, "ABC") == expected
