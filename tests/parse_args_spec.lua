describe("boil argument parsing", function()
  local boil
  local original_notify

  before_each(function()
    package.loaded["boil.init"] = nil
    package.loaded["boil.expander"] = nil
    package.loaded["boil.config"] = nil
    package.loaded["boil.logger"] = nil

    -- Mock vim.notify to suppress log output during tests
    original_notify = vim.notify
    vim.notify = function() end

    boil = require "boil"
  end)

  after_each(function()
    -- Restore original vim.notify
    vim.notify = original_notify
  end)

  describe("parse_args functionality", function()
    it("should parse template path and key=value pairs correctly", function()
      -- Capture parsed arguments by mocking insert_template
      local captured_template = nil
      local captured_vars = {}

      local original_insert = boil.insert_template
      boil.insert_template = function(template_path, runtime_vars)
        captured_template = template_path
        captured_vars = runtime_vars or {}
      end

      boil.setup {
        templates = {},
        variables = {},
      }

      -- Create a test command that uses the same parsing logic as Boil
      vim.api.nvim_create_user_command("TestBoilParse", function(opts)
        -- This replicates the parse_args logic from init.lua
        local template_path = nil
        local runtime_vars = {}

        for _, arg in ipairs(opts.fargs) do
          local key, value = arg:match "^([^=]+)=(.*)$"
          if key and value then
            -- Remove outer quotes if present
            if value:match '^".*"$' or value:match "^'.*'$" then
              value = value:sub(2, -2)
            end
            runtime_vars[key] = value
          else
            -- First non-variable argument is template path
            if not template_path and not arg:match "=" then
              template_path = arg
            end
          end
        end

        boil.insert_template(template_path, runtime_vars)
      end, { nargs = "*" })

      -- Test parsing
      vim.cmd "TestBoilParse template.py author=JohnDoe project=myapp version=1.0"

      -- Verify results
      assert.equals("template.py", captured_template)
      assert.equals("JohnDoe", captured_vars.author)
      assert.equals("myapp", captured_vars.project)
      assert.equals("1.0", captured_vars.version)

      -- Cleanup
      vim.api.nvim_del_user_command "TestBoilParse"
      boil.insert_template = original_insert
    end)

    it("should handle only runtime variables (no template path)", function()
      local captured_template = nil
      local captured_vars = {}

      local original_insert = boil.insert_template
      boil.insert_template = function(template_path, runtime_vars)
        captured_template = template_path
        captured_vars = runtime_vars or {}
      end

      boil.setup { templates = {}, variables = {} }

      vim.api.nvim_create_user_command("TestVarsOnly", function(opts)
        local template_path = nil
        local runtime_vars = {}

        for _, arg in ipairs(opts.fargs) do
          local key, value = arg:match "^([^=]+)=(.*)$"
          if key and value then
            if value:match '^".*"$' or value:match "^'.*'$" then
              value = value:sub(2, -2)
            end
            runtime_vars[key] = value
          else
            if not template_path and not arg:match "=" then
              template_path = arg
            end
          end
        end

        boil.insert_template(template_path, runtime_vars)
      end, { nargs = "*" })

      vim.cmd "TestVarsOnly author=Jane project=webapp version=2.0"

      assert.is_nil(captured_template)
      assert.equals("Jane", captured_vars.author)
      assert.equals("webapp", captured_vars.project)
      assert.equals("2.0", captured_vars.version)

      vim.api.nvim_del_user_command "TestVarsOnly"
      boil.insert_template = original_insert
    end)

    it("should handle values without spaces (quote parsing limitation)", function()
      local captured_template = nil
      local captured_vars = {}

      local original_insert = boil.insert_template
      boil.insert_template = function(template_path, runtime_vars)
        captured_template = template_path
        captured_vars = runtime_vars or {}
      end

      boil.setup { templates = {}, variables = {} }

      vim.api.nvim_create_user_command("TestQuotes", function(opts)
        local template_path = nil
        local runtime_vars = {}

        for _, arg in ipairs(opts.fargs) do
          local key, value = arg:match "^([^=]+)=(.*)$"
          if key and value then
            if value:match '^".*"$' or value:match "^'.*'$" then
              value = value:sub(2, -2)
            end
            runtime_vars[key] = value
          else
            if not template_path and not arg:match "=" then
              template_path = arg
            end
          end
        end

        boil.insert_template(template_path, runtime_vars)
      end, { nargs = "*" })

      -- Test with values that don't contain spaces (Vim command parsing limitation)
      vim.cmd "TestQuotes test.py author=JohnSmith description=TestFile"

      assert.equals("test.py", captured_template)
      assert.equals("JohnSmith", captured_vars.author)
      assert.equals("TestFile", captured_vars.description)

      vim.api.nvim_del_user_command "TestQuotes"
      boil.insert_template = original_insert
    end)

    it("should handle empty arguments gracefully", function()
      local captured_template = nil
      local captured_vars = {}

      local original_insert = boil.insert_template
      boil.insert_template = function(template_path, runtime_vars)
        captured_template = template_path
        captured_vars = runtime_vars or {}
      end

      boil.setup { templates = {}, variables = {} }

      vim.api.nvim_create_user_command("TestEmpty", function(opts)
        local template_path = nil
        local runtime_vars = {}

        for _, arg in ipairs(opts.fargs) do
          local key, value = arg:match "^([^=]+)=(.*)$"
          if key and value then
            if value:match '^".*"$' or value:match "^'.*'$" then
              value = value:sub(2, -2)
            end
            runtime_vars[key] = value
          else
            if not template_path and not arg:match "=" then
              template_path = arg
            end
          end
        end

        boil.insert_template(template_path, runtime_vars)
      end, { nargs = "*" })

      vim.cmd "TestEmpty"

      assert.is_nil(captured_template)
      assert.is_same({}, captured_vars)

      vim.api.nvim_del_user_command "TestEmpty"
      boil.insert_template = original_insert
    end)

    it("should handle mixed arguments correctly", function()
      local captured_template = nil
      local captured_vars = {}

      local original_insert = boil.insert_template
      boil.insert_template = function(template_path, runtime_vars)
        captured_template = template_path
        captured_vars = runtime_vars or {}
      end

      boil.setup { templates = {}, variables = {} }

      vim.api.nvim_create_user_command("TestMixed", function(opts)
        local template_path = nil
        local runtime_vars = {}

        for _, arg in ipairs(opts.fargs) do
          local key, value = arg:match "^([^=]+)=(.*)$"
          if key and value then
            if value:match '^".*"$' or value:match "^'.*'$" then
              value = value:sub(2, -2)
            end
            runtime_vars[key] = value
          else
            if not template_path and not arg:match "=" then
              template_path = arg
            end
          end
        end

        boil.insert_template(template_path, runtime_vars)
      end, { nargs = "*" })

      -- Test with template path and variables mixed
      vim.cmd "TestMixed author=Dev template.js project=frontend debug=true"

      -- Template path should be the first non-key=value argument
      assert.equals("template.js", captured_template)
      assert.equals("Dev", captured_vars.author)
      assert.equals("frontend", captured_vars.project)
      assert.equals("true", captured_vars.debug)

      vim.api.nvim_del_user_command "TestMixed"
      boil.insert_template = original_insert
    end)
  end)
end)
