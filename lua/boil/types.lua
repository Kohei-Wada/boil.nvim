---@meta

---@class Template
---@field path string Absolute path to template file
---@field config TemplateConfig Template configuration reference

---@class TemplateConfig
---@field path string Template directory path
---@field name? string Optional source name
---@field filter? fun(template: Template): boolean Optional filter function
---@field variables? table<string, any> Template-specific variables

---@class Config
---@field templates TemplateConfig[] List of template configurations
---@field filter? fun(template: Template): boolean Global filter function
---@field variables? table<string, any> Global variables
---@field logger? LoggerConfig Logger configuration

---@class LoggerConfig
---@field level? number Minimum log level to display (vim.log.levels.*)
---@field prefix? string Prefix for all log messages
