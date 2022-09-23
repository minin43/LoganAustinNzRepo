util.AddNetworkString("RunFireOverlay")
util.AddNetworkString("RunTeleportOverlay")
util.AddNetworkString("StopOverlay")
util.AddNetworkString("StartBloodCount")
util.AddNetworkString("UpdateBloodCount")
util.AddNetworkString("SendBatteryLevel")
util.AddNetworkString("RunSound")
util.AddNetworkString("StartTeleportTimer")
util.AddNetworkString("UpdateTeleportTimer")
util.AddNetworkString("ResetChalkMessages")
util.AddNetworkString("DeleteChalkMessages")
util.AddNetworkString("RunCoward")

--[[
    Easter egg
    "Some say a demon haunts the floors of this accursed hospital, preying on the hopes of the lost souls who wander there. Do you dare enter it, and find out yourself?
    Perhaps a way to vanquish it lie within its stone walls, trapped between the screams of the unyielding and undead."

    1. No power, power switch is locked behind the destructible wall
        a. Flavor text indicating its destructability
        b. Access to hallway is locked by key findable in speed cola buy area
    2. Elevator to basement is powered separately, need to fill a generator with gas cans
        a. Flavor text should update indicating how much it's been filled with (1/4, 2/4, 3/4)
        b. Spot 1 is in power area, spot 2 is in the buy area to the right of spawn elevator, spot 3 is somewhere in spawn area
            or in first buy area, spot 4 is in the buy area to the left of spawn elevator
    3. Once power is reactivated, the building "consoles" can be interacted with to disable building lockdown
        a. First console is the in the first buy area, second console is in the basement
    4. Once the consoles have been activated, power once again dies in the building, but it can be restored by the backup
        generator, which teleports the player when used, and unlocks the first door to the poison hallway
        a. The generator has 2 lights above it which relate to the lights triggered by the switches in the basement.
            The correct switches (one, the other, or both) have to be pulled to match what's shown in the generator room in order
            to reach the PaP area.
        b. The backup generator area is unlocked by a set of keys found in the basement (only one of those double doors opens)
        c. The players must PaP at least one gun to break the padlock locking the final door to the poison hallway
    5. The players must then make it through the winding hallways of the inner hospital, finding effigy parts throughout each buy area
        a. One or some parts (doll?) are found earlier on
    6. Players must construct the boss effigy in a build table, and then ignite the effigy (explosion damage will do the trick too)
        to draw out the boss. Once the effigy is burned, the boss spawns and the game enters round infinity
    7. The boss has a lot of health but takes double damage from explosives and fire. Once the boss dies, players can escape through
        the tunnel at the very end of the map.
]]

--[[    Post script-load work    ]]

local mapscript = {}
mapscript.bloodGodKills = 0
mapscript.bloodGodKillsGoal = 10
mapscript.batteryLevels = {}
mapscript.flashlightStatuses = {}

--The gas cans used to fill the generators
local gascanspawns = {
    { --Can 1, found around the power room
        {pos = Vector(-214, 2372, 15), ang = Angle(0, -90, 0)}, --By jugg
        {pos = Vector(-693.2, 3046.3, 13.9), ang = Angle(-0, 87.8, 0)}, --In the un-barricaded operating room
        {pos = Vector(-1923.25, 3534.25, 15.25), ang = Angle(0, 106, 0)} --By AR-15 wallbuy
    },
    { --Can 2, found in spawn and first-buy areas
        {pos = Vector(-2181.088623, 468.324829, 15.435638), ang = Angle(-0.501, -179.562, 0.401)}, --Outside
        {pos = Vector(-2665.829590, 981.737122, 15.617842), ang = Angle(-22.630, 179.775, 0.053)}, --Hallway to first building console
        {pos = Vector(-1996.276123, 1646.433960, 15.805776), ang = Angle(-20.024, 127.682, -0.00)} --In the construction room with the generator
    },
    { --Can 3, found before poison hallway
        {pos = Vector(-4042.156494, 2299.571289, 15.327369), ang = Angle(0.005, -89.606, -0.010)}, --End of the shower hallway
        {pos = Vector(-2820.499756, 2997.671387, 15.176751), ang = Angle(-0.042, 179.939, -0.001)}, --Corner of Speed Cola room
        {pos = Vector(-3244.239990, 2709.144775, 15.417276), ang = Angle(-28.406, -103.495, 0.216)} --Dark corner of multiple-bed room
    },
    { --Can 4, found behind the destructible wall
        {pos = Vector(-1521.962036, 3592.954590, 12.954604), ang = Angle(-30.518, 93.740, -1.926)}
    }
}

local babyspawns = {
    {pos = Vector(-4175.835938, 5322.623047, 66.900337), ang = Angle(-28.771, -163.458, 88.214)}, --Utility room
    {pos = Vector(-4557.794434, 6429.033203, 85.221519), ang = Angle(-30.306, 14.718, 82.847)}, --On the bench
    {pos = Vector(-4739.419922, 7701.262695, 112.092331), ang = Angle(56.154, -87.995, -88.512)} --In the trash can
}
local skullspawns = {
    {pos = Vector(-5463.068848, 7131.594238, 107.016449), ang = Angle(3.375, 72.139, 0.339)}, --On the operating table
    {pos = Vector(-6125.040527, 7802.763672, 67.052742), ang = Angle(3.238, 178.112, 0.279)}, --Between the benches
    {pos = Vector(-6760.770508, 9302.520508, 111.466789), ang = Angle(5.118, 39.262, 0.718)} --In the trash can
}
local paperspawns = {
    {pos = Vector(-6424.794922, 10043.782227, 106.180504), ang = Angle(1.038, -37.129, 0.345)}, --On operating table
    {pos = Vector(-4267.633301, 9975.561523, 114.061790), ang = Angle(0.573, 172.451, -0.351)}, --On counter
    {pos = Vector(-4969.188965, 10526.915039, 82.693443), ang = Angle(0.835, 145.076, -0.326)} --In boss spawn room
}

