# Template Creation Guide

This document covers everything you need to know about creating and organizing templates for boil.nvim.

## Table of Contents

- [Template Basics](#template-basics)
- [Directory Structure](#directory-structure)
- [Variable Usage](#variable-usage)
- [Runtime Variables](#runtime-variables)
- [Template Examples](#template-examples)
- [Best Practices](#best-practices)

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

Use `key=value` syntax with the `:Boil` command:

```vim
" Basic usage
:Boil template.py author=John project=MyApp

" Multiple variables
:Boil react-component.jsx component=UserProfile author=Jane team=Frontend

" With quotes for values containing spaces
:Boil readme.md project="My Amazing App" description="A revolutionary tool"

" Escape sequences for special characters
:Boil config.py database="localhost:5432" connection="user=admin\\npass=secret"
```

### Telescope Integration

Pass runtime variables to Telescope picker:

```vim
" Telescope with runtime variables
:Telescope boil author=John project=MyApp

" Multiple variables
:Telescope boil component=Header team=UI version=2.0
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
:Boil template.py author=John
```

### Practical Examples

#### Dynamic Project Setup
```vim
:Boil python/project.py project=WebAPI author=TeamLead version=1.0
```

#### Component Generation
```vim
:Boil react/component.jsx component=UserCard props="name,email,avatar"
```

#### Documentation Templates
```vim
:Boil docs/api.md service=UserService version=2.1 maintainer=Backend
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
:Boil python/class.py class_name=UserManager description="User management system"
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
:Boil react-component.jsx component=UserCard props="name,email" author=Frontend
```

### API Documentation Template

**File: `docs/api.md`**
```markdown
# {{service}} API

**Version:** {{version}}
**Author:** {{author}}
**Last Updated:** {{__date__}}

## Overview

{{description}}

## Endpoints

### GET /{{endpoint}}

{{endpoint_description}}

**Parameters:**
- `param1` (string): {{param1_description}}
- `param2` (number): {{param2_description}}

**Response:**
```json
{
  "status": "success",
  "data": {{sample_response}}
}
```

## Error Codes

| Code | Description |
|------|-------------|
| 400  | Bad Request |
| 404  | Not Found   |
| 500  | Server Error|

## Examples

{{examples}}
```

**Usage:**
```vim
:Boil api.md service=UserAPI version=2.0 endpoint=users description="User management API"
```

### Configuration File Template

**File: `config/env.conf`**
```ini
# {{project}} Configuration
# Generated: {{__date__}}
# Environment: {{environment}}

[database]
host={{db_host}}
port={{db_port}}
name={{db_name}}
user={{db_user}}

[api]
base_url={{api_url}}
timeout={{timeout}}
rate_limit={{rate_limit}}

[logging]
level={{log_level}}
format={{log_format}}
```

**Usage:**
```vim
:Boil env.conf project=WebApp environment=production db_host=localhost db_port=5432
```

## Best Practices

### 1. Use Descriptive Variable Names

```
Good: {{component_name}}, {{api_version}}, {{author_email}}
Avoid: {{c}}, {{v}}, {{e}}
```

### 2. Provide Meaningful Defaults

```lua
variables = {
  author = "Development Team",  -- Better than empty
  license = "MIT",             -- Common default
  version = "1.0.0"           -- Semantic versioning
}
```

### 3. Group Related Templates

Organize templates by language, framework, or purpose:
```
templates/
├── web/
│   ├── html/
│   ├── css/
│   └── javascript/
├── backend/
│   ├── python/
│   ├── go/
│   └── rust/
└── docs/
    ├── api/
    ├── user/
    └── dev/
```

### 4. Use Comments for Complex Variables

```python
# Project: {{project}}
# Module: {{module}}
# Purpose: {{purpose}}
# Dependencies: {{dependencies}}
```

### 5. Create Template Families

Design templates that work together:
- `model.py` + `test_model.py`
- `component.jsx` + `component.test.js` + `component.stories.js`
- `service.go` + `service_test.go` + `mock_service.go`

### 6. Leverage Runtime Variables for Flexibility

Design templates to accept runtime variables for maximum reusability:

```python
# Template accepts: class_name, base_class, methods
class {{class_name}}({{base_class}}):
    """{{description}}"""

    {{methods}}
```

### 7. Keep Templates Simple

Remember the "Less is More" philosophy - complex logic belongs in Lua configuration, not templates:

```lua
-- Good: Logic in config
variables = {
  header = function()
    return vim.bo.filetype == "python" and "#!/usr/bin/env python3" or ""
  end
}
```

```python
# Template stays simple
{{header}}
# Your code here
```

### 8. Test Your Templates

Create sample scenarios to verify templates work correctly:

```vim
" Test with minimal variables
:Boil template.py author=Test

" Test with all variables
:Boil template.py author=Test project=Sample version=1.0 description="Test template"
```
