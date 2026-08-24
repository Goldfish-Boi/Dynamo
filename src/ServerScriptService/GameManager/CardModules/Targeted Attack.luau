--!strict
--!optimize 2

local module = {}

local replicatedStorage = game:GetService("ReplicatedStorage")

local deckManager = require(script.Parent.Parent.Managers.DeckManager)
local helpers = require(script.Parent.Parent.Helpers)

function module.Main(index:number)
	if not helpers.getPillarsTable then return end
	
	local currentTurnCount = deckManager.GetTurnCount()
	
	local pillarsTable = helpers.getPillarsTable()
	local isaPlayer, player = helpers.isPlayer(index)
	
	if currentTurnCount == 1 then
		deckManager.SetTurnCount(deckManager.GetTurnCount() + 1)
	else
		deckManager.SetTurnCount(deckManager.GetTurnCount() + 2)
	end
	
	if isaPlayer and player then
		local success, targetIndex = pcall(function()
			return replicatedStorage.Communicators.Remotes.Functions.RequestPlayerDecision:InvokeClient(player, "PickPlayer", false, true)::string
		end)
		
		if success then
			deckManager["OverrideTurnIndex"] = helpers.getPlayerIndex(targetIndex)
		else
			deckManager["OverrideTurnIndex"] = helpers.getPlayerIndex(helpers.getAllOthers(index)[math.random(1, #helpers.getAllOthers(index))])
		end
	else
		deckManager["OverrideTurnIndex"] = helpers.getPlayerIndex(helpers.getAllOthers(index)[math.random(1, #helpers.getAllOthers(index))])
	end
	
	workspace.Sounds.Attack.PitchShiftSoundEffect.Octave = (0.1 * deckManager.GetTurnCount()) + 0.8
	workspace.Sounds.Attack:Play()
	
	deckManager["IsRoundTerminated"] = true
	
	local primary = pillarsTable[index].PrimaryPart

	if primary then
		replicatedStorage.Communicators.Remotes.Events.CreateClientEffect:FireAllClients({
			{Type = "TransitionCard", Card = "Targeted Attack", TweenInfo = TweenInfo.new(1, Enum.EasingStyle.Exponential, Enum.EasingDirection.In), From = primary.Position + Vector3.new(0, 30, 0), To = workspace.UsedCards.Position + Vector3.new(0, 0.25 + (0.5 * (#workspace.Round.Cards.UsedCards:GetChildren())), 0), Parabolic = true},
			{Type = "SetUsedCards", Cards = {"Targeted Attack"}, InitialDelayNumber = 1.5}
		})	
	end
end

return module