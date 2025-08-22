local M = {}
local expander = require "boil.expander"
local templates = require "boil.templates"
local logger = require "boil.logger"

require "boil.types"

---Check if visual mode selection is active
---@return boolean is_visual_active True if visual mode selection is active
local function is_visual_mode_active()
  local mode = vim.fn.mode()
  return mode == "v" or mode == "V" or mode == "\22" -- \22 is Ctrl-V (visual-block)
end

---Get visual mode selection range
---@return table|nil selection_range Table with start_row, start_col, end_row, end_col or nil if no selection
local function get_visual_selection_range()
  local start_pos = vim.fn.getpos "'<"
  local end_pos = vim.fn.getpos "'>"

  -- Check if we have valid visual marks
  if start_pos[2] == 0 or end_pos[2] == 0 then
    return nil
  end

  return {
    start_row = start_pos[2] - 1, -- Convert to 0-based indexing
    start_col = start_pos[3] - 1,
    end_row = end_pos[2] - 1,
    end_col = end_pos[3] - 1,
  }
end

---Insert template content into buffer
---@param template Template Template to insert
---@param config Config Plugin configuration
---@param runtime_variables? table<string, string> Runtime variables to use during expansion
M.insert_template_content = function(template, config, runtime_variables)
  local content = templates.load_template(template.path)
  if not content then
    return
  end

  local expanded, err = expander.expand(content, config, template.config, runtime_variables)
  if err then
    logger.warn("Template expansion warnings:\n" .. err)
  end
  if not expanded then
    logger.error("Failed to expand template: " .. template.path)
    return
  end

  local lines = vim.split(expanded, "\n", { plain = true })

  -- Check if we're in visual mode or have a recent visual selection
  local is_visual = is_visual_mode_active()
  local selection_range = get_visual_selection_range()

  if is_visual or selection_range then
    -- Replace visual selection with template content
    if selection_range then
      -- Exit visual mode first to clear selection
      if is_visual then
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
      end

      -- Replace the selected range with template content
      vim.api.nvim_buf_set_lines(0, selection_range.start_row, selection_range.end_row + 1, false, lines)

      logger.info("Template replaced selection: " .. templates.get_display_name(template))
    end
  else
    -- Handle cursor position insertion
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    local current_line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]

    if current_line == "" then
      -- Empty line: replace it with template
      vim.api.nvim_buf_set_lines(0, row - 1, row, false, lines)
    else
      -- Non-empty line: insert at cursor position
      local before_cursor = current_line:sub(1, col)
      local after_cursor = current_line:sub(col + 1)

      -- If template has multiple lines, handle them properly
      if #lines == 1 then
        -- Single line template: insert inline
        local new_line = before_cursor .. lines[1] .. after_cursor
        vim.api.nvim_buf_set_lines(0, row - 1, row, false, { new_line })
      else
        -- Multi-line template: split current line and insert template between
        local new_lines = {}
        table.insert(new_lines, before_cursor .. lines[1])
        for i = 2, #lines - 1 do
          table.insert(new_lines, lines[i])
        end
        table.insert(new_lines, lines[#lines] .. after_cursor)
        vim.api.nvim_buf_set_lines(0, row - 1, row, false, new_lines)
      end
    end

    logger.info("Template inserted: " .. templates.get_display_name(template))
  end
end

return M
