describe("boil.utils", function()
  local utils

  before_each(function()
    package.loaded["boil.utils"] = nil
    utils = require "boil.utils"
  end)

  describe("parse_args", function()
    it("should parse template path and runtime variables", function()
      local args = { "template.py", "author=John", "project=myapp", "version=1.0" }
      local template_path, runtime_vars = utils.parse_args(args)

      assert.equals("template.py", template_path)
      assert.equals("John", runtime_vars.author)
      assert.equals("myapp", runtime_vars.project)
      assert.equals("1.0", runtime_vars.version)
    end)

    it("should handle only runtime variables (no template path)", function()
      local args = { "author=Jane", "project=webapp", "debug=true" }
      local template_path, runtime_vars = utils.parse_args(args)

      assert.is_nil(template_path)
      assert.equals("Jane", runtime_vars.author)
      assert.equals("webapp", runtime_vars.project)
      assert.equals("true", runtime_vars.debug)
    end)

    it("should handle only template path (no variables)", function()
      local args = { "template.js" }
      local template_path, runtime_vars = utils.parse_args(args)

      assert.equals("template.js", template_path)
      assert.is_same({}, runtime_vars)
    end)

    it("should handle empty arguments", function()
      local args = {}
      local template_path, runtime_vars = utils.parse_args(args)

      assert.is_nil(template_path)
      assert.is_same({}, runtime_vars)
    end)

    it("should remove quotes from values", function()
      local args = { "template.py", 'author="John Smith"', "description='A test file'" }
      local template_path, runtime_vars = utils.parse_args(args)

      assert.equals("template.py", template_path)
      assert.equals("John Smith", runtime_vars.author)
      assert.equals("A test file", runtime_vars.description)
    end)

    it("should handle values without quotes", function()
      local args = { "template.py", "author=JohnSmith", "project=test" }
      local template_path, runtime_vars = utils.parse_args(args)

      assert.equals("template.py", template_path)
      assert.equals("JohnSmith", runtime_vars.author)
      assert.equals("test", runtime_vars.project)
    end)

    it("should handle mixed argument order", function()
      local args = { "author=Dev", "template.js", "project=frontend", "debug=true" }
      local template_path, runtime_vars = utils.parse_args(args)

      -- First non-key=value argument becomes template path
      assert.equals("template.js", template_path)
      assert.equals("Dev", runtime_vars.author)
      assert.equals("frontend", runtime_vars.project)
      assert.equals("true", runtime_vars.debug)
    end)

    it("should handle special characters in values", function()
      local args = { "template.py", "path=/home/user", "email=user@example.com" }
      local template_path, runtime_vars = utils.parse_args(args)

      assert.equals("template.py", template_path)
      assert.equals("/home/user", runtime_vars.path)
      assert.equals("user@example.com", runtime_vars.email)
    end)

    it("should handle values with equals signs", function()
      local args = { "template.py", "equation=x=y+1", "config=debug=true" }
      local template_path, runtime_vars = utils.parse_args(args)

      assert.equals("template.py", template_path)
      assert.equals("x=y+1", runtime_vars.equation)
      assert.equals("debug=true", runtime_vars.config)
    end)

    it("should ignore arguments that look like variables but are not (no value)", function()
      local args = { "template=", "author=John", "project" }
      local template_path, runtime_vars = utils.parse_args(args)

      -- "project" should be template path since it's not key=value
      assert.equals("project", template_path)
      assert.equals("", runtime_vars.template) -- Empty value after =
      assert.equals("John", runtime_vars.author)
    end)

    it("should handle unicode characters in values", function()
      local args = { "template.py", "author=João", "message=こんにちは" }
      local template_path, runtime_vars = utils.parse_args(args)

      assert.equals("template.py", template_path)
      assert.equals("João", runtime_vars.author)
      assert.equals("こんにちは", runtime_vars.message)
    end)
  end)
end)
