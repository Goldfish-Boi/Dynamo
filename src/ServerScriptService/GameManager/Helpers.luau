--!strict
--!optimize 2

local types = require(script.Parent.Types)
local players = game:GetService("Players")

local helpers: types.Helpers = {} :: types.Helpers

helpers.getPlayerTable = nil
helpers.getPillarsTable= nil
helpers.getDeck= nil
helpers.getPlrCardsProvider= nil

function helpers.setProviders(playerProvider:() -> {string}, pillarsProvider:() -> {Model}, deckProvider:() -> {string}, plrCardsProvider:() -> types.array<{string}>)
	helpers.getPlayerTable = playerProvider
	helpers.getPillarsTable = pillarsProvider
	helpers.getDeck = deckProvider
	helpers.getPlrCardsProvider = plrCardsProvider
end

function helpers.copyTable<T>(t: T): T
	if typeof(t) ~= "table" then return t end

	local copy = {}
	for i, v in pairs(t :: any) do
		copy[i] = helpers.copyTable(v)
	end

	setmetatable(copy, getmetatable(t))
	return copy :: T
end

function helpers.isPlayer(index: number): (boolean, Player?)
	if not helpers.getPlayerTable then return false, nil end

	local playerTable = helpers.getPlayerTable()

	if #playerTable == 0 then return false, nil end

	local plr = playerTable[index]
	local player = players:FindFirstChild(plr)

	if player then
		return true, player :: Player
	else
		return false, nil
	end
end

return helpers