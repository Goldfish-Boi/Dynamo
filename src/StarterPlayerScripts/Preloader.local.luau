--!strict
--!optimize 2

local contentProvider = game:GetService("ContentProvider")
local replicatedStorage = game:GetService("ReplicatedStorage")

local cardInfo:{[string]:{[string]:any}} = require(replicatedStorage.Modules.CardInfo)::{[string]:any}
local assets = {}

for card, cardData in pairs(cardInfo) do
	if not cardData["IconID"] then continue end
	if typeof(cardData["IconID"]) ~= "number" then continue end
	
	local imageLabel = Instance.new("ImageLabel")
	imageLabel.Image = "rbxassetid://" .. cardData["IconID"]
	
	local decal = Instance.new("Decal")
	decal.ColorMap = "rbxassetid://" .. cardData["IconID"]
	
	table.insert(assets, imageLabel)
	table.insert(assets, decal)
end

contentProvider:PreloadAsync(assets)

for i, item in ipairs(assets::{Instance}) do
	item:Destroy()
end

assets = nil