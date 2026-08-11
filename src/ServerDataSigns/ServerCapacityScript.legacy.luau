local TweenService = game:GetService("TweenService")

game.Players.PlayerAdded:Connect(function(plr)
	TweenService:Create(script.Parent.BG.Progress, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Size = UDim2.fromScale(#game.Players:GetPlayers() / game.Players.MaxPlayers, 1)}):Play()
	script.Parent.BG.TextLabel.Text = tostring(#game.Players:GetPlayers()) .. " / " .. game.Players.MaxPlayers
	script.Parent.TextLabel.Text = "Server Capacity [" .. math.round(#game.Players:GetPlayers() * 1000 / game.Players.MaxPlayers) / 10 .. "%]"
end)

game.Players.PlayerRemoving:Connect(function()
	TweenService:Create(script.Parent.BG.Progress, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Size = UDim2.fromScale(#game.Players:GetPlayers() / game.Players.MaxPlayers, 1)}):Play()
	script.Parent.BG.TextLabel.Text = tostring(#game.Players:GetPlayers()) .. " / " .. game.Players.MaxPlayers
	script.Parent.TextLabel.Text = "Server Capacity [" .. math.round(#game.Players:GetPlayers() * 1000 / game.Players.MaxPlayers) / 10 .. "%]"
end)