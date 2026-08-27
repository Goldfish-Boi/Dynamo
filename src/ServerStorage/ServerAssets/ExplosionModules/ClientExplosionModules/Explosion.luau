--!strict
--!optimize 2

local tweenService = game:GetService("TweenService")
local replicatedStorage = game:GetService("ReplicatedStorage")

local cameraShaker = require(replicatedStorage.Modules.CameraShaker)

local explosionParts = replicatedStorage.Assets.ExplosionAssets.Explosion.ExplosionParts

local camShake = cameraShaker.new(Enum.RenderPriority.Camera.Value, function(shakeCFrame) workspace.Camera.CFrame *= shakeCFrame end)::any

camShake:Start()

return function ()
	print("Boom")
	
	local pillar:Model = script.Parent::any
	
	local playerSpawn:BasePart = pillar:FindFirstChild("PlayerSpawn")::BasePart
	
	script.Explosion:Play()
	camShake:Shake(cameraShaker.Presets.Explosion)
	
	for count = 1, 15 do
		local explosionPart:BasePart = explosionParts:GetChildren()[math.random(1, #explosionParts:GetChildren())]:Clone()::BasePart
		
		explosionPart.Position = playerSpawn.Position
		explosionPart.Rotation = Vector3.new(math.random(-180, 180), math.random(-180, 180), math.random(-180, 180))
		explosionPart.Size = Vector3.new(6, 6, 6)
		explosionPart.Parent = workspace.Camera
		
		local lifetime = math.random(5, 10) / 10
		
		task.delay(lifetime, function()
			explosionPart:Destroy()
		end)
		
		task.delay(lifetime - 0.25, function()
			tweenService:Create(explosionPart, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 1, Color = Color3.fromRGB(50, 50, 50)}):Play()
		end)
		
		tweenService:Create(explosionPart, TweenInfo.new(lifetime - 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Color = Color3.fromRGB(189, 113, 69)}):Play()
		tweenService:Create(explosionPart, TweenInfo.new(lifetime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = playerSpawn.Position + Vector3.new(math.random(-20, 20), math.random(-20, 20), math.random(-20, 20)), Size = Vector3.new(25, 25, 25)}):Play()
	end
	
	task.delay(5, function()
		camShake:Stop()
	end)
end