# Template Creation Guide

This document covers everything you need to know about creating and organizing templates for boil.nvim.

## Table of Contents

- [Template Basics](#template-basics)
- [Variable Usage](#variable-usage)
- [Runtime Variables](#runtime-variables)
- [Advanced `__selection__` Usage](#advanced-__selection__-usage)
- [Template Examples](#template-examples)

## Template Basics

Templates are simple text files with `{{variable}}` placeholders that get replaced with actual values during insertion.

### Simple Template Example

Templates use `{{variable}}` placeholders that get replaced during insertion. See [`examples/templates/python/basic.py`](../examples/templates/python/basic.py) for a complete example.

### Variable Syntax

- Variables use double curly braces: `{{variable_name}}`
- Variable names are case-sensitive
- No spaces inside braces: `{{name}}` ✓, `{{ name }}` ✗
- Built-in variables start with `__`: `{{__filename__}}`

Templates can be organized in any directory structure you prefer. The plugin recursively scans all configured directories and discovers templates automatically. See the [`examples/templates/`](../examples/templates/) directory for one possible organization approach.

## Variable Usage

### Built-in Variables

- `{{__filename__}}` - Full filename with extension (`app.py`)
- `{{__basename__}}` - Filename without extension (`app`)
- `{{__date__}}` - Current date in YYYY-MM-DD format
- `{{__author__}}` - Author from configuration
- `{{__selection__}}` - Current visual selection or current line content (see [Advanced Usage](#advanced-__selection__-usage))

### Custom Variables

Define custom variables in your configuration:

```lua
variables = {
  company = "ACME Corp",
  license = "MIT",
  email = "dev@acme.com"
}
```

Then use them in templates:
```
Copyright (c) {{__date__}} {{company}}
Licensed under {{license}} license
Contact: {{email}}
```

## Runtime Variables

Runtime variables allow you to specify values at template insertion time, providing maximum flexibility for dynamic content.

### Command Line Usage

The `:Boil` command uses absolute template paths and supports runtime variables with `key=value` syntax:

```vim
" Basic usage (use Tab completion to get absolute paths)
:Boil /home/user/.config/nvim/templates/python/basic.py author=John project=MyApp

" Multiple variables
:Boil /home/user/.config/nvim/templates/react/component.jsx component=UserProfile author=Jane team=Frontend

" With quotes for values containing spaces
:Boil /home/user/.config/nvim/templates/docs/readme.md project="My Amazing App" description="A useful tool"

" Escape sequences for special characters
:Boil /home/user/.config/nvim/templates/config/database.py database="localhost:5432" connection="user=admin\\npass=secret"
```

**Tip:** Use Tab completion (`:Boil <Tab>`) to see available template paths instead of typing absolute paths manually.

### Alternative Usage Methods

For a better user experience, consider these alternatives to typing absolute paths:

#### 1. Tab Completion
```vim
" Start typing and press Tab for completion
:Boil <Tab>
" Shows all available template paths
```

#### 2. Telescope Integration
```vim
" Visual picker (no need for absolute paths)
:Telescope boil

" Telescope with runtime variables
:Telescope boil author=John project=MyApp

" Multiple variables
:Telescope boil component=Header team=UI version=2.0
```

#### 3. Interactive Selection
```vim
" Command without arguments opens interactive picker
:Boil
```

### Variable Priority

Variables are resolved with the following priority (highest to lowest):

1. **Runtime variables** (command line arguments)
2. **Template-specific variables** (directory configuration)
3. **Global variables** (main configuration)
4. **Built-in variables**

Example:
```vim
" If you have author="Default" in config, this overrides it
:Boil /path/to/templates/python/template.py author=John
```

### Practical Examples

See the [Template Examples](#template-examples) section for complete usage examples with the provided example templates.

## Advanced `__selection__` Usage

The `{{__selection__}}` variable is a useful feature for quick modification of existing code. Unlike traditional snippet engines that require pre-planning, `__selection__` works with code that already exists.

### Bash vi-mode Integration

This workflow can enhance command-line productivity:

1. **Start with existing command**: Type or recall a bash command
2. **Enter vi-mode**: Press `Ctrl-x Ctrl-e` or `v` (in vi normal mode) to open editor
3. **Visual select**: Select the command or part of it
4. **Apply template**: Use `:Boil` to wrap selection with error handling, logging, or functions

#### Example Workflow

```bash
# 1. Original command in bash
curl -X POST https://api.example.com/users -d '{"name": "John"}'

# 2. Ctrl-x Ctrl-e opens editor with command
# 3. Visual select the curl command
# 4. :Boil /path/to/templates/bash/error-handling.sh

# 5. Result: Robust script with error handling
#!/bin/bash
set -euo pipefail

main() {
  curl -X POST https://api.example.com/users -d '{"name": "John"}' || {
    echo "Error: API call failed" >&2
    echo "Check network connection and API endpoint" >&2
    exit 1
  }
}

main "$@"
```

### Why This Approach Is Different

Unlike snippets which require pre-planning, `__selection__` enables **quick code modification**:

| Traditional Snippets | `__selection__` Method |
|---------------------|------------------------|
| Plan → Write snippet → Code | Code → Select → Modify |
| Static placeholders | Dynamic existing content |
| Editor-only workflow | Command-line integrated |
| New code creation | Existing code enhancement |

### Selection-Based Template Examples

#### Error Handling Wrapper
**File: [`examples/templates/bash/error-handling.sh`](../examples/templates/bash/error-handling.sh)**

#### Function Wrapper
**File: [`examples/templates/bash/function-wrap.sh`](../examples/templates/bash/function-wrap.sh)**

**Usage:**
```vim
:Boil examples/templates/bash/function-wrap.sh function_name=cleanup_logs
```

#### Python Try-Catch
**File: [`examples/templates/python/try-catch.py`](../examples/templates/python/try-catch.py)**

#### Debug Logger
**File: [`examples/templates/any/debug-wrap.txt`](../examples/templates/any/debug-wrap.txt)**

### Practical Use Cases

#### 1. Command History Enhancement
```bash
# From history: complex git command
git log --oneline --graph --decorate --branches | head -20

# Select → Apply function template → Reusable function
show_git_tree() {
  git log --oneline --graph --decorate --branches | head -20
}
```

#### 2. Script Development
```bash
# Working command in terminal
find /var/log -name "*.log" -mtime +7 -delete

# Convert to safe script with confirmation
cleanup_old_logs() {
  local files_to_delete
  files_to_delete=$(find /var/log -name "*.log" -mtime +7)

  if [[ -n "$files_to_delete" ]]; then
    echo "Files to delete:"
    echo "$files_to_delete"
    read -p "Continue? (y/N): " confirm
    [[ "$confirm" == "y" ]] && find /var/log -name "*.log" -mtime +7 -delete
  fi
}
```

#### 3. Code Block Enhancement
```python
# Existing working code
data = requests.get("https://api.example.com/data").json()
process_data(data)

# Select → Apply error handling template
try:
    data = requests.get("https://api.example.com/data").json()
    process_data(data)
except requests.RequestException as e:
    logger.error(f"API request failed: {e}")
    raise
except Exception as e:
    logger.error(f"Data processing failed: {e}")
    raise
```

### Integration with Development Workflow

This approach integrates seamlessly with common development patterns:

- **fc command**: `fc` opens last command in editor for selection-based templating
- **History editing**: `history | grep pattern` → select command → wrap in function
- **Interactive debugging**: Add logging/debugging around existing code blocks
- **Script hardening**: Convert working commands into production-ready scripts

The key insight: **Start with working code, then make it better**, rather than planning perfect code from the beginning.

## Template Examples

### Example Templates

**All example templates are located in the [`examples/templates/`](../examples/templates/) directory:**

- **[`python/class.py`](../examples/templates/python/class.py)** - Python class template with documentation
- **[`python/basic.py`](../examples/templates/python/basic.py)** - Basic Python script structure
- **[`bash/error-handling.sh`](../examples/templates/bash/error-handling.sh)** - Bash script with error handling
- **[`bash/function-wrap.sh`](../examples/templates/bash/function-wrap.sh)** - Function wrapper template
- **[`javascript/react-component.jsx`](../examples/templates/javascript/react-component.jsx)** - React component template

**Usage:**
```vim
:Boil examples/templates/python/class.py class_name=UserManager description="User management system"
:Boil examples/templates/bash/error-handling.sh
:Boil examples/templates/javascript/react-component.jsx component=UserCard
```

To use these examples in your setup:
```lua
require('boil').setup({
  templates = {
    {
      path = vim.fn.stdpath("data") .. "/lazy/boil.nvim/examples/templates",
      name = "Examples"
    }
  }
})
```
