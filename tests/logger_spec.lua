describe("boil.logger", function()
  local logger
  local original_notify

  before_each(function()
    package.loaded["boil.logger"] = nil
    logger = require "boil.logger"

    -- Mock vim.notify
    original_notify = vim.notify
    vim.notify = function(msg, level)
      -- Store the last notification for assertions
      _G.last_notification = { msg = msg, level = level }
    end
    _G.last_notification = nil
  end)

  after_each(function()
    -- Restore original vim.notify
    vim.notify = original_notify
    _G.last_notification = nil
  end)

  describe("setup", function()
    it("should use default configuration when no options provided", function()
      logger.setup()

      assert.equals(vim.log.levels.INFO, logger.options.level)
      assert.equals("[boil.nvim]", logger.options.prefix)
    end)

    it("should merge user configuration with defaults", function()
      logger.setup {
        level = vim.log.levels.DEBUG,
        prefix = "[custom]",
      }

      assert.equals(vim.log.levels.DEBUG, logger.options.level)
      assert.equals("[custom]", logger.options.prefix)
    end)

    it("should handle nil configuration", function()
      logger.setup(nil)

      assert.equals(vim.log.levels.INFO, logger.options.level)
      assert.equals("[boil.nvim]", logger.options.prefix)
    end)

    it("should override only specified options", function()
      logger.setup {
        level = vim.log.levels.WARN,
        -- prefix not specified, should use default
      }

      assert.equals(vim.log.levels.WARN, logger.options.level)
      assert.equals("[boil.nvim]", logger.options.prefix)
    end)

    it("should handle empty configuration table", function()
      logger.setup {}

      assert.equals(vim.log.levels.INFO, logger.options.level)
      assert.equals("[boil.nvim]", logger.options.prefix)
    end)
  end)

  describe("log levels", function()
    describe("info", function()
      it("should log when level is INFO or lower", function()
        logger.setup { level = vim.log.levels.INFO }
        logger.info "Test info message"

        assert.is_not_nil(_G.last_notification)
        assert.equals("[boil.nvim] Test info message", _G.last_notification.msg)
        assert.equals(vim.log.levels.INFO, _G.last_notification.level)
      end)

      it("should log when level is DEBUG", function()
        logger.setup { level = vim.log.levels.DEBUG }
        logger.info "Test info message"

        assert.is_not_nil(_G.last_notification)
        assert.equals("[boil.nvim] Test info message", _G.last_notification.msg)
      end)

      it("should not log when level is WARN or higher", function()
        logger.setup { level = vim.log.levels.WARN }
        logger.info "Test info message"

        assert.is_nil(_G.last_notification)
      end)

      it("should not log when level is ERROR", function()
        logger.setup { level = vim.log.levels.ERROR }
        logger.info "Test info message"

        assert.is_nil(_G.last_notification)
      end)
    end)

    describe("warn", function()
      it("should log when level is WARN or lower", function()
        logger.setup { level = vim.log.levels.WARN }
        logger.warn "Test warning message"

        assert.is_not_nil(_G.last_notification)
        assert.equals("[boil.nvim] Test warning message", _G.last_notification.msg)
        assert.equals(vim.log.levels.WARN, _G.last_notification.level)
      end)

      it("should log when level is INFO", function()
        logger.setup { level = vim.log.levels.INFO }
        logger.warn "Test warning message"

        assert.is_not_nil(_G.last_notification)
        assert.equals("[boil.nvim] Test warning message", _G.last_notification.msg)
      end)

      it("should log when level is DEBUG", function()
        logger.setup { level = vim.log.levels.DEBUG }
        logger.warn "Test warning message"

        assert.is_not_nil(_G.last_notification)
      end)

      it("should not log when level is ERROR", function()
        logger.setup { level = vim.log.levels.ERROR }
        logger.warn "Test warning message"

        assert.is_nil(_G.last_notification)
      end)
    end)

    describe("error", function()
      it("should log when level is ERROR or lower", function()
        logger.setup { level = vim.log.levels.ERROR }
        logger.error "Test error message"

        assert.is_not_nil(_G.last_notification)
        assert.equals("[boil.nvim] Test error message", _G.last_notification.msg)
        assert.equals(vim.log.levels.ERROR, _G.last_notification.level)
      end)

      it("should log when level is WARN", function()
        logger.setup { level = vim.log.levels.WARN }
        logger.error "Test error message"

        assert.is_not_nil(_G.last_notification)
      end)

      it("should log when level is INFO", function()
        logger.setup { level = vim.log.levels.INFO }
        logger.error "Test error message"

        assert.is_not_nil(_G.last_notification)
      end)

      it("should log when level is DEBUG", function()
        logger.setup { level = vim.log.levels.DEBUG }
        logger.error "Test error message"

        assert.is_not_nil(_G.last_notification)
      end)

      it("should not log when level is higher than ERROR", function()
        -- If level is set higher than ERROR, nothing should log
        logger.setup { level = vim.log.levels.ERROR + 1 }
        logger.error "Test error message"

        assert.is_nil(_G.last_notification)
      end)
    end)

    describe("debug", function()
      it("should log when level is DEBUG", function()
        logger.setup { level = vim.log.levels.DEBUG }
        logger.debug "Test debug message"

        assert.is_not_nil(_G.last_notification)
        assert.equals("[boil.nvim] Test debug message", _G.last_notification.msg)
        assert.equals(vim.log.levels.DEBUG, _G.last_notification.level)
      end)

      it("should not log when level is INFO or higher", function()
        logger.setup { level = vim.log.levels.INFO }
        logger.debug "Test debug message"

        assert.is_nil(_G.last_notification)
      end)

      it("should not log when level is WARN", function()
        logger.setup { level = vim.log.levels.WARN }
        logger.debug "Test debug message"

        assert.is_nil(_G.last_notification)
      end)

      it("should not log when level is ERROR", function()
        logger.setup { level = vim.log.levels.ERROR }
        logger.debug "Test debug message"

        assert.is_nil(_G.last_notification)
      end)
    end)
  end)

  describe("message formatting", function()
    it("should format messages with prefix", function()
      logger.setup { prefix = "[test]" }
      logger.info "Hello world"

      assert.equals("[test] Hello world", _G.last_notification.msg)
    end)

    it("should handle empty prefix", function()
      logger.setup { prefix = "" }
      logger.info "Hello world"

      assert.equals(" Hello world", _G.last_notification.msg)
    end)

    it("should handle multiline messages", function()
      logger.setup()
      logger.info "Line 1\nLine 2\nLine 3"

      assert.equals("[boil.nvim] Line 1\nLine 2\nLine 3", _G.last_notification.msg)
    end)

    it("should handle empty messages", function()
      logger.setup()
      logger.info ""

      assert.equals("[boil.nvim] ", _G.last_notification.msg)
    end)

    it("should handle messages with special characters", function()
      logger.setup()
      logger.info "Test: {{var}} $pecial @chars #123"

      assert.equals("[boil.nvim] Test: {{var}} $pecial @chars #123", _G.last_notification.msg)
    end)
  end)

  describe("_log internal function", function()
    it("should format and notify correctly", function()
      logger.setup { prefix = "[internal]" }
      logger._log("Direct log message", vim.log.levels.WARN)

      assert.is_not_nil(_G.last_notification)
      assert.equals("[internal] Direct log message", _G.last_notification.msg)
      assert.equals(vim.log.levels.WARN, _G.last_notification.level)
    end)

    it("should pass correct level to vim.notify", function()
      logger.setup()

      logger._log("Debug test", vim.log.levels.DEBUG)
      assert.equals(vim.log.levels.DEBUG, _G.last_notification.level)

      logger._log("Info test", vim.log.levels.INFO)
      assert.equals(vim.log.levels.INFO, _G.last_notification.level)

      logger._log("Warn test", vim.log.levels.WARN)
      assert.equals(vim.log.levels.WARN, _G.last_notification.level)

      logger._log("Error test", vim.log.levels.ERROR)
      assert.equals(vim.log.levels.ERROR, _G.last_notification.level)
    end)
  end)

  describe("edge cases", function()
    it("should handle very long messages", function()
      logger.setup()
      local long_message = string.rep("a", 1000)
      logger.info(long_message)

      assert.equals("[boil.nvim] " .. long_message, _G.last_notification.msg)
    end)

    it("should handle unicode characters", function()
      logger.setup()
      logger.info "こんにちは 世界 🌍"

      assert.equals("[boil.nvim] こんにちは 世界 🌍", _G.last_notification.msg)
    end)

    it("should handle numeric log levels", function()
      -- Vim log levels are numbers, ensure they work correctly
      logger.setup { level = 0 } -- DEBUG level
      logger.debug "Should appear"
      assert.is_not_nil(_G.last_notification)

      _G.last_notification = nil
      logger.setup { level = 4 } -- ERROR level
      logger.info "Should not appear"
      assert.is_nil(_G.last_notification)
    end)
  end)
end)
