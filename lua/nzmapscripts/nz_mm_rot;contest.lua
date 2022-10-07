util.AddNetworkString("LoganRunSound")

local skullspawns = {
    {pos = Vector(304.499237, 1010.673462, 284.557831), ang = Angle(44.986, 147.314, -0.003)}, --Corner of main room
    {pos = Vector(-820.094360, 2237.027832, -28.537106), ang = Angle(-0.000, -156.880, 45.000)}, --In fireplace
    {pos = Vector(1473.607910, 1561.651367, 144.410141), ang = Angle(-29.361, -155.950, 17.396)}, --Out of map, against against handrails
    {pos = Vector(796.942261, 1123.194824, 278.961273), ang = Angle(45.000, 146.000, 0.000)} --Corner above Jugg
}

local flavorskulls = {
    {pos = Vector(-12.794922, -472.857483, -61.672523), ang = Angle(-46.073, 93.528, -3.181)},
    {pos = Vector(0.457985, -469.424957, -60.480034), ang = Angle(-44.190, 41.347, 17.533)},
    {pos = Vector(-22.606207, -467.593475, -60.053642), ang = Angle(-44.648, 137.528, -27.707)}
}

local busts = {
    1372, 1373
}

local jars = {
    1753, 1745, 1707, 2024
}

local jardepository = {
    {pos = Vector(-1111.5, 1985, 130), ang = Angle(0.000, 0.000, 0.000), mdl = "models/props_c17/concrete_barrier001a.mdl"},
    {pos = Vector(-1143, 1985, 130), ang = Angle(0.000, 0.000, 0.000), mdl = "models/props_c17/concrete_barrier001a.mdl"},
    {pos = Vector(-1127.5, 1952, 174), ang = Angle(0.000, 0.000, -0.000), mdl = "models/props_junk/metalbucket02a.mdl", usable = true},
    {pos = Vector(-1127.5, 2018.5, 174), ang = Angle(0.000, 0.000, -0.000), mdl = "models/props_junk/metalbucket02a.mdl", usable = true},
    {pos = Vector(-1127.8, 1985.9, 154.8), ang = Angle(0.000, 90.000, 0.000), mdl = "models/props_lab/filecabinet02.mdl"},
    {pos = Vector(-1107.3, 1989.6, 256.5), ang = Angle(-90.000, -0.000, 180.000), mdl = "models/props_junk/trashdumpster02b.mdl"}
}
local placedjars = {
    {pos = Vector(-1127.5, 2026, 171), ang = Angle(0.000, 90.000, -0.000), mdl = "models/props/spookington/eyejar.mdl"},
    {pos = Vector(-1127.5, 2010.5, 171), ang = Angle(0.000, -177.360, 0.000), mdl = "models/props/spookington/eyejar.mdl"},
    {pos = Vector(-1127.5, 1960.5, 171), ang = Angle(0.000, 92.200, 0.000), mdl = "models/props/spookington/eyejar.mdl"},
    {pos = Vector(-1127.5, 1944, 171), ang = Angle(0.000, 63.460, 0.000), mdl = "models/props/spookington/eyejar.mdl"}
}
local hintbust = {pos = Vector(-1127, 1987, 184.7), ang = Angle(0.000, 0.000, 0.000), mdl = "models/props_combine/breenbust.mdl"}

local mapscript = {}

local eyeballs = nzItemCarry:CreateCategory("eyeballs")
	eyeballs:SetIcon("spawnicons/models/props/spookington/eyejar.png") --this errors, what else should be used?
	eyeballs:SetText("Press E to pick up the jar of eyes")
	eyeballs:SetDropOnDowned(false)
	eyeballs:SetShowNotification(true)
	eyeballs:SetResetFunction(function(self)
		for _, id in pairs(jars) do
			local ent = ents.GetMapCreatedEntity(id)
			self:RegisterEntity(ent)
		end
	end)
	eyeballs:SetPickupFunction(function(self, ply, ent)
        ply:GiveCarryItem(self.id)
        ent:Remove()
	end)
	eyeballs:SetCondition( function(self, ply)
		return !ply:HasCarryItem("eyeballs")
	end)
