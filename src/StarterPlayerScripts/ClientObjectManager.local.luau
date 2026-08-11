--!strict
--!optimize 2

local collectionService = game:GetService("CollectionService")

local clientObjects = workspace.ClientSidedObjects

for i, object in ipairs(collectionService:GetTagged("Invisible")) do
	if object:IsA("BasePart") then
		object.Transparency = 1	
	end
end

for i, teleporter in ipairs(clientObjects.Teleporters:GetChildren()) do
	local startPart:BasePart? = teleporter:FindFirstChild("Start")::BasePart?
	local endPart:BasePart? = teleporter:FindFirstChild("End")::BasePart?
	
	if (not startPart) or (not endPart) then return end
	
	startPart.Touched:Connect(function(otherPart:BasePart)
		local character:Model? = otherPart.Parent::Model?
		if not character then return end
		
		if not character:FindFirstChildOfClass("Humanoid") then return end
		
		character:PivotTo(CFrame.new(endPart.Position) * character:GetPivot().Rotation)
	end)
end