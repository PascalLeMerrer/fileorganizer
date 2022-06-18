suite "formatting":
  test "format index takes in account the max len":
    check(formatIndex(4, 1)  == "4")
    check(formatIndex(42, 2)  == "42")
    check(formatIndex(42, 3)  == " 42")
    check(formatIndex(42, 4)  == "  42")
    check(formatIndex(42, 5)  == "   42")
    check(formatIndex(123456, 6)  == "123456")