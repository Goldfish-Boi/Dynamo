--!strict
--!optimize 2

local tweenService = game:GetService("TweenService")

local hookTemplates = script.Hooks
local waypoints = workspace.Lobby.RoofConveyor.Waypoints

local hookSpeed = 10

local waypointsList:{BasePart} = {}

for _, child in ipairs(waypoints:GetChildren()) do
	if child:IsA("BasePart") then
		table.insert(waypointsList, child)
	end
end

table.sort(waypointsList, function(a, b)
	local aNum = tonumber(a.Name) or 0
	local bNum = tonumber(b.Name) or 0
	return aNum < bNum
end)

function moveHook()
	local hooks:{any} = hookTemplates:GetChildren()
	local hook:Model = hooks[math.random(1, #hooks)]:Clone()

	hook:PivotTo(waypoints["1"].CFrame)

	hook.Parent = workspace.Camera
	
	if not hook.PrimaryPart then return end
	
	local CFrameValue = Instance.new("CFrameValue")
	CFrameValue.Value = hook.PrimaryPart.CFrame

	local connection = CFrameValue:GetPropertyChangedSignal("Value"):Connect(function()
		hook:PivotTo(CFrameValue.Value)
	end)

	for i = 1, #waypoints:GetChildren() - 1 do
		local start:BasePart = waypointsList[i]
		local finish:BasePart = waypointsList[i + 1]
		
		if finish.Color == Color3.fromRGB(255, 0, 0) then
			CFrameValue.Value = finish.CFrame
			continue
		end

		local distance = (finish.Position - start.Position).Magnitude
		local moveTime = distance / hookSpeed

		local tween = tweenService:Create(CFrameValue, TweenInfo.new(moveTime, Enum.EasingStyle.Linear), {Value = finish.CFrame})
		tween:Play()

		task.wait(moveTime)
	end
	
	connection:Disconnect()
	connection = nil

	hook:Destroy()
end

while task.wait(3) do
	task.spawn(function()
		moveHook()
	end)
end