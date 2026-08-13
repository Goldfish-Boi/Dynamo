local module = {}

local deckManager = require(script.Parent.Parent.Managers.DeckManager)

function module.Main()
	local currentTurnCount = deckManager.GetTurnCount()
	
	if currentTurnCount == 1 then
		deckManager.SetTurnCount(deckManager.GetTurnCount() + 1)
	else
		deckManager.SetTurnCount(deckManager.GetTurnCount() + 2)
	end
	
	workspace.Sounds.Attack.PitchShiftSoundEffect.Octave = (0.1 * deckManager.GetTurnCount()) + 0.8
	workspace.Sounds.Attack:Play()
	
	deckManager["IsRoundTerminated"] = true
end

return module