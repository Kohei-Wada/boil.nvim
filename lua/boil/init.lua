local M = {}
local config = require "boil.config"
local templates = require "boil.templates"
local expander = require "boil.expander"
local logger = require "boil.logger"

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
    M.insert_template(opts.args)
  end, {
    nargs = "?",
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
M.insert_template = function(template_name)
  local cfg = config.get()
  local template_list = templates.find_templates(cfg)

  local function insert_content(template)
    local content = templates.load_template(template.path)
    if content then
      local expanded, err = expander.expand(content, cfg, template.config)
      if err then
        logger.warn("Template expansion warnings:\n" .. err)
      end

      local lines = vim.split(expanded, "\n", { plain = true })
      local row, _ = unpack(vim.api.nvim_win_get_cursor(0))

      -- If current line is empty, replace it; otherwise insert after current line
      local current_line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
      if current_line == "" then
        vim.api.nvim_buf_set_lines(0, row - 1, row, false, lines)
      else
        vim.api.nvim_buf_set_lines(0, row, row, false, lines)
      end

      logger.info("Template inserted: " .. templates.get_display_name(template))
    end
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
