local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local StudioService = game:GetService("StudioService")
local MarketplaceService = game:GetService("MarketplaceService")

local ExternalUrl = "http://localhost:31415"

local function GetGameName()
	local success, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, game.PlaceId)
	return success and info.Name or "a place"
end

local function CheckHttp()
	return pcall(HttpService.GetAsync, HttpService, "https://google.com")
end

if CheckHttp() then
	local StartTime = DateTime.now().UnixTimestamp
	local GameName = game.PlaceId > 0 and GetGameName() or "a local file"
	
	local IsEditing = false

	local function UpdatePresence()
		HttpService:RequestAsync({
			Url = ExternalUrl,
			Method = "POST",
			Body = HttpService:JSONEncode({
				Timestamp = StartTime,
				GameName = GameName,
				Action = IsEditing and "Editing " .. IsEditing or nil
			})
		})
	end
	
	local function KillPresence()
		HttpService:RequestAsync({
			Url = ExternalUrl,
			Method = "DELETE"
		})
	end
	
	local function UpdateActiveScript()
		local Script = StudioService.ActiveScript
		IsEditing = Script and Script.Name or false
	end
	
	StudioService:GetPropertyChangedSignal("ActiveScript"):Connect(function()
		UpdateActiveScript()
		UpdatePresence()
	end)
	
	UpdateActiveScript()
	UpdatePresence()
	
	-- Handle game closed
	plugin.Unloading:Connect(function()
		KillPresence()
	end)
else
	warn("[Discord RPC] HttpService is disabled in this experience. Enable and re-open the place to display rich presence.")
end