describe("boil.config", function()
  local config

  before_each(function()
    package.loaded["boil.config"] = nil
    config = require "boil.config"
  end)

  describe("setup", function()
    it("should initialize with default values", function()
      config.setup()
      local options = config.get()

      assert.is_not_nil(options.templates)
      assert.is_table(options.templates)
      assert.is_not_nil(options.variables)
      assert.is_table(options.variables)
      assert.is_not_nil(options.variables.author)
    end)

    it("should merge user config with defaults", function()
      config.setup {
        variables = {
          author = "Test Author",
          custom_var = "custom value",
        },
      }
      local options = config.get()

      assert.equals("Test Author", options.variables.author)
      assert.equals("custom value", options.variables.custom_var)
      assert.is_table(options.templates)
    end)

    it("should expand template directory paths", function()
      config.setup {
        templates = {
          { path = "~/personal", variables = { author = "Personal" } },
          { path = "$HOME/company", variables = { author = "Company", company = "ACME" } },
        },
      }
      local options = config.get()

      assert.equals(2, #options.templates)
      assert.is_table(options.templates[1])
      -- Templates are directory-only now
      assert.is_nil(options.templates[1].path:match "^~")
      assert.is_nil(options.templates[2].path:match "%$HOME")
      assert.equals("Personal", options.templates[1].variables.author)
      assert.equals("Company", options.templates[2].variables.author)
      assert.equals("ACME", options.templates[2].variables.company)
    end)

    it("should handle nil user config", function()
      config.setup(nil)
      local options = config.get()

      assert.is_not_nil(options)
      assert.is_table(options.templates)
      assert.is_table(options.variables)
    end)

    it("should handle empty user config", function()
      config.setup {}
      local options = config.get()

      assert.is_not_nil(options)
      assert.is_table(options.templates)
      assert.is_table(options.variables)
    end)

    it("should have empty templates by default", function()
      config.setup {
        variables = {
          author = "New Author",
        },
      }
      local options = config.get()

      assert.is_table(options.templates)
      assert.equals(0, #options.templates)
    end)

    it("should completely replace templates when provided", function()
      config.setup {
        templates = {
          { path = "/custom/path/only" },
        },
      }
      local options = config.get()

      assert.equals(1, #options.templates)
      assert.equals(vim.fn.expand "/custom/path/only", options.templates[1].path)
    end)

    it("should handle template configs without type field", function()
      config.setup {
        templates = {
          { path = "/some/path" },
          { path = "/another/path" },
        },
      }
      local options = config.get()

      assert.equals(2, #options.templates)
      assert.is_string(options.templates[1].path)
      assert.is_string(options.templates[2].path)
    end)

    it("should add default filter function to templates", function()
      config.setup {
        templates = {
          { path = "/some/path" },
        },
      }
      local options = config.get()

      assert.is_function(options.templates[1].filter)
      assert.is_true(options.templates[1].filter {})
    end)

    it("should include default logger configuration", function()
      config.setup()
      local options = config.get()

      assert.is_table(options.logger)
      assert.equals(vim.log.levels.INFO, options.logger.level)
      assert.equals("[boil.nvim]", options.logger.prefix)
    end)

    it("should merge user logger configuration with defaults", function()
      config.setup {
        logger = {
          level = vim.log.levels.DEBUG,
          prefix = "[custom]",
        },
      }
      local options = config.get()

      assert.is_table(options.logger)
      assert.equals(vim.log.levels.DEBUG, options.logger.level)
      assert.equals("[custom]", options.logger.prefix)
    end)

    it("should override only specified logger options", function()
      config.setup {
        logger = {
          level = vim.log.levels.WARN,
          -- prefix not specified, should use default
        },
      }
      local options = config.get()

      assert.is_table(options.logger)
      assert.equals(vim.log.levels.WARN, options.logger.level)
      assert.equals("[boil.nvim]", options.logger.prefix) -- default
    end)
  end)

  describe("get", function()
    it("should return empty table before setup", function()
      local options = config.get()
      assert.is_table(options)
      assert.same({}, options)
    end)

    it("should return options after setup", function()
      config.setup {
        variables = {
          author = "Test",
        },
      }
      local options = config.get()

      assert.is_not_nil(options)
      assert.equals("Test", options.variables.author)
    end)
  end)
end)
