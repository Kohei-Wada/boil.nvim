describe("boil.templates", function()
  local templates

  before_each(function()
    package.loaded["boil.templates"] = nil
    package.loaded["boil.sources"] = nil
    package.loaded["boil.sources.dir"] = nil
    templates = require "boil.templates"
  end)

  describe("find_templates with filter", function()
    it("should apply filter function to exclude templates", function()
      local temp_dir = vim.fn.tempname()
      vim.fn.mkdir(temp_dir, "p")

      -- Create test files
      vim.fn.writefile({ "test content" }, temp_dir .. "/include.txt")
      vim.fn.writefile({ "test content" }, temp_dir .. "/exclude.txt")
      vim.fn.writefile({ "test content" }, temp_dir .. "/test.py")

      local config = {
        templates = {
          {
            path = temp_dir,
            type = "dir",
            filter = function(template)
              -- Exclude templates with "exclude" in the display name
              return not templates.get_display_name(template):match "exclude"
            end,
          },
        },
      }

      local result = templates.find_templates(config)

      assert.equals(2, #result)
      local paths = {}
      for _, template in ipairs(result) do
        table.insert(paths, vim.fn.fnamemodify(template.path, ":t:r"))
      end

      -- Check by filename (without extension)
      local has_include = false
      local has_test = false
      local has_exclude = false
      for _, template in ipairs(result) do
        local basename = vim.fn.fnamemodify(template.path, ":t:r")
        if basename == "include" then
          has_include = true
        end
        if basename == "test" then
          has_test = true
        end
        if basename == "exclude" then
          has_exclude = true
        end
      end
      assert.is_truthy(has_include)
      assert.is_truthy(has_test)
      assert.is_falsy(has_exclude)

      -- Cleanup
      vim.fn.delete(temp_dir, "rf")
    end)

    it("should pass correct arguments to filter function", function()
      local temp_dir = vim.fn.tempname()
      vim.fn.mkdir(temp_dir .. "/subdir", "p")
      vim.fn.writefile({ "test" }, temp_dir .. "/subdir/test.py")

      local filter_args = {}
      local config = {
        templates = {
          {
            path = temp_dir,
            type = "dir",
            filter = function(template)
              -- Store the template object
              filter_args = template
              return true
            end,
          },
        },
      }

      templates.find_templates(config)

      -- Check the interface
      assert.is_truthy(filter_args.path:match "test%.py$")
      assert.is_truthy(templates.get_display_name(filter_args):match "test%.py.*")
      assert.equals("dir", filter_args.config.type)
      assert.is_not_nil(filter_args.config.name or filter_args.config.path)
      assert.is_string(filter_args.path)

      -- Cleanup
      vim.fn.delete(temp_dir, "rf")
    end)

    it("should work without filter", function()
      local temp_dir = vim.fn.tempname()
      vim.fn.mkdir(temp_dir, "p")
      vim.fn.writefile({ "test" }, temp_dir .. "/test1.txt")
      vim.fn.writefile({ "test" }, temp_dir .. "/test2.txt")

      local config = {
        templates = {
          { path = temp_dir, type = "dir" },
        },
      }

      local result = templates.find_templates(config)

      assert.equals(2, #result)

      -- Cleanup
      vim.fn.delete(temp_dir, "rf")
    end)

    it("should filter by file extension", function()
      local temp_dir = vim.fn.tempname()
      vim.fn.mkdir(temp_dir, "p")
      vim.fn.writefile({ "test" }, temp_dir .. "/python_test.py")
      vim.fn.writefile({ "test" }, temp_dir .. "/js_test.js")
      vim.fn.writefile({ "test" }, temp_dir .. "/lua_test.lua")

      local config = {
        templates = {
          {
            path = temp_dir,
            type = "dir",
            filter = function(template)
              -- Only include Python and Lua files
              return template.path:match "%.py$" or template.path:match "%.lua$"
            end,
          },
        },
      }

      local result = templates.find_templates(config)

      assert.equals(2, #result)
      local paths = {}
      for _, template in ipairs(result) do
        table.insert(paths, vim.fn.fnamemodify(template.path, ":t:r"))
      end

      assert.is_truthy(vim.tbl_contains(paths, "python_test"))
      assert.is_truthy(vim.tbl_contains(paths, "lua_test"))
      assert.is_falsy(vim.tbl_contains(paths, "js_test"))

      -- Cleanup
      vim.fn.delete(temp_dir, "rf")
    end)
  end)

  describe("global filter", function()
    it("should apply global filter after directory filter", function()
      local temp_dir = vim.fn.tempname()
      vim.fn.mkdir(temp_dir, "p")

      -- Create test files
      vim.fn.writefile({ "test" }, temp_dir .. "/allowed.txt")
      vim.fn.writefile({ "test" }, temp_dir .. "/blocked.txt")
      vim.fn.writefile({ "test" }, temp_dir .. "/filtered.txt")

      local config = {
        templates = {
          {
            path = temp_dir,
            type = "dir",
            filter = function(template)
              -- Directory filter blocks "filtered"
              return not templates.get_display_name(template):match "filtered"
            end,
          },
        },
        filter = function(template)
          -- Global filter blocks "blocked"
          return not templates.get_display_name(template):match "blocked"
        end,
      }

      local result = templates.find_templates(config)

      assert.equals(1, #result)
      assert.equals("allowed", vim.fn.fnamemodify(result[1].path, ":t:r"))

      -- Cleanup
      vim.fn.delete(temp_dir, "rf")
    end)

    it("should pass correct arguments to global filter including source", function()
      local temp_dir = vim.fn.tempname()
      vim.fn.mkdir(temp_dir, "p")
      vim.fn.writefile({ "test" }, temp_dir .. "/test.txt")

      local filter_args = {}
      local config = {
        templates = {
          { path = temp_dir, type = "dir" },
        },
        filter = function(template)
          filter_args = template
          return true
        end,
      }

      templates.find_templates(config)

      -- Check the new interface
      assert.is_truthy(filter_args.path:match "test%.txt$")
      assert.is_truthy(templates.get_display_name(filter_args):match "test%.txt.*")
      assert.equals("dir", filter_args.config.type)
      assert.is_not_nil(filter_args.config.name or filter_args.config.path)
      assert.is_string(filter_args.path)

      -- Cleanup
      vim.fn.delete(temp_dir, "rf")
    end)

    it("should work without global filter", function()
      local temp_dir = vim.fn.tempname()
      vim.fn.mkdir(temp_dir, "p")
      vim.fn.writefile({ "test" }, temp_dir .. "/test.txt")

      local config = {
        templates = {
          { path = temp_dir, type = "dir" },
        },
        -- No global filter
      }

      local result = templates.find_templates(config)

      assert.equals(1, #result)
      assert.equals("test", vim.fn.fnamemodify(result[1].path, ":t:r"))

      -- Cleanup
      vim.fn.delete(temp_dir, "rf")
    end)
  end)

  describe("duplicate handling", function()
    it("should handle duplicate templates from nested directories", function()
      -- Setup nested directory structure
      local nested_dir = "/tmp/boil_test_nested"
      local child_dir = nested_dir .. "/child"

      vim.fn.mkdir(nested_dir, "p")
      vim.fn.mkdir(child_dir, "p")

      -- Create template in child directory
      vim.fn.writefile({ "Nested template content" }, child_dir .. "/test.txt")

      local config = {
        templates = {
          {
            name = "parent",
            path = nested_dir,
            type = "dir",
            variables = { source = "parent" },
          },
          {
            name = "child",
            path = child_dir,
            type = "dir",
            variables = { source = "child" },
          },
        },
      }

      local result = templates.find_templates(config)

      -- Should only have one instance of test.txt (from child source)
      local test_templates = vim.tbl_filter(function(t)
        return templates.get_display_name(t):match "test%.txt"
      end, result)

      assert.equals(1, #test_templates)
      assert.equals("child", test_templates[1].config.name)
      assert.equals("child", test_templates[1].config.variables.source)

      -- Cleanup
      vim.fn.delete(nested_dir, "rf")
    end)

    it("should prefer more specific source when duplicates exist", function()
      local base_dir = "/tmp/boil_test_specific"
      local sub_dir = base_dir .. "/sub"

      vim.fn.mkdir(base_dir, "p")
      vim.fn.mkdir(sub_dir, "p")

      -- Create the SAME FILE that will be found by both sources
      -- The key insight: create file in subdirectory that parent also scans
      vim.fn.writefile({ "Template {{source}}" }, sub_dir .. "/duplicate.txt")

      local config = {
        templates = {
          {
            name = "base",
            path = base_dir, -- This will find sub/duplicate.txt as "sub/duplicate.txt"
            type = "dir",
            variables = { source = "base" },
          },
          {
            name = "specific",
            path = sub_dir, -- This will find duplicate.txt as "duplicate.txt"
            type = "dir",
            variables = { source = "specific" },
          },
        },
      }

      local result = templates.find_templates(config)

      -- Both sources should find the same physical file
      local duplicate_templates = vim.tbl_filter(function(t)
        return t.path:match "duplicate%.txt$" -- Same absolute path
      end, result)

      -- Should only have one (the more specific "specific" source wins)
      assert.equals(1, #duplicate_templates)
      assert.equals("specific", duplicate_templates[1].config.name)

      -- Cleanup
      vim.fn.delete(base_dir, "rf")
    end)
  end)
end)
