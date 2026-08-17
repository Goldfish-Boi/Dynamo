--!optimize 2

local tweenService = game:GetService("TweenService")
local replicatedStorage = game:GetService("ReplicatedStorage")

local cameraShaker = require(replicatedStorage.Modules.CameraShaker)

local explosionParts = script.ExplosionParts

local camShake = cameraShaker.new(Enum.RenderPriority.Camera.Value, function(shakeCFrame) workspace.Camera.CFrame *= shakeCFrame end)

camShake:Start()

return function ()
	local pillar:Model = script.Parent::any
	
	local playerSpawn:BasePart = pillar:FindFirstChild("PlayerSpawn")::BasePart
	
	script.Explosion:Play()
	camShake:Shake(cameraShaker.Presets.ClassicExplosion)
	
	local explosion = Instance.new("Explosion")
	explosion.Position = playerSpawn.Position
	explosion.Parent = workspace.Camera
end