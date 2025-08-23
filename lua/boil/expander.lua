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

---Evaluate a variable value (execute if function, convert to string if not)
---@param key string Variable name
---@param value any Variable value (function or string)
---@param errors table Array to collect error messages
---@return string replacement The evaluated replacement string
local function evaluate_variable(key, value, errors)
  if type(value) == "function" then
    local ok, ret = pcall(value)
    if ok then
      return ret or ""
    else
      table.insert(errors, string.format("Variable '%s' function failed: %s", key, ret))
      return "{{" .. key .. ":ERROR}}"
    end
  else
    return tostring(value)
  end
end

---Apply indentation to lines
---@param lines table Array of lines
---@param indent string Indentation string to apply
---@return table indented_lines Lines with indentation applied
local function apply_indentation(lines, indent)
  local indented_lines = {}
  for _, line in ipairs(lines) do
    table.insert(indented_lines, indent .. line)
  end
  return indented_lines
end

---Replace multi-line variable with proper indentation
---@param result string Template content
---@param pattern string Pattern to match (escaped variable placeholder)
---@param replacement string Multi-line replacement text
---@return string result Modified template content
---@return boolean replaced Whether any replacement was made
local function replace_multiline_variable(result, pattern, replacement)
  local replaced = false
  local lines = nil -- Lazy initialization to avoid duplicate vim.split calls

  -- Helper function to get lines, splitting only once
  local function get_lines()
    if not lines then
      lines = vim.split(replacement, "\n", { plain = true })
    end
    return lines
  end

  -- Check if the placeholder appears with indentation (at line start after newline)
  local indented_pattern = "(\n%s*)" .. pattern
  result = result:gsub(indented_pattern, function(prefix)
    replaced = true
    local indent = prefix:match "\n(%s*)"
    local indented_lines = apply_indentation(get_lines(), indent)
    return "\n" .. table.concat(indented_lines, "\n")
  end)

  -- Handle the case where the placeholder is at the beginning of the file with indentation
  local start_pattern = "^(%s+)" .. pattern
  result = result:gsub(start_pattern, function(indent)
    replaced = true
    local indented_lines = apply_indentation(get_lines(), indent)
    return table.concat(indented_lines, "\n")
  end)

  return result, replaced
end

---Replace single-line variable
---@param result string Template content
---@param pattern string Pattern to match (escaped variable placeholder)
---@param replacement string Single-line replacement text
---@return string result Modified template content
local function replace_single_line_variable(result, pattern, replacement)
  return result:gsub(pattern, escape_replacement(replacement))
end

---Check for unexpanded variables in the result
---@param result string Expanded template content
---@return table unexpanded Array of unexpanded variable names
local function check_unexpanded_variables(result)
  local unexpanded = {}
  for match in result:gmatch "{{([^}]+)}}" do
    if not match:match ":ERROR$" then
      table.insert(unexpanded, match)
    end
  end
  return unexpanded
end

---Expand variables in template content
---@param template_content string Template content with {{variable}} placeholders
---@param variables table<string, any> Merged variables to use for expansion
---@return string|nil expanded_content Content with variables expanded
---@return string|nil error_message Error message if expansion failed
M.expand = function(template_content, variables)
  local result = template_content
  local errors = {}

  -- Process all variables uniformly
  for key, value in pairs(variables) do
    local pattern = "{{" .. vim.pesc(key) .. "}}"

    -- Evaluate the variable value
    local replacement = evaluate_variable(key, value, errors)

    -- Handle replacement based on content type
    if replacement:find "\n" then
      -- Multi-line replacement with indentation handling
      local new_result, replaced = replace_multiline_variable(result, pattern, replacement)
      result = new_result

      -- If no indented replacements were made, do a simple replacement
      if not replaced then
        result = replace_single_line_variable(result, pattern, replacement)
      end
    else
      -- Single line replacement
      result = replace_single_line_variable(result, pattern, replacement)
    end
  end

  -- Check for unexpanded variables
  local unexpanded = check_unexpanded_variables(result)
  if #unexpanded > 0 then
    table.insert(errors, string.format("Undefined variables: %s", table.concat(unexpanded, ", ")))
  end

  -- Return result with any error messages
  if #errors > 0 then
    return result, table.concat(errors, "\n")
  end

  return result
end

return M
