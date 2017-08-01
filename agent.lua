local util        = require 'util.util'
local fileutil    = require 'util.fileutil'
local tableutil   = require 'util.tableutil'

local customLogWatchConfig = (require 'conf.logwatchconfig').getconfig()
local tunningConfig        = (require 'conf.tunningconfig' ).getconfig()
local parserConfig         = (require 'conf.parserconfig'  ).init()
local customParserConfig   = (require 'conf.parserconfig'  ).getconfig()
local customKafkaConfig    = (require 'conf.kafkaconfig'   ).getconfig()

local singlelineW = require 'watchlog.watchlogfilesingleline'
local multilineW  = require 'watchlog.watchlogfilemultiline'
local javalogW    = require 'watchlog.watchlogfilejavalog'
local jsonlogW    = require 'watchlog.watchlogfilesinglelinejson'

local container , metrics , msgCount = {} , {} , 0
local lastCheckTaskTime , now = os.time() , os.time()

local function createTask(first, task)
    print("creat task " .. task.dirpath .. task.filename)
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
		if task.dirpath == nil then error("dirpath define missing") end
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
                if container[task.dirpath .. filename] == nil then
    			    local newtask = tableutil.clone(task)
    			    newtask.filename = filename
                    container[task.dirpath .. filename] , metrics[task.dirpath .. filename] = createTask(first, newtask) , 0
                end
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
            else
                msgCount = msgCount + result
                metrics[name] = metrics[name] + result
            end
        else
            print(result)
        end
    end
    if msgCount == 0 then util.sleep(tunningConfig.NO_DATA_INTERVAL) end
    msgCount = 0
end