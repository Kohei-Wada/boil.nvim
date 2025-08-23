# 🔥 boil.nvim

A Neovim plugin for intentional boilerplate template insertion with variable expansion and runtime variables.

## Features

- **Manual Template Insertion** - `:Boil` command for intentional template use
- **Runtime Variables** - Dynamic `key=value` specification at insertion time
- **Multiple Directories** - Personal, team, and project-specific templates
- **Variable Expansion** - `{{variable}}` placeholders with built-in and custom variables
- **Telescope Integration** - Optional enhanced UI with preview support

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  'Kohei-Wada/boil.nvim',
  dependencies = { 'nvim-telescope/telescope.nvim' }, -- Optional
  config = function()
    require('boil').setup({
      templates = {
        { path = "~/.config/nvim/templates" }
      }
    })
  end
}
```

## Usage

```vim
" Basic template insertion
:Boil
:Boil /path/to/templates/python/class.py

" With runtime variables (see examples/ directory)
:Boil examples/templates/python/class.py class_name=UserManager author=John
:Boil examples/templates/bash/error-handling.sh

" Using Telescope
:Telescope boil
:Telescope boil author=Jane team=Frontend

" Note: Telescope integration with __selection__ variable may be unstable
```

**Variable Priority**: Runtime > Template-specific > Global > Built-in

## Configuration

```lua
require('boil').setup({
  templates = {
    {
      path = "~/.config/nvim/templates",
      variables = { author = "John Doe" }
    },
    -- Try the examples directory
    {
      path = vim.fn.stdpath("data") .. "/lazy/boil.nvim/examples/templates",
      name = "Examples"
    }
  },
  variables = {
    __filename__ = function() return vim.fn.expand("%:t") end,
    __date__ = function() return os.date("%Y-%m-%d") end,
  }
})
```

For Telescope: `require('telescope').load_extension('boil')`

**Known Issue**: When using templates with `{{__selection__}}` variable through Telescope integration, Visual selection state may not be properly detected when using Telescope picker. For reliable `__selection__` usage, use the `:Boil` command directly.

## Template Example

**Template file: `examples/templates/python/class.py`**
```python
"""{{description}}
Author: {{author}}
Date: {{__date__}}
"""

class {{class_name}}:
    def __init__(self):
        pass
```

**Usage:**
```vim
:Boil examples/templates/python/class.py class_name=User description="User model" author=Me
```

See the `examples/templates/` directory for more ready-to-use templates including bash error handling, React components, and selection-based templates.

## Documentation

- [Configuration Guide](docs/CONFIGURATION.md) - Detailed setup
- [Template Creation](docs/TEMPLATES.md) - Creating templates

## Design Philosophy: Less is More

boil.nvim embodies a minimalist approach to template engines: **do one thing exceptionally well, and delegate everything else to a powerful programming language.**

### The Core Principle

```lua
-- The entire template engine in essence:
content:gsub("{{" .. key .. "}}", replacement)
```

### Why This Approach Works

Instead of building complex features into the template engine itself, boil.nvim provides a simple string substitution mechanism and delegates all complex logic to Lua functions. This creates unlimited extensibility through programming rather than built-in features.

```lua
-- Want conditional logic? Program it in Lua
variables = {
  header = function()
    if vim.bo.filetype == "python" then
      return "#!/usr/bin/env python3"
    elseif vim.bo.filetype == "bash" then
      return "#!/bin/bash"
    end
    return ""
  end,

  -- Want API integration? Program it in Lua
  project_info = function()
    local handle = io.popen("gh repo view --json name,description")
    local result = handle:read("*a")
    handle:close()
    return vim.fn.json_decode(result).description
  end,

  -- Want user interaction? Program it in Lua
  priority = function()
    return vim.fn.input("Priority (1-5): ")
  end
}
```

### The Power of Delegation

This design means that any functionality you can imagine can be implemented through Lua configuration. The `{{__selection__}}` variable, for example, is not a special built-in feature—it's simply one function that demonstrates what's possible when you combine a simple engine with a powerful programming language.

## Development

```bash
make test   # Run tests
make lint   # Lint code
make format # Format code
```

## License

MIT License - see [LICENSE](LICENSE) file.
