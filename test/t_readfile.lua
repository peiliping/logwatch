local parserConfig         = (require 'conf.parserconfig'  ).init()
local customParserConfig   = (require 'conf.parserconfig'  ).getconfig()
local tunningConfig        = (require 'conf.tunningconfig' ).getconfig()
local customLogWatchConfig = (require 'conf.logwatchconfig').getconfig()

local singlelineW = require 'watchlog.watchlogfilesingleline'
local multilineW  = require 'watchlog.watchlogfilemultiline'

for _ , task in ipairs(customLogWatchConfig) do
    local watchlogFac = (task.multiline and multilineW or singlelineW)
    local wtcLogFile = watchlogFac:new(task, customParserConfig, tunningConfig, first)
    local kafakClient = {safeSendMsg = function(topic , key , msg , retrytimes) print(msg) end}
    while wtcLogFile:readFile(kafakClient , nil) > 0 do
    end
end