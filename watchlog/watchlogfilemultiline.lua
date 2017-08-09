local singlelineW = require 'watchlog.watchlogfilesingleline'

local watchlogfilemultiline = {
    ---- CONSTANTS ----
    MULTILINE_IDENTIFY = nil ,
    MULTILINE_MAX_NUM = nil ,
    ---- Core Data ----
    ---- Temp Data ----
    multiLineData = nil ,
    multiLineNum = nil ,
}

setmetatable(watchlogfilemultiline , singlelineW)
watchlogfilemultiline.__index = watchlogfilemultiline

function watchlogfilemultiline:new(task, customParserConfig, tunningConfig, first)
    local self = {}
    self = singlelineW:new(task, customParserConfig, tunningConfig, first)
    setmetatable(self ,  watchlogfilemultiline)
    self.MULTILINE_IDENTIFY = task.multilineIdentify
    self.MULTILINE_MAX_NUM = tunningConfig.MULTILINE_MAX_NUM
    self.multiLineNum = 0
  return self
end

function watchlogfilemultiline:handleMultiLine(kafkaClient, topic)
    if self.postponeBuffer:match(self.MULTILINE_IDENTIFY) then
        if self.multiLineData then 
            self:handleEventPlus(kafkaClient , topic , self.multiLineData)
        end
        self.multiLineData = {}
        table.insert(self.multiLineData , self.postponeBuffer)
        self.multiLineNum = 1
    else
        if self.multiLineData then
            if self.multiLineNum < self.MULTILINE_MAX_NUM then
                table.insert(self.multiLineData , self.postponeBuffer)
            end
            self.multiLineNum = self.multiLineNum + 1
        end
    end
end

function watchlogfilemultiline:handleData(kafkaClient, topic)
    self.lastFileExist = self.currentNow
    self.tempKafkaKey = self.currentNow .. self.KFK_MSG_KEY_SUFFIX
    for line in self.readerBuffer:gmatch('[^\n]+') do
        if self.postponeBuffer then
            self:handleMultiLine(kafkaClient , topic)
        end
        self.postponeBuffer = line
    end
    if string.byte(self.readerBuffer , -1) == 10 then
        if self.postponeBuffer then
            self:handleMultiLine(kafkaClient , topic)
            self.postponeBuffer = nil
        end
    end
end

function watchlogfilemultiline:handleEventPlus(kafkaClient, topic, msgTable)
    if self.multiLineNum == 1 then
        self:handleEvent(kafkaClient , topic , msgTable[1])
    else
        self.count = self.count + self.multiLineNum - 1
        self:handleEvent(kafkaClient , topic , table.concat(msgTable , '\n'))
    end
end

return watchlogfilemultiline