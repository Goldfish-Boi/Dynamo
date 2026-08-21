--!strict
--!optimize 2

local types = require(script.Parent.Parent.Types)
local helpers:types.Helpers = require(script.Parent.Parent.Helpers)

local module = {}

local deckManager:types.deckManager = require(script.Parent.Parent.Managers.DeckManager)

function module.Main()
	deckManager.ReverseOrder = not deckManager.ReverseOrderu
	
	deckManager.SetTurnCount(deckManager.GetTurnCount() - 1)
end

return module