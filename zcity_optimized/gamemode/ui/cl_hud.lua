-- ZCity Optimized - HUD System
-- Minimal, performant HUD

hg.UI.HUD = hg.UI.HUD or {}

-- HUD Elements
hg.UI.HUD.Elements = {
	health = true,
	armor = true,
	ammo = true,
	compass = true,
	status = true,
	crosshair = true,
}

-- Colors
hg.UI.HUD.Colors = {
	bg = Color(0, 0, 0, 180),
	fg = Color(255, 255, 255, 255),
	accent = Color(200, 50, 50, 255),
	good = Color(50, 200, 50, 255),
	warn = Color(255, 200, 50, 255),
	bad = Color(255, 50, 50, 255),
}

-- Main HUD paint
hook.Add("HUDPaint", "ZC_HUD_Main", function()
	if not GetConVar("hg_cl_hud"):GetBool() then return end
	if not LocalPlayer():Alive() then return end
	
	local ply = LocalPlayer()
	local org = hg.GetOrganism(ply)
	local wep = ply:GetActiveWeapon()
	
	// Health/Armor (bottom left)
	if hg.UI.HUD.Elements.health and org then
		hg.UI.HUD.DrawHealth(ply, org)
	end
	
	// Ammo (bottom right)
	if hg.UI.HUD.Elements.ammo and IsValid(wep) then
		hg.UI.HUD.DrawAmmo(ply, wep)
	end
	
	// Compass (top center)
	if hg.UI.HUD.Elements.compass then
		hg.UI.HUD.DrawCompass(ply)
	end
	
	// Status effects (top right)
	if hg.UI.HUD.Elements.status and org then
		hg.UI.HUD.DrawStatus(ply, org)
	end
	
	// Crosshair (center)
	if hg.UI.HUD.Elements.crosshair then
		hg.UI.HUD.DrawCrosshair(ply, wep)
	end
end)

function hg.UI.HUD.DrawHealth(ply, org)
	local x, y = 20, ScrH() - 140
	local w, h = 220, 24
	local margin = 4
	
	// Background
	draw.RoundedBox(4, x, y, w, h, hg.UI.HUD.Colors.bg)
	
	// Health bar
	local hpFrac = math.Clamp(org.health / org.maxhealth, 0, 1)
	local hpCol = hg.LerpColor(hpFrac, hg.UI.HUD.Colors.bad, hg.UI.HUD.Colors.good)
	draw.RoundedBox(4, x + margin, y + margin, (w - margin * 2) * hpFrac, h - margin * 2, hpCol)
	
	// Health text
	draw.SimpleTextOutlined(
		string.format("HP: %d/%d", org.health, org.maxhealth),
		"ZC_HUD_Small", x + w/2, y + h/2,
		hg.UI.HUD.Colors.fg, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, hg.UI.HUD.Colors.bg
	)
	
	// Armor
	if org.armor > 0 then
		y = y - 30
		local aw = 220
		local ah = 16
		
		draw.RoundedBox(4, x, y, aw, ah, hg.UI.HUD.Colors.bg)
		local armFrac = math.Clamp(org.armor / org.maxarmor, 0, 1)
		draw.RoundedBox(4, x + margin, y + margin, (aw - margin * 2) * armFrac, ah - margin * 2, Color(50, 100, 255, 255))
		
		draw.SimpleTextOutlined(
			string.format("AR: %d", org.armor),
			"ZC_HUD_Small", x + aw/2, y + ah/2,
			hg.UI.HUD.Colors.fg, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, hg.UI.HUD.Colors.bg
		)
	end
	
	// Stamina bar
	y = y - 24
	local sw = 220
	local sh = 10
	
	draw.RoundedBox(4, x, y, sw, sh, hg.UI.HUD.Colors.bg)
	local stamFrac = math.Clamp(org.stamina / org.maxstamina, 0, 1)
	draw.RoundedBox(4, x + margin, y + margin, (sw - margin * 2) * stamFrac, sh - margin * 2, Color(255, 200, 50, 255))
