local M = {}

---Parse command-line arguments for telescope
---@param args_string string|nil Raw argument string from telescope command
---@return table runtime_vars Parsed runtime variables
M.parse_command_args = function(args_string)
  local runtime_vars = {}

  if not args_string or args_string == "" then
    return runtime_vars
  end

  -- Split args_string into individual arguments
  local args = {}
  for arg in args_string:gmatch "%S+" do
    table.insert(args, arg)
  end

  -- Use utils.parse_args but ignore template_path since telescope handles template selection via UI
  local utils = require "boil.utils"
  local _, parsed_runtime_vars = utils.parse_args(args)

  return parsed_runtime_vars
end

return M
