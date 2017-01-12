local threads , metrics = {} , {}

local customKafkaConfig = require 'conf.kafkaconfig'
local kafkaClient = require 'kafkaclient'
kafkaClient.initKafkaClient(customKafkaConfig.getconfig() , metrics)
local customParserConfig = require 'conf.parserconfig'
customParserConfig.init()
local customLogWatchConfig = require 'conf.logwatchconfig'
local tunningConfig = require 'conf.tunningconfig'
local util = require 'util'
local singlelineW = require 'watchlogfilesingleline'
local multilineW = require 'watchlogfilemultiline'
local javalogW = require 'watchlogfilejavalog'
local jsonlogW = require 'watchlogfilesinglelinejson'
------------------------------------------------------------------------------------
local function createCollectThread(kafkaClient , task , customParserConfig , tunningConfig)
    return coroutine.create(function()
        local coroutine_yield = coroutine.yield
        local topic = kafkaClient.getTopicInst(task.topic)
        local watchlogFac = nil 
        if task.multiline then
            watchlogFac = (task.javaLog and  javalogW or multilineW)
        else
            watchlogFac = (task.jsonLog and jsonlogW or singlelineW)
        end
        local wtcLogFile = watchlogFac:new(task , customParserConfig , tunningConfig)
        while true do
            local c = wtcLogFile:readFile(kafkaClient , topic)
            coroutine_yield(c)
        end
        wtcLogFile:close()
    end)
end

local function dispatch(threads , metrics , tunningConfig)
    local coroutine_resume = coroutine.resume
    local NO_DATA_INTERVAL = tunningConfig.getconfig().NO_DATA_INTERVAL
    local msgCount = 0
    while true do
        for index , worker in ipairs(threads) do
            local status , result = coroutine_resume(worker)
            if status then
                msgCount = msgCount + result
                metrics[index][2] = metrics[index][2] + result
            else
                print(result)
            end
        end
        if msgCount == 0 then 
            util.sleep(NO_DATA_INTERVAL)
        end
        msgCount = 0
    end
end

for _ , task in ipairs(customLogWatchConfig.getconfig()) do
    local worker = createCollectThread(kafkaClient , task , customParserConfig , tunningConfig)
    table.insert(threads , worker)
    table.insert(metrics , {task.path , 0})
end
dispatch(threads , metrics , tunningConfig)