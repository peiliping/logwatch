local util = {}

local cjson = require 'cjson'
local io_open , io_popen = io.open , io.popen
local os_date = os.date

local ffi = require 'ffi'

ffi.cdef[[
    unsigned int sleep(unsigned int seconds);
]]

function util.sleep(sec)
    ffi.C.sleep(sec)
end

function util.getHostName()
    local v = io_popen("hostname")
    local result = v:lines()()
    v:close()
    return result
end

function util.getFileAndInode(task , timestamp)
    local path = task.path
    if task.logNameSuffix then
        path = task.path .. os_date(task.logNameSuffix , timestamp)    
    end
    local file = io_open(path , "r")
    local inode = nil
    if file then
        local tmp = io_popen("ls -i " .. path)
        inode = tmp:lines()()
        tmp:close()
    end
    return file , inode
end

function util.checkFileRolling(task , file , inode , timestamp)
    local rolling = false
    if file == nil then
        file , inode = util.getFileAndInode(task , timestamp)
        rolling = true
    else
        local t_file , t_inode = util.getFileAndInode(task , timestamp)
        if inode == t_inode then
            t_file:close()
        else
            file:close()
            file , inode , rolling = t_file , t_inode , true
        end
    end
    return rolling , file , inode
end

function util.mergeMapTables(tbs)
    local container = {}
    for _ , tb in ipairs(tbs) do
        for key , value in pairs(tb) do
            container[key] = value
        end
    end
    return container
end

function util.mergeMapTables2Left(left , right)
    for key , value in pairs(right) do
        left[key] = value
    end
end

function util.parseData(msg , rule , container)
    local handled , parseResult = false , {msg:match(rule.regex)}
    for index , value in ipairs(parseResult) do
        local cf = rule.conversion[index]
        container[rule.mapping[index]] = (cf and cf(value) or value)
        handled = true
    end
    return handled
end

function util.grok(rule)
    rule.mapping = {}
    local escapes = {
        ['%%'] = '%%%' ,
        ['%.'] = '%%.' ,
        ['%['] = '%%[' ,
        ['%]'] = '%%]' ,
        ['%('] = '%%(' ,
        ['%)'] = '%%)' ,
        ['%+'] = '%%+' ,
        ['%*'] = '%%*' ,
        ['%-'] = '%%-' ,
        ['%?'] = '%%?' ,
        ['%^'] = '%%^' ,
    }
    for k , v in pairs(escapes) do
        rule.grok = string.gsub(rule.grok , k , v)
    end
    local t_grokstr , cts = string.gsub(rule.grok , '%$([%a|_]+)%$([%a|_]+)' , function(l , f) return '$' .. l .. '_' .. f end)
    while cts > 0 do
        t_grokstr , cts = string.gsub(t_grokstr , '%$([%a|_]+)%$([%a|_]+)' , function(l , f) return '$' .. l .. '_' .. f end)
    end
    local _ , count = string.gsub(t_grokstr , '%$([%a|_]+)' , '(.-)')
    local index = 0 
    rule.regex = string.gsub(t_grokstr , '%$([%a|_]+)' , function(w) 
        table.insert(rule.mapping , w)
        index = index + 1
        return (index == count and '(.*)' or '(.-)')
    end)
end

function util.grokP(rule)
    local total_len , pos = string.len(rule.regex) , 0 
    local posSeq = {}

    while  total_len - pos > 4 do
        pos = string.find(rule.regex , '%(%.%-%)' , pos)
        if pos then
            pos = pos + 4
            table.insert(posSeq , pos)
        else
            pos = total_len
        end
    end

    local index = 1
    local result = string.gsub(rule.regex , '%(%.%-%)' , function(w)
        local sp = string.sub(rule.regex , posSeq[index] , posSeq[index] + 1)
        if sp == '%' then
            sp = string.sub(rule.regex , posSeq[index] , posSeq[index] + 2)
        end
        sp = '([^' .. sp .. ']*)'
        index = index + 1
        return sp
    end)
    rule.regex = result
end    

return util