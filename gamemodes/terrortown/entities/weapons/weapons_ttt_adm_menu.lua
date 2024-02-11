AddCSLuaFile()

local math = math
local util = util
local timer = timer
local hook = hook
local table = table
local ents = ents

local MathRandom = math.random
local MathRand = math.Rand
local MathSqrt = math.sqrt
local MathNormalizeAngle = math.NormalizeAngle
local TableInsert = table.insert

if CLIENT then
    SWEP.PrintName          = "Admin Menu"
    SWEP.Slot               = 8

    SWEP.ViewModelFOV       = 60
    SWEP.DrawCrosshair      = false
    SWEP.ViewModelFlip      = false
end

SWEP.ViewModel              = "models/weapons/v_slam.mdl"
SWEP.WorldModel             = "models/weapons/w_slam.mdl"
SWEP.Weight                 = 2

SWEP.Base                   = "weapon_tttbase"
SWEP.Category               = WEAPON_CATEGORY_ROLE

SWEP.Spawnable              = false
SWEP.AutoSpawnable          = false
SWEP.HoldType               = "slam"
SWEP.Kind                   = WEAPON_ROLE

SWEP.DeploySpeed            = 4
SWEP.AllowDrop              = false
SWEP.NoSights               = true
SWEP.UseHands               = true
SWEP.LimitedStock           = true
SWEP.AmmoEnt                = nil

SWEP.Primary.Delay          = 0.2
SWEP.Primary.Automatic      = false
SWEP.Primary.Cone           = 0
SWEP.Primary.Ammo           = nil
SWEP.Primary.ClipSize       = -1
SWEP.Primary.ClipMax        = -1
SWEP.Primary.DefaultClip    = -1
SWEP.Primary.Sound          = ""

SWEP.Secondary.Delay        = 0.2
SWEP.Secondary.Automatic    = false
SWEP.Secondary.Cone         = 0
SWEP.Secondary.Ammo         = nil
SWEP.Secondary.ClipSize     = -1
SWEP.Secondary.ClipMax      = -1
SWEP.Secondary.DefaultClip  = -1
SWEP.Secondary.Sound        = ""

SWEP.InLoadoutFor           = {ROLE_ADMIN}
SWEP.InLoadoutForDefault    = {ROLE_ADMIN}

local admin_slap_cost = CreateConVar("ttt_admin_slap_cost", 10, FCVAR_REPLICATED, "The amount of admin power it costs to use the slap command. Set to 0 to disable", 0, 100)
local admin_bring_cost = CreateConVar("ttt_admin_bring_cost", 15, FCVAR_REPLICATED, "The amount of admin power it costs to use the bring command. Set to 0 to disable", 0, 100)
local admin_goto_cost = CreateConVar("ttt_admin_goto_cost", 15, FCVAR_REPLICATED, "The amount of admin power it costs to use the goto command. Set to 0 to disable", 0, 100)
local admin_send_cost = CreateConVar("ttt_admin_send_cost", 20, FCVAR_REPLICATED, "The amount of admin power it costs to use the send command. Set to 0 to disable", 0, 100)
local admin_jail_cost = CreateConVar("ttt_admin_jail_cost", 5, FCVAR_REPLICATED, "The amount of admin power it costs to use the jail command per second. Set to 0 to disable", 0, 100)
local admin_ignite_cost = CreateConVar("ttt_admin_ignite_cost", 10, FCVAR_REPLICATED, "The amount of admin power it costs to use the ignite command per second. Set to 0 to disable", 0, 100)
local admin_blind_cost = CreateConVar("ttt_admin_blind_cost", 10, FCVAR_REPLICATED, "The amount of admin power it costs to use the blind command per second. Set to 0 to disable", 0, 100)
local admin_freeze_cost = CreateConVar("ttt_admin_freeze_cost", 10, FCVAR_REPLICATED, "The amount of admin power it costs to use the freeze command per second. Set to 0 to disable", 0, 100)
local admin_ragdoll_cost = CreateConVar("ttt_admin_ragdoll_cost", 10, FCVAR_REPLICATED, "The amount of admin power it costs to use the ragdoll command per second. Set to 0 to disable", 0, 100)
local admin_strip_cost = CreateConVar("ttt_admin_strip_cost", 60, FCVAR_REPLICATED, "The amount of admin power it costs to use the strip command. Set to 0 to disable", 0, 100)
local admin_respawn_cost = CreateConVar("ttt_admin_respawn_cost", 60, FCVAR_REPLICATED, "The amount of admin power it costs to use the respawn command. Set to 0 to disable", 0, 100)
local admin_slay_cost = CreateConVar("ttt_admin_slay_cost", 80, FCVAR_REPLICATED, "The amount of admin power it costs to use the slay command. Set to 0 to disable", 0, 100)
local admin_kick_cost = CreateConVar("ttt_admin_kick_cost", 100, FCVAR_REPLICATED, "The amount of admin power it costs to use the kick command. Set to 0 to disable", 0, 100)

