local M = {}

-- Default picker configuration
M.default_config = {
  prompt_title = "Boil Templates",
  previewer_title = "Template Preview",
}

-- Store extension config
local ext_config = {}

---Setup extension configuration
---@param user_ext_config table|nil User extension configuration
M.setup = function(user_ext_config)
  ext_config = user_ext_config or {}
end

---Merge configurations with priority: default -> extension -> runtime
---@param opts table Runtime options
---@return table merged_opts Merged configuration options
M.merge_config = function(opts)
  opts = opts or {}

  -- Extract runtime variables before merging configs to avoid conflicts
  local runtime_vars = opts.runtime_vars
  opts.runtime_vars = nil

  -- Merge configs: default -> extension -> runtime
  opts = vim.tbl_deep_extend("force", M.default_config, ext_config, opts)

  -- Handle theme string (similar to telescope-file-browser)
  if opts.theme then
    local theme_name = opts.theme
    local theme_func = require("telescope.themes")["get_" .. theme_name]
    if theme_func then
      opts = theme_func(opts)
    end
    opts.theme = nil
  end

  return opts, runtime_vars
end

return M
