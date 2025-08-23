local M = {}

require "boil.types"

---Safely escape replacement string for string.gsub
---@param str string String to escape
---@return string escaped_string Safe string for gsub replacement
local function escape_replacement(str)
  -- Escape % characters in replacement string to prevent gsub interpretation
  -- as capture group references
  return (str:gsub("%%", "%%%%"))
end

---Expand variables in template content
---@param template_content string Template content with {{variable}} placeholders
---@param config Config Global configuration
---@param template_config? TemplateConfig Template-specific configuration
---@param runtime_variables? table<string, string> Runtime variables with highest priority
---@return string|nil expanded_content Content with variables expanded
---@return string|nil error_message Error message if expansion failed
M.expand = function(template_content, config, template_config, runtime_variables)
  local result = template_content
  local errors = {}

  -- Merge variables: global < template-specific < runtime
  local variables = vim.tbl_extend("force", {}, config.variables or {})
  if template_config and template_config.variables then
    variables = vim.tbl_extend("force", variables, template_config.variables)
  end
  if runtime_variables then
    variables = vim.tbl_extend("force", variables, runtime_variables)
  end

  -- Process all variables uniformly
  for key, value in pairs(variables) do
    local pattern = "{{" .. vim.pesc(key) .. "}}"
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

    -- Handle multi-line replacements with proper indentation
    if replacement:find "\n" then
      -- Check if the placeholder appears with indentation (at line start)
      local indented_pattern = "(\n%s*)" .. pattern
      local start_pattern = "^(%s+)" .. pattern

      -- Try to replace indented occurrences first
      local replaced = false
      result = result:gsub(indented_pattern, function(prefix)
        replaced = true
        local indent = prefix:match "\n(%s*)"
        local lines = vim.split(replacement, "\n", { plain = true })
        -- Add indentation to the beginning of each line
        local indented_lines = {}
        for _, line in ipairs(lines) do
          table.insert(indented_lines, indent .. line)
        end
        return "\n" .. table.concat(indented_lines, "\n")
      end)

      -- Handle the case where the placeholder is at the beginning of the file with indentation
      result = result:gsub(start_pattern, function(indent)
        replaced = true
        local lines = vim.split(replacement, "\n", { plain = true })
        -- Add indentation to the beginning of each line
        local indented_lines = {}
        for _, line in ipairs(lines) do
          table.insert(indented_lines, indent .. line)
        end
        return table.concat(indented_lines, "\n")
      end)

      -- If no indented replacements were made, do a simple replacement
      if not replaced then
        result = result:gsub(pattern, escape_replacement(replacement))
      end
    else
      -- Single line replacement, use the original method
      result = result:gsub(pattern, escape_replacement(replacement))
    end
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
