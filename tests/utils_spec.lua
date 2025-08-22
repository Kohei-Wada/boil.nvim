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

    it("should unescape common escape sequences in values", function()
      local args =
        { "template.py", "multiline=line1\\nline2\\nline3", "tabbed=col1\\tcol2", 'quote=She said \\"Hello\\"' }
      local template_path, runtime_vars = utils.parse_args(args)

      assert.equals("template.py", template_path)
      assert.equals("line1\nline2\nline3", runtime_vars.multiline)
      assert.equals("col1\tcol2", runtime_vars.tabbed)
      assert.equals('She said "Hello"', runtime_vars.quote)
    end)

    it("should handle mixed escaped and unescaped sequences", function()
      local args = { "template.py", "mixed=Path: C:\\\\temp\\nNewline here\\tTab here", "backslash=Keep \\\\ this" }
      local template_path, runtime_vars = utils.parse_args(args)

      assert.equals("template.py", template_path)
      assert.equals("Path: C:\\temp\nNewline here\tTab here", runtime_vars.mixed)
      assert.equals("Keep \\ this", runtime_vars.backslash)
    end)

    it("should handle escape sequences in quoted values", function()
      local args = { "template.py", 'message="Hello\\nWorld\\tTab"', "path='C:\\\\Users\\\\test'" }
      local template_path, runtime_vars = utils.parse_args(args)

      assert.equals("template.py", template_path)
      assert.equals("Hello\nWorld\tTab", runtime_vars.message)
      assert.equals("C:\\Users\\test", runtime_vars.path)
    end)

    it("should ignore extra non-key=value arguments after template path", function()
      local args = { "template.py", "ignored_arg1", "ignored_arg2", "author=John", "project=test" }
      local template_path, runtime_vars = utils.parse_args(args)

      assert.equals("template.py", template_path)
      assert.equals("John", runtime_vars.author)
      assert.equals("test", runtime_vars.project)
      -- ignored_arg1 and ignored_arg2 should not affect the result
    end)

    it("should handle the example case: var var1 var2 x=a y=c", function()
      local args = { "var", "var1", "var2", "x=a", "y=c" }
      local template_path, runtime_vars = utils.parse_args(args)

      assert.equals("var", template_path) -- First non-key=value arg
      assert.equals("a", runtime_vars.x)
      assert.equals("c", runtime_vars.y)
      -- var1 and var2 should be ignored
      assert.is_nil(runtime_vars.var1)
      assert.is_nil(runtime_vars.var2)
    end)

    it("should handle values with spaces (pre-parsed)", function()
      -- Note: These would be pre-parsed by shell/Vim, so we test the result
      local args = { "template.py", "description=Hello World", "path=/path with spaces" }
      local template_path, runtime_vars = utils.parse_args(args)

      assert.equals("template.py", template_path)
      assert.equals("Hello World", runtime_vars.description)
      assert.equals("/path with spaces", runtime_vars.path)
    end)

    it("should handle values with newlines and tabs", function()
      local args = { "template.py", "multiline=line1\nline2", "tabbed=col1\tcol2" }
      local template_path, runtime_vars = utils.parse_args(args)

      assert.equals("template.py", template_path)
      assert.equals("line1\nline2", runtime_vars.multiline)
      assert.equals("col1\tcol2", runtime_vars.tabbed)
    end)

    it("should handle values with various whitespace characters", function()
      local args = { "template.py", "spaces=   multiple   spaces   ", "mixed= \t\n mixed \r\n " }
      local template_path, runtime_vars = utils.parse_args(args)

      assert.equals("template.py", template_path)
      assert.equals("   multiple   spaces   ", runtime_vars.spaces)
      assert.equals(" \t\n mixed \r\n ", runtime_vars.mixed)
    end)

    it("should handle literal backslashes and escape sequences", function()
      local args = { "template.py", "backslash=path\\\\to\\\\file", 'quote=She said "Hello"' }
      local template_path, runtime_vars = utils.parse_args(args)

      assert.equals("template.py", template_path)
      assert.equals("path\\to\\file", runtime_vars.backslash)
      assert.equals('She said "Hello"', runtime_vars.quote)
    end)

    it("should handle empty values with quotes", function()
      local args = { "template.py", 'empty=""', "single=''" }
      local template_path, runtime_vars = utils.parse_args(args)

      assert.equals("template.py", template_path)
      assert.equals("", runtime_vars.empty)
      assert.equals("", runtime_vars.single)
    end)

    it("should handle values with only whitespace", function()
      local args = { "template.py", "spaces=   ", "tabs=\t\t\t" }
      local template_path, runtime_vars = utils.parse_args(args)

      assert.equals("template.py", template_path)
      assert.equals("   ", runtime_vars.spaces)
      assert.equals("\t\t\t", runtime_vars.tabs)
    end)

    it("should handle complex quoted values with special chars", function()
      local args = { "template.py", 'json={"key": "value with spaces"}', "regex='\\\\d+\\\\.\\\\d+'" }
      local template_path, runtime_vars = utils.parse_args(args)

      assert.equals("template.py", template_path)
      assert.equals('{"key": "value with spaces"}', runtime_vars.json)
      assert.equals("\\d+\\.\\d+", runtime_vars.regex)
    end)

    -- Edge case tests for Copilot feedback fixes
    it("should ignore arguments with empty keys", function()
      local args = { "template.py", "=value", "=another", "valid=good" }
      local template_path, runtime_vars = utils.parse_args(args)

      assert.equals("template.py", template_path)
      assert.is_nil(runtime_vars[""])
      assert.equals("good", runtime_vars.valid)
      -- Should have only one valid variable
      local count = 0
      for _ in pairs(runtime_vars) do
        count = count + 1
      end
      assert.equals(1, count)
    end)

    it("should preserve unknown escape sequences", function()
      local args = { "template.py", "unknown=\\b\\f\\v\\x41", "known=\\n\\t" }
      local template_path, runtime_vars = utils.parse_args(args)

      assert.equals("template.py", template_path)
      -- Unknown escape sequences should be preserved
      assert.equals("\\b\\f\\v\\x41", runtime_vars.unknown)
      -- Known escape sequences should be converted
      assert.equals("\n\t", runtime_vars.known)
    end)
  end)
end)
