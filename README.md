# boil.nvim

A Neovim plugin for automatic boilerplate template insertion when creating new files. Manages file-based templates (not snippets) with support for multiple template directories and variable expansion.

## Features

- **Manual Template Insertion**: Use `:Boil` command for intentional template insertion
- **Multiple Template Directories**: Support personal, team, and project-specific templates with priority ordering
- **Variable Expansion**: Support placeholders like `{{__filename__}}`, `{{__date__}}`, `{{__author__}}`
- **Flexible Filtering**: Directory-specific and global filters to control template visibility
- **Telescope Integration**: Enhanced UI with preview and theme support
- **Recursive Template Discovery**: Automatically finds templates in subdirectories

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  'Kohei-Wada/boil.nvim',
  dependencies = {
    'nvim-telescope/telescope.nvim', -- Optional, for enhanced UI
  },
  config = function()
    require('boil').setup({
      -- Configuration here
    })
  end
}
```

Using [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use {
  'Kohei-Wada/boil.nvim',
  requires = {
    'nvim-telescope/telescope.nvim', -- Optional
  },
  config = function()
    require('boil').setup()
  end
}
```

## Configuration

### Basic Setup

```lua
require('boil').setup({
  templates = {
    -- Template directories
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
    -- Optional logger configuration
    level = vim.log.levels.INFO,  -- Minimum log level (DEBUG, INFO, WARN, ERROR)
    prefix = "[boil.nvim]",       -- Custom prefix for log messages
  }
})
```

### Telescope Integration

```lua
require('telescope').setup({
  extensions = {
    boil = {
      theme = 'ivy', -- 'ivy', 'dropdown', 'cursor', or nil
      -- Any other telescope picker options
    }
  }
})

-- Load the extension
require('telescope').load_extension('boil')
```

## Usage

### Commands

- `:Boil` - Open template picker using vim.ui.select
- `:Boil /absolute/path/to/template.py` - Insert specific template by absolute path
- `:Telescope boil` - Open template picker using Telescope (if extension is loaded)

### Template Examples

**Python Basic Template** (`python/basic.py`):
```python
#!/usr/bin/env python3
"""
{{__filename__}}
Author: {{__author__}}
Date: {{__date__}}
"""

def main():
    pass

if __name__ == "__main__":
    main()
```

**React Component Template** (`javascript/react-component.jsx`):
```jsx
import React from 'react';

const {{__basename__}} = () => {
  return (
    <div>
      <h1>{{__basename__}}</h1>
    </div>
  );
};

export default {{__basename__}};
```

## Variable System

Variables are processed with the following priority (highest to lowest):

1. **Template-specific variables** (defined in each template config)
2. **Global variables** (defined in main config)
3. **Built-in variables**

### Design Philosophy: Less is More

**boil.nvim embraces the "Less is More" philosophy** - achieving maximum flexibility through minimal complexity. The template engine remains compact and focused, providing unlimited extensibility by delegating complex logic to Lua configuration rather than building it into the engine itself.

This minimalist approach:
- Maintains simplicity and reliability (fewer bugs in less code)
- Leverages Lua's full programming capabilities instead of reinventing them
- Provides seamless integration with Neovim's APIs and ecosystem
- Keeps debugging straightforward in a single language environment
- Allows users to bring their own complexity only when needed

**The template engine intentionally does just one thing: variable substitution** via `{{variable}}` placeholders. Everything else - conditionals, loops, complex transformations - belongs in your Lua configuration where you have the full power of the language at your disposal.

```lua
-- Example: Complex logic belongs in Lua config, not templates
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
  end
}
```

### Built-in Variables

Built-in variables use the `__` prefix to distinguish them from user-defined variables:

- `{{__filename__}}` - Current file name with extension
- `{{__basename__}}` - Current file name without extension
- `{{__date__}}` - Current date (YYYY-MM-DD)
- `{{__author__}}` - Author name from configuration

### Custom Variables

```lua
-- Function-based variables
variables = {
  project = function()
    return vim.fn.fnamemodify(vim.fn.getcwd(), ':t')
  end,
  timestamp = function()
    return os.date("%Y-%m-%d %H:%M:%S")
  end
}

-- Static variables
variables = {
  company = "ACME Corporation",
  license = "MIT"
}
```

## Filtering

The filtering system exists primarily to help you effectively use template collections from other sources - whether from team repositories, community template packs, or shared configurations. It allows selective inclusion of templates based on your current context and needs.

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

This simple interface provides all necessary information for filtering while maintaining extensibility.

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

## Development

### Running Tests

```bash
make test
```

### Linting

```bash
make lint
```

### Code Formatting

```bash
stylua lua/
```

## Architecture

- `lua/boil/init.lua` - Main module entry point with setup function
- `lua/boil/config.lua` - Configuration management with type annotations
- `lua/boil/templates.lua` - Template discovery, loading, filtering, and directory scanning
- `lua/boil/expander.lua` - Variable expansion system
- `lua/boil/types.lua` - Type definitions for LSP support
- `lua/telescope/_extensions/boil.lua` - Telescope integration

## License

MIT License - see [LICENSE](LICENSE) file for details.
