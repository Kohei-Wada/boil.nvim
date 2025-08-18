local M = {}

require "boil.types"

---Default logger configuration
---@type LoggerConfig
local default_options = {
  level = vim.log.levels.INFO,
  prefix = "[boil.nvim]",
}

M.options = default_options

---Setup logger configuration
---@param opts? LoggerConfig Logger configuration options
M.setup = function(opts)
  M.options = vim.tbl_extend("force", default_options, opts or {})
end

---Log an info message
---@param msg string Message to log
M.info = function(msg)
  if M.options.level <= vim.log.levels.INFO then
    M._log(msg, vim.log.levels.INFO)
  end
end

---Log a warning message
---@param msg string Message to log
M.warn = function(msg)
  if M.options.level <= vim.log.levels.WARN then
    M._log(msg, vim.log.levels.WARN)
  end
end

---Log an error message
---@param msg string Message to log
M.error = function(msg)
  if M.options.level <= vim.log.levels.ERROR then
    M._log(msg, vim.log.levels.ERROR)
  end
end

---Log a debug message
---@param msg string Message to log
M.debug = function(msg)
  if M.options.level <= vim.log.levels.DEBUG then
    M._log(msg, vim.log.levels.DEBUG)
  end
end

---Internal logging function
---@param msg string Message to log
---@param level number Log level (vim.log.levels.*)
M._log = function(msg, level)
  local formatted = M.options.prefix .. " " .. msg
  vim.notify(formatted, level)
end

return M
