local multilineW = require 'watchlog.watchlogfilemultiline'
local util = require 'util.util'
local tableutil = require 'util.tableutil'
local json = require 'rapidjson'

local watchlogfilejavalog = {
    ---- CONSTANTS ----
    ---- Core Data ----
    ---- Temp Data ----
}

setmetatable(watchlogfilejavalog , multilineW)
watchlogfilejavalog.__index = watchlogfilejavalog

function watchlogfilejavalog:new(task, customParserConfig, tunningConfig, first)
    local self = {}
    self = multilineW:new(task, customParserConfig, tunningConfig, first)
    setmetatable(self ,  watchlogfilejavalog)
  return self
end

function watchlogfilejavalog:handleEventPlus(kafkaClient , topic , msgTable)
    if self.multiLineNum == 1 then
        self:handleEvent(kafkaClient , topic , msgTable[1])
    else
        self.count = self.count + self.multiLineNum
        local handled = self:parseData(msgTable[1])
        local tmp_content = {}
        if handled then
            local exceptionName , exceptionMsg = msgTable[2]:match('%s?([^%s]-tion):(.*)') --('(.-Exception):(.*)')
            if exceptionName and exceptionMsg then
                tmp_content['exceptionName'] = exceptionName
                tmp_content['exceptionMsg'] = exceptionMsg
                if self.multiLineNum > 2 then
                    tmp_content['stack'] = table.concat(msgTable , '\n' , 2)
                end
            else
                tmp_content['messageDetail'] = table.concat(msgTable , '\n' , 2)
            end
            tableutil.simpleCopy(self.EVENT_CONTAINER , tmp_content)
            kafkaClient.safeSendMsg(topic , self.tempKafkaKey  , json.encode(tmp_content) , 10)
        else
            print(table.concat(msgTable , '\n'))
        end
    end
end

return watchlogfilejavalog