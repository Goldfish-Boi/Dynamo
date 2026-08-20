--!strict
--!optimize 2

local module = {}

local replicatedStorage = game:GetService("ReplicatedStorage")

local deckManager = require(script.Parent.Parent.Managers.DeckManager)
local helpers = require(script.Parent.Parent.Helpers)

function module.Main(index:number)
	local currentTurnCount = deckManager.GetTurnCount()
	
	local isaPlayer, player = helpers.isPlayer(index)
	
	if currentTurnCount == 1 then
		deckManager.SetTurnCount(deckManager.GetTurnCount() + 1)
	else
		deckManager.SetTurnCount(deckManager.GetTurnCount() + 2)
	end
	
	workspace.Sounds.Attack.PitchShiftSoundEffect.Octave = (0.1 * deckManager.GetTurnCount()) + 0.8
	workspace.Sounds.Attack:Play()
	
	if isaPlayer and player then
		local success, targetIndex = pcall(function()
			return replicatedStorage.Communicators.Remotes.Functions.RequestPlayerDecision:InvokeClient(player, "PickPlayer", true)::string
		end)
		
		if success then
			deckManager["OverrideTurnIndex"] = helpers.getPlayerIndex(targetIndex)
		else
			deckManager["OverrideTurnIndex"] = helpers.getPlayerIndex(helpers.getAllOthers(index)[math.random(1, #helpers.getAllOthers(index))])
		end
	else
		deckManager["OverrideTurnIndex"] = helpers.getPlayerIndex(helpers.getAllOthers(index)[math.random(1, #helpers.getAllOthers(index))])
	end
	
	deckManager["IsRoundTerminated"] = true
end

return module