-- PremiumSpinWheelServerWithGamepass.lua
-- Place in ServerScriptService
-- This handles PREMIUM wheel with GamePass purchase system and spin counter

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")

-- PREMIUM GamePass IDs (CHANGE THESE TO YOUR ACTUAL PREMIUM GAMEPASS IDs)
local PREMIUM_GAMEPASS_5_CREDITS = 1643732909
local PREMIUM_GAMEPASS_20_CREDITS = 1643289140

-- Create or get PREMIUM RemoteEvents
local function getOrCreateRemoteEvent(name)
	local event = ReplicatedStorage:FindFirstChild(name)
	if not event then
		event = Instance.new("RemoteEvent")
		event.Name = name
		event.Parent = ReplicatedStorage
	end
	return event
end

local PremiumSpinWheelPrize = getOrCreateRemoteEvent("PremiumSpinWheelPrize")
local PremiumGetCreditsEvent = getOrCreateRemoteEvent("PremiumGetCreditsEvent")
local PremiumUpdateCreditsEvent = getOrCreateRemoteEvent("PremiumUpdateCreditsEvent")
local PremiumPurchaseGamePassEvent = getOrCreateRemoteEvent("PremiumPurchaseGamePassEvent")

-- NEW: Premium spin counter RemoteEvents
local PremiumUpdateSpinCounterEvent = getOrCreateRemoteEvent("PremiumUpdateSpinCounterEvent")
local PremiumSpecial30thSpinEvent = getOrCreateRemoteEvent("PremiumSpecial30thSpinEvent")
local PremiumUpdateProgressContainersEvent = getOrCreateRemoteEvent("PremiumUpdateProgressContainersEvent")

-- DataStores for saving PREMIUM data
local premiumCreditsDataStore = DataStoreService:GetDataStore("PremiumSpinWheelCredits")
local premiumSpinCounterDataStore = DataStoreService:GetDataStore("PremiumSpinWheelCounter")
local premiumMilestoneDataStore = DataStoreService:GetDataStore("PremiumSpinWheelMilestones")

-- Store player PREMIUM data in memory
local playerPremiumCredits = {}
local playerPremiumSpinCounters = {}
local playerPremiumMilestones = {}

-- Function to give PREMIUM tool to player
local function givePremiumToolToPlayer(player, toolName)
	-- Look for tool in ReplicatedStorage
	local tool = nil
	local possibleFolders = {"PremiumTools", "Tools", "Cars", "Ships", "Items"}

	for _, folderName in ipairs(possibleFolders) do
		local folder = ReplicatedStorage:FindFirstChild(folderName)
		if folder then
			tool = folder:FindFirstChild(toolName)
			if tool then break end
		end
	end

	if not tool then
		tool = ReplicatedStorage:FindFirstChild(toolName)
	end

	if tool then
		local toolClone = tool:Clone()
		toolClone.Parent = player.Backpack
		print("🎩 PREMIUM: " .. player.Name .. " received tool: " .. toolName)
		return true
	else
		warn("🎩 ❌ Premium Tool '" .. toolName .. "' not found!")
		return false
	end
end

-- Function to update player PREMIUM credits
local function updatePlayerPremiumCredits(player, amount)
	local userId = player.UserId
	if not playerPremiumCredits[userId] then
		playerPremiumCredits[userId] = 0
	end

	playerPremiumCredits[userId] = playerPremiumCredits[userId] + amount

	-- Update client
	PremiumUpdateCreditsEvent:FireClient(player, playerPremiumCredits[userId])

	-- Save to DataStore
	pcall(function()
		premiumCreditsDataStore:SetAsync(userId, playerPremiumCredits[userId])
	end)

	return playerPremiumCredits[userId]
end

-- Function to increment PREMIUM spin counter
local function incrementPremiumSpinCounter(player)
	local userId = player.UserId

	if not playerPremiumSpinCounters[userId] then
		playerPremiumSpinCounters[userId] = 0
	end

	playerPremiumSpinCounters[userId] = playerPremiumSpinCounters[userId] + 1

	pcall(function()
		premiumSpinCounterDataStore:SetAsync(userId, playerPremiumSpinCounters[userId])
	end)

	UpdateSpinCounterEvent:FireClient(player, playerPremiumSpinCounters[userId])

	return playerPremiumSpinCounters[userId]
