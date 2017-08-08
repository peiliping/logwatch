local json = require 'rapidjson'
local lpeg = require 'lpeg'

local groks = {
    '"$time_local" $remote_addr $upstream_addr $request_time $request_method $status "$scheme://$host$request_uri" $request_length $body_bytes_sent "$http_referer" "$http_user_agent"'
}

local function dsl(rule)
    print(rule.grok)
    local p = lpeg.P('$') * (lpeg.P('az') + lpeg.S('$'))
    print(lpeg.match(p , rule.grok))
end

for _ , val in ipairs(groks) do
	local rule = {grok = val}
	dsl(rule)
	print("")
	print("---------- line ----------")
	print(rule.regex)
	print(json.encode(rule.mapping))
	print("")
end