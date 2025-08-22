local telescope = require "telescope"

-- Import boil telescope modules
local config = require "boil.telescope.config"
local picker = require "boil.telescope.picker"
local utils = require "boil.utils"

return telescope.register_extension {
  setup = function(user_ext_config, telescope_config)
    -- Setup configuration module
    config.setup(user_ext_config)
  end,
  exports = {
    boil = function(telescope_vars)
      local runtime_vars = telescope_vars or {}

      -- unescape and parse runtime variables
      for key, value in pairs(runtime_vars) do
        if type(value) == "string" then
          runtime_vars[key] = utils.unescape_string(value)
        end
      end

      local opts = {
        runtime_vars = runtime_vars,
      }

      local merged_opts = config.merge_config(opts)
      picker.create_picker(merged_opts)
    end,
  },
}