eyeballs:Update()

function mapscript.OnGameBegin()
    eyeballs:Reset()

    for _, tab in pairs(skullspawns) do
        tab.destroyed = false
        local ent = ents.Create("nz_script_prop")
        ent:SetModel("models/monstermash/gibs/head_skull.mdl")
        ent:SetPos(tab.pos)
        ent:SetAngles(tab.ang)
        ent:Spawn()
        ent.OnTakeDamage = function(_, dmginfo)
            if !dmginfo or !dmginfo:GetAttacker():IsPlayer() or !dmginfo:IsBulletDamage() then return end
            ent:Remove()
            tab.destroyed = true

            for k, v in pairs(skullspawns) do
                if !v.destroyed then 
                    net.Start("LoganRunSound")
                        net.WriteString("ambient/creatures/town_moan1.wav") --ambient/machines/thumper_hit.wav
                        net.WriteInt(90, 16)
                    net.Broadcast()
                    return
                end
            end
            
            nzElec:Activate()
        end
    end

    for _, tab in pairs(flavorskulls) do
        local ent = ents.Create("nz_script_prop")
        ent:SetModel("models/monstermash/gibs/head_skull.mdl")
        ent:SetPos(tab.pos)
        ent:SetAngles(tab.ang)
        ent:Spawn()
    end

    for _, tab in pairs(jardepository) do
        local ent = ents.Create("nz_script_prop")
        ent:SetModel(tab.mdl)
        ent:SetPos(tab.pos)
        ent:SetAngles(tab.ang)
        ent:Spawn()

        if ent.usable then
            ent:SetNWString("NZText", "Looks hungry for some eyes")
            ent:SetNWString("NZRequiredItem", "eyeballs")
		    ent:SetNWString("NZHasText", "Press E to add some eyeballs")

            ent.OnUsed = function(self, ply)
                if ply:HasCarryItem("eyeballs") then
                    for k, v in pairs(placedjars) do
                        if !v.placed then
                            v.placed = true
                            
                            --Play nuckle crack animation

                            local ent2 = ents.Create("nz_script_prop")
                            ent2:SetModel(v.mdl)
                            ent2:SetPos(v.pos)
                            ent2:SetAngles(v.ang)
                            ent2:Spawn()

                            for k2, v2 in pairs(placedjars) do
                                if !v.placed then
                                    break
                                end
                            end

                            ElectrifyBusts()
                            break
                        end
                    end

                    ply:RemoveCarryItem("eyeballs")
                end
            end
        end
    end
end

hook.Add("EntityTakeDamage", "BustTakesDamage", function(ent, dmginfo)
    if ent and IsValid(ent) and ent:GetModel() == "models/props_combine/breenbust.mdl" and 
        engine.ActiveGamemode() == "nzombies" and game.GetMap() == "mm_rot" then
        print(dmginfo:GetDamageType())
    end
end)

function ElectrifyBusts()

end

--//Creates the lightning aura once around the given ent
function Electrify( ent )
	local effect = EffectData()
	effect:SetScale( 1 )
	effect:SetEntity( ent )
	util.Effect( "lightning_aura", effect )
end

--//Creates a never-ending lightning aura around the given ent
function SetPermaElectrify( penis )
	local function PermaElectrify( ent )
		if not game.active then --Find the appropriate variable/function return
			return false
		end
		local effecttimer = 0
		if effecttimer < CurTime() then
			local effect = EffectData()
			effect:SetScale( 1 )
			effect:SetEntity( ent )
			util.Effect( "lightning_aura", effect )
			effecttimer = CurTime() + 1
		end
	end
	penis.Think = PermaElectrify
end

return mapscript