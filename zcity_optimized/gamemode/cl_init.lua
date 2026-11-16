-- ZCity Optimized - Client Init
-- Lightweight client-side initialization

include("shared.lua")

-- Client-side only convars
CreateClientConVar("hg_cl_crosshair", "1", true, false, "Enable custom crosshair")
CreateClientConVar("hg_cl_hud", "1", true, false, "Enable HUD")
CreateClientConVar("hg_cl_thirdperson", "0", true, false, "Third person view")
CreateClientConVar("hg_cl_fov", "90", true, false, "Field of view")
CreateClientConVar("hg_cl_bob", "1", true, false, "View bobbing")
CreateClientConVar("hg_cl_shake", "1", true, false, "Screen shake")

-- Fonts
surface.CreateFont("ZC_HUD_Small", {
	font = "Roboto",
	size = ScreenScale(6),
	weight = 400,
	antialias = true,
})

surface.CreateFont("ZC_HUD_Medium", {
	font = "Roboto",
	size = ScreenScale(10),
	weight = 500,
	antialias = true,
})

surface.CreateFont("ZC_HUD_Large", {
	font = "Roboto",
	size = ScreenScale(18),
	weight = 600,
	antialias = true,
})

surface.CreateFont("ZC_HUD_Mono", {
	font = "Consolas",
	size = ScreenScale(7),
	weight = 400,
	antialias = true,
})

-- Materials (lazy loaded)
hg.Materials = {}

function hg.GetMaterial(name, path)
	if hg.Materials[name] then return hg.Materials[name] end
	hg.Materials[name] = Material(path, "smooth noclamp")
	return hg.Materials[name]
end

-- Preload essential materials
hg.GetMaterial("blur", "pp/blurscreen")
hg.GetMaterial("gradient", "gui/gradient")
hg.GetMaterial("vignette", "vgui/vignette")

-- Blur function (optimized)
local blurMat = Material("pp/blurscreen")
local blurCache = {}

function hg.DrawBlur(panel, amount, passes, alpha)
	if not IsValid(panel) then return end
	
	amount = amount or 5
	passes = passes or 1
	alpha = alpha or 255
	
	if hg.ConVarBool("potatopc") then
		surface.SetDrawColor(0, 0, 0, math.min(alpha, amount * 20))
		surface.DrawRect(0, 0, panel:GetWide(), panel:GetTall())
		return
	end
	
	local x, y = panel:LocalToScreen(0, 0)
	local w, h = panel:GetSize()
	
	surface.SetMaterial(blurMat)
	surface.SetDrawColor(255, 255, 255, alpha)
	
	local key = amount .. ":" .. passes
	if blurCache[key] then
		render.UpdateScreenEffectTexture()
		surface.DrawTexturedRect(-x, -y, ScrW(), ScrH())
		return
	end
	
	blurCache[key] = true
	
	for i = 1, passes do
		blurMat:SetFloat("$blur", i * amount / passes)
		blurMat:Recompute()
		render.UpdateScreenEffectTexture()
		surface.DrawTexturedRect(-x, -y, ScrW(), ScrH())
	end
end

