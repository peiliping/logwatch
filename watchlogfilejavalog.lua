local multilineW = require 'watchlogfilemultiline'
local util = require 'util.util'
local tableutil = require 'util.tableutil'
local cjson = require 'cjson'

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
        local handled = util.parseData(msgTable[1] , self.parseRule , self.EVENT_CONTAINER)
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
            tableutil.simpleCopy(tmp_content , self.EVENT_CONTAINER)
            kafkaClient.safeSendMsg(topic , self.tempKafkaKey  , cjson.encode(tmp_content) , 10)
        else
            print(table.concat(msgTable , '\n'))
        end
    end
end

return watchlogfilejavalog