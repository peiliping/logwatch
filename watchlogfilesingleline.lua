local util = require 'util'
local cjson = require 'cjson'

local os_time = os.time
local string_byte = string.byte

local GO_ON = true
local STOP = false

local watchlogfile = {
    task = nil ,
    parseRule = nil ,
    tunningConfig = nil ,
    ---- CONSTANTS ----
    CHECK_FILE_EXIST_INTERVAL = nil ,
    BUFFER_SIZE = nil ,
    KFK_MSG_KEY_SUFFIX = nil,
    EVENT_CONTAINER = nil ,
    ---- Core Data ----
    file = nil ,
    inode = nil ,
    pos = nil ,
    lastCheckTime = nil ,
    ---- Temp Data ----
    tempPos = nil ,
    count = nil ,
    currentNow = nil , 
    tempKafkaKey = nil ,
    readerBuffer = nil ,
    postponeBuffer = nil ,
}

watchlogfile.__index = watchlogfile

function watchlogfile:new(task , customParserConfig , tunningConfig)
    local self = {}
    setmetatable(self , watchlogfile)
    self.task = task
    self.parseRule = customParserConfig.getconfig()[task.rule]
    self.tunningConfig = tunningConfig

    self.CHECK_FILE_EXIST_INTERVAL = tunningConfig.getconfig().CHECK_FILE_EXIST_INTERVAL
    self.BUFFER_SIZE = tunningConfig.getconfig().BUFFER_SIZE
    self.KFK_MSG_KEY_SUFFIX = "_" .. task.rule
    self.EVENT_CONTAINER = util.mergeMapTables({task.tags , {hostname = util.getHostName()}})
    
    self.currentNow = os_time()
    self.lastCheckTime = os_time()
    self.file , self.inode = util.getFileAndInode(task , self.lastCheckTime)
    if task.origin or (not self.file) then
        self.pos = 0
    else
        self.pos = self.file:seek("end")
    end
    self.tempPos = 0
    return self
end 

function watchlogfile:checkFileRolling()
    if (self.currentNow - self.lastCheckTime) > self.CHECK_FILE_EXIST_INTERVAL then
        local rolling , r_file , r_inode = util.checkFileRolling(self.task , self.file , self.inode , self.currentNow)
        if rolling then
            self.file , self.inode , self.pos = r_file , r_inode , 0
        end
        self.lastCheckTime = self.currentNow
    end
end

function watchlogfile:readData2Buffer()
    self.tempPos = (self.file and self.file:seek("end") or 0)
    self.count = 0
    if self.tempPos <= self.pos then
        return STOP
    end
    self.file:seek("set" , self.pos)
    self.readerBuffer = ""
    if self.tempPos - self.pos < self.BUFFER_SIZE then
        self.readerBuffer = self.file:read(self.tempPos - self.pos)
        self.pos = self.tempPos
    else
        self.readerBuffer = self.file:read(self.BUFFER_SIZE)
        self.pos = self.pos + self.BUFFER_SIZE
    end
    if self.postponeBuffer then
        self.readerBuffer = self.postponeBuffer .. self.readerBuffer
        self.postponeBuffer = nil
    end    
    return GO_ON
end

function watchlogfile:handleData(kafkaClient , topic)
    self.tempKafkaKey = self.currentNow .. self.KFK_MSG_KEY_SUFFIX
    for line in self.readerBuffer:gmatch('[^\n]+') do
        if self.postponeBuffer then 
            self:handleEvent(kafkaClient , topic , self.postponeBuffer)
        end
        self.postponeBuffer = line
        self.count = self.count + 1
    end
    if string_byte(self.readerBuffer , -1) == 10 then
        self:handleEvent(kafkaClient , topic , self.postponeBuffer)
        self.postponeBuffer = nil
    end
end

function watchlogfile:handleEvent(kafkaClient , topic , msg)
    local handled = util.parseData(msg , self.parseRule , self.EVENT_CONTAINER)
    if handled then
        kafkaClient.safeSendMsg(topic , self.tempKafkaKey , cjson.encode(self.EVENT_CONTAINER) , 10)
    else
        print(msg)
    end
end

function watchlogfile:readFile(kafkaClient , topic)
    self.currentNow = os_time()
    if self:readData2Buffer() then 
        self:handleData(kafkaClient , topic)
    else
        self:checkFileRolling()    
    end
    return self.count
end

function watchlogfile:close()
    self.file:close()
end

return watchlogfile