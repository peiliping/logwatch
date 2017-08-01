local cjson = require 'cjson'
local util = require 'util.tuil'

local groks = {
    '"$time_local" $remote_addr $upstream_addr $request_time $request_method $status "$scheme://$host$request_uri" $request_length $body_bytes_sent "$http_referer" "$http_user_agent"'
}

for _ , val in ipairs(groks) do
	local rule = {grok = val}
	util.grok(rule)
	util.grokP(rule)
	print("")
	print("---------- Cutting line ----------")
	print(rule.regex)
	print(cjson.encode(rule.mapping))
	print("")
end