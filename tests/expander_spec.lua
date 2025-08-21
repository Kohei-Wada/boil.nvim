describe("boil.expander", function()
  local expander

  before_each(function()
    package.loaded["boil.expander"] = nil
    expander = require "boil.expander"
  end)

  describe("expand", function()
    it("should expand basic variables", function()
      local template = "File: {{__filename__}}\nBase: {{__basename__}}\nDate: {{__date__}}\nAuthor: {{__author__}}"
      local config = {
        variables = {
          __filename__ = function()
            return "test.lua"
          end,
          __basename__ = function()
            return "test"
          end,
          __author__ = "Test Author",
          __date__ = function()
            return "2024-01-01"
          end,
        },
      }

      local result = expander.expand(template, config)

      assert.is_string(result)
      assert.is_not_nil(result:match "File: test%.lua")
      assert.is_not_nil(result:match "Base: test")
      assert.is_not_nil(result:match "Date: 2024%-01%-01")
      assert.is_not_nil(result:match "Author: Test Author")
    end)

    it("should use template-specific variables over global ones", function()
      local template = "Author: {{author}}\nCompany: {{company}}"
      local config = {
        variables = {
          author = "Global Author",
          company = "Global Company",
        },
      }
      local template_config = {
        variables = {
          author = "Template Author",
        },
      }

      local result = expander.expand(template, config, template_config)

      assert.is_not_nil(result:match "Author: Template Author")
      assert.is_not_nil(result:match "Company: Global Company")
    end)

    it("should handle function variables", function()
      local template = "Project: {{project}}"
      local config = {
        variables = {
          project = function()
            return "MyProject"
          end,
        },
      }

      local result = expander.expand(template, config)

      assert.is_not_nil(result:match "Project: MyProject")
    end)

    it("should handle nil template_config", function()
      local template = "Author: {{author}}"
      local config = {
        variables = {
          author = "Global Author",
        },
      }

      local result = expander.expand(template, config, nil)

      assert.is_not_nil(result:match "Author: Global Author")
    end)

    it("should merge all variable sources correctly", function()
      local template = "A: {{a}}\nB: {{b}}\nC: {{c}}"
      local config = {
        variables = {
          a = "global_a",
          b = "global_b",
        },
      }
      local template_config = {
        variables = {
          b = "template_b",
          c = "template_c",
        },
      }

      local result = expander.expand(template, config, template_config)

      assert.is_not_nil(result:match "A: global_a")
      assert.is_not_nil(result:match "B: template_b")
      assert.is_not_nil(result:match "C: template_c")
    end)

    it("should handle function errors gracefully", function()
      local template = "Project: {{project}}\nAuthor: {{author}}"
      local config = {
        variables = {
          project = function()
            error "Failed to get project name"
          end,
          author = "Test Author",
        },
      }

      local result, err = expander.expand(template, config)

      assert.is_string(result)
      assert.is_string(err)
      assert.is_not_nil(err:match "Variable 'project' function failed")
      assert.is_not_nil(result:match "{{project:ERROR}}")
      assert.is_not_nil(result:match "Author: Test Author")
    end)

    it("should detect undefined variables", function()
      local template = "Name: {{name}}\nEmail: {{email}}\nPhone: {{phone}}"
      local config = {
        variables = {
          name = "John Doe",
        },
      }

      local result, err = expander.expand(template, config)

      assert.is_string(result)
      assert.is_string(err)
      assert.is_not_nil(err:match "Undefined variables")
      assert.is_not_nil(err:match "email")
      assert.is_not_nil(err:match "phone")
      assert.is_not_nil(result:match "Name: John Doe")
      assert.is_not_nil(result:match "{{email}}")
      assert.is_not_nil(result:match "{{phone}}")
    end)

    it("should handle nil return from function variables", function()
      local template = "Value: {{value}}"
      local config = {
        variables = {
          value = function()
            return nil
          end,
        },
      }

      local result = expander.expand(template, config)

      assert.is_string(result)
      assert.equals("Value: ", result)
    end)

    it("should return clean result when no errors", function()
      local template = "Hello {{name}}"
      local config = {
        variables = {
          name = "World",
        },
      }

      local result, err = expander.expand(template, config)

      assert.is_string(result)
      assert.is_nil(err)
      assert.equals("Hello World", result)
    end)

    -- Runtime Variables Tests
    it("should use runtime variables with highest priority", function()
      local template = "Author: {{author}}\nProject: {{project}}\nVersion: {{version}}"
      local config = {
        variables = {
          author = "Global Author",
          project = "Global Project",
          version = "1.0.0",
        },
      }
      local template_config = {
        variables = {
          author = "Template Author",
          project = "Template Project",
        },
      }
      local runtime_variables = {
        author = "Runtime Author",
      }

      local result = expander.expand(template, config, template_config, runtime_variables)

      assert.is_not_nil(result:match "Author: Runtime Author") -- Runtime wins
      assert.is_not_nil(result:match "Project: Template Project") -- Template wins over global
      assert.is_not_nil(result:match "Version: 1%.0%.0") -- Global used (no override)
    end)

    it("should handle runtime variables when template_config is nil", function()
      local template = "Name: {{name}}\nEmail: {{email}}"
      local config = {
        variables = {
          name = "Global Name",
          email = "global@example.com",
        },
      }
      local runtime_variables = {
        email = "runtime@example.com",
      }

      local result = expander.expand(template, config, nil, runtime_variables)

      assert.is_not_nil(result:match "Name: Global Name")
      assert.is_not_nil(result:match "Email: runtime@example%.com")
    end)

    it("should handle nil runtime variables gracefully", function()
      local template = "Author: {{author}}"
      local config = {
        variables = {
          author = "Global Author",
        },
      }

      local result = expander.expand(template, config, nil, nil)

      assert.is_not_nil(result:match "Author: Global Author")
    end)

    it("should handle empty runtime variables table", function()
      local template = "Author: {{author}}"
      local config = {
        variables = {
          author = "Global Author",
        },
      }
      local runtime_variables = {}

      local result = expander.expand(template, config, nil, runtime_variables)

      assert.is_not_nil(result:match "Author: Global Author")
    end)

    it("should allow runtime variables to define new variables", function()
      local template = "Name: {{name}}\nRole: {{role}}"
      local config = {
        variables = {
          name = "John",
        },
      }
      local runtime_variables = {
        role = "Developer",
      }

      local result = expander.expand(template, config, nil, runtime_variables)

      assert.is_not_nil(result:match "Name: John")
      assert.is_not_nil(result:match "Role: Developer")
    end)

    it("should maintain variable priority chain with all sources", function()
      local template = "A: {{a}}\nB: {{b}}\nC: {{c}}\nD: {{d}}"
      local config = {
        variables = {
          a = "global_a",
          b = "global_b",
          c = "global_c",
          d = "global_d",
        },
      }
      local template_config = {
        variables = {
          b = "template_b",
          c = "template_c",
        },
      }
      local runtime_variables = {
        c = "runtime_c",
      }

      local result = expander.expand(template, config, template_config, runtime_variables)

      assert.is_not_nil(result:match "A: global_a") -- Global only
      assert.is_not_nil(result:match "B: template_b") -- Template over global
      assert.is_not_nil(result:match "C: runtime_c") -- Runtime over template and global
      assert.is_not_nil(result:match "D: global_d") -- Global only
    end)

    it("should handle runtime variables with newline characters", function()
      local template = "Description: {{description}}\nCode: {{code}}"
      local config = {
        variables = {
          description = "Single line description",
        },
      }
      local runtime_variables = {
        description = "Multi-line\ndescription\nwith breaks",
        code = "function test() {\n  return true;\n}",
      }

      local result = expander.expand(template, config, nil, runtime_variables)

      -- Check that newlines are preserved
      assert.is_not_nil(result:match "Description: Multi%-line\ndescription\nwith breaks")
      assert.is_not_nil(result:match "Code: function test%(%) %{\n  return true;\n%}")
    end)

    it("should handle runtime variables with various whitespace characters", function()
      local template = "Spaced: {{spaced}}\nTabbed: {{tabbed}}\nMixed: {{mixed}}"
      local runtime_variables = {
        spaced = "  has   spaces  ",
        tabbed = "\thas\ttabs\t",
        mixed = " \t\n mixed \r\n content \t ",
      }

      local result = expander.expand(template, { variables = {} }, nil, runtime_variables)

      -- Verify whitespace is preserved exactly
      assert.is_not_nil(result:match "Spaced:   has   spaces  ")
      assert.is_not_nil(result:match "Tabbed: \thas\ttabs\t")
      assert.is_not_nil(result:match "Mixed:  \t\n mixed \r\n content \t ")
    end)

    it("should handle runtime variables with special regex characters", function()
      local template = "Pattern: {{pattern}}\nRegex: {{regex}}"
      local runtime_variables = {
        pattern = "*.js files",
        regex = "^[a-zA-Z]+$",
      }

      local result = expander.expand(template, { variables = {} }, nil, runtime_variables)

      -- These should work correctly despite containing regex special chars
      assert.is_not_nil(result:match "Pattern: %*%.js files")
      assert.is_not_nil(result:match "Regex: %^%[a%-zA%-Z%]%+%$")
    end)

    it("should handle runtime variables with percent characters", function()
      local template = "Progress: {{progress}}\nFormat: {{format}}\nMessage: {{message}}"
      local runtime_variables = {
        progress = "Loading: 100% complete",
        format = "Use %s for string and %d for numbers",
        message = "Result: 50% success rate\n%s will be processed next",
      }

      local result = expander.expand(template, { variables = {} }, nil, runtime_variables)

      -- Verify percent characters are handled correctly
      assert.is_not_nil(result:match "Progress: Loading: 100%% complete")
      assert.is_not_nil(result:match "Format: Use %%s for string and %%d for numbers")
      assert.is_not_nil(result:match "Message: Result: 50%% success rate\n%%s will be processed next")
    end)

    it("should handle runtime variables with complex multiline content", function()
      local template = "Script: {{script}}\nSQL: {{sql}}"
      local runtime_variables = {
        script = '#!/bin/bash\necho "Progress: 100%"\nif [ $# -eq 0 ]; then\n  echo "No args"\nfi',
        sql = "SELECT *\nFROM users\nWHERE name LIKE '%john%'\n  AND status = 'active';",
      }

      local result = expander.expand(template, { variables = {} }, nil, runtime_variables)

      -- Check that complex multiline content with % chars is preserved
      assert.is_not_nil(result:match "Script: #!/bin/bash")
      assert.is_not_nil(result:match 'echo "Progress: 100%%"')
      assert.is_not_nil(result:match "SQL: SELECT %*")
      assert.is_not_nil(result:match "WHERE name LIKE '%%john%%'")
    end)
  end)
end)
