local util        = require 'util.util'
local fileutil    = require 'util.fileutil'
local tableutil   = require 'util.tableutil'
local kafkaClient = require 'rdkafka.kafkaclient'

local customLogWatchConfig = (require 'conf.logwatchconfig').getconfig()
local tunningConfig        = (require 'conf.tunningconfig' ).getconfig()
local parserConfig         = (require 'conf.parserconfig'  ).init()
local customParserConfig   = (require 'conf.parserconfig'  ).getconfig()
local customKafkaConfig    = (require 'conf.kafkaconfig'   ).getconfig()

local singlelineW = require 'watchlog.watchlogfilesingleline'
local multilineW  = require 'watchlog.watchlogfilemultiline'
local javalogW    = require 'watchlog.watchlogfilejavalog'
local jsonlogW    = require 'watchlog.watchlogfilesinglelinejson'

local container , metrics , msgCount = {} , {}
local msgCount , taskDelete , deleteList = 0 , false , {}
local lastCheckTaskTime , now = os.time() , os.time()

kafkaClient.initKafkaClient(customKafkaConfig , metrics)

local function createTask(first, task)
    print("creat task " .. task.dirpath .. task.filename)
    return coroutine.create(function()
        local topic = kafkaClient.getTopicInst(task.topic)
        local watchlogFac = nil
        if task.multiline then
            watchlogFac = (task.javaLog and javalogW or multilineW)
        else
            watchlogFac = (task.jsonLog and jsonlogW or singlelineW)
        end
        local wtcLogFile = watchlogFac:new(task , customParserConfig , tunningConfig)
        local c = 0 
        while true do
            c = wtcLogFile:readFile(kafkaClient , topic)
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
                    local item = createTask(first , task)
                    table.insert(container,{p , item})
                    table.insert(metrics , {p , 0})
                    container[p] = item
    			end
    		end
    	elseif task.filenameFilter then
    		local filenames = fileutil.filter(task.dirpath , task.filenameFilter)
    		for _ , filename in ipairs(filenames) do
                if container[task.dirpath .. filename] == nil then
    			    local newtask = tableutil.clone(task)
    			    newtask.filename = filename
                    local item = createTask(first, newtask)
                    table.insert(container , {task.dirpath .. filename , item})
                    table.insert(metrics , {task.dirpath .. filename , 0})
                    container[task.dirpath .. filename] = item
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
    taskDelete = false
    for index , item in ipairs(container) do
        local status , result = coroutine.resume(item[2])
        if status then
            if result < 0 then
                print("delete task for " .. item[1])
                taskDelete = true
                table.insert(deleteList , item[1])
            else
                msgCount = msgCount + result
                metrics[index][2] = metrics[index][2] + result
            end
        else
            print(result)
        end
    end
    if taskDelete then
        for _ , delItem in ipairs(deleteList) do
            container[delItem] , metrics[delItem] = nil , nil
            for p , item in ipairs(container) do
                if item[1] == delItem then
                    container[p] = nil
                    break
                end
            end
        end
        deleteList = {}
    end
    if msgCount == 0 then util.sleep(tunningConfig.NO_DATA_INTERVAL) end
    msgCount = 0
end