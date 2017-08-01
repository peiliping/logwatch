local lfs = require 'lfs'

local fileutil = {}

function fileutil.isExist(path)
	local file = io.open(path, "r")
	if file then file:close() end
	return file ~= nil
end

function fileutil.filter(path, regex)
	local result = {}
	if fileutil.isExist(path) then
		for filename in lfs.dir(path) do
        	if filename ~= "." and filename ~= ".." then
				local s , e = string.find(filename, regex)
				if(s == 1 and e == string.len(filename)) then
					table.insert(result, filename)
				end
        	end
    	end
	end
	return result
end

function fileutil.getFileAndInode(task)
    local path = task.dirpath .. task.filename
    local file = io.open(path, "r")
    local inode = nil
    if file then
        inode = lfs.attributes(path).ino
    end
    return file , inode
end

function fileutil.checkFileRolling(task, file, inode)
    local rolling = false
    if file == nil then
        file , inode = fileutil.getFileAndInode(task)
        rolling = true
    else
        local t_file , t_inode = fileutil.getFileAndInode(task)
        if inode == t_inode then
            t_file:close()
        else
            file:close()
            file , inode , rolling = t_file , t_inode , true
        end
    end
    return rolling , file , inode
end

return fileutil