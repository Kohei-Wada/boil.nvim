local M = {}

---Parse command arguments to extract template path and runtime variables
---@param args_list string[] List of command arguments
---@return string|nil template_path Template path if specified
---@return table<string, string> runtime_vars Runtime variables as key-value pairs
M.parse_args = function(args_list)
  local template_path = nil
  local runtime_vars = {}

  for _, arg in ipairs(args_list) do
    -- Check if argument contains '=' (runtime variable)
    local key, value = arg:match "^([^=]+)=(.*)$"
    if key and value then
      -- Remove outer quotes if present
      if value:match '^".*"$' or value:match "^'.*'$" then
        value = value:sub(2, -2)
      end
      runtime_vars[key] = value
    else
      -- First non-variable argument is template path
      if not template_path and not arg:match "=" then
        template_path = arg
      end
    end
  end

  return template_path, runtime_vars
end

return M