end

-- NEW: Function to check premium milestones and update containers
local function checkAndUpdatePremiumMilestones(player)
	local userId = player.UserId
	local totalSpins = playerPremiumSpinCounters[userId] or 0
	local milestones = playerPremiumMilestones[userId] or {}

	-- Check if player reached 30 spins and hasn't received Scanner5 (Premium Prize 3)
	if totalSpins >= 30 and not milestones.scanner5 then
		-- Give Scanner5 (Premium Prize 3)
		if givePremiumToolToPlayer(player, "Scanner5") then
			milestones.scanner5 = true
			playerPremiumMilestones[userId] = milestones

			pcall(function()
				premiumMilestoneDataStore:SetAsync(userId, milestones)
			end)

			-- Update client to switch to container 2
			PremiumUpdateProgressContainersEvent:FireClient(player, 2, "Scanner5")
			print("🎩 " .. player.Name .. " earned Scanner5 (Premium Prize 3) at 30 spins")
			return true
		end

		-- Check if player reached 60 spins and hasn't received Magic Carpet (Premium Prize 5)
	elseif totalSpins >= 60 and not milestones.magicCarpet then
		-- Give Magic Carpet (Premium Prize 5)
		if givePremiumToolToPlayer(player, "Magic Carpet") then
			milestones.magicCarpet = true
			playerPremiumMilestones[userId] = milestones

			pcall(function()
				premiumMilestoneDataStore:SetAsync(userId, milestones)
			end)

			-- Update client to hide both containers
			PremiumUpdateProgressContainersEvent:FireClient(player, 0, "Magic Carpet")
			print("🎩 " .. player.Name .. " earned Magic Carpet (Premium Prize 5) at 60 spins")
			return true
		end
	end

	return false
end

-- NEW: Function to load premium spin counter and milestones
local function loadPremiumSpinCounterAndMilestones(player)
	local userId = player.UserId

	-- Load spin counter
	local success, savedCounter = pcall(function()
		return premiumSpinCounterDataStore:GetAsync(userId)
	end)

	if success and savedCounter ~= nil then
		playerPremiumSpinCounters[userId] = savedCounter
	else
		playerPremiumSpinCounters[userId] = 0
		pcall(function()
			premiumSpinCounterDataStore:SetAsync(userId, 0)
		end)
	end

	-- Load milestones
	local milestoneSuccess, savedMilestones = pcall(function()
		return premiumMilestoneDataStore:GetAsync(userId)
	end)

	if milestoneSuccess and savedMilestones ~= nil then
		playerPremiumMilestones[userId] = savedMilestones
	else
		playerPremiumMilestones[userId] = {}
		pcall(function()
			premiumMilestoneDataStore:SetAsync(userId, {})
		end)
	end

	-- Send initial counter to client
	PremiumUpdateSpinCounterEvent:FireClient(player, playerPremiumSpinCounters[userId])

	-- Set initial container based on total spins
	local totalSpins = playerPremiumSpinCounters[userId]
	local milestones = playerPremiumMilestones[userId] or {}

	if totalSpins < 30 or (totalSpins >= 30 and not milestones.scanner5) then
		PremiumUpdateProgressContainersEvent:FireClient(player, 1, "")
	elseif totalSpins < 60 or (totalSpins >= 60 and not milestones.magicCarpet) then
		PremiumUpdateProgressContainersEvent:FireClient(player, 2, "")
	else
		PremiumUpdateProgressContainersEvent:FireClient(player, 0, "")
	end

	-- Check if next spin is a milestone and notify client
	if totalSpins < 30 then
		if totalSpins == 29 then
			PremiumSpecial30thSpinEvent:FireClient(player)
		end
	elseif totalSpins < 60 then
		if totalSpins == 59 then
			PremiumSpecial30thSpinEvent:FireClient(player)
		end
	end

	print("🎩 Loaded for " .. player.Name .. 
		" | Premium Spins: " .. playerPremiumSpinCounters[userId] ..
		" | Scanner5: " .. tostring(playerPremiumMilestones[userId].scanner5 or false) ..
		" | Magic Carpet: " .. tostring(playerPremiumMilestones[userId].magicCarpet or false))
end

