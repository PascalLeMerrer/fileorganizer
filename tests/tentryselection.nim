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