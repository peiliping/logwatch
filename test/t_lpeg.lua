local json = require 'cjson'

local lpeg = require 'lpeg'
locale = lpeg.locale()

local C  = lpeg.C
local Ct = lpeg.Ct
local P  = lpeg.P
local S  = lpeg.S

local grok = '"$time_local" $remote_addr $upstream_addr $request_time $request_method $status "$scheme://$host_request_uri" $request_length $body_bytes_sent "$http_referer" "$http_user_agent"'
local target = '"([^"]*)" ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) "([^:]*)://([^"]*)" ([^ ]*) ([^ ]*) "([^"]*)" "([^"]*)"'

local p_var = C(P'$' * (locale.alpha + S'_-')^1)
local p_other = C(P(1) - p_var)^0
local all = Ct((p_other * p_var * p_other)^1)

local elements = all:match(grok)
for index , value in ipairs(elements) do
	if string.sub(value , 1 , 1) == "$" then
		if elements[index+1] then
		    elements[index] = '([^' .. elements[index+1] .. ']*)'
		else
			elements[index] = '(.*)'
		end
	end
end

print(target)
print(table.concat(elements))