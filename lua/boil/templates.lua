local M = {}
local logger = require "boil.logger"

require "boil.types"

---Scan directory recursively for template files
---@param template_config TemplateConfig
---@return Template[]
local function scan_directory(template_config)
  local templates = {}
  local dir = vim.fn.expand(template_config.path)

  if vim.fn.isdirectory(dir) ~= 1 then
    return templates
  end

  -- Use vim.fs.dir for recursive directory iteration
  local files = {}
  local function scan_dir(path)
    for name, type in vim.fs.dir(path) do
      if name ~= "." and name ~= ".." then
        local full_path = path .. "/" .. name
        if type == "file" then
          table.insert(files, full_path)
        elseif type == "directory" then
          scan_dir(full_path)
        end
      end
    end
  end
  scan_dir(dir)

  for _, file in ipairs(files) do
    table.insert(templates, {
      path = file, -- Absolute path to template file
      config = template_config,
    })
  end

  return templates
end

---Generate display name for template
---@param template Template
---@return string
local function get_display_name(template)
  local config = template.config
  local source_name = config.name or vim.fn.fnamemodify(vim.fn.expand(config.path), ":t")
  return string.format("%s (%s)", template.path, source_name)
end

---Find all templates from configured sources
---@param config Config
---@return Template[]
M.find_templates = function(config)
  local all_templates = {}
  local path_to_template = {} -- Track templates by absolute path for duplicate detection

  for _, template_config in ipairs(config.templates or {}) do
    -- Scan directory for templates
    local templates = scan_directory(template_config)

    -- Apply filters to each template
    for _, template in ipairs(templates) do
      local should_include = true

      -- Apply source-specific filter if defined
      if template_config.filter and type(template_config.filter) == "function" then
        should_include = template_config.filter(template)
      end

      -- Apply global filter if defined and directory filter passed
      if should_include and config.filter and type(config.filter) == "function" then
        should_include = config.filter(template)
      end

      if should_include then
        -- Check for duplicates
        if path_to_template[template.path] then
          -- Template already exists - keep the more specific source (last one wins)
          logger.debug(
            string.format(
              "Duplicate template detected: %s\n  Replacing: %s\n  With: %s",
              template.path,
              get_display_name(path_to_template[template.path]),
              get_display_name(template)
            )
          )
          -- Remove the old template from all_templates
          for i = #all_templates, 1, -1 do
            if all_templates[i].path == template.path then
              table.remove(all_templates, i)
              break
            end
          end
        end

        -- Add the new template
        table.insert(all_templates, template)
        path_to_template[template.path] = template
      end
    end
  end

  return all_templates
end

---Load template content from file path
---@param template_path string Path to template file
---@return string? content Template content or nil if failed
M.load_template = function(template_path)
  local file = io.open(template_path, "r")
  if not file then
    logger.error("Failed to load template: " .. template_path)
    return nil
  end

  local content = file:read "*a"
  file:close()
  return content
end

---Show template selection UI using vim.ui.select
---@param templates Template[] Available templates
---@param callback fun(template: Template) Callback function when template is selected
M.select_template = function(templates, callback)
  if #templates == 0 then
    logger.warn "No templates found"
    return
  end

  local items = {}
  for _, template in ipairs(templates) do
    table.insert(items, get_display_name(template))
  end

  vim.ui.select(items, {
    prompt = "Select template:",
  }, function(choice, idx)
    if choice and idx then
      callback(templates[idx])
    end
  end)
end

---Find template by path
---@param templates Template[] List of templates to search
---@param path string Template path to find
---@return Template? template Found template or nil
M.get_template_by_path = function(templates, path)
  for _, template in ipairs(templates) do
    if template.path == path then
      return template
    end
  end
  return nil
end

-- Export the display name generation function
M.get_display_name = get_display_name

return M
