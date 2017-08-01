local customLogWatchConfig = (require 'conf.logwatchconfig').getconfig()
local tunningConfig        = (require 'conf.tunningconfig' ).getconfig()
local parserConfig         = (require 'conf.parserconfig'  ).init()
local customParserConfig   = (require 'conf.parserconfig'  ).getconfig()
local customKafkaConfig    = (require 'conf.kafkaconfig'   ).getconfig()

local util      = require 'util'
local fileutil  = require 'fileutil'
local tableutil = require 'tableutil'

local singlelineW = require 'watchlogfilesingleline'
local multilineW  = require 'watchlogfilemultiline'
local javalogW    = require 'watchlogfilejavalog'
local jsonlogW    = require 'watchlogfilesinglelinejson'

local container , metrics = {} , {}

local lastCheckTaskTime , now = os.time() , os.time()
local msgCount = 0

local function createTask(first, task)
    return coroutine.create(function()
        local watchlogFac = nil
        if task.multiline then
            watchlogFac = (task.javaLog and javalogW or multilineW)
        else
            watchlogFac = (task.jsonLog and jsonlogW or singlelineW)
        end
        local wtcLogFile = watchlogFac:new(task , customParserConfig , tunningConfig)
        local c = 0 
        while true do
            c = wtcLogFile:readFile(nil , nil)
            if c < 0 then break end
            coroutine.yield(c)
        end
        wtcLogFile:close()
        coroutine.yield(c)
    end)
end

local function checkTask(first)
	for _ , task in ipairs(customLogWatchConfig) do
		if task.dirpath == nil then
			error("dirpath define missing")
		end
    	if task.filename then
    		local p = task.dirpath .. task.filename
    		if container[p] == nil then
    			if fileutil.isExist(p) then
                    container[p] , metrics[p] = createTask(first, task) , 0
    			end
    		end
    	elseif task.filenameFilter then
    		local filenames = fileutil.filter(task.dirpath , task.filenameFilter)
    		for _ , filename in ipairs(filenames) do
    			local newtask = tableutil.clone(task)
    			newtask.filename = filename
                container[filename] , metrics[filename] = createTask(first, newtask) , 0
    		end
    	else
    		error("filename define missing")
    	end
	end
end
--------------------------------------- starting ---------------------------------------
checkTask(true)
while true do
	now = os.time()
	if now - lastCheckTaskTime >= tunningConfig.CHECK_FILE_EXIST_INTERVAL then
		checkTask(false)
		lastCheckTaskTime = now
	end
    for name , worker in pairs(container) do
        local status , result = coroutine.resume(worker)
        if status then
            if result < 0 then
                container[name] , metrics[name] = nil , nil
                print("delete task for " .. name)
            end
            msgCount = msgCount + result
            metrics[name] = metrics[name] + result
        else
            print(result)
        end
    end
    if msgCount == 0 then 
        util.sleep(tunningConfig.NO_DATA_INTERVAL)
    end
    msgCount = 0
end