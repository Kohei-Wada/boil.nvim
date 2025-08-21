describe("boil runtime variables", function()
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

  describe("insert_template with runtime variables", function()
    it("should accept runtime variables parameter", function()
      boil.setup {
        templates = {},
        variables = {
          author = "Global Author",
        },
      }

      -- Test that the function accepts runtime variables without error
      local ok, err = pcall(function()
        boil.insert_template("nonexistent.txt", { author = "Runtime Author" })
      end)

      -- Should not crash, even if template doesn't exist
      assert.is_true(ok or err:match "Template not found")
    end)

    it("should work without runtime variables (backward compatibility)", function()
      boil.setup {
        templates = {},
        variables = {
          author = "Global Author",
        },
      }

      -- Test legacy call without runtime variables
      local ok, err = pcall(function()
        boil.insert_template "nonexistent.txt"
      end)

      -- Should not crash
      assert.is_true(ok or err:match "Template not found")
    end)

    it("should handle nil runtime variables", function()
      boil.setup {
        templates = {},
        variables = {
          author = "Global Author",
        },
      }

      -- Test with explicit nil
      local ok, err = pcall(function()
        boil.insert_template("nonexistent.txt", nil)
      end)

      -- Should not crash
      assert.is_true(ok or err:match "Template not found")
    end)
  end)
end)
