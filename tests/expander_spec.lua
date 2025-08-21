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
  end)
end)
