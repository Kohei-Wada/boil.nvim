# Developer API Documentation

This document provides technical details for developers who want to extend boil.nvim or understand its internal architecture.

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Module Reference](#module-reference)
- [Extension Points](#extension-points)
- [Testing Framework](#testing-framework)
- [Development Workflow](#development-workflow)

## Architecture Overview

boil.nvim follows a modular architecture with clear separation of concerns:

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   User Input    │    │  Telescope UI   │    │  vim.ui.select  │
│  (:Boil cmd)    │    │   Extension     │    │      UI         │
└─────────┬───────┘    └─────────┬───────┘    └─────────┬───────┘
          │                      │                      │
          └──────────────────────┼──────────────────────┘
                                 │
                    ┌─────────────▼───────────┐
                    │      boil.init.lua      │
                    │   (Main Entry Point)    │
                    └─────────────┬───────────┘
                                  │
          ┌───────────────────────┼───────────────────────┐
          │                       │                       │
    ┌─────▼──────┐    ┌──────────▼─────────┐    ┌────────▼────────┐
    │   config   │    │     templates      │    │    expander     │
    │ (Settings) │    │ (Discovery/Load)   │    │ (Variables)     │
    └────────────┘    └────────────────────┘    └─────────────────┘
                               │
                    ┌──────────▼─────────┐
                    │       utils        │
                    │ (Argument Parsing) │
                    └────────────────────┘
```

## Module Reference

### boil.init

**Entry point module providing the main API**

```lua
local boil = require('boil')

-- Setup function
boil.setup(config)

-- Template insertion
boil.insert_template(template_path, runtime_variables)
```

**Key Functions:**
- `setup(user_config)` - Initialize plugin with configuration
- `insert_template(template_name, runtime_variables)` - Insert template content

### boil.config

**Configuration management with type annotations**

```lua
local config = require('boil.config')

-- Get merged configuration
local cfg = config.get()

-- Setup configuration
config.setup(user_config)
```

**Key Functions:**
- `setup(user_config)` - Merge user config with defaults
- `get()` - Return current merged configuration
- `validate(config)` - Validate configuration structure

### boil.templates

**Template discovery, loading, and filtering**

```lua
local templates = require('boil.templates')

-- Find all available templates
local template_list = templates.find_templates(config)

-- Load template content
local content = templates.load_template(path)

-- Get template by path
local template = templates.get_template_by_path(list, path)
```

**Key Functions:**
- `find_templates(config)` - Discover templates from configured directories
- `load_template(path)` - Read template file content
- `get_template_by_path(list, path)` - Find template by absolute path
- `get_display_name(template)` - Generate human-readable name
- `select_template(list, callback)` - Show template picker

### boil.expander

**Variable expansion system**

```lua
local expander = require('boil.expander')

-- Expand template with variables
local result, errors = expander.expand(content, config, template_config, runtime_vars)
```

**Key Functions:**
- `expand(content, config, template_config, runtime_variables)` - Process template variables

**Variable Priority (highest to lowest):**
1. Runtime variables
2. Template-specific variables
3. Global variables
4. Built-in variables

### boil.utils

**Utility functions for argument parsing**

```lua
local utils = require('boil.utils')

-- Parse command arguments
local template_path, runtime_vars = utils.parse_args(args_list)

-- Unescape string sequences
local unescaped = utils.unescape_string(str)
```

**Key Functions:**
- `parse_args(args_list)` - Parse command line arguments into template path and variables
- `unescape_string(str)` - Convert escape sequences (`\n`, `\t`, etc.)

### boil.logger

**Logging system**

```lua
local logger = require('boil.logger')

-- Setup logger
logger.setup(config)

-- Log messages
logger.info("Template inserted")
logger.warn("Template not found")
logger.error("Failed to load template")
logger.debug("Variable expansion details")
```

### boil.telescope.*

**Telescope integration modules**

```lua
-- Configuration management
local config = require('boil.telescope.config')
config.setup(user_config)
local opts, runtime_vars = config.merge_config(opts)

-- Argument parsing
local args = require('boil.telescope.args')
local runtime_vars = args.parse_command_args(args_string)

-- Picker implementation
local picker = require('boil.telescope.picker')
picker.create_picker(opts)
```

## Extension Points

### Custom Variable Functions

Extend the variable system with custom functions:

```lua
require('boil').setup({
  variables = {
    git_branch = function()
      local handle = io.popen("git branch --show-current")
      local branch = handle:read("*a"):gsub("\n", "")
      handle:close()
      return branch
    end,

    current_time = function()
      return os.date("%H:%M:%S")
    end,

    file_count = function()
      local files = vim.fn.glob("*", false, true)
      return tostring(#files)
    end
  }
})
```

### Custom Filters

Create sophisticated filtering logic:

```lua
require('boil').setup({
  filter = function(template)
    -- Language-specific filtering
    local ft = vim.bo.filetype
    if ft == "python" then
      return template.path:match("%.py$")
    end

    -- Project context filtering
    local cwd = vim.fn.getcwd()
    if cwd:match("work") then
      return not template.path:match("personal")
    end

    -- Time-based filtering
    local hour = tonumber(os.date("%H"))
    if hour < 9 or hour > 17 then
      return not template.path:match("work")
    end

    return true
  end
})
```

### Telescope Themes

Customize the Telescope integration:

```lua
require('telescope').setup({
  extensions = {
    boil = {
      theme = 'dropdown',
      layout_config = {
        width = 0.8,
        height = 0.6,
      },
      preview = {
        hide_on_startup = false,
      },
      -- Custom key mappings
      mappings = {
        i = {
          ["<C-d>"] = require('telescope.actions').delete_buffer,
        },
      },
    }
  }
})
```

## Testing Framework

boil.nvim uses [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) for testing.

### Running Tests

```bash
# Run all tests
make test

# Run specific test file
nvim --headless --noplugin -u scripts/minimal_init.vim -c "PlenaryBustedFile tests/config_spec.lua" -c "q"
```

### Test Structure

```lua
describe("module_name", function()
  local module

  before_each(function()
    -- Clear package cache for clean state
    package.loaded["boil.module"] = nil
    module = require("boil.module")
  end)

  describe("function_name", function()
    it("should do something", function()
      local result = module.function_name("input")
      assert.equals("expected", result)
    end)
  end)
end)
```

### Test Categories

**Unit Tests:**
- `config_spec.lua` - Configuration management
- `expander_spec.lua` - Variable expansion
- `templates_spec.lua` - Template discovery and loading
- `utils_spec.lua` - Utility functions
- `telescope_config_spec.lua` - Telescope configuration

**Integration Tests:**
- `runtime_variables_spec.lua` - End-to-end runtime variable flow

### Writing New Tests

1. Create test file: `tests/new_feature_spec.lua`
2. Follow existing patterns for setup/teardown
3. Mock external dependencies when necessary
4. Test both success and failure cases
5. Include edge cases and boundary conditions

```lua
describe("new_feature", function()
  local new_feature

  before_each(function()
    package.loaded["boil.new_feature"] = nil
    new_feature = require("boil.new_feature")
  end)

  it("should handle normal input", function()
    local result = new_feature.process("normal")
    assert.equals("expected", result)
  end)

  it("should handle edge cases", function()
    assert.has_no.errors(function()
      new_feature.process("")
      new_feature.process(nil)
    end)
  end)

  it("should validate input", function()
    assert.has.errors(function()
      new_feature.process("invalid")
    end)
  end)
end)
```

## Development Workflow

### Setting Up Development Environment

1. **Clone and setup:**
   ```bash
   git clone <repo>
   cd boil.nvim
   ```

2. **Install dependencies:**
   ```bash
   # plenary.nvim for testing (clone to ../plenary.nvim)
   git clone https://github.com/nvim-lua/plenary.nvim ../plenary.nvim
   ```

3. **Run tests:**
   ```bash
   make test
   ```

4. **Lint code:**
   ```bash
   make lint
   ```

### Code Style

- Use [stylua](https://github.com/JohnnyMorganz/StyLua) for formatting
- Follow existing patterns for module structure
- Add type annotations using EmmyLua format
- Include comprehensive error handling

### Adding New Features

1. **Design Phase:**
   - Consider the "Less is More" philosophy
   - Ensure feature fits the core use case
   - Plan API surface carefully

2. **Implementation:**
   - Write tests first (TDD approach)
   - Implement minimal viable version
   - Add comprehensive error handling
   - Update type definitions

3. **Documentation:**
   - Update relevant documentation files
   - Add usage examples
   - Update README if user-facing

4. **Integration:**
   - Ensure tests pass
   - Check for breaking changes
   - Update version if necessary

### Performance Considerations

- Template discovery is cached per session
- File I/O is minimized through lazy loading
- Variable expansion uses simple string replacement
- Telescope integration is optional and lazy-loaded

### Error Handling

- Use descriptive error messages
- Provide actionable suggestions
- Log appropriate level (debug/info/warn/error)
- Graceful degradation when possible

```lua
local function safe_expand(content, variables)
  local success, result = pcall(expand_template, content, variables)
  if not success then
    logger.error("Template expansion failed: " .. result)
    return content -- Return original content as fallback
  end
  return result
end
```
