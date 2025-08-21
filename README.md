# boil.nvim

A Neovim plugin for intentional boilerplate template insertion. Manages file-based templates with support for multiple directories, variable expansion, and runtime variables.

## Features

- **Manual Template Insertion**: Use `:Boil` command for intentional template insertion
- **Runtime Variables**: Dynamic variable specification at insertion time
- **Multiple Template Directories**: Personal, team, and project-specific templates
- **Variable Expansion**: Built-in and custom placeholders like `{{__filename__}}`, `{{__date__}}`
- **Telescope Integration**: Enhanced UI with preview and theme support
- **Flexible Filtering**: Directory-specific and global filters

## Quick Start

### Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  'Kohei-Wada/boil.nvim',
  dependencies = {
    'nvim-telescope/telescope.nvim', -- Optional, for enhanced UI
  },
  config = function()
    require('boil').setup({
      templates = {
        { path = "~/.config/nvim/templates" }
      }
    })
  end
}
```

### Basic Usage

```vim
" Basic template insertion
:Boil

" Insert specific template
:Boil python/class.py

" With runtime variables
:Boil python/class.py class_name=UserManager author=John

" Using Telescope
:Telescope boil
:Telescope boil author=Jane project=WebApp
```

## Runtime Variables

**NEW FEATURE**: Specify variables dynamically at template insertion time using `key=value` syntax.

### Command Line Usage

```vim
" Single variable
:Boil template.py author=John

" Multiple variables
:Boil react-component.jsx component=UserCard author=Jane team=Frontend

" With quotes for spaces
:Boil readme.md project="My Amazing App" description="A revolutionary tool"

" Escape sequences
:Boil config.py database="localhost:5432" connection="user=admin\\npass=secret"
```

### Telescope Integration

```vim
" Telescope with runtime variables
:Telescope boil author=John project=MyApp

" Multiple variables
:Telescope boil component=Header team=UI version=2.0
```

### Variable Priority

Variables are resolved with the following priority (highest to lowest):

1. **Runtime variables** (command line arguments) 🆕
2. **Template-specific variables** (directory configuration)
3. **Global variables** (main configuration)
4. **Built-in variables** (`{{__filename__}}`, `{{__date__}}`, etc.)

This allows maximum flexibility - define defaults in configuration and override them as needed.

## Configuration

### Basic Setup

```lua
require('boil').setup({
  templates = {
    {
      name = "personal",
      path = "~/.config/nvim/templates",
      variables = { author = "John Doe" }
    },
    {
      name = "work",
      path = "~/work/templates",
      variables = { company = "ACME Corp" }
    }
  },
  variables = {
    __filename__ = function() return vim.fn.expand("%:t") end,
    __date__ = function() return os.date("%Y-%m-%d") end,
    __author__ = "Default Author"
  }
})
```

### Telescope Setup

```lua
require('telescope').setup({
  extensions = {
    boil = {
      theme = 'ivy', -- 'dropdown', 'cursor', or nil
    }
  }
})
require('telescope').load_extension('boil')
```

## Template Examples

### Python Class with Runtime Variables

**Template file: `python/class.py`**
```python
"""
{{description}}
Author: {{author}}
Created: {{__date__}}
"""

class {{class_name}}:
    """{{class_description}}"""

    def __init__(self):
        pass
```

**Usage:**
```vim
:Boil python/class.py class_name=UserManager description="User management system" author=TeamLead
```

### React Component

**Template file: `react/component.jsx`**
```jsx
import React from 'react';

/**
 * {{component}} component
 * @author {{author}}
 */
const {{component}} = () => {
  return (
    <div className="{{component_class}}">
      <h1>{{component}}</h1>
    </div>
  );
};

export default {{component}};
```

**Usage:**
```vim
:Boil react/component.jsx component=UserProfile author=Frontend component_class=user-profile
```

## Documentation

- **[Configuration Guide](docs/CONFIGURATION.md)** - Detailed setup and variable system
- **[Template Creation](docs/TEMPLATES.md)** - How to create and organize templates
- **[Developer API](docs/API.md)** - Architecture and extension points

## Philosophy: Less is More

boil.nvim embraces simplicity - the template engine does one thing well: variable substitution via `{{variable}}` placeholders. Complex logic belongs in your Lua configuration where you have the full power of the language.

```lua
-- Complex logic in config, not templates
variables = {
  header = function()
    return vim.bo.filetype == "python" and "#!/usr/bin/env python3" or ""
  end
}
```

## Development

```bash
# Run tests
make test

# Lint code
make lint

# Format code
stylua lua/
```

## License

MIT License - see [LICENSE](LICENSE) file for details.
