--!strict
--!optimize 2

local tweenService = game:GetService("TweenService")

return function ()
	local splashScreen = script.SplashScreen
	
	if game.Players.LocalPlayer then
		splashScreen.Parent = game.Players.LocalPlayer.PlayerGui
	end
	
	splashScreen.Background.Logo.Size = UDim2.fromScale(0, 0)
	
	for i, instance in ipairs(splashScreen:GetDescendants()) do
		if instance:IsA("GuiObject") then
			instance.InputSink = Enum.InputSink.All
			instance.Active = true
			instance.Interactable = true
		end
	end
	
	task.wait(1)
	
	tweenService:Create(splashScreen.Background.Logo, TweenInfo.new(1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.fromScale(0.3, 0.3)}):Play()
	
	task.wait(1.5)
	
	tweenService:Create(splashScreen.Background.Logo, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {ImageTransparency = 1}):Play()
	--tweenService:Create(splashScreen.Background, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency = 1}):Play()
	
	task.wait(0.5)
	
	for i = 1, 5 do
		local right = splashScreen.Background.Frames:FindFirstChild("Right" .. i)::Frame
		local left = splashScreen.Background.Frames:FindFirstChild("Left" .. i)::Frame
		
		if right then
			tweenService:Create(right, TweenInfo.new(1, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), {Position = UDim2.fromScale(right.Position.X.Scale, -1)}):Play()
		end
		
		if left then
			tweenService:Create(left, TweenInfo.new(1, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), {Position = UDim2.fromScale(left.Position.X.Scale, 1)}):Play()
		end
		
		task.wait(0.2)
	end
	
	task.wait(1)
	
	splashScreen:Destroy()
end