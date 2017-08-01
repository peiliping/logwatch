local customLogWatchConfig = (require 'conf.logwatchconfig').getconfig()
local tunningConfig        = (require 'conf.tunningconfig' ).getconfig()

local fileutil = require 'fileutil'
local util 	   = require 'util'

local container , metrics = {} , {}

local lastCheckTaskTime = os.time()

local function createTask(first, now, task)

end

local function checkTask(first, now)
	for _ , task in ipairs(customLogWatchConfig) do
		if task.dirpath == nil then
			error("dirpath define missing")
		end
    	if task.filename then
    		local p = task.dirpath .. task.filename
    		if container[p] == nil then
    			if fileutil.isExist(p) then
    				createTask(first, now, task)
    			end
    		end
    	elseif task.filenameFilter then
    		local filenames = fileutil.filter(task.dirpath , task.filenameFilter)
    		for _ , filename in ipairs(filenames) do
    			local newtask = util.clone(task)
    			newtask.filename = filename
    			createTask(first, now, newtask)
    		end
    	else
    		error("filename define missing")
    	end
	end
end

checkTask(true, now)
while false do
	local now = os.time()
	if now - lastCheckTaskTime >= tunningConfig.CHECK_FILE_EXIST_INTERVAL then
		checkTask(false, now)
		lastCheckTaskTime = now
	end
end
