local expander = require "boil.expander"

describe("Selection variable indentation", function()
  it("preserves indentation for multi-line __selection__ variable", function()
    -- Setup config with __selection__ variable
    local test_config = {
      variables = {
        __selection__ = function()
          return "for i in $(seq 10);\ndo\n   echo $i\ndone"
        end,
      },
    }

    -- Template with indented placeholder
    local template_content = [[main () {
    {{__selection__}}
}]]

    -- Expand the template
    local result = expander.expand(template_content, test_config.variables)

    -- Expected result with proper indentation (adds 4 spaces to each line, preserving relative indentation)
    local expected = [[main () {
    for i in $(seq 10);
    do
       echo $i
    done
}]]

    assert.are.equal(expected, result)
  end)

  it("handles __selection__ at the beginning of a line", function()
    local test_config = {
      variables = {
        __selection__ = function()
          return "line1\nline2\nline3"
        end,
      },
    }

    local template_content = "    {{__selection__}}"
    local result = expander.expand(template_content, test_config.variables)

    local expected = "    line1\n    line2\n    line3"
    assert.are.equal(expected, result)
  end)

  it("handles __selection__ with mixed indentation", function()
    local test_config = {
      variables = {
        __selection__ = function()
          return "if (condition) {\n    doSomething();\n}"
        end,
      },
    }

    local template_content = [[
function wrapper() {
    {{__selection__}}
}]]

    local result = expander.expand(template_content, test_config.variables)

    local expected = [[
function wrapper() {
    if (condition) {
        doSomething();
    }
}]]

    assert.are.equal(expected, result)
  end)

  it("handles single-line __selection__ without modification", function()
    local test_config = {
      variables = {
        __selection__ = function()
          return "single line content"
        end,
      },
    }

    local template_content = "    {{__selection__}}"
    local result = expander.expand(template_content, test_config.variables)

    local expected = "    single line content"
    assert.are.equal(expected, result)
  end)

  it("handles __selection__ with tabs", function()
    local test_config = {
      variables = {
        __selection__ = function()
          return "line1\nline2"
        end,
      },
    }

    local template_content = "\t{{__selection__}}"
    local result = expander.expand(template_content, test_config.variables)

    local expected = "\tline1\n\tline2"
    assert.are.equal(expected, result)
  end)

  it("preserves existing indentation in the selection", function()
    local test_config = {
      variables = {
        __selection__ = function()
          -- Selection with its own indentation
          return "def method():\n    print('hello')\n    return True"
        end,
      },
    }

    local template_content = [[
class MyClass:
    {{__selection__}}
]]

    local result = expander.expand(template_content, test_config.variables)

    local expected = [[
class MyClass:
    def method():
        print('hello')
        return True
]]

    assert.are.equal(expected, result)
  end)

  it("handles empty lines in multi-line selection", function()
    local test_config = {
      variables = {
        __selection__ = function()
          return "line1\n\nline3"
        end,
      },
    }

    local template_content = "    {{__selection__}}"
    local result = expander.expand(template_content, test_config.variables)

    local expected = "    line1\n    \n    line3"
    assert.are.equal(expected, result)
  end)

  it("handles complex real-world scenario", function()
    -- The exact scenario from the user's issue
    local test_config = {
      variables = {
        __selection__ = function()
          return [[for i in $(seq 10);
do
   echo $i
done]]
        end,
      },
    }

    local template_content = [[main () {
    {{__selection__}}
}]]

    local result = expander.expand(template_content, test_config.variables)

    local expected = [[main () {
    for i in $(seq 10);
    do
       echo $i
    done
}]]

    assert.are.equal(expected, result)
  end)
end)
