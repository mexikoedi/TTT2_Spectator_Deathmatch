if engine.ActiveGamemode() ~= "terrortown" then return end

if SERVER then
    AddCSLuaFile()
else
    SWEP.EquipMenuData = {
        type = "item_weapon",
        name = "ttt2_spectator_deathmatch_weapon_4",
        desc = ""
    }

    SWEP.PrintName = LANG.GetTranslation("ttt2_spectator_deathmatch_weapon_4")
    SWEP.Slot = 0
    SWEP.ViewModelFlip = false
    SWEP.ViewModelFOV = 54
    SWEP.Icon = "vgui/ttt/icon_cbar"
end

SWEP.Base = "weapon_tttbase"
SWEP.HoldType = "melee"
SWEP.UseHands = true
SWEP.ViewModel = "models/weapons/c_crowbar.mdl"
SWEP.WorldModel = "models/weapons/w_crowbar.mdl"
SWEP.Weight = 5
SWEP.DrawCrosshair = false
SWEP.Primary.Damage = 20
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true
SWEP.Primary.Delay = 0.5
SWEP.Primary.Ammo = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = true
SWEP.Secondary.Ammo = "none"
SWEP.Secondary.Delay = 5
SWEP.Kind = WEAPON_MELEE
SWEP.WeaponID = AMMO_CROWBAR
SWEP.NoSights = true
SWEP.IsSilent = true
SWEP.AutoSpawnable = false
SWEP.AllowDelete = false -- never removed for weapon reduction
SWEP.AllowDrop = false
local sound_single = Sound("Weapon_Crowbar.Single")

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
    if not IsValid(self:GetOwner()) then return end

    -- for some reason not always true
    if self:GetOwner().LagCompensation then
        self:GetOwner():LagCompensation(true)
    end

    local spos = self:GetOwner():GetShootPos()
    local sdest = spos + (self:GetOwner():GetAimVector() * 70)

    local tr_main = util.TraceLine({
        start = spos,
        endpos = sdest,
        filter = self:GetOwner(),
        mask = MASK_SHOT_HULL
    })

    local hitEnt = tr_main.Entity

    if CLIENT and LocalPlayer() == self:GetOwner() then
        self:EmitSound(sound_single, self.Primary.SoundLevel)
    else
        local tbl = {}

        for _, v in ipairs(player.GetHumans()) do
            if v ~= self:GetOwner() and v:IsGhost() then
                table.insert(tbl, v)
            end
        end

        net.Start("SpecDM_BulletGhost")
        net.WriteString(sound_single)
        net.WriteVector(self:GetPos())
        net.WriteUInt(self.Primary.SoundLevel or 0, 19)
        net.Send(tbl)
    end

    if IsValid(hitEnt) and hitEnt.IsGhost and hitEnt:IsGhost() then
        self:SendWeaponAnim(ACT_VM_HITCENTER)

        if not (CLIENT and (not IsFirstTimePredicted())) then
            local edata = EffectData()
            edata:SetStart(spos)
            edata:SetOrigin(tr_main.HitPos)
            edata:SetNormal(tr_main.Normal)
            edata:SetSurfaceProp(tr_main.SurfaceProps)
            edata:SetHitBox(tr_main.HitBox)
            -- edata:SetDamageType(DMG_CLUB)
            edata:SetEntity(hitEnt)

            if hitEnt:IsPlayer() then
                -- does not work on players rah
                -- util.Decal("Blood", tr_main.HitPos + tr_main.HitNormal, tr_main.HitPos - tr_main.HitNormal)
                -- do a bullet just to make blood decals work sanely
                -- need to disable lagcomp because firebullets does its own
                self:GetOwner():LagCompensation(false)

                self:GetOwner():FireBullets({
                    Num = 1,
                    Src = spos,
                    Dir = self:GetOwner():GetAimVector(),
                    Spread = Vector(0, 0, 0),
                    Tracer = 0,
                    Force = 1,
                    Damage = 0
                })
            else
                util.Effect("Impact", edata)
            end
        end
    else
        self:SendWeaponAnim(ACT_VM_MISSCENTER)
    end

    if SERVER then
        -- Do another trace that sees nodraw stuff like func_button
        -- local tr_all = nil
        -- tr_all = util.TraceLine({start = spos, endpos = sdest, filter = self:GetOwner()})
        self:GetOwner():SetAnimation(PLAYER_ATTACK1)

        if hitEnt and hitEnt:IsValid() and hitEnt:IsPlayer() and hitEnt:IsGhost() then
            local dmg = DamageInfo()
            dmg:SetDamage(self.Primary.Damage)
            dmg:SetAttacker(self:GetOwner())
            dmg:SetInflictor(self)
            dmg:SetDamageForce(self:GetOwner():GetAimVector() * 1500)
            dmg:SetDamagePosition(self:GetOwner():GetPos())
            dmg:SetDamageType(DMG_CLUB)
            hitEnt:TakeDamageInfo(dmg)
        end
    end

    if self:GetOwner().LagCompensation then
        self:GetOwner():LagCompensation(false)
    end
end

function SWEP:SecondaryAttack()
end

function SWEP:OnDrop()
    self:Remove()
end

function SWEP:DrawWorldModel()
    if LocalPlayer():IsGhost() then
        self:DrawModel()
    else
        return
    end
end
