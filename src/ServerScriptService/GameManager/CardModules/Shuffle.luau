--!strict
--!optimize 2

local types = require(script.Parent.Parent.Types)
local helpers:types.Helpers = require(script.Parent.Parent.Helpers)

local module = {}

local replicatedStorage = game:GetService("ReplicatedStorage")

local deckManager = require(script.Parent.Parent.Managers.DeckManager)

function module.Main(index:number)
	if (not helpers.getDeck) or (not helpers.getPillarsTable) then warn("No Helpers registered") return end

	local pillarsTable = helpers.getPillarsTable()
	local currentTurnCount = deckManager.GetTurnCount()

	local deck = helpers.getDeck()
	
	print(deck)
	
	Random.new():Shuffle(deck)
	
	print(deck)

	local primary = pillarsTable[index].PrimaryPart

	if primary then
		replicatedStorage.Communicators.Remotes.Events.CreateClientEffect:FireAllClients({
			{Type = "TransitionCard", Card = "Shuffle", TweenInfo = TweenInfo.new(1, Enum.EasingStyle.Exponential, Enum.EasingDirection.In), From = primary.Position + Vector3.new(0, 30, 0), To = "UsedCards", Parabolic = true},
			{Type = "SetUsedCards", Cards = {"Shuffle"}, InitialDelayNumber = 1.5}
		})	
	end
end

return module