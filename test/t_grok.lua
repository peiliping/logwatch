local json = require 'rapidjson'
local util  = require 'util.grokutil'

local groks = {
    '"$time_local" $remote_addr $upstream_addr $request_time $request_method $status "$scheme://$host$request_uri" $request_length $body_bytes_sent "$http_referer" "$http_user_agent"'
}

for _ , val in ipairs(groks) do
	local rule = {grok = val , easysplit = true}
	util.base(rule)
	util.plus(rule)
	print("")
	print("---------- line ----------")
	print(rule.regex)
	print(json.encode(rule.mapping))
	print("")
end