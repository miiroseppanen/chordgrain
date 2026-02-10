-- grid_backend.lua: normalize grid transport and LED flush behavior

local GridBackend = {}

local device = nil
local on_key = nil

local function safe_method(obj, method, ...)
  if not obj or not obj[method] then
    return false, nil
  end
  return pcall(obj[method], obj, ...)
end

function GridBackend.connect(key_handler)
  on_key = key_handler
  if not grid or not grid.connect then
    device = nil
    return nil
  end

  local ok, g = pcall(grid.connect)
  if not ok then
    device = nil
    return nil
  end

  device = g
  if device and on_key then
    device.key = function(x, y, z)
      on_key(device, x, y, z)
    end
  end
  return device
end

function GridBackend.reconnect()
  return GridBackend.connect(on_key)
end

function GridBackend.get_device()
  return device
end

function GridBackend.render(render_fn, s)
  if not device or not render_fn or not s then
    return
  end
  render_fn(device, s)
  safe_method(device, "refresh")
end

function GridBackend.clear()
  if not device then return end
  safe_method(device, "all", 0)
  safe_method(device, "refresh")
end

function GridBackend.disconnect()
  GridBackend.clear()
  device = nil
end

return GridBackend
