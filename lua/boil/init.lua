local M = {}
local config = require "boil.config"
local templates = require "boil.templates"
local inserter = require "boil.inserter"
local logger = require "boil.logger"
local utils = require "boil.utils"

require "boil.types"

---Setup boil.nvim plugin
---@param user_config? Config User configuration
M.setup = function(user_config)
  config.setup(user_config)

  -- Setup logger with merged configuration (defaults + user overrides)
  local merged_config = config.get()
  if merged_config.logger then
    logger.setup(merged_config.logger)
  end

  vim.api.nvim_create_user_command("Boil", function(opts)
    local template_path, runtime_vars = utils.parse_args(opts.fargs)
    M.insert_template(template_path, runtime_vars)
  end, {
    nargs = "*",
    range = true,
    complete = function()
      local template_list = templates.find_templates(config.get())
      local paths = {}
      for _, template in ipairs(template_list) do
        table.insert(paths, template.path)
      end
      return paths
    end,
  })
end

---Insert template into current buffer
---@param template_name? string Optional template path to insert directly
---@param runtime_variables? table<string, string> Runtime variables to use during expansion
M.insert_template = function(template_name, runtime_variables)
  local cfg = config.get()
  local template_list = templates.find_templates(cfg)

  local function insert_content(template)
    inserter.insert_template_content(template, cfg, runtime_variables)
  end

  if template_name and template_name ~= "" then
    -- Find template by absolute path only
    local template = templates.get_template_by_path(template_list, template_name)
    if template then
      insert_content(template)
    else
      logger.error("Template not found: " .. template_name)
    end
  else
    templates.select_template(template_list, insert_content)
  end
end

return M
