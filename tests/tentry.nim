suite "Entry selection":
  test "Entry may be selected":
    var myEntry = e("A")
    let actual = entry.select(myEntry)
    check(actual.selected)

  test "Sequence of entries may be reversed":
    let entries : seq[Entry] = @[e("a"), e("b"), e("c"), e("d")]
    let expected : seq[Entry] = @[e("d"), e("c"), e("b"), e("a")]
    check(entry.reverse(entries) == expected)

  test "Next entry in a sequence may be selected":
    let entries : seq[Entry] = @[e("a"), e("b", selected=true), e("c"), e("d")]
    let expected : seq[Entry] = @[e("a"), e("b"), e("c", selected=true), e("d")]
    check(entry.selectNext(entries) == expected)

  test "First entry in a sequence is selected after the last one when calling entry.selectNext":
    let entries : seq[Entry] = @[e("a"), e("b"), e("c"), e("d", selected=true)]
    let expected : seq[Entry] = @[e("a", selected=true), e("b"), e("c"), e("d")]
    check(entry.selectNext(entries) == expected)

  test "Previous entry in a sequence may be selected":
    let entries : seq[Entry] = @[e("a"), e("b"), e("c", selected=true), e("d")]
    let expected : seq[Entry] = @[e("a"), e("b", selected=true), e("c"), e("d")]
    check(entry.selectPrevious(entries) == expected)

  test "Last entry in a sequence is selected after the first one when calling selectPRevious":
    let entries : seq[Entry] = @[e("a", selected=true), e("b"), e("c"), e("d")]
    let expected : seq[Entry] = @[e("a"), e("b"), e("c"), e("d", selected=true)]
    check(entry.selectPrevious(entries) == expected)

  test "First entry in a sequence may be selected":
    let entries : seq[Entry] = @[e("a"), e("b"), e("c"), e("d")]
    let expected : seq[Entry] = @[e("a", selected=true), e("b"), e("c"), e("d")]
    check(entry.selectFirst(entries) == expected)

  test "getSelectedItemIndex returns the position of the first selected entry in the sequence":
    let entries : seq[Entry] = @[e("a"), e("b"), e("c", selected=true), e("d")]
    check(entry.getSelectedItemIndex(entries) == 2)

  test "getSelectedItemIndex returns -1 where there is no selected entry in the sequence":
    let entries : seq[Entry] = @[e("a"), e("b"), e("c"), e("d")]
    check(entry.getSelectedItemIndex(entries) == -1)

  test "getSelectedItem returns the first selected entry in the sequence":
    let entries : seq[Entry] = @[e("a"), e("b"), e("c", selected=true), e("d")]
    let expected = e("c", selected=true)
    let actual = entry.getSelectedItem(entries)
    check(actual.isSome)
    check(actual.get() == expected)

  test "getSelectedItem returns null where there is no selected entry in the sequence":
    let entries : seq[Entry] = @[e("a"), e("b"), e("c"), e("d")]
    let actual = entry.getSelectedItem(entries)
    check(actual.isNone)
