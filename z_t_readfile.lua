local customParserConfig = require 'conf.parserconfig'
customParserConfig.init()
local tunningConfig = require 'conf.tunningconfig'
local singlelineW = require 'watchlogfilesingleline'
local multilineW = require 'watchlogfilemultiline'
local customLogWatchConfig = require 'z_t_logwatchconfig'

for _ , task in ipairs(customLogWatchConfig.getconfig()) do
    local watchlogFac = (task.multiline and multilineW or singlelineW)
    local wtcLogFile = watchlogFac:new(task , customParserConfig , tunningConfig)
    local kafakClient = {safeSendMsg = function(topic , key , msg , retrytimes) print(msg) end}
    while wtcLogFile:readFile(kafakClient , nil) > 0 do
    end
end