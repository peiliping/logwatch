local singlelineW = require 'watchlogfilesingleline'
local util = require 'util'
local cjson = require 'cjson'

local watchlogfilesinglelinejson = {
    ---- CONSTANTS ----
    ---- Core Data ----
    ---- Temp Data ----
}

setmetatable(watchlogfilesinglelinejson , singlelineW)
watchlogfilesinglelinejson.__index = watchlogfilesinglelinejson

function watchlogfilesinglelinejson:new(task , customParserConfig , tunningConfig)
    local self = {}
    self = singlelineW:new(task , customParserConfig , tunningConfig)
    setmetatable(self ,  watchlogfilesinglelinejson)
  return self
end

function watchlogfilesinglelinejson:handleEvent(kafkaClient , topic , msg)
    local status , jsn = pcall(cjson.decode , msg)
    if status then
        util.mergeMapTables2Left(jsn , self.EVENT_CONTAINER)
        kafkaClient.safeSendMsg(topic , self.tempKafkaKey , cjson.encode(self.EVENT_CONTAINER) , 10)
    else
        print(msg)
    end
end

return watchlogfilesinglelinejson