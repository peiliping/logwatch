local multilineW = require 'watchlogfilemultiline'
local util = require 'util'
local cjson = require 'cjson'
local table_concat = table.concat

local watchlogfilejavalog = {
    ---- CONSTANTS ----
    ---- Core Data ----
    ---- Temp Data ----
}

setmetatable(watchlogfilejavalog , multilineW)
watchlogfilejavalog.__index = watchlogfilejavalog

function watchlogfilejavalog:new(task , customParserConfig , tunningConfig)
    local self = {}
    self = multilineW:new(task , customParserConfig , tunningConfig)
    setmetatable(self ,  watchlogfilejavalog)
  return self
end

function watchlogfilejavalog:handleEventPlus(kafkaClient , topic , msgTable)
    if self.multiLineNum == 1 then
        self:handleEvent(kafkaClient , topic , msgTable[1])
    else
        local handled = util.parseData(msgTable[1] , self.parseRule , self.EVENT_CONTAINER)
        local tmp_content = {}
        if handled then
            local exceptionName , exceptionMsg = msgTable[2]:match('%s?([^%s]-tion):(.*)') --('(.-Exception):(.*)')
            if exceptionName and exceptionMsg then
                tmp_content['exceptionName'] = exceptionName
                tmp_content['exceptionMsg'] = exceptionMsg
                if self.multiLineNum > 2 then
                    tmp_content['stack'] = table_concat(msgTable , '\n' , 2)
                end
            else
                tmp_content['messageDetail'] = table_concat(msgTable , '\n' , 2)
            end
            util.mergeMapTables2Left(tmp_content , self.EVENT_CONTAINER)
            kafkaClient.safeSendMsg(topic , self.tempKafkaKey  , cjson.encode(tmp_content) , 10)
        else
            print(table_concat(msgTable , '\n'))
        end
    end
end

return watchlogfilejavalog