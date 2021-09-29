local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local StudioService = game:GetService("StudioService")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local ExternalUrl = "http://localhost:31415"

local function GetGameName()
	local success, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, game.PlaceId)
	return success and info.Name or "a place"
end

local StartTime = DateTime.now().UnixTimestamp
local GameName = game.PlaceId > 0 and GetGameName() or "a local file"

local IsTestMode = RunService:IsRunMode()
local IsEditingScript = false
local IsAnimatingRig = false

local HasFailed = false

-- Presence updating functions
local function Failsafe()
	if HasFailed then return end
	HasFailed = true
	
	warn("[robloxstudio-rpc] Failed to connect to local server, aborting presence updates. Make sure you have started the local server and then restart Studio!")
	plugin:Deactivate()
end

local function UpdatePresence()
	local State = nil
	
	if not IsTestMode then
		if IsEditingScript then
			State = "Editing " .. IsEditingScript.Name
		elseif IsAnimatingRig then
			State = "Animating a rig"
		end
	end
	
	local success = pcall(HttpService.RequestAsync, HttpService, {
		Url = ExternalUrl,
		Method = "POST",
		Body = HttpService:JSONEncode({
			Timestamp = StartTime,
			Details = (IsTestMode and "Testing" or "Editing") .. " " .. GameName,
			State = State
		})
	})
	if not success then Failsafe() end
end

local function KillPresence()
	local success = pcall(HttpService.RequestAsync, HttpService, {
		Url = ExternalUrl,
		Method = "DELETE"
	})
	if not success then Failsafe() end
end

-- Script editing detection
StudioService:GetPropertyChangedSignal("ActiveScript"):Connect(function()
	IsEditingScript = StudioService.ActiveScript or false
	UpdatePresence()
end)

-- Rig animating detection
CoreGui.ChildAdded:Connect(function(Object)
	if Object:IsA("Folder") and Object.Name == "GridLines" and not IsTestMode and not IsAnimatingRig then
		IsAnimatingRig = true
		UpdatePresence()
		
		Object.AncestryChanged:Connect(function()
			print("Ancestry changed")
			IsAnimatingRig = false
			UpdatePresence()
		end)
	end
end)

-- Start presence
IsEditingScript = StudioService.ActiveScript or false
UpdatePresence()

-- Handle game closed
plugin.Unloading:Connect(function()
	if HasFailed then return end
	KillPresence()
end)