--!strict
--!optimize 2

local tweenService = game:GetService("TweenService")
local contentProvider = game:GetService("ContentProvider")

local loadingScreenTips:{string} = require(script.LoadingScreenTips)

local debounceBuffer = 0

for i, service in ipairs(game:GetChildren()) do
	contentProvider:PreloadAsync({service})
	
	debounceBuffer += 1

	if debounceBuffer == 1000 then
		task.wait()
	end
end

print(loadingScreenTips[math.random(1, #loadingScreenTips)])

require(script.SplashScreen)