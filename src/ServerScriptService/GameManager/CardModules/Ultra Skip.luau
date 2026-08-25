--!strict
--!optimize 2

local module = {}

local replicatedStorage = game:GetService("ReplicatedStorage")

local deckManager = require(script.Parent.Parent.Managers.DeckManager)
local helpers = require(script.Parent.Parent.Helpers)

function module.Main(index:number)
	if not helpers.getPillarsTable then return end

	local pillarsTable = helpers.getPillarsTable()
	
	deckManager["IsRoundTerminated"] = true

	local primary = pillarsTable[index].PrimaryPart

	if primary then
		replicatedStorage.Communicators.Remotes.Events.CreateClientEffect:FireAllClients({
			{Type = "TransitionCard", Card = "Ultra Skip", TweenInfo = TweenInfo.new(1, Enum.EasingStyle.Exponential, Enum.EasingDirection.In), From = primary.Position + Vector3.new(0, 30, 0), To = "UsedCards", Parabolic = true},
			{Type = "SetUsedCards", Cards = {"Ultra Skip"}, InitialDelayNumber = 1.5}
		})
	end
end

return module