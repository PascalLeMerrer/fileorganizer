suite "filtering":
  test "Entries with searched character must pass through filter":
    let entries : seq[Entry] = @[e("c"), e("aaa"), e("bbb"), e("abb")]
    let expected : seq[Entry] = @[e("aaa"), e("abb")]
    check(filter(entries, "a") == expected)

  test "Files with 2 non consecutives searched characters must pass through filter":
    let entries : seq[Entry] = @[e("abc"), e("bbb"), e("cca"), e("eee")]
    let expected : seq[Entry] = @[e("abc")]
    check(filter(entries, "ac") == expected)

  test "filtering returns all when search string is empty":
    let entries : seq[Entry] = @[e("silk"), e("selenium"), e("silently"), e("silence"), e("steel")]
    let expected = entries
    check(filter(entries, "") == expected)

  test "filtering empty list returns empty list":
    let entries : seq[Entry] = @[]
    let expected : seq[Entry] = @[]
    check(filter(entries, "a") == expected)

  test "filtering retrieves lowercase letters into uppercase strings":
    let entries : seq[Entry] = @[e("SILKY"), e("SELENIUM"), e("SILENTLY"), e("SILENCE"), e("STEEL"), e("SILLY")]
    let expected : seq[Entry] = @[e("SILKY"), e("SILENTLY"), e("SILLY")]
    check(filter(entries, "sly") == expected)

  test "filtering retrieves uppercase letters into lowercase strings":
    let entries : seq[Entry] = @[e("silky"), e("selenium"), e("silently"), e("silence"), e("steel"), e("silly")]
    let expected : seq[Entry] = @[e("silky"), e("silently"), e("silly")]
    check(filter(entries, "SLY") == expected)

  test "filtering ignores diacritics in file names":
    let entries : seq[Entry] = @[e("Bibliothè̀que"), e("Applications"), e("Work"), e("près"), e("Hack")]
    let expected : seq[Entry] = @[e("Bibliothè̀que"), e("près")]
    let actual = filter(entries, "e")
    check(actual == expected)

  test "filtering ignores diacritics in search string":
      let entries : seq[Entry] = @[e("Bibliothè̀que"), e("Applications"), e("Work"), e("près"), e("Hack")]
      let expected : seq[Entry] = @[e("Applications"), e("Hack")]
      let actual = filter(entries, "à")
      check(actual == expected)