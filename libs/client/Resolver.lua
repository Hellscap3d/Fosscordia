local fs = require('fs')
local base64 = require('base64')
local class = require('class')

local encode = base64.encode
local readFileSync = fs.readFileSync
local classes = class.classes
local isInstance = class.isInstance
local insert = table.insert
local format = string.format

local Resolver = {}

local int64_t, uint64_t, istype
local function loadffi()
	local ffi = require('ffi')
	istype = ffi.istype
	int64_t = ffi.typeof('int64_t')
	uint64_t = ffi.typeof('uint64_t')
end

local function int(obj)
	local t = type(obj)
	if t == 'string' and tonumber(obj) then
		return obj
	elseif t == 'cdata' then
		if not istype then loadffi() end
		if istype(int64_t, obj) or istype(uint64_t, obj) then
			return tostring(obj):match('%d*')
		end
	elseif t == 'number' then
		return format('%i', obj)
	end
end

function Resolver.userId(obj)
	if isInstance(obj, classes.User) then
		return obj.id
	elseif isInstance(obj, classes.Member) then
		return obj.user.id
	end
	return int(obj)
end

function Resolver.messageId(obj)
	if isInstance(obj, classes.Message) then
		return obj.id
	end
	return int(obj)
end

function Resolver.channelId(obj)
	if isInstance(obj, classes.Channel) then
		return obj.id
	end
	return int(obj)
end

function Resolver.roleId(obj)
	if isInstance(obj, classes.Role) then
		return obj.id
	end
	return int(obj)
end

function Resolver.guildId(obj)
	if isInstance(obj, classes.Guild) then
		return obj.id
	end
	return int(obj)
end

function Resolver.messageIds(objs)
	local ret = {}
	if isInstance(objs, classes.Iterable) then
		for obj in objs:iter() do
			insert(ret, Resolver.messageId(obj))
		end
	elseif type(objs) == 'table' then
		for _, obj in pairs(objs) do
			insert(ret, Resolver.messageId(obj))
		end
	end
	return ret
end

function Resolver.emoji(obj)
	if isInstance(obj, classes.Emoji) then
		return obj.name .. ':' .. obj.id
	elseif isInstance(obj, classes.Reaction) then
		if obj.emojiId then
			return obj.emojiName .. ':' .. obj.emojiId
		else
			return obj.emojiName
		end
	end
	return tostring(obj)
end

function Resolver.color(obj)
	if isInstance(obj, classes.Color) then
		return obj.value
	end
	return tonumber(obj)
end

function Resolver.permissions(obj)
	if isInstance(obj, classes.Permissions) then
		return obj.value
	end
	return tonumber(obj)
end

function Resolver.base64(obj)
	if type(obj) == 'string' then
		if obj:find('data:.*;base64,') == 1 then
			return obj
		end
		local data, err = readFileSync(obj)
		if not data then
			return nil, err
		end
		return 'data:;base64,' .. encode(data)
	end
	return nil
end

return Resolver