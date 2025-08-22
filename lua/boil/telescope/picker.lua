local M = {}

local finders = require "telescope.finders"
local pickers = require "telescope.pickers"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local previewers = require "telescope.previewers"

local boil = require "boil"
local logger = require "boil.logger"

---Create telescope entry for template
---@param entry table Template entry
---@return table telescope_entry Entry for telescope finder
local function make_entry(entry)
  local templates = require "boil.templates"
  local display_name = templates.get_display_name(entry)
  return {
    value = entry.path,
    display = display_name,
    ordinal = display_name,
  }
end

---Create previewer for template content
---@param opts table Picker options
---@return table previewer Telescope previewer
local function create_previewer(opts)
  return previewers.new_buffer_previewer {
    title = opts.previewer_title,
    define_preview = function(self, entry, status)
      local templates = require "boil.templates"
      local content = templates.load_template(entry.value)
      if content then
        local lines = vim.split(content, "\n")
        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
        -- Set filetype based on template extension for syntax highlighting
        local extension = vim.fn.fnamemodify(entry.value, ":e")
        if extension ~= "" then
          vim.bo[self.state.bufnr].filetype = extension
        end
      end
    end,
  }
end

---Create key mappings for picker
---@param runtime_vars table Runtime variables to pass to insert_template
---@return function attach_mappings Telescope attach_mappings function
local function create_mappings(runtime_vars)
  return function(prompt_bufnr, map)
    actions.select_default:replace(function()
      actions.close(prompt_bufnr)
      local selection = action_state.get_selected_entry()
      if selection then
        boil.insert_template(selection.value, runtime_vars)
      end
    end)
    return true
  end
end

---Create and display the boil template picker
---@param opts table Picker options including runtime_vars
M.create_picker = function(opts)
  opts = opts or {}

  -- Extract runtime variables
  local runtime_vars = opts.runtime_vars

  -- Get templates using boil's global config
  local config = require "boil.config"
  local templates = require "boil.templates"
  local template_list = templates.find_templates(config.get())

  if #template_list == 0 then
    logger.warn "No templates found"
    return
  end

  pickers
    .new(opts, {
      prompt_title = opts.prompt_title,
      finder = finders.new_table {
        results = template_list,
        entry_maker = make_entry,
      },
      sorter = conf.generic_sorter(opts),
      previewer = create_previewer(opts),
      attach_mappings = create_mappings(runtime_vars),
    })
    :find()
end

return M
