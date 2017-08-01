local tableutil = {}

function tableutil.clone(object)
    if type(object) ~= "table" then
        return object
    else
        local new_table = {}
        for key, value in pairs(object) do
            new_table[key] = tableutil.clone(value)
        end
        return new_table
    end
end

return tableutil