local table_utils = require("highlight-colors.table_utils")

local M = {}

M.color_usage_regex = "[:=]+%s*[\"']?"

---Returns the text content of the specified buffer within received range
---@param min_row number
---@param max_row number
---@param active_buffer_id number
---@usage buffer_utils.get_buffer_contents(0, 10, 1) => Returns {'first row', 'second row'}
---@return string[]
function M.get_buffer_contents(min_row, max_row, active_buffer_id)
	if not vim.api.nvim_buf_is_valid(active_buffer_id) then
		return { "" }
	end
	return vim.api.nvim_buf_get_lines(active_buffer_id, min_row, max_row, false)
end

---Removes color matches that are fully contained within another match.
---This prevents highlighting both `Color3.fromHex("#FFFFFF")` and the inner `#FFFFFF`.
---@param positions {row: number, start_column: number, end_column: number, value: string}[]
---@return {row: number, start_column: number, end_column: number, value: string}[]
function M.remove_nested_matches(positions)
	local final_positions = {}
	for i, pos1 in ipairs(positions) do
		local is_nested = false
		for j, pos2 in ipairs(positions) do
			-- Check if pos1 is different from pos2 and on the same row
			if i ~= j and pos1.row == pos2.row then
				-- Check if pos1 is fully contained within pos2
				if pos1.start_column >= pos2.start_column and pos1.end_column <= pos2.end_column then
					is_nested = true
					break -- Found a container, no need to check further for this pos1
				end
			end
		end
		-- Only keep the position if it was not nested within any other
		if not is_nested then
			table.insert(final_positions, pos1)
		end
	end
	return final_positions
end

---Returns the color matches based on the received lua patterns
---@param min_row number
---@param max_row number
---@param active_buffer_id number
---@param row_offset number
---@return {row: number, start_column: number, end_column: number, value: string}[]
function M.get_positions_by_regex(patterns, min_row, max_row, active_buffer_id, row_offset)
	local positions = {}
	local content = M.get_buffer_contents(min_row, max_row, active_buffer_id)

	for _, pattern in pairs(patterns) do
		for key, value in pairs(content) do
			for match in string.gmatch(value, pattern) do
				local row = key + min_row - row_offset
				local column_offset = M.get_column_offset(positions, match, row)
				local pattern_without_usage_regex = M.remove_color_usage_pattern(match)
				local valid_start, start_column = pcall(vim.fn.match, value, pattern_without_usage_regex, column_offset)
				local valid_end, end_column = pcall(vim.fn.matchend, value, pattern_without_usage_regex, column_offset)
				local isFalsePositiveCSSVariable = match == ": var"

				if valid_start and valid_end and not isFalsePositiveCSSVariable then
					table.insert(positions, {
						value = match,
						row = row,
						start_column = start_column,
						end_column = end_column,
					})
				end
			end
		end
	end

	-- Filter out nested matches before returning
	return M.remove_nested_matches(positions)
end

-- Handles repeated colors in the same row: e.g. `#fff #fff`
---@param positions {row: number, start_column: number, end_column: number, value: string}[]
---@param match string
---@param row number
---@return number | nil
function M.get_column_offset(positions, match, row)
	local repeated_colors_in_row = table_utils.filter(positions, function(position)
		return position.value == match and position.row == row
	end)
	local last_repeated_color = repeated_colors_in_row[#repeated_colors_in_row]
	return last_repeated_color and last_repeated_color.end_column or nil
end

---Removes useless data from the colors string in case of named colors
---@param match string
---@usage remove_color_usage_pattern(": blue") => Returns "blue"
---@return string
function M.remove_color_usage_pattern(match)
	local _, end_index = string.find(match, M.color_usage_regex)
	return end_index and string.sub(match, end_index + 1, string.len(match)) or match
end

return M
