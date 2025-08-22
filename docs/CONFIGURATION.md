# Configuration Guide

This document provides comprehensive configuration examples and explanations for boil.nvim.

## Table of Contents

- [Basic Configuration](#basic-configuration)
- [Template Directories](#template-directories)
- [Variable System](#variable-system)
- [Filtering System](#filtering-system)
- [Telescope Integration](#telescope-integration)
- [Logger Configuration](#logger-configuration)

## Basic Configuration

```lua
require('boil').setup({
  templates = {
    -- Template directories with priority order
    {
      name = "personal",
      path = "~/.local/share/nvim/boil/personal",
      variables = { author = "John Doe" },
      filter = function(template)
        return true -- Include all templates
      end
    },
    {
      name = "work",
      path = "~/.config/nvim/boil/templates",
      variables = { company = "ACME Corp" },
    },
    {
      path = "~/dotfiles/templates",
      -- name will default to "templates" (directory name)
    },
  },
  variables = {
    -- Global variables available to all templates
    __filename__ = function() return vim.fn.expand("%:t") end,
    __basename__ = function() return vim.fn.expand("%:t:r") end,
    __date__ = function() return os.date("%Y-%m-%d") end,
    __author__ = "Default Author"
  },
  filter = function(template)
    -- Global filter applied after source-specific filters
    return true
  end,
  logger = {
    level = vim.log.levels.INFO,
    prefix = "[boil.nvim]",
  }
})
```

## Template Directories

Template directories are processed in the order they are defined. Each directory can have its own configuration:

```lua
templates = {
  {
    name = "personal",           -- Display name (optional)
    path = "~/.config/templates", -- Path to template directory
    variables = {                -- Directory-specific variables
      license = "MIT",
      email = "john@example.com"
    },
    filter = function(template)  -- Directory-specific filter
      return template.path:match("%.lua$")
    end
  }
}
```

### Path Resolution

- `~` expands to home directory
- Relative paths are resolved from Neovim's current working directory
- Absolute paths are used as-is

## Variable System

Variables are processed with the following priority (highest to lowest):

1. **Runtime variables** (passed via command line)
2. **Template-specific variables** (defined in each template config)
3. **Global variables** (defined in main config)
4. **Built-in variables**

### Design Philosophy: Less is More

**boil.nvim embraces the "Less is More" philosophy** - achieving maximum flexibility through minimal complexity. The template engine remains compact and focused, providing unlimited extensibility by delegating complex logic to Lua configuration rather than building it into the engine itself.

This minimalist approach:
- Maintains simplicity and reliability (fewer bugs in less code)
- Leverages Lua's full programming capabilities instead of reinventing them
- Provides seamless integration with Neovim's APIs and ecosystem
- Keeps debugging straightforward in a single language environment
- Allows users to bring their own complexity only when needed

**The template engine intentionally does just one thing: variable substitution** via `{{variable}}` placeholders. Everything else - conditionals, loops, complex transformations - belongs in your Lua configuration where you have the full power of the language at your disposal.

### Built-in Variables

Built-in variables use the `__` prefix to distinguish them from user-defined variables:

- `{{__filename__}}` - Current file name with extension
- `{{__basename__}}` - Current file name without extension
- `{{__date__}}` - Current date (YYYY-MM-DD)
- `{{__author__}}` - Author name from configuration

### Custom Variables

#### Function-based Variables

```lua
variables = {
  project = function()
    return vim.fn.fnamemodify(vim.fn.getcwd(), ':t')
  end,
  timestamp = function()
    return os.date("%Y-%m-%d %H:%M:%S")
  end,
  git_user = function()
    local handle = io.popen("git config user.name")
    local result = handle:read("*a"):gsub("\n", "")
    handle:close()
    return result
  end
}
```

#### Static Variables

```lua
variables = {
  company = "ACME Corporation",
  license = "MIT",
  contact = "team@acme.com"
}
```

#### Complex Logic Examples

```lua
variables = {
  -- Conditional content
  header = function()
    if vim.bo.filetype == "python" then
      return "#!/usr/bin/env python3"
    elseif vim.bo.filetype == "sh" then
      return "#!/bin/bash"
    end
    return ""
  end,

  -- Generated lists
  imports = function()
    local modules = {"os", "sys", "json"}
    local lines = {}
    for _, mod in ipairs(modules) do
      table.insert(lines, "import " .. mod)
    end
    return table.concat(lines, "\n")
  end,

  -- Context-aware variables
  namespace = function()
    local cwd = vim.fn.getcwd()
    if cwd:match("work") then
      return "com.company.project"
    else
      return "personal.project"
    end
  end
}
```

## Filtering System

The filtering system exists primarily to help you effectively use template collections from other sources - whether from team repositories, community template packs, or shared configurations.

### Why Filtering?

When using external template collections, you often get more templates than you need:
- Team repositories might include templates for multiple languages
- Community packs may have templates for frameworks you don't use
- Shared dotfiles might contain personal templates irrelevant to your workflow

Filters let you cherry-pick what's useful without forking or modifying the original sources.

### Filter Function Interface

Filter functions receive a template object with the following structure:

```lua
template = {
  path = "/absolute/path/to/template",      -- Absolute path to template file
  config = { ... }                          -- Template configuration reference
}
```

### Directory-Level Filtering

```lua
{
  name = "team-templates",
  path = "~/work/shared-templates",  -- Shared team repository
  filter = function(template)
    -- Filter by file extension using path
    return template.path:match("%.py$") or template.path:match("%.go$")
  end
}
```

### Global Filtering

```lua
filter = function(template)
  -- Hide work templates on weekends
  if template.config.name == "work" then
    return os.date("%w") ~= "0" and os.date("%w") ~= "6"
  end

  -- Filter out test templates in production projects
  if vim.fn.getcwd():match("production") then
    return not template.path:match("test")
  end

  return true
end
```

### Advanced Filtering Examples

```lua
filter = function(template)
  -- Language-specific filtering
  local ft = vim.bo.filetype
  if ft == "python" then
    return template.path:match("%.py$")
  elseif ft == "lua" then
    return template.path:match("%.lua$")
  end

  -- Project-specific filtering
  local project_type = vim.fn.expand("%:p"):match("frontend") and "frontend" or "backend"
  return template.path:match(project_type)
end
```

## Telescope Integration

### Basic Setup

```lua
require('telescope').setup({
  extensions = {
    boil = {
      theme = 'ivy', -- 'ivy', 'dropdown', 'cursor', or nil
      prompt_title = "Select Template",
      previewer_title = "Template Preview",
      -- Any other telescope picker options
    }
  }
})

-- Load the extension
require('telescope').load_extension('boil')
```

### Custom Telescope Configuration

```lua
require('telescope').setup({
  extensions = {
    boil = {
      theme = 'dropdown',
      prompt_title = "🔥 Boil Templates",
      previewer_title = "📄 Preview",
      layout_config = {
        width = 0.8,
        height = 0.8,
      },
      -- Custom sorting
      sorter = require('telescope.config').values.generic_sorter({}),
    }
  }
})
```

## Logger Configuration

Control logging behavior for debugging and monitoring:

```lua
logger = {
  level = vim.log.levels.INFO,  -- DEBUG, INFO, WARN, ERROR
  prefix = "[boil.nvim]",       -- Custom prefix for log messages
}
```

### Log Levels

- `vim.log.levels.DEBUG` - Detailed debugging information
- `vim.log.levels.INFO` - General information (default)
- `vim.log.levels.WARN` - Warning messages
- `vim.log.levels.ERROR` - Error messages only

### Example Logger Usage

```lua
-- For development/debugging
logger = {
  level = vim.log.levels.DEBUG,
  prefix = "[boil-dev]",
}

-- For production use
logger = {
  level = vim.log.levels.WARN,
  prefix = "[boil]",
}
```