if SERVER then
    util.AddNetworkString("TTT_AdminSlapCommand")
    util.AddNetworkString("TTT_AdminBringCommand")
    util.AddNetworkString("TTT_AdminGotoCommand")
    util.AddNetworkString("TTT_AdminSendCommand")
    util.AddNetworkString("TTT_AdminJailCommand")
    util.AddNetworkString("TTT_AdminIgniteCommand")
    util.AddNetworkString("TTT_AdminBlindCommand")
    util.AddNetworkString("TTT_AdminFreezeCommand")
    util.AddNetworkString("TTT_AdminRagdollCommand")
    util.AddNetworkString("TTT_AdminStripCommand")
    util.AddNetworkString("TTT_AdminRespawnCommand")
    util.AddNetworkString("TTT_AdminSlayCommand")
    util.AddNetworkString("TTT_AdminKickCommand")
end

function SWEP:Initialize()
    self:SendWeaponAnim(ACT_SLAM_DETONATOR_DRAW)
    if CLIENT then
        self:AddHUDHelp("adminmenu_help_pri", nil, true)
    end
    return self.BaseClass.Initialize(self)
end

function SWEP:OnDrop()
    self:Remove()
end

function SWEP:Deploy()
    if SERVER and IsValid(self:GetOwner()) then
        self:GetOwner():DrawViewModel(false)
    end

    self:DrawShadow(false)
    self:SendWeaponAnim(ACT_SLAM_DETONATOR_DRAW)
    return true
end

function SWEP:PrimaryAttack()
    if not IsFirstTimePredicted() then return end
    self:SetNextSecondaryFire(CurTime() + self.Secondary.Delay)
    if CLIENT then
        -- TODO: Build admin menu UI
    end
end