--Batteries
local batteries = {
	{pos = Vector(-2436.871582, 1014.399536, 46.50404), ang = Angle(-55.045, 151.149, -167.21)},
	{pos = Vector(-1786.455444, 2370.384521, 48.57032), ang = Angle(-37.775, -64.178, 11.95)},
	{pos = Vector(-1979.874268, 3566.959473, 37.85770), ang = Angle(-37.916, 51.778, 11.93)},
	{pos = Vector(-97.313683, 2924.940186, 37.81508), ang = Angle(-37.314, -118.791, 12.04)},
	{pos = Vector(-2902.511963, 2597.846436, 48.59691), ang = Angle(-38.151, -84.157, 11.88)},
	{pos = Vector(-4622.492188, 3658.279297, -92.48356), ang = Angle(-36.196, -164.181, 11.34)},
	{pos = Vector(-6782.381836, 3432.891602, 34.38910), ang = Angle(-37.794, 157.666, 11.94)},
    {pos = Vector(-3403.921875, 3300.159668, 18.95353), ang = Angle(-53.143, 85.770, -168.46)},
    {pos = Vector(-3647.955078, 6750.748047, 112.58902), ang = Angle(-40.741, 55.908, 14.65)},
    {pos = Vector(-4929.287109, 7471.330566, 101.76261), ang = Angle(-26.939, -4.668, 9.41)},
    {pos = Vector(-5460.764160, 7138.412598, 104.58886), ang = Angle(-38.037, 73.588, 11.90)},
    {pos = Vector(-5473.729980, 7142.676270, 104.53120), ang = Angle(-37.222, 42.693, 12.05)},
    {pos = Vector(-5536.578125, 10493.915039, 81.09477), ang = Angle(-36.348, 35.411, 11.37)},
    {pos = Vector(-5536.988281, 10531.532227, 81.09297), ang = Angle(-36.311, -43.786, 11.36)},
    {pos = Vector(-4273.901855, 10044.547852, 112.55004), ang = Angle(-61.845, -110.469, -164.04)},
    {pos = Vector(-4270.998047, 10008.869141, 112.57056), ang = Angle(58.348, -49.255, -8.13)},
    {pos = Vector(-4270.181152, 9983.740234, 112.65776), ang = Angle(42.282, 107.380, 175.01)},
    {pos = Vector(-4273.702637, 9886.146484, 112.59091), ang = Angle(56.654, 167.444, -11.40)},
    {pos = Vector(-4272.020020, 9822.676758, 112.52522), ang = Angle(-53.056, -105.436, -163.68)},
    {pos = Vector(-4274.509277, 9803.791992, 112.66100), ang = Angle(34.587, -25.402, 174.65)},
    {pos = Vector(-2430.007080, 1346.526367, -3528.44970), ang = Angle(64.863, 66.468, -14.13)},
    {pos = Vector(-2433.776855, 1347.847412, -3528.48461), ang = Angle(-52.461, 142.025, -167.32)},
    {pos = Vector(-3339.458984, 1488.409424, -3549.39941), ang = Angle(71.161, -74.220, -19.93)},
    {pos = Vector(-3364.109375, 662.760254, -3549.39843), ang = Angle(61.172, -85.910, -14.430)},
    {pos = Vector(-3360.204834, 572.172607, -3549.368652), ang = Angle(-38.956, 132.059, 12.01)},
    {pos = Vector(-3364.406982, 566.230713, -3549.42529), ang = Angle(-60.017, 123.212, -164.98)},
    {pos = Vector(-5174.005859, 560.970459, -3531.32959), ang = Angle(30.249, 21.286, 173.75)},
    {pos = Vector(-5174.726074, 578.369934, -3531.48828), ang = Angle(-51.760, 97.969, -169.90)},
    {pos = Vector(-3269.567871, 2077.697754, -3549.38061), ang = Angle(-38.943, -139.653, 11.97)},
    {pos = Vector(-3282.178711, 2076.142822, -3549.47021), ang = Angle(-58.391, 58.327, -166.00)},
    {pos = Vector(-2439.740967, 781.870728, 46.52282), ang = Angle(-61.265, 11.267, -170.51)},
    {pos = Vector(158.518555, 3749.448486, 34.58102), ang = Angle(-38.046, -115.702, 11.60)},
    {pos = Vector(-351.988251, 2292.685791, 52.67468), ang = Angle(-38.877, -170.935, 10.76)},
    {pos = Vector(-2438.876465, 1012.538818, 46.576851), ang = Angle(-45.786, -23.365, 11.249)},
    {pos = Vector(-2943.356201, 376.680359, 32.539017), ang = Angle(-52.924, 54.885, -167.160)},
    {pos = Vector(-1634.872925, 2501.901611, 48.442104), ang = Angle(-61.534, -126.098, -164.882)},
    {pos = Vector(-1669.691406, 4030.333252, 48.593281), ang = Angle(57.175, 173.273, -12.060)},
    {pos = Vector(-724.885986, 3514.568604, 48.604996), ang = Angle(-35.177, 68.342, 10.817)},
    {pos = Vector(-3065.257080, 3074.691895, 0.541340), ang = Angle(-57.086, -66.165, -167.97)}
}

--//Still in need of some refinement
local areasByVector = {
    { --Spawn area & beyond
        {pos1 = Vector(223.3, 4672.2, -50.0), pos2 = Vector(-4224.0, -1505.1, 256.0)}, --This pair overlaps parts of areasByVector[1][2] & areasByVector[1][3], but that's okay
        {pos1 = Vector(-6873.0, 10810.0, 320.0), pos2 = Vector(-2137.0, 4672.2, -50.0)},
        {pos1 = Vector(-4768, 3008.0, -50.0), pos2 = Vector(-3968.0, 2308.0, 128.0)},
    },
    { --Generator area
        {pos1 = Vector(-4864.0, 2596.0, 0.0), pos2 = Vector(-5695.0, 3451.5, 192)},
        {pos1 = Vector(-5055.0, 3397.4, 128), pos2 = Vector(-4608.4, 4543, -128)}
    },
    { --Teleport area
        {pos1 = Vector(-6336.0, 3904.0, -32.0), pos2 = Vector(-7424.0, 2080.0, 192.0)}
    },
    { --Basement area
        {pos1 = Vector(-5513.0, -63.5, -3632.6), pos2 = Vector(-2305.0, 2368.4, -3392.0)}
    }
}

--Possible spots players may teleport to on power generator flippage
local possibleTeleports = {
    default = {
		{pos = Vector(-6751.75, 3268.5, 0), ang = Angle(0, -180, 0)}
	},
    pap = {
        {pos = Vector(-2844.5, 297, -1663), ang = Angle(0, 0, 0)}
    }
	post = {
		{pos = Vector(-3064, 195, -3580), ang = Angle(0, -180, 0)},
		{pos = Vector(-5082, 724, -3582), ang = Angle(3.5 -17.5, 0)},
		{pos = Vector(-3392, 2641, 2), ang = Angle(0, -90, 0)},
		{pos = Vector(-4124, 2852, 5), ang = Angle(0, 0, 0)},
		{pos = Vector(-1825.5, 3709.75, 0.0), ang = Angle(0, -7.5, 0)},
		{pos = Vector(-3007.5, 512.5, 0.0), ang = Angle(0, -90, 0)}
	},
}
local spawnTeleport = {pos = Vector(-2367, 12, 2), ang = Angle(0, 90, 0)}

local radiosByID = {"1456", "2144", "1403"}

