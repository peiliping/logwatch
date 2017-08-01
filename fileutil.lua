local lfs = require 'lfs'

local fileutil = {}

function fileutil.isExist(path)
	local file = io.open(path, "r")
	if file then file:close() end
	return file ~= nil
end

function fileutil.filter(path , regex)
	local result = {}
	if isExist(path) then
		
	end
	return result
end

return fileutil