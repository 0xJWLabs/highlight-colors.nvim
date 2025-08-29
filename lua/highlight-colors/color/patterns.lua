local M = {}

-- [[ REGEX DEFINITIONS ]]
M.rgb_regex = "rgba?[(]+" .. string.rep("%s*%d+%s*", 3, "[,%s]") .. "[,%s/]?%s*%d*%.?%d*%%?%s*[)]+"
M.hex_regex = "#%x%x%x+%f[^%w_]"
M.hex_0x_regex = "%f[%w_]0x%x%x%x+%f[^%w_]"
M.hsl_regex = "hsla?[(]+"
	.. string.rep("%s*%d*%.?%d+%%?d?e?g?t?u?r?n?%s*", 3, "[,%s]")
	.. "[%s,/]?%s*%d*%.?%d*%%?%s*[)]+"
M.hsl_without_func_regex = ":" .. string.rep("%s*%d*%.?%d+%%?d?e?g?t?u?r?n?%s*", 3, "[,%s]")

-- NEW: Roblox Color3.fromRgb Regex
-- Matches: Color3.fromRgb(255, 255, 255)
M.roblox_color3_rgb_regex = "Color3%.fromRgb%s*%(" .. string.rep("%s*%d+%s*", 3, "%s*,%s*") .. "%s*%)"
M.roblox_color3_new_regex = "Color3%.new%s*%(" .. string.rep("%s*%d*%.?%d+%s*", 3, "%s*,%s*") .. "%s*%)"

M.var_regex = "%-%-[%d%a-_]+"
M.var_declaration_regex = M.var_regex .. ":%s*" .. M.hex_regex
M.var_usage_regex = "var%(" .. M.var_regex .. "%)"

M.tailwind_prefix = "!?%a+"
M.ansi_regex = "\\033%[%d;%d%dm"

-- [[ CHECKER FUNCTIONS ]]

---Checks whether a color is short hex
---@param color string
---@return boolean
function M.is_short_hex_color(color)
	if string.match(color, M.hex_regex) then
		return string.len(color) == 4
	end
	return false
end

---Checks whether a color is hex
---@param color string
---@return boolean
function M.is_hex_color(color)
	if string.match(color, M.hex_regex) then
		return string.len(color) == 7
	end
	return false
end

---Checks whether a color is hex with alpha data
---@param color string
---@return boolean
function M.is_alpha_layer_hex(color)
	return string.match(color, M.hex_regex) ~= nil and string.len(color) == 9
end

---Checks whether a color is rgb
---@param color string
---@return boolean
function M.is_rgb_color(color)
	return string.match(color, M.rgb_regex) ~= nil
end

---Checks whether a color is hsl
---@param color string
---@return boolean
function M.is_hsl_color(color)
	return string.match(color, M.hsl_regex) ~= nil
end

-- Checks wether a color is a hsl without function color
---@param color string
---@return boolean
function M.is_hsl_without_func_color(color)
	return string.match(color, M.hsl_without_func_regex) ~= nil
end

---Checks whether a color is a CSS var color
---@param color string
---@return boolean
function M.is_var_color(color)
	return string.match(color, M.var_usage_regex) ~= nil
end

-- NEW: Roblox Color3.fromRgb Checker Function
---Checks whether a color is a Roblox Color3.fromRgb
---@param color string
---@usage is_roblox_color3_rgb_color("Color3.fromRgb(255, 0, 128)") => Returns true
---@return boolean
function M.is_roblox_color3_rgb_color(color)
	return string.match(color, M.roblox_color3_rgb_regex) ~= nil
end

-- NEW: Roblox Color3.new Checker Function
---Checks whether a color is a Roblox Color3.new
---@param color string
---@usage is_roblox_color3_new_color("Color3.new(0, 0, 0)") => Returns true
---@return boolean
function M.is_roblox_color3_new_color(color)
	return string.match(color, M.roblox_color3_new_regex) ~= nil
end

---Checks whether a color is a custom color
---@param color string
---@param custom_colors table
---@return boolean
function M.is_custom_color(color, custom_colors)
	for _, custom_color in pairs(custom_colors) do
		if color == custom_color.label:gsub("%%", "") then
			return true
		end
	end
	return false
end

---Checks whether a color is a named color e.g. 'blue', 'green'
---@param named_color_patterns table
---@param color string
---@return boolean
function M.is_named_color(named_color_patterns, color)
	for _, pattern in pairs(named_color_patterns) do
		if string.match(color, pattern) then
			return true
		end
	end
	return false
end

---Checks whether a color is a ansi color
---@param color string
---@return boolean
function M.is_ansi_color(color)
	return string.match(color, M.ansi_regex) ~= nil
end

return M
