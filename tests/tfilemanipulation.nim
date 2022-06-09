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
