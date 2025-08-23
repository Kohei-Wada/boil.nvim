local boil = require "boil"
local config = require "boil.config"

describe("Visual mode selection replacement", function()
  local test_template_dir
  local original_config

  before_each(function()
    -- Create temporary directory for test templates
    test_template_dir = vim.fn.tempname()
    vim.fn.mkdir(test_template_dir, "p")

    -- Save original config
    original_config = config.get()

    -- Setup test configuration
    boil.setup {
      templates = {
        { path = test_template_dir },
      },
      variables = {
        test_var = "test_value",
      },
    }

    -- Create test template files
    local simple_template = test_template_dir .. "/simple.txt"
    local simple_file = io.open(simple_template, "w")
    simple_file:write "Template Content"
    simple_file:close()

    local multi_template = test_template_dir .. "/multi.txt"
    local multi_file = io.open(multi_template, "w")
    multi_file:write "Line 1\nLine 2\nLine 3"
    multi_file:close()

    local var_template = test_template_dir .. "/variable.txt"
    local var_file = io.open(var_template, "w")
    var_file:write "Hello {{test_var}}"
    var_file:close()
  end)

  after_each(function()
    -- Clean up temporary directory
    vim.fn.delete(test_template_dir, "rf")

    -- Restore original config
    config.setup(original_config)
  end)

  it("replaces visual selection with template content", function()
    -- Create a new buffer with content
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(buf)
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {
      "First line",
      "Second line to replace",
      "Third line",
    })

    -- Set visual selection (line 2)
    vim.fn.setpos("'<", { 0, 2, 1, 0 })
    vim.fn.setpos("'>", { 0, 2, vim.fn.col "$", 0 })

    -- Insert template
    boil.insert_template(test_template_dir .. "/simple.txt")

    -- Check result
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert.are.same({
      "First line",
      "Template Content",
      "Third line",
    }, lines)
  end)

  it("replaces multi-line visual selection", function()
    -- Create a new buffer with content
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(buf)
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {
      "First line",
      "Replace this",
      "And this too",
      "Fourth line",
    })

    -- Set visual selection (lines 2-3)
    vim.fn.setpos("'<", { 0, 2, 1, 0 })
    vim.fn.setpos("'>", { 0, 3, vim.fn.col "$", 0 })

    -- Insert multi-line template
    boil.insert_template(test_template_dir .. "/multi.txt")

    -- Check result
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert.are.same({
      "First line",
      "Line 1",
      "Line 2",
      "Line 3",
      "Fourth line",
    }, lines)
  end)

  it("inserts at cursor position on non-empty line when no selection", function()
    -- Create a new buffer with content
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(buf)
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {
      "Hello world",
    })

    -- Position cursor after "Hello "
    vim.api.nvim_win_set_cursor(0, { 1, 5 })

    -- Clear any visual marks
    vim.fn.setpos("'<", { 0, 0, 0, 0 })
    vim.fn.setpos("'>", { 0, 0, 0, 0 })

    -- Insert template
    boil.insert_template(test_template_dir .. "/simple.txt")

    -- Check result
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert.are.same({
      "HelloTemplate Content world",
    }, lines)
  end)

  it("replaces empty line with template", function()
    -- Create a new buffer with empty line
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(buf)
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {
      "First line",
      "",
      "Third line",
    })

    -- Position cursor on empty line
    vim.api.nvim_win_set_cursor(0, { 2, 0 })

    -- Clear any visual marks
    vim.fn.setpos("'<", { 0, 0, 0, 0 })
    vim.fn.setpos("'>", { 0, 0, 0, 0 })

    -- Insert template
    boil.insert_template(test_template_dir .. "/simple.txt")

    -- Check result
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert.are.same({
      "First line",
      "Template Content",
      "Third line",
    }, lines)
  end)

  it("expands variables in selected text replacement", function()
    -- Create a new buffer with content
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(buf)
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {
      "Replace me",
    })

    -- Set visual selection
    vim.fn.setpos("'<", { 0, 1, 1, 0 })
    vim.fn.setpos("'>", { 0, 1, vim.fn.col "$", 0 })

    -- Insert template with variables
    boil.insert_template(test_template_dir .. "/variable.txt")

    -- Check result
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert.are.same({
      "Hello test_value",
    }, lines)
  end)

  it("handles multi-line template insertion at cursor position", function()
    -- Create a new buffer with content
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(buf)
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {
      "Before template after",
    })

    -- Position cursor after "Before "
    vim.api.nvim_win_set_cursor(0, { 1, 6 })

    -- Clear any visual marks
    vim.fn.setpos("'<", { 0, 0, 0, 0 })
    vim.fn.setpos("'>", { 0, 0, 0, 0 })

    -- Insert multi-line template
    boil.insert_template(test_template_dir .. "/multi.txt")

    -- Check result
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert.are.same({
      "BeforeLine 1",
      "Line 2",
      "Line 3 template after",
    }, lines)
  end)
end)
