local singlelineW = require 'watchlog.watchlogfilesingleline'
local tableutil = require 'util.tableutil'
local json = require 'rapidjson'

local watchlogfilesinglelinejson = {
    ---- CONSTANTS ----
    ---- Core Data ----
    ---- Temp Data ----
}

setmetatable(watchlogfilesinglelinejson , singlelineW)
watchlogfilesinglelinejson.__index = watchlogfilesinglelinejson

function watchlogfilesinglelinejson:new(task, customParserConfig, tunningConfig, first)
    local self = {}
    self = singlelineW:new(task, customParserConfig, tunningConfig, first)
    setmetatable(self ,  watchlogfilesinglelinejson)
  return self
end

function watchlogfilesinglelinejson:handleEvent(kafkaClient , topic , msg)
    local status , jsn = pcall(json.decode , msg)
    if status then
        tableutil.simpleCopy(jsn , self.EVENT_CONTAINER)
        kafkaClient.safeSendMsg(topic , self.tempKafkaKey , json.encode(self.EVENT_CONTAINER) , 10)
    else
        print(msg)
    end
end

return watchlogfilesinglelinejson