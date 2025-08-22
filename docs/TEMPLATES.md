# Template Creation Guide

This document covers everything you need to know about creating and organizing templates for boil.nvim.

## Table of Contents

- [Template Basics](#template-basics)
- [Directory Structure](#directory-structure)
- [Variable Usage](#variable-usage)
- [Runtime Variables](#runtime-variables)
- [Template Examples](#template-examples)

## Template Basics

Templates are simple text files with `{{variable}}` placeholders that get replaced with actual values during insertion.

### Simple Template Example

**File: `python/basic.py`**
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

### Variable Syntax

- Variables use double curly braces: `{{variable_name}}`
- Variable names are case-sensitive
- No spaces inside braces: `{{name}}` ✓, `{{ name }}` ✗
- Built-in variables start with `__`: `{{__filename__}}`

## Directory Structure

Organize templates in logical directories for easy discovery:

```
templates/
├── python/
│   ├── basic.py
│   ├── class.py
│   ├── script.py
│   └── test.py
├── javascript/
│   ├── react-component.jsx
│   ├── node-script.js
│   └── express-route.js
├── lua/
│   ├── module.lua
│   ├── plugin.lua
│   └── spec.lua
└── docs/
    ├── readme.md
    ├── api.md
    └── changelog.md
```

## Variable Usage

### Built-in Variables

- `{{__filename__}}` - Full filename with extension (`app.py`)
- `{{__basename__}}` - Filename without extension (`app`)
- `{{__date__}}` - Current date in YYYY-MM-DD format
- `{{__author__}}` - Author from configuration

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
:Boil /home/user/.config/nvim/templates/docs/readme.md project="My Amazing App" description="A revolutionary tool"

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

#### Dynamic Project Setup
```vim
:Boil /path/to/templates/python/project.py project=WebAPI author=TeamLead version=1.0
```

#### Component Generation
```vim
:Boil /path/to/templates/react/component.jsx component=UserCard props="name,email,avatar"
```

#### Documentation Templates
```vim
:Boil /path/to/templates/docs/api.md service=UserService version=2.1 maintainer=Backend
```

## Template Examples

### Python Class Template

**File: `python/class.py`**
```python
"""
{{description}}
Author: {{author}}
Created: {{__date__}}
"""

class {{class_name}}:
    """{{class_description}}"""

    def __init__(self):
        """Initialize {{class_name}}."""
        pass

    def __str__(self):
        """String representation of {{class_name}}."""
        return f"{{class_name}}()"
```

**Usage:**
```vim
:Boil /path/to/templates/python/class.py class_name=UserManager description="User management system"
```

### React Component Template

**File: `javascript/react-component.jsx`**
```jsx
import React from 'react';
import PropTypes from 'prop-types';

/**
 * {{component}} component
 * {{description}}
 * @author {{author}}
 */
const {{component}} = ({ {{props}} }) => {
  return (
    <div className="{{component_class}}">
      <h1>{{component}}</h1>
      {/* Component content */}
    </div>
  );
};

{{component}}.propTypes = {
  {{prop_types}}
};

{{component}}.defaultProps = {
  {{default_props}}
};

export default {{component}};
```

**Usage:**
```vim
:Boil /path/to/templates/javascript/react-component.jsx component=UserCard props="name,email" author=Frontend
```
