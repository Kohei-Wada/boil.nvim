local telescope = require "telescope"

-- Import boil telescope modules
local config = require "boil.telescope.config"
local args = require "boil.telescope.args"
local picker = require "boil.telescope.picker"

---Main picker function with runtime variables support
---@param opts table Picker options including runtime_vars
local function boil_picker(opts)
  opts = opts or {}

  -- Merge configuration
  local merged_opts, runtime_vars = config.merge_config(opts)
  merged_opts.runtime_vars = runtime_vars

  -- Create and display picker
  picker.create_picker(merged_opts)
end

---Command-style picker for telescope command interface
---@param args_string string Raw argument string from telescope command
local function boil_command_picker(args_string)
  local runtime_vars = args.parse_command_args(args_string)
  boil_picker { runtime_vars = runtime_vars }
end

return telescope.register_extension {
  setup = function(user_ext_config, telescope_config)
    -- Setup configuration module
    config.setup(user_ext_config)
  end,
  exports = {
    boil = function(opts)
      -- If called with string argument (from command), parse it
      if type(opts) == "string" then
        boil_command_picker(opts)
      else
        -- If called with table opts (from Lua), use directly
        boil_picker(opts or {})
      end
    end,
  },
}
