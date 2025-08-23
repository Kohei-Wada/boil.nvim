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

See the `examples/templates/` directory for more ready-to-use templates including bash error handling, React components, and selection-based transformations.

## Documentation

- [Configuration Guide](docs/CONFIGURATION.md) - Detailed setup
- [Template Creation](docs/TEMPLATES.md) - Creating templates

## Philosophy

Simple variable substitution only. Complex logic belongs in Lua config:

```lua
variables = {
  header = function()
    return vim.bo.filetype == "python" and "#!/usr/bin/env python3" or ""
  end
}
```

## Development

```bash
make test   # Run tests
make lint   # Lint code
make format # Format code
```

## License

MIT License - see [LICENSE](LICENSE) file.
