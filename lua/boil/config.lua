local M = {}

require "boil.types"

-- Default filter function that always returns true
local default_filter = function(template)
  return true
end

---@type Config
M.defaults = {
  templates = {},
  filter = default_filter,
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
    __selection__ = function()
      -- Check for visual marks first (from previous visual selection)
      local start_pos = vim.fn.getpos "'<"
      local end_pos = vim.fn.getpos "'>"

      -- Check if we have valid visual marks
      if start_pos[2] > 0 and end_pos[2] > 0 then
        -- Check if this is a recent visual selection (not just old marks)
        local current_line = vim.fn.line "."
        if start_pos[2] <= current_line and current_line <= end_pos[2] then
          local lines = vim.api.nvim_buf_get_lines(0, start_pos[2] - 1, end_pos[2], false)

          if #lines == 0 then
            return vim.api.nvim_get_current_line()
          end

          -- Get the last visual mode type
          local vmode = vim.fn.visualmode()

          -- Handle character-wise selection
          if vmode == "v" then
            if #lines == 1 then
              lines[1] = string.sub(lines[1], start_pos[3], end_pos[3])
            else
              lines[1] = string.sub(lines[1], start_pos[3])
              lines[#lines] = string.sub(lines[#lines], 1, end_pos[3])
            end
          end
          -- For line-wise (V) and block-wise (^V), use full lines

          return table.concat(lines, "\n")
        end
      end

      -- Fallback to current line
      return vim.api.nvim_get_current_line()
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
        template_config.filter = default_filter
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
