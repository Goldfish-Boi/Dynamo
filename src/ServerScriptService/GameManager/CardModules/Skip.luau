--!strict
--!optimize 2

local module = {}

local replicatedStorage = game:GetService("ReplicatedStorage")

local helpers = require(script.Parent.Parent.Helpers)
local deckManager = require(script.Parent.Parent.Managers.DeckManager)

function module.Main(index:number, decision:{string})
	if not helpers.getPlrCardsProvider or not helpers.getPillarsTable then return end

	local pillarsTable = helpers.getPillarsTable()
	local plrCardsTable = helpers.getPlrCardsProvider()
	local plrCards = plrCardsTable[index]
	
	local isaPlayer, player = helpers.isPlayer(index)

	local cardsUsed = 0

	for i, card in ipairs(decision) do
		local turnsLeft = deckManager.GetTurnCount()
		
		if turnsLeft > 0 then
			deckManager.SetTurnCount(turnsLeft - 1)
			
			cardsUsed += 1
			
			table.remove(plrCards, table.find(plrCards, decision[i]))
		end
	end
	
	if #decision > 1 and isaPlayer and player then
		replicatedStorage.Communicators.Remotes.Events.OrderClientAction:FireClient(player, "RemoveSelected", nil, cardsUsed)
	end

	local primary = pillarsTable[index].PrimaryPart

	if cardsUsed > 0 and primary then
		local cardsToUse = {}

		for i = 1, cardsUsed do
			table.insert(cardsToUse, "Reverse")
		end

		replicatedStorage.Communicators.Remotes.Events.CreateClientEffect:FireAllClients({
			{Type = "TransitionCard", Card = cardsToUse, TweenInfo = TweenInfo.new(1, Enum.EasingStyle.Exponential, Enum.EasingDirection.In), From = primary.Position + Vector3.new(0, 30, 0), To = workspace.UsedCards.Position + Vector3.new(0, 0.25 + (0.5 * (#workspace.Round.Cards.UsedCards:GetChildren())), 0), Parabolic = true},
			{Type = "SetUsedCards", Cards = cardsToUse, DelayNumber = 0.125, InitialDelayNumber = 1.5}
		})
	end
end

return module