local gascans = nzItemCarry:CreateCategory("gascan")
	gascans:SetIcon("spawnicons/models/props_junk/metalgascan.png") --spawnicons/models/props_junk/gascan001a.png
	gascans:SetText("Press E to pick up the gas can")
	gascans:SetDropOnDowned(false)
	gascans:SetShowNotification(true)
	gascans:SetResetFunction(function(self)
		for num, tab in pairs(gascanspawns) do
			subtab = tab[math.random(1, #tab)]
			if tab.ent and tab.ent:IsValid() then
				tab.ent:Remove()
			end
			local ent = ents.Create("nz_script_prop")
			ent:SetModel("models/props_junk/metalgascan.mdl")
			ent:SetPos(subtab.pos)
			ent:SetAngles(subtab.ang)
			ent:Spawn()
			tab.ent = ent
			self:RegisterEntity(ent)
		end
	end)
	gascans:SetPickupFunction(function(self, ply, ent)
        ply:GiveCarryItem(self.id)
        ent:Remove()
	end)
	gascans:SetCondition( function(self, ply)
		return !ply:HasCarryItem("gascan")
	end)
gascans:Update()

--Batteries are only created on round & game start, you'll find code for spawning them in mapscript.OnRoundStart and mapscript.OnGameBegin
local battery = nzItemCarry:CreateCategory("battery")
	battery:SetIcon("spawnicons/models/zworld_equipment/zpile.png")
    battery:SetText("Press E to insert battery into your flashlight")
	battery:SetDropOnDowned(false)
	battery:SetShowNotification(true)
	battery:SetResetFunction(function(self)
		for _, info in pairs(batteries) do
			if info.spawned and info.ent and info.ent:IsValid() then
				info.ent:Remove()
				info.spawned = false
			end
        end
        for k, v in pairs(player.GetAll()) do
            v:RemoveCarryItem("battery")
        end
        mapscript.batteryLevels = {}
	end)
	battery:SetPickupFunction(function(self, ply, ent)
		ply:GiveCarryItem(self.id)
		ply:AllowFlashlight(true)
		mapscript.flashlightStatuses[ply] = true
        mapscript.batteryLevels[ply:SteamID()] = math.Clamp(mapscript.batteryLevels[ply:SteamID()] + ent.charge, 0, 100)
        
        net.Start("SendBatteryLevel")
            net.WriteInt(mapscript.batteryLevels[ply:SteamID()], 16)
        net.Send(ply)
		
		for k, v in pairs(batteries) do
			if v.ent == ent then
				ent:Remove()
				v.spawned = false
				break
			end
		end

        timer.Simple(2, function()
            if ply and ply:IsValid() and ply:Alive() and ply:HasCarryItem(self.id) then
                ply:RemoveCarryItem(self.id)
            end
        end)
	end)
	battery:SetCondition( function(self, ply)
		return (!ply:HasCarryItem("battery") or mapscript.batteryLevels[ply:SteamID()] < 90)
	end)
battery:Update()

local key = nzItemCarry:CreateCategory("key")
    key:SetIcon("spawnicons/models/zpprops/keychain.png")
    key:SetText("Press E to pick up the keys")
    key:SetDropOnDowned(false)
    key:SetShowNotification(true)
    key:SetResetFunction(function(self)
		local ent = ents.Create("nz_script_prop")
        ent:SetModel("models/zpprops/keychain.mdl")
        ent:SetPos(Vector(-3281.935791, 2072.425537, -3548.327393))
        ent:SetAngles(Angle(5.750, 128.816, -9.700))
        ent:Spawn()
        self:RegisterEntity(ent)
        local ent2 = ents.Create("nz_script_prop")
        ent2:SetModel("models/zpprops/keychain.mdl")
        ent2:SetPos(Vector(-3063.526367, 375.649017, 33.818169))
        ent2:SetAngles(Angle(5.229, 74.363, -10.752))
        ent2:Spawn()
        self:RegisterEntity(ent2)
        for k, v in pairs(player.GetAll()) do
            v:RemoveCarryItem("key")
        end
	end)
	key:SetPickupFunction(function(self, ply, ent)
		ply:GiveCarryItem(self.id)
        ent:Remove()
	end)
	key:SetCondition( function(self, ply)
		return !ply:HasCarryItem("key")
	end)
key:Update()

local effigy1 = neItemCarry:CreateCategory("effigy1")
    key:SetIcon("spawnicons/models/maxofs2d/companion_doll.png")
    key:SetText("This might come in handy later...")
    key:SetDropOnDowned(false)
    key:SetShowNotification(true)
    key:SetResetFunction(function(self)
        local ent = ents.Create("nz_script_prop")
        ent:SetModel("models/maxofs2d/companion_doll.mdl")
        ent:SetPos(Vector(-2185.035156, 1238.462280, 0.567021))
        ent:SetAngles(Angle(-0.878, -135.587, 1.082))
        ent:Spawn()
        self:RegisterEntity(ent)
        for k, v in pairs(player.GetAll()) do
            v:RemoveCarryItem("effigy1")
        end
    end)
    key:SetPickupFunction(function(self, ply, ent)
        ply:GiveCarryItem(self.id)
        ent:Remove()
    end)
    key:SetCondition( function(self, ply)
        return !ply:HasCarryItem("effigy1")
    end)
effigy1:Update()

local effigy2 = neItemCarry:CreateCategory("effigy2")
    effigy2:SetIcon("spawnicons/models/props_c17/doll01.png")
    effigy2:SetText("This might come in handy later...")
    effigy2:SetDropOnDowned(false)
    effigy2:SetShowNotification(true)
    effigy2:SetResetFunction(function(self)
        local spawn = babyspawns[math.random(#babyspawns)]
        local ent = ents.Create("nz_script_prop")
        ent:SetModel("models/props_c17/doll01.mdl")
        ent:SetPos(Vector(spawn.pos))
        ent:SetAngles(Angle(spawn.ang))
        ent:Spawn()
        self:RegisterEntity(ent)
        for k, v in pairs(player.GetAll()) do
            v:RemoveCarryItem("effigy2")
        end
    end)
    effigy2:SetPickupFunction(function(self, ply, ent)
        ply:GiveCarryItem(self.id)
        ent:Remove()
    end)
    effigy2:SetCondition( function(self, ply)
        return !ply:HasCarryItem("effigy2")
    end)
effigy2:Update()

local effigy3 = neItemCarry:CreateCategory("effigy3")
    effigy3:SetIcon("spawnicons/models/props_junk/garbage_newspaper001a.png")
    effigy3:SetText("This might come in handy later...")
    effigy3:SetDropOnDowned(false)
    effigy3:SetShowNotification(true)
    effigy3:SetResetFunction(function(self)
        local spawn = paperspawns[math.random(#paperspawns)]
        local ent = ents.Create("nz_script_prop")
        ent:SetModel("models/props_junk/garbage_newspaper001a.mdl")
        ent:SetPos(Vector(spawn.pos))
        ent:SetAngles(Angle(spawn.ang))
        ent:Spawn()
        self:RegisterEntity(ent)
        for k, v in pairs(player.GetAll()) do
            v:RemoveCarryItem("effigy3")
        end
    end)
    effigy3:SetPickupFunction(function(self, ply, ent)
        ply:GiveCarryItem(self.id)
        ent:Remove()
    end)
    effigy3:SetCondition( function(self, ply)
        return !ply:HasCarryItem("effigy3")
    end)
effigy3:Update()

local effigy4 = neItemCarry:CreateCategory("effigy4")
    effigy4:SetIcon("spawnicons/models/Gibs/HGIBS.png")
    effigy4:SetText("This might come in handy later...")
    effigy4:SetDropOnDowned(false)
    effigy4:SetShowNotification(true)
    effigy4:SetResetFunction(function(self)
        local spawn = skullspawns[math.random(#skullspawns)]
        local ent = ents.Create("nz_script_prop")
        ent:SetModel("models/Gibs/HGIBS.mdl")
        ent:SetPos(Vector(spawn.pos))
        ent:SetAngles(Angle(spawn.ang))
        ent:Spawn()
        self:RegisterEntity(ent)
        for k, v in pairs(player.GetAll()) do
            v:RemoveCarryItem("effigy4")
        end
    end)
    effigy4:SetPickupFunction(function(self, ply, ent)
        ply:GiveCarryItem(self.id)
        ent:Remove()
    end)
    effigy4:SetCondition( function(self, ply)
        return !ply:HasCarryItem("effigy4")
    end)
effigy4:Update()

--IN NEED OF HEAVY UPDATING
local buildabletbl = {
	model = "models/weapons/w_c4.mdl",
	pos = Vector( 10, 10, 10 ), --C4 Position, relative to the table
	ang = Angle( 0, 0, 0 ), --C4 Angles
	parts = {
		[ "charged_detonator" ] = { 0, 1 },
		[ "tire" ] = { 2 },
		[ "nitroamine" ] = { 3 },
		[ "blastcap" ] = { 4 }
	},
	usefunc = function( self, ply ) -- When it's completed and a player presses E
		if !ply:HasCarryItem( "c4" ) then
			ply:GiveCarryItem( "c4" )
		end
	end,
	--[[partadded = function(table, id, ply) -- When a part is added (optional)
		
	end,
	finishfunc = function(table) -- When all parts have been added (optional)
		
	end,]]
	text = "Press E to pick up the plastic explosive."
}

local escapeDetector = ents.Create("nz_script_prop")
escapeDetector:SetPos(Vector(-3832.5, 10583.5, 116))
escapeDetector:SetModel("models/hunter/blocks/cube2x2x2.mdl")
escapeDetector:SetTrigger(true) --Required for an entity to make use of StartTouch
escapeDetector:SetNoDraw(true)
escapeDetector:SetNotSolid(true)
escapeDetector:Spawn()
escapeDetector.StartTouch = MyStartTouch

--[[    Non-mapscript functions    ]]

--IN NEED OF HEAVY UPDATING
local finalround = 0
local function MyStartTouch( self, ply )
	if not ply:IsPlayer() and not ply:Alive() then return end
	finalround = nzRound:GetNumber()
	local escaped, escapednames = {}, {}
	ply:GodEnable() --Because cheeky nandos will try to break immersion by throwing explosives into the end area
	ply:SetTargetPriority( TARGET_PRIORITY_NONE )
	ply:Freeze( true )
	--//It was suggested to use GetAllPlayingAndAlive, but I want to avoid spectators doing nothing waiting for game to end
	if #player.GetAll() == 1 then
		nzEE.Cam:QueueView( 1, nil, nil, nil, true, nil, ply ) --Fade for aesthetics
		nzEE.Cam:QueueView( 15, Vector( -400.915161, -1325.068115, -380.741180 ), nil, Angle( 0.000, 91.500, 0.000 ), nil, nil, ply ) --Black screen
		nzEE.Cam:Music( "nz/easteregg/motd_good.wav", ply )
		nzEE.Cam:Text( "You escaped after ".. finalround .." rounds!", ply )
		--nzEE.Cam:QueueView( 0, Vector(  ), nil, Angle(  ), nil, nil, ply ) --Final Scene
		timer.Simple( 16, function()
			nzRound:Win( "Congratulations on escaping!", false )
			if ply:Alive() then ply:KillSilent() end
			ply:Freeze( false )
			ply:SetTargetPriority( TARGET_PRIORITY_PLAYER )
		end )
		nzEE.Cam:Begin()
		return
	end
	if not timer.Exists( "EscapeTimer" ) then
		timer.Create( "EscapeTimer", 30, 1, function()
			nzRound:Freeze( true )
			--//nzEE includes capability to target every player, but that leaves me without a way to target the players for Freezing and SetTargetPriority
			--//I don't know if including every nzEE function within the k, v is more or less efficient than not
			for k, v in pairs( player.GetAll() ) do
				v:Freeze( true )
				v:SetTargetPriority( TARGET_PRIORITY_NONE )
				nzEE.Cam:QueueView( 1, nil, nil, nil, true, nil, ply ) --Fade for aesthetics
				nzEE.Cam:QueueView( 15, Vector( -1243.480469, 668.968994, -176.465607 ), Vector( -1250.941895, -1273.481445, -164.941498 ), Angle( 0.000, -89.560, 0.000 ), true, nil, ply )
				if not escaped[ ply ] then
					nzEE.Cam:Music( "nz/easteregg/motd_bad.wav", ply )
					nzEE.Cam:Text( "You did not escape the facility...", ply )
				else
					nzEE.Cam:Music( "nz/easteregg/motd_good.wav", ply )
					nzEE.Cam:Text( "You escaped after ".. finalround .." rounds!", ply )
				end
				--[[nzEE.Cam:QueueView( 15, Vector(  ), Vector(  ), Angle(  ), true, nil, ply ) --Pan 1
				nzEE.Cam:Text( "Escapees: " .. table.concat( escapednames, ", " ) .. ".", ply ) 
				nzEE.Cam:QueueView( 15, Vector(  ), Vector(  ), Angle(  ), true, nil, ply ) --Pan 2
				nzEE.Cam:Text( "Thank you for playing!", ply )
				nzEE.Cam:QueueView( 0, Vector(  ), Vector(  ), Angle(  ), true, nil, ply ) --Final Scene]]
			end
			timer.Simple( 46, function() --After 20 more seconds, actually end the game
				nzRound:Win( "Congratulations to everyone who escaped!", false )
				for k, v in pairs( player.GetAllPlayingAndAlive() ) do
					v:Freeze( false )
					v:SetTargetPriority( TARGET_PRIORITY_PLAYER )
					if v:Alive() then v:KillSilent() end
				end
			end )
			timer.Destroy( "EscapeTimer" )
		end )
	end

	nzEE.Cam:QueueView( timer.TimeLeft( "EscapeTimer" ), Vector( -400.915161, -1325.068115, -380.741180 ), nil, Angle( 0.000, 91.500, 0.000 ), true, nil, ply )
	nzEE.Cam:Text( "Waiting for the rest of the players...", ply )
	PrintMessage( HUD_PRINTTALK, ply:Nick() .. " has escaped the map! All remaining players have " .. math.Round( timer.TimeLeft( "EscapeTimer" ) ) .. " seconds to follow suit!" ) --This should always be 30 the first time
	escaped[ ply ] = true --Used for logic
	table.insert( escapednames, ply:Nick() ) --Used for the end message
	nzEE.Cam:Begin()
end

function GetNavFlood(navArea, tab)
    for k, v in pairs(navArea:GetAdjacentAreas()) do 
        if not tab[v:GetID()] then 
            tab[v:GetID()] = true 
            GetNavFlood(v, tab) 
        end 
    end 
end

local NavAreaPrimarySeed = navmesh.GetNavAreaByID(5263) --The primary play area, contains 75% of the map
local NavAreaPrimaryList = {[5263] = true}
GetNavFlood(NavAreaPrimarySeed, NavAreaPrimaryList)
local NavAreaGeneratorSeed = navmesh.GetNavAreaByID(55) --The generator play area, very small, where the players teleport away from
local NavAreaGeneratorList = {[55] = true}
GetNavFlood(NavAreaGeneratorSeed, NavAreaGeneratorList)
local NavAreaTeleportSeed = navmesh.GetNavAreaByID(34) --The teleport-only play area players teleport to when no basement levers have been flipped
local NavAreaTeleportList = {[34] = true}
GetNavFlood(NavAreaTeleportSeed, NavAreaTeleportList)
local NavAreaBasementSeed = navmesh.GetNavAreaByID(77) --The entire basement play area
local NavAreaBasementList = {[77] = true}
GetNavFlood(NavAreaBasementSeed, NavAreaBasementList)

local allZombieSpawns = {{}, {}, {}, {}}
for k, v in pairs(ents.GetAll()) do
    if v:GetClass() == "nz_spawn_zombie_normal" or v:GetClass() == "nz_spawn_zombie_special" then
        v.spawnNav = navmesh.GetNearestNavArea(v:GetPos())
        v.spawnNavID = v.spawnNav:GetID()
        --No loop since no table
        if NavAreaPrimaryList[v.spawnNavID] then
            table.insert(allZombieSpawns[1], v)
            v.spawnZone = 1
        elseif NavAreaGeneratorList[v.spawnNavID] then
            table.insert(allZombieSpawns[2], v)
            v.spawnZone = 2
        elseif NavAreaTeleportList[v.spawnNavID] then
            table.insert(allZombieSpawns[3], v)
            v.spawnZone = 3
        elseif NavAreaBasementList[v.spawnNavID] then
            table.insert(allZombieSpawns[4], v)
            v.spawnZone = 4
        end
    end 
end

--Uses the ID to respawn all zombie entities of the specific ID, called when players have moved beyond a map area, via a ladder, teleporting, or the elevator
function CleanupZombies(id)
    print("CleanupZombies call with id " .. id)
    for k, v in pairs(ents.GetAll()) do
        if v:GetClass() == "nz_zombie_walker" or v:GetClass() == "nz_zombie_special_dog" or v:GetClass() == "nz_zombie_special_burning" then
            if v.spawnZone == id then
                v:RespawnZombie()
            end
        end
    end
end

--//Creates the lightning aura once around the given ent (lasts 0.5 seconds, approximately)
function Electrify(ent)
	local effect = EffectData()
	effect:SetScale(1)
	effect:SetEntity(ent)
	--util.Effect("lightning_aura", effect)
end

--//Creates a never-ending lightning aura around the given ent
function SetElectrify(ent, enable, scale)
    electrifiedEnts = electrifiedEnts or {}
    electrifiedScale = electrifiedScale or {}
    electrifiedEnts[ent] = enable
    electrifiedScale[ent] = scale or 1

    local effecttimer = 0
    hook.Add("Think", "PermaElectrifyEntities", function()
        if effecttimer < CurTime() then
            for k, v in pairs(electrifiedEnts) do
                if v then
                    local effect = EffectData()
                    effect:SetScale(1) --Does nothing?
                    effect:SetRadius(electrifiedScale[k])
                    effect:SetEntity(k)
                    --util.Effect("lightning_aura", effect)
                end
            end
            effecttimer = CurTime() + 0.3
        end
    end)
end

--This function teleports the player to the given pos with the given angle after a possible delay, and plays HUD and sound effects on the client
function SpecialTeleport(ply, pos, ang, delay)
	ply:GodEnable()
    ply:Lock()
    local oldPriority = ply:GetTargetPriority()
    ply:SetTargetPriority(TARGET_PRIORITY_NONE)
	SetElectrify(ply, true)
	timer.Simple(delay or 0, function()
        net.Start("RunTeleportOverlay")
        net.Send(ply)
	end)

	timer.Simple(2 + (delay or 0), function() --Delay the teleport for a bit to play sound & HUD effect
		ply:SetNoDraw(true) --may also need to set their equipped weapons invisible
		--ply:Freeze(true)
		SetElectrify(ply, false)

        --Full length of the HUD effects should be 4 seconds
		timer.Simple(2 - 1.4, function()
			local effectData = EffectData()
			effectData:SetOrigin(pos)
			effectData:SetMagnitude(2)
			effectData:SetEntity(nil)
			util.Effect("lightning_prespawn", effectData)

            timer.Simple(1.4, function()
                ply:SetPos(pos)
                ply:SetEyeAngles(ang)
        
				effectData = EffectData()
				effectData:SetStart(ply:GetPos() + Vector(0, 0, 1000))
				effectData:SetOrigin(ply:GetPos())
				effectData:SetMagnitude(0.75)
				util.Effect("lightning_strike", effectData)

				ply:SetNoDraw(false)
				ply:GodDisable()
                ply:UnLock()
                ply:SetTargetPriority(oldPriority)
                --Alternative idea to changing the collision group, we could also just kill the zombies in a box around it
				timer.Simple(1, function() --We don't want the player spawning inside a zombie and not being able to move
					ply:SetCollisionGroup(COLLISION_GROUP_NONE)
					timer.Simple(1, function()
						ply:SetCollisionGroup(COLLISION_GROUP_PLAYER) --Change back
					end)
				end)
			end)
		end)
	end)
end

--Generates a random set length totalDesired of values between 1 and maxNum as a table, returns nil if the 2 params are equal or total is under max
function GenerateRandomSet(maxNum, totalDesired)
    if totalDesired >= maxNum then
        return
    end

    local throwawayTab = {}
    for counter = 1, totalDesired do
        local randomNum = math.random(1, maxNum)
        while throwawayTab[randomNum] do
            randomNum = math.random(1, maxNum)
        end
        throwawayTab[randomNum] = true
    end

    return throwawayTab
end

function StartGeneratorHumm()
    if !generatorSoundEmitter then
        generatorSoundEmitter = ents.Create("nz_script_prop")
        generatorSoundEmitter:SetPos(Vector(4761, 4497.5, -73.0))
        generatorSoundEmitter:SetAngles(Angle(0, 0, 0))
        generatorSoundEmitter:SetModel("models/hunter/blocks/cube025x025x025.mdl") --can I create an ent with no model?
        generatorSoundEmitter:Spawn()
    end
    
    if !timer.Exists("GeneratorHumm2") then
        generatorSoundEmitter:EmitSound("nz/effects/generator2_start.wav", 130)
        timer.Simple(1.25, function() --generator2_start plays for 2.8 seconds
            timer.Create("GeneratorHumm2", 1.5, 0, function()
                generatorSoundEmitter:EmitSound("nz/effects/generator2_humm.wav", 130)
            end)
        end)
    end
end

function StopGeneratorHumm()
    if generatorSoundEmitter then
        timer.Simple(timer.TimeLeft("GeneratorHumm2"), function()
            generatorSoundEmitter:EmitSound("nz/effects/generator2_shutdown.wav", 130)
        end)
        timer.Remove("GeneratorHumm2")
    end
end

--[[    Mapscript functions    ]]

function mapscript.OnGameBegin()
    --Reset pick-up-able objects
    gascans:Reset()
    battery:Reset()
    key:Reset()

    tbl = ents.Create( "buildable_table" )
	tbl:AddValidCraft( "Plastic Explosive", buildabletbl )
	--tbl:SetPos( Vector( -1384.457886, 971.894897, -184.897278 ) )
	--tbl:SetAngles( Angle( 0.000, -90.000, 0.000 ) )
	tbl:Spawn()

    --Spawns the initial set of batteries
    local throwawayTab = GenerateRandomSet(#batteries, #batteries / 2)
    for k, v in pairs(batteries) do
        if throwawayTab[k] then
            local ent = ents.Create("nz_script_prop")
			ent:SetModel("models/zworld_equipment/zpile.mdl")
			ent:SetPos(v.pos)
			ent:SetAngles(v.ang)
			ent:Spawn()
            battery:RegisterEntity(ent)

            v.spawned = true
            v.ent = ent
            ent.charge = math.random(25, 80)

            ent:SetNWString("NZRequiredItem", "battery")
            ent:SetNWString("NZHasText", "Press E to add the battery to your flashlight.")
        end
    end

    --Disables flashlights on all players
    timer.Simple(0, function()
        for k, v in pairs(player.GetAll()) do
            mapscript.flashlightStatuses[v] = false
            v:AllowFlashlight(false)
        end
    end )

    --Creates spooky noises to play from radios
    timer.Create("RadioSounds", math.random(35, 50), 0, function()
        local sounds = {"numbers", "numbers2", "numbers3", "static", "static1", "static2", "whispers"}
		local soundToPlay = "radio sounds/" .. sounds[math.random(#sounds)] .. ".ogg"
		for k, v in pairs(radiosByID) do
			ents.GetMapCreatedEntity(v):EmitSound(soundToPlay, 90)
		end
    end)

    --Lock & apply text to the basement elevator
    local elDoor1 = ents.GetMapCreatedEntity("1825")
    elDoor1:Fire("Lock")
    elDoor1:SetNWString("NZText", "You must power the generator before calling the elevator")
    local elDoor2 = ents.GetMapCreatedEntity("1826")
    elDoor2:Fire("Lock")
    elDoor2:SetNWString("NZText", "You must power the generator before calling the elevator")
    local elButton = ents.GetMapCreatedEntity("2304")
    elButton:Fire("Lock")
    elButton:SetNWString("NZText", "You must power the generator before calling the elevator")

    --Lock the bunker elevator
    --ents.GetMapCreatedEntity("1907"):Fire("Use") --Inside elevator button
    ents.GetMapCreatedEntity("1907"):Fire("Lock")
    ents.GetMapCreatedEntity("1488"):Fire("Lock") --Main floor elevator button
    ents.GetMapCreatedEntity("1493"):Fire("Lock") --Elevator ent
    ents.GetMapCreatedEntity("1478"):SetPos(Vector(-2394, 1280, 64)) --Left door (closed position: Vector(-2394, 1280, 64))
    ents.GetMapCreatedEntity("1477"):SetPos(Vector(-2341, 1280, 64)) --Right door (closed position: Vector(-2341, 1280, 64))
    --Open the jail door in front of power generator room
    ents.GetMapCreatedEntity("2778"):Fire("Use")
    --Locks the associated padlocked doors
    ents.GetMapCreatedEntity("1567"):Fire("Lock")
    ents.GetMapCreatedEntity("2591"):Fire("Lock")
    ents.GetMapCreatedEntity("2592"):Fire("Lock")
    --Sets some flavor text for the destructable wall
    ents.GetMapCreatedEntity("1563"):SetNWString("NZText", "This part of the wall is awfully crumbly...")
    --Door to the power room, that doesn't seem to want to lock via door buy settings
    ents.GetMapCreatedEntity("1746"):Fire("Lock")

    --Reused on both the padlock and the door for both padlock-door sets
    function PadlockOnUseFunction(ent, ply, doorId)
        if ply:HasCarryItem("key") then
            ply:RemoveCarryItem("key")
            --Play unlock sound
            timer.Simple(0, function() --Length of the sound
                if ent:GetClass() == "prop_physics" then
                    ent:SetModel("models/props_wasteland/prison_padlock001b.mdl")
                    ent:GetPhysicsObject():EnableMotion(true)
                    ent:GetPhysicsObject():ApplyForceCenter(Vector(0, 0, 0))
                    ent:SetCollisionGroup(COLLISION_GROUP_WORLD)
                    ent:SetNWString("NZText", "")

                    local door = ents.GetMapCreatedEntity(doorId)
                    door:Fire("Unlock")
                    door:Fire("Use")
                    --door:Fire("Lock")
                    door.OnUsed = function(but, ply)
                        timer.Simple(0, function()
                            but:Fire("Lock")
                        end)
                    end
                else
                    ent:Fire("Unlock")
                    ent:Fire("Use")
                    --ent:Fire("Lock")
                    ent.OnUsed = function(but, ply)
                        timer.Simple(0, function()
                            but:Fire("Lock")
                        end)
                    end
                end

                if doorId == 1567 then
                    nzDoors:OpenLinkedDoors("Padlock1") --This will need to reflect in the config!!!!
                else
                    nzDoors:OpenLinkedDoors("Padlock2")
                end
            end)
        end
    end

    --Creates the padlock required to unlock to access power room
    local padlock1 = ents.Create("prop_physics")
    padlock1:SetPos(Vector(-1066.5, 2811.75, 38.9))
    padlock1:SetAngles(Angle(0, 180, 0))
    padlock1:SetModel("models/props_wasteland/prison_padlock001a.mdl")
    padlock1:SetNWString("NZText", "Locked, find a key")
    padlock1:SetNWString("NZRequiredItem", "key")
    padlock1:SetNWString("NZHasText", "Press E to unlock the padlock")
    padlock1:Spawn()
    padlock1:Activate()
    padlock1:GetPhysicsObject():EnableMotion(false)
    padlock1.OnUsed = function(ent, ply)
        PadlockOnUseFunction(ent, ply, 1567)
    end
    local padlock1door = ents.GetMapCreatedEntity(1567)
    padlock1door.OnUsed = function(ent, ply)
        PadlockOnUseFunction(ent, ply, 1567)
    end

    local padlock2 = ents.Create("prop_physics")
    padlock2:SetPos(Vector(-4132.473145, 2302.010010, 40.326866))
    padlock2:SetAngles(Angle(-0.000, -90.000, -0.000))
    padlock2:SetModel("models/props_wasteland/prison_padlock001a.mdl")
    padlock2:SetNWString("NZText", "Locked, find a key")
    padlock2:SetNWString("NZRequiredItem", "key")
    padlock2:SetNWString("NZHasText", "Press E to unlock the padlock")
    padlock2:Spawn()
    padlock2:Activate()
    padlock2:GetPhysicsObject():EnableMotion(false)
    padlock2.OnUsed = function(ent, ply)
        PadlockOnUseFunction(ent, ply, 2592)
    end
    local padlock2door = ents.GetMapCreatedEntity(2592)
    padlock2door.OnUsed = function(ent, ply)
        PadlockOnUseFunction(ent, ply, 2592)
    end

    --//Logic behind backup generator teleportation location
    --3 options: both, just nearest, just furthest
    local TeleportVariance = math.random(3)
    local lightOptions = {
        light1 = false,
        light2 = false,
        --Option 1: both activated/red
        {
            light1 = "models/props_c17/light_cagelight01_on.mdl",
            light2 = "models/props_c17/light_cagelight01_on.mdl",
            switch1 = true,
            switch2 = true
        },
        --Option 2: furthest only
        {
            light1 = "models/props_c17/light_cagelight02_on.mdl",
            light2 = "models/props_c17/light_cagelight01_on.mdl",
            switch1 = false,
            switch2 = true
        },
        --Option 3: closest only
        {
            light1 = "models/props_c17/light_cagelight01_on.mdl",
            light2 = "models/props_c17/light_cagelight02_on.mdl",
            switch1 = true,
            switch2 = false
        }
    }

    local light1 = ents.Create("prop_physics")
    light1:SetPos(Vector())
    light1:SetAngles(Angle())
    light1:SetModel(lightOptions[TeleportVariance].light1)
    light1:Spawn()
    light1:Activate()
    light1:GetPhysicsObject():EnableMotion(false)

    local light2 = ents.Create("prop_physics")
    light2:SetPos(Vector())
    light2:SetAngles(Angle())
    light2:SetModel(lightOptions[TeleportVariance].light2)
    light2:Spawn()
    light2:Activate()
    light2:GetPhysicsObject():EnableMotion(false)

    --Set up far lever (switch2)
    local sparkLever = ents.GetMapCreatedEntity("1921")
    --SetElectrify(sparkLever, true)
	sparkLever.OnUsed = function(but, ply)
		lightOptions.light1 = !lightOptions.light1

        local throwawayTab = {1, 3, 4} --Have to do this stupid work-around since these are hl2 sounds and there's no teleport2.wav
        timer.Simple(1, function()
            net.Start("RunSound")
                net.WriteString("ambient/machines/teleport" .. throwawayTab[math.random(#throwawayTab)] .. ".wav")
            net.Broadcast()
        end)
	end
    --Near lever (switch1)
    local nonSparkLever = ents.GetMapCreatedEntity("1920")
    --SetElectrify(nonSparkLever, true)
	nonSparkLever.OnUsed = function(but, ply)
		lightOptions.light2 = !lightOptions.light2
        
		local throwawayTab = {1, 3, 4}
        timer.Simple(1, function()
            net.Start("RunSound")
                net.WriteString("ambient/machines/teleport" .. throwawayTab[math.random(#throwawayTab)] .. ".wav")
            net.Broadcast()
        end)
	end

	--The generator power switch that teleports the player
    newPowerSwitch = ents.GetMapCreatedEntity("2767")
    mapscript.NewPowerSwitch = newPowerSwitch
    newPowerSwitch.OnUsed = function(button, ply)
        if newPowerSwitch.powerSwitchDelay or !ply then return end

        if !powerSwitchUsed then
            powerSwitchUsed = true
        end

        newPowerSwitch.powerSwitchDelay = true
        SetElectrify(button, true, 0.5)
        Electrify(ply)
        timer.Simple(30, function() newPowerSwitch.powerSwitchDelay = false SetElectrify(button, false) end)

		if nzElec:IsOn() then
            button:EmitSound("ambient/energy/zap" .. math.random(9) .. ".wav")

            local insta = DamageInfo()
            insta:SetAttacker(button)
            insta:SetDamageType(DMG_SHOCK)
            insta:SetDamage(ply:GetMaxHealth() - 1)
            ply:TakeDamageInfo(insta)

            timer.Simple(4, function()
                ents.GetMapCreatedEntity("2767"):Fire("Use")
            end)
        else
            timer.Simple(1, function()
                for k, v in pairs(player.GetAll()) do
                    v:ChatPrint("Backup generator started, building power online")
                end
                nzElec:Activate()
                StartGeneratorHumm()
            end)
        end

        local reteleportTime = math.random(30, 45)
        if lightOptions.light1 == lightOptions[TeleportVariance].light1 and lightOptions.light2 == lightOptions[TeleportVariance].light2 then
            SpecialTeleport(ply, possibleTeleports.pap.pos, possibleTeleports.pap.ang, 1)
            reteleportTime = math.random(45, 60)
        end
        
        timer.Simple(4, function() --Teleport HUD effects should take 4 seconds
            teleportTimers = teleportTimers or {}
            teleportTimers[ply:SteamID()] = reteleportTime
            net.Start("StartTeleportTimer")
                net.WriteInt(teleportTimers[ply:SteamID()], 16)
            net.Send(ply)

            timer.Create(ply:SteamID() .. "TeleportTimer", 1, 0, function()
                if !IsValid(ply) or !teleportTimers[ply:SteamID()] then 
                    timer.Remove(ply:SteamID() .. "TeleportTimer")
                end
                if teleportTimers[ply:SteamID()] == 0 or !ply:GetNotDowned() then
                    timer.Remove(ply:SteamID() .. "TeleportTimer")
                    SpecialTeleport(ply, spawnTeleport.pos, spawnTeleport.ang)
                    net.Start("UpdateTeleportTimer")
                        net.WriteInt(0, 16)
                    net.Send(ply)
                end

                teleportTimers[ply:SteamID()] = teleportTimers[ply:SteamID()] - 1
                net.Start("UpdateTeleportTimer")
                    net.WriteInt(teleportTimers[ply:SteamID()], 16)
                net.Send(ply)
            end)
        end)
        return true
	end

    --Creates the elevator generator
    local gasLevel, generatorPowered = 0, false
    local gen = ents.Create("nz_script_prop")
    gen:SetPos(Vector(-2723, 1790, 27.5))
    gen:SetAngles(Angle(0, -90, 0))
    gen:SetModel("models/props_wasteland/laundry_washer003.mdl")
    gen:SetNWString("NZText", "You must fill this generator with gasoline to power it")
    gen:SetNWString("NZRequiredItem", "gascan")
    gen:SetNWString("NZHasText", "Press E to fuel this generator with gasoline")
    gen:Spawn()
    gen:Activate()
    gen.OnUsed = function(self, ply)
        if ply:HasCarryItem("gascan") and !generatorPowered and !gasDelay then
            gasDelay = true
            gasLevel = gasLevel + 1

            --This feels unnecessary
            for num, tab in pairs(gascanspawns) do
                if tab.ent == ply.ent then
                    tab.used = true
                    tab.held = false
                    continue
                end
            end

            ply:RemoveCarryItem("gascan")
            gen:SetNWString("NZText", "")
            gen:SetNWString("NZHasText", "")
            gen:EmitSound("nz/effects/gas_pour.wav")

            --After the gas_pour sound has played
            timer.Simple(3, function()
                if not gen then return end
                gasDelay = false

                if gasLevel == 4 then
                    generatorPowered = true
                    gen:SetNWString("NZText", "This generator is powered on.")
                    gen:SetNWString("NZHasText", "") --There shouldn't be any more
                    gen:EmitSound("nz/effects/generator_start.wav")

                    elDoor1:Fire("Unlock")
                    elDoor2:Fire("Unlock")
                    elDoor1:SetNWString("NZText", "")
                    elDoor2:SetNWString("NZText", "")
                    elButton:SetNWString("NZText", "")

                    --After the 9 second generator_start sound has played
                    timer.Simple(9, function()
                        elButton:Fire("Unlock")
                        elButton:Fire("Use")
                        elButton:SetNWString("NZText", "The elevator is being called up")
                        nzDoors:OpenLinkedDoors("d1")

                        gen:EmitSound("nz/effects/generator_humm.ogg")
                        timer.Create("GeneratorHumm", 3, 0, function()
                            if not gen then return end
                            gen:EmitSound("nz/effects/generator_humm.ogg")
                        end)
                    end)
                else
                    gen:SetNWString("NZText", "The generator is currently " .. gasLevel .. "/4 full")
                    gen:SetNWString("NZHasText", "Press E to fuel this generator with gasoline")
                end
            end)
        end
    end
    gen.Think = function()
        --If the generator is removed, or the game has ended, destroy the "on" sound & timer
        if (!generatorPowered and gen:IsValid() or !gen:IsValid()) and timer.Exists("GeneratorHumm") then
            timer.Destroy("GeneratorHumm")
        end
    end

    --Sets up the map-spawned consoles to disable "system lockdown" which re-kills power
    mapscript.consoleButtons = {"1455", "2056", "1359", pressed = 0, ents = {}}
    for k, v in ipairs(mapscript.consoleButtons) do
        local console = ents.GetMapCreatedEntity(v)
        console:SetNWString("NZText", "Power must be activated")
        mapscript.consoleButtons[v] = false
        table.Add(mapscript.consoleButtons.ents, console)
        console.OnUsed = function()
            if nzElec:IsOn() and !mapscript.consoleButtons[v] then
                mapscript.consoleButtons[v] = true
                mapscript.consoleButtons.pressed = mapscript.consoleButtons.pressed + 1
                console:SetNWString("NZText", "")
                console:EmitSound("buttons/button4.wav")
                if mapscript.consoleButtons.pressed == 2 then
                    timer.Simple(1, function()
                        local throwawayTab = {1, 3, 4}
                        net.Start("RunSound")
                            net.WriteString("ambient/machines/teleport" .. throwawayTab[math.random(#throwawayTab)] .. ".wav")
                        net.Broadcast()
                        timer.Simple(1, function() nzElec:Reset())
                    end)
                end
            end
        end
    end

    --Reset possible battery levels after a new game
    for k, v in pairs(player.GetAll()) do
        mapscript.batteryLevels[v:SteamID()] = 0
    end

	--Timer for checking battery levels
	timer.Create("BatteryChecks", 2, 0, function()
		for k, v in pairs(player.GetAll()) do
			if v:Alive() and mapscript.batteryLevels[v:SteamID()] then
				if mapscript.batteryLevels[v:SteamID()] == 0 then
					v:Flashlight(false) --turns off the flashlight
                    v:AllowFlashlight(false) --prevents the flashlight from changing states
                    v:RemoveCarryItem("battery")
				end
                if v:FlashlightIsOn() then
					mapscript.batteryLevels[v:SteamID()] = math.Approach(mapscript.batteryLevels[v:SteamID()], 0, -1)--[[math.Clamp(mapscript.batteryLevels[v:SteamID()] - 1, 0, 100)]]
					net.Start("SendBatteryLevel")
						net.WriteInt(mapscript.batteryLevels[v:SteamID()], 16)
					net.Send(v)
				end
			end
		end
	end)
end

function mapscript.OnRoundStart()
	--Redundant flashlight-setting, for when players join mid-game
    timer.Simple(0, function()
        for k, v in pairs(player.GetAll()) do
            if mapscript.flashlightStatuses[v] then 
                v:AllowFlashlight(true)
            else 
                mapscript.flashlightStatuses[v] = false
                v:AllowFlashlight(false)
            end

            net.Start("StartBloodCount")
            net.Send(v)
        end
    end)

	--Randomly (re)spawn batteries
	local notSpawned = {}
	for k, v in pairs(batteries) do
        if !v.spawned then
            notSpawned[#notSpawned + 1] = {v, k}
        end
    end
    for k, v in pairs(player.GetAll()) do
        mapscript.batteryLevels[v:SteamID()] = mapscript.batteryLevels[v:SteamID()] or 0
    end
    
    newBat = notSpawned[math.random(#notSpawned)]
    local ent = ents.Create("nz_script_prop")
    ent:SetModel("models/zworld_equipment/zpile.mdl")
    ent:SetPos(newBat[1].pos)
    ent:SetAngles(newBat[1].ang)
    ent:Spawn()
    battery:RegisterEntity(ent)
    batteries[newBat[2]].ent = ent
    batteries[newBat[2]].spawned = true
    ent.charge = math.random(25, 80)
    ent:SetNWString("NZRequiredItem", "battery")
    ent:SetNWString("NZHasText", "Press E to add the battery to your flashlight.")

    --Redundantly remove the text, if a player joins in after the step as been completed
    --[[if mapscript.bloodGodKills >= mapscript.bloodGodKillsGoal then
        net.Start("RunCoward")
        net.Broadcast()
    end]]
end

function mapscript.ElectricityOn()
    if !postFirstActivation then
        for k, v in pairs(player.GetAll()) do
            v:ChatPrint("Building power enabled, system lockdown under effect...")
        end

        local colorEditor = ents.FindByClass("edit_color")[1]
        local contrastScale = 0.5 --This is the value it's set to in the config, we scale this value up here
        timer.Create("RemoveGrayscale", 0.5, 10, function()
            contrastScale = contrastScale + 0.05
            colorEditor:SetContrast(contrastScale)
        end)

        for k, v in pairs(mapscript.consoleButtons.ents) do
            v:SetNWString("NZText", "Press E to rescind system lockdown")
        end

		timer.Simple(5, function()
            local fakeSwitch, fakeLever = ents.Create("nz_script_prop"), ents.Create("nz_script_prop")
            --Move the power lever and replace it with a fake one

            --ents.FindByClass("power_box")[1]:SetPos()
		end)
	end
	postFirstActivation = true
end

function mapscript.OnGameEnd()
    powerSwitch = ents.FindByClass("power_box")[1]
    if powerSwitch and IsValid(powerSwitch) then 
        powerSwitch:Remove()
    end

    ents.FindByClass("edit_color")[1]:SetContrast(0.5)
end

--[[	Any hooks    ]]

--This is used to check if players enter/leave areas zombies can't travel through, and will need to respawn
hook.Add("Think", "CNavAreaChecking", function()
    if nzRound:GetState() == ROUND_CREATE then
        return
    end
    mapscript.area1 = mapscript.area1 or 0
    mapscript.area2 = mapscript.area2 or 0
    mapscript.area3 = mapscript.area3 or 0
    mapscript.area4 = mapscript.area4 or 0

    local area1, area2, area3, area4 = 0, 0, 0, 0
    for k, v in pairs(player.GetAll()) do
        if v:Alive() then
            for _, tab in pairs(areasByVector[1]) do
                if v:GetPos():WithinAABox(tab.pos1, tab.pos2) then
                    area1 = area1 + 1
                end
            end

            for _, tab in pairs(areasByVector[2]) do
                if v:GetPos():WithinAABox(tab.pos1, tab.pos2) then
                    area2 = area2 + 1
                end
            end

            for _, tab in pairs(areasByVector[3]) do
                if v:GetPos():WithinAABox(tab.pos1, tab.pos2) then
                    area3 = area3 + 1
                end
            end

            for _, tab in pairs(areasByVector[4]) do
                if v:GetPos():WithinAABox(tab.pos1, tab.pos2) then
                    area4 = area4 + 1
                end
            end
        end
    end

    --Really ugly, as 4 big-ass if statements
    --I should call update() on the one spawner ent to force the change immediately, but it's done every 4 seconds anyway
    if area1 != mapscript.area1 then
        print("Player count mismatch in area 1, old value: " .. mapscript.area1 .. ", new value: " .. area1)
        mapscript.area1 = area1
        if area1 < 1 then
            for k, v in pairs(allZombieSpawns[1]) do
                v.disabled = true
            end
            CleanupZombies(1)
        else
            print("Enabling zombie spawns in area1")
            for k, v in pairs(allZombieSpawns[1]) do
                v.disabled = false
            end
        end
    end
    if area2 != mapscript.area2 then
        print("Player count mismatch in area 2, old value: " .. mapscript.area2 .. ", new value: " .. area2)
        mapscript.area2 = area2
        if area2 < 1 then
            for k, v in pairs(allZombieSpawns[2]) do
                v.disabled = true
            end
            CleanupZombies(2)
        else
            print("Enabling zombie spawns in area2")
            for k, v in pairs(allZombieSpawns[2]) do
                v.disabled = false
            end
        end
    end
    if area3 != mapscript.area3 then
        print("Player count mismatch in area 3, old value: " .. mapscript.area3 .. ", new value: " .. area3)
        mapscript.area3 = area3
        if area3 < 1 then
            for k, v in pairs(allZombieSpawns[3]) do
                v.disabled = true
            end
            CleanupZombies(3)
        else
            print("Enabling zombie spawns in area3")
            for k, v in pairs(allZombieSpawns[3]) do
                v.disabled = false
            end
        end
    end
    if area4 != mapscript.area4 then
        print("Player count mismatch in area 4, old value: " .. mapscript.area4 .. ", new value: " .. area4)
        mapscript.area4 = area4
        if area4 < 1 then
            for k, v in pairs(allZombieSpawns[4]) do
                v.disabled = true
            end
            CleanupZombies(4)
        else
            print("Enabling zombie spawns in area4")
            for k, v in pairs(allZombieSpawns[4]) do
                v.disabled = false
            end
        end
    end
end)

hook.Add("OnZombieSpawned", "AssignSpawnID", function(zom, spawner)
    zom.spawnZone = spawner.spawnZone
end)

hook.Add("PlayerUse", "PreventPull", function(ply, button)
    if button == mapscript.NewPowerSwitch and button.powerSwitchDelay then
        return false
    end
end)

--[[    Overwritten Functions    ]]

--Overwrites default function, enables the "disabling" of spawns, used when players enter a different area
function Spawner:UpdateWeights()
	local plys = player.GetAllTargetable()
	for _, spawn in pairs(self.tSpawns) do
		-- reset
        spawn:SetSpawnWeight(0)
        if !spawn.disabled then
            local weight = math.huge
            for _, ply in pairs(plys) do
                local dist = spawn:GetPos():DistToSqr(ply:GetPos())
                if dist < weight then
                    weight = dist
                end
            end
            spawn:SetSpawnWeight(100000000 / weight)
        end
	end
end

--Overwrites default function, fixes spawning issues related to spawn weights when close to areas with disabled spawns
function Spawner:GetAverageWeight()
    local sum = 0
    local count = 0
    for _, spawn in pairs(self.tSpawns) do
        if !spawn.disabled then
            sum = sum + spawn:GetSpawnWeight()
            count = count + 1
        end
	end
	return ((sum / count) * 0.5) + 1500
end

return mapscript

--[[
Test Effects:
Useful EE function:
	nzNotifications:PlaySound("")
	nzRound:Freeze(true) --Prevents switching and spawning

    Script work:
    - CleanupZombies works incorrectly if you leave & re-enter the same area ID (no it's not? Don't know why it didn't work before)
    - Sound should play when unlocking padlock
    - Sound should play when picking up extra batteries
    - Lightning effect may not work properly on MAP-SPAWNED entities, potential work-around: just use the ent's position and don't set an ent, or recreate the ent but set it invisible
        Or maybe scale needs to be -1? Check zet's code...

    Nav work:
    - Zombies get stuck in "shower"-like area

    Theory work:
    - Spawning a boss
        - ent:SetSequence() - Sets an animation on a model