end

function hg.UI.HUD.DrawAmmo(ply, wep)
	local clip = wep:Clip1()
	local reserve = ply:GetAmmoCount(wep:GetPrimaryAmmoType())
	
	if clip < 0 and reserve <= 0 then return end
	
	local x, y = ScrW() - 240, ScrH() - 100
	local w, h = 220, 40
	
	draw.RoundedBox(4, x, y, w, h, hg.UI.HUD.Colors.bg)
	
	local txt = clip >= 0 and string.format("%d / %d", clip, reserve) or string.format("∞ / %d", reserve)
	
	draw.SimpleTextOutlined(
		txt,
		"ZC_HUD_Large", x + w - 10, y + h/2,
		hg.UI.HUD.Colors.fg, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER, 1, hg.UI.HUD.Colors.bg
	)
	
	// Fire mode
	if wep.GetZC_FireMode then
		local modes = wep.FireModes or {"auto"}
		local mode = modes[wep:GetZC_FireMode() or 1] or "auto"
		draw.SimpleTextOutlined(
			mode:upper(),
			"ZC_HUD_Small", x + 10, y + h - 10,
			hg.UI.HUD.Colors.warn, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM, 1, hg.UI.HUD.Colors.bg
		)
	end
	
	// Heat
	if wep.ZC_Heat and wep.ZC_Heat > 0 then
		local hw = (w - 20) * (wep.ZC_Heat / 100)
		draw.RoundedBox(4, x + 10, y + h - 6, hw, 4, Color(255, 100, 0, 200))
	end
end

function hg.UI.HUD.DrawCompass(ply)
	local x, y = ScrW() / 2, 40
	local w = 300
	local h = 30
	
	local ang = ply:EyeAngles().y
	
	draw.RoundedBox(4, x - w/2, y, w, h, Color(0, 0, 0, 150))
	
	local dirs = {"N", "NE", "E", "SE", "S", "SW", "W", "NW", "N"}
	local degPerDir = 45
	
	for i = 1, 9 do
		local dirAng = (i - 1) * degPerDir - 180
		local diff = math.AngleDifference(ang, dirAng)
		local px = x + (diff / 90) * (w / 2)
		
		if px >= x - w/2 and px <= x + w/2 then
			local alpha = 255 * (1 - math.abs(diff) / 90)
			surface.SetDrawColor(255, 255, 255, alpha)
			surface.DrawLine(px, y + h * 0.3, px, y + h * 0.7)
			
			draw.SimpleTextOutlined(
				dirs[i],
				"ZC_HUD_Small", px, y + h/2,
				Color(255, 255, 255, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, alpha)
			)
		end
	end
	
	// Center marker
	surface.SetDrawColor(255, 50, 50, 255)
	surface.DrawLine(x, y + h * 0.2, x, y + h * 0.8)
end

function hg.UI.HUD.DrawStatus(ply, org)
	local x, y = ScrW() - 220, 40
	local w = 200
	local h = 24
	local margin = 4
	
	local statuses = {}
	
	if org.bleeding then table.insert(statuses, {icon = "♥", col = hg.UI.HUD.Colors.bad, text = "BLEEDING"}) end
	if org.poisoned then table.insert(statuses, {icon = "☠", col = hg.UI.HUD.Colors.warn, text = "POISONED"}) end
	if org.radiation > 10 then table.insert(statuses, {icon = "☢", col = hg.UI.HUD.Colors.warn, text = "RAD: " .. math.floor(org.radiation)}) end
	if org.hunger < 20 then table.insert(statuses, {icon = "🍖", col = hg.UI.HUD.Colors.warn, text = "HUNGRY"}) end
	if org.thirst < 20 then table.insert(statuses, {icon = "💧", col = hg.UI.HUD.Colors.bad, text = "THIRSTY"}) end
	if org.broken_bones and next(org.broken_bones) then table.insert(statuses, {icon = "🦴", col = hg.UI.HUD.Colors.bad, text = "FRACTURE"}) end
	if org.unconscious then table.insert(statuses, {icon = "💤", col = Color(150, 150, 150), text = "UNCONSCIOUS"}) end
	
	for i, status in ipairs(statuses) do
		local sy = y + (i - 1) * (h + 4)
		
		draw.RoundedBox(4, x, sy, w, h, hg.UI.HUD.Colors.bg)
		
		draw.SimpleTextOutlined(
			status.text,
			"ZC_HUD_Small", x + w/2, sy + h/2,
			status.col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, hg.UI.HUD.Colors.bg
		)
	end
