local telescope = require "telescope"
local finders = require "telescope.finders"
local pickers = require "telescope.pickers"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local previewers = require "telescope.previewers"

local boil = require "boil"
local logger = require "boil.logger"

-- Default picker configuration
local default_config = {
  prompt_title = "Boil Templates",
  previewer_title = "Template Preview",
}

-- Store extension config
local ext_config = {}

local function boil_picker(opts)
  opts = opts or {}

  -- Merge configs: default -> extension -> runtime
  opts = vim.tbl_deep_extend("force", default_config, ext_config, opts)

  -- Handle theme string (similar to telescope-file-browser)
  if opts.theme then
    local theme_name = opts.theme
    local theme_func = require("telescope.themes")["get_" .. theme_name]
    if theme_func then
      opts = theme_func(opts)
    end
    opts.theme = nil
  end

  -- Uses boil's global config - template management is boil's responsibility
  -- Telescope handles only UI/presentation concerns
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
        entry_maker = function(entry)
          local display_name = templates.get_display_name(entry)
          return {
            value = entry.path,
            display = display_name,
            ordinal = display_name,
          }
        end,
      },
      sorter = conf.generic_sorter(opts),
      previewer = previewers.new_buffer_previewer {
        title = opts.previewer_title,
        define_preview = function(self, entry, status)
          local templates_module = require "boil.templates"
          local content = templates_module.load_template(entry.value)
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
      },
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          if selection then
            boil.insert_template(selection.value)
          end
        end)
        return true
      end,
    })
    :find()
end

return telescope.register_extension {
  setup = function(user_ext_config, telescope_config)
    -- Store user extension config
    ext_config = user_ext_config or {}
  end,
  exports = {
    boil = boil_picker,
  },
}