-- Handle PREMIUM GamePass purchase and give credits
local function handlePremiumGamePassPurchase(player, gamePassId)
	local userId = player.UserId

	local creditAmount = 0
	if gamePassId == PREMIUM_GAMEPASS_5_CREDITS then
		creditAmount = 5
		print("🎩 " .. player.Name .. " purchased PREMIUM 5-credits GamePass")
	elseif gamePassId == PREMIUM_GAMEPASS_20_CREDITS then
		creditAmount = 20
		print("🎩 " .. player.Name .. " purchased PREMIUM 20-credits GamePass")
	else
		warn("🎩 ❌ Unknown Premium GamePass ID: " .. gamePassId)
		return false
	end

	-- Give the PREMIUM credits
	if updatePlayerPremiumCredits(player, creditAmount) then
		game.StarterGui:SetCore("SendNotification", {
			Title = "🎩 Premium GamePass!",
			Text = "+" .. creditAmount .. " premium credits! Total: " .. playerPremiumCredits[userId],
			Duration = 5
		})

		print("🎩 ✅ Added " .. creditAmount .. " PREMIUM credits to " .. player.Name .. 
			" | Total: " .. playerPremiumCredits[userId])
		return true
	end

	return false
end

-- Listen for PREMIUM GamePass purchase events
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, purchasedGamePassId, wasPurchased)
	-- Check if it's a PREMIUM GamePass
	if purchasedGamePassId == PREMIUM_GAMEPASS_5_CREDITS or purchasedGamePassId == PREMIUM_GAMEPASS_20_CREDITS then
		if wasPurchased then
			handlePremiumGamePassPurchase(player, purchasedGamePassId)
		else
			print("🎩 ❌ " .. player.Name .. " cancelled PREMIUM GamePass purchase")
		end
	end
end)

-- Handle PREMIUM purchase requests from client
PremiumPurchaseGamePassEvent.OnServerEvent:Connect(function(player, gamePassType)
	local gamePassId = nil

	if gamePassType == "premium5credits" then
		gamePassId = PREMIUM_GAMEPASS_5_CREDITS
	elseif gamePassType == "premium20credits" then
		gamePassId = PREMIUM_GAMEPASS_20_CREDITS
	else
		warn("🎩 ❌ Invalid premium gamePassType: " .. tostring(gamePassType))
		return
	end

	MarketplaceService:PromptGamePassPurchase(player, gamePassId)
end)

-- Function to load PREMIUM credits from DataStore
local function loadPlayerPremiumCredits(player)
	local userId = player.UserId
	local success, savedCredits = pcall(function()
		return premiumCreditsDataStore:GetAsync(userId)
	end)

	if success then
		playerPremiumCredits[userId] = savedCredits or 0
	else
		playerPremiumCredits[userId] = 0
		pcall(function()
			premiumCreditsDataStore:SetAsync(userId, 0)
		end)
	end

	PremiumUpdateCreditsEvent:FireClient(player, playerPremiumCredits[userId])
end

-- Function to save PREMIUM data
local function savePlayerPremiumData(player)
	local userId = player.UserId
	if playerPremiumCredits[userId] then
		pcall(function()
			premiumCreditsDataStore:SetAsync(userId, playerPremiumCredits[userId])
		end)
	end
	if playerPremiumMilestones[userId] then
		pcall(function()
			premiumMilestoneDataStore:SetAsync(userId, playerPremiumMilestones[userId])
		end)
	end
end

-- Handle player joining
Players.PlayerAdded:Connect(function(player)
	print("🎩 Loading premium data for " .. player.Name)
	loadPlayerPremiumCredits(player)
	loadPremiumSpinCounterAndMilestones(player)
end)

-- Handle player leaving
Players.PlayerRemoving:Connect(function(player)
	print("🎩 Saving premium data for " .. player.Name)
	savePlayerPremiumData(player)
	playerPremiumCredits[player.UserId] = nil
	playerPremiumSpinCounters[player.UserId] = nil
	playerPremiumMilestones[player.UserId] = nil
end)

-- Handle get PREMIUM credits request
PremiumGetCreditsEvent.OnServerEvent:Connect(function(player)
	local credits = playerPremiumCredits[player.UserId] or 0
	PremiumUpdateCreditsEvent:FireClient(player, credits)
end)

