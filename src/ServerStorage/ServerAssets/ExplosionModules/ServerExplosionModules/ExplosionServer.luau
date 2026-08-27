--!strict
--!optimize 2

return function ()
	print("Boom")
	
	local pillar:Model = script.Parent::any
	local playerSpawn:BasePart = pillar:FindFirstChild("PlayerSpawn")::BasePart
	
	local player:Player? = game.Players:FindFirstChild(pillar.Name)::Player?
	
	if player and player.Character then
		local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
		
		if humanoid then
			humanoid.Health = 0
		end
	end
	
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = pillar:GetChildren()
	params.ExcludeInstances = {playerSpawn}
	
	local parts = workspace:GetPartBoundsInRadius(playerSpawn.Position, math.random(75, 200) / 10, params)
	
	print(parts)
	
	for i, part in ipairs(parts) do
		part.Anchored = false
		part.RootPriority = math.random(0, 255)
	end
	
	task.wait()
	
	for i, part in ipairs(parts) do
		part.AssemblyLinearVelocity = Vector3.new(math.random(50, 100) * ((math.random(0, 1) * 2) - 1), math.random(50, 100), math.random(50, 100) * ((math.random(0, 1) * 2) - 1))
		--part:ApplyImpulse(Vector3.new(math.random(50, 100) * ((math.random(0, 1) * 2) - 1), math.random(50, 100), math.random(50, 100) * ((math.random(0, 1) * 2) - 1)))
	end
	
	task.wait(5)
	
	for i, part in ipairs(parts) do
		part:Destroy()
	end
	
	if player then
		game.ReplicatedStorage.Communicators.Remotes.Events.TransitionWithRound:FireClient(player)
		player:LoadCharacterAsync()
	end
end