local Snowflake = require('./Snowflake')
local Bitfield = require('../utils/Bitfield')

local json = require('json')
local enums = require('../enums')
local class = require('../class')
local typing = require('../typing')
local helpers = require('../helpers')
local constants = require('../constants')

local format = string.format
local insert = table.insert
local checkEnum = typing.checkEnum
local readOnly = helpers.readOnly

local JUMP_LINK_FMT = constants.JUMP_LINK_FMT
local USER_PATTERN = constants.USER_PATTERN
local ROLE_PATTERN = constants.ROLE_PATTERN
local CHANNEL_PATTERN = constants.CHANNEL_PATTERN
local EMOJI_PATTERN = constants.EMOJI_PATTERN
local TIMESTAMP_PATTERN = constants.TIMESTAMP_PATTERN
local STYLED_TIMESTAMP_PATTERN = constants.STYLED_TIMESTAMP_PATTERN

local Message, get = class('Message', Snowflake)

function Message:__init(data, client)

	Snowflake.__init(self, data, client)

	self._channel_id = data.channel_id
	self._guild_id = data.guild_id
	self._webhook_id = data.webhook_id
	self._type = data.type
	self._author = client.state:newUser(data.author)
	self._content = data.content
	self._timestamp = data.timestamp
	self._edited_timestamp = data.edited_timestamp
	self._tts = data.tts
	self._mention_everyone = data.mention_everyone
	self._nonce = data.nonce
	self._pinned = data.pinned
	self._flags = data.flags
	self._mentions = client.state:newUsers(data.mentions)
	self._embeds = data.embeds
	self._attachments = data.attachments

	if data.reactions then
		self._reactions = client.state:newReactions(data.channel_id, data.id, data.reactions)
	end

	-- TODO: activity, application, reference

end

function Message:setContent(content)
	return self.client:editMessage(self.channelId, self.id, {content = content or json.null})
end

function Message:setEmbed(embed)
	return self.client:editMessage(self.channelId, self.id, {embed = embed or json.null})
end

function Message:hideEmbeds()
	local flags = Bitfield(self.flags)
	flags:disableValue(enums.messageFlag.suppressEmbeds)
	return self.client:editMessage({flags = flags:toDec()})
end

function Message:showEmbeds()
	local flags = Bitfield(self.flags)
	flags:enableValue(enums.messageFlag.suppressEmbeds)
	return self.client:editMessage({flags = flags:toDec()})
end

function Message:hasFlag(flag)
	return Bitfield(self.flags):hasValue(checkEnum(enums.messageFlag, flag))
end

function Message:pin()
	return self.client:pinMessage(self.channelId, self.id)
end

function Message:unpin()
	return self.client:unpinMessage(self.channelId, self.id)
end

function Message:addReaction(emoji)
	return self.client:addReaction(self.channelId, self.id, emoji)
end

function Message:removeReaction(emoji, userId)
	return self.client:removeReaction(self.channelId, self.id, emoji, userId)
end

function Message:clearReactions(emoji)
	return self.client:clearReactions(self.channel, self.id, emoji)
end

function Message:delete()
	return self.client:deleteMessage(self.channelId, self.id)
end

function Message:reply(payload)
	return self.client:createMessage(self.channelId, payload)
end

function Message:getChannel()
	return self.client:getChannel(self.channelId)
end

function Message:getRawMentions(type)

	type = checkEnum(enums.mentionType, type)
	local mentions = {}

	if type == enums.mentionType.user then
		for id in self.content:gmatch(USER_PATTERN) do
			insert(mentions, {id = id})
		end
	elseif type == enums.mentionType.role then
		for id in self.content:gmatch(ROLE_PATTERN) do
			insert(mentions, {id = id})
		end
	elseif type == enums.mentionType.channel then
		for id in self.content:gmatch(CHANNEL_PATTERN) do
			insert(mentions, {id = id})
		end
	elseif type == enums.mentionType.emoji then
		for a, name, id in self.content:gmatch(EMOJI_PATTERN) do
			insert(mentions, {animated = a == 'a', name = name, id = id})
		end
	elseif type == enums.mentionType.timestamp then
		for timestamp in self.content:gmatch(TIMESTAMP_PATTERN) do
			insert(mentions, {timestamp = timestamp})
		end
		for timestamp, style in self.content:gmatch(STYLED_TIMESTAMP_PATTERN) do
			insert(mentions, {timestamp = timestamp, style = style})
		end
	end

	return mentions

end

function Message:crosspost()
	return self.client:crosspostMessage(self.channelId, self.id)
end

function Message:getMember()
	if not self.guildId then
		return nil, 'Not a guild message'
	end
	return self.client:getGuildMember(self.guildId, self.author.id)
end

function Message:getGuild()
	if not self.guildId then
		return nil, 'Not a guild message'
	end
	return self.client:getGuild(self.guildId)
end

function get:type()
	return self._type
end

function get:flags()
	return self._flags or 0
end

function get:pinned()
	return self._pinned
end

function get:tts()
	return self._tts
end

function get:nonce()
	return self._nonce
end

function get:author()
	return self._author
end

function get:editedTimestamp()
	return self._edited_timestamp
end

function get:mentionsEveryone()
	return self._mention_everyone
end

function get:mentionedUsers()
	return self._mentions
end

function get:embed()
	return self.embeds[1]
end

function get:attachment()
	return self.attachments[1]
end

function get:embeds()
	return readOnly(self._embeds)
end

function get:attachments()
	return readOnly(self._attachments)
end

function get:reactions()
	return self._reactions
end

function get:content()
	return self._content
end

function get:channelId()
	return self._channel_id
end

function get:guildId()
	return self._guild_id
end

function get:link()
	local guildId = self.guildId
	local channelId = self.channelId
	return format(JUMP_LINK_FMT, guildId or '@me', channelId, self.id)
end

function get:webhookId()
	return self._webhook_id
end

return Message
