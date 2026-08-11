--!strict
--!optimize 2

local module = {}

local tweenService = game:GetService("TweenService")
local replicatedStorage = game:GetService("ReplicatedStorage")

local gui = script.Parent.Parent.Parent
local holder = gui.Holder
local buttons = holder.Buttons
local mainFrame = holder.MainFrame
local uiTemplates = script.Parent.Parent.UITemplates

function module.Open()
	tweenService:Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.fromScale(0.75, 0.75)}):Play()
	tweenService:Create(mainFrame.UICorner, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {CornerRadius = UDim.new(0.1, 0)}):Play()
	tweenService:Create(buttons.SettingsButton, TweenInfo.new(0.25, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = UDim2.fromScale(0.15, 0.15), Position = UDim2.fromScale(0.05, 0.26)}):Play()
end

return module