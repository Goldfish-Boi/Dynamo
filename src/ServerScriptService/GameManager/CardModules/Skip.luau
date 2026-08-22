--!strict
--!optimize 2

local module = {}

local helpers = require(script.Parent.Parent.Helpers)
local deckManager = require(script.Parent.Parent.Managers.DeckManager)

function module.Main(index:number, decision:{string})
	if not helpers.getPlrCardsProvider then return end
	
	local plrCardsTable = helpers.getPlrCardsProvider()
	local plrCards = plrCardsTable[index]
	
	for i, card in ipairs(decision) do
		local turnsLeft = deckManager.GetTurnCount()
		
		if turnsLeft > 0 then
			deckManager.SetTurnCount(turnsLeft - 1)
			
			table.remove(plrCards, table.find(plrCards, decision[i]))
		end
	end
end

return module