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
			if i ~= j and pos1.row == pos2.row then
				-- Check if pos1 is fully contained within pos2, but not identical
				if
					pos1.start_column >= pos2.start_column
					and pos1.end_column <= pos2.end_column
					and not (pos1.start_column == pos2.start_column and pos1.end_column == pos2.end_column)
				then
					is_nested = true
					break
				end
			end
		end
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
	local all_positions = {}
	local content = M.get_buffer_contents(min_row, max_row, active_buffer_id)

	for key, line in pairs(content) do
		for _, pattern in pairs(patterns) do
			local search_offset = 1
			while true do
				-- Use string.find to get reliable positions
				local start_pos, end_pos = string.find(line, pattern, search_offset, true)
				if not start_pos then
					break
				end

				local match = string.sub(line, start_pos, end_pos)
				local isFalsePositiveCSSVariable = match == ": var"

				if not isFalsePositiveCSSVariable then
					-- For named colors, the match might be '= blue'. We need to find the position of just 'blue'.
					local final_start = start_pos - 1 -- Convert to 0-based for Neovim
					local final_end = end_pos
					local clean_match = M.remove_color_usage_pattern(match)

					-- If the string was cleaned, find the start of the clean part within the full match
					if #clean_match < #match then
						local clean_start_in_match, _ = string.find(match, clean_match, 1, true)
						if clean_start_in_match then
							final_start = (start_pos + clean_start_in_match - 1) - 1 -- Adjust start and convert to 0-based
							final_end = final_start + #clean_match
						end
					end

					table.insert(all_positions, {
						value = match,
						row = key + min_row - row_offset,
						start_column = final_start,
						end_column = final_end,
					})
				end
				-- Start the next search after the beginning of the current match to allow for overlapping patterns
				search_offset = start_pos + 1
			end
		end
	end

	-- Filter out nested matches at the very end
	return M.remove_nested_matches(all_positions)
end

-- This function is no longer needed with the new string.find loop
-- but is kept here for reference if you need to revert.
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
