local util = {}

local ffi   = require 'ffi'

ffi.cdef[[
    unsigned int sleep(unsigned int seconds);
]]

function util.sleep(sec)
    ffi.C.sleep(sec)
end

function util.getHostName()
    local v = io.popen("hostname")
    local result = v:lines()()
    v:close()
    return result
end

local escapes = {
    {'%%' , '%%%'} ,
    {'%.' , '%%.'} ,
    {'%[' , '%%['} ,
    {'%]' , '%%]'} ,
    {'%(' , '%%('} ,
    {'%)' , '%%)'} ,
    {'%+' , '%%+'} ,
    {'%*' , '%%*'} ,
    {'%-' , '%%-'} ,
    {'%?' , '%%?'} ,
    {'%^' , '%%^'} ,
}

function util.escapes4regex(rule)
    for _ , v in ipairs(escapes) do
        rule.grok = string.gsub(rule.grok , v[1] , v[2])
    end
end

function util.grok(rule)
    rule.mapping = {}
    util.escapes4regex(rule)
    local t_grokstr , cts = rule.grok , 1
    while cts > 0 do
        t_grokstr , cts = string.gsub(t_grokstr , '%$([%a|_]+)%$([%a|_]+)' , function(l , f) return '$' .. l .. '_' .. f end)
    end
    local _ , count = string.gsub(t_grokstr , '%$([%a|_]+)' , '(.-)')
    local index = 0 
    rule.regex = string.gsub(t_grokstr , '%$([%a|_]+)' , function(w) 
        index = index + 1
        if w == 'ninja' then
            return (index == count and '.*' or '.-')
        else
            table.insert(rule.mapping , w)
            return (index == count and '(.*)' or '(.-)')
        end
    end)
end

function util.grokP(rule)
    local total_len , pos = string.len(rule.regex) , 0 
    local posSeq = {}
    -- ensure the starting,ending of not greedy regex 
    while  total_len - pos > 4 do
        pos = string.find(rule.regex , '%(%.%-%)' , pos)
        if pos then
            pos = pos + 4
            table.insert(posSeq , pos)
        else
            pos = total_len
        end
    end
    -- convert not greedy regex to limit greey regex
    local index = 1
    local result = string.gsub(rule.regex , '%(%.%-%)' , function(w)
        local sp = string.sub(rule.regex , posSeq[index] , posSeq[index])
        if sp == '%' then
            sp = string.sub(rule.regex , posSeq[index] , posSeq[index] + 1)
        end
        sp = '([^' .. sp .. ']*)'
        index = index + 1
        return sp
    end)
    -- ignore multi blank split
    if rule.easysplit then
        result = string.gsub(result , '%)%s+' , ')%%s+')
    end

    rule.regex = result
end

return util