local util      = require 'util'
local fileutil  = require 'fileutil'
local tableutil = require 'tableutil'
local cjson     = require 'cjson'

local GO_ON = true
local STOP  = false

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
    lastFileExist = nil ,
    ---- Temp Data ----
    tempPos = nil ,
    count = nil ,
    currentNow = nil ,
    tempKafkaKey = nil ,
    readerBuffer = nil ,
    postponeBuffer = nil ,
}

watchlogfile.__index = watchlogfile

function watchlogfile:new(task, customParserConfig, tunningConfig, first)
    local self = {}
    setmetatable(self, watchlogfile)
    self.task = task
    self.parseRule = customParserConfig[task.rule]
    self.tunningConfig = tunningConfig

    self.CHECK_FILE_EXIST_INTERVAL = tunningConfig.CHECK_FILE_EXIST_INTERVAL
    self.BUFFER_SIZE = tunningConfig.BUFFER_SIZE
    self.KFK_MSG_KEY_SUFFIX = "_" .. task.rule
    self.EVENT_CONTAINER = tableutil.clone(task.tags)
    self.EVENT_CONTAINER.hostname = util.getHostName()
    self.EVENT_CONTAINER.filename = task.dirpath .. task.filename
    
    self.currentNow , self.lastCheckTime , self.lastFileExist = os.time() , os.time() , os.time()
    self.file , self.inode = fileutil.getFileAndInode(task)
    if first then
        if task.origin or (not self.file) then
            self.pos = 0
        else
            self.pos = self.file:seek("end")
        end
    else
        self.pos = 0
    end
    self.tempPos = 0
    return self
end

function watchlogfile:checkFileRolling()
    if (self.currentNow - self.lastCheckTime) > self.CHECK_FILE_EXIST_INTERVAL then
        local rolling , r_file , r_inode = fileutil.checkFileRolling(self.task, self.file, self.inode)
        if rolling then
            self.file , self.inode , self.pos = r_file , r_inode , 0
        end
        self.lastCheckTime = self.currentNow
    end
    if self.file == nil and self.currentNow - self.lastFileExist > self.CHECK_FILE_EXIST_INTERVAL * 5 then
        self.count = -1
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

function watchlogfile:handleData(kafkaClient, topic)
    self.lastFileExist = self.currentNow
    self.tempKafkaKey = self.currentNow .. self.KFK_MSG_KEY_SUFFIX
    for line in self.readerBuffer:gmatch('[^\n]+') do
        if self.postponeBuffer then 
            self:handleEvent(kafkaClient, topic, self.postponeBuffer)
        end
        self.postponeBuffer = line
    end
    if string.byte(self.readerBuffer, -1) == 10 then
        self:handleEvent(kafkaClient, topic, self.postponeBuffer)
        self.postponeBuffer = nil
    end
end

function watchlogfile:handleEvent(kafkaClient, topic, msg)
    local handled = util.parseData(msg, self.parseRule, self.EVENT_CONTAINER)
    self.count = self.count + 1
    if handled then
        print(cjson.encode(self.EVENT_CONTAINER))
        --kafkaClient.safeSendMsg(topic, self.tempKafkaKey, cjson.encode(self.EVENT_CONTAINER), 10)
    else
        print(msg)
    end
end

function watchlogfile:readFile(kafkaClient, topic)
    self.currentNow = os.time()
    if self:readData2Buffer() then
        self:handleData(kafkaClient, topic)
    else
        self:checkFileRolling()
    end
    return self.count
end

function watchlogfile:close()
    if self.file then
        self.file:close()
    end
end

return watchlogfile