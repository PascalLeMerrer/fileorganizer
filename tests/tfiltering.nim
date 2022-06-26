suite "filtering":
  test "Entries with searched subtring must pass through filter":
    let entries : seq[Entry] = @[e("silk"), e("selenium"), e("silently"), e("silence"), e("steel")]
    let expected : seq[Entry] = @[e("selenium"), e("silently"), e("silence")]
    check(filter(entries, "le") == expected)

  test "Entries with all searched substrings must pass through filter":
    let entries : seq[Entry] = @[e("silk"), e("selenium"), e("silently"), e("silence"), e("steel")]
    let expected : seq[Entry] = @[e("silently"), e("silence")]
    check(filter(entries, "si en") == expected)

  test "filtering returns all when search string is empty":
    let entries : seq[Entry] = @[e("silk"), e("selenium"), e("silently"), e("silence"), e("steel")]
    let expected = entries
    check(filter(entries, "") == expected)

  test "filtering empty list returns empty list":
    let entries : seq[Entry] = @[]
    let expected : seq[Entry] = @[]
    check(filter(entries, "a") == expected)

  test "filtering retrieves lowercase letters into uppercase strings":
    let entries : seq[Entry] = @[e("SILK"), e("SELENIUM"), e("SILENTLY"), e("SILENCE"), e("STEEL")]
    let expected : seq[Entry] = @[e("SILENTLY"), e("SILENCE")]
    check(filter(entries, "si en") == expected)

  test "filtering retrieves uppercase letters into lowercase strings":
    let entries : seq[Entry] = @[e("silk"), e("selenium"), e("silently"), e("silence"), e("steel")]
    let expected : seq[Entry] = @[e("silently"), e("silence")]
    check(filter(entries, "SI EN") == expected)

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