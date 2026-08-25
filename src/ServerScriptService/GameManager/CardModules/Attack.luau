--!strict
--!optimize 2

local module = {}

local replicatedStorage = game:GetService("ReplicatedStorage")

local helpers = require(script.Parent.Parent.Helpers)
local deckManager = require(script.Parent.Parent.Managers.DeckManager)

function module.Main(index:number)
	if not helpers.getPillarsTable then return end
	
	local pillarsTable = helpers.getPillarsTable()
	local currentTurnCount = deckManager.GetTurnCount()
	
	if currentTurnCount == 1 then
		deckManager.SetTurnCount(deckManager.GetTurnCount() + 1)
	else
		deckManager.SetTurnCount(deckManager.GetTurnCount() + 2)
	end
	
	workspace.Sounds.Attack.PitchShiftSoundEffect.Octave = (0.1 * deckManager.GetTurnCount()) + 0.8
	workspace.Sounds.Attack:Play()
	
	deckManager["IsRoundTerminated"] = true
	
	local primary = pillarsTable[index].PrimaryPart

	if primary then
		replicatedStorage.Communicators.Remotes.Events.CreateClientEffect:FireAllClients({
			{Type = "TransitionCard", Card = "Attack", TweenInfo = TweenInfo.new(1, Enum.EasingStyle.Exponential, Enum.EasingDirection.In), From = primary.Position + Vector3.new(0, 30, 0), To = "UsedCards", Parabolic = true},
			{Type = "SetUsedCards", Cards = {"Attack"}, InitialDelayNumber = 1.5}
		})	
	end
end

return module