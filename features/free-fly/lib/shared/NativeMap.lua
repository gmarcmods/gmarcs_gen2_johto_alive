-- Read-only collision view of an unloaded Gen 2 connection neighbor.
local M = {}
function M.neighbor(world, id, Map)
  local def = world.maps and world.maps[id]
  local tileset = def and world.tilesets and world.tilesets[def.tileset]
  if not def or not tileset then return nil end
  local w, h = (def.width or 10) * 2, (def.height or 9) * 2
  return {
    id = id, def = def, widthCells = w, heightCells = h,
    inBounds = function(_, x, y) return x >= 0 and y >= 0 and x < w and y < h end,
    isWalkableCell = function(_, x, y)
      return Map.defIsWalkableCell ~= nil and Map.defIsWalkableCell(def, tileset, x, y) == true
    end,
    isWaterCell = function(_, x, y)
      return Map.defIsWaterCell ~= nil and Map.defIsWaterCell(def, tileset, x, y) == true
    end,
    cellTile = function() return nil end,
  }
end
return M
