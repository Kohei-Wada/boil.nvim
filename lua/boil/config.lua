local M = {}

require "boil.types"

---@type Config
M.defaults = {
  templates = {},
  filter = function(template)
    return true
  end,
  variables = {
    __filename__ = function()
      local filename = vim.fn.expand "%:t"
      if filename == "" then
        filename = "untitled"
      end
      return filename
    end,
    __basename__ = function()
      local basename = vim.fn.expand "%:t:r"
      if basename == "" then
        basename = "untitled"
      end
      return basename
    end,
    __author__ = vim.env.USER or "",
    __date__ = function()
      return os.date "%Y-%m-%d"
    end,
  },
  logger = {
    level = vim.log.levels.INFO,
    prefix = "[boil.nvim]",
  },
}

---@type Config
M.options = {}

---Setup boil configuration
---@param user_config? Config User configuration to merge with defaults
M.setup = function(user_config)
  user_config = user_config or {}
  M.options = vim.tbl_deep_extend("force", M.defaults, user_config)

  if M.options.templates then
    for _, template_config in ipairs(M.options.templates) do
      -- Expand template directory paths
      if template_config.path then
        template_config.path = vim.fn.expand(template_config.path)
      end

      -- Add default filter if not provided
      if not template_config.filter then
        template_config.filter = function(template)
          return true
        end
      end
    end
  end
end

---Get current configuration
---@return Config
M.get = function()
  return M.options
end

return M