-- Handle PREMIUM spin wheel prize
PremiumSpinWheelPrize.OnServerEvent:Connect(function(player, prize, prizeIndex, is30thSpinPrize)
	-- Validate prize
	local validPrizes = {"Bilzerian", 999999, "Scanner5", 100000, "Magic Carpet", 50000, "Shovel5", 250000}
	local isValid = false

	for _, validPrize in pairs(validPrizes) do
		if prize == validPrize then
			isValid = true
			break
		end
	end

	if not isValid then
		warn("🎩 " .. player.Name .. " tried to cheat with premium prize: " .. tostring(prize))
		return
	end

	-- Check if player has at least 1 premium credit to spin
	local userId = player.UserId
	if not playerPremiumCredits[userId] or playerPremiumCredits[userId] < 1 then
		warn("🎩 " .. player.Name .. " tried to spin premium wheel with no credits!")

		game.StarterGui:SetCore("SendNotification", {
			Title = "🎩 Premium Wheel",
			Text = "You need premium credits to spin!",
			Duration = 3
		})

		return
	end

	-- Deduct 1 premium credit for the spin
	updatePlayerPremiumCredits(player, -1)

	-- INCREMENT PREMIUM SPIN COUNTER
	local totalSpins = playerPremiumSpinCounters[userId] or 0
	playerPremiumSpinCounters[userId] = totalSpins + 1

	-- Save spin counter
	pcall(function()
		premiumSpinCounterDataStore:SetAsync(userId, playerPremiumSpinCounters[userId])
	end)

	-- Update client
	PremiumUpdateSpinCounterEvent:FireClient(player, playerPremiumSpinCounters[userId])

	-- Check for milestone prizes
	local gaveMilestone = checkAndUpdatePremiumMilestones(player)

	-- OVERRIDE PRIZE FOR 30TH SPIN
	local currentMilestones = playerPremiumMilestones[userId] or {}
	if is30thSpinPrize then
		if playerPremiumSpinCounters[userId] == 30 and not currentMilestones.scanner5 then
			prize = "Scanner5"
			prizeIndex = 3
		elseif playerPremiumSpinCounters[userId] == 60 and not currentMilestones.magicCarpet then
			prize = "Magic Carpet"
			prizeIndex = 5
		end
	end

	-- Give prize (unless it was a milestone prize already given above)
	if not gaveMilestone then
		if type(prize) == "number" then
			-- Give PREMIUM money
			local leaderstats = player:FindFirstChild("leaderstats")
			if leaderstats then
				local money = leaderstats:FindFirstChild("Money")
				if money then
					money.Value = money.Value + prize
					print("🎩 💰 " .. player.Name .. " won $" .. prize .. " from PREMIUM wheel")

					game.StarterGui:SetCore("SendNotification", {
						Title = "🎩 PREMIUM Wheel",
						Text = "You won $" .. prize .. "!",
						Duration = 5
					})
				end
			end
		elseif type(prize) == "string" then
			-- Give PREMIUM tool
			local success = givePremiumToolToPlayer(player, prize)
			if success then
				print("🎩 🎁 " .. player.Name .. " won premium tool: " .. prize)

				game.StarterGui:SetCore("SendNotification", {
					Title = "🎩 PREMIUM Wheel",
					Text = "You won " .. prize .. "!",
					Duration = 5
				})
			else
				-- If premium tool not found, give bonus money
				local leaderstats = player:FindFirstChild("leaderstats")
				if leaderstats then
					local money = leaderstats:FindFirstChild("Money")
					if money then
						money.Value = money.Value + 2000
						print("🎩 💰 " .. player.Name .. " got $2000 compensation for missing premium tool")
						game.StarterGui:SetCore("SendNotification", {
							Title = "🎩 PREMIUM Wheel",
							Text = prize .. " not found. Received $2000!",
							Duration = 5
						})
					end
				end
			end
		end
	end
end)

-- Load existing players
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(function()
		loadPlayerPremiumCredits(player)
		loadPremiumSpinCounterAndMilestones(player)
	end)
end

print("🎩 PREMIUM Spin wheel with spin counter system ready!")
print("   - Premium 5 Credits GamePass ID: " .. PREMIUM_GAMEPASS_5_CREDITS)
print("   - Premium 20 Credits GamePass ID: " .. PREMIUM_GAMEPASS_20_CREDITS)
print("   - Scanner5 at 30 spins, Magic Carpet at 60 spins")
