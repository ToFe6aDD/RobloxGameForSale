-- ChestManager.lua - 
-- Place in: ServerScriptService

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local DataStoreService = game:GetService("DataStoreService")

print("🎮 Starting Chest Manager with Fixed Dig Progress Indicator...")
-- ========== DATA STORE SETUP ==========
local CHEST_DATA_STORE_NAME = "ChestCountData"
local MONEY_DATA_STORE_NAME = "PlayerMoneyData"
local chestDataStore = DataStoreService:GetDataStore(CHEST_DATA_STORE_NAME)
local moneyDataStore = DataStoreService:GetDataStore(MONEY_DATA_STORE_NAME)
-- Error handling function
local function safeDataStoreCall(callback, playerName, action)
	local success, result = pcall(callback)
	if not success then
		print("❌ DataStore Error (" .. action .. ") for " .. playerName .. ": " .. tostring(result))
		return nil
	end
	return result
end

-- ========== MONEY SYSTEM FUNCTIONS WITH SAVING ==========
local function saveMoney(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local money = leaderstats:FindFirstChild("Money")
		if money then
			safeDataStoreCall(function()
				moneyDataStore:SetAsync(tostring(player.UserId), money.Value)
			end, player.Name, "saveMoney")
			print("💾 Saved money for " .. player.Name .. ": $" .. money.Value)
		end
	end
end

local function loadMoney(player)
	local data = safeDataStoreCall(function()
		return moneyDataStore:GetAsync(tostring(player.UserId))
	end, player.Name, "loadMoney")

	return data or 1000 -- Default starting money
end

local function giveMoney(player, amount)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local money = leaderstats:FindFirstChild("Money")
		if money then
			money.Value = money.Value + amount
			print("💰 Gave $" .. amount .. " to " .. player.Name .. ". Total: $" .. money.Value)

			-- Save money after giving
			saveMoney(player)
			return true
		else
			print("❌ Money value not found in leaderstats for " .. player.Name)
		end
	else
		print("❌ leaderstats folder not found for " .. player.Name)
	end
	return false
end

-- ========== CHEST COUNT FUNCTIONS WITH SAVING ==========
local function saveChestCount(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local chests = leaderstats:FindFirstChild("Chest")
		if chests then
			safeDataStoreCall(function()
				chestDataStore:SetAsync(tostring(player.UserId), chests.Value)
			end, player.Name, "saveChestCount")
			print("💾 Saved chest count for " .. player.Name .. ": " .. chests.Value)
		end
	end
end

local function loadChestCount(player)
	local data = safeDataStoreCall(function()
		return chestDataStore:GetAsync(tostring(player.UserId))
	end, player.Name, "loadChestCount")

	return data or 0 -- Default starting chest count
end

local function incrementChestCount(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
		print("✅ Created leaderstats folder for " .. player.Name)
	end

	local chests = leaderstats:FindFirstChild("Chest")
	if not chests then
		chests = Instance.new("IntValue")
		chests.Name = "Chest"
		chests.Value = loadChestCount(player) -- Load saved count
		chests.Parent = leaderstats
		print("✅ Created Chest value for " .. player.Name .. " with loaded count: " .. chests.Value)
	end

	chests.Value = chests.Value + 1
	print("📦 " .. player.Name .. " opened a chest! Total: " .. chests.Value)

	-- Save chest count after incrementing
	saveChestCount(player)

	return chests.Value
end


-- ========== PLAYER SETUP WITH DATA LOADING ==========
local function setupPlayer(player)
	task.wait(1)
	print("👤 Setting up player: " .. player.Name)

	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
		print("✅ Created leaderstats folder for " .. player.Name)
	end

	-- Load and setup money
	local savedMoney = loadMoney(player)
	local money = leaderstats:FindFirstChild("Money")
	if not money then
		money = Instance.new("IntValue")
		money.Name = "Money"
		money.Value = savedMoney
		money.Parent = leaderstats
		print("✅ Created Money value: $" .. money.Value .. " for " .. player.Name)
	else
		money.Value = savedMoney
		print("✅ Loaded Money value: $" .. money.Value .. " for " .. player.Name)
	end

	-- Load and setup chest count
	local savedChests = loadChestCount(player)
	local chests = leaderstats:FindFirstChild("Chest")
	if not chests then
		chests = Instance.new("IntValue")
		chests.Name = "Chest"
		chests.Value = savedChests
		chests.Parent = leaderstats
		print("✅ Created Chest value: " .. chests.Value .. " for " .. player.Name)
	else
		chests.Value = savedChests
		print("✅ Loaded Chest value: " .. chests.Value .. " for " .. player.Name)
	end

	-- Send notification about loaded data
	task.delay(2, function()
		if player and player.Parent then
			player:SendNotification("💰 Wallet Loaded", 
				"Money: $" .. money.Value .. " | Chests Opened: " .. chests.Value, 5)
		end
	end)
end


-- Setup existing players
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(function()
		setupPlayer(player)
	end)
end
-- Setup new players
Players.PlayerAdded:Connect(setupPlayer)
-- Save data when player leaves
Players.PlayerRemoving:Connect(function(player)
	print("👋 Saving data for leaving player: " .. player.Name)
	saveMoney(player)
	saveChestCount(player)
end)
-- Auto-save every 5 minutes
game:GetService("RunService").Heartbeat:Connect(function()
	-- Save all players' data every 5 minutes
	for _, player in ipairs(Players:GetPlayers()) do
		saveMoney(player)
		saveChestCount(player)
	end
end)

-- Add chest value to existing players
for _, player in ipairs(Players:GetPlayers()) do
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local chests = leaderstats:FindFirstChild("Chest")
		if not chests then
			chests = Instance.new("IntValue")
			chests.Name = "Chest"
			chests.Value = 0
			chests.Parent = leaderstats
			print("✅ Added Chest value to existing player: " .. player.Name)
		end
	end
end
-- ========== CHEST SYSTEM ==========
local CHEST_GROUPS = {
	[1] = {
		ChestValue = 2,
		TierWeights = {
			[1] = 80,
			[2] =50,
			[3] =5,
			[4] =0,
			[5] =0,
			[6] = 0,
			[7] = 0
		},
		Groups = {
			[1] = { 
				Vector3.new(-65.54, 16.59, -340.02),
				Vector3.new(-52.47, 16.59, -281.76),
				Vector3.new(56.55, 16.59, -248.66),
				Vector3.new(74.14, 16.59, -196.10),
				Vector3.new(134.97, 15.09, -210.11),
				Vector3.new(84.80, 16.59, -253.03),
				Vector3.new(4.82, 15.11, -271.83),
				Vector3.new(116.71, 16.59, -219.08),
				Vector3.new(-20.83, 16.59, -325.62),
				Vector3.new(166.42, 15.14, -223.53),
				Vector3.new(-27.83, 16.59, -318.74),
				Vector3.new(50.22, 16.59, -312.48),
				Vector3.new(13.55, 16.59, -322.14),
				Vector3.new(40.01, 15.09, -240.18),
				Vector3.new(67.97, 16.50, -235.21),
				Vector3.new(110.35, 15.14, -241.12),
				Vector3.new(151.48, 15.09, -212.32),
				Vector3.new(-41.84, 16.59, -335.01),
				Vector3.new(62.35, 15.25, -189.80),
				Vector3.new(108.54, 16.59, -274.92),
				Vector3.new(161.41, 15.09, -201.71),
				Vector3.new(165.19, 16.59, -253.18),
				Vector3.new(105.85, 16.59, -204.55),
				Vector3.new(82.85, 16.59, -293.20),
				Vector3.new(76.94, 16.59, -217.03),
				Vector3.new(133.91, 15.09, -223.94),
				Vector3.new(148.14, 16.59, -248.33),
				Vector3.new(65.77, 16.59, -271.87),
				Vector3.new(-42.68, 16.61, -356.35),
				Vector3.new(92.12, 16.59, -299.56),
				Vector3.new(6.73, 15.72, -380.11),
				Vector3.new(12.18, 16.59, -341.28),
				Vector3.new(44.36, 16.59, -260.12),
				Vector3.new(79.48, 16.59, -270.51),
				Vector3.new(104.54, 16.10, -229.35),
				Vector3.new(57.38, 15.39, -213.92),
				Vector3.new(2.56, 16.59, -297.90),
				Vector3.new(-20.15, 16.59, -364.33),
				Vector3.new(53.49, 16.59, -268.71),
				Vector3.new(5.63, 16.59, -317.04),
				Vector3.new(67.30, 16.59, -300.66),
				Vector3.new(106.66, 16.59, -217.53),
				Vector3.new(110.44, 16.43, -252.55),
				Vector3.new(91.75, 16.59, -195.47),
				Vector3.new(13.43, 16.59, -297.75),
				Vector3.new(15.91, 16.59, -305.55),
				Vector3.new(-35.16, 15.30, -280.13),
				Vector3.new(22.73, 16.26, -382.67),
				Vector3.new(19.62, 15.99, -364.86),
				Vector3.new(-97.13, 16.59, -322.74),
				Vector3.new(6.41, 16.07, -345.78),
				Vector3.new(-57.40, 16.59, -350.01),
				Vector3.new(34.45, 16.59, -331.77),
				Vector3.new(121.76, 15.18, -240.44),
				Vector3.new(-16.11, 16.54, -306.85),
				Vector3.new(65.00, 16.59, -205.81),
				Vector3.new(88.83, 16.59, -226.27),
				Vector3.new(107.40, 16.59, -289.91),
				Vector3.new(45.51, 15.09, -226.53),
				Vector3.new(80.90, 16.59, -188.92),
				Vector3.new(-67.01, 16.59, -292.67),
				Vector3.new(-79.12, 16.59, -316.74),
				Vector3.new(61.30, 16.17, -209.28),
				Vector3.new(143.21, 16.59, -264.02),
				Vector3.new(-85.21, 16.59, -303.77),
				Vector3.new(22.87, 16.59, -351.79),
				Vector3.new(93.85, 16.59, -273.44),
				Vector3.new(17.54, 16.59, -333.95),
				Vector3.new(51.85, 15.09, -234.61),
				Vector3.new(-53.21, 16.59, -327.75),
				Vector3.new(-38.15, 16.59, -326.13),
				Vector3.new(-82.04, 16.59, -341.35),
				Vector3.new(-12.71, 15.80, -348.99)

				
			}
		}
	},
	[2] = {
		ChestValue = 1,

		TierWeights = {
			[1] = 500,
			[2] = 400,
			[3] = 80,
			[4] = 0,
			[5] = 0,
			[6] = 0,
			[7] = 0
		},
		Groups = {
			[1] = { 
				Vector3.new(325.07, 19.08, -357.00),
				Vector3.new(264.68, 20.97, -220.95),
				Vector3.new(310.97, 15.10, -287.53),
				Vector3.new(340.26, 18.13, -334.74),
				Vector3.new(385.00, 15.09, -268.37),
				Vector3.new(228.84, 16.79, -231.56),
				Vector3.new(263.81, 15.68, -185.52),
				Vector3.new(363.15, 15.59, -352.60),
				Vector3.new(408.49, 14.89, -328.19),
				Vector3.new(390.24, 15.19, -346.66),
				Vector3.new(382.89, 15.48, -472.68),
				Vector3.new(371.18, 15.09, -258.34),
				Vector3.new(113.96, 16.59, -264.22),
				Vector3.new(293.13, 16.40, -255.91),
				Vector3.new(296.31, 15.85, -265.03),
				Vector3.new(293.44, 15.10, -229.62),
				Vector3.new(340.42, 15.09, -259.96),
				Vector3.new(368.44, 15.58, -406.34),
				Vector3.new(407.06, 15.09, -455.87),
				Vector3.new(393.11, 15.09, -428.55),
				Vector3.new(340.79, 15.59, -383.30),
				Vector3.new(333.44, 15.09, -210.98),
				Vector3.new(407.83, 14.90, -357.76),
				Vector3.new(319.29, 15.09, -205.78),
				Vector3.new(339.84, 15.09, -231.53),
				Vector3.new(272.87, 20.28, -255.55),
				Vector3.new(352.06, 15.27, -435.14),
				Vector3.new(247.35, 21.55, -228.47),
				Vector3.new(327.06, 15.73, -324.27),
				Vector3.new(423.95, 15.08, -393.18),
				Vector3.new(405.77, 15.09, -444.17),
				Vector3.new(407.29, 15.09, -390.51),
				Vector3.new(373.48, 15.59, -430.67),
				Vector3.new(430.13, 14.93, -408.68),
				Vector3.new(351.96, 15.09, -271.26),
				Vector3.new(324.04, 15.09, -230.60),
				Vector3.new(259.46, 20.88, -235.26),
				Vector3.new(359.58, 15.51, -443.40),
				Vector3.new(288.35, 15.32, -223.26),
				Vector3.new(399.24, 15.03, -343.32),
				Vector3.new(328.54, 15.71, -347.84),
				Vector3.new(405.73, 19.22, -485.50),
				Vector3.new(377.54, 18.69, -462.43),
				Vector3.new(337.60, 15.49, -315.40),
				Vector3.new(373.75, 15.66, -471.11),
				Vector3.new(366.52, 15.47, -339.09),
				Vector3.new(385.57, 15.49, -401.92),
				Vector3.new(416.53, 15.09, -434.17),
				Vector3.new(416.32, 15.09, -415.20),
				Vector3.new(244.42, 18.91, -246.97),
				Vector3.new(367.52, 15.59, -364.16),
				Vector3.new(371.04, 15.48, -442.19),
				Vector3.new(391.31, 15.00, -361.75),
				Vector3.new(397.29, 16.81, -478.97),
				Vector3.new(375.85, 15.59, -415.34),
				Vector3.new(373.30, 15.27, -380.06),
				Vector3.new(330.17, 15.09, -244.59),
				Vector3.new(376.98, 20.09, -333.40),
				Vector3.new(372.92, 15.59, -316.57),
				Vector3.new(85.54, 16.59, -253.59),
				Vector3.new(351.06, 15.50, -423.36),
				Vector3.new(185.15, 15.09, -191.71),
				Vector3.new(409.06, 15.08, -373.09),
				Vector3.new(244.70, 16.98, -183.82),
				Vector3.new(349.15, 15.42, -436.79),
				Vector3.new(369.52, 15.42, -469.47),
				Vector3.new(383.19, 15.51, -446.20),
				Vector3.new(387.23, 15.39, -308.17),
				Vector3.new(181.69, 15.09, -205.89),
				Vector3.new(199.28, 15.09, -198.87),
				Vector3.new(341.13, 15.41, -394.83),
				Vector3.new(373.02, 15.44, -394.05),
				Vector3.new(367.57, 15.09, -278.12),
				Vector3.new(370.91, 15.59, -297.45),
				Vector3.new(72.89, 16.59, -227.92),
				Vector3.new(313.57, 14.47, -278.40),
				Vector3.new(395.77, 15.78, -470.29),
				Vector3.new(139.03, 15.09, -216.49),
				Vector3.new(307.54, 15.09, -234.14),
				Vector3.new(360.83, 15.96, -418.51),
				Vector3.new(103.70, 16.59, -307.74),
				Vector3.new(134.75, 16.59, -273.03),
				Vector3.new(282.18, 15.09, -193.49),
				Vector3.new(350.35, 15.09, -248.47),
				Vector3.new(385.34, 15.09, -286.33),
				Vector3.new(300.52, 15.09, -203.83),
				Vector3.new(200.23, 25.71, -253.65),
				Vector3.new(339.20, 16.84, -361.83),
				Vector3.new(327.81, 16.04, -294.01),
				Vector3.new(54.10, 16.59, -300.12),
				Vector3.new(4.50, 16.59, -406.39),
				Vector3.new(215.60, 15.90, -207.92),
				Vector3.new(314.85, 19.78, -304.82),
				Vector3.new(27.83, 16.59, -310.29),
				Vector3.new(236.10, 16.80, -264.67),
				Vector3.new(254.41, 20.24, -262.29),
				Vector3.new(307.90, 19.50, -433.09),
				Vector3.new(133.75, 16.59, -273.03),
				Vector3.new(314.94, 15.07, -420.44),
				Vector3.new(321.23, 14.74, -443.65),
				Vector3.new(53.06, 16.59, -308.61),
				Vector3.new(331.00, 16.66, -375.49),
				Vector3.new(226.32, 17.19, -196.18),
				Vector3.new(409.31, 14.84, -472.11),
				Vector3.new(393.75, 15.08, -412.45),
				Vector3.new(41.97, 16.46, -259.94),
				Vector3.new(227.75, 16.10, -245.50),
				Vector3.new(24.76, 16.59, -349.05),
				Vector3.new(276.48, 17.59, -227.14),
				Vector3.new(-21.65, 16.59, -318.17),
				Vector3.new(-4.98, 15.83, -343.14),
				Vector3.new(16.40, 15.68, -374.41),
				Vector3.new(-49.17, 16.59, -293.44),
				Vector3.new(-68.78, 16.59, -303.10)

			},
			
		}
	},
	[3] = {
		ChestValue = 1,

		TierWeights = {
			[1] = 120,
			[2] = 120,
			[3] = 35,
			[4] = 20,
			[5] = 3,
			[6] = 1,
			[7] = 0
		},
		Groups = {
			[1] = { 
				Vector3.new(404.51, 44.51, -653.82),
				Vector3.new(395.45, 46.27, -685.11),
				Vector3.new(458.38, 49.13, -627.27),
				Vector3.new(363.46, 39.97, -682.10),
				Vector3.new(341.89, 40.59, -709.02),
				Vector3.new(143.55, 15.09, -730.35),
				Vector3.new(337.32, 41.21, -686.65),
				Vector3.new(382.33, 44.99, -687.61),
				Vector3.new(445.37, 41.01, -511.49),
				Vector3.new(465.61, 68.60, -677.15),
				Vector3.new(448.02, 59.44, -667.73),
				Vector3.new(404.92, 46.43, -690.01),
				Vector3.new(450.21, 45.02, -613.78),
				Vector3.new(337.55, 41.00, -696.74),
				Vector3.new(373.42, 42.92, -707.16),
				Vector3.new(314.50, 40.44, -691.48),
				Vector3.new(469.86, 40.89, -570.23),
				Vector3.new(255.83, 40.59, -705.64),
				Vector3.new(462.20, 40.90, -527.26),
				Vector3.new(414.10, 44.58, -695.57),
				Vector3.new(317.63, 40.40, -716.65),
				Vector3.new(240.64, 40.59, -703.30),
				Vector3.new(43.46, 15.09, -684.50),
				Vector3.new(155.13, 15.22, -726.67),
				Vector3.new(418.78, 49.96, -655.89),
				Vector3.new(70.04, 15.08, -711.90),
				Vector3.new(455.13, 62.65, -669.95),
				Vector3.new(130.25, 15.09, -735.24),
				Vector3.new(455.35, 47.03, -598.06),
				Vector3.new(404.51, 44.51, -653.82),
				Vector3.new(340.79, 15.59, -383.30),
				Vector3.new(336.24, 41.18, -682.61),
				Vector3.new(385.65, 45.87, -697.78),
				Vector3.new(472.61, 41.00, -542.79),
				Vector3.new(50.97, 15.09, -698.20),
				Vector3.new(476.81, 42.20, -581.56),
				Vector3.new(348.45, 40.67, -683.69),
				Vector3.new(463.83, 45.59, -589.07),
				Vector3.new(418.83, 48.49, -686.06),
				Vector3.new(185.65, 29.17, -695.17),
				Vector3.new(374.18, 15.09, -724.48),
				Vector3.new(438.92, 40.61, -621.54),
				Vector3.new(364.94, 42.37, -702.77),
				Vector3.new(215.55, 38.40, -708.28),
				Vector3.new(151.52, 15.67, -690.51),
				Vector3.new(327.81, 16.04, -294.01),
				Vector3.new(379.31, 41.48, -676.75),
				Vector3.new(165.61, 17.54, -700.50),
				Vector3.new(415.26, 49.47, -673.84),
				Vector3.new(441.72, 42.72, -611.22),
				Vector3.new(74.18, 15.09, -724.48),
				Vector3.new(371.07, 39.39, -679.15),
				Vector3.new(85.01, 15.09, -730.09),
				Vector3.new(314.85, 19.78, -304.82),
				Vector3.new(135.39, 15.09, -721.97),
				Vector3.new(117.93, 15.05, -731.93),
				Vector3.new(478.71, 50.46, -633.16),
				Vector3.new(225.85, 40.85, -713.61),
				Vector3.new(354.35, 41.12, -697.29),
				Vector3.new(328.80, 41.31, -692.21),
				Vector3.new(106.00, 15.09, -727.14),
				Vector3.new(193.61, 32.86, -704.82),
				Vector3.new(462.32, 66.44, -667.56),
				Vector3.new(165.36, 18.16, -690.90),
				Vector3.new(322.59, 40.58, -699.03),
				Vector3.new(92.97, 15.09, -717.82),
				Vector3.new(479.01, 52.45, -617.11),
				Vector3.new(238.79, 40.59, -718.64),
				Vector3.new(457.98, 37.98, -508.22),
				Vector3.new(57.43, 15.09, -705.63),
				Vector3.new(124.01, 15.09, -721.27),
				Vector3.new(307.77, 40.29, -698.59),
				Vector3.new(397.32, 43.43, -659.40),
				Vector3.new(331.95, 40.42, -703.87),
				Vector3.new(411.07, 44.15, -646.99),
				Vector3.new(294.94, 40.08, -701.28),
				Vector3.new(293.81, 40.59, -718.97),
				Vector3.new(349.63, 40.94, -702.99),
				Vector3.new(440.72, 42.72, -611.22),
				Vector3.new(428.62, 50.18, -661.16),
				Vector3.new(468.10, 49.71, -605.99),
				Vector3.new(59.74, 15.09, -714.29),
				Vector3.new(437.39, 51.95, -665.86),
				Vector3.new(227.93, 42.28, -700.97),
				Vector3.new(304.13, 40.59, -709.67),
				Vector3.new(204.47, 35.71, -695.43),
				Vector3.new(257.06, 40.59, -728.63),
				Vector3.new(148.09, 14.90, -702.03),
				Vector3.new(112.74, 15.37, -714.14),
				Vector3.new(465.79, 49.15, -634.54),
				Vector3.new(274.33, 40.59, -708.89),
				Vector3.new(226.54, 42.02, -700.78),
				Vector3.new(443.91, 46.34, -634.29),
				Vector3.new(309.54, 40.59, -724.88),
				Vector3.new(331.00, 16.66, -375.49),
				Vector3.new(442.71, 47.90, -646.09),
				Vector3.new(235.88, 40.63, -709.49),
				Vector3.new(37.87, 15.01, -689.95)
			}
		}
	},
	[4] = {
		ChestValue = 2,
		TierWeights = {
			[1] =190,
			[2] =190,
			[3] =120,
			[4] =70,
			[5] =5,
			[6] = 2,
			[7] = 1
		},
		Groups = {
			[1] = { 
				Vector3.new(347.58, 96.04, -582.19),
				Vector3.new(25.55, 62.99, -515.70),
				Vector3.new(276.58, 90.41, -619.85),
				Vector3.new(204.13, 139.93, -531.27),
				Vector3.new(22.40, 60.77, -478.50),
				Vector3.new(384.85, 76.92, -539.26),
				Vector3.new(335.48, 102.47, -562.23),
				Vector3.new(41.66, 69.08, -513.57),
				Vector3.new(276.21, 112.49, -576.76),
				Vector3.new(21.82, 60.55, -513.86),
				Vector3.new(376.61, 76.82, -526.34),
				Vector3.new(300.34, 100.44, -530.22),
				Vector3.new(117.04, 49.01, -672.00),
				Vector3.new(280.57, 109.23, -587.29),
				Vector3.new(312.04, 76.99, -650.90),
				Vector3.new(335.23, 76.18, -609.97),
				Vector3.new(262.16, 120.58, -544.10),
				Vector3.new(342.68, 76.62, -509.36),
				Vector3.new(195.58, 140.38, -522.18),
				Vector3.new(16.39, 53.16, -508.78),
				Vector3.new(420.14, 49.47, -607.17),
				Vector3.new(168.96, 143.30, -531.72),
				Vector3.new(70.24, 48.59, -661.49),
				Vector3.new(284.96, 95.95, -606.91),
				Vector3.new(72.19, 45.34, -678.30),
				Vector3.new(278.94, 90.42, -504.56),
				Vector3.new(329.58, 74.32, -623.39),
				Vector3.new(106.08, 48.61, -672.50),
				Vector3.new(16.64, 55.78, -529.87),
				Vector3.new(327.48, 98.03, -594.78),
				Vector3.new(307.48, 98.03, -594.78),
				Vector3.new(112.89, 49.67, -672.50),
				Vector3.new(420.86, 55.31, -592.44),
				Vector3.new(25.20, 53.58, -551.67),
				Vector3.new(303.82, 78.74, -624.95),
				Vector3.new(329.11, 76.71, -512.06),
				Vector3.new(120.61, 133.02, -550.08),
				Vector3.new(228.07, 131.61, -546.80),
				Vector3.new(303.86, 93.46, -604.26),
				Vector3.new(70.95, 47.92, -670.55),
				Vector3.new(85.73, 48.53, -671.58),
				Vector3.new(280.78, 76.82, -672.16),
				Vector3.new(420.84, 76.54, -536.15),
				Vector3.new(292.16, 90.04, -507.14),
				Vector3.new(259.47, 86.54, -497.06),
				Vector3.new(275.77, 103.80, -600.78),
				Vector3.new(347.88, 72.10, -537.08),
				Vector3.new(26.09, 48.24, -567.02),
				Vector3.new(85.18, 48.17, -684.00),
				Vector3.new(353.67, 97.19, -572.09),
				Vector3.new(425.88, 75.77, -552.52),
				Vector3.new(262.74, 120.59, -557.47),
				Vector3.new(405.14, 76.78, -545.28),
				Vector3.new(275.49, 116.20, -563.55),
				Vector3.new(85.18, 48.17, -684.00),
				Vector3.new(415.23, 72.81, -558.74),
				Vector3.new(219.64, 132.17, -529.47),
				Vector3.new(23.78, 60.90, -533.99),
				Vector3.new(422.88, 75.77, -552.52),
				Vector3.new(405.29, 61.90, -590.76),
				Vector3.new(4.93, 54.09, -464.28),
				Vector3.new(260.22, 74.57, -680.28),
				Vector3.new(423.25, 76.71, -571.55),
				Vector3.new(325.68, 78.82, -623.39),
				Vector3.new(370.08, 76.96, -562.25),
				Vector3.new(230.23, 129.49, -535.22),
				Vector3.new(250.23, 129.49, -535.22),
				Vector3.new(322.93, 106.04, -554.45),
				Vector3.new(19.68, 50.43, -548.47),
				Vector3.new(-38.05, 27.91, -451.00),
				Vector3.new(23.78, 60.90, -533.99),
				Vector3.new(347.16, 76.86, -524.16),
				Vector3.new(337.53, 100.31, -578.99),
				Vector3.new(-29.94, 36.32, -445.88),
				Vector3.new(275.77, 103.80, -600.78),
				Vector3.new(297.03, 97.50, -521.25),
				Vector3.new(127.03, 49.14, -661.87),
				Vector3.new(336.60, 15.49, -315.40),
				Vector3.new(278.52, 98.85, -603.35),
				Vector3.new(95.59, 47.97, -662.70),
				Vector3.new(79.64, 48.39, -657.65),
				Vector3.new(233.49, 131.96, -530.71),
				Vector3.new(242.37, 131.44, -542.86),
				Vector3.new(16.39, 53.16, -508.78),
				Vector3.new(307.67, 91.08, -603.56),
				Vector3.new(282.18, 15.09, -193.49),
				Vector3.new(410.49, 73.14, -573.31),
				Vector3.new(29.39, 44.47, -608.10),
				Vector3.new(276.11, 76.42, -678.43),
				Vector3.new(0.42, 15.09, -609.14),
				Vector3.new(-0.42, 15.09, -609.14),
				Vector3.new(-4.02, 15.09, -576.25),
				Vector3.new(3.03, 53.60, -476.66),
				Vector3.new(-15.40, 15.09, -590.23),
				Vector3.new(27.99, 44.13, -590.65),
				Vector3.new(79.48, 16.59, -270.51),
				Vector3.new(266.26, 77.03, -670.66),
				Vector3.new(-30.26, 25.48, -472.07),
				Vector3.new(-17.64, 42.77, -452.06),
				Vector3.new(440.39, 76.42, -559.11),
				Vector3.new(312.00, 106.22, -545.24),
				Vector3.new(178.65, 142.51, -515.93),
				Vector3.new(-6.96, 48.26, -454.97),
				Vector3.new(12.89, 57.55, -469.50),
				Vector3.new(165.40, 141.70, -523.12),
				Vector3.new(129.91, 136.01, -540.21),
				Vector3.new(25.12, 57.80, -508.18),
				Vector3.new(321.68, 75.12, -633.25),
				Vector3.new(390.08, 76.96, -562.25),
				Vector3.new(334.35, 71.98, -497.15),
				Vector3.new(320.31, 99.89, -587.73),
				Vector3.new(437.34, 76.63, -572.84),
				Vector3.new(296.60, 93.64, -609.98),
				Vector3.new(12.89, 57.55, -469.50),
				Vector3.new(-6.88, 15.09, -598.87),
				Vector3.new(-40.67, 19.78, -467.59),
				Vector3.new(267.33, 90.15, -618.89),
				Vector3.new(385.00, 15.09, -268.37),
				Vector3.new(438.21, 76.32, -548.43),
				Vector3.new(301.10, 76.84, -661.00),
				Vector3.new(377.80, 76.59, -555.39),
				Vector3.new(24.76, 16.59, -349.05),
				Vector3.new(302.12, 85.29, -504.67),
				Vector3.new(319.75, 76.88, -617.72),
				Vector3.new(-25.89, 54.96, -525.15),
				Vector3.new(-24.26, 52.37, -518.91),
				Vector3.new(-7.80, 15.09, -608.65)
			


			}
		}
	},
	[5] = {
		ChestValue = 2,
		TierWeights = {
			[1] = 190,
			[2] =190,
			[3] =50,
			[4] =10,
			[5] =2,
			[6] = 1,
			[7] = 0
		},
		Groups = {
			[1] = { 
				Vector3.new(708.86, 15.09, 668.16),
				Vector3.new(644.73, 22.20, 470.05),
				Vector3.new(687.05, 16.72, 261.33),
				Vector3.new(672.58, 15.68, 252.13),
				Vector3.new(619.23, 21.50, 348.50),
				Vector3.new(692.29, 19.06, 275.73),
				Vector3.new(705.73, 16.16, 535.06),
				Vector3.new(637.48, 17.18, 496.63),
				Vector3.new(660.71, 19.07, 457.33),
				Vector3.new(592.38, 15.09, 650.93),
				Vector3.new(611.13, 15.09, 773.80),
				Vector3.new(579.74, 15.09, 726.65),
				Vector3.new(651.16, 26.64, 295.70),
				Vector3.new(684.64, 22.69, 425.14),
				Vector3.new(653.36, 18.20, 402.31),
				Vector3.new(625.86, 15.09, 695.95),
				Vector3.new(675.65, 24.43, 493.91),
				Vector3.new(652.26, 29.02, 491.65),
				Vector3.new(695.75, 20.98, 437.61),
				Vector3.new(634.00, 18.16, 260.17),
				Vector3.new(618.29, 15.09, 781.46),
				Vector3.new(645.84, 15.09, 719.22),
				Vector3.new(688.93, 17.59, 559.66),
				Vector3.new(645.68, 17.30, 556.25),
				Vector3.new(613.10, 15.09, 680.22),
				Vector3.new(658.50, 20.75, 534.99),
				Vector3.new(689.97, 15.09, 623.91),
				Vector3.new(700.52, 21.89, 397.62),
				Vector3.new(635.49, 15.09, 575.35),
				Vector3.new(687.04, 24.21, 396.73),
				Vector3.new(640.59, 26.92, 338.72),
				Vector3.new(698.46, 21.21, 369.39),
				Vector3.new(604.51, 17.39, 285.65),
				Vector3.new(654.95, 21.18, 274.31),
				Vector3.new(656.42, 27.83, 505.63),
				Vector3.new(711.93, 16.75, 453.29),
				Vector3.new(640.05, 15.09, 632.52),
				Vector3.new(618.96, 19.68, 293.16),
				Vector3.new(605.54, 15.09, 754.41),
				Vector3.new(666.54, 27.63, 336.23),
				Vector3.new(654.32, 22.86, 520.47),
				Vector3.new(679.23, 24.70, 378.42),
				Vector3.new(692.42, 15.43, 590.50),
				Vector3.new(638.75, 19.74, 524.04),
				Vector3.new(698.26, 21.61, 304.85),
				Vector3.new(673.23, 28.10, 297.44),
				Vector3.new(678.55, 23.71, 397.07),
				Vector3.new(682.09, 20.80, 466.47),
				Vector3.new(629.54, 20.99, 480.33),
				Vector3.new(701.94, 15.09, 685.71),
				Vector3.new(652.47, 16.61, 253.89),
				Vector3.new(698.28, 17.33, 519.79),
				Vector3.new(652.89, 17.29, 412.97),
				Vector3.new(625.02, 15.09, 807.18),
				Vector3.new(610.77, 15.09, 751.37),
				Vector3.new(623.10, 18.95, 375.39),
				Vector3.new(647.89, 15.12, 583.88),
				Vector3.new(666.17, 19.50, 557.86),
				Vector3.new(572.57, 14.75, 695.70),
				Vector3.new(694.53, 17.30, 542.62),
				Vector3.new(660.36, 15.09, 628.01),
				Vector3.new(630.68, 17.53, 459.90),
				Vector3.new(676.12, 20.64, 520.17),
				Vector3.new(674.80, 21.39, 425.01),
				Vector3.new(682.20, 16.70, 580.64),
				Vector3.new(706.21, 16.93, 502.99),
				Vector3.new(704.80, 17.14, 482.98),
				Vector3.new(720.31, 17.19, 391.67),
				Vector3.new(604.34, 18.38, 363.85),
				Vector3.new(636.57, 21.64, 367.44),
				Vector3.new(692.46, 18.89, 491.54),
				Vector3.new(679.70, 15.09, 626.15),
				Vector3.new(713.93, 15.64, 509.82),
				Vector3.new(682.55, 15.49, 592.91),
				Vector3.new(610.87, 17.74, 267.10),
				Vector3.new(669.30, 19.71, 435.53),
				Vector3.new(660.47, 15.09, 703.00),
				Vector3.new(672.30, 25.11, 367.33),
				Vector3.new(652.17, 23.52, 365.74),
				Vector3.new(672.23, 23.68, 478.51),
				Vector3.new(715.35, 17.98, 373.60),
				Vector3.new(643.41, 15.09, 707.12),
				Vector3.new(679.20, 20.26, 536.63),
				Vector3.new(713.91, 17.49, 434.25),
				Vector3.new(656.01, 26.14, 478.84),
				Vector3.new(681.63, 15.09, 692.35),
				Vector3.new(619.59, 15.08, 759.29),
				Vector3.new(650.59, 16.87, 441.79),
				Vector3.new(687.97, 23.80, 334.71),
				Vector3.new(650.61, 16.67, 441.79),
				Vector3.new(623.46, 17.17, 469.42),
				Vector3.new(707.49, 19.09, 323.32),
				Vector3.new(714.47, 15.99, 464.13),
				Vector3.new(657.23, 15.09, 668.83),
				Vector3.new(603.38, 15.09, 668.38),
				Vector3.new(682.06, 15.09, 656.64),
				Vector3.new(701.97, 20.85, 427.15),
				Vector3.new(679.24, 15.09, 592.61),
				Vector3.new(590.81, 15.09, 736.75),
				Vector3.new(616.09, 15.09, 761.17),
				Vector3.new(597.92, 15.09, 719.26),
				Vector3.new(600.24, 15.09, 703.15),
				Vector3.new(586.87, 15.09, 692.06),
				Vector3.new(594.64, 15.09, 741.96),
				Vector3.new(567.03, 15.09, 715.45),
				Vector3.new(600.10, 15.09, 773.89),
				Vector3.new(584.16, 15.09, 772.23),
				Vector3.new(574.97, 15.09, 766.22),
				Vector3.new(564.99, 15.09, 771.99),
				Vector3.new(571.78, 15.09, 784.46),
				Vector3.new(557.82, 15.09, 794.35),
				Vector3.new(556.35, 15.09, 781.10),
				Vector3.new(557.92, 15.09, 763.52),
				Vector3.new(542.48, 15.09, 776.70),
				Vector3.new(538.41, 15.09, 790.42),
				Vector3.new(547.84, 15.09, 800.22),
				Vector3.new(563.25, 15.09, 811.22),
				Vector3.new(574.75, 15.09, 819.43),
				Vector3.new(589.75, 15.09, 827.82),
				Vector3.new(607.60, 15.09, 827.19),
				Vector3.new(622.98, 15.09, 823.91),
				Vector3.new(602.75, 15.09, 776.49),
				Vector3.new(590.36, 15.09, 793.86),
				Vector3.new(595.43, 15.09, 808.96),
				Vector3.new(564.64, 15.09, 811.49),
				Vector3.new(530.90, 15.09, 798.83),
				Vector3.new(517.19, 15.09, 799.42),
				Vector3.new(506.63, 15.09, 806.84),
				Vector3.new(491.01, 15.09, 806.61),
				Vector3.new(477.75, 15.09, 809.46),
				Vector3.new(459.20, 15.09, 810.54),
				Vector3.new(464.40, 15.09, 820.09),
				Vector3.new(473.66, 15.09, 820.51),
				Vector3.new(484.37, 15.09, 822.29),
				Vector3.new(493.41, 15.09, 826.96),
				Vector3.new(505.69, 15.09, 825.23),
				Vector3.new(516.54, 15.09, 824.23),
				Vector3.new(502.55, 15.09, 818.74),
				Vector3.new(509.00, 15.09, 835.55),
				Vector3.new(512.47, 15.09, 856.00),
				Vector3.new(517.48, 15.09, 868.33),
				Vector3.new(538.83, 15.09, 865.02),
				Vector3.new(507.47, 15.09, 872.34),
				Vector3.new(492.16, 15.09, 878.53),
				Vector3.new(474.81, 15.09, 881.43),
				Vector3.new(449.88, 15.09, 895.92),
				Vector3.new(436.56, 15.09, 892.28),
				Vector3.new(438.40, 15.09, 882.24),
				Vector3.new(442.40, 15.09, 869.26),
				Vector3.new(444.29, 15.09, 849.72),
				Vector3.new(440.46, 15.09, 826.83),
				Vector3.new(445.02, 15.09, 813.17),
				Vector3.new(471.81, 15.09, 848.43),
				Vector3.new(433.69, 15.09, 859.86),
				Vector3.new(426.38, 14.72, 853.86),
				Vector3.new(416.45, 16.40, 852.81),
				Vector3.new(407.61, 15.75, 847.49),
				Vector3.new(411.91, 15.09, 836.12),
				Vector3.new(422.99, 15.09, 837.02),
				Vector3.new(432.69, 15.09, 835.13),
				Vector3.new(438.26, 15.09, 827.32),
				Vector3.new(440.74, 15.09, 815.50),
				Vector3.new(428.84, 15.09, 815.45),
				Vector3.new(416.46, 15.09, 821.67),
				Vector3.new(405.35, 15.09, 826.21),
				Vector3.new(392.75, 15.09, 831.62),
				Vector3.new(385.14, 15.09, 837.10),
				Vector3.new(378.25, 15.09, 852.73),
				Vector3.new(380.58, 15.02, 866.68),
				Vector3.new(383.57, 14.83, 884.56),
				Vector3.new(392.81, 13.94, 886.91),
				Vector3.new(405.19, 15.09, 887.75),
				Vector3.new(414.81, 15.09, 894.01),
				Vector3.new(411.26, 15.09, 905.35),
				Vector3.new(394.41, 15.09, 906.07),
				Vector3.new(382.03, 15.09, 901.64),
				Vector3.new(371.78, 15.09, 903.35),
				Vector3.new(363.40, 15.09, 914.12),
				Vector3.new(354.90, 15.09, 911.43),
				Vector3.new(345.38, 15.09, 918.52),
				Vector3.new(336.56, 15.09, 916.28),
				Vector3.new(339.08, 15.09, 905.72),
				Vector3.new(344.81, 15.09, 889.34),
				Vector3.new(348.43, 15.09, 879.30),
				Vector3.new(359.27, 15.09, 864.11),
				Vector3.new(379.29, 15.09, 851.39),
				Vector3.new(369.29, 15.09, 842.10),
				Vector3.new(362.25, 15.09, 831.83),
				Vector3.new(352.46, 15.09, 827.02),
				Vector3.new(340.50, 15.09, 837.86),
				Vector3.new(331.59, 15.09, 850.34),
				Vector3.new(330.23, 15.09, 862.54),
				Vector3.new(330.68, 15.09, 884.90),
				Vector3.new(329.84, 15.09, 897.35),
				Vector3.new(327.13, 15.09, 910.50),
				Vector3.new(319.47, 15.09, 919.87),
				Vector3.new(305.98, 15.09, 918.07),
				Vector3.new(296.61, 15.09, 921.15),
				Vector3.new(283.44, 15.09, 926.56),
				Vector3.new(272.64, 15.09, 919.78),
				Vector3.new(258.17, 15.09, 924.28),
				Vector3.new(246.18, 15.09, 923.08),
				Vector3.new(235.41, 15.09, 911.23),
				Vector3.new(233.67, 15.09, 901.71),
				Vector3.new(229.25, 15.08, 887.30),
				Vector3.new(220.77, 15.09, 893.25),
				Vector3.new(212.59, 15.09, 897.98),
				Vector3.new(204.45, 15.09, 892.18),
				Vector3.new(199.47, 15.09, 882.36),
				Vector3.new(186.47, 15.09, 882.24),
				Vector3.new(184.51, 15.09, 873.15),
				Vector3.new(187.14, 15.08, 865.07),
				Vector3.new(175.34, 15.09, 864.54),
				Vector3.new(166.51, 15.09, 870.86),
				Vector3.new(157.60, 15.09, 867.81),
				Vector3.new(152.72, 15.09, 856.32),
				Vector3.new(151.58, 15.09, 848.01),
				Vector3.new(157.62, 15.09, 839.55),
				Vector3.new(152.46, 15.09, 837.25),
				Vector3.new(146.17, 15.09, 842.07),
				Vector3.new(140.13, 15.09, 850.53),
				Vector3.new(133.29, 15.09, 848.16),
				Vector3.new(130.27, 15.09, 840.75),
				Vector3.new(128.18, 15.09, 834.21),
				Vector3.new(120.80, 15.09, 831.63),
				Vector3.new(133.77, 15.09, 827.00),
				Vector3.new(144.55, 15.09, 825.20),
				Vector3.new(154.47, 15.09, 823.41),
				Vector3.new(161.54, 15.09, 817.06),
				Vector3.new(164.92, 15.09, 809.50),
				Vector3.new(164.67, 15.09, 802.61),
				Vector3.new(171.59, 15.09, 798.34),
				Vector3.new(179.96, 15.09, 798.22),
				Vector3.new(183.10, 15.09, 804.10),
				Vector3.new(178.75, 15.09, 813.21),
				Vector3.new(173.80, 15.09, 820.16),
				Vector3.new(171.35, 15.09, 827.89),
				Vector3.new(177.86, 15.09, 832.54),
				Vector3.new(185.37, 15.09, 832.87),
				Vector3.new(194.57, 15.09, 831.33),
				Vector3.new(202.91, 15.41, 833.47),
				Vector3.new(210.70, 15.58, 832.16),
				Vector3.new(218.73, 14.74, 827.44),
				Vector3.new(215.55, 14.76, 821.49),
				Vector3.new(206.81, 14.97, 822.13),
				Vector3.new(201.78, 15.09, 816.36),
				Vector3.new(207.90, 15.09, 806.40),
				Vector3.new(214.47, 15.09, 800.65),
				Vector3.new(221.72, 15.09, 796.44),
				Vector3.new(227.97, 15.09, 790.18),
				Vector3.new(235.85, 15.09, 791.10),
				Vector3.new(243.43, 15.09, 793.33),
				Vector3.new(253.16, 15.09, 791.70),
				Vector3.new(256.42, 15.05, 798.06),
				Vector3.new(258.83, 14.79, 811.65),
				Vector3.new(267.94, 14.80, 814.91),
				Vector3.new(278.77, 15.03, 808.62),
				Vector3.new(301.95, 15.09, 811.84),
				Vector3.new(300.47, 15.02, 824.90),
				Vector3.new(298.83, 14.99, 837.16),
				Vector3.new(300.46, 15.02, 846.90),
				Vector3.new(291.47, 14.96, 851.88),
				Vector3.new(282.00, 14.96, 853.47),
				Vector3.new(260.37, 14.12, 860.08),
				Vector3.new(252.67, 15.07, 866.74),
				Vector3.new(240.54, 14.01, 865.91),
				Vector3.new(238.29, 14.20, 862.13),
				Vector3.new(242.14, 14.87, 850.66),
				Vector3.new(240.47, 14.91, 840.66),
				Vector3.new(238.71, 15.01, 830.14),
				Vector3.new(237.39, 14.89, 822.25),
				Vector3.new(235.98, 14.90, 813.84),
				Vector3.new(234.62, 14.90, 805.68),
				Vector3.new(241.86, 15.03, 803.95),
				Vector3.new(251.79, 14.85, 819.53),
				Vector3.new(215.95, 14.83, 833.10),
				Vector3.new(189.81, 15.09, 835.23),
				Vector3.new(183.73, 15.09, 830.90),
				Vector3.new(174.33, 15.09, 831.07),
				Vector3.new(162.84, 15.09, 823.87),
				Vector3.new(157.22, 15.09, 823.04),
				Vector3.new(141.05, 15.09, 831.10),
				Vector3.new(255.68, 15.09, 876.39),
				Vector3.new(265.12, 15.09, 877.04),
				Vector3.new(289.24, 15.09, 880.64),
				Vector3.new(314.90, 15.09, 890.01),
				Vector3.new(327.23, 15.09, 897.72),
				Vector3.new(342.15, 15.09, 862.47),
				Vector3.new(346.26, 15.09, 851.12),
				Vector3.new(352.76, 15.09, 843.69),
				Vector3.new(372.86, 15.09, 830.98),



			}
		}
	},
	[6] = {
		ChestValue = 1,
		TierWeights = {
			[1] = 90,
			[2] =190,
			[3] =60,
			[4] =10,
			[5] =3,
			[6] = 1,
			[7] = 0
		},
		Groups = {
			[1] = { 
				Vector3.new(140.22, 38.82, 812.63),
				Vector3.new(131.05, 39.14, 807.13),
				Vector3.new(116.91, 39.25, 803.66),
				Vector3.new(107.29, 39.37, 798.72),
				Vector3.new(117.62, 39.14, 789.67),
				Vector3.new(128.75, 39.14, 790.95),
				Vector3.new(136.89, 39.14, 786.25),
				Vector3.new(142.39, 39.14, 777.19),
				Vector3.new(147.87, 39.13, 769.67),
				Vector3.new(145.70, 39.14, 757.90),
				Vector3.new(145.98, 39.14, 743.47),
				Vector3.new(139.44, 39.28, 743.33),
				Vector3.new(140.52, 39.14, 729.25),
				Vector3.new(139.45, 39.14, 716.88),
				Vector3.new(136.92, 39.80, 698.61),
				Vector3.new(79.29, 40.24, 774.38),
				Vector3.new(81.16, 40.08, 782.43),
				Vector3.new(87.92, 40.18, 788.21),
				Vector3.new(92.27, 39.66, 784.63),
				Vector3.new(101.82, 39.23, 783.40),
				Vector3.new(105.68, 39.20, 792.64),
				Vector3.new(108.50, 39.78, 802.59),
				Vector3.new(117.46, 39.17, 800.79),
				Vector3.new(118.88, 39.14, 789.58),
				Vector3.new(127.23, 39.14, 788.83),
				Vector3.new(134.38, 39.14, 785.29),
				Vector3.new(137.46, 39.14, 793.27),
				Vector3.new(137.96, 39.10, 801.66),
				Vector3.new(131.58, 39.14, 808.14),
				Vector3.new(122.16, 39.14, 802.78),
				Vector3.new(111.82, 39.71, 804.32),
				Vector3.new(111.25, 39.14, 792.87),
				Vector3.new(121.64, 39.14, 798.58),
				Vector3.new(130.17, 39.14, 806.05),
				Vector3.new(89.03, 55.19, 760.64),
				Vector3.new(97.66, 55.19, 759.65),
				Vector3.new(107.83, 55.19, 761.44),
				Vector3.new(117.58, 55.19, 762.98),
				Vector3.new(123.23, 55.19, 755.27),
				Vector3.new(124.41, 55.19, 770.08),
				Vector3.new(125.26, 55.19, 750.08),
				Vector3.new(123.65, 55.19, 738.07),
				Vector3.new(120.33, 55.19, 732.37),
				Vector3.new(122.24, 55.19, 720.49),
				Vector3.new(124.67, 55.19, 713.89),
				Vector3.new(118.38, 55.19, 704.50),
				Vector3.new(116.25, 55.19, 692.60),
				Vector3.new(114.63, 55.19, 684.37),
				Vector3.new(115.07, 55.19, 675.91),
				Vector3.new(105.20, 55.19, 671.07),
				Vector3.new(98.99, 55.40, 666.00),
				Vector3.new(92.50, 55.20, 669.49),
				Vector3.new(84.95, 55.58, 680.74),
				Vector3.new(83.66, 55.83, 688.90),
				Vector3.new(78.98, 56.78, 696.04),
				Vector3.new(71.67, 56.30, 700.85),
				Vector3.new(68.74, 55.18, 708.22),
				Vector3.new(62.32, 55.18, 711.86),
				Vector3.new(58.44, 55.19, 716.99),
				Vector3.new(59.09, 55.19, 725.83),
				Vector3.new(65.05, 55.19, 734.26),
				Vector3.new(60.69, 55.19, 741.70),
				Vector3.new(53.92, 55.25, 741.47),
				Vector3.new(43.91, 56.42, 742.29),
				Vector3.new(45.11, 55.85, 749.32),
				Vector3.new(69.54, 55.19, 744.81),
				Vector3.new(83.22, 55.35, 746.97),
				Vector3.new(89.76, 55.19, 741.42),
				Vector3.new(91.34, 55.19, 731.41),
				Vector3.new(96.27, 55.18, 725.19),
				Vector3.new(103.21, 55.19, 727.89),
				Vector3.new(108.07, 55.19, 734.58),
				Vector3.new(104.81, 55.19, 743.86),
				Vector3.new(100.97, 55.19, 710.70),
				Vector3.new(92.06, 55.19, 707.33),
				Vector3.new(88.72, 55.19, 704.76),
				Vector3.new(82.79, 55.91, 696.60),
				Vector3.new(82.93, 56.07, 686.96),
				Vector3.new(83.72, 55.71, 678.67),
				Vector3.new(78.24, 58.65, 672.74),
				Vector3.new(66.78, 59.92, 679.07),
				Vector3.new(63.78, 59.92, 685.61),
				Vector3.new(66.32, 59.81, 692.09),
				Vector3.new(70.64, 56.63, 698.01),
				Vector3.new(69.75, 55.52, 705.51),
				Vector3.new(63.72, 55.18, 709.89),
				Vector3.new(59.33, 55.27, 706.45),
				Vector3.new(53.26, 55.19, 705.57),
				Vector3.new(47.83, 55.19, 710.62),
				Vector3.new(45.95, 55.19, 698.33),
				Vector3.new(47.20, 55.19, 690.43),
				Vector3.new(48.03, 55.26, 675.36),
				Vector3.new(42.48, 54.59, 679.40),
				Vector3.new(37.56, 51.39, 685.43),
				Vector3.new(38.36, 54.94, 691.51),
				Vector3.new(40.38, 55.19, 698.36),
				Vector3.new(37.31, 55.19, 704.86),
				Vector3.new(30.84, 55.19, 709.57),
				Vector3.new(28.32, 55.33, 715.53),
				Vector3.new(29.79, 55.27, 722.77),
				Vector3.new(37.21, 55.19, 724.32),
				Vector3.new(41.60, 55.37, 730.35),
				Vector3.new(40.78, 56.21, 737.08),
				Vector3.new(26.02, 55.59, 739.43),
				Vector3.new(22.66, 54.68, 732.98),
				Vector3.new(26.51, 55.49, 723.86),
				Vector3.new(32.20, 55.18, 712.33),
				Vector3.new(30.01, 55.19, 703.22),
				Vector3.new(38.45, 55.19, 696.55),
				Vector3.new(31.32, 54.67, 597.33),
				Vector3.new(40.36, 55.87, 592.30),
				Vector3.new(52.73, 55.23, 586.81),
				Vector3.new(65.23, 55.14, 584.05),
				Vector3.new(76.66, 54.76, 581.51),
				Vector3.new(76.47, 55.19, 571.85),
				Vector3.new(74.11, 55.19, 561.17),
				Vector3.new(65.87, 55.19, 541.32),
				Vector3.new(65.92, 55.19, 531.99),
				Vector3.new(62.54, 55.19, 521.88),
				Vector3.new(57.57, 55.17, 510.96),
				Vector3.new(51.57, 55.58, 501.83),
				Vector3.new(74.77, 52.14, 502.66),
				Vector3.new(58.02, 55.19, 529.59),
				Vector3.new(49.39, 55.19, 535.37),
				Vector3.new(39.56, 55.17, 530.25),
				Vector3.new(32.66, 56.04, 529.78),
				Vector3.new(23.76, 56.75, 531.46),
				Vector3.new(16.55, 56.84, 528.05),
				Vector3.new(8.14, 54.22, 526.47),
				Vector3.new(0.82, 51.67, 520.63),
				Vector3.new(-14.14, 41.02, 534.78),
				Vector3.new(-13.69, 44.45, 548.74),
				Vector3.new(-19.94, 40.34, 567.38),
				Vector3.new(-21.96, 37.74, 574.94),
				Vector3.new(-13.72, 38.33, 589.37),
				Vector3.new(-8.79, 39.92, 597.85),
				Vector3.new(-9.85, 38.20, 603.49),
				Vector3.new(-19.67, 33.62, 588.99),
				Vector3.new(-22.75, 29.89, 588.54),
				Vector3.new(-27.40, 26.61, 596.13),
				Vector3.new(-20.76, 39.72, 569.30),
				Vector3.new(-10.28, 44.78, 540.05),
				Vector3.new(-0.66, 50.05, 537.31),
				Vector3.new(5.30, 54.07, 542.85),
				Vector3.new(15.29, 57.44, 549.49),
				Vector3.new(25.65, 56.73, 549.11),
				Vector3.new(35.18, 55.64, 548.75),
				Vector3.new(44.40, 55.18, 544.69),
				Vector3.new(53.22, 55.19, 550.65),
				Vector3.new(30.34, 56.05, 564.44),
				Vector3.new(19.67, 57.01, 563.90),
				Vector3.new(13.46, 56.86, 569.85),
				Vector3.new(9.58, 55.22, 583.60),
				Vector3.new(-28.29, 15.79, 521.62),
				Vector3.new(-32.03, 16.16, 530.65),
				Vector3.new(-37.44, 15.36, 527.01),
				Vector3.new(-25.17, 15.61, 502.01),
				Vector3.new(-29.81, 16.99, 490.80),
				Vector3.new(-32.99, 18.89, 483.12),
				Vector3.new(-36.40, 16.25, 474.87),
				Vector3.new(-32.79, 16.13, 466.01),
				Vector3.new(-24.18, 16.68, 461.78),
				Vector3.new(-19.67, 15.79, 453.99),
				Vector3.new(-10.26, 14.67, 430.36),
				Vector3.new(-16.06, 15.17, 423.29),
				Vector3.new(-26.50, 15.56, 418.41),
				Vector3.new(-25.00, 16.05, 406.68),
				Vector3.new(-31.48, 14.67, 400.37),
				Vector3.new(-36.74, 15.06, 395.20),
				Vector3.new(-36.46, 15.09, 375.30),
				Vector3.new(-27.39, 15.29, 368.04),
				Vector3.new(-30.05, 14.99, 349.24),
				Vector3.new(-33.74, 15.09, 344.07),
				Vector3.new(-29.14, 15.09, 332.99),
				Vector3.new(-22.64, 15.36, 327.65),
				Vector3.new(-16.71, 15.03, 318.61),
				Vector3.new(-11.54, 15.34, 313.17),
				Vector3.new(-11.02, 15.12, 300.28),
				Vector3.new(-3.25, 15.07, 293.17),
				Vector3.new(4.37, 15.09, 284.78),
				Vector3.new(10.29, 15.09, 270.49),
				Vector3.new(20.53, 15.09, 265.40),
				Vector3.new(40.43, 15.17, 254.30),
				Vector3.new(41.71, 15.09, 249.02),
				Vector3.new(-6.86, 15.09, 272.37),
				Vector3.new(-21.15, 15.09, 278.29),
				Vector3.new(-35.41, 15.09, 285.99),
				Vector3.new(-48.36, 15.09, 304.04),
				Vector3.new(-57.29, 15.09, 314.43),
				Vector3.new(-52.43, 15.09, 327.00),
				Vector3.new(-45.47, 15.09, 335.19),
				Vector3.new(-51.02, 15.09, 344.81),
				Vector3.new(-52.44, 15.09, 354.47),
				Vector3.new(-66.72, 15.09, 313.28),
				Vector3.new(-57.68, 15.09, 294.29),
				Vector3.new(-44.35, 15.09, 284.28),
				Vector3.new(-44.56, 15.09, 335.95),
				Vector3.new(-46.67, 15.09, 352.45),
				Vector3.new(-46.34, 15.09, 367.24),
				Vector3.new(-46.00, 15.09, 379.81),
				Vector3.new(-39.82, 15.09, 398.29),
				Vector3.new(-62.29, 15.09, 402.52),
				Vector3.new(-62.18, 15.09, 414.03),
				Vector3.new(-55.18, 15.09, 423.24),
				Vector3.new(-42.68, 15.09, 429.20),
				Vector3.new(-49.40, 15.09, 449.75),
				Vector3.new(-59.75, 15.09, 454.03),
				Vector3.new(-59.29, 15.09, 465.05),
				Vector3.new(-53.85, 15.09, 472.85),
				Vector3.new(-52.65, 15.09, 496.36),
				Vector3.new(-45.82, 15.12, 503.11),
				Vector3.new(-41.42, 15.31, 514.08),
				Vector3.new(-35.05, 15.65, 526.22),
				Vector3.new(60.75, 15.08, 461.44),
				Vector3.new(65.18, 15.08, 466.36),
				Vector3.new(73.32, 15.09, 466.99),
				Vector3.new(83.26, 15.09, 467.01),
				Vector3.new(85.91, 15.09, 456.02),
				Vector3.new(93.34, 15.08, 442.44),
				Vector3.new(94.73, 15.09, 431.68),
				Vector3.new(95.96, 15.09, 416.68),
				Vector3.new(98.64, 15.13, 404.85),
				Vector3.new(93.07, 16.15, 395.58),
				Vector3.new(87.60, 18.60, 386.23),
				Vector3.new(94.55, 16.51, 379.16),
				Vector3.new(98.08, 15.83, 373.24),
				Vector3.new(98.74, 17.74, 360.14),
				Vector3.new(91.88, 21.16, 357.33),
				Vector3.new(98.77, 18.49, 344.19),
				Vector3.new(98.11, 17.93, 337.62),
				Vector3.new(97.41, 17.64, 328.05),
				Vector3.new(104.81, 15.25, 321.59),
				Vector3.new(100.86, 16.17, 313.99),
				Vector3.new(113.90, 15.09, 303.18),
				Vector3.new(118.38, 15.18, 293.19),
				Vector3.new(128.26, 15.16, 286.56),
				Vector3.new(129.79, 15.09, 294.61),
				Vector3.new(125.17, 15.08, 303.39),
				Vector3.new(129.56, 15.09, 320.72),
				Vector3.new(139.32, 15.09, 319.52),
				Vector3.new(144.94, 15.08, 309.39),
				Vector3.new(143.93, 15.09, 296.28),
				Vector3.new(149.94, 15.09, 286.21),
				Vector3.new(147.89, 15.12, 278.39),
				Vector3.new(152.55, 15.09, 308.75),
				Vector3.new(157.31, 15.09, 301.55),
				Vector3.new(157.47, 15.09, 292.11),
				Vector3.new(155.17, 15.09, 283.07),
				Vector3.new(150.93, 15.25, 272.61),
				Vector3.new(156.90, 15.70, 262.89),
				Vector3.new(164.96, 15.11, 269.86),
				Vector3.new(172.30, 15.09, 274.23),
				Vector3.new(183.23, 15.09, 285.13),
				Vector3.new(190.53, 15.09, 281.77),
				Vector3.new(190.71, 15.09, 270.83),
				Vector3.new(184.15, 15.09, 262.51),
				Vector3.new(188.81, 15.54, 256.43),
				Vector3.new(196.09, 15.09, 259.20),
				Vector3.new(205.26, 15.09, 270.80),
				Vector3.new(214.97, 15.08, 272.86),
				Vector3.new(221.49, 15.09, 261.62),
				Vector3.new(209.57, 15.56, 249.63),
				Vector3.new(216.14, 16.02, 245.83),
				Vector3.new(228.87, 15.09, 253.42),
				Vector3.new(234.96, 15.09, 264.24),
				Vector3.new(248.05, 15.09, 267.26),
				Vector3.new(250.40, 15.08, 256.81),
				Vector3.new(263.59, 15.09, 252.59),
				Vector3.new(271.83, 15.09, 246.60),
				Vector3.new(267.29, 15.09, 229.13),
				Vector3.new(248.37, 15.09, 225.45),
				Vector3.new(233.23, 15.09, 215.82),
				Vector3.new(220.49, 15.08, 196.64),
				Vector3.new(223.74, 15.09, 185.37),
				Vector3.new(225.15, 15.09, 174.82),
				Vector3.new(242.88, 15.09, 181.18),
				Vector3.new(255.81, 15.09, 193.34),
				Vector3.new(273.50, 15.09, 196.55),
				Vector3.new(281.19, 15.09, 210.72),
				Vector3.new(292.17, 15.09, 218.95),
				Vector3.new(289.91, 15.08, 240.00),
				Vector3.new(235.51, 15.09, 177.29),
				Vector3.new(226.58, 15.09, 170.74),
				Vector3.new(209.12, 15.08, 173.28),
				Vector3.new(207.71, 15.09, 188.29),
				Vector3.new(206.43, 15.14, 201.96),
				Vector3.new(195.96, 16.16, 208.04),
				Vector3.new(169.61, 15.09, 192.08),
				Vector3.new(158.10, 15.09, 189.16),
				Vector3.new(143.81, 15.09, 200.90),
				Vector3.new(143.28, 15.29, 215.66),
				Vector3.new(114.82, 15.18, 237.01),
				Vector3.new(97.61, 15.16, 247.60),
				Vector3.new(88.18, 14.97, 239.78),
				Vector3.new(76.88, 15.16, 244.42),
				Vector3.new(40.93, 14.97, 248.04),
				Vector3.new(36.21, 15.09, 257.00),
				Vector3.new(162.74, 36.21, 240.67),
				Vector3.new(173.15, 35.01, 232.60),
				Vector3.new(179.94, 33.92, 232.81),
				Vector3.new(168.44, 35.25, 226.47),
				Vector3.new(159.85, 36.07, 233.36),
				Vector3.new(149.95, 37.17, 236.37),
				Vector3.new(153.64, 36.44, 245.11),
				Vector3.new(139.63, 37.15, 245.28),
				Vector3.new(136.29, 36.59, 254.65),
				Vector3.new(121.96, 37.25, 254.92),
				Vector3.new(122.51, 36.58, 265.47),
				Vector3.new(113.06, 36.59, 268.63),
				Vector3.new(105.71, 36.99, 262.83),
				Vector3.new(103.40, 36.58, 276.59),
				Vector3.new(90.73, 36.43, 273.14),
				Vector3.new(92.44, 37.36, 286.36),
				Vector3.new(88.74, 34.98, 298.95),
				Vector3.new(81.82, 37.15, 310.68),
				Vector3.new(76.58, 37.00, 321.99),
				Vector3.new(71.34, 36.28, 337.35),
				Vector3.new(64.84, 36.93, 336.86),
				Vector3.new(58.58, 37.42, 348.18),
				Vector3.new(59.45, 41.10, 358.58),
				Vector3.new(57.39, 44.07, 365.89),
				Vector3.new(63.83, 47.19, 372.45),
				Vector3.new(65.47, 45.61, 368.48),
				Vector3.new(33.27, 53.84, 366.74),
				Vector3.new(22.31, 55.42, 360.70),
				Vector3.new(34.28, 54.48, 350.37),
				Vector3.new(27.70, 62.38, 328.82),
				Vector3.new(28.75, 62.88, 320.31),
				Vector3.new(34.19, 69.92, 304.84),
				Vector3.new(35.26, 70.71, 297.07),
				Vector3.new(37.35, 70.69, 287.73),
				Vector3.new(53.86, 70.48, 287.87),
				Vector3.new(61.06, 70.68, 281.90),
				Vector3.new(64.25, 67.82, 272.51),
				Vector3.new(66.94, 66.30, 261.03),
				Vector3.new(68.18, 64.29, 251.51),
				Vector3.new(61.97, 64.36, 257.36),
				Vector3.new(57.86, 67.14, 271.69),
				Vector3.new(42.88, 70.15, 273.49),
				Vector3.new(38.40, 69.75, 265.45),
				Vector3.new(30.06, 69.70, 262.53),
				Vector3.new(25.03, 70.31, 271.57),
				Vector3.new(16.49, 70.59, 274.66),
				Vector3.new(15.46, 70.54, 282.65),
				Vector3.new(16.50, 70.62, 292.94),
				Vector3.new(9.10, 70.60, 296.29),
				Vector3.new(3.69, 70.59, 291.66),
				Vector3.new(5.46, 70.60, 283.69),
				Vector3.new(4.02, 70.37, 275.85),
				Vector3.new(14.17, 70.76, 275.00),
				Vector3.new(12.15, 70.59, 287.32),
				Vector3.new(2.87, 70.55, 299.78),
				Vector3.new(3.36, 68.49, 316.93),
				Vector3.new(9.38, 70.28, 326.59),
				Vector3.new(9.75, 58.84, 344.60),
				Vector3.new(-0.37, 56.58, 350.08),
				Vector3.new(-7.13, 56.55, 347.30),
				Vector3.new(-5.07, 56.59, 358.57),
				Vector3.new(-3.85, 57.29, 366.29),
				Vector3.new(13.39, 55.43, 375.82),
				Vector3.new(18.68, 55.43, 372.57),
				Vector3.new(22.16, 55.37, 366.27),
				Vector3.new(24.69, 54.54, 376.54),
				Vector3.new(8.80, 55.39, 385.26),
				Vector3.new(4.26, 55.51, 393.49),
				Vector3.new(7.07, 55.60, 399.02),
				Vector3.new(4.35, 55.33, 404.13),
				Vector3.new(-2.40, 54.66, 399.92),
				Vector3.new(0.67, 53.17, 388.68),
				Vector3.new(9.17, 55.32, 381.36),
				Vector3.new(54.85, 46.09, 369.97),
				Vector3.new(62.80, 48.21, 375.66),
				Vector3.new(47.93, 70.18, 397.76),
				Vector3.new(46.43, 71.46, 407.27),
				Vector3.new(35.69, 73.12, 403.03),
				Vector3.new(30.82, 72.69, 397.55),
				Vector3.new(25.21, 72.59, 407.49),
				Vector3.new(20.96, 72.52, 415.18),
				Vector3.new(19.85, 72.58, 422.99),
				Vector3.new(17.60, 72.55, 428.35),
				Vector3.new(7.42, 71.85, 431.98),
				Vector3.new(10.15, 72.55, 438.87),
				Vector3.new(56.58, 69.33, 412.18),
				Vector3.new(61.35, 66.89, 404.96),
				Vector3.new(65.89, 64.60, 404.31),
				Vector3.new(85.30, 15.09, 434.85),
				Vector3.new(83.95, 15.09, 442.42),
				Vector3.new(79.64, 15.09, 457.84),
				Vector3.new(67.64, 14.94, 473.37),
				Vector3.new(69.87, 15.03, 470.46),
				Vector3.new(77.90, 15.08, 468.07),
				Vector3.new(82.62, 15.05, 470.62),
				Vector3.new(89.71, 15.09, 452.47),



			}
		}
	},
	[7] = {
		ChestValue = 1,
		TierWeights = {
			[1] = 60,
			[2] =190,
			[3] =70,
			[4] =35,
			[5] =3,
			[6] = 1,
			[7] = 0
		},
		Groups = {
			[1] = { 
				Vector3.new(1631.95, 17.63, -491.61),
				Vector3.new(1640.43, 17.63, -493.58),
				Vector3.new(1639.96, 17.63, -480.62),
				Vector3.new(1641.38, 17.63, -471.16),
				Vector3.new(1651.36, 17.63, -473.65),
				Vector3.new(1646.31, 17.63, -468.83),
				Vector3.new(1625.02, 17.63, -504.91),
				Vector3.new(1618.22, 17.63, -501.72),
				Vector3.new(1612.72, 17.63, -509.78),
				Vector3.new(1605.66, 17.63, -509.82),
				Vector3.new(1600.33, 17.63, -502.30),
				Vector3.new(1594.58, 17.63, -508.41),
				Vector3.new(1594.87, 17.63, -520.15),
				Vector3.new(1585.70, 17.63, -525.00),
				Vector3.new(1583.74, 17.63, -512.68),
				Vector3.new(1586.48, 17.63, -499.36),
				Vector3.new(1589.05, 17.63, -486.82),
				Vector3.new(1591.11, 17.63, -472.01),
				Vector3.new(1581.40, 17.63, -469.95),
				Vector3.new(1574.78, 17.63, -475.06),
				Vector3.new(1563.90, 17.63, -483.04),
				Vector3.new(1566.58, 17.61, -492.82),
				Vector3.new(1560.75, 17.63, -497.72),
				Vector3.new(1551.97, 17.63, -497.91),
				Vector3.new(1549.15, 17.63, -511.62),
				Vector3.new(1542.91, 17.63, -517.82),
				Vector3.new(1536.08, 17.63, -510.32),
				Vector3.new(1536.75, 17.63, -500.16),
				Vector3.new(1529.43, 17.63, -495.32),
				Vector3.new(1517.60, 17.63, -492.57),
				Vector3.new(1522.93, 17.63, -484.72),
				Vector3.new(1531.39, 17.62, -479.14),
				Vector3.new(1525.17, 17.63, -469.66),
				Vector3.new(1512.40, 17.63, -472.43),
				Vector3.new(1505.31, 17.63, -474.91),
				Vector3.new(1493.04, 17.63, -470.24),
				Vector3.new(1497.36, 17.63, -492.44),
				Vector3.new(1491.92, 17.63, -503.93),
				Vector3.new(1495.73, 17.63, -512.36),
				Vector3.new(1506.71, 17.63, -508.44),
				Vector3.new(1505.50, 17.63, -498.38),
				Vector3.new(1490.10, 17.63, -494.57),
				Vector3.new(1483.62, 17.63, -490.09),
				Vector3.new(1469.97, 17.63, -490.88),
				Vector3.new(1466.86, 17.63, -500.97),
				Vector3.new(1469.38, 17.63, -515.54),
				Vector3.new(1453.84, 17.63, -512.10),
				Vector3.new(1446.86, 17.63, -503.46),
				Vector3.new(1444.19, 17.63, -492.44),
				Vector3.new(1434.34, 17.63, -494.32),
				Vector3.new(1423.49, 17.63, -492.32),
				Vector3.new(1425.51, 17.63, -508.63),
				Vector3.new(1415.85, 17.63, -511.51),
				Vector3.new(1411.34, 17.62, -504.56),
				Vector3.new(1411.42, 17.63, -493.25),
				Vector3.new(1406.16, 17.63, -489.60),
				Vector3.new(1395.43, 17.63, -497.41),
				Vector3.new(1388.15, 17.63, -491.04),
				Vector3.new(1381.22, 17.63, -484.19),
				Vector3.new(1386.25, 17.63, -477.19),
				Vector3.new(1384.12, 17.63, -468.86),
				Vector3.new(1375.89, 17.63, -471.46),
				Vector3.new(1373.27, 17.63, -477.90),
				Vector3.new(1396.69, 17.63, -469.68),
				Vector3.new(1404.31, 17.63, -473.55),
				Vector3.new(1414.17, 17.63, -469.64),
				Vector3.new(1421.84, 17.63, -474.87),
				Vector3.new(1423.95, 17.63, -480.37),
				Vector3.new(1429.32, 17.63, -469.14),
				Vector3.new(1437.70, 17.63, -469.64),
				Vector3.new(1447.39, 17.63, -470.47),
				Vector3.new(1457.16, 17.63, -470.36),
				Vector3.new(1459.39, 17.63, -476.06),
				Vector3.new(1462.15, 17.63, -483.21),
				Vector3.new(1486.65, 17.63, -470.42),
				Vector3.new(1500.76, 17.63, -469.73),
				Vector3.new(1520.69, 17.63, -469.90),
				Vector3.new(1516.88, 17.63, -484.21),
				Vector3.new(1588.06, 17.63, -472.20),
				Vector3.new(1592.39, 17.63, -454.73),
				Vector3.new(1583.11, 17.63, -452.08),
				Vector3.new(1573.38, 17.63, -451.85),
				Vector3.new(1573.72, 17.63, -444.61),
				Vector3.new(1579.59, 17.63, -437.56),
				Vector3.new(1589.25, 17.63, -431.64),
				Vector3.new(1593.12, 17.63, -423.00),
				Vector3.new(1597.78, 17.63, -414.30),
				Vector3.new(1605.63, 17.63, -411.31),
				Vector3.new(1613.32, 17.63, -413.86),
				Vector3.new(1622.42, 17.63, -414.71),
				Vector3.new(1632.70, 17.63, -412.95),
				Vector3.new(1638.98, 17.63, -419.72),
				Vector3.new(1637.61, 17.63, -428.31),
				Vector3.new(1645.21, 17.63, -439.73),
				Vector3.new(1646.74, 17.63, -448.55),
				Vector3.new(1641.22, 17.63, -456.03),
				Vector3.new(1643.93, 17.63, -462.94),
				Vector3.new(1645.45, 17.63, -470.15),
				Vector3.new(1658.93, 17.63, -464.13),
				Vector3.new(1660.31, 17.63, -455.23),
				Vector3.new(1664.66, 17.63, -444.48),
				Vector3.new(1668.28, 17.63, -437.90),
				Vector3.new(1665.66, 17.63, -428.48),
				Vector3.new(1658.61, 17.63, -422.44),
				Vector3.new(1645.68, 17.63, -430.76),
				Vector3.new(1651.35, 17.63, -412.46),
				Vector3.new(1651.41, 17.63, -403.37),
				Vector3.new(1650.81, 17.63, -394.06),
				Vector3.new(1657.68, 17.63, -392.39),
				Vector3.new(1664.89, 17.63, -398.73),
				Vector3.new(1671.50, 17.63, -404.54),
				Vector3.new(1668.34, 17.63, -415.18),
				Vector3.new(1637.99, 17.63, -391.69),
				Vector3.new(1634.87, 17.63, -383.76),
				Vector3.new(1624.84, 17.63, -383.05),
				Vector3.new(1613.13, 17.63, -383.80),
				Vector3.new(1600.75, 17.63, -382.70),
				Vector3.new(1590.11, 17.63, -383.38),
				Vector3.new(1582.47, 17.63, -387.96),
				Vector3.new(1577.37, 17.63, -393.76),
				Vector3.new(1583.62, 17.63, -399.48),
				Vector3.new(1568.93, 17.63, -384.21),
				Vector3.new(1565.02, 17.63, -383.06),
				Vector3.new(1555.64, 17.63, -382.21),
				Vector3.new(1546.65, 17.63, -383.18),
				Vector3.new(1538.53, 17.62, -382.28),
				Vector3.new(1534.58, 17.63, -388.87),
				Vector3.new(1532.02, 17.63, -395.63),
				Vector3.new(1520.95, 17.63, -389.42),
				Vector3.new(1517.29, 17.66, -402.20),
				Vector3.new(1525.45, 17.63, -418.44),
				Vector3.new(1526.15, 17.63, -434.01),
				Vector3.new(1520.51, 17.63, -441.49),
				Vector3.new(1517.93, 17.63, -449.91),
				Vector3.new(1523.51, 17.63, -455.56),
				Vector3.new(1527.48, 17.63, -446.06),
				Vector3.new(1532.19, 17.60, -439.66),
				Vector3.new(1546.06, 17.63, -434.45),
				Vector3.new(1552.64, 17.63, -429.64),
				Vector3.new(1560.42, 17.63, -435.30),
				Vector3.new(1562.81, 17.63, -445.10),
				Vector3.new(1572.81, 17.63, -437.27),
				Vector3.new(1580.24, 17.63, -418.94),
				Vector3.new(1590.90, 17.63, -415.91),
				Vector3.new(1599.79, 17.63, -410.12),
				Vector3.new(1629.43, 17.63, -408.23),
				Vector3.new(1638.12, 17.62, -385.05),
				Vector3.new(1648.72, 17.63, -383.66),
				Vector3.new(1662.76, 17.63, -375.23),
				Vector3.new(1672.26, 17.63, -366.74),
				Vector3.new(1668.96, 17.63, -356.13),
				Vector3.new(1658.36, 17.63, -355.68),
				Vector3.new(1648.38, 17.63, -359.37),
				Vector3.new(1639.96, 17.63, -365.91),
				Vector3.new(1629.88, 17.63, -364.40),
				Vector3.new(1621.74, 17.63, -362.29),
				Vector3.new(1613.16, 17.63, -365.46),
				Vector3.new(1604.58, 17.63, -367.91),
				Vector3.new(1582.47, 17.63, -364.91),
				Vector3.new(1574.62, 17.63, -361.26),
				Vector3.new(1568.77, 17.63, -365.64),
				Vector3.new(1562.21, 17.63, -367.08),
				Vector3.new(1559.27, 17.63, -359.41),
				Vector3.new(1549.18, 17.63, -368.79),
				Vector3.new(1540.21, 17.63, -367.73),
				Vector3.new(1536.96, 17.63, -357.34),
				Vector3.new(1530.48, 17.63, -359.31),
				Vector3.new(1522.16, 17.63, -359.72),
				Vector3.new(1524.73, 17.63, -367.73),
				Vector3.new(1520.78, 17.63, -356.91),
				Vector3.new(1521.68, 17.63, -348.75),
				Vector3.new(1516.14, 17.63, -360.41),
				Vector3.new(1518.55, 17.63, -340.59),
				Vector3.new(1519.95, 17.63, -326.92),
				Vector3.new(1521.37, 17.63, -321.84),
				Vector3.new(1531.30, 17.63, -318.91),
				Vector3.new(1533.16, 17.63, -329.80),
				Vector3.new(1538.55, 17.63, -333.77),
				Vector3.new(1544.59, 17.63, -328.77),
				Vector3.new(1549.62, 17.63, -320.01),
				Vector3.new(1557.58, 17.63, -320.11),
				Vector3.new(1558.61, 17.63, -330.56),
				Vector3.new(1568.92, 17.63, -333.93),
				Vector3.new(1571.63, 17.63, -324.98),
				Vector3.new(1577.87, 17.63, -318.61),
				Vector3.new(1583.27, 17.63, -324.86),
				Vector3.new(1577.02, 17.63, -331.22),
				Vector3.new(1573.38, 17.63, -343.04),
				Vector3.new(1590.47, 17.63, -330.44),
				Vector3.new(1593.60, 17.63, -319.01),
				Vector3.new(1601.89, 17.63, -321.88),
				Vector3.new(1612.19, 17.63, -328.19),
				Vector3.new(1618.74, 17.63, -332.62),
				Vector3.new(1623.22, 17.63, -325.97),
				Vector3.new(1619.30, 17.63, -316.63),
				Vector3.new(1615.49, 17.63, -306.69),
				Vector3.new(1606.17, 17.41, -306.48),
				Vector3.new(1602.68, 17.63, -309.19),
				Vector3.new(1610.11, 17.63, -301.10),
				Vector3.new(1620.96, 17.63, -302.46),
				Vector3.new(1629.21, 17.63, -299.00),
				Vector3.new(1642.33, 17.63, -300.27),
				Vector3.new(1648.20, 17.63, -293.41),
				Vector3.new(1642.52, 17.63, -287.41),
				Vector3.new(1635.73, 17.63, -280.63),
				Vector3.new(1631.44, 17.63, -273.37),
				Vector3.new(1625.66, 17.63, -272.93),
				Vector3.new(1624.15, 17.63, -281.42),
				Vector3.new(1619.78, 17.63, -288.01),
				Vector3.new(1612.36, 17.63, -292.65),
				Vector3.new(1605.23, 17.63, -290.24),
				Vector3.new(1600.28, 17.63, -294.63),
				Vector3.new(1597.05, 17.63, -302.72),
				Vector3.new(1590.21, 17.63, -305.69),
				Vector3.new(1584.81, 17.63, -303.52),
				Vector3.new(1601.47, 17.63, -294.97),
				Vector3.new(1599.02, 17.62, -288.23),
				Vector3.new(1600.18, 17.63, -278.97),
				Vector3.new(1595.85, 17.63, -273.79),
				Vector3.new(1591.48, 17.62, -266.53),
				Vector3.new(1589.50, 17.63, -257.11),
				Vector3.new(1590.10, 17.63, -248.77),
				Vector3.new(1585.22, 17.63, -245.94),
				Vector3.new(1583.45, 17.63, -253.44),
				Vector3.new(1586.58, 17.63, -261.77),
				Vector3.new(1585.62, 17.63, -269.45),
				Vector3.new(1582.18, 17.63, -277.70),
				Vector3.new(1575.43, 17.63, -278.25),
				Vector3.new(1570.33, 17.63, -274.25),
				Vector3.new(1564.16, 17.63, -272.65),
				Vector3.new(1557.62, 17.63, -275.82),
				Vector3.new(1550.16, 17.63, -275.64),
				Vector3.new(1541.69, 17.63, -274.58),
				Vector3.new(1537.94, 17.63, -270.55),
				Vector3.new(1541.87, 17.63, -264.00),
				Vector3.new(1544.66, 17.63, -261.31),
				Vector3.new(1550.36, 17.63, -267.22),
				Vector3.new(1554.78, 17.63, -264.20),
				Vector3.new(1552.04, 17.63, -256.27),
				Vector3.new(1547.46, 17.63, -250.37),
				Vector3.new(1549.16, 17.63, -234.25),
				Vector3.new(1559.74, 17.62, -237.79),
				Vector3.new(1570.86, 17.63, -239.19),
				Vector3.new(1591.17, 17.63, -331.29),
				Vector3.new(1585.11, 17.63, -321.17),
				Vector3.new(1573.61, 17.63, -324.93),
				Vector3.new(1564.06, 17.63, -331.40),
				Vector3.new(1556.41, 17.63, -330.26),
				Vector3.new(1548.50, 17.63, -324.77),
				Vector3.new(1540.56, 17.63, -321.24),
				Vector3.new(1531.66, 17.63, -325.26),
				Vector3.new(1522.17, 17.63, -323.85),
				Vector3.new(1517.44, 17.63, -302.59),
				Vector3.new(1516.02, 17.63, -296.31),
				Vector3.new(1517.56, 17.63, -285.51),
				Vector3.new(1518.77, 17.63, -277.33),
				Vector3.new(1522.27, 17.63, -267.37),
				Vector3.new(1531.45, 17.63, -268.60),
				Vector3.new(1511.16, 17.63, -266.10),
				Vector3.new(1501.83, 17.63, -269.41),
				Vector3.new(1494.27, 17.63, -270.64),
				Vector3.new(1487.95, 17.63, -267.30),
				Vector3.new(1479.39, 17.63, -265.77),
				Vector3.new(1471.83, 17.63, -262.14),
				Vector3.new(1469.87, 17.63, -252.73),
				Vector3.new(1469.43, 17.63, -244.97),
				Vector3.new(1466.94, 17.63, -238.85),
				Vector3.new(1458.60, 17.63, -243.08),
				Vector3.new(1450.77, 17.63, -244.27),
				Vector3.new(1442.97, 17.63, -244.57),
				Vector3.new(1441.51, 17.63, -251.45),
				Vector3.new(1446.38, 17.63, -256.66),
				Vector3.new(1463.39, 17.63, -251.56),
				Vector3.new(1466.60, 17.63, -270.65),
				Vector3.new(1458.89, 17.63, -276.37),
				Vector3.new(1445.42, 17.63, -273.55),
				Vector3.new(1441.14, 17.63, -267.26),
				Vector3.new(1442.35, 17.63, -259.08),
				Vector3.new(1437.67, 17.63, -253.50),
				Vector3.new(1428.71, 17.63, -252.17),
				Vector3.new(1425.45, 17.63, -258.52),
				Vector3.new(1432.22, 17.63, -269.02),
				Vector3.new(1443.44, 17.63, -280.39),
				Vector3.new(1441.97, 17.63, -290.29),
				Vector3.new(1447.23, 17.63, -298.11),
				Vector3.new(1456.13, 17.63, -296.33),
				Vector3.new(1464.42, 17.63, -293.96),
				Vector3.new(1468.11, 17.63, -302.67),
				Vector3.new(1474.76, 17.63, -316.50),
				Vector3.new(1487.47, 17.63, -320.34),
				Vector3.new(1486.90, 17.63, -328.23),
				Vector3.new(1498.48, 17.63, -326.74),
				Vector3.new(1501.44, 17.63, -332.60),
				Vector3.new(1499.66, 17.63, -344.61),
				Vector3.new(1492.41, 17.63, -347.81),
				Vector3.new(1489.57, 17.63, -355.02),
				Vector3.new(1492.02, 17.63, -363.14),
				Vector3.new(1502.66, 17.63, -361.86),
				Vector3.new(1494.00, 17.63, -369.66),
				Vector3.new(1484.79, 17.63, -368.36),
				Vector3.new(1473.70, 17.63, -368.72),
				Vector3.new(1461.27, 17.63, -369.26),
				Vector3.new(1453.11, 17.63, -367.06),
				Vector3.new(1449.36, 17.63, -359.75),
				Vector3.new(1450.55, 17.63, -351.70),
				Vector3.new(1456.69, 17.63, -343.90),
				Vector3.new(1461.63, 17.63, -341.08),
				Vector3.new(1442.31, 17.63, -334.83),
				Vector3.new(1438.49, 17.63, -329.68),
				Vector3.new(1431.90, 17.63, -320.80),
				Vector3.new(1439.63, 17.63, -317.65),
				Vector3.new(1446.74, 17.63, -307.42),
				Vector3.new(1449.29, 17.63, -301.34),
				Vector3.new(1452.35, 17.62, -296.40),
				Vector3.new(1442.42, 17.63, -290.13),
				Vector3.new(1437.10, 17.63, -282.96),
				Vector3.new(1431.93, 17.63, -275.99),
				Vector3.new(1426.69, 17.63, -268.93),
				Vector3.new(1422.00, 17.63, -262.61),
				Vector3.new(1413.44, 17.63, -256.03),
				Vector3.new(1404.32, 17.63, -255.09),
				Vector3.new(1401.95, 17.63, -262.28),
				Vector3.new(1404.53, 17.63, -267.98),
				Vector3.new(1406.77, 17.63, -276.18),
				Vector3.new(1412.10, 17.63, -283.36),
				Vector3.new(1417.34, 17.63, -290.43),
				Vector3.new(1422.43, 17.63, -297.28),
				Vector3.new(1427.83, 17.63, -304.56),
				Vector3.new(1427.13, 17.63, -312.36),
				Vector3.new(1429.89, 17.63, -319.41),
				Vector3.new(1428.43, 17.63, -327.15),
				Vector3.new(1423.55, 17.63, -333.27),
				Vector3.new(1422.13, 17.63, -340.75),
				Vector3.new(1414.88, 17.63, -345.27),
				Vector3.new(1407.83, 17.63, -343.63),
				Vector3.new(1406.00, 17.63, -336.21),
				Vector3.new(1403.36, 17.63, -328.74),
				Vector3.new(1400.58, 17.63, -321.31),
				Vector3.new(1397.03, 17.63, -313.57),
				Vector3.new(1394.48, 17.63, -306.33),
				Vector3.new(1394.75, 17.63, -295.09),
				Vector3.new(1394.60, 17.63, -287.50),
				Vector3.new(1392.89, 17.63, -279.30),
				Vector3.new(1393.30, 17.63, -271.83),
				Vector3.new(1384.17, 17.63, -271.20),
				Vector3.new(1377.10, 17.63, -276.44),
				Vector3.new(1375.34, 17.63, -284.00),
				Vector3.new(1369.54, 17.63, -291.44),
				Vector3.new(1368.09, 17.63, -299.47),
				Vector3.new(1362.99, 17.63, -311.55),
				Vector3.new(1368.87, 17.63, -319.48),
				Vector3.new(1376.82, 17.63, -330.19),
				Vector3.new(1382.49, 17.63, -338.67),
				Vector3.new(1391.32, 17.63, -346.36),
				Vector3.new(1400.27, 17.63, -353.78),
				Vector3.new(1398.73, 17.63, -362.04),
				Vector3.new(1390.38, 17.63, -366.21),
				Vector3.new(1379.78, 17.63, -367.50),
				Vector3.new(1372.98, 17.63, -363.51),
				Vector3.new(1366.15, 17.63, -354.30),
				Vector3.new(1353.59, 17.63, -347.22),
				Vector3.new(1346.49, 17.63, -350.56),
				Vector3.new(1350.99, 17.63, -362.13),
				Vector3.new(1354.77, 17.63, -371.85),
				Vector3.new(1347.13, 17.63, -380.53),
				Vector3.new(1354.00, 17.63, -382.95),
				Vector3.new(1362.11, 17.63, -379.84),
				Vector3.new(1371.72, 17.63, -379.67),
				Vector3.new(1381.80, 17.63, -384.41),
				Vector3.new(1389.42, 17.63, -382.36),
				Vector3.new(1401.02, 17.63, -383.06),
				Vector3.new(1407.50, 17.63, -386.32),
				Vector3.new(1393.11, 17.63, -392.60),
				Vector3.new(1391.33, 17.63, -399.87),
				Vector3.new(1382.52, 17.63, -400.15),
				Vector3.new(1375.13, 17.62, -399.05),
				Vector3.new(1360.50, 17.63, -403.49),
				Vector3.new(1351.23, 17.63, -405.99),
				Vector3.new(1346.13, 17.63, -408.69),
				Vector3.new(1352.23, 17.63, -415.77),
				Vector3.new(1361.99, 17.63, -417.21),
				Vector3.new(1370.95, 17.63, -418.54),
				Vector3.new(1380.45, 17.63, -419.95),
				Vector3.new(1385.30, 17.63, -424.80),
				Vector3.new(1383.83, 17.63, -432.35),
				Vector3.new(1378.49, 17.63, -441.43),
				Vector3.new(1371.76, 17.62, -443.96),
				Vector3.new(1363.61, 17.63, -441.39),
				Vector3.new(1391.75, 17.63, -422.83),
				Vector3.new(1400.96, 17.63, -416.00),
				Vector3.new(1410.15, 17.63, -415.20),
				Vector3.new(1418.04, 17.63, -412.24),
				Vector3.new(1428.92, 17.63, -413.60),
				Vector3.new(1442.55, 17.63, -412.76),
				Vector3.new(1445.48, 17.63, -406.12),
				Vector3.new(1445.38, 17.63, -396.49),
				Vector3.new(1444.92, 17.63, -382.89),
				Vector3.new(1454.65, 17.63, -386.52),
				Vector3.new(1454.96, 17.68, -416.11),
				Vector3.new(1464.98, 17.68, -417.60),
				Vector3.new(1475.79, 17.68, -419.20),
				Vector3.new(1484.76, 17.68, -420.53),
				Vector3.new(1492.31, 17.63, -416.97),
				Vector3.new(1499.09, 17.63, -409.83),
				Vector3.new(1500.38, 17.63, -401.13),
				Vector3.new(1500.95, 17.63, -393.87),
				Vector3.new(1495.55, 17.63, -386.59),
				Vector3.new(1489.45, 17.63, -382.55),
				Vector3.new(1482.29, 17.63, -386.54),
				Vector3.new(1494.27, 17.63, -409.28),
				Vector3.new(1486.80, 17.63, -415.15),
				Vector3.new(1486.58, 17.63, -422.15),
				Vector3.new(1483.26, 17.63, -431.30),
				Vector3.new(1475.16, 17.63, -433.41),
				Vector3.new(1467.88, 17.63, -426.87),
				Vector3.new(1461.41, 17.63, -420.88),
				Vector3.new(1455.75, 17.63, -432.05),
				Vector3.new(1461.79, 17.63, -440.18),
				Vector3.new(1482.46, 17.63, -436.71),
				Vector3.new(1498.00, 17.63, -444.18),
				Vector3.new(1490.76, 17.63, -457.23),
				Vector3.new(1481.64, 18.04, -459.91),
				Vector3.new(1464.63, 17.63, -458.39),
				Vector3.new(1445.96, 17.66, -457.62),
				Vector3.new(1422.52, 17.63, -457.64),
				Vector3.new(1377.30, 17.63, -456.45),
				Vector3.new(1373.48, 17.63, -467.66),
				Vector3.new(1378.96, 17.63, -474.63),
				Vector3.new(1386.01, 17.63, -473.09),
				Vector3.new(1384.56, 17.63, -482.80),
				Vector3.new(1393.71, 17.63, -493.15),
				Vector3.new(1401.53, 17.63, -491.89),
				Vector3.new(1412.11, 17.63, -490.54),
				Vector3.new(1419.49, 17.63, -491.63),
				Vector3.new(1424.92, 17.63, -481.54),
				Vector3.new(1424.52, 17.63, -473.15),
				Vector3.new(1460.51, 17.63, -479.12),
				Vector3.new(1459.49, 17.63, -485.98),
				Vector3.new(1456.36, 17.63, -492.15),
				Vector3.new(1450.79, 17.63, -496.28),
				Vector3.new(1442.23, 17.63, -502.63),
				Vector3.new(1442.19, 17.63, -509.70),
				Vector3.new(1451.96, 17.63, -511.60),
				Vector3.new(1460.98, 17.63, -511.10),
				Vector3.new(1467.83, 17.63, -506.01),
				Vector3.new(1470.04, 17.63, -496.71),
				Vector3.new(1477.60, 17.63, -490.94),
				Vector3.new(1485.56, 17.63, -494.91),
				Vector3.new(1483.83, 17.63, -507.03),
				Vector3.new(1491.75, 17.63, -511.92),
				Vector3.new(1502.03, 17.63, -513.44),
				Vector3.new(1508.88, 17.63, -509.47),
				Vector3.new(1510.09, 17.63, -501.29),
				Vector3.new(1511.77, 17.63, -489.95),
				Vector3.new(1511.51, 17.63, -480.11),
				Vector3.new(1514.92, 17.63, -472.10),
				Vector3.new(1524.01, 17.63, -474.85),
				Vector3.new(1524.91, 17.63, -486.31),
				Vector3.new(1527.13, 17.63, -494.90),
				Vector3.new(1504.63, 18.45, -465.43),
				Vector3.new(1515.08, 18.36, -462.41),
				Vector3.new(1525.46, 18.41, -464.75),
				Vector3.new(1509.84, 18.50, -452.02),
				Vector3.new(1508.81, 18.50, -441.78),
				Vector3.new(1509.91, 18.29, -434.51),
				Vector3.new(1509.22, 18.56, -425.71),
				Vector3.new(1508.55, 18.44, -417.12),
				Vector3.new(1508.28, 18.32, -409.52),
				Vector3.new(1509.51, 18.54, -400.51),
				Vector3.new(1509.90, 18.24, -390.08),
				Vector3.new(1514.89, 18.37, -371.36),
				Vector3.new(1509.01, 18.24, -358.40),
				Vector3.new(1509.62, 18.33, -342.28),
				Vector3.new(1509.67, 18.54, -324.27),
				Vector3.new(1511.64, 18.74, -308.04),
				Vector3.new(1510.63, 18.55, -293.32),
				Vector3.new(1508.30, 18.32, -285.25),
				Vector3.new(1509.83, 18.54, -305.86),
				Vector3.new(1502.71, 18.43, -317.18),
				Vector3.new(1491.69, 18.25, -317.10),
				Vector3.new(1523.33, 18.42, -311.56),
				Vector3.new(1532.79, 18.35, -312.50),
				Vector3.new(1542.85, 18.30, -311.79),
				Vector3.new(1554.71, 18.50, -309.53),
				Vector3.new(1564.31, 18.34, -311.73),
				Vector3.new(1573.39, 18.50, -311.11),
				Vector3.new(1582.51, 18.56, -310.21),
				Vector3.new(1594.68, 18.31, -313.69),
				Vector3.new(1602.02, 17.63, -312.51),
				Vector3.new(1614.41, 18.50, -373.97),
				Vector3.new(1598.52, 18.37, -377.14),
				Vector3.new(1589.69, 18.35, -378.23),
				Vector3.new(1566.87, 18.49, -374.00),
				Vector3.new(1554.26, 18.42, -376.26),
				Vector3.new(1535.66, 18.02, -377.13),
				Vector3.new(1517.34, 18.13, -378.10),
				Vector3.new(1504.45, 18.47, -379.45),
				Vector3.new(1509.66, 18.22, -371.49),
				Vector3.new(1389.73, 18.35, -375.63),
				Vector3.new(1400.64, 18.56, -373.84),
				Vector3.new(1418.42, 18.19, -373.71),
				Vector3.new(1447.32, 18.18, -372.56),
				Vector3.new(1462.75, 18.36, -375.42),
				Vector3.new(1482.32, 23.28, -250.12),
				Vector3.new(1483.23, 23.28, -240.15),
				Vector3.new(1494.49, 23.28, -235.77),
				Vector3.new(1499.03, 23.28, -245.72),
				Vector3.new(1502.25, 23.28, -254.52),
				Vector3.new(1509.95, 23.28, -250.22),
				Vector3.new(1509.67, 23.28, -239.80),
				Vector3.new(1520.52, 23.28, -237.18),
				Vector3.new(1532.79, 23.28, -239.65),
				Vector3.new(1534.15, 23.28, -250.23),
				Vector3.new(1528.51, 23.28, -256.58),
				Vector3.new(1517.27, 23.28, -252.41),
				Vector3.new(1506.32, 23.28, -254.12),
				Vector3.new(1507.16, 17.63, -271.70),
				Vector3.new(1523.26, 17.63, -272.35),



			}
		}
	},
	[8] = {
		ChestValue = 1,
		TierWeights = {
			[1] = 60,
			[2] =90,
			[3] =90,
			[4] =90,
			[5] =4,
			[6] = 3,
			[7] = 2
		},
		Groups = {
			[1] = { 
				Vector3.new(2019.98, 34.16, 1534.77),
				Vector3.new(2049.03, 34.16, 1515.60),
				Vector3.new(2070.79, 34.16, 1503.96),
				Vector3.new(2079.27, 34.16, 1476.82),
				Vector3.new(2083.01, 34.16, 1411.15),
				Vector3.new(2076.90, 34.16, 1387.38),
				Vector3.new(2125.33, 34.16, 1360.85),
				Vector3.new(2103.27, 34.16, 1317.22),
				Vector3.new(2108.74, 34.24, 1276.43),
				Vector3.new(2081.33, 34.15, 1247.12),
				Vector3.new(2089.44, 34.16, 1202.97),
				Vector3.new(2054.93, 34.16, 1144.47),
				Vector3.new(2057.35, 34.16, 1115.06),
				Vector3.new(2011.24, 34.16, 1113.85),
				Vector3.new(1978.85, 34.16, 1098.09),
				Vector3.new(1951.12, 34.16, 1106.74),
				Vector3.new(1920.71, 34.16, 1120.67),
				Vector3.new(1964.45, 26.96, 1079.25),
				Vector3.new(1908.04, 26.96, 1041.02),
				Vector3.new(1874.39, 26.96, 1041.31),
				Vector3.new(1842.09, 26.96, 1028.91),
				Vector3.new(1826.11, 16.96, 1004.55),
				Vector3.new(1797.17, 16.96, 981.30),
				Vector3.new(1755.59, 16.96, 977.96),
				Vector3.new(1713.91, 16.96, 1010.67),
				Vector3.new(1674.90, 16.96, 1048.57),
				Vector3.new(1642.67, 17.46, 1086.44),
				Vector3.new(1632.48, 26.96, 1127.60),
				Vector3.new(1609.25, 26.96, 1161.78),
				Vector3.new(1598.08, 26.96, 1199.52),
				Vector3.new(1599.08, 34.16, 1221.30),
				Vector3.new(1579.89, 34.16, 1254.20),
				Vector3.new(1552.54, 34.16, 1310.58),
				Vector3.new(1553.67, 34.16, 1355.43),
				Vector3.new(1570.41, 34.16, 1382.17),
				Vector3.new(1591.45, 34.16, 1418.46),
				Vector3.new(1622.71, 34.16, 1452.29),
				Vector3.new(1644.42, 34.16, 1492.69),
				Vector3.new(1670.54, 34.16, 1553.75),
				Vector3.new(1722.57, 34.16, 1639.48),
				Vector3.new(1760.31, 34.16, 1662.18),
				Vector3.new(1829.17, 34.16, 1620.35),
				Vector3.new(1878.73, 34.16, 1586.64),
				Vector3.new(1931.16, 34.16, 1566.36),
				Vector3.new(1990.50, 34.16, 1546.23),
				Vector3.new(1983.01, 34.16, 1514.92),
				Vector3.new(1954.71, 34.16, 1436.92),
				Vector3.new(1984.52, 34.16, 1404.36),
				Vector3.new(2022.89, 34.16, 1374.01),
				Vector3.new(1998.02, 34.21, 1289.71),
				Vector3.new(2019.26, 34.16, 1215.08),
				Vector3.new(2004.52, 34.16, 1171.28),
				Vector3.new(1941.49, 34.16, 1239.52),
				Vector3.new(1867.00, 34.16, 1235.00),
				Vector3.new(1898.77, 34.16, 1173.90),
				Vector3.new(1870.64, 26.96, 1130.03),
				Vector3.new(1758.70, 26.96, 1133.21),
				Vector3.new(1725.30, 34.16, 1186.83),
				Vector3.new(1626.77, 34.16, 1233.51),
				Vector3.new(1598.49, 34.16, 1340.17),
				Vector3.new(1606.31, 34.16, 1412.53),
				Vector3.new(1658.70, 34.16, 1434.49),
				Vector3.new(1760.89, 34.16, 1456.65),
				Vector3.new(1843.01, 34.16, 1420.56),
				Vector3.new(1866.28, 34.16, 1393.64),
				Vector3.new(1886.27, 34.16, 1323.80),
				Vector3.new(1794.42, 52.26, 1312.92),
				Vector3.new(1811.27, 52.26, 1341.43),
				Vector3.new(1811.41, 52.26, 1381.41),
				Vector3.new(1800.64, 52.26, 1394.97),
				Vector3.new(1780.58, 52.26, 1396.76),
				Vector3.new(1740.86, 52.66, 1401.71),
				Vector3.new(1727.96, 52.66, 1410.98),
				Vector3.new(1711.17, 52.66, 1394.51),
				Vector3.new(1701.53, 52.66, 1400.55),
				Vector3.new(1675.97, 52.66, 1411.15),
				Vector3.new(1672.22, 52.66, 1395.99),
				Vector3.new(1768.63, 52.26, 1371.84),
				Vector3.new(1771.25, 52.26, 1351.18),
				Vector3.new(1785.06, 52.26, 1324.84),
				Vector3.new(1785.38, 52.26, 1301.36),
				Vector3.new(1806.79, 52.26, 1295.91),
				Vector3.new(1806.57, 52.26, 1272.68),
				Vector3.new(1814.57, 52.26, 1259.49),
				Vector3.new(1780.90, 52.26, 1286.42),
				Vector3.new(1757.59, 52.26, 1294.66),
				Vector3.new(1731.03, 52.26, 1285.88),
				Vector3.new(1717.06, 52.26, 1273.91),
				Vector3.new(1711.43, 52.26, 1255.83),
				Vector3.new(1695.68, 52.26, 1248.40),
				Vector3.new(1680.27, 52.26, 1258.05),
				Vector3.new(1676.76, 52.26, 1247.84),
				Vector3.new(1671.30, 52.26, 1267.83),
				Vector3.new(1681.18, 52.26, 1277.61),
				Vector3.new(1692.83, 52.26, 1287.59),
				Vector3.new(1691.92, 52.26, 1297.87),
				Vector3.new(1679.53, 52.26, 1298.81),
				Vector3.new(1727.88, 52.26, 1300.91),
				Vector3.new(1737.28, 52.26, 1309.54),
				Vector3.new(1747.30, 52.26, 1323.12),
				Vector3.new(1759.11, 52.26, 1324.25),
				Vector3.new(1773.69, 52.26, 1334.74),
				Vector3.new(1753.12, 52.26, 1332.21),
				Vector3.new(1730.56, 52.26, 1326.71),
				Vector3.new(1719.11, 52.26, 1336.51),
				Vector3.new(1732.79, 52.26, 1335.29),
				Vector3.new(1745.35, 52.26, 1343.62),
				Vector3.new(1746.33, 52.26, 1356.87),
				Vector3.new(1749.23, 52.26, 1373.01),
				Vector3.new(1727.89, 52.26, 1381.72),
				Vector3.new(1712.52, 52.26, 1379.55),
				Vector3.new(1679.49, 52.26, 1376.94),
				Vector3.new(1654.61, 52.24, 1393.87),
				Vector3.new(1644.06, 52.26, 1388.74),
				Vector3.new(1655.99, 52.26, 1344.48),
				Vector3.new(1670.40, 52.26, 1321.12),
				Vector3.new(1676.61, 52.26, 1309.22),
				Vector3.new(1671.92, 52.26, 1284.93),
				Vector3.new(1634.87, 52.66, 1310.35),
				Vector3.new(1653.91, 52.66, 1319.84),
				Vector3.new(1657.83, 52.66, 1301.83),
				Vector3.new(1651.50, 52.66, 1270.46),
				Vector3.new(1661.70, 52.66, 1247.91),
				Vector3.new(1739.57, 52.26, 1308.45),
				Vector3.new(1742.65, 52.26, 1324.92),
				Vector3.new(1765.28, 52.26, 1324.23),
				Vector3.new(1778.29, 52.26, 1304.50),
				Vector3.new(1817.33, 52.26, 1321.91),



			}
		}
	},
	[9] = {
		ChestValue = 1,
		TierWeights = {
			[1] = 30,
			[2] =100,
			[3] =130,
			[4] =80,
			[5] =30,
			[6] = 8,
			[7] = 3
		},
		Groups = {
			[1] = { 
				Vector3.new(-30.01, 15.09, 2110.53),
				Vector3.new(-16.06, 15.09, 2105.80),
				Vector3.new(-1.93, 15.09, 2108.27),
				Vector3.new(7.96, 15.09, 2108.62),
				Vector3.new(8.74, 15.09, 2118.84),
				Vector3.new(18.35, 15.09, 2120.08),
				Vector3.new(26.78, 15.09, 2115.95),
				Vector3.new(29.74, 15.09, 2107.82),
				Vector3.new(27.18, 15.09, 2096.48),
				Vector3.new(32.56, 15.09, 2097.42),
				Vector3.new(32.66, 15.09, 2107.22),
				Vector3.new(30.30, 15.09, 2119.33),
				Vector3.new(22.76, 15.09, 2121.22),
				Vector3.new(12.78, 15.09, 2126.26),
				Vector3.new(18.06, 15.09, 2130.93),
				Vector3.new(24.18, 15.09, 2136.17),
				Vector3.new(19.11, 15.09, 2150.39),
				Vector3.new(11.91, 15.09, 2153.70),
				Vector3.new(1.76, 15.09, 2147.53),
				Vector3.new(0.59, 15.09, 2138.81),
				Vector3.new(-3.93, 15.09, 2128.90),
				Vector3.new(-17.06, 15.09, 2127.90),
				Vector3.new(-28.20, 15.09, 2134.21),
				Vector3.new(-42.98, 15.09, 2133.21),
				Vector3.new(-47.01, 15.09, 2121.08),
				Vector3.new(-56.47, 15.09, 2125.04),
				Vector3.new(-59.60, 15.09, 2134.65),
				Vector3.new(-58.11, 15.09, 2145.75),
				Vector3.new(-61.58, 15.09, 2155.28),
				Vector3.new(-58.05, 15.09, 2164.91),
				Vector3.new(-52.97, 15.09, 2172.50),
				Vector3.new(-50.05, 15.09, 2181.91),
				Vector3.new(-44.72, 15.09, 2189.93),
				Vector3.new(-39.15, 15.09, 2197.80),
				Vector3.new(-36.34, 15.09, 2214.40),
				Vector3.new(-23.46, 15.09, 2230.86),
				Vector3.new(-17.03, 15.09, 2240.33),
				Vector3.new(-3.10, 15.09, 2229.00),
				Vector3.new(-0.07, 15.09, 2215.79),
				Vector3.new(6.74, 15.09, 2199.00),
				Vector3.new(8.38, 15.09, 2185.43),
				Vector3.new(11.82, 15.09, 2169.01),
				Vector3.new(22.07, 15.09, 2156.60),
				Vector3.new(31.86, 15.09, 2155.56),
				Vector3.new(37.01, 15.09, 2167.97),
				Vector3.new(47.37, 15.09, 2190.87),
				Vector3.new(62.25, 15.09, 2184.92),
				Vector3.new(80.31, 15.09, 2182.16),
				Vector3.new(87.46, 15.09, 2171.32),
				Vector3.new(83.68, 15.09, 2159.84),
				Vector3.new(73.56, 15.09, 2150.05),
				Vector3.new(71.54, 15.09, 2132.71),
				Vector3.new(73.55, 15.09, 2121.14),
				Vector3.new(75.01, 15.09, 2108.50),
				Vector3.new(74.55, 15.09, 2098.62),
				Vector3.new(72.79, 15.09, 2090.66),
				Vector3.new(78.86, 15.09, 2077.11),
				Vector3.new(81.07, 15.09, 2064.20),
				Vector3.new(91.59, 15.09, 2060.77),
				Vector3.new(103.10, 15.09, 2065.44),
				Vector3.new(114.17, 15.09, 2066.96),
				Vector3.new(120.58, 15.09, 2055.07),
				Vector3.new(127.13, 15.09, 2070.90),
				Vector3.new(122.52, 15.09, 2082.16),
				Vector3.new(124.01, 15.09, 2091.93),
				Vector3.new(128.96, 15.09, 2099.31),
				Vector3.new(115.32, 15.09, 2108.84),
				Vector3.new(123.04, 15.09, 2122.20),
				Vector3.new(125.44, 15.09, 2140.03),
				Vector3.new(112.57, 15.09, 2149.19),
				Vector3.new(105.19, 15.09, 2158.79),
				Vector3.new(93.71, 15.09, 2151.04),
				Vector3.new(91.95, 15.09, 2132.74),
				Vector3.new(94.42, 15.09, 2119.17),
				Vector3.new(85.82, 15.09, 2107.36),
				Vector3.new(118.07, 15.09, 2080.50),
				Vector3.new(120.13, 15.09, 2092.97),
				Vector3.new(126.87, 15.09, 2105.86),
				Vector3.new(138.10, 15.09, 2116.15),
				Vector3.new(148.57, 15.09, 2114.86),
				Vector3.new(156.14, 15.09, 2106.78),
				Vector3.new(167.95, 15.09, 2092.31),
				Vector3.new(180.93, 15.09, 2082.29),
				Vector3.new(190.95, 15.09, 2069.15),
				Vector3.new(191.94, 15.09, 2057.69),
				Vector3.new(181.21, 15.09, 2056.96),
				Vector3.new(171.62, 15.09, 2050.84),
				Vector3.new(163.50, 15.09, 2057.45),
				Vector3.new(151.15, 15.09, 2054.99),
				Vector3.new(160.21, 15.09, 2035.51),
				Vector3.new(170.91, 15.09, 2024.19),
				Vector3.new(179.25, 15.09, 2013.25),
				Vector3.new(189.93, 15.09, 2017.81),
				Vector3.new(194.66, 15.09, 2030.06),
				Vector3.new(205.95, 15.09, 2018.70),
				Vector3.new(209.74, 15.09, 2007.26),
				Vector3.new(215.47, 15.09, 1995.83),
				Vector3.new(221.57, 15.09, 2007.46),
				Vector3.new(224.28, 15.09, 2019.50),
				Vector3.new(219.15, 15.09, 2031.34),
				Vector3.new(209.72, 15.09, 2047.27),
				Vector3.new(196.21, 15.09, 2059.17),
				Vector3.new(181.18, 15.09, 2078.87),
				Vector3.new(164.47, 15.09, 2093.95),
				Vector3.new(155.14, 15.09, 2105.91),
				Vector3.new(138.41, 15.09, 2113.74),
				Vector3.new(123.36, 15.09, 2123.63),
				Vector3.new(122.03, 15.09, 2134.61),
				Vector3.new(138.36, 15.09, 2126.25),
				Vector3.new(114.43, 15.09, 2150.78),
				Vector3.new(95.79, 15.09, 2153.02),
				Vector3.new(77.82, 15.09, 2151.50),
				Vector3.new(60.65, 15.09, 2154.82),
				Vector3.new(62.33, 15.09, 2165.91),
				Vector3.new(58.50, 15.09, 2177.63),
				Vector3.new(99.42, 15.09, 2059.15),
				Vector3.new(99.36, 15.09, 2043.69),
				Vector3.new(110.77, 15.09, 2038.60),
				Vector3.new(126.62, 15.09, 2034.97),
				Vector3.new(152.22, 15.09, 2019.83),
				Vector3.new(167.09, 15.09, 2018.41),
				Vector3.new(188.85, 15.09, 2016.33),
				Vector3.new(206.83, 15.09, 2018.21),
				Vector3.new(218.81, 15.09, 2022.18),
				Vector3.new(217.36, 15.09, 2005.50),
				Vector3.new(230.39, 15.09, 2003.25),
				Vector3.new(229.48, 15.09, 1991.11),
				Vector3.new(224.95, 15.09, 1978.51),
				Vector3.new(233.94, 15.09, 1972.86),
				Vector3.new(248.09, 15.09, 1977.13),
				Vector3.new(243.36, 15.09, 1991.82),
				Vector3.new(241.34, 15.09, 1957.39),
				Vector3.new(231.18, 15.09, 1952.04),
				Vector3.new(222.23, 15.09, 1935.87),
				Vector3.new(211.17, 15.09, 1932.22),
				Vector3.new(197.91, 15.09, 1936.14),
				Vector3.new(182.39, 15.09, 1937.63),
				Vector3.new(182.18, 15.09, 1954.50),
				Vector3.new(193.24, 15.09, 1958.75),
				Vector3.new(192.65, 15.09, 1969.84),
				Vector3.new(195.37, 15.09, 1979.89),
				Vector3.new(180.85, 15.09, 1977.22),
				Vector3.new(167.65, 15.09, 1974.88),
				Vector3.new(161.03, 15.09, 1961.11),
				Vector3.new(148.51, 15.09, 1954.86),
				Vector3.new(135.81, 15.09, 1950.07),
				Vector3.new(124.37, 15.09, 1946.18),
				Vector3.new(118.02, 15.09, 1954.38),
				Vector3.new(115.89, 15.09, 1966.35),
				Vector3.new(105.29, 15.09, 1955.41),
				Vector3.new(92.07, 15.09, 1960.46),
				Vector3.new(86.94, 15.09, 1971.23),
				Vector3.new(88.51, 15.09, 1987.69),
				Vector3.new(89.93, 15.09, 2002.55),
				Vector3.new(99.29, 15.09, 2006.26),
				Vector3.new(103.26, 15.09, 2011.60),
				Vector3.new(80.84, 15.09, 2020.16),
				Vector3.new(70.82, 15.09, 2015.86),
				Vector3.new(68.65, 15.09, 2003.63),
				Vector3.new(71.10, 15.09, 1987.64),
				Vector3.new(65.20, 15.09, 1974.87),
				Vector3.new(51.78, 15.09, 1971.55),
				Vector3.new(43.33, 15.09, 1978.75),
				Vector3.new(40.24, 15.09, 1974.62),
				Vector3.new(36.95, 15.09, 1989.24),
				Vector3.new(33.45, 15.09, 2006.21),
				Vector3.new(31.62, 15.09, 2022.13),
				Vector3.new(19.34, 15.09, 2046.60),
				Vector3.new(18.69, 15.09, 2058.50),
				Vector3.new(16.51, 15.09, 2074.54),
				Vector3.new(4.02, 15.09, 2077.38),
				Vector3.new(-7.78, 15.09, 2070.45),
				Vector3.new(-19.06, 15.09, 2063.34),
				Vector3.new(-26.62, 15.09, 2053.30),
				Vector3.new(-17.92, 15.09, 2039.75),
				Vector3.new(-15.88, 15.09, 2026.61),
				Vector3.new(-9.76, 15.09, 2016.91),
				Vector3.new(-9.77, 15.09, 2004.66),
				Vector3.new(-1.32, 15.09, 1985.38),
				Vector3.new(11.32, 15.09, 1980.65),
				Vector3.new(7.27, 15.09, 1975.93),
				Vector3.new(-5.22, 15.09, 1972.96),
				Vector3.new(-18.50, 15.09, 1984.47),
				Vector3.new(-30.42, 15.09, 1985.49),
				Vector3.new(-46.91, 15.09, 1971.91),
				Vector3.new(-54.05, 15.09, 1978.88),
				Vector3.new(-66.55, 15.09, 1984.67),
				Vector3.new(-78.65, 15.09, 1975.70),
				Vector3.new(-92.32, 14.18, 1976.23),
				Vector3.new(-90.56, 15.09, 1993.19),
				Vector3.new(-91.99, 15.09, 2008.19),
				Vector3.new(-96.66, 15.09, 2020.90),
				Vector3.new(-108.13, 15.09, 2025.54),
				Vector3.new(-113.30, 15.09, 2022.57),
				Vector3.new(-103.18, 15.09, 2034.20),
				Vector3.new(-94.28, 15.09, 2045.10),
				Vector3.new(-91.62, 15.09, 2056.81),
				Vector3.new(-97.22, 15.09, 2066.85),
				Vector3.new(-95.91, 15.09, 2078.83),
				Vector3.new(-87.60, 15.09, 2085.92),
				Vector3.new(-86.19, 15.09, 2097.60),
				Vector3.new(-94.09, 15.09, 2112.49),
				Vector3.new(-70.16, 15.09, 2128.98),
				Vector3.new(-59.56, 15.09, 2135.65),
				Vector3.new(-40.34, 15.09, 2157.06),
				Vector3.new(-29.16, 15.09, 2180.85),
				Vector3.new(-18.43, 15.09, 2208.58),
				Vector3.new(-26.18, 15.09, 2227.00),
				Vector3.new(-41.20, 15.09, 2240.32),
				Vector3.new(-52.68, 15.09, 2228.99),
				Vector3.new(-66.60, 15.09, 2223.76),
				Vector3.new(-72.80, 15.09, 2242.45),
				Vector3.new(-83.05, 15.09, 2253.14),
				Vector3.new(-95.68, 15.09, 2251.04),
				Vector3.new(-97.89, 15.09, 2240.08),
				Vector3.new(-97.81, 15.09, 2224.84),
				Vector3.new(-93.28, 15.09, 2208.36),
				Vector3.new(-83.76, 15.09, 2193.25),
				Vector3.new(-86.89, 15.09, 2183.17),
				Vector3.new(-101.56, 15.09, 2173.93),
				Vector3.new(-100.44, 15.09, 2164.01),
				Vector3.new(-85.99, 15.09, 2153.71),
				Vector3.new(-82.21, 15.09, 2140.13),
				Vector3.new(-78.44, 15.09, 2126.27),
				Vector3.new(-86.63, 15.09, 2115.25),
				Vector3.new(-87.02, 15.09, 2101.23),
				Vector3.new(-77.35, 15.09, 2085.89),
				Vector3.new(-78.83, 15.09, 2073.13),
				Vector3.new(-89.80, 15.09, 2063.70),
				Vector3.new(-103.00, 15.09, 2050.25),
				Vector3.new(-116.76, 15.09, 2041.57),
				Vector3.new(-128.64, 15.09, 2043.47),
				Vector3.new(-130.29, 15.09, 2061.19),
				Vector3.new(-135.77, 15.09, 2070.88),
				Vector3.new(-138.42, 15.09, 2086.30),
				Vector3.new(-144.47, 15.09, 2099.89),
				Vector3.new(-147.49, 15.09, 2122.03),
				Vector3.new(-144.86, 15.09, 2136.98),
				Vector3.new(-162.17, 15.09, 2147.92),
				Vector3.new(-165.93, 15.09, 2164.83),
				Vector3.new(-155.23, 15.09, 2174.76),
				Vector3.new(-152.45, 15.09, 2191.24),
				Vector3.new(-155.52, 15.09, 2213.09),
				Vector3.new(-168.32, 15.09, 2219.01),
				Vector3.new(-180.87, 15.09, 2206.16),
				Vector3.new(-200.03, 15.09, 2190.44),
				Vector3.new(-200.59, 15.09, 2179.92),
				Vector3.new(-203.57, 15.09, 2162.28),
				Vector3.new(-197.73, 15.09, 2151.15),
				Vector3.new(-203.72, 15.09, 2131.48),
				Vector3.new(-200.64, 15.09, 2114.35),
				Vector3.new(-198.30, 15.09, 2102.25),
				Vector3.new(-201.63, 15.09, 2087.54),
				Vector3.new(-196.01, 15.09, 2071.38),
				Vector3.new(-196.33, 15.09, 2052.32),
				Vector3.new(-192.10, 15.09, 2037.30),
				Vector3.new(-178.59, 15.09, 2029.73),
				Vector3.new(-146.74, 15.09, 2036.23),
				Vector3.new(-120.64, 15.09, 2039.55),
				Vector3.new(-207.05, 15.09, 2031.13),
				Vector3.new(-215.36, 15.09, 2037.54),
				Vector3.new(-225.60, 15.09, 2053.78),
				Vector3.new(-223.30, 15.09, 2068.43),
				Vector3.new(-230.16, 15.09, 2082.25),
				Vector3.new(-238.75, 15.09, 2093.30),
				Vector3.new(-235.86, 15.09, 2106.06),
				Vector3.new(-228.50, 15.09, 2117.00),
				Vector3.new(-220.22, 15.09, 2127.29),
				Vector3.new(-221.81, 15.09, 2140.77),
				Vector3.new(-217.86, 15.09, 2158.21),
				Vector3.new(-208.40, 15.09, 2164.95),
				Vector3.new(-200.00, 15.09, 2162.32),
				Vector3.new(-204.12, 15.09, 2141.35),
				Vector3.new(-213.94, 15.09, 2125.96),
				Vector3.new(-263.02, 15.09, 2085.19),
				Vector3.new(-277.52, 15.09, 2083.70),
				Vector3.new(-296.53, 15.09, 2087.91),
				Vector3.new(-305.17, 15.09, 2082.73),
				Vector3.new(-303.62, 15.09, 2072.50),
				Vector3.new(-300.70, 15.09, 2059.46),
				Vector3.new(-315.49, 15.09, 2058.91),
				Vector3.new(-332.35, 15.09, 2057.43),
				Vector3.new(-334.04, 15.09, 2027.07),
				Vector3.new(-323.65, 15.09, 2030.26),
				Vector3.new(-309.54, 15.09, 2034.85),
				Vector3.new(-299.57, 15.09, 2050.89),
				Vector3.new(-287.81, 15.09, 2054.80),
				Vector3.new(-277.66, 15.09, 2046.86),
				Vector3.new(-274.79, 15.09, 2035.38),
				Vector3.new(-260.24, 15.09, 2015.48),
				Vector3.new(-253.10, 15.09, 2023.09),
				Vector3.new(-278.95, 15.09, 2008.20),
				Vector3.new(-279.47, 15.09, 1999.65),
				Vector3.new(-286.82, 15.09, 1989.17),
				Vector3.new(-282.08, 15.09, 1978.25),
				Vector3.new(-277.56, 15.09, 1957.43),
				Vector3.new(-277.79, 15.09, 1941.96),
				Vector3.new(-286.35, 15.09, 1940.91),
				Vector3.new(-298.34, 15.09, 1936.98),
				Vector3.new(-309.46, 15.09, 1933.66),
				Vector3.new(-312.80, 15.09, 1941.71),
				Vector3.new(-299.88, 15.09, 1945.16),
				Vector3.new(-300.23, 15.09, 1956.86),
				Vector3.new(-311.28, 15.09, 1958.70),
				Vector3.new(-319.84, 15.09, 1964.52),
				Vector3.new(-336.17, 15.09, 1962.93),
				Vector3.new(-349.95, 15.09, 1969.23),
				Vector3.new(-361.77, 15.09, 1987.21),
				Vector3.new(-372.98, 15.09, 1993.93),
				Vector3.new(-382.14, 15.09, 1993.26),
				Vector3.new(-387.09, 15.09, 1980.67),
				Vector3.new(-379.21, 15.09, 1971.84),
				Vector3.new(-366.03, 15.09, 1964.10),
				Vector3.new(-352.19, 15.09, 1943.13),
				Vector3.new(-339.06, 15.09, 1929.31),
				Vector3.new(-324.35, 15.09, 1918.46),
				Vector3.new(-336.67, 15.09, 1911.21),
				Vector3.new(-356.28, 15.09, 1913.94),
				Vector3.new(-367.23, 15.09, 1912.08),
				Vector3.new(-385.92, 15.09, 1917.48),
				Vector3.new(-402.01, 15.09, 1924.74),
				Vector3.new(-415.94, 15.09, 1915.62),
				Vector3.new(-412.76, 15.09, 1901.70),
				Vector3.new(-397.88, 15.09, 1894.83),
				Vector3.new(-383.94, 15.09, 1892.23),
				Vector3.new(-360.86, 15.09, 1889.78),
				Vector3.new(-346.62, 15.09, 1895.97),
				Vector3.new(-317.35, 15.09, 1899.56),
				Vector3.new(-321.35, 15.09, 1887.68),
				Vector3.new(-331.06, 15.09, 1884.86),
				Vector3.new(-339.19, 15.09, 1879.56),
				Vector3.new(-361.09, 15.09, 1878.33),
				Vector3.new(-399.67, 15.09, 1868.21),
				Vector3.new(-418.98, 15.09, 1858.81),
				Vector3.new(-421.73, 15.09, 1841.12),
				Vector3.new(-403.35, 15.09, 1826.36),
				Vector3.new(-371.35, 15.09, 1825.82),
				Vector3.new(-348.73, 15.09, 1822.07),
				Vector3.new(-329.53, 15.09, 1818.88),
				Vector3.new(-313.11, 15.09, 1829.86),
				Vector3.new(-291.39, 15.09, 1833.01),
				Vector3.new(-290.63, 15.09, 1813.46),
				Vector3.new(-286.93, 15.09, 1789.66),
				Vector3.new(-286.81, 15.09, 1777.48),
				Vector3.new(-298.75, 15.09, 1777.70),
				Vector3.new(-310.98, 15.09, 1785.08),
				Vector3.new(-327.75, 15.09, 1782.14),
				Vector3.new(-363.00, 15.09, 1787.99),
				Vector3.new(-385.17, 15.09, 1794.97),
				Vector3.new(-411.39, 15.09, 1793.60),
				Vector3.new(-407.74, 15.09, 1767.80),
				Vector3.new(-377.44, 15.09, 1740.97),
				Vector3.new(-352.65, 15.09, 1742.49),
				Vector3.new(-346.23, 15.09, 1742.04),
				Vector3.new(-325.30, 15.09, 1732.30),
				Vector3.new(-308.46, 15.09, 1724.39),
				Vector3.new(-291.61, 15.09, 1729.19),
				Vector3.new(-268.47, 15.09, 1731.89),
				Vector3.new(-245.18, 15.09, 1728.40),
				Vector3.new(-244.35, 15.09, 1714.89),
				Vector3.new(-254.97, 15.09, 1707.29),
				Vector3.new(-260.65, 15.09, 1694.38),
				Vector3.new(-253.83, 15.09, 1684.83),
				Vector3.new(-255.52, 15.09, 1675.26),
				Vector3.new(-264.39, 15.09, 1675.35),
				Vector3.new(-284.64, 15.09, 1673.22),
				Vector3.new(-306.17, 15.09, 1663.57),
				Vector3.new(-339.51, 15.09, 1667.82),
				Vector3.new(-350.32, 15.09, 1657.14),
				Vector3.new(-339.86, 15.09, 1642.11),
				Vector3.new(-314.96, 15.09, 1636.59),
				Vector3.new(-289.67, 15.09, 1636.59),
				Vector3.new(-278.91, 15.09, 1643.59),
				Vector3.new(-268.39, 15.09, 1638.44),
				Vector3.new(-265.07, 15.09, 1626.57),
				Vector3.new(-265.60, 15.09, 1614.76),
				Vector3.new(-284.30, 15.09, 1597.68),
				Vector3.new(-293.25, 15.09, 1582.07),
				Vector3.new(-283.81, 15.09, 1571.31),
				Vector3.new(-256.02, 15.09, 1579.07),
				Vector3.new(-246.09, 15.09, 1561.74),
				Vector3.new(-223.64, 15.09, 1561.80),
				Vector3.new(-206.91, 15.09, 1564.89),
				Vector3.new(-208.04, 15.09, 1576.95),
				Vector3.new(-221.54, 15.09, 1588.37),
				Vector3.new(-214.72, 15.09, 1604.43),
				Vector3.new(-200.01, 15.09, 1619.65),
				Vector3.new(-195.78, 15.09, 1635.24),
				Vector3.new(-202.89, 15.09, 1648.01),
				Vector3.new(-184.62, 15.09, 1649.04),
				Vector3.new(-148.36, 15.09, 1641.49),
				Vector3.new(-124.10, 15.09, 1626.37),
				Vector3.new(-105.98, 15.09, 1633.29),
				Vector3.new(-87.57, 15.09, 1630.23),
				Vector3.new(-84.67, 15.09, 1616.07),
				Vector3.new(-85.19, 15.09, 1598.00),
				Vector3.new(-85.53, 15.09, 1585.28),
				Vector3.new(-100.02, 15.09, 1567.90),
				Vector3.new(-98.36, 15.09, 1546.07),
				Vector3.new(-107.30, 15.09, 1531.03),
				Vector3.new(-119.47, 15.09, 1528.99),
				Vector3.new(-130.71, 15.09, 1537.97),
				Vector3.new(-142.67, 15.09, 1535.29),
				Vector3.new(-156.24, 15.09, 1538.49),
				Vector3.new(-172.44, 15.09, 1547.20),
				Vector3.new(-187.65, 15.09, 1546.92),
				Vector3.new(-215.19, 15.09, 1563.49),
				Vector3.new(-209.20, 15.09, 1581.23),
				Vector3.new(-205.80, 15.09, 1594.06),
				Vector3.new(-212.24, 15.09, 1606.86),
				Vector3.new(-199.12, 15.09, 1616.03),
				Vector3.new(-175.90, 15.09, 1604.98),
				Vector3.new(-177.47, 15.09, 1595.51),
				Vector3.new(-168.18, 15.09, 1591.95),
				Vector3.new(-166.53, 15.09, 1582.28),
				Vector3.new(-160.18, 15.09, 1576.73),
				Vector3.new(-161.53, 15.09, 1566.05),
				Vector3.new(-154.23, 15.09, 1562.39),
				Vector3.new(-147.33, 15.09, 1568.70),
				Vector3.new(-136.21, 15.09, 1572.50),
				Vector3.new(-135.78, 15.09, 1579.68),
				Vector3.new(-142.49, 15.09, 1590.26),
				Vector3.new(-140.93, 15.09, 1600.49),
				Vector3.new(-152.25, 15.09, 1607.01),
				Vector3.new(-154.93, 15.09, 1616.98),
				Vector3.new(-163.94, 15.09, 1621.40),
				Vector3.new(-167.18, 15.09, 1634.52),
				Vector3.new(-151.38, 15.09, 1628.76),
				Vector3.new(-136.96, 15.09, 1608.57),
				Vector3.new(-120.94, 15.09, 1595.14),
				Vector3.new(-119.67, 15.09, 1579.30),
				Vector3.new(-124.21, 15.09, 1562.32),
				Vector3.new(-122.78, 15.09, 1550.77),
				Vector3.new(-146.26, 15.09, 1548.73),
				Vector3.new(-148.37, 15.09, 1563.66),
				Vector3.new(-140.35, 15.09, 1572.01),
				Vector3.new(-107.37, 15.09, 1582.91),
				Vector3.new(-94.59, 15.09, 1572.84),
				Vector3.new(-64.65, 15.09, 1626.88),
				Vector3.new(-56.99, 15.09, 1619.07),
				Vector3.new(-55.61, 15.09, 1609.00),
				Vector3.new(-49.62, 15.09, 1600.39),
				Vector3.new(-25.52, 15.09, 1565.34),
				Vector3.new(-14.78, 15.09, 1554.39),
				Vector3.new(-15.68, 15.09, 1543.86),
				Vector3.new(0.94, 15.09, 1527.21),
				Vector3.new(30.74, 15.09, 1526.07),
				Vector3.new(39.26, 15.09, 1550.28),
				Vector3.new(36.91, 15.09, 1569.15),
				Vector3.new(36.69, 15.09, 1592.58),
				Vector3.new(26.08, 15.09, 1607.43),
				Vector3.new(31.70, 15.09, 1623.78),
				Vector3.new(25.44, 14.98, 1640.27),
				Vector3.new(1.00, 15.35, 1655.22),
				Vector3.new(-26.68, 15.35, 1658.11),
				Vector3.new(-45.35, 15.35, 1658.28),
				Vector3.new(-53.89, 15.35, 1669.79),
				Vector3.new(-53.29, 15.35, 1693.77),
				Vector3.new(-47.22, 15.35, 1723.85),
				Vector3.new(-39.53, 15.35, 1719.74),
				Vector3.new(-31.75, 15.35, 1704.81),
				Vector3.new(-18.29, 15.35, 1684.57),
				Vector3.new(-13.15, 15.35, 1700.56),
				Vector3.new(-1.40, 15.35, 1712.16),
				Vector3.new(9.72, 15.35, 1710.85),
				Vector3.new(12.75, 15.35, 1685.77),
				Vector3.new(24.16, 13.85, 1656.65),
				Vector3.new(39.24, 13.85, 1656.22),
				Vector3.new(67.67, 13.85, 1664.76),
				Vector3.new(81.83, 13.85, 1680.69),
				Vector3.new(72.38, 13.85, 1693.35),
				Vector3.new(55.90, 13.85, 1705.58),
				Vector3.new(45.44, 13.85, 1711.21),
				Vector3.new(33.97, 13.85, 1711.31),
				Vector3.new(61.85, 13.85, 1722.96),
				Vector3.new(72.57, 13.85, 1729.41),
				Vector3.new(92.81, 13.85, 1738.89),
				Vector3.new(94.85, 13.85, 1729.09),
				Vector3.new(106.59, 15.09, 1708.98),
				Vector3.new(104.83, 15.09, 1697.12),
				Vector3.new(108.45, 15.09, 1680.25),
				Vector3.new(108.20, 15.09, 1653.71),
				Vector3.new(102.20, 15.09, 1636.99),
				Vector3.new(105.95, 15.09, 1614.59),
				Vector3.new(111.39, 15.09, 1597.67),
				Vector3.new(120.81, 15.09, 1599.54),
				Vector3.new(123.23, 15.09, 1589.99),
				Vector3.new(122.33, 15.09, 1580.20),
				Vector3.new(116.59, 15.09, 1565.51),
				Vector3.new(130.46, 15.09, 1552.12),
				Vector3.new(115.12, 15.09, 1532.33),
				Vector3.new(135.08, 15.09, 1532.08),
				Vector3.new(149.61, 15.09, 1538.86),
				Vector3.new(170.12, 15.09, 1557.25),
				Vector3.new(159.47, 15.09, 1568.10),
				Vector3.new(149.24, 15.09, 1594.98),
				Vector3.new(153.78, 15.09, 1610.98),
				Vector3.new(177.95, 15.09, 1616.33),
				Vector3.new(173.63, 15.09, 1605.68),
				Vector3.new(167.63, 15.09, 1595.64),
				Vector3.new(180.76, 15.09, 1588.84),
				Vector3.new(184.98, 15.09, 1607.37),
				Vector3.new(197.63, 15.09, 1618.42),
				Vector3.new(197.19, 15.09, 1606.19),
				Vector3.new(197.06, 15.09, 1592.06),
				Vector3.new(204.84, 15.09, 1576.60),
				Vector3.new(195.56, 15.09, 1566.63),
				Vector3.new(192.61, 15.09, 1553.69),
				Vector3.new(179.12, 15.09, 1541.70),
				Vector3.new(177.48, 15.09, 1540.91),
				Vector3.new(198.74, 15.09, 1542.88),
				Vector3.new(214.33, 15.09, 1545.06),
				Vector3.new(218.56, 15.09, 1553.54),
				Vector3.new(211.91, 15.09, 1563.34),
				Vector3.new(215.17, 15.09, 1579.95),
				Vector3.new(210.41, 15.09, 1597.29),
				Vector3.new(218.46, 15.09, 1605.35),
				Vector3.new(231.44, 15.09, 1599.82),
				Vector3.new(239.43, 15.09, 1588.30),
				Vector3.new(246.86, 15.09, 1570.31),
				Vector3.new(245.23, 15.09, 1557.35),
				Vector3.new(261.93, 15.09, 1572.98),
				Vector3.new(268.18, 15.09, 1584.35),
				Vector3.new(264.46, 15.09, 1595.60),
				Vector3.new(275.08, 15.09, 1605.92),
				Vector3.new(285.74, 15.09, 1609.78),
				Vector3.new(289.64, 15.09, 1601.66),
				Vector3.new(280.04, 15.09, 1591.85),
				Vector3.new(303.74, 15.09, 1615.22),
				Vector3.new(294.63, 15.09, 1636.68),
				Vector3.new(298.64, 15.09, 1662.43),
				Vector3.new(288.02, 15.09, 1669.91),
				Vector3.new(269.89, 15.09, 1670.07),
				Vector3.new(257.62, 15.09, 1670.19),
				Vector3.new(236.08, 15.09, 1663.65),
				Vector3.new(218.47, 15.09, 1663.19),
				Vector3.new(205.25, 15.09, 1658.41),
				Vector3.new(198.03, 15.09, 1674.14),
				Vector3.new(186.35, 15.09, 1681.61),
				Vector3.new(170.60, 15.09, 1683.59),
				Vector3.new(167.55, 15.09, 1700.16),
				Vector3.new(148.04, 15.09, 1690.40),
				Vector3.new(130.28, 15.09, 1711.84),
				Vector3.new(146.11, 15.09, 1722.25),
				Vector3.new(167.48, 15.09, 1729.22),
				Vector3.new(192.26, 15.09, 1737.61),
				Vector3.new(205.11, 15.09, 1752.77),
				Vector3.new(221.04, 15.09, 1736.93),
				Vector3.new(235.74, 15.09, 1729.14),
				Vector3.new(241.03, 15.09, 1710.40),
				Vector3.new(265.20, 15.09, 1704.90),
				Vector3.new(282.82, 15.09, 1706.00),
				Vector3.new(289.94, 15.09, 1699.92),
				Vector3.new(294.12, 15.09, 1688.85),
				Vector3.new(290.60, 15.09, 1675.49),
				Vector3.new(299.12, 15.09, 1667.43),
				Vector3.new(305.35, 15.09, 1654.01),
				Vector3.new(319.49, 15.09, 1653.26),
				Vector3.new(336.27, 15.09, 1665.34),
				Vector3.new(335.87, 15.09, 1677.13),
				Vector3.new(325.22, 15.09, 1687.98),
				Vector3.new(313.45, 15.09, 1699.98),
				Vector3.new(316.40, 15.09, 1714.92),
				Vector3.new(316.86, 15.09, 1732.32),
				Vector3.new(287.19, 15.09, 1736.07),
				Vector3.new(261.67, 15.09, 1758.77),
				Vector3.new(239.39, 15.09, 1769.97),
				Vector3.new(217.68, 15.09, 1776.36),
				Vector3.new(235.04, 15.09, 1786.45),
				Vector3.new(232.56, 15.09, 1799.83),
				Vector3.new(250.55, 15.09, 1803.30),
				Vector3.new(272.50, 15.09, 1802.40),
				Vector3.new(293.98, 15.09, 1803.84),
				Vector3.new(302.56, 15.09, 1818.13),
				Vector3.new(293.48, 15.09, 1828.81),
				Vector3.new(276.15, 15.09, 1826.01),
				Vector3.new(278.20, 15.09, 1836.75),
				Vector3.new(285.60, 15.09, 1857.96),
				Vector3.new(302.91, 15.09, 1862.63),
				Vector3.new(314.27, 15.09, 1847.28),
				Vector3.new(322.07, 15.09, 1834.49),
				Vector3.new(332.44, 15.09, 1808.26),
				Vector3.new(332.13, 15.09, 1774.80),
				Vector3.new(321.75, 15.09, 1825.55),
				Vector3.new(296.10, 15.09, 1831.22),
				Vector3.new(280.33, 15.09, 1825.56),
				Vector3.new(251.13, 15.09, 1825.89),
				Vector3.new(251.57, 15.09, 1849.04),
				Vector3.new(248.44, 15.09, 1874.06),
				Vector3.new(245.21, 15.09, 1888.85),
				Vector3.new(253.79, 15.09, 1894.18),
				Vector3.new(267.90, 15.09, 1893.41),
				Vector3.new(280.47, 15.09, 1905.16),
				Vector3.new(268.69, 15.09, 1911.17),
				Vector3.new(276.37, 15.09, 1927.09),
				Vector3.new(287.91, 15.09, 1919.20),
				Vector3.new(279.19, 15.09, 1940.90),
				Vector3.new(266.82, 15.09, 1943.00),
				Vector3.new(246.43, 15.09, 1943.42),
				Vector3.new(244.27, 15.09, 1956.81),
				Vector3.new(253.88, 15.09, 1973.84),
				Vector3.new(247.26, 15.09, 1986.54),
				Vector3.new(228.98, 15.09, 1986.98),
				Vector3.new(218.14, 15.09, 1980.20),
				Vector3.new(206.38, 15.09, 1966.18),
				Vector3.new(193.32, 15.09, 1958.76),
				Vector3.new(179.96, 15.09, 1956.64),
				Vector3.new(189.44, 15.09, 1937.46),
				Vector3.new(188.68, 15.09, 1923.34),
				Vector3.new(176.83, 15.09, 1912.88),
				Vector3.new(170.49, 15.09, 1896.34),
				Vector3.new(169.71, 15.09, 1881.81),
				Vector3.new(173.18, 15.09, 1870.14),
				Vector3.new(156.20, 15.09, 1851.79),
				Vector3.new(176.53, 15.09, 1840.66),
				Vector3.new(190.28, 15.09, 1834.77),
				Vector3.new(198.91, 15.09, 1849.08),
				Vector3.new(206.86, 15.09, 1841.25),
				Vector3.new(239.68, 15.09, 1818.67),
				Vector3.new(167.99, 15.09, 1934.63),
				Vector3.new(153.33, 15.09, 1948.19),
				Vector3.new(146.49, 15.09, 1964.66),
				Vector3.new(165.84, 15.09, 1975.71),
				Vector3.new(184.00, 15.09, 1979.14),
				Vector3.new(89.16, 16.85, 1916.47),
				Vector3.new(71.50, 16.85, 1901.84),
				Vector3.new(61.83, 16.85, 1871.31),
				Vector3.new(66.72, 16.85, 1852.69),
				Vector3.new(52.19, 16.85, 1840.09),
				Vector3.new(34.12, 16.85, 1755.57),
				Vector3.new(49.59, 16.85, 1758.84),
				Vector3.new(74.67, 16.85, 1770.11),
				Vector3.new(11.97, 28.85, 1811.85),
				Vector3.new(11.34, 28.85, 1828.76),
				Vector3.new(-1.64, 28.85, 1831.03),
				Vector3.new(-9.76, 28.85, 1841.40),
				Vector3.new(4.89, 28.85, 1843.99),
				Vector3.new(14.86, 28.85, 1841.05),
				Vector3.new(-20.36, 28.85, 1819.18),
				Vector3.new(-18.33, 28.85, 1796.84),
				Vector3.new(-14.54, 28.85, 1780.04),
				Vector3.new(0.67, 28.85, 1793.28),
				Vector3.new(11.48, 28.85, 1781.50),
				Vector3.new(35.77, 16.85, 1757.04),
				Vector3.new(-27.48, 30.35, 1895.51),
				Vector3.new(-10.07, 30.35, 1895.75),
				Vector3.new(-43.49, 30.35, 1927.54),
				Vector3.new(-57.00, 30.35, 1934.37),
				Vector3.new(-79.90, 28.85, 1859.39),
				Vector3.new(-68.97, 28.85, 1849.41),
				Vector3.new(-76.54, 28.85, 1839.62),
				Vector3.new(-70.40, 28.85, 1819.84),
				Vector3.new(-85.88, 28.85, 1804.55),
				Vector3.new(-87.28, 28.85, 1797.39),
				Vector3.new(-95.67, 28.85, 1805.89),
				Vector3.new(-94.72, 28.85, 1815.64),
				Vector3.new(-91.81, 28.85, 1813.15),
				Vector3.new(-103.94, 28.85, 1806.12),
				Vector3.new(-163.12, 55.65, 1826.00),
				Vector3.new(-164.89, 55.65, 1812.22),
				Vector3.new(-149.01, 55.65, 1822.48),
				Vector3.new(-170.78, 55.65, 1819.50),
				Vector3.new(-183.48, 55.65, 1816.39),
				Vector3.new(-196.55, 55.65, 1819.76),
				Vector3.new(-218.37, 55.65, 1821.79),
				Vector3.new(-229.07, 55.65, 1821.85),
				Vector3.new(-207.40, 55.65, 1837.43),
				Vector3.new(-223.16, 55.65, 1867.69),
				Vector3.new(-215.63, 55.65, 1882.56),
				Vector3.new(-207.40, 55.65, 1879.99),
				Vector3.new(-193.07, 55.65, 1878.41),
				Vector3.new(-177.66, 55.65, 1870.01),
				Vector3.new(-188.41, 55.65, 1861.43),
				Vector3.new(-193.81, 55.65, 1850.93),
				Vector3.new(-180.86, 55.65, 1838.96),
				Vector3.new(-177.64, 55.65, 1820.67),
				Vector3.new(-182.34, 140.85, 1996.84),
				Vector3.new(-196.98, 140.85, 1991.63),
				Vector3.new(-232.58, 140.85, 1985.77),
				Vector3.new(-190.87, 140.85, 1979.24),
				Vector3.new(-144.91, 135.85, 1993.61),
				Vector3.new(-124.14, 135.85, 1994.95),
				Vector3.new(-130.50, 135.85, 1982.64),
				Vector3.new(-146.56, 135.85, 1969.32),
				Vector3.new(-124.13, 135.85, 1970.96),
				Vector3.new(-147.40, 119.65, 1930.02),
				Vector3.new(-166.42, 110.09, 1910.60),
				Vector3.new(-110.09, 82.92, 1863.03),
				Vector3.new(-96.58, 85.09, 1860.79),
				Vector3.new(-86.83, 77.07, 1872.88),
				Vector3.new(-108.71, 75.16, 1901.56),
				Vector3.new(-112.61, 75.12, 1919.88),
				Vector3.new(-133.27, 74.25, 1927.27),
				Vector3.new(-150.33, 74.25, 1930.59),
				Vector3.new(-153.51, 74.25, 1944.09),
				Vector3.new(-173.65, 71.85, 1945.69),
				Vector3.new(-186.98, 68.65, 1937.53),
				Vector3.new(-199.33, 55.65, 1873.80),



			}
		}
	},
	[10] = {
		ChestValue = 1,
		TierWeights = {
			[1] = 0,
			[2] = 0,
			[3] = 0,
			[4] =90,
			[5] =90,
			[6] = 90,
			[7] = 40
		},
		Groups = {
			[1] = { 
				Vector3.new(-1468.56, 59.40, -640.45),
				Vector3.new(-1522.52, 21.95, -620.40),
				Vector3.new(-1499.65, 21.89, -657.59),
				Vector3.new(-1410.90, 17.16, -720.48),
				Vector3.new(-1397.44, 21.56, -669.94),
				Vector3.new(-1348.04, 17.50, -632.89),
				Vector3.new(-1398.32, 43.33, -631.72),
				Vector3.new(-1399.70, 21.85, -576.69),
				Vector3.new(-1426.25, 16.82, -535.12),
				Vector3.new(-1477.97, 16.70, -543.07),
				Vector3.new(-894.17, 15.63, 2037.71),
				Vector3.new(-866.90, 15.63, 2019.09),
				Vector3.new(-884.38, 15.63, 2015.54),
				Vector3.new(-868.67, 15.69, 2038.46),
				Vector3.new(-113.64, 16.97, 3044.20),
				Vector3.new(-22.95, 16.25, 3011.39),
				Vector3.new(14.98, 16.16, 3011.79),
				Vector3.new(30.64, 15.14, 3031.20),
				Vector3.new(12.65, 18.59, 3056.01),
				Vector3.new(-15.55, 17.25, 3058.85),
				Vector3.new(-17.65, 15.27, 3071.83),
				Vector3.new(-19.00, 13.91, 3088.15),
				Vector3.new(-31.90, 13.65, 3090.17),
				Vector3.new(-52.62, 13.85, 3118.14),
				Vector3.new(-61.63, 14.86, 3107.98),
				Vector3.new(-79.43, 15.76, 3117.24),
				Vector3.new(-95.84, 19.05, 3097.91),
				Vector3.new(-47.82, 29.36, 3039.45),
				Vector3.new(-71.39, 57.54, 3035.31),
				Vector3.new(-83.58, 47.05, 3047.54),
				Vector3.new(-1269.08, 73.66, 2820.86),
				Vector3.new(-1244.78, 73.66, 2827.35),
				Vector3.new(-1230.66, 73.66, 2893.85),
				Vector3.new(-1261.48, 73.66, 2921.39),
				Vector3.new(-1296.51, 73.66, 2894.15),
				Vector3.new(-1355.92, 54.46, 2861.33),
				Vector3.new(-1269.94, 54.46, 3008.62),
				Vector3.new(-1236.83, 73.69, 3055.66),
				Vector3.new(-1174.47, 73.66, 3034.48),
				Vector3.new(-1234.69, 73.66, 3151.86),
				Vector3.new(-1210.61, 54.46, 3798.31),
				Vector3.new(-1236.35, 54.46, 3782.36),
				Vector3.new(-1290.12, 54.47, 3842.74),
				Vector3.new(-1304.07, 54.46, 3841.79),
				Vector3.new(-1291.85, 73.66, 3887.12),
				Vector3.new(-1217.67, 73.66, 3874.58),
				Vector3.new(-1303.03, 73.66, 3948.29),
				Vector3.new(-1382.10, 73.66, 3929.29),
				Vector3.new(-1460.65, 73.66, 3952.32),
				Vector3.new(-1430.33, 54.46, 3877.36),
				Vector3.new(-2390.88, 54.46, 3937.54),
				Vector3.new(-2373.41, 54.46, 3933.64),
				Vector3.new(-2425.44, 54.46, 3857.51),
				Vector3.new(-2449.47, 73.66, 3921.24),
				Vector3.new(-2493.96, 73.66, 3879.26),
				Vector3.new(-2494.99, 73.66, 3822.69),
				Vector3.new(-2546.98, 73.66, 3782.00),
				Vector3.new(-2522.34, 73.66, 3752.18),
				Vector3.new(-2525.58, 73.66, 3673.27),
				Vector3.new(-2471.39, 54.46, 3726.01),
				Vector3.new(-2398.88, 54.63, 3895.77),
				Vector3.new(-2537.53, 73.65, 3107.86),
				Vector3.new(-2534.11, 73.66, 3052.78),
				Vector3.new(-2495.59, 73.66, 3012.00),
				Vector3.new(-2510.98, 73.66, 2960.57),
				Vector3.new(-2428.85, 73.66, 2923.07),
				Vector3.new(-2406.06, 73.66, 2807.05),
				Vector3.new(-2384.43, 54.46, 2920.41),
				Vector3.new(-2442.78, 54.46, 2948.16),
				Vector3.new(-2456.00, 54.46, 3033.65),
				Vector3.new(-2462.19, 54.46, 3089.48),
				Vector3.new(381.72, 15.09, 2086.19),
				Vector3.new(491.19, 15.09, 2090.98),
				Vector3.new(526.82, 15.09, 2075.64),
				Vector3.new(506.84, 15.09, 2030.42),
				Vector3.new(1479.14, 23.51, 2294.45),
				Vector3.new(1490.62, 23.51, 2269.81),
				Vector3.new(1551.58, 15.78, 2275.56),
				Vector3.new(1551.00, 15.78, 2252.74),
				Vector3.new(1572.95, 25.60, 2343.28),
				Vector3.new(1484.69, 16.89, 2397.67),
				Vector3.new(1443.61, 16.89, 2360.50),
				Vector3.new(-762.02, 20.91, 76.37),
				Vector3.new(-744.79, 19.34, 62.78),
				Vector3.new(-734.29, 16.17, 54.06),
				Vector3.new(-702.27, 19.67, 84.34),
				Vector3.new(-637.96, 16.93, 132.00),


			}
		}
	},
	[11] = {
		ChestValue = 2,
		TierWeights = {
			[1] = 0,
			[2] =50,
			[3] =90,
			[4] =70,
			[5] =20,
			[6] = 5,
			[7] = 1
		},
		Groups = {
			[1] = { 
				Vector3.new(-183.90, 28.09, -698.79),
				Vector3.new(-197.67, 20.09, -735.70),
				Vector3.new(-177.59, 41.43, -754.45),
				Vector3.new(-170.18, 56.36, -776.76),
				Vector3.new(-199.54, 51.08, -779.49),
				Vector3.new(-169.21, 17.81, -802.99),
				Vector3.new(-161.67, 17.31, -820.07),
				Vector3.new(-187.95, 13.41, -841.63),
				Vector3.new(-201.98, 15.01, -830.31),
				Vector3.new(-120.89, 15.14, -837.98),
				Vector3.new(-109.88, 19.55, -819.99),
				Vector3.new(-86.89, 14.98, -806.38),
				Vector3.new(-84.81, 18.12, -783.83),
				Vector3.new(-76.89, 19.81, -770.92),
				Vector3.new(-82.90, 19.25, -743.50),
				Vector3.new(-94.58, 15.60, -730.35),
				Vector3.new(-94.75, 15.09, -713.06),
				Vector3.new(-116.24, 15.09, -698.26),
				Vector3.new(-135.79, 17.09, -692.65),
				Vector3.new(-141.01, 17.22, -711.68),
				Vector3.new(-130.13, 18.76, -720.88),
				Vector3.new(-654.58, 15.09, 39.34),
				Vector3.new(-685.20, 16.61, 52.12),
				Vector3.new(-698.13, 18.70, 106.09),
				Vector3.new(-716.11, 15.38, 117.75),
				Vector3.new(-739.95, 15.28, 123.32),
				Vector3.new(-734.00, 15.93, 152.74),
				Vector3.new(-717.54, 16.12, 157.80),
				Vector3.new(-701.03, 16.00, 169.16),
				Vector3.new(-679.38, 16.40, 163.22),
				Vector3.new(-659.64, 16.54, 165.90),
				Vector3.new(-657.12, 15.22, 183.89),
				Vector3.new(-636.77, 15.17, 176.93),
				Vector3.new(-614.86, 15.09, 145.33),
				Vector3.new(-672.85, 23.85, 141.04),
				Vector3.new(-736.95, 16.01, 113.56),
				Vector3.new(-760.31, 15.09, 102.05),
				Vector3.new(-761.32, 17.59, 87.11),
				Vector3.new(-753.74, 21.41, 71.32),
				Vector3.new(-759.27, 17.44, 47.53),
				Vector3.new(-773.93, 18.05, 51.25),
				Vector3.new(-791.33, 16.60, 41.72),
				Vector3.new(-791.23, 15.25, 19.42),
				Vector3.new(-824.32, 15.15, 59.57),
				Vector3.new(-1385.11, 17.08, -557.72),
				Vector3.new(-1414.56, 21.54, -560.50),
				Vector3.new(-1436.03, 21.95, -561.27),
				Vector3.new(-1455.29, 21.34, -546.67),
				Vector3.new(-1478.58, 21.95, -579.25),
				Vector3.new(-1486.92, 21.95, -596.54),
				Vector3.new(-1516.26, 21.45, -596.21),
				Vector3.new(-1550.11, 16.80, -615.98),
				Vector3.new(-1550.72, 17.10, -650.08),
				Vector3.new(-1526.92, 21.95, -652.33),
				Vector3.new(-1509.65, 21.95, -659.70),
				Vector3.new(-1495.81, 21.34, -665.97),
				Vector3.new(-1506.30, 21.95, -684.74),
				Vector3.new(-1517.06, 17.14, -703.24),
				Vector3.new(-1483.55, 17.21, -714.65),
				Vector3.new(-1481.59, 17.28, -714.26),
				Vector3.new(-1448.22, 21.48, -703.78),
				Vector3.new(-1412.45, 21.95, -689.79),
				Vector3.new(-1392.00, 21.37, -674.23),
				Vector3.new(-1368.83, 16.87, -687.37),
				Vector3.new(-1403.88, 16.57, -718.31),
				Vector3.new(-1355.25, 16.99, -684.08),
				Vector3.new(-1364.03, 21.25, -650.41),
				Vector3.new(-1398.69, 43.34, -631.01),
				Vector3.new(-1404.87, 43.24, -615.15),
				Vector3.new(-1419.17, 51.96, -611.74),
				Vector3.new(-1417.11, 52.13, -592.49),
				Vector3.new(-1437.54, 52.34, -589.50),
				Vector3.new(-1447.39, 58.81, -603.36),
				Vector3.new(-1440.20, 59.74, -645.13),
				Vector3.new(-1436.40, 56.88, -671.56),
				Vector3.new(-1421.31, 50.03, -668.04),
				Vector3.new(-1479.57, 58.48, -635.38),
				Vector3.new(-1488.55, 43.72, -643.43),



			}
		}
	},
	[12] = {
		ChestValue = 1,
		TierWeights = {
			[1] = 0,
			[2] =120,
			[3] =190,
			[4] =160,
			[5] =30,
			[6] = 8,
			[7] = 5
		},
		Groups = {
			[1] = { 
				Vector3.new(-1882.14, 22.20, 3322.76),
				Vector3.new(-1849.76, 22.21, 3360.15),
				Vector3.new(-1800.24, 22.21, 3314.96),
				Vector3.new(-1952.00, 22.20, 3287.00),
				Vector3.new(-2198.40, 14.19, 3528.11),
				Vector3.new(-2091.56, 15.68, 3344.25),
				Vector3.new(-1457.04, 17.04, 3206.71),
				Vector3.new(-1775.50, 22.26, 3388.61),
				Vector3.new(-2041.30, 16.38, 3166.86),
				Vector3.new(-1773.15, 22.21, 3370.67),
				Vector3.new(-1763.16, 22.21, 3412.39),
				Vector3.new(-1789.57, 22.26, 3382.04),
				Vector3.new(-1930.18, 22.20, 3347.12),
				Vector3.new(-1927.38, 22.20, 3383.31),
				Vector3.new(-2104.30, 15.68, 3311.01),
				Vector3.new(-1603.34, 15.76, 3502.44),
				Vector3.new(-1870.82, 22.21, 3361.82),
				Vector3.new(-1923.94, 22.20, 3395.97),
				Vector3.new(-1908.40, 15.81, 3076.46),
				Vector3.new(-2145.99, 15.68, 3429.21),
				Vector3.new(-2211.61, 15.67, 3292.80),
				Vector3.new(-1819.31, 22.21, 3376.21),
				Vector3.new(-1531.19, 14.73, 3385.79),
				Vector3.new(-1724.61, 22.21, 3378.75),
				Vector3.new(-1546.42, 14.73, 3369.04),
				Vector3.new(-1983.97, 22.20, 3322.16),
				Vector3.new(-1785.02, 22.21, 3335.84),
				Vector3.new(-1842.39, 22.21, 3349.65),
				Vector3.new(-2184.02, 14.35, 3177.33),
				Vector3.new(-2196.27, 15.68, 3405.96),
				Vector3.new(-1759.92, 33.85, 3329.18),
				Vector3.new(-1794.67, 22.21, 3373.21),
				Vector3.new(-1897.86, 22.21, 3372.83),
				Vector3.new(-1906.17, 22.20, 3361.82),
				Vector3.new(-1857.52, 22.25, 3326.27),
				Vector3.new(-1767.39, 22.21, 3465.51),
				Vector3.new(-2125.40, 15.68, 3291.28),
				Vector3.new(-2207.31, 15.68, 3392.35),
				Vector3.new(-1780.63, 22.21, 3376.62),
				Vector3.new(-1819.50, 22.21, 3396.94),
				Vector3.new(-1877.32, 22.20, 3497.72),
				Vector3.new(-1938.87, 22.20, 3246.38),
				Vector3.new(-1936.63, 22.20, 3419.10),
				Vector3.new(-1837.09, 22.20, 3447.75),
				Vector3.new(-2073.63, 13.99, 3520.85),
				Vector3.new(-1824.59, 22.21, 3414.66),
				Vector3.new(-1791.53, 22.21, 3449.63),
				Vector3.new(-1909.92, 22.20, 3421.49),
				Vector3.new(-1789.62, 16.34, 3606.59),
				Vector3.new(-1481.59, 17.04, 3212.76),
				Vector3.new(-2028.60, 15.24, 3427.57),
				Vector3.new(-1829.59, 22.21, 3407.78),
				Vector3.new(-1908.11, 22.20, 3374.08),
				Vector3.new(-1797.57, 22.21, 3395.73),
				Vector3.new(-1859.30, 22.25, 3316.38),
				Vector3.new(-1615.56, 15.76, 3531.43),
				Vector3.new(-2211.88, 15.67, 3362.66),
				Vector3.new(-1848.35, 22.26, 3463.21),
				Vector3.new(-2188.90, 14.19, 3556.05),
				Vector3.new(-1891.20, 22.21, 3363.89),
				Vector3.new(-1782.08, 22.20, 3320.93),
				Vector3.new(-2106.50, 15.68, 3322.62),
				Vector3.new(-1814.09, 16.34, 3586.24),
				Vector3.new(-1831.36, 22.26, 3351.25),
				Vector3.new(-1802.75, 22.21, 3324.50),
				Vector3.new(-2166.22, 14.35, 3167.67),
				Vector3.new(-1946.62, 22.20, 3299.89),
				Vector3.new(-1872.10, 22.26, 3453.97),
				Vector3.new(-1852.08, 38.84, 3210.69),
				Vector3.new(-1857.99, 22.26, 3365.58),
				Vector3.new(-2063.34, 16.60, 3078.89),
				Vector3.new(-1773.88, 22.26, 3415.16),
				Vector3.new(-1915.30, 22.20, 3339.22),
				Vector3.new(-2089.08, 15.19, 3540.45),
				Vector3.new(-2186.42, 15.67, 3446.89),
				Vector3.new(-1807.70, 22.21, 3354.45),
				Vector3.new(-2023.61, 16.38, 3196.22),
				Vector3.new(-1933.26, 22.20, 3371.07),
				Vector3.new(-1952.93, 22.20, 3293.62),
				Vector3.new(-1739.97, 22.21, 3342.24),
				Vector3.new(-1768.38, 19.52, 3089.19),
				Vector3.new(-1973.88, 22.20, 3299.17),
				Vector3.new(-1749.81, 33.85, 3315.46),
				Vector3.new(-1794.39, 22.26, 3439.93),
				Vector3.new(-2111.13, 15.68, 3429.16),
				Vector3.new(-1823.44, 22.21, 3455.00),
				Vector3.new(-1911.18, 22.20, 3353.55),
				Vector3.new(-2035.53, 16.60, 3060.87),
				Vector3.new(-1778.61, 22.21, 3393.08),
				Vector3.new(-1885.37, 22.26, 3442.00),
				Vector3.new(-1824.01, 22.21, 3373.93),
				Vector3.new(-1785.99, 22.21, 3455.49),
				Vector3.new(-1739.21, 29.39, 3253.77),
				Vector3.new(-1482.71, 17.04, 3218.43),
				Vector3.new(-1805.37, 19.52, 3093.74),
				Vector3.new(-2203.83, 15.68, 3319.12),
				Vector3.new(-1800.30, 22.21, 3358.54),
				Vector3.new(-2180.49, 15.67, 3262.23),
				Vector3.new(-1777.32, 22.21, 3421.26),
				Vector3.new(-1826.05, 22.26, 3436.41),
				Vector3.new(-1766.76, 22.21, 3344.76),
				Vector3.new(-1940.97, 22.20, 3334.28),
				Vector3.new(-1936.16, 15.81, 3095.66),
				Vector3.new(-1794.69, 19.51, 3079.30),
				Vector3.new(-1898.86, 22.20, 3257.79),
				Vector3.new(-1811.31, 22.21, 3425.28),
				Vector3.new(-1826.16, 22.21, 3359.70),



			}
		}
	},
	[13] = {
		ChestValue = 1,
		TierWeights = {
			[1] = 0,
			[2] =0,
			[3] =70,
			[4] =90,
			[5] =90,
			[6] = 40,
			[7] = 40
		},
		Groups = {
			[1] = { 
				Vector3.new(1953.36, 71.39, 3542.57),
				Vector3.new(1956.75, 71.39, 3536.47),
				Vector3.new(1882.85, 52.50, 3518.68),
				Vector3.new(1888.31, 52.50, 3518.22),
				Vector3.new(1947.38, 79.66, 3469.23),
				Vector3.new(1944.39, 79.66, 3475.30),
				Vector3.new(2109.90, 79.52, 3398.88),
				Vector3.new(2131.92, 77.52, 3406.08),
				Vector3.new(1915.79, 14.72, 3196.17),
				Vector3.new(1932.71, 18.32, 3167.23),
				Vector3.new(2132.61, 21.92, 3359.93),
				Vector3.new(2098.92, 35.92, 3383.65),
				Vector3.new(2011.13, 51.92, 3423.85),
				Vector3.new(1944.88, 51.93, 3322.81),
				Vector3.new(1997.59, 57.52, 3326.20),
				Vector3.new(2000.20, 57.52, 3297.71),
				Vector3.new(1996.25, 67.53, 3322.45),
				Vector3.new(2055.45, 77.52, 3348.54),
				Vector3.new(2119.04, 15.92, 3366.08),


			}
		}
	},
	[14] = {
		ChestValue = 1,
		TierWeights = {
			[1] = 20,
			[2] =90,
			[3] =110,
			[4] =90,
			[5] =90,
			[6] = 10,
			[7] = 5
		},
		Groups = {
			[1] = { 
				Vector3.new(1959.71, 51.92, 3415.67),
				Vector3.new(2125.51, 16.42, 3100.91),
				Vector3.new(2024.71, 15.92, 3207.41),
				Vector3.new(2163.48, 21.92, 3283.72),
				Vector3.new(1949.00, 47.12, 3199.96),
				Vector3.new(2216.17, 16.72, 3116.69),
				Vector3.new(2038.27, 51.92, 3381.58),
				Vector3.new(2133.91, 16.31, 3194.59),
				Vector3.new(2232.39, 16.72, 3209.71),
				Vector3.new(2172.96, 17.12, 3104.69),
				Vector3.new(2064.41, 16.31, 3264.19),
				Vector3.new(2023.14, 14.72, 3119.37),
				Vector3.new(2165.92, 15.92, 3243.32),
				Vector3.new(2092.44, 16.72, 3263.23),
				Vector3.new(2000.50, 15.92, 3284.70),
				Vector3.new(2196.25, 16.72, 3112.72),
				Vector3.new(2149.69, 16.32, 3108.42),
				Vector3.new(2014.35, 16.72, 3092.28),
				Vector3.new(2154.78, 16.72, 3177.41),
				Vector3.new(2150.73, 35.92, 3373.97),
				Vector3.new(2127.08, 16.72, 3186.87),
				Vector3.new(2011.13, 15.92, 3287.94),
				Vector3.new(2020.24, 16.72, 3091.65),
				Vector3.new(2079.00, 15.92, 3175.02),
				Vector3.new(2140.04, 16.32, 3213.27),
				Vector3.new(2064.69, 15.92, 3170.34),
				Vector3.new(2139.02, 15.92, 3093.38),
				Vector3.new(2108.56, 15.92, 3226.56),
				Vector3.new(2235.40, 16.72, 3243.28),
				Vector3.new(2209.54, 15.92, 3090.36),
				Vector3.new(2092.95, 15.92, 3283.85),
				Vector3.new(2114.92, 16.16, 3217.37),
				Vector3.new(2170.19, 21.92, 3353.02),
				Vector3.new(1969.98, 72.72, 3275.80),
				Vector3.new(2234.34, 16.32, 3119.88),
				Vector3.new(2158.81, 16.72, 3178.26),
				Vector3.new(2098.18, 15.92, 3175.56),
				Vector3.new(2160.00, 16.72, 3099.13),
				Vector3.new(1976.30, 15.92, 3227.11),
				Vector3.new(1949.48, 73.53, 3279.81),
				Vector3.new(2162.62, 35.92, 3380.13),
				Vector3.new(2083.86, 16.72, 3271.91),
				Vector3.new(1992.21, 16.32, 3212.13),
				Vector3.new(2035.69, 14.72, 3093.99),
				Vector3.new(2149.38, 21.92, 3350.79),
				Vector3.new(2115.57, 15.92, 3239.02),
				Vector3.new(2314.82, 16.72, 3240.07),
				Vector3.new(1963.32, 72.72, 3256.70),
				Vector3.new(2174.10, 16.72, 3128.00),
				Vector3.new(2297.26, 16.72, 3245.24),
				Vector3.new(1926.74, 73.53, 3269.55),
				Vector3.new(2024.82, 51.92, 3390.02),
				Vector3.new(2099.00, 15.92, 3231.07),
				Vector3.new(2160.85, 16.72, 3103.68),
				Vector3.new(2114.57, 16.32, 3187.76),
				Vector3.new(2002.75, 15.92, 3248.83),
				Vector3.new(2097.27, 15.92, 3160.51),
				Vector3.new(2165.02, 16.72, 3113.15),
				Vector3.new(1951.72, 51.92, 3371.08),
				Vector3.new(1974.10, 15.92, 3207.15),
				Vector3.new(2112.41, 16.32, 3133.22),
				Vector3.new(1995.69, 14.72, 3068.45),
				Vector3.new(2188.77, 17.12, 3103.91),
				Vector3.new(2202.45, 16.32, 3196.25),
				Vector3.new(2217.92, 16.72, 3185.57),
				Vector3.new(2105.09, 15.92, 3195.24),
				Vector3.new(1933.97, 74.73, 3252.07),
				Vector3.new(2133.84, 15.92, 3230.06),
				Vector3.new(2104.30, 15.92, 3193.21),
				Vector3.new(2232.56, 16.72, 3228.68),
				Vector3.new(2233.58, 16.32, 3266.43),
				Vector3.new(1964.76, 15.92, 3182.99),
				Vector3.new(2084.15, 16.32, 3195.44),
				Vector3.new(1999.01, 14.72, 3082.13),
				Vector3.new(1957.88, 51.93, 3348.91),
				Vector3.new(2195.76, 17.12, 3101.03),
				Vector3.new(2138.83, 35.92, 3396.53),
				Vector3.new(1925.46, 73.53, 3298.13),
				Vector3.new(2098.40, 16.72, 3244.64),
				Vector3.new(2108.23, 15.92, 3287.43),
				Vector3.new(2066.48, 35.92, 3390.06),
				Vector3.new(2002.21, 15.92, 3274.34),
				Vector3.new(1962.42, 51.93, 3324.64),
				Vector3.new(2137.02, 21.92, 3324.88),
				Vector3.new(2013.68, 15.52, 3111.91),
				Vector3.new(2092.12, 15.92, 3183.04),
				Vector3.new(2111.14, 16.32, 3271.77),
				Vector3.new(2149.25, 35.92, 3360.14),
				Vector3.new(2107.72, 16.32, 3203.07),
				Vector3.new(2121.20, 35.92, 3381.32),
				Vector3.new(2143.07, 16.31, 3199.71),
				Vector3.new(2009.10, 15.98, 3253.27),
				Vector3.new(2151.54, 16.58, 3191.91),
				Vector3.new(1980.03, 51.92, 3416.65),
				Vector3.new(2144.76, 16.72, 3100.70),
				Vector3.new(2112.36, 16.32, 3103.90),
				Vector3.new(1982.32, 73.52, 3291.91),
				Vector3.new(2065.38, 16.32, 3251.38),
				Vector3.new(2218.94, 16.32, 3104.23),
				Vector3.new(2002.09, 15.92, 3298.03),
				Vector3.new(2062.13, 15.92, 3181.78),
				Vector3.new(1994.49, 14.72, 3094.87),
				Vector3.new(2230.36, 15.92, 3108.85),
				Vector3.new(2189.75, 16.72, 3126.24),
				Vector3.new(2007.94, 14.72, 3076.29),
				Vector3.new(2063.63, 15.92, 3279.96),
				Vector3.new(2163.25, 15.92, 3206.85),
				Vector3.new(2204.45, 16.32, 3266.08),
				Vector3.new(2201.32, 16.72, 3124.60),
				Vector3.new(1926.79, 51.92, 3410.99),
				Vector3.new(2038.85, 14.72, 3078.84),
				Vector3.new(2083.27, 16.72, 3274.80),
				Vector3.new(2224.57, 16.32, 3127.37),
				Vector3.new(1979.79, 72.72, 3266.79),
				Vector3.new(2165.60, 16.00, 3163.22),
				Vector3.new(2177.48, 15.92, 3092.11),
				Vector3.new(2019.11, 14.72, 3076.19),
				Vector3.new(2111.00, 16.32, 3122.19),
				Vector3.new(1977.37, 72.72, 3255.33),
				Vector3.new(2194.03, 16.32, 3146.89),
				Vector3.new(2047.06, 15.92, 3089.27),
				Vector3.new(2168.09, 21.92, 3269.12),
				Vector3.new(2029.23, 14.72, 3078.04),
				Vector3.new(1929.81, 51.92, 3381.75),
				Vector3.new(1999.50, 15.92, 3176.47),
				Vector3.new(2272.20, 16.72, 3242.32),
				Vector3.new(1976.60, 15.92, 3195.13),
				Vector3.new(2098.22, 35.92, 3392.58),
				Vector3.new(2017.88, 16.32, 3258.76),
				Vector3.new(1955.06, 51.93, 3338.66),
				Vector3.new(1969.17, 55.52, 3235.52),
				Vector3.new(2114.85, 16.32, 3162.61),
				Vector3.new(2123.78, 15.92, 3246.89),
				Vector3.new(1937.16, 73.53, 3295.01),
				Vector3.new(2150.64, 16.32, 3230.43),
				Vector3.new(2004.29, 15.92, 3207.99),
				Vector3.new(1942.19, 51.92, 3424.23),
				Vector3.new(2077.63, 15.92, 3164.67),
				Vector3.new(1953.97, 119.12, 3368.38),
				Vector3.new(1951.29, 33.92, 3169.64),
				Vector3.new(2062.59, 15.92, 3235.99),
				Vector3.new(2015.44, 16.32, 3237.07),
				Vector3.new(1988.13, 14.72, 3101.37),
				Vector3.new(2081.91, 15.92, 3230.41),
				Vector3.new(2165.80, 15.92, 3224.59),
				Vector3.new(1961.92, 47.12, 3206.55),
				Vector3.new(1985.48, 16.35, 3227.22),
				Vector3.new(2327.59, 16.72, 3243.90),
				Vector3.new(1945.97, 33.92, 3176.23),
				Vector3.new(2153.39, 35.92, 3394.77),
				Vector3.new(2109.92, 15.92, 3220.25),
				Vector3.new(1915.26, 51.93, 3394.93),
				Vector3.new(1987.04, 51.92, 3406.47),
				Vector3.new(1974.51, 63.92, 3320.20),
				Vector3.new(2001.26, 15.92, 3164.13),
				Vector3.new(2112.48, 16.32, 3257.15),
				Vector3.new(2028.35, 14.72, 3102.11),
				Vector3.new(2136.79, 15.92, 3233.29),
				Vector3.new(1978.56, 72.72, 3261.14),
				Vector3.new(2069.76, 15.92, 3188.76),
				Vector3.new(1944.93, 73.53, 3323.11),
				Vector3.new(1966.04, 119.13, 3340.49),
				Vector3.new(1945.22, 119.13, 3318.40),
				Vector3.new(1996.23, 119.12, 3396.11),



			}
		}
	},
	
}

local TIERS = {
	{
		Name = "PRIMEVAL",
		Tier = 1,
		MoneyRange = {Min = 500, Max = 2000},
		Color = Color3.fromRGB(200, 200, 0),
		ModelName = "Tier1Chest",
		RequiredClicks = 10  -- Tier 1 needs 5 clicks
	},
	{
		Name = "ENGOT",
		Tier = 2,
		MoneyRange = {Min = 2000, Max = 5000},
		Color = Color3.fromRGB(255, 85, 0),
		ModelName = "Tier2Chest",
		RequiredClicks = 50  -- Tier 2 needs 10 clicks
	},
	{
		Name = "SOLORIS",
		Tier = 3,
		MoneyRange = {Min = 5000, Max = 15000},
		Color = Color3.fromRGB(116, 170, 0),
		ModelName = "Tier3Chest",
		RequiredClicks = 250  -- Tier 3 needs 25 clicks
	},
	{
		Name = "ARKUS",
		Tier = 4,
		MoneyRange = {Min = 15000, Max = 30000},
		Color = Color3.fromRGB(70, 200, 255),
		ModelName = "Tier4Chest",
		RequiredClicks = 750  -- Tier 4 needs 50 clicks
	},
	{
		Name = "EXODUS",
		Tier = 5,
		MoneyRange = {Min = 30000, Max = 75000},
		Color = Color3.fromRGB(170, 0, 255),
		ModelName = "Tier5Chest",
		RequiredClicks = 1500  -- Tier 5 needs 100 clicks
	},
	{
		Name = "MYTHIC",
		Tier = 6,
		MoneyRange = {Min = 75000, Max = 150000},
		Color = Color3.fromRGB(255, 255, 0),
		ModelName = "Tier6Chest",
		RequiredClicks = 5000  -- Tier 6 needs 150 clicks
	},
	{
		Name = "ZENITH",
		Tier = 7,
		MoneyRange = {Min = 250000, Max = 500000},
		Color = Color3.fromRGB(255, 255, 255),
		ModelName = "Tier7Chest",
		RequiredClicks = 9999  -- Tier 7 needs 300 clicks
	}
}

-- ========== HELPER FUNCTIONS ==========
local function selectTierByProbability(tierWeights)
	local totalWeight = 0
	for tier = 1, 7 do
		totalWeight = totalWeight + (tierWeights[tier] or 0)
	end
	if totalWeight <= 0 then
		print("⚠️ No tier weights set or all zero, using random tier")
		return math.random(1, 7)
	end
	local cumulativeWeights = {}
	local cumulative = 0
	for tier = 1, 7 do
		local weight = tierWeights[tier] or 0
		if weight > 0 then
			cumulative = cumulative + weight
			cumulativeWeights[tier] = cumulative
		end
	end
	local randomValue = math.random(1, totalWeight)
	for tier = 1, 7 do
		if cumulativeWeights[tier] and randomValue <= cumulativeWeights[tier] then
			return tier
		end
	end
	return math.random(1, 7)
end

-- ========== REMOTE EVENT SETUP ==========
local ChestEvents

if not ReplicatedStorage:FindFirstChild("ChestEvents") then
	ChestEvents = Instance.new("Folder")
	ChestEvents.Name = "ChestEvents"
	ChestEvents.Parent = ReplicatedStorage
else
	ChestEvents = ReplicatedStorage.ChestEvents
end

local function createEvent(name)
	if not ChestEvents:FindFirstChild(name) then
		local event = Instance.new("RemoteEvent")
		event.Name = name
		event.Parent = ChestEvents
		print("✅ Created event:", name)
	end
	return ChestEvents:FindFirstChild(name)
end

local ShovelHitEvent = createEvent("ShovelHit")
local UpdateChestStateEvent = createEvent("UpdateChestState")
local MetalDetectorScanEvent = createEvent("MetalDetectorScan")
local ChestOpenedNotificationEvent = createEvent("ChestOpenedNotification")

-- ========== SETTINGS ==========

local MAX_ACTIVE_CHESTS = 5
local RESPAWN_DELAY = 10
local shovelHitCounts = {}
local occupiedPositions = {}
local activeChests = {}
local RAISE_STEPS = 5
local RAISE_INCREMENT = 0.5
local TOTAL_RAISE_HEIGHT = RAISE_STEPS * RAISE_INCREMENT

-- ========== FIXED DIG PROGRESS INDICATOR ==========
-- Store references to indicators to prevent duplicates
local chestIndicators = {}

local function createDigProgressIndicator(chest)
	-- Check if indicator already exists
	if chestIndicators[chest] then
		chestIndicators[chest]:Destroy()
		chestIndicators[chest] = nil
	end

	-- Remove any existing indicators
	local existingIndicator = chest:FindFirstChild("DigProgressIndicator")
	if existingIndicator then
		existingIndicator:Destroy()
	end

	local chestPart = chest.PrimaryPart or chest:FindFirstChildWhichIsA("BasePart")
	if not chestPart then
		print("❌ No chest part found for progress indicator")
		return nil
	end

	-- Create BillboardGui
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "DigProgressIndicator"
	billboard.AlwaysOnTop = true
	billboard.Size = UDim2.new(0, 150, 0, 80)
	billboard.StudsOffset = Vector3.new(0, 4, 0)
	billboard.MaxDistance = 50
	billboard.Enabled = true

	-- Create main frame
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(1, 0, 1, 0)
	mainFrame.BackgroundTransparency = 1
	mainFrame.Parent = billboard

	-- Create icon
	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.new(0, 30, 0, 30)
	icon.Position = UDim2.new(0.5, -15, 0, 10)
	icon.BackgroundTransparency = 1
	icon.Image = "rbxassetid://12627937320"
	icon.Parent = mainFrame

	-- Create progress text
	local progressText = Instance.new("TextLabel")
	progressText.Name = "ProgressText"
	progressText.Size = UDim2.new(1, 0, 0, 30)
	progressText.Position = UDim2.new(0, 0, 0.5, 0)
	progressText.BackgroundTransparency = 1
	progressText.Text = "0/?"
	progressText.TextColor3 = Color3.fromRGB(255, 255, 255)
	progressText.Font = Enum.Font.GothamBlack
	progressText.TextSize = 20
	progressText.TextStrokeTransparency = 0.3
	progressText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	progressText.TextXAlignment = Enum.TextXAlignment.Center
	progressText.Parent = mainFrame

	billboard.Parent = chestPart
	chestIndicators[chest] = billboard

	print("✅ Dig progress indicator created for:", chest.Name)
	return billboard
end

local function updateDigProgress(chest, currentClicks, requiredClicks)
	-- Get or create indicator
	local indicator = chestIndicators[chest]
	if not indicator then
		indicator = createDigProgressIndicator(chest)
	end

	if indicator then
		local progressText = indicator:FindFirstChild("MainFrame") and indicator.MainFrame:FindFirstChild("ProgressText")
		if progressText then
			-- Completely replace the text
			progressText.Text = tostring(currentClicks) .. "/" .. tostring(requiredClicks)

			-- Change color based on progress
			local progressPercent = currentClicks / requiredClicks
			if progressPercent >= 1 then
				progressText.TextColor3 = Color3.fromRGB(0, 255, 0)  -- Green
				progressText.Text = "READY!"
			elseif progressPercent >= 0.5 then
				progressText.TextColor3 = Color3.fromRGB(255, 255, 0)  -- Yellow
			else
				progressText.TextColor3 = Color3.fromRGB(255, 255, 255)  -- White
			end
		else
			-- Recreate indicator if text is missing
			createDigProgressIndicator(chest)
			updateDigProgress(chest, currentClicks, requiredClicks)
		end
	end
end

local function removeDigProgressIndicator(chest)
	if chestIndicators[chest] then
		chestIndicators[chest]:Destroy()
		chestIndicators[chest] = nil
	end

	local indicator = chest:FindFirstChild("DigProgressIndicator")
	if indicator then
		indicator:Destroy()
	end
	print("🗑️ Removed dig progress indicator from:", chest.Name)
end

-- ========== CHEST MANAGEMENT FUNCTIONS ==========
local function getChestSystemFolder()
	local chestSystem = Workspace:FindFirstChild("ChestSystem")
	if not chestSystem then
		chestSystem = Instance.new("Folder")
		chestSystem.Name = "ChestSystem"
		chestSystem.Parent = Workspace
	end
	local activeChestsFolder = chestSystem:FindFirstChild("ActiveChests")
	if not activeChestsFolder then
		activeChestsFolder = Instance.new("Folder")
		activeChestsFolder.Name = "ActiveChests"
		activeChestsFolder.Parent = chestSystem
	end
	local templates = chestSystem:FindFirstChild("ChestTemplates")
	if not templates then
		print("❌ WARNING: No ChestTemplates folder found!")
	end
	return chestSystem, activeChestsFolder, templates
end

local function createProximityPrompt(chest)
	local existingPrompt = chest:FindFirstChild("ChestPrompt")
	if existingPrompt then
		existingPrompt:Destroy()
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ChestPrompt"
	prompt.ActionText = "Open Chest"
	prompt.ObjectText = "Treasure"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 15
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX

	-- IMPORTANT: Disable line of sight requirement
	prompt.RequiresLineOfSight = false

	-- Additional settings to make it more visible
	prompt.ClickablePrompt = true
	prompt.Enabled = true

	local chestPart = chest.PrimaryPart or chest:FindFirstChildWhichIsA("BasePart")
	if chestPart then
		prompt.Parent = chestPart
	else
		prompt.Parent = chest
	end

	print("➕ Created ProximityPrompt for chest:", chest.Name)
	return prompt
end

local function setChestTransparency(chest, transparency, instant)
	if not chest or not chest:IsA("Model") then
		return
	end
	for _, obj in ipairs(chest:GetDescendants()) do
		if obj:IsA("BasePart") then
			if obj.Name == "HumanoidRootPart" then
				obj.Transparency = 1
				obj.CanCollide = false
			else
				if instant then
					obj.Transparency = transparency
				else
					if obj.Transparency ~= transparency then
						local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
						local tween = TweenService:Create(obj, tweenInfo, {Transparency = transparency})
						tween:Play()
					end
				end
			end
		elseif obj:IsA("ParticleEmitter") then
			if transparency == 1 then
				obj.Enabled = false
			else
				obj.Enabled = true
			end
		end
	end
end

local function raiseChestOneStep(chest)
	local chestPart = chest.PrimaryPart or chest:FindFirstChildWhichIsA("BasePart")
	if not chestPart then return end
	local currentRaiseStep = chest:FindFirstChild("CurrentRaiseStep")
	if not currentRaiseStep then
		currentRaiseStep = Instance.new("IntValue")
		currentRaiseStep.Name = "CurrentRaiseStep"
		currentRaiseStep.Value = 0
		currentRaiseStep.Parent = chest
	end
	currentRaiseStep.Value = currentRaiseStep.Value + 1
	for _, part in ipairs(chest:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			local newPosition = Vector3.new(
				part.Position.X,
				part.Position.Y + RAISE_INCREMENT,
				part.Position.Z
			)
			local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			local tween = TweenService:Create(part, tweenInfo, {Position = newPosition})
			tween:Play()
		end
	end
	print("📈 Chest raised to step " .. currentRaiseStep.Value .. "/" .. RAISE_STEPS)
	return currentRaiseStep.Value
end

local function checkForRaise(chest, currentClicks, requiredClicks)
	local clicksPerStep = math.max(1, math.ceil(requiredClicks / RAISE_STEPS))
	local currentRaiseStep = chest:FindFirstChild("CurrentRaiseStep")
	if not currentRaiseStep then
		currentRaiseStep = Instance.new("IntValue")
		currentRaiseStep.Name = "CurrentRaiseStep"
		currentRaiseStep.Value = 0
		currentRaiseStep.Parent = chest
	end
	local cappedClicks = math.min(currentClicks, requiredClicks)
	local targetStep = math.min(math.floor(cappedClicks / clicksPerStep), RAISE_STEPS)
	if targetStep == 0 and cappedClicks > 0 then
		targetStep = 1
	end
	if targetStep > currentRaiseStep.Value then
		local stepsToRaise = targetStep - currentRaiseStep.Value
		if targetStep == RAISE_STEPS and stepsToRaise > 1 then
			for _, part in ipairs(chest:GetDescendants()) do
				if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
					local finalHeight = RAISE_INCREMENT * RAISE_STEPS
					local currentHeight = RAISE_INCREMENT * currentRaiseStep.Value
					local raiseAmount = finalHeight - currentHeight
					local newPosition = Vector3.new(
						part.Position.X,
						part.Position.Y + raiseAmount,
						part.Position.Z
					)
					local tweenInfo = TweenInfo.new(
						0.8,
						Enum.EasingStyle.Back,
						Enum.EasingDirection.Out
					)
					local tween = TweenService:Create(part, tweenInfo, {Position = newPosition})
					tween:Play()
				end
			end
			currentRaiseStep.Value = RAISE_STEPS
			print("🚀 Chest jumped to final step! (Powerful shovel)")
		else
			for i = 1, stepsToRaise do
				raiseChestOneStep(chest)
			end
		end
		return true
	end
	return false
end

local function makeChestAppear(chest)
	print("🔄 Making chest appear: " .. chest.Name)
	local humanoidRootPart = chest:FindFirstChild("HumanoidRootPart")
	if humanoidRootPart then
		humanoidRootPart.Transparency = 1
		humanoidRootPart.CanCollide = false
	end
	setChestTransparency(chest, 0, false)
	for _, part in ipairs(chest:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			part.CanCollide = true
		end
	end
	for _, obj in ipairs(chest:GetDescendants()) do
		if obj:IsA("ParticleEmitter") then
			obj.Enabled = true
		end
	end
	print("✨ Chest " .. chest.Name .. " is now visible!")
end

local function makeChestDisappear(chest)
	print("🔄 Making chest disappear: " .. chest.Name)
	local prompt = chest:FindFirstChild("ChestPrompt")
	if prompt then
		prompt:Destroy()
	end

	-- Remove indicator
	removeDigProgressIndicator(chest)

	local humanoidRootPart = chest:FindFirstChild("HumanoidRootPart")
	if humanoidRootPart then
		humanoidRootPart.Transparency = 1
		humanoidRootPart.CanCollide = false
	end
	setChestTransparency(chest, 1, true)
	for _, part in ipairs(chest:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			part.CanCollide = false
		end
	end
	for _, obj in ipairs(chest:GetDescendants()) do
		if obj:IsA("ParticleEmitter") then
			obj.Enabled = false
		end
	end
	print("🌫️ Chest " .. chest.Name .. " is now transparent")
end

local function findEmptyPositionInGroup(groupData, usedPositions)
	local attempts = 0
	local maxAttempts = 50

	local allPositions = {}
	for subgroupId, positions in pairs(groupData.Groups) do
		for _, position in ipairs(positions) do
			table.insert(allPositions, position)
		end
	end

	if #allPositions == 0 then
		print("❌ No positions found in this group")
		return nil
	end

	while attempts < maxAttempts do
		attempts = attempts + 1
		local position = allPositions[math.random(#allPositions)]
		local tooClose = false

		for occupiedPos, _ in pairs(occupiedPositions) do
			if (position - occupiedPos).Magnitude < 15 then
				tooClose = true
				break
			end
		end

		if not tooClose then
			return position
		end
	end

	print("⚠️ Could not find empty position after " .. maxAttempts .. " attempts")
	return allPositions[math.random(#allPositions)]
end

local function spawnChestAtPosition(position, groupData)
	local chestSystem, activeChestsFolder, templates = getChestSystemFolder()
	if not templates then
		print("❌ Cannot spawn chest: No templates available")
		return nil
	end    

	local chestModels = {}
	for _, child in ipairs(templates:GetChildren()) do
		if child:IsA("Model") then
			for _, scriptInModel in ipairs(child:GetDescendants()) do
				if scriptInModel:IsA("Script") or scriptInModel:IsA("LocalScript") then
					scriptInModel:Destroy()
				end
			end
			table.insert(chestModels, child)
		end
	end
	if #chestModels == 0 then
		print("❌ No chest models found in templates!")
		return nil
	end

	local tier
	if groupData and groupData.TierWeights then
		local tierNumber = selectTierByProbability(groupData.TierWeights)
		if tierNumber >= 1 and tierNumber <= #TIERS then
			tier = TIERS[tierNumber]
		else
			tier = TIERS[1]
		end
	else
		local tierIndex = math.random(#TIERS)
		tier = TIERS[tierIndex]
	end

	local template = templates:FindFirstChild(tier.ModelName)
	if not template then
		if #chestModels > 0 then
			template = chestModels[math.random(#chestModels)]
		else
			return nil
		end
	end

	local chest = template:Clone()
	chest.Name = tier.Name .. "Chest_" .. math.random(1000, 9999)

	if not chest:FindFirstChild("IsChest") then
		local isChest = Instance.new("StringValue")
		isChest.Name = "IsChest"
		isChest.Value = "true"
		isChest.Parent = chest
	end
	if not chest:FindFirstChild("DigProgress") then
		local digProgress = Instance.new("IntValue")
		digProgress.Name = "DigProgress"
		digProgress.Value = 0
		digProgress.Parent = chest
	end
	local chestPart
	for _, part in ipairs(chest:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			chestPart = part
			break
		end
	end

	if not chestPart then
		chest:Destroy()
		return nil
	end

	chest.PrimaryPart = chestPart
	chest:SetPrimaryPartCFrame(CFrame.new(position))

	for _, part in ipairs(chest:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
		end
	end

	makeChestDisappear(chest)

	if not chest:FindFirstChild("TreasureValue") then
		local treasure = Instance.new("IntValue")
		treasure.Name = "TreasureValue"
		treasure.Value = math.random(tier.MoneyRange.Min, tier.MoneyRange.Max)
		treasure.Parent = chest
	end

	if not chest:FindFirstChild("ChestTier") then
		local chestTier = Instance.new("IntValue")
		chestTier.Name = "ChestTier"
		chestTier.Value = tier.Tier
		chestTier.Parent = chest
	end

	local state = Instance.new("StringValue")
	state.Name = "ChestState"
	state.Value = "Buried"
	state.Parent = chest

	local currentRaiseStep = Instance.new("IntValue")
	currentRaiseStep.Name = "CurrentRaiseStep"
	currentRaiseStep.Value = 0
	currentRaiseStep.Parent = chest

	if groupData then
		local groupIndexValue = Instance.new("IntValue")
		groupIndexValue.Name = "GroupIndex"
		groupIndexValue.Value = 0

		for idx, group in pairs(CHEST_GROUPS) do
			if group == groupData then
				groupIndexValue.Value = idx
				break
			end
		end

		groupIndexValue.Parent = chest
		print("📊 Chest belongs to group: " .. groupIndexValue.Value)
	end

	chest.Parent = activeChestsFolder
	occupiedPositions[position] = chest
	activeChests[chest] = true

	print("✨ Spawned " .. chest.Name .. " at position: " .. 
		math.floor(position.X) .. ", " .. 
		math.floor(position.Y) .. ", " .. 
		math.floor(position.Z))

	return chest
end

local function initializeChests()
	local chestSystem, activeChestsFolder, _ = getChestSystemFolder()

	for _, chest in ipairs(activeChestsFolder:GetChildren()) do
		chest:Destroy()
	end

	occupiedPositions = {}
	activeChests = {}
	chestIndicators = {}
	local totalChestsSpawned = 0

	for groupId, groupData in pairs(CHEST_GROUPS) do
		local chestsToSpawn = groupData.ChestValue or 0

		if chestsToSpawn > 0 then
			local totalPositions = 0
			for subgroupId, positions in pairs(groupData.Groups) do
				totalPositions = totalPositions + #positions
			end

			print("🎯 Group " .. groupId .. " wants " .. chestsToSpawn .. " chests (total positions: " .. totalPositions .. ")")

			for i = 1, chestsToSpawn do
				local position = findEmptyPositionInGroup(groupData, {})
				if position then
					local chest = spawnChestAtPosition(position, groupData)
					if chest then
						totalChestsSpawned = totalChestsSpawned + 1
						task.wait(0.1)
					else
						print("⚠️ Failed to spawn chest at position")
					end
				else
					print("⚠️ Could not find position for chest " .. i .. " in group " .. groupId)
				end
			end
		else
			print("⏭️ Skipping Group " .. groupId .. " (ChestValue: 0)")
		end
	end

	print("🎉 Total chests spawned: " .. totalChestsSpawned)
end

-- ========== HINGE ANIMATION FUNCTIONS ==========
local function findChestLids(chest)
	local lidParts = {}
	local possibleLidNames = {
		"MetalTop", "WoodTop", "Lid", "Top", 
		"ChestLid", "ChestTop", "Cover", "Door",
		"TopPart", "ChestTopPart", "WoodTopPart", 
		"TopWood", "TopMetal", "MetalLid", "WoodLid"
	}
	for _, name in ipairs(possibleLidNames) do
		local part = chest:FindFirstChild(name)
		if part and part:IsA("BasePart") then
			table.insert(lidParts, part)
			print("🔍 Found lid part: " .. name)
		end
	end
	for _, part in ipairs(chest:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			local lowerName = part.Name:lower()
			if (lowerName:find("top") or lowerName:find("lid") or lowerName:find("cover")) and not table.find(lidParts, part) then
				table.insert(lidParts, part)
				print("🔍 Found additional lid part: " .. part.Name)
			end
		end
	end
	if #lidParts == 0 then
		print("⚠️ No lid parts found for chest:", chest.Name)
	else
		print("✅ Found " .. #lidParts .. " lid parts to animate")
	end
	return lidParts
end

local function getHingePosition(lidPart, basePart)
	local lidCFrame = lidPart.CFrame
	local baseCFrame = basePart.CFrame
	local edges = {
		Vector3.new(0, 0, -lidPart.Size.Z/2),
		Vector3.new(0, 0, lidPart.Size.Z/2),
		Vector3.new(-lidPart.Size.X/2, 0, 0),
		Vector3.new(lidPart.Size.X/2, 0, 0),
	}
	local closestEdge = edges[1]
	local closestDistance = math.huge
	for _, edgeOffset in ipairs(edges) do
		local edgeWorldPos = lidCFrame:PointToWorldSpace(edgeOffset)
		local distance = (edgeWorldPos - baseCFrame.Position).Magnitude
		if distance < closestDistance then
			closestDistance = distance
			closestEdge = edgeOffset
		end
	end
	local hingeOffset = closestEdge
	local hingeWorldPos = lidCFrame:PointToWorldSpace(hingeOffset)
	print("🔧 Hinge position for " .. lidPart.Name .. ": " .. tostring(hingeOffset))
	return hingeWorldPos, hingeOffset
end

local function rotateAroundHinge(lidPart, hingeWorldPos, rotationAngle)
	local currentCFrame = lidPart.CFrame
	local rotationCFrame = CFrame.new(hingeWorldPos) * CFrame.Angles(rotationAngle, 0, 0) * CFrame.new(-hingeWorldPos)
	return rotationCFrame * currentCFrame
end

local function animateChestLidsOpen(lidParts, basePart)
	if not lidParts or #lidParts == 0 then 
		print("❌ Cannot animate: No lid parts found")
		return 
	end
	print("🎬 Playing hinge-based chest opening animation for " .. #lidParts .. " lid parts...")
	local allTweens = {}
	for index, lidPart in ipairs(lidParts) do
		local hingeWorldPos, hingeOffset = getHingePosition(lidPart, basePart)
		if not lidPart:FindFirstChild("OriginalCFrame") then
			local originalCFrameValue = Instance.new("CFrameValue")
			originalCFrameValue.Name = "OriginalCFrame"
			originalCFrameValue.Value = lidPart.CFrame
			originalCFrameValue.Parent = lidPart
		end
		local rotationAngle = math.rad(-90)
		if hingeOffset.Z > 0 then
			rotationAngle = math.rad(90)
		end
		local randomAngle = math.rad(math.random(-5, 5))
		rotationAngle = rotationAngle + randomAngle
		local newCFrame = rotateAroundHinge(lidPart, hingeWorldPos, rotationAngle)
		local delayTime = (index - 1) * 0.15
		local tweenInfo = TweenInfo.new(
			0.7,
			Enum.EasingStyle.Back,
			Enum.EasingDirection.Out,
			0,
			false,
			delayTime
		)
		local tween = TweenService:Create(lidPart, tweenInfo, {CFrame = newCFrame})
		table.insert(allTweens, tween)
		local liftTweenInfo = TweenInfo.new(
			0.3,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out,
			0,
			false,
			delayTime
		)
		local liftAmount = Vector3.new(
			math.random(-1, 1) * 0.05,
			math.random(2, 4) * 0.1,
			math.random(-1, 1) * 0.05
		)
		local currentPos = lidPart.Position
		local hingeToCenter = currentPos - hingeWorldPos
		local liftedPos = hingeWorldPos + (hingeToCenter * 1.1) + liftAmount
		local liftTween = TweenService:Create(lidPart, liftTweenInfo, {Position = liftedPos})
		table.insert(allTweens, liftTween)
		print("   → Animating " .. lidPart.Name .. " around hinge (delay: " .. string.format("%.2f", delayTime) .. "s)")
	end
	for _, tween in ipairs(allTweens) do
		tween:Play()
	end
	print("✅ Hinge-based chest opening animation started")
	return allTweens
end

local function playChestOpenSound(parentPart)
	local sound = Instance.new("Sound")
	sound.Name = "ChestOpenSound"
	sound.SoundId = "rbxassetid://119863961338012"
	sound.Volume = 0.5
	sound.Parent = parentPart or workspace
	sound:Play()
	game:GetService("Debris"):AddItem(sound, 3)
end

local function playMoneySound(parentPart)
	local sound = Instance.new("Sound")
	sound.Name = "MoneySound"
	sound.SoundId = "rbxassetid://9119266006"
	sound.Volume = 0.3
	sound.Parent = parentPart or workspace
	sound:Play()
	game:GetService("Debris"):AddItem(sound, 3)
end

-- ========== CHEST OPENING FUNCTION ==========
local function openChest(chest, player)
	print("=== CHEST OPENING ===")
	print("Player:", player.Name)
	print("Chest:", chest.Name)

	removeDigProgressIndicator(chest)
 -- Remove prompt and prompt part
 
	-- CHEST COUNT TRACKING - ADD THIS LINE
	incrementChestCount(player)
	
	if activeChests[chest] then
		activeChests[chest] = false
	end

	local chestState = chest:FindFirstChild("ChestState")
	if not chestState then 
		print("❌ No chest state found")
		return false 
	end

	if chestState.Value ~= "DugUp" then
		print("❌ Chest not ready to open. State:", chestState.Value)
		return false
	end

	local character = player.Character
	local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then 
		print("❌ No humanoid root part")
		return false 
	end

	local chestPart = chest.PrimaryPart or chest:FindFirstChildWhichIsA("BasePart")
	if not chestPart then 
		print("❌ No chest part found")
		return false 
	end

	local distance = (humanoidRootPart.Position - chestPart.Position).Magnitude
	if distance > 20 then 
		print("❌ Player too far:", distance)
		return false 
	end

	chestState.Value = "Opened"
	UpdateChestStateEvent:FireClient(player, chest, "Opened")

	local prompt = chest:FindFirstChild("ChestPrompt")
	if prompt then
		prompt:Destroy()
	end

	local chestGroupIndex = chest:FindFirstChild("GroupIndex")
	local originalGroupId = chestGroupIndex and chestGroupIndex.Value

	local lidParts = findChestLids(chest)
	if #lidParts > 0 then
		animateChestLidsOpen(lidParts, chestPart)
		playChestOpenSound(chestPart)
	end

	local treasure = chest:FindFirstChild("TreasureValue")
	if treasure then
		print("💰 Giving reward: $" .. treasure.Value)

		if ChestOpenedNotificationEvent then
			ChestOpenedNotificationEvent:FireAllClients(
				player.Name,
				treasure.Value,
				chest.Name,
				chest:FindFirstChild("ChestTier") and chest.ChestTier.Value or 1
			)
		end

		local success = giveMoney(player, treasure.Value)
		if success then
			playMoneySound(chestPart)
		end
	end

	for pos, chestObj in pairs(occupiedPositions) do
		if chestObj == chest then
			occupiedPositions[pos] = nil
			break
		end
	end

	task.delay(10, function()
		if chest and chest.Parent then
			chest:Destroy()
			print("🗑️ Removed opened chest:", chest.Name)
		end
	end)

	if originalGroupId then
		task.delay(RESPAWN_DELAY, function()
			print("🔄 Respawning new chest in Group " .. originalGroupId)

			local groupData = CHEST_GROUPS[originalGroupId]
			if not groupData then
				print("❌ Group data not found for group:", originalGroupId)
				return
			end

			if (groupData.ChestValue or 0) <= 0 then
				print("⚠️ Group " .. originalGroupId .. " has ChestValue = 0, skipping respawn")
				return
			end

			local newPosition = findEmptyPositionInGroup(groupData, {})
			if newPosition then
				print("✅ Found respawn position in group " .. originalGroupId .. ": " .. tostring(newPosition))
				local newChest = spawnChestAtPosition(newPosition, groupData)
				if newChest then
					print("✅ Chest respawned successfully!")
				else
					print("❌ Failed to spawn chest at position")
				end
			else
				print("❌ Could not find empty position in group " .. originalGroupId)
			end
		end)
	else
		print("❌ Could not find group index for chest, cannot respawn")
	end

	print("✅ Chest opened successfully by", player.Name)
	return true
end

-- ========== EVENT HANDLERS ==========
MetalDetectorScanEvent.OnServerEvent:Connect(function(player, chest)
	print("=== METAL DETECTOR SCAN ===")
	print("Player:", player.Name)

	if not player or not chest then return end

	local foundChest = workspace:FindFirstChild(chest.Name, true)
	if not foundChest then
		print("❌ Chest not found in workspace!")
		return
	end
	chest = foundChest

	local chestState = chest:FindFirstChild("ChestState")
	if not chestState then return end

	-- Check if chest is already scanned
	if chestState.Value ~= "Buried" then 
		print("⚠️ Chest already scanned or being dug:", chestState.Value)
		return 
	end

	local character = player.Character
	local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end

	local chestPart = chest.PrimaryPart or chest:FindFirstChildWhichIsA("BasePart")
	if not chestPart then return end

	local distance = (humanoidRootPart.Position - chestPart.Position).Magnitude
	if distance > 50 then return end

	-- Get chest tier to determine required clicks
	local chestTier = chest:FindFirstChild("ChestTier")
	if not chestTier then
		print("❌ Chest tier not found!")
		return
	end

	local tierData = TIERS[chestTier.Value]
	if not tierData then
		print("❌ Tier data not found for tier:", chestTier.Value)
		return
	end

	local requiredClicks = tierData.RequiredClicks or 5
	print("📊 Tier " .. chestTier.Value .. " requires " .. requiredClicks .. " clicks")

	-- Immediately change chest state to "Scanned" - NO player tracking
	chestState.Value = "Scanned"
	makeChestAppear(chest)

	-- === FIX: Create dig progress indicator immediately with 0/requiredClicks ===
	-- Get or create indicator
	local indicator = chestIndicators[chest]
	if not indicator then
		indicator = createDigProgressIndicator(chest)
	end

	-- Set initial progress to 0/requiredClicks
	if indicator then
		local progressText = indicator:FindFirstChild("MainFrame") and indicator.MainFrame:FindFirstChild("ProgressText")
		if progressText then
			progressText.Text = "0/" .. requiredClicks
			progressText.TextColor3 = Color3.fromRGB(255, 255, 255)  -- White
		end
	end

	-- Reset any existing dig progress for this chest
	shovelHitCounts[chest] = {
		clicks = 0
	}
	-- ==============================================================

	print("✅ Chest scanned! Visible to ALL players with progress indicator 0/" .. requiredClicks)

	-- Notify ALL players that the chest is now scanned
	for _, plr in pairs(Players:GetPlayers()) do
		UpdateChestStateEvent:FireClient(plr, chest, "Scanned")
	end
end)
ShovelHitEvent.OnServerEvent:Connect(function(player, chest, clickValue)
	print("=== SHOVEL HIT ===")
	print("Player:", player.Name)
	print("Click Value:", clickValue or 1)

	if not player or not chest then return end

	local foundChest = workspace:FindFirstChild(chest.Name, true)
	if not foundChest then
		print("❌ Chest not found!")
		return
	end
	chest = foundChest

	local isChestValue = chest:FindFirstChild("IsChest")
	if not isChestValue then return end

	local chestState = chest:FindFirstChild("ChestState")
	if not chestState then return end

	-- Check chest state - must be "Scanned" or "DugUp" to allow digging
	if chestState.Value ~= "Scanned" then 
		print("❌ Chest not ready for digging. State:", chestState.Value)
		return 
	end

	local character = player.Character
	local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end

	local chestPart = chest.PrimaryPart or chest:FindFirstChildWhichIsA("BasePart")
	if not chestPart then return end

	local distance = (humanoidRootPart.Position - chestPart.Position).Magnitude
	if distance > 10 then  -- Increased distance for digging
		print("❌ Player too far:", distance)
		return 
	end

	-- Get chest tier and required clicks
	local chestTier = chest:FindFirstChild("ChestTier")
	if not chestTier then
		print("❌ Chest tier not found!")
		return
	end

	local tierData = TIERS[chestTier.Value]
	if not tierData then
		print("❌ Tier data not found for tier:", chestTier.Value)
		return
	end

	local requiredClicks = tierData.RequiredClicks or 5
	print("📊 Tier " .. chestTier.Value .. " requires " .. requiredClicks .. " clicks")

	-- Get or create hit data for this chest
	local hitData = shovelHitCounts[chest]
	if not hitData then
		hitData = {
			clicks = 0
		}
		shovelHitCounts[chest] = hitData
		print("📊 Started tracking dig progress for chest:", chest.Name)
	end

	-- ANY player can increment the click count
	local additionalClicks = clickValue or 1
	hitData.clicks = hitData.clicks + additionalClicks

	print("🔄 Dig progress: " .. hitData.clicks .. "/" .. requiredClicks .. " (by " .. player.Name .. ")")

	-- Update dig progress indicator - SINGLE UPDATE
	updateDigProgress(chest, hitData.clicks, requiredClicks)

	-- Check and update chest raising
	checkForRaise(chest, hitData.clicks, requiredClicks)

	if hitData.clicks >= requiredClicks then
		print("🎯 Dig complete! Chest ready to open")
		chestState.Value = "DugUp"

		-- The indicator already shows "READY!" from the updateDigProgress function
		createProximityPrompt(chest)
		shovelHitCounts[chest] = nil

		-- Fire to ALL players that the chest is ready to open
		for _, plr in pairs(Players:GetPlayers()) do
			UpdateChestStateEvent:FireClient(plr, chest, "DugUp")
		end

		print("✅ Chest now has ProximityPrompt for ALL players")
	end
end)

game:GetService("ProximityPromptService").PromptTriggered:Connect(function(prompt, player)
	if prompt.Name == "ChestPrompt" then
		local chest = prompt.Parent
		if chest and chest.Parent then
			while chest and not chest:FindFirstChild("IsChest") do
				chest = chest.Parent
			end
			if chest and chest:FindFirstChild("IsChest") then
				openChest(chest, player)
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	print("👋 Player leaving:", player.Name)
end)

-- ========== INITIALIZATION ==========
task.wait(2)
initializeChests()
print("🚀 Chest Manager with Fixed Dig Progress Indicator ready!")
print("   - Shows shovel icon with progress (e.g., '0/5') above scanned chests")
print("   - NO DUPLICATION - text updates correctly")
print("   - Progress updates in real-time for all players")
print("   - Indicator disappears when chest is opened")
print("   - " .. MAX_ACTIVE_CHESTS .. " active chests maximum")
print("   - Tier-based click system: T1=5, T2=10, T3=25, T4=50, T5=100, T6=150, T7=300")
