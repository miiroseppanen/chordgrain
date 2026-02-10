# Safe cleanup patch for norns script.lua

If you see `attempt to call a nil value (field 'cleanup')` when loading chordgrain (or any script), norns is calling `cleanup()` when it is still nil. That can happen on the **first script load after boot** or when the previous script did not define `cleanup`.

**File on norns:** `/home/we/norns/lua/core/script.lua`

**Change:** At the start of `Script.clear`, set a safe default *before* calling the old cleanup, and only call the old value if it is a function.

**Find this block** (near the top of `Script.clear`, right after `_norns.free_engine()`):

```lua
  if cleanup ~= nil then
    local ok, err
    ok, err = pcall(cleanup)
    if not ok then
      print("### cleanup failed with error: "..err)
    end
  end
```

**Replace it with:**

```lua
  local old_cleanup = cleanup
  cleanup = norns.none
  if type(old_cleanup) == "function" then
    local ok, err = pcall(old_cleanup)
    if not ok then
      print("### cleanup failed with error: " .. tostring(err))
    end
  end
```

So: save the current `cleanup`, set `cleanup` to a no-op immediately, then call the saved value only if it is a function. That way the next time `cleanup` is read it is never nil, and you never call a nil value.

You can apply this on the device via Maiden (edit the file and save) or over SSH. Restart matron or reboot norns after editing.