end

function hg.UI.HUD.DrawCrosshair(ply, wep)
	if ply:InVehicle() then return end
	if IsValid(wep) and wep.GetZC_IronSights and wep:GetZC_IronSights() and wep:GetSightProgress() > 0.5 then return end
	
	local x, y = ScrW() / 2, ScrH() / 2
	local gap = 10
	local len = 14
	local thick = 2
	
	local alpha = 200
	if IsValid(wep) and wep.GetCurrentSpread then
		local spread = wep:GetCurrentSpread()
		alpha = math.Clamp(255 * (1 - spread * 50), 100, 255)
	end
	
	surface.SetDrawColor(255, 255, 255, alpha)
	
	// Gap in center
	surface.DrawRect(x - gap - len, y - thick/2, len, thick)
	surface.DrawRect(x + gap, y - thick/2, len, thick)
	surface.DrawRect(x - thick/2, y - gap - len, thick, len)
	surface.DrawRect(x - thick/2, y + gap, thick, len)
	
	// Center dot
	surface.DrawRect(x - 1, y - 1, 2, 2)
end

// Hitmarkers
hg.UI.HUD.Hitmarkers = {}

net.Receive("ZC_Hitmarker", function()
	local pos = net.ReadVector()
	local dmg = net.ReadInt(16)
	local isHead = net.ReadBool()
	
	table.insert(hg.UI.HUD.Hitmarkers, {
		pos = pos,
		time = CurTime() + 0.5,
		dmg = dmg,
		head = isHead,
	})
end)

hook.Add("HUDPaint", "ZC_Hitmarkers", function()
	local now = CurTime()
	
	for i = #hg.UI.HUD.Hitmarkers, 1, -1 do
		local hm = hg.UI.HUD.Hitmarkers[i]
		
		if hm.time < now then
			table.remove(hg.UI.HUD.Hitmarkers, i)
		else
			local frac = (hm.time - now) / 0.5
			local alpha = 255 * frac
			
			local screen = hm.pos:ToScreen()
			if screen.visible then
				local size = 8 * frac
				local gap = 4 * frac
				
				surface.SetDrawColor(255, 255, 255, alpha)
				if hm.head then surface.SetDrawColor(255, 200, 50, alpha) end
				
				surface.DrawLine(screen.x - gap - size, screen.y - gap - size, screen.x - gap, screen.y - gap)
				surface.DrawLine(screen.x + gap, screen.y - gap - size, screen.x + gap + size, screen.y - gap)
				surface.DrawLine(screen.x - gap - size, screen.y + gap, screen.x - gap, screen.y + gap + size)
				surface.DrawLine(screen.x + gap, screen.y + gap, screen.x + gap + size, screen.y + gap + size)
				
				if hm.dmg > 0 then
					draw.SimpleTextOutlined(
						tostring(hm.dmg),
						"ZC_HUD_Small", screen.x, screen.y - gap - size - 10,
						Color(255, 255, 255, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 1, Color(0, 0, 0, alpha)
					)
				end
			end
		end
	end
end)

print("[ZC UI] HUD system loaded")