-- HUD Paint hook (minimal)
hook.Add("HUDPaint", "ZC_HUD", function()
	if not GetConVar("hg_cl_hud"):GetBool() then return end
	if not LocalPlayer():Alive() then return end
	
	local ply = LocalPlayer()
	local organism = ply.organism
	
	-- Health/Armor
	if organism then
		local hp = math.max(0, organism.health or 100)
		local maxhp = organism.maxhealth or 100
		local armor = organism.armor or 0
		
		local x, y = 20, ScrH() - 120
		local w, h = 200, 20
		
		-- Health bar bg
		surface.SetDrawColor(0, 0, 0, 180)
		surface.DrawRect(x, y, w, h)
		
		-- Health bar
		local hpCol = hg.LerpColor(hp / maxhp, hg.Colors.Red, hg.Colors.Green)
		surface.SetDrawColor(hpCol.r, hpCol.g, hpCol.b, 200)
		surface.DrawRect(x + 2, y + 2, (w - 4) * (hp / maxhp), h - 4)
		
		-- Text
		draw.SimpleTextOutlined(
			string.format("HP: %d/%d", hp, maxhp),
			"ZC_HUD_Small", x + w/2, y + h/2,
			hg.Colors.White, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, hg.Colors.Black
		)
		
		-- Armor
		if armor > 0 then
			y = y - 25
			surface.SetDrawColor(0, 0, 0, 180)
			surface.DrawRect(x, y, w, 15)
			
			surface.SetDrawColor(50, 100, 255, 200)
			surface.DrawRect(x + 2, y + 2, (w - 4) * math.Clamp(armor / 100, 0, 1), 11)
			
			draw.SimpleTextOutlined(
				string.format("AR: %d", armor),
				"ZC_HUD_Small", x + w/2, y + 7,
				hg.Colors.White, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, hg.Colors.Black
			)
		end
	end
	
	-- Ammo
	local wep = ply:GetActiveWeapon()
	if IsValid(wep) and wep:Clip1() >= 0 then
		local ammo = wep:Clip1()
		local reserve = ply:GetAmmoCount(wep:GetPrimaryAmmoType())
		
		local x, y = ScrW() - 220, ScrH() - 80
		draw.SimpleTextOutlined(
			string.format("%d / %d", ammo, reserve),
			"ZC_HUD_Medium", x, y,
			hg.Colors.White, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER, 1, hg.Colors.Black
		)
	end
	
	-- Crosshair
	if GetConVar("hg_cl_crosshair"):GetBool() and not ply:InVehicle() then
		local x, y = ScrW() / 2, ScrH() / 2
		local gap = 8
		local len = 12
		local thick = 2
		
		surface.SetDrawColor(255, 255, 255, 200)
		surface.DrawRect(x - gap - len, y - thick/2, len, thick)
		surface.DrawRect(x + gap, y - thick/2, len, thick)
		surface.DrawRect(x - thick/2, y - gap - len, thick, len)
		surface.DrawRect(x - thick/2, y + gap, thick, len)
	end
end)

-- Third person view
hook.Add("CalcView", "ZC_ThirdPerson", function(ply, pos, ang, fov)
	if not GetConVar("hg_cl_thirdperson"):GetBool() then return end
	if not ply:Alive() then return end
	
	local view = {}
	view.origin = pos - ang:Forward() * 80 + ang:Up() * 10
	view.angles = ang
	view.fov = GetConVar("hg_cl_fov"):GetFloat()
	view.drawviewer = true
	
	return view
end)

-- View bobbing
hook.Add("CalcView", "ZC_ViewBob", function(ply, pos, ang, fov)
	if not GetConVar("hg_cl_bob"):GetBool() then return end
	if not ply:Alive() then return end
	if ply:GetMoveType() == MOVETYPE_NOCLIP then return end
	
	local vel = ply:GetVelocity():Length2D()
	if vel < 10 then return end
	
	local bob = math.sin(CurTime() * 10) * (vel / 300) * 0.5
	local roll = math.cos(CurTime() * 5) * (vel / 300) * 0.3
	
	ang = Angle(ang.p + bob, ang.y, ang.r + roll)
	
	return {angles = ang}
end)

-- Screen shake
hg.ScreenShake = {intensity = 0, time = 0}

net.Receive("hg_Effect", function()
	local type = net.ReadString()
	if type == "shake" then
		hg.ScreenShake.intensity = net.ReadFloat()
		hg.ScreenShake.time = CurTime() + net.ReadFloat()
	end
end)

hook.Add("CalcView", "ZC_ScreenShake", function(ply, pos, ang, fov)
	if hg.ScreenShake.time > CurTime() then
		local frac = (hg.ScreenShake.time - CurTime()) / 1
		local intensity = hg.ScreenShake.intensity * frac
		
		ang = Angle(
			ang.p + math.Rand(-intensity, intensity),
			ang.y + math.Rand(-intensity, intensity),
			ang.r + math.Rand(-intensity, intensity)
		)
		
		return {angles = ang}
	end
end)

-- Input blocking for menus
hook.Add("ScoreboardShow", "ZC_Scoreboard", function()
	return true -- Use sandbox scoreboard
end)

hook.Add("SpawnMenuOpen", "ZC_SpawnMenu", function()
	return true -- Use sandbox spawn menu
end)

hook.Add("ContextMenuOpen", "ZC_ContextMenu", function()
	return true -- Use sandbox context menu
end)

print("[ZCity Optimized] Client core loaded v" .. zb.Version)