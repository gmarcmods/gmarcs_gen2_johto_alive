-- Voxel library discovery.  Dramatic Shape, the battle-art fork and
-- the Gen 2 Stadium mod publish the same library contract (exports.lib
-- with a require serving the voxel module family) under different mod
-- ids, and future forks will too.  Known ids are preferred for
-- determinism; any other export is admitted by capability, probed on a
-- marker module every member of the family serves.
local M = {}

local KNOWN = { "gmarcs_gen2_voxel_mod", "GEN2_VOXEL", "DRAMATIC_SHAPE", "BATTLE_ART_VOXEL_FORK",
                "STADIUM2_OVERWORLD_MODELS" }

local function libShaped(lib)
  return type(lib) == "table" and type(lib.require) == "function"
end

-- unknown ids must also PROVE the family membership: plenty of mods
-- export a lib.require of their own (Wilds of Kanto does), and the
-- marker module is one every voxel family member serves
local function servesVoxel(lib)
  if not libShaped(lib) then return false end
  local ok, state = pcall(lib.require, "VoxelState")
  return ok and state ~= nil
end

function M.lib(game)
  local exports = game and game.mods and game.mods.exports
  if not exports then return nil end
  for _, id in ipairs(KNOWN) do
    local ex = exports[id]
    local lib = type(ex) == "table" and ex.lib or nil
    if libShaped(lib) then return lib end
  end
  for _, ex in pairs(exports) do
    local lib = type(ex) == "table" and ex.lib or nil
    if servesVoxel(lib) then return lib end
  end
  return nil
end

-- Read native map coordinates only. A renderer probing a roof must never
-- rename a live tileset shared by the engine and other mods.
function M.roofHeight(game,map,cx,cy)
  local lib=M.lib(game)
  if not lib or not map then return nil end
  local ok,scene=pcall(lib.require,'VoxelScene')
  if ok and type(scene)=='table'and type(scene.groundAt)=='function'then
    local got,h=pcall(scene.groundAt,map,cx,cy)
    if got and type(h)=='number'and h==h and h<math.huge and h>=16 then return h end
  end
  -- Older Gen 1 renderers expose shape data but no public ground query.
  local got,h=pcall(function()
    local shapes=lib.require('TileShape')
    local tile=map.cellTile and map:cellTile(cx,cy)
    local s=shapes and shapes.forMap and shapes.forMap(map)[tile]
    if s and s.art~='stair'then return s.h end
  end)
  if got and type(h)=='number'and h==h and h<math.huge and h>=16 then return h end
end

return M
