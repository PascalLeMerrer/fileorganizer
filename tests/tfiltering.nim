import ../src/filemanipulation

import unittest

suite "filtering":

  test "format numbers":
    assert formatIndex(42)  == "  42"

