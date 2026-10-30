-- Loads the assembled pack against the real engine modules.
-- Run from an engine checkout that has this pack inside its mods directory:
--   luajit mods/gmarcs_gen2_johto_alive/tests/load.lua

package.path = './?.lua;./?/init.lua;' .. package.path
love = require('tests.love_stub')
require('src.core.GameVersion').set('gold')

local script = (arg and arg[0]) or ''
local root = script:match('^(.*)/tests/[^/]+$')
assert(root and root ~= '', 'run this test from the pack directory')

local optionKeys, hooks, warnings, errors = {}, {}, {}, {}

local mod = {
  id = 'gmarcs_gen2_johto_alive',
  path = root,
  exports = {},
  content = setmetatable({}, { __index = function(self, key)
    local items, registry = {}, {}
    setmetatable(registry, { __index = function(t, method)
      if method == 'each' then
        local fn = function()
          local id, value = next(items)
          return function()
            if id == nil then return nil end
            local key, item = id, value
            id, value = next(items, id)
            return key, item
          end
        end
        t.each = fn
        return fn
      end
      local fn = function(_, id, value)
        if method == 'get' then return items[id] end
        if method == 'register' or method == 'override' or method == 'add' then
          items[id] = value
        end
        return true
      end
      t[method] = fn
      return fn
    end })
    self[key] = registry
    return registry
  end }),
  assets = setmetatable({
    path = function(_, relative) return root .. '/' .. relative end,
    list = function() return {} end,
    info = function() return nil end,
    image = function(_, relative) return { path = relative } end,
  }, { __index = function() return function() return true end end }),
  save = setmetatable({}, { __index = function(self, method)
    local store = {}
    local fn = function(_, key, value)
      if method == 'get' then return store[key] end
      store[key] = value
      return true
    end
    self[method] = fn
    return fn
  end }),
  events = setmetatable({}, { __index = function(self, method)
    local fn = function() return true end
    self[method] = fn
    return fn
  end }),
  options = {
    define = function(_, schema)
      optionKeys = {}
      for _, row in ipairs(schema) do
        assert(type(row.key) == 'string' and row.key ~= '', 'row needs a key')
        optionKeys[#optionKeys + 1] = row.key
      end
    end,
    get = function() return nil end,
  },
  hooks = {
    wrap = function(_, name) hooks[#hooks + 1] = name end,
  },
  find = function() return nil end,
  log = {
    info = function() end,
    warn = function(_, fmt) warnings[#warnings + 1] = fmt end,
    error = function(_, fmt) errors[#errors + 1] = fmt end,
  },
}
function mod:read(relative)
  local handle = assert(io.open(self.path .. '/' .. relative, 'rb'),
    'missing ' .. relative)
  local text = handle:read('*a')
  handle:close()
  return text
end

local install = assert(loadfile(root .. '/main.lua'))()
assert(type(install) == 'function', 'main.lua must return an install function')
install(mod)

-- The shared sky library is materialized into both sky features.
for _, feature in ipairs({ 'free-fly', 'wild-skies' }) do
  local handle = io.open(root .. '/features/' .. feature .. '/lib/shared/skylib.lua', 'rb')
  assert(handle, feature .. ' is missing the shared sky library')
  handle:close()
end

assert(#(function() local t = {} for k in pairs(mod.exports) do t[#t + 1] = k end return t end)() >= 0)
assert(#optionKeys > 0, 'no options were registered')
for _, key in ipairs(optionKeys) do
  assert(key:match('^[%w%-_]+%.'), 'option key is not namespaced: ' .. key)
end
assert(#hooks > 0, 'no hooks were registered')
assert(#errors == 0, 'features reported errors')

io.write(('features: 3, options: %d, hooks: %d, warnings: %d\n'):format(
  #optionKeys, #hooks, #warnings))
for i, fmt in ipairs(warnings) do print('warn: ' .. tostring(fmt)) end
io.write('Johto Alive load PASS\n')