if SERVER then
    local function Slap(admin, ply) -- Function modified from ULX and ULib
        if not IsPlayer(admin) or not admin:IsActiveAdmin() then return end
        if not IsPlayer(ply) then return end
        if not ply:IsActive() then
            admin:PrintMessage(HUD_PRINTTALK, ply:Nick() .. " is dead. Your admin power was not used.")
            return false
        end

        local slapSounds = {
            "physics/body/body_medium_impact_hard1.wav",
            "physics/body/body_medium_impact_hard2.wav",
            "physics/body/body_medium_impact_hard3.wav",
            "physics/body/body_medium_impact_hard5.wav",
            "physics/body/body_medium_impact_hard6.wav",
            "physics/body/body_medium_impact_soft5.wav",
            "physics/body/body_medium_impact_soft6.wav",
            "physics/body/body_medium_impact_soft7.wav",
        }
        local power = 500

        if ply:InVehicle() then
            ply:ExitVehicle()
        end

        local sound_num = MathRandom(#slapSounds)
        ply:EmitSound(slapSounds[sound_num])

        local direction = Vector(MathRand( -10, 10 ), MathRand( -10, 10 ), 15)
        direction:Normalize()
        ply:SetVelocity(direction * power)

        local angle_punch_pitch = MathRand(-20, 20)
        local angle_punch_yaw = MathSqrt(400 - angle_punch_pitch * angle_punch_pitch)
        if MathRandom() < 0.5 then
            angle_punch_yaw = angle_punch_yaw * -1
        end
        ply:ViewPunch(Angle(angle_punch_pitch, angle_punch_yaw, 0))

        net.Start("TTT_AdminMessage")
        net.WriteUInt(3, 4)
        net.WriteUInt(ADMIN_MESSAGE_PLAYER, 2)
        net.WriteString(admin:SteamID64())
        net.WriteUInt(ADMIN_MESSAGE_TEXT, 2)
        net.WriteString(" slapped ")
        net.WriteUInt(ADMIN_MESSAGE_PLAYER, 2)
        net.WriteString(ply:SteamID64())
        net.Broadcast()

        return true
    end
    net.Receive("TTT_AdminSlapCommand", function(_, admin)
        local sid64 = net.ReadString()
        local ply = player.GetBySteamID64(sid64)

        local cost = admin_slap_cost:GetInt()
        local power = admin:GetNWInt("TTTAdminPower")
        if power < cost then return end

        if Slap(admin, ply) then
            admin:SetNWInt("TTTAdminPower", power - cost)
        end
    end)

    local function Teleport(admin, from, to) -- Function modified from ULX and ULib
        if not IsPlayer(admin) or not admin:IsActiveAdmin() then return end
        if not IsPlayer(from) or not IsPlayer(to) then return end
        if not from:IsActive() then
            admin:PrintMessage(HUD_PRINTTALK, from:Nick() .. " is dead. Your admin power was not used.")
            return false
        end
        if not to:IsActive() then
            admin:PrintMessage(HUD_PRINTTALK, to:Nick() .. " is dead. Your admin power was not used.")
            return false
        end
        if not to:IsInWorld() then
            admin:PrintMessage(HUD_PRINTTALK, "Cannot find space to teleport to " .. to:Nick() .. ". Your admin power was not used.")
            return false
        end

        if from:InVehicle() then
            from:ExitVehicle()
        end
        if to:InVehicle() then
            to:ExitVehicle()
        end

        local yawForward = to:EyeAngles().yaw
        local directions = {
            yawForward,
            MathNormalizeAngle(yawForward + 90),
            MathNormalizeAngle(yawForward - 90),
            MathNormalizeAngle(yawForward - 180)
        }

        local target = to:GetPos()
        local t = {}
        t.start = target + Vector(0, 0, 32)
        t.filter = {to, from}

        for _, dir in ipairs(directions) do
            t.endpos = to:GetPos() + Angle(0, dir, 0):Forward() * 50
            local tr = util.TraceEntity(t, from)
            if not tr.Hit then
                from:SetPos(tr.HitPos)
                from:SetEyeAngles((target - tr.HitPos):Angle())
                from:SetLocalVelocity(Vector(0, 0, 0))

                return true
            end
        end

        admin:PrintMessage(HUD_PRINTTALK, "Cannot find space to teleport to " .. to:Nick() .. ". Your admin power was not used.")
        return false
    end

    local function Bring(admin, ply)
        if Teleport(admin, ply, admin) then
            net.Start("TTT_AdminMessage")
            net.WriteUInt(3, 4)
            net.WriteUInt(ADMIN_MESSAGE_PLAYER, 2)
            net.WriteString(admin:SteamID64())
            net.WriteUInt(ADMIN_MESSAGE_TEXT, 2)
            net.WriteString(" brought ")
            net.WriteUInt(ADMIN_MESSAGE_PLAYER, 2)
            net.WriteString(ply:SteamID64())
            net.Broadcast()

            return true
        end

        return false
    end
    net.Receive("TTT_AdminBringCommand", function(_, admin)
        local sid64 = net.ReadString()
        local ply = player.GetBySteamID64(sid64)

        local cost = admin_bring_cost:GetInt()
        local power = admin:GetNWInt("TTTAdminPower")
        if power < cost then return end

        if Bring(admin, ply) then
            admin:SetNWInt("TTTAdminPower", power - cost)
        end
    end)

    local function Goto(admin, ply)
        if Teleport(admin, admin, ply) then
            net.Start("TTT_AdminMessage")
            net.WriteUInt(3, 4)
            net.WriteUInt(ADMIN_MESSAGE_PLAYER, 2)
            net.WriteString(admin:SteamID64())
            net.WriteUInt(ADMIN_MESSAGE_TEXT, 2)
            net.WriteString(" teleported to ")
            net.WriteUInt(ADMIN_MESSAGE_PLAYER, 2)
            net.WriteString(ply:SteamID64())
            net.Broadcast()

            return true
        end

        return false
    end
    net.Receive("TTT_AdminGotoCommand", function(_, admin)
        local sid64 = net.ReadString()
        local ply = player.GetBySteamID64(sid64)

        local cost = admin_goto_cost:GetInt()
        local power = admin:GetNWInt("TTTAdminPower")
        if power < cost then return end

        if Goto(admin, ply) then
            admin:SetNWInt("TTTAdminPower", power - cost)
        end
    end)

    local function Send(admin, from, to)
        if Teleport(admin, from, to) then
            net.Start("TTT_AdminMessage")
            net.WriteUInt(5, 4)
            net.WriteUInt(ADMIN_MESSAGE_PLAYER, 2)
            net.WriteString(admin:SteamID64())
            net.WriteUInt(ADMIN_MESSAGE_TEXT, 2)
            net.WriteString(" transported ")
            net.WriteUInt(ADMIN_MESSAGE_PLAYER, 2)
            net.WriteString(from:SteamID64())
            net.WriteUInt(ADMIN_MESSAGE_TEXT, 2)
            net.WriteString(" to ")
            net.WriteUInt(ADMIN_MESSAGE_PLAYER, 2)
            net.WriteString(to:SteamID64())
            net.Broadcast()

            return true
        end

        return false
    end
    net.Receive("TTT_AdminSendCommand", function(_, admin)
        local fromSid64 = net.ReadString()
        local from = player.GetBySteamID64(fromSid64)
        local toSid64 = net.ReadString()
        local to = player.GetBySteamID64(toSid64)

        local cost = admin_send_cost:GetInt()
        local power = admin:GetNWInt("TTTAdminPower")
        if power < cost then return end

        if Send(admin, from, to) then
            admin:SetNWInt("TTTAdminPower", power - cost)
        end
    end)

    local function Jail(admin, ply, time) -- Function modified from ULX and ULib
        if not IsPlayer(admin) or not admin:IsActiveAdmin() then return end
        if not IsPlayer(ply) then return end
        if not ply:IsActive() then
            admin:PrintMessage(HUD_PRINTTALK, ply:Nick() .. " is dead. Your admin power was not used.")
            return false
        end

        local jailWalls = {
            {pos = Vector(0, 0, -5), ang = Angle(90, 0, 0)},
            {pos = Vector(0, 0, 97), ang = Angle(90, 0, 0)},
            {pos = Vector(21, 31, 46), ang = Angle(0, 90, 0)},
            {pos = Vector(21, -31, 46), ang = Angle(0, 90, 0)},
            {pos = Vector(-21, 31, 46), ang = Angle(0, 90, 0)},
            {pos = Vector(-21, -31, 46), ang = Angle(0, 90, 0)},
            {pos = Vector(-52, 0, 46), ang = Angle(0, 0, 0)},
            {pos = Vector(52, 0, 46), ang = Angle(0, 0, 0)},
        }
        local sid64 = ply:SteamID64()

        if timer.Exists("AdminJail_" .. sid64) then
            admin:PrintMessage(HUD_PRINTTALK, ply:Nick() .. " is already in jail. Your admin power was not used.")
            return false
        end

        if ply:InVehicle() then
            local vehicle = ply:GetParent()
            ply:ExitVehicle()
            vehicle:Remove()
        end

        local wallEnts = {}
        for _, v in ipairs(jailWalls) do
            local ent = ents.Create("prop_physics")
            ent:SetModel(Model("models/props_building_details/Storefront_Template001a_Bars.mdl"))
            ent:SetPos(ply:GetPos() + v.pos)
            ent:SetAngles(v.ang)
            ent:Spawn()
            ent:GetPhysicsObject():EnableMotion(false)
            ent:SetMoveType(MOVETYPE_NONE)
            TableInsert(wallEnts, ent)
        end

        local function RemoveWalls()
            for _, ent in ipairs(wallEnts) do
                if ent:IsValid() then
                    ent:Remove()
                end
            end
        end

        hook.Add("TTTEndRound", "Admin_TTTEndRound_Jail_" .. sid64, function()
            local timerIdentifier = "AdminJail_" .. sid64
            if timer.Exists(timerIdentifier) then
                RemoveWalls()
                timer.Remove(timerIdentifier)
                hook.Remove("PlayerDisconnected", "Admin_PlayerDisconnected_Jail_" .. sid64)
                hook.Remove("TTTEndRound", "Admin_TTTEndRound_Jail_" .. sid64)
            end
        end)

        hook.Add("PlayerDisconnected", "Admin_PlayerDisconnected_Jail_" .. sid64, function(p)
            if p:SteamID64() ~= sid64 then return end
            local timerIdentifier = "AdminJail_" .. sid64
            if timer.Exists(timerIdentifier) then
                RemoveWalls()
                timer.Remove(timerIdentifier)
                hook.Remove("TTTEndRound", "Admin_TTTEndRound_Jail_" .. sid64)
                hook.Remove("PlayerDisconnected", "Admin_PlayerDisconnected_Jail_" .. sid64)
            end
        end)

        timer.Create("AdminJail_" .. sid64, time, 1, function()
            RemoveWalls()
            hook.Remove("TTTEndRound", "Admin_TTTEndRound_Jail_" .. sid64)
            hook.Remove("PlayerDisconnected", "Admin_PlayerDisconnected_Jail_" .. sid64)
        end)

        net.Start("TTT_AdminMessage")
        net.WriteUInt(6, 4)
        net.WriteUInt(ADMIN_MESSAGE_PLAYER, 2)
        net.WriteString(admin:SteamID64())
        net.WriteUInt(ADMIN_MESSAGE_TEXT, 2)
        net.WriteString(" jailed ")
        net.WriteUInt(ADMIN_MESSAGE_PLAYER, 2)
        net.WriteString(ply:SteamID64())
        net.WriteUInt(ADMIN_MESSAGE_TEXT, 2)
        net.WriteString(" for ")
        net.WriteUInt(ADMIN_MESSAGE_VARIABLE, 2)
        net.WriteString(tostring(time))
        net.WriteUInt(ADMIN_MESSAGE_TEXT, 2)
        net.WriteString(" seconds")
        net.Broadcast()

        return true
    end
    net.Receive("TTT_AdminJailCommand", function(_, admin)
        local sid64 = net.ReadString()
        local ply = player.GetBySteamID64(sid64)
        local time = net.ReadUInt(8)

        local cost = admin_jail_cost:GetInt()
        local power = admin:GetNWInt("TTTAdminPower")
        if power < cost then return end

        if Jail(admin, ply, time) then
            admin:SetNWInt("TTTAdminPower", power - cost)
        end
    end)

    local function Ignite(admin, ply, time)
        if not IsPlayer(admin) or not admin:IsActiveAdmin() then return end
        if not IsPlayer(ply) then return end
        if not ply:IsActive() then
            admin:PrintMessage(HUD_PRINTTALK, ply:Nick() .. " is dead. Your admin power was not used.")
            return false
        end

        if ply:IsOnFire() then
            admin:PrintMessage(HUD_PRINTTALK, ply:Nick() .. " is already on fire. Your admin power was not used.")
            return false
        end

        ply:Ignite(time)

        net.Start("TTT_AdminMessage")
        net.WriteUInt(6, 4)
        net.WriteUInt(ADMIN_MESSAGE_PLAYER, 2)
        net.WriteString(admin:SteamID64())
        net.WriteUInt(ADMIN_MESSAGE_TEXT, 2)
        net.WriteString(" ignited ")
        net.WriteUInt(ADMIN_MESSAGE_PLAYER, 2)
        net.WriteString(ply:SteamID64())
        net.WriteUInt(ADMIN_MESSAGE_TEXT, 2)
        net.WriteString(" for ")
        net.WriteUInt(ADMIN_MESSAGE_VARIABLE, 2)
        net.WriteString(tostring(time))
        net.WriteUInt(ADMIN_MESSAGE_TEXT, 2)
        net.WriteString(" seconds")
        net.Broadcast()

        return true
    end
    net.Receive("TTT_AdminIgniteCommand", function(_, admin)
        local sid64 = net.ReadString()
        local ply = player.GetBySteamID64(sid64)
        local time = net.ReadUInt(8)

        local cost = admin_ignite_cost:GetInt()
        local power = admin:GetNWInt("TTTAdminPower")
        if power < cost then return end

        if Ignite(admin, ply, time) then
            admin:SetNWInt("TTTAdminPower", power - cost)
        end
    end)

    local function Blind(admin, ply, time) -- Function modified from ULX and ULib
        if not IsPlayer(admin) or not admin:IsActiveAdmin() then return end
        if not IsPlayer(ply) then return end
        if not ply:IsActive() then
            admin:PrintMessage(HUD_PRINTTALK, ply:Nick() .. " is dead. Your admin power was not used.")
            return false
        end

        local sid64 = ply:SteamID64()

        if timer.Exists("AdminBlind_" .. sid64) then
            admin:PrintMessage(HUD_PRINTTALK, ply:Nick() .. " is already blind. Your admin power was not used.")
            return false
        end

        net.Start("TTT_AdminBlindClient")
        net.WriteBool(true)
        net.Send(ply)

        local function Unblind()
            if not IsPlayer(ply) then return end
            net.Start("TTT_AdminBlindClient")
            net.WriteBool(false)
            net.Send(ply)
        end

        hook.Add("TTTEndRound", "Admin_TTTEndRound_Blind_" .. sid64, function()
            local timerIdentifier = "AdminBlind_" .. sid64
            if timer.Exists(timerIdentifier) then
                Unblind()
                timer.Remove(timerIdentifier)
                hook.Remove("PlayerDeath", "Admin_PlayerDeath_Blind_" .. sid64)
                hook.Remove("TTTEndRound", "Admin_TTTEndRound_Blind_" .. sid64)
            end
        end)

        hook.Add("PlayerDeath", "Admin_PlayerDeath_Blind_", function(p, _, _)
            if p:SteamID64() ~= sid64 then return end
            local timerIdentifier = "AdminBlind_" .. sid64
            if timer.Exists(timerIdentifier) then
                Unblind()
                timer.Remove(timerIdentifier)
                hook.Remove("TTTEndRound", "Admin_TTTEndRound_Blind_" .. sid64)
                hook.Remove("PlayerDeath", "Admin_PlayerDeath_Blind_" .. sid64)
            end
        end)

        timer.Create("AdminBlind_" .. sid64, time, 1, function()
            Unblind()
            hook.Remove("TTTEndRound", "Admin_TTTEndRound_Blind_" .. sid64)
            hook.Remove("PlayerDeath", "Admin_PlayerDeath_Blind_" .. sid64)
        end)

        net.Start("TTT_AdminMessage")
        net.WriteUInt(6, 4)
        net.WriteUInt(ADMIN_MESSAGE_PLAYER, 2)
        net.WriteString(admin:SteamID64())
        net.WriteUInt(ADMIN_MESSAGE_TEXT, 2)
        net.WriteString(" blinded ")
        net.WriteUInt(ADMIN_MESSAGE_PLAYER, 2)
        net.WriteString(ply:SteamID64())
        net.WriteUInt(ADMIN_MESSAGE_TEXT, 2)
        net.WriteString(" for ")
        net.WriteUInt(ADMIN_MESSAGE_VARIABLE, 2)
        net.WriteString(tostring(time))
        net.WriteUInt(ADMIN_MESSAGE_TEXT, 2)
        net.WriteString(" seconds")
        net.Broadcast()

        return true
    end
    net.Receive("TTT_AdminBlindCommand", function(_, admin)
        local sid64 = net.ReadString()
        local ply = player.GetBySteamID64(sid64)
        local time = net.ReadUInt(8)

        local cost = admin_blind_cost:GetInt()
        local power = admin:GetNWInt("TTTAdminPower")
        if power < cost then return end

        if Blind(admin, ply, time) then
            admin:SetNWInt("TTTAdminPower", power - cost)
        end
    end)

    local function Freeze(admin, ply, time)
        if not IsPlayer(admin) or not admin:IsActiveAdmin() then return end
        if not IsPlayer(ply) then return end
        if not ply:IsActive() then
            admin:PrintMessage(HUD_PRINTTALK, ply:Nick() .. " is dead. Your admin power was not used.")
            return false
        end

        local sid64 = ply:SteamID64()

        if timer.Exists("AdminFreeze_" .. sid64) then
            admin:PrintMessage(HUD_PRINTTALK, ply:Nick() .. " is already frozen. Your admin power was not used.")
            return false
        end

        if ply:InVehicle() then
            ply:ExitVehicle()
        end

        ply:Freeze(true)

        local function Unfreeze()
            if not IsPlayer(ply) or not ply:IsActive() then return end
            ply:Freeze(false)
        end

        hook.Add("TTTEndRound", "Admin_TTTEndRound_Freeze_" .. sid64, function()
            local timerIdentifier = "AdminFreeze_" .. sid64
            if timer.Exists(timerIdentifier) then
                Unfreeze()
                timer.Remove(timerIdentifier)
                hook.Remove("TTTEndRound", "Admin_TTTEndRound_Freeze_" .. sid64)
            end
        end)

        timer.Create("AdminFreeze_" .. sid64, time, 1, function()
            Unfreeze()
            hook.Remove("TTTEndRound", "Admin_TTTEndRound_Freeze_" .. sid64)
        end)

        net.Start("TTT_AdminMessage")
        net.WriteUInt(6, 4)
        net.WriteUInt(ADMIN_MESSAGE_PLAYER, 2)
        net.WriteString(admin:SteamID64())
        net.WriteUInt(ADMIN_MESSAGE_TEXT, 2)
        net.WriteString(" froze ")
        net.WriteUInt(ADMIN_MESSAGE_PLAYER, 2)
        net.WriteString(ply:SteamID64())
        net.WriteUInt(ADMIN_MESSAGE_TEXT, 2)
        net.WriteString(" for ")
        net.WriteUInt(ADMIN_MESSAGE_VARIABLE, 2)
        net.WriteString(tostring(time))
        net.WriteUInt(ADMIN_MESSAGE_TEXT, 2)
        net.WriteString(" seconds")
        net.Broadcast()

        return true
    end
    net.Receive("TTT_AdminFreezeCommand", function(_, admin)
        local sid64 = net.ReadString()
        local ply = player.GetBySteamID64(sid64)
        local time = net.ReadUInt(8)

        local cost = admin_freeze_cost:GetInt()
        local power = admin:GetNWInt("TTTAdminPower")
        if power < cost then return end

        if Freeze(admin, ply, time) then
            admin:SetNWInt("TTTAdminPower", power - cost)
        end
    end)

    local function Ragdoll(admin, ply, time) -- Function modified from ULX, ULib and the Possum role
        if not IsPlayer(admin) or not admin:IsActiveAdmin() then return end
        if not IsPlayer(ply) then return end
        if not ply:IsActive() then
            admin:PrintMessage(HUD_PRINTTALK, ply:Nick() .. " is dead. Your admin power was not used.")
            return false
        end

        local sid64 = ply:SteamID64()

        if timer.Exists("AdminRagdoll_" .. sid64) then
            admin:PrintMessage(HUD_PRINTTALK, ply:Nick() .. " is already ragdolled. Your admin power was not used.")
            return false
        end

        if ply:InVehicle() then
            ply:ExitVehicle()
        end

        local ragdoll = ents.Create("prop_ragdoll")
        ragdoll.playerHealth = ply:Health()
        ragdoll.playerColor = ply:GetPlayerColor()

        ragdoll.WYOZIBHDontEat = true -- Don't let the red matter bomb destroy this ragdoll

        ragdoll:SetPos(ply:GetPos())
        ragdoll:SetModel(ply:GetModel())
        ragdoll:SetSkin(ply:GetSkin())
        for _, value in pairs(ply:GetBodyGroups()) do
            ragdoll:SetBodygroup(value.id, ply:GetBodygroup(value.id))
        end
        ragdoll:SetAngles(ply:GetAngles())
        ragdoll:SetColor(ply:GetColor())
        ragdoll:Activate()

        local velocity = ply:GetVelocity()
        for i = 1, ragdoll:GetPhysicsObjectCount() do
            local phys_obj = ragdoll:GetPhysicsObjectNum(i)
            if phys_obj then
                phys_obj:SetVelocity(velocity)
            end
        end

        ply:SetParent(ragdoll)
        ply:Spectate(OBS_MODE_CHASE)
        ply:SpectateEntity(ragdoll)

        ply:DrawViewModel(false)
        ply:DrawWorldModel(false)

        local function Unragdoll()
            if not IsPlayer(ply) or not ply:IsActive() then return end

            -- Save these things in case something like a Randomat has changed them
            -- We'll restore them later since the `Spawn` call resets these flags to their default
            local jumpPower = ply:GetJumpPower()
            local walkSpeed = ply:GetWalkSpeed()
            local maxHealth = ply:GetMaxHealth()

            ply:SpectateEntity(nil)
            ply:UnSpectate()
            ply:SetParent()
            ply:Spawn()
            ply:SetPos(ragdoll:GetPos())
            ply:SetVelocity(ragdoll:GetVelocity())
            local yaw = ragdoll:GetAngles().yaw
            ply:SetAngles(Angle(0, yaw, 0))
            ply:SetModel(ragdoll:GetModel())
            ply:SetPlayerColor(ragdoll.playerColor)

            ply:DrawViewModel(true)
            ply:DrawWorldModel(true)

            local newhealth = ragdoll.playerHealth
            if newhealth <= 0 then
                newhealth = 1
            end
            ply:SetHealth(newhealth)

            -- Restore potentially-changed values
            ply:SetWalkSpeed(walkSpeed)
            ply:SetJumpPower(jumpPower)
            ply:SetMaxHealth(maxHealth)

            SafeRemoveEntity(ragdoll)
        end

        hook.Add("PostEntityTakeDamage", "Admin_PostEntityTakeDamage_Ragdoll_" .. sid64, function(ent, dmginfo, taken)
            if not taken then return end
            if ent ~= ragdoll then return end

            local att = dmginfo:GetAttacker()
            if not IsPlayer(att) then return end
            if att:ShouldActLikeJester() then return end

            if not IsPlayer(ply) or not ply:Alive() or ply:IsSpec() then return end
            if att == ply then return end

            local damage = dmginfo:GetDamage()
            ragdoll.playerHealth = ragdoll.playerHealth - damage

            if ragdoll.playerHealth <= 0 then
                Unragdoll()

                local inflictor = dmginfo:GetInflictor()
                if not IsValid(inflictor) then
                    inflictor = att
                end
                local type = dmginfo:GetDamageType()
                local force = dmginfo:GetDamageForce()

                local dmg = DamageInfo()
                dmg:SetDamageType(type)
                dmg:SetAttacker(att)
                dmg:SetInflictor(inflictor)
                dmg:SetDamage(damage)
                dmg:SetDamageForce(force)

                ply:TakeDamageInfo(dmg)
            else
                ply:SetHealth(ragdoll.playerHealth)
            end
        end)

        hook.Add("TTTEndRound", "Admin_TTTEndRound_Ragdoll_" .. sid64, function()
            local timerIdentifier = "AdminRagdoll_" .. sid64
            if timer.Exists(timerIdentifier) then
                Unragdoll()
                timer.Remove(timerIdentifier)
                hook.Remove("PostEntityTakeDamage", "Admin_PostEntityTakeDamage_Ragdoll_" .. sid64)
                hook.Remove("PlayerDeath", "Admin_PlayerDeath_Ragdoll_" .. sid64)
                hook.Remove("PlayerDisconnected", "Admin_PlayerDisconnected_Ragdoll_" .. sid64)
                hook.Remove("TTTEndRound", "Admin_TTTEndRound_Ragdoll_" .. sid64)
            end
        end)

        hook.Add("PlayerDeath", "Admin_PlayerDeath_Ragdoll_", function(p, _, _)
            if p:SteamID64() ~= sid64 then return end
            local timerIdentifier = "AdminRagdoll_" .. sid64
            if timer.Exists(timerIdentifier) then
                Unragdoll()
                timer.Remove(timerIdentifier)
                hook.Remove("PostEntityTakeDamage", "Admin_PostEntityTakeDamage_Ragdoll_" .. sid64)
                hook.Remove("TTTEndRound", "Admin_TTTEndRound_Ragdoll_" .. sid64)
                hook.Remove("PlayerDisconnected", "Admin_PlayerDisconnected_Ragdoll_" .. sid64)
                hook.Remove("PlayerDeath", "Admin_PlayerDeath_Ragdoll_" .. sid64)
            end
        end)

        hook.Add("PlayerDisconnected", "Admin_PlayerDisconnected_Ragdoll_" .. sid64, function(p)
            if p:SteamID64() ~= sid64 then return end
            local timerIdentifier = "AdminRagdoll_" .. sid64
            if timer.Exists(timerIdentifier) then
                Unragdoll()
                timer.Remove(timerIdentifier)
                hook.Remove("PostEntityTakeDamage", "Admin_PostEntityTakeDamage_Ragdoll_" .. sid64)
                hook.Remove("TTTEndRound", "Admin_TTTEndRound_Ragdoll_" .. sid64)
                hook.Remove("PlayerDeath", "Admin_PlayerDeath_Ragdoll_" .. sid64)
                hook.Remove("PlayerDisconnected", "Admin_PlayerDisconnected_Ragdoll_" .. sid64)
            end
        end)

        timer.Create("AdminRagdoll_" .. sid64, time, 1, function()
            Unragdoll()
            hook.Remove("PostEntityTakeDamage", "Admin_PostEntityTakeDamage_Ragdoll_" .. sid64)
            hook.Remove("TTTEndRound", "Admin_TTTEndRound_Ragdoll_" .. sid64)
            hook.Remove("PlayerDeath", "Admin_PlayerDeath_Ragdoll_" .. sid64)
            hook.Remove("PlayerDisconnected", "Admin_PlayerDisconnected_Ragdoll_" .. sid64)
        end)

        net.Start("TTT_AdminMessage")
        net.WriteUInt(6, 4)
        net.WriteUInt(ADMIN_MESSAGE_PLAYER, 2)
        net.WriteString(admin:SteamID64())
        net.WriteUInt(ADMIN_MESSAGE_TEXT, 2)
        net.WriteString(" ragdolled ")
        net.WriteUInt(ADMIN_MESSAGE_PLAYER, 2)
        net.WriteString(ply:SteamID64())
        net.WriteUInt(ADMIN_MESSAGE_TEXT, 2)
        net.WriteString(" for ")
        net.WriteUInt(ADMIN_MESSAGE_VARIABLE, 2)
        net.WriteString(tostring(time))
        net.WriteUInt(ADMIN_MESSAGE_TEXT, 2)
        net.WriteString(" seconds")
        net.Broadcast()

        return true
    end
    net.Receive("TTT_AdminRagdollCommand", function(_, admin)
        local sid64 = net.ReadString()
        local ply = player.GetBySteamID64(sid64)
        local time = net.ReadUInt(8)

        local cost = admin_ragdoll_cost:GetInt()
        local power = admin:GetNWInt("TTTAdminPower")
        if power < cost then return end

        if Ragdoll(admin, ply, time) then
            admin:SetNWInt("TTTAdminPower", power - cost)
        end
    end)

    local function Strip(admin, ply)
        if not IsPlayer(admin) or not admin:IsActiveAdmin() then return end
        if not IsPlayer(ply) then return end
        if not ply:IsActive() then
            admin:PrintMessage(HUD_PRINTTALK, ply:Nick() .. " is dead. Your admin power was not used.")
            return false
        end

        for _, wep in ipairs(ply:GetWeapons()) do
            local class = wep:GetClass()
            if not (class == "weapon_ttt_unarmed" or class == "weapon_zm_carry" or class == "weapon_zm_improvised") then
                ply:StripWeapon(class)
            end
        end

        net.Start("TTT_AdminMessage")
        net.WriteUInt(3, 4)
        net.WriteUInt(ADMIN_MESSAGE_PLAYER, 2)
        net.WriteString(admin:SteamID64())
        net.WriteUInt(ADMIN_MESSAGE_TEXT, 2)
        net.WriteString(" stripped weapons from ")
        net.WriteUInt(ADMIN_MESSAGE_PLAYER, 2)
        net.WriteString(ply:SteamID64())
        net.Broadcast()

        return true
    end
    net.Receive("TTT_AdminStripCommand", function(_, admin)
        local sid64 = net.ReadString()
        local ply = player.GetBySteamID64(sid64)

        local cost = admin_strip_cost:GetInt()
        local power = admin:GetNWInt("TTTAdminPower")
        if power < cost then return end

        if Strip(admin, ply) then
            admin:SetNWInt("TTTAdminPower", power - cost)
        end
    end)

    local function Respawn(admin, ply)
        if not IsPlayer(admin) or not admin:IsActiveAdmin() then return end
        if not IsPlayer(ply) then return end
        if ply:Alive() then
            admin:PrintMessage(HUD_PRINTTALK, ply:Nick() .. " is already alive. Your admin power was not used.")
            return false
        end

        local body = ply.server_ragdoll or ply:GetRagdollEntity()
        ply:SpawnForRound(true)
        ply:SetDefaultCredits()
        SafeRemoveEntity(body)

        net.Start("TTT_AdminMessage")
        net.WriteUInt(3, 4)
        net.WriteUInt(ADMIN_MESSAGE_PLAYER, 2)
        net.WriteString(admin:SteamID64())
        net.WriteUInt(ADMIN_MESSAGE_TEXT, 2)
        net.WriteString(" respawned ")
        net.WriteUInt(ADMIN_MESSAGE_PLAYER, 2)
        net.WriteString(ply:SteamID64())
        net.Broadcast()

        return true
    end
    net.Receive("TTT_AdminRespawnCommand", function(_, admin)
        local sid64 = net.ReadString()
        local ply = player.GetBySteamID64(sid64)

        local cost = admin_respawn_cost:GetInt()
        local power = admin:GetNWInt("TTTAdminPower")
        if power < cost then return end

        if Respawn(admin, ply) then
            admin:SetNWInt("TTTAdminPower", power - cost)
        end
    end)

    local function Slay(admin, ply)
        if not IsPlayer(admin) or not admin:IsActiveAdmin() then return end
        if not IsPlayer(ply) then return end
        if not ply:IsActive() then
            admin:PrintMessage(HUD_PRINTTALK, ply:Nick() .. " is dead. Your admin power was not used.")
            return false
        end

        ply:Kill()

        net.Start("TTT_AdminMessage")
        net.WriteUInt(3, 4)
        net.WriteUInt(ADMIN_MESSAGE_PLAYER, 2)
        net.WriteString(admin:SteamID64())
        net.WriteUInt(ADMIN_MESSAGE_TEXT, 2)
        net.WriteString(" slayed ")
        net.WriteUInt(ADMIN_MESSAGE_PLAYER, 2)
        net.WriteString(ply:SteamID64())
        net.Broadcast()

        return true
    end
    net.Receive("TTT_AdminSlayCommand", function(_, admin)
        local sid64 = net.ReadString()
        local ply = player.GetBySteamID64(sid64)

        local cost = admin_slay_cost:GetInt()
        local power = admin:GetNWInt("TTTAdminPower")
        if power < cost then return end

        if Slay(admin, ply) then
            admin:SetNWInt("TTTAdminPower", power - cost)
        end
    end)

    local function Kick(admin, ply, reason)
        if not IsPlayer(admin) or not admin:IsActiveAdmin() then return end
        if not IsPlayer(ply) then return end

        if not ply:IsActive() then
            ply:Kill()
        end

        net.Start("TTT_AdminKickClient")
        net.WriteString(admin:Nick())
        net.WriteString(reason)
        net.Send(ply)

        net.Start("TTT_AdminMessage")
        net.WriteUInt(6, 4)
        net.WriteUInt(ADMIN_MESSAGE_PLAYER, 2)
        net.WriteString(admin:SteamID64())
        net.WriteUInt(ADMIN_MESSAGE_TEXT, 2)
        net.WriteString(" kicked ")
        net.WriteUInt(ADMIN_MESSAGE_PLAYER, 2)
        net.WriteString(ply:SteamID64())
        net.WriteUInt(ADMIN_MESSAGE_TEXT, 2)
        net.WriteString(" (")
        net.WriteUInt(ADMIN_MESSAGE_VARIABLE, 2)
        net.WriteString(reason)
        net.WriteUInt(ADMIN_MESSAGE_TEXT, 2)
        net.WriteString(")")
        net.Broadcast()

        return true
    end
    net.Receive("TTT_AdminKickCommand", function(_, admin)
        local sid64 = net.ReadString()
        local ply = player.GetBySteamID64(sid64)

        local cost = admin_kick_cost:GetInt()
        local power = admin:GetNWInt("TTTAdminPower")
        if power < cost then return end

        if Kick(admin, ply) then
            admin:SetNWInt("TTTAdminPower", power - cost)
        end
    end)
end