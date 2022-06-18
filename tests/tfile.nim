suite "getSelectedDirectoryPath":
  test "concatenates the parent dir path with the selected subdirectory name":
    let subDirectories: seq[Entry] = @[
        e(path="/root/subdir1", filename="subdir1"),
        e(path="/root/subdir2", filename="subdir2", selected=true),
        e(path="/root/subdir3", filename="subdir3")
      ]
    let actualPath = file.getSelectedDirectoryPath("/root", subDirectories)
    check(actualPath == "/root/subdir2")

  test "returns the parent to the parent dir when .. is selected":
    let subDirectories: seq[Entry] = @[
        e(path="/root/dir1/../", filename="..", selected=true),
        e(path="/root/dir1/subdir1", filename="subdir1"),
        e(path="/root/dir1/subdir2", filename="subdir2")
      ]
    let actualPath = file.getSelectedDirectoryPath("/root/dir1", subDirectories)
    check(actualPath == "/root")