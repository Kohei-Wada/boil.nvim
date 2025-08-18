local M = {}

require "boil.types"

---Expand variables in template content
---@param template_content string Template content with {{variable}} placeholders
---@param config Config Global configuration
---@param template_config? TemplateConfig Template-specific configuration
---@return string|nil expanded_content Content with variables expanded
---@return string|nil error_message Error message if expansion failed
M.expand = function(template_content, config, template_config)
  local result = template_content
  local errors = {}

  -- Merge variables: global < template-specific
  local variables = vim.tbl_extend("force", {}, config.variables or {})
  if template_config and template_config.variables then
    variables = vim.tbl_extend("force", variables, template_config.variables)
  end

  -- Process all variables uniformly
  for key, value in pairs(variables) do
    local pattern = "{{" .. key .. "}}"
    local replacement

    if type(value) == "function" then
      local ok, ret = pcall(value)
      if ok then
        replacement = ret or ""
      else
        table.insert(errors, string.format("Variable '%s' function failed: %s", key, ret))
        replacement = "{{" .. key .. ":ERROR}}"
      end
    else
      replacement = tostring(value)
    end

    result = result:gsub(pattern, replacement)
  end

  -- Check for unexpanded variables
  local unexpanded = {}
  for match in result:gmatch "{{([^}]+)}}" do
    if not match:match ":ERROR$" then
      table.insert(unexpanded, match)
    end
  end

  if #unexpanded > 0 then
    table.insert(errors, string.format("Undefined variables: %s", table.concat(unexpanded, ", ")))
  end

  if #errors > 0 then
    return result, table.concat(errors, "\n")
  end

  return result
end

return M
