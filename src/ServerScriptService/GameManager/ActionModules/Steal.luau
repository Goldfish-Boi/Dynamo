--!strict
--!optimize 2

local types = require(script.Parent.Parent.Types)
local helpers = require(script.Parent.Parent.Helpers)

local stealModule = {}

local replicatedStorage = game:GetService("ReplicatedStorage")

function stealModule.Steal(index:number, actionInfo:types.ActionInfo)
	if not helpers.getPlrCardsProvider then warn("No Helpers registered") return end
	
	print("Steal")
	
	local isaPlayer, player = helpers.isPlayer(index)
	local plrCards = helpers.getPlrCardsProvider()
	
	if isaPlayer and player then
		local success, index:string|number = pcall(function()
			return replicatedStorage.Communicators.Remotes.Functions.RequestPlayerDecision:InvokeClient(player, "Steal", #plrCards[actionInfo.TargetIndex])
		end)
		
		if not success then
			print("Disconnected")
			return
		end
		
		if typeof(index) == "string" then
			print("AFK while stealing")
			return
		end
		
		print(index)
	end
end

function stealModule.TripleSteal(index:number, actionInfo:types.ActionInfo)
	if not helpers.getPlrCardsProvider then warn("No Helpers registered") return end
	
	print("Triple Steal")
end


return stealModule
