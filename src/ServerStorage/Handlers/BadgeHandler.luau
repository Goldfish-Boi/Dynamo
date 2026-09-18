--!strict
--!optimize 2

local badgeHandler = {}

local badgeService = game:GetService("BadgeService")

function badgeHandler.AwardBadge(plr:Player, badge:number)
	pcall(function()
		if badgeService:UserHasBadgeAsync(plr.User, badge) then return end
		
		badgeService:AwardBadgeAsync(plr.User, badge)
	end)
end

return badgeHandler
