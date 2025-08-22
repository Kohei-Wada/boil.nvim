describe("boil.telescope.config", function()
  local config

  before_each(function()
    -- Clear package cache to ensure clean state
    package.loaded["boil.telescope.config"] = nil
    package.loaded["telescope.themes"] = nil

    -- Mock telescope.themes
    package.loaded["telescope.themes"] = {
      get_ivy = function(opts)
        opts = opts or {}
        opts.ivy_theme_applied = true
        return opts
      end,
      get_dropdown = function(opts)
        opts = opts or {}
        opts.dropdown_theme_applied = true
        return opts
      end,
      get_cursor = function(opts)
        opts = opts or {}
        opts.cursor_theme_applied = true
        return opts
      end,
    }

    config = require "boil.telescope.config"
  end)

  describe("default configuration", function()
    it("should have correct default values", function()
      assert.equals("Boil Templates", config.default_config.prompt_title)
      assert.equals("Template Preview", config.default_config.previewer_title)
    end)
  end)

  describe("setup", function()
    it("should store user extension config", function()
      local user_config = {
        prompt_title = "Custom Templates",
        previewer_title = "Custom Preview",
      }

      config.setup(user_config)

      -- Test by calling merge_config which should use the stored config
      local merged_opts = config.merge_config {}
      assert.equals("Custom Templates", merged_opts.prompt_title)
      assert.equals("Custom Preview", merged_opts.previewer_title)
    end)

    it("should handle nil user config", function()
      assert.has_no.errors(function()
        config.setup(nil)
      end)

      -- Should still use default config
      local merged_opts = config.merge_config {}
      assert.equals("Boil Templates", merged_opts.prompt_title)
    end)

    it("should handle empty user config", function()
      config.setup {}

      local merged_opts = config.merge_config {}
      assert.equals("Boil Templates", merged_opts.prompt_title)
      assert.equals("Template Preview", merged_opts.previewer_title)
    end)
  end)

  describe("merge_config", function()
    it("should return default config when no options provided", function()
      local merged_opts = config.merge_config()

      assert.equals("Boil Templates", merged_opts.prompt_title)
      assert.equals("Template Preview", merged_opts.previewer_title)
    end)

    it("should return default config with empty options", function()
      local merged_opts = config.merge_config {}

      assert.equals("Boil Templates", merged_opts.prompt_title)
      assert.equals("Template Preview", merged_opts.previewer_title)
    end)

    it("should preserve runtime_vars in merged options", function()
      local test_runtime_vars = { author = "Test", project = "TestProject" }
      local opts = {
        prompt_title = "Custom Title",
        runtime_vars = test_runtime_vars,
      }

      local merged_opts = config.merge_config(opts)

      -- runtime_vars should be preserved in merged_opts
      assert.is_same(test_runtime_vars, merged_opts.runtime_vars)
      assert.equals("Custom Title", merged_opts.prompt_title)
    end)

    it("should handle nil runtime_vars", function()
      local opts = {
        prompt_title = "Custom Title",
        runtime_vars = nil,
      }

      local merged_opts = config.merge_config(opts)

      assert.is_nil(merged_opts.runtime_vars)
      assert.equals("Custom Title", merged_opts.prompt_title)
    end)

    it("should merge configs with correct priority: default < extension < runtime", function()
      -- Setup extension config
      config.setup {
        prompt_title = "Extension Title",
        previewer_title = "Extension Preview",
        extension_only = "extension_value",
      }

      -- Runtime options
      local opts = {
        prompt_title = "Runtime Title",
        runtime_only = "runtime_value",
      }

      local merged_opts = config.merge_config(opts)

      -- Runtime should override extension and default
      assert.equals("Runtime Title", merged_opts.prompt_title)
      -- Extension should override default
      assert.equals("Extension Preview", merged_opts.previewer_title)
      -- Extension-only and runtime-only should be preserved
      assert.equals("extension_value", merged_opts.extension_only)
      assert.equals("runtime_value", merged_opts.runtime_only)
    end)

    describe("theme handling", function()
      it("should apply ivy theme correctly", function()
        local opts = {
          theme = "ivy",
          prompt_title = "Test Title",
        }

        local merged_opts = config.merge_config(opts)

        assert.is_true(merged_opts.ivy_theme_applied)
        assert.equals("Test Title", merged_opts.prompt_title)
        assert.is_nil(merged_opts.theme) -- theme should be removed after processing
      end)

      it("should apply dropdown theme correctly", function()
        local opts = {
          theme = "dropdown",
        }

        local merged_opts = config.merge_config(opts)

        assert.is_true(merged_opts.dropdown_theme_applied)
        assert.is_nil(merged_opts.theme)
      end)

      it("should apply cursor theme correctly", function()
        local opts = {
          theme = "cursor",
        }

        local merged_opts = config.merge_config(opts)

        assert.is_true(merged_opts.cursor_theme_applied)
        assert.is_nil(merged_opts.theme)
      end)

      it("should handle non-existent theme gracefully", function()
        local opts = {
          theme = "non_existent_theme",
          prompt_title = "Test Title",
        }

        local merged_opts = config.merge_config(opts)

        -- Should not crash and should preserve other options
        assert.equals("Test Title", merged_opts.prompt_title)
        assert.is_nil(merged_opts.theme) -- theme should still be removed
        -- Should not have any theme applied flags
        assert.is_nil(merged_opts.ivy_theme_applied)
        assert.is_nil(merged_opts.dropdown_theme_applied)
        assert.is_nil(merged_opts.cursor_theme_applied)
      end)

      it("should handle nil theme correctly", function()
        local opts = {
          theme = nil,
          prompt_title = "Test Title",
        }

        local merged_opts = config.merge_config(opts)

        assert.equals("Test Title", merged_opts.prompt_title)
        assert.is_nil(merged_opts.theme)
      end)
    end)

    it("should preserve all other options during merge", function()
      local opts = {
        prompt_title = "Custom Title",
        runtime_vars = { author = "Test" },
        custom_option = "custom_value",
        nested = {
          deep = {
            value = "deep_value",
          },
        },
      }

      local merged_opts = config.merge_config(opts)

      assert.equals("Custom Title", merged_opts.prompt_title)
      assert.equals("Template Preview", merged_opts.previewer_title) -- from default
      assert.equals("custom_value", merged_opts.custom_option)
      assert.equals("deep_value", merged_opts.nested.deep.value)
      assert.is_same({ author = "Test" }, merged_opts.runtime_vars)
    end)
  end)

  describe("complex scenarios", function()
    it("should handle complex merge with extension config, runtime vars, and theme", function()
      -- Setup extension config
      config.setup {
        prompt_title = "Extension Title",
        theme = "ivy", -- This should be overridden by runtime
        extension_setting = "ext_value",
      }

      local opts = {
        prompt_title = "Runtime Title",
        theme = "dropdown",
        runtime_vars = { author = "TestAuthor", project = "TestProject" },
        runtime_setting = "runtime_value",
      }

      local merged_opts = config.merge_config(opts)

      -- Check runtime vars preserved
      assert.is_same({ author = "TestAuthor", project = "TestProject" }, merged_opts.runtime_vars)

      -- Check config merge priority
      assert.equals("Runtime Title", merged_opts.prompt_title) -- runtime wins
      assert.equals("Template Preview", merged_opts.previewer_title) -- default (not overridden)
      assert.equals("ext_value", merged_opts.extension_setting) -- from extension
      assert.equals("runtime_value", merged_opts.runtime_setting) -- from runtime

      -- Check theme application
      assert.is_true(merged_opts.dropdown_theme_applied) -- runtime theme wins
      assert.is_nil(merged_opts.theme) -- removed after processing
    end)
  end)
end)
