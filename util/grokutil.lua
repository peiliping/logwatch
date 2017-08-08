local grok = {}

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

function grok.escapes4regex(rule)
    for _ , v in ipairs(escapes) do
        rule.grok = string.gsub(rule.grok , v[1] , v[2])
    end
end

function grok.base(rule)
    rule.mapping = {}
    grok.escapes4regex(rule)
    local t_grokstr , cts = rule.grok , 1
    while cts > 0 do
        t_grokstr , cts = string.gsub(t_grokstr , '%$([%a|_]+)%$([%a|_]+)' , function(l , f) return '$' .. l .. '_' .. f end)
    end
    local _ , count = string.gsub(t_grokstr , '%$([%a|_]+)' , '(.-)')
    local index , notail = 0 , false
    rule.regex = string.gsub(t_grokstr , '%$([%a|_]+)' , function(w) 
        index = index + 1
        if index == count then
            notail = (w == string.sub(t_grokstr , 0-string.len(w)))
        end
        if w == 'ninja' then
            return (notail and '.*' or '.-')
        else
            table.insert(rule.mapping , w)
            return (notail and '(.*)' or '(.-)')
        end
    end)
end

function grok.plus(rule)
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
        local sp = string.sub(rule.regex , posSeq[index] , posSeq[index])
        if sp == '%' then
            sp = string.sub(rule.regex , posSeq[index] , posSeq[index] + 1)
        end
        sp = '([^' .. sp .. ']*)'
        index = index + 1
        return sp
    end)
    if rule.easysplit then
        result = string.gsub(result , '%)%s+' , ')%%s+')
    end
    rule.regex = result
end

return grok