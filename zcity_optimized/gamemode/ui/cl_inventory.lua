-- ZCity Optimized - Inventory UI
-- Lightweight inventory/equipment interface

hg.UI = hg.UI or {}
hg.UI.Inventory = hg.UI.Inventory or {}

local PANEL = {}

function PANEL:Init()
	self:SetSize(ScrW() * 0.6, ScrH() * 0.7)
	self:Center()
	self:MakePopup()
	self:SetTitle("Inventory")
	self:SetDeleteOnClose(true)
	
	self.Slots = {}
	self.QuickSlots = {}
	self.Equipment = {}
	self.SelectedSlot = nil
	self.DraggedItem = nil
	self.DragOffset = {x = 0, y = 0}
	
	// Layout
	local margin = 10
	local slotSize = 64
	local cols = 6
	
	// Main inventory grid
	self.Grid = vgui.Create("DPanel", self)
	self.Grid:SetPos(margin, 40)
	self.Grid:SetSize((slotSize + 4) * cols + 4, (slotSize + 4) * 5 + 4)
	self.Grid.Paint = function(s, w, h)
		draw.RoundedBox(4, 0, 0, w, h, Color(30, 30, 30, 200))
	end
	
	// Quickslots bar
	self.QuickBar = vgui.Create("DPanel", self)
	self.QuickBar:SetPos(margin, self.Grid:GetTall() + 50)
	self.QuickBar:SetSize((slotSize + 4) * 6 + 4, slotSize + 8)
	self.QuickBar.Paint = function(s, w, h)
		draw.RoundedBox(4, 0, 0, w, h, Color(40, 40, 40, 220))
	end
	
	// Equipment panel
	self.EqPanel = vgui.Create("DPanel", self)
	self.EqPanel:SetPos(self.Grid:GetWide() + margin * 2, 40)
	self.EqPanel:SetSize(200, self:GetTall() - 80)
	self.EqPanel.Paint = function(s, w, h)
		draw.RoundedBox(4, 0, 0, w, h, Color(30, 30, 30, 200))
	end
	
	// Info panel
	self.InfoPanel = vgui.Create("DPanel", self)
	self.InfoPanel:SetPos(margin, self.QuickBar:GetY() + self.QuickBar:GetTall() + 10)
	self.InfoPanel:SetSize(self:GetWide() - margin * 2, 80)
	self.InfoPanel.Paint = function(s, w, h)
		draw.RoundedBox(4, 0, 0, w, h, Color(20, 20, 20, 220))
		
		if self.DraggedItem then
			local item = hg.Inventory.GetItem(self.DraggedItem.class)
			if item then
				draw.SimpleText(item.name, "ZC_HUD_Medium", 10, 10, color_white)
				draw.SimpleText(item.desc, "ZC_HUD_Small", 10, 35, Color(200, 200, 200))
				draw.SimpleText("Weight: " .. item.weight .. " kg", "ZC_HUD_Small", 10, 55, Color(150, 150, 150))
			end
		elseif self.SelectedSlot and self.SelectedItem then
			local item = hg.Inventory.GetItem(self.SelectedItem.class)
			if item then
				draw.SimpleText(item.name, "ZC_HUD_Medium", 10, 10, color_white)
				draw.SimpleText(item.desc, "ZC_HUD_Small", 10, 35, Color(200, 200, 200))
				draw.SimpleText("Weight: " .. item.weight .. " kg x " .. self.SelectedItem.count, "ZC_HUD_Small", 10, 55, Color(150, 150, 150))
			end
		end
	end
	
	// Create slots
	self:CreateSlots()
	self:CreateQuickSlots()
	self:CreateEquipmentSlots()
	
	// Weight bar
	self.WeightBar = vgui.Create("DPanel", self)
	self.WeightBar:SetPos(margin, self:GetTall() - 30)
	self.WeightBar:SetSize(self:GetWide() - margin * 2, 20)
	self.WeightBar.Paint = function(s, w, h)
		local inv = hg.GetInventory(LocalPlayer())
		if not inv then return end
		
		draw.RoundedBox(4, 0, 0, w, h, Color(50, 50, 50, 200))
		
		local frac = math.Clamp(inv.weight / inv.maxweight, 0, 1)
		local col = hg.LerpColor(frac, hg.Colors.Green, hg.Colors.Red)
		surface.SetDrawColor(col.r, col.g, col.b, 200)
		surface.DrawRect(2, 2, (w - 4) * frac, h - 4)
		
		draw.SimpleTextOutlined(
			string.format("Weight: %.1f / %.1f kg", inv.weight, inv.maxweight),
			"ZC_HUD_Small", w/2, h/2,
			color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black
		)
	end
	
	// Close button
	self.CloseBtn = vgui.Create("DButton", self)
	self.CloseBtn:SetPos(self:GetWide() - 40, 8)
	self.CloseBtn:SetSize(32, 32)
	self.CloseBtn:SetText("×")
	self.CloseBtn:SetFont("ZC_HUD_Large")
	self.CloseBtn.DoClick = function() self:Close() end
	self.CloseBtn.Paint = function(s, w, h)
		if s:IsHovered() then
			draw.RoundedBox(4, 0, 0, w, h, Color(200, 50, 50, 200))
		else
			draw.RoundedBox(4, 0, 0, w, h, Color(100, 30, 30, 200))
		end
	end
end

function PANEL:CreateSlots()
	local slotSize = 64
	local cols = 6
	local margin = 4
	
	for i = 1, 30 do
		local col = (i - 1) % cols
		local row = math.floor((i - 1) / cols)
		
		local slot = vgui.Create("DButton", self.Grid)
		slot:SetPos(margin + col * (slotSize + margin), margin + row * (slotSize + margin))
		slot:SetSize(slotSize, slotSize)
		slot:SetText("")
		slot.SlotIndex = i
		
		slot.Paint = function(s, w, h)
			local inv = hg.GetInventory(LocalPlayer())
			local item = inv and inv.slots[i]
			
			// Background
			if s:IsHovered() then
				draw.RoundedBox(4, 0, 0, w, h, Color(60, 60, 80, 200))
			elseif self.SelectedSlot == i then
				draw.RoundedBox(4, 0, 0, w, h, Color(80, 60, 40, 200))
			else
				draw.RoundedBox(4, 0, 0, w, h, Color(40, 40, 50, 200))
			end
			
			// Border
			surface.SetDrawColor(100, 100, 120, 100)
			surface.DrawOutlinedRect(0, 0, w, h, 1)
			
			// Item
			if item then
				local itemData = hg.Inventory.GetItem(item.class)
				if itemData then
					// Icon
					if itemData.model then
						// Draw model icon (simplified)
						surface.SetDrawColor(150, 150, 150, 200)
						surface.DrawRect(8, 8, w - 16, h - 16)
					end
					
					// Count
					if item.count > 1 then
						draw.SimpleTextOutlined(
							"x" .. item.count,
							"ZC_HUD_Small", w - 4, h - 4,
							color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM, 1, color_black
						)
					end
					
					// Weight
					draw.SimpleTextOutlined(
						string.format("%.1fkg", itemData.weight * item.count),
						"ZC_HUD_Mono", 4, h - 18,
						color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM, 1, color_black
					)
				end
			end
			
			// Drag overlay
			if self.DraggedItem and self.DraggedItem.slot == i then
				draw.RoundedBox(4, 0, 0, w, h, Color(100, 200, 100, 100))
			end
		end
		
		slot.DoClick = function(s)
			self:OnSlotClick(i)
		end
		
		slot.DoRightClick = function(s)
			self:OnSlotRightClick(i)
		end
		
		slot.OnMousePressed = function(s, key)
			if key == MOUSE_LEFT then
				self:StartDrag(i)
			end
		end
		
		slot.OnMouseReleased = function(s, key)
			if key == MOUSE_LEFT then
				self:EndDrag(i)
			end
		end
		
		self.Slots[i] = slot
	end
end

function PANEL:CreateQuickSlots()
	local slotSize = 64
	local margin = 4
	
	for i = 1, 6 do
		local slot = vgui.Create("DButton", self.QuickBar)
		slot:SetPos(margin + (i - 1) * (slotSize + margin), margin)
		slot:SetSize(slotSize, slotSize)
		slot:SetText("")
		slot.QuickSlot = i
		
		slot.Paint = function(s, w, h)
			local inv = hg.GetInventory(LocalPlayer())
			local qsSlot = inv and inv.quickslots[i]
			local item = qsSlot and inv.slots[qsSlot]
			
			if s:IsHovered() then
				draw.RoundedBox(4, 0, 0, w, h, Color(60, 80, 60, 200))
			else
				draw.RoundedBox(4, 0, 0, w, h, Color(40, 60, 40, 200))
			end
			
			surface.SetDrawColor(100, 150, 100, 100)
			surface.DrawOutlinedRect(0, 0, w, h, 2)
			
			// Number
			draw.SimpleTextOutlined(
				tostring(i),
				"ZC_HUD_Small", 4, 4,
				color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 1, color_black
			)
			
			if item then
				local itemData = hg.Inventory.GetItem(item.class)
				if itemData and itemData.model then
					surface.SetDrawColor(150, 150, 150, 200)
					surface.DrawRect(8, 8, w - 16, h - 16)
				end
				
				if item.count > 1 then
					draw.SimpleTextOutlined(
						"x" .. item.count,
						"ZC_HUD_Small", w - 4, h - 4,
						color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM, 1, color_black
					)
				end
			end
		end
		
		slot.DoClick = function(s)
			self:OnQuickSlotClick(i)
		end
		
		slot.DoRightClick = function(s)
			local inv = hg.GetInventory(LocalPlayer())
			if inv and inv.quickslots[i] then
				hg.Inventory.SetQuickslot(LocalPlayer(), i, 0)
			end
		end
		
		self.QuickSlots[i] = slot
	end
end

function PANEL:CreateEquipmentSlots()
	local slotSize = 56
	local margin = 4
	local y = 10
	
	local eq = hg.Equipment.Get(LocalPlayer())
	if not eq then return end
	
	for slotName, _ in pairs(hg.Equipment.Slots) do
		if hg.Equipment.Categories[slotName] ~= "weapon" then
			local btn = vgui.Create("DButton", self.EqPanel)
			btn:SetPos(margin, y)
			btn:SetSize(self.EqPanel:GetWide() - margin * 2, slotSize)
			btn:SetText("")
			btn.EqSlot = slotName
			
			btn.Paint = function(s, w, h)
				local item = eq.slots[slotName]
				
				if s:IsHovered() then
					draw.RoundedBox(4, 0, 0, w, h, Color(60, 60, 80, 200))
				elseif item then
					draw.RoundedBox(4, 0, 0, w, h, Color(50, 70, 50, 200))
				else
					draw.RoundedBox(4, 0, 0, w, h, Color(40, 40, 50, 200))
				end
				
				surface.SetDrawColor(100, 100, 120, 100)
				surface.DrawOutlinedRect(0, 0, w, h, 1)
				
				// Slot name
				draw.SimpleText(
					slotName:upper(),
					"ZC_HUD_Small", 8, h/2,
					color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER
				)
				
				if item then
					local itemData = hg.Equipment.GetItem(item.class)
					if itemData then
						draw.SimpleText(
							itemData.name,
							"ZC_HUD_Small", w - 8, h/2,
							color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER
						)
					end
				end
			end
			
			btn.DoClick = function(s)
				if item then
					hg.Equipment.Unequip(LocalPlayer(), slotName)
				else
					// Open item picker for this slot
					self:OpenItemPicker(slotName)
				end
			end
			
			y = y + slotSize + margin
		end
	end
end

function PANEL:OnSlotClick(slot)
	self.SelectedSlot = slot
	local inv = hg.GetInventory(LocalPlayer())
	self.SelectedItem = inv and inv.slots[slot]
end

function PANEL:OnSlotRightClick(slot)
	local inv = hg.GetInventory(LocalPlayer())
	if not inv or not inv.slots[slot] then return end
	
	local menu = DermaMenu()
	
	menu:AddOption("Use", function()
		hg.Inventory.UseItem(LocalPlayer(), slot)
	end)
	
	menu:AddOption("Drop", function()
		hg.Inventory.DropItem(LocalPlayer(), slot)
	end)
	
	menu:AddOption("Drop All", function()
		hg.Inventory.DropItem(LocalPlayer(), slot, inv.slots[slot].count)
	end)
	
	menu:AddSpacer()
	
	// Quickslot assignment
	for i = 1, 6 do
		menu:AddOption("Set to Quickslot " .. i, function()
			hg.Inventory.SetQuickslot(LocalPlayer(), i, slot)
		end)
	end
	
	menu:AddOption("Clear Quickslot", function()
		for i = 1, 6 do
			if inv.quickslots[i] == slot then
				hg.Inventory.SetQuickslot(LocalPlayer(), i, 0)
			end
		end
	end)
	
	menu:Open()
end

function PANEL:OnQuickSlotClick(qs)
	hg.Inventory.UseQuickslot(LocalPlayer(), qs)
end

function PANEL:StartDrag(slot)
	local inv = hg.GetInventory(LocalPlayer())
	if not inv or not inv.slots[slot] then return end
	
	self.DraggedItem = {
		slot = slot,
		class = inv.slots[slot].class,
		count = inv.slots[slot].count,
	}
	
	local x, y = input.GetCursorPos()
	local sx, sy = self.Slots[slot]:LocalToScreen(0, 0)
	self.DragOffset.x = x - sx
	self.DragOffset.y = y - sy
	
	self.Slots[slot]:SetVisible(false)
end

function PANEL:EndDrag(targetSlot)
	if not self.DraggedItem then return end
	
	local fromSlot = self.DraggedItem.slot
	
	if targetSlot and targetSlot ~= fromSlot then
		hg.Inventory.MoveItem(LocalPlayer(), fromSlot, targetSlot)
	end
	
	if self.Slots[fromSlot] then
		self.Slots[fromSlot]:SetVisible(true)
	end
	
	self.DraggedItem = nil
end

function PANEL:OpenItemPicker(eqSlot)
	local menu = DermaMenu()
	
	for class, item in pairs(hg.Equipment.Items) do
		if item.slot == eqSlot then
			menu:AddOption(item.name, function()
				hg.Equipment.Equip(LocalPlayer(), class, eqSlot)
			end)
		end
	end
	
	menu:Open()
end

function PANEL:Think()
	// Update dragged item position
	if self.DraggedItem then
		local x, y = input.GetCursorPos()
		// Visual feedback handled in paint
	end
	
	// Close on inventory key
	if input.IsKeyDown(KEY_TAB) then
		self:Close()
	end
end

vgui.Register("ZC_InventoryMenu", PANEL, "ZFrame")

// Console command
concommand.Add("zc_inventory", function()
	if IsValid(hg.UI.Inventory.Menu) then
		hg.UI.Inventory.Menu:Close()
	else
		hg.UI.Inventory.Menu = vgui.Create("ZC_InventoryMenu")
	end
end)

// Key bind
hook.Add("PlayerBindPress", "ZC_InventoryBind", function(ply, bind, pressed)
	if bind == "+menu" and pressed then
		if IsValid(hg.UI.Inventory.Menu) then
			hg.UI.Inventory.Menu:Close()
		else
			hg.UI.Inventory.Menu = vgui.Create("ZC_InventoryMenu")
		end
		return true
	end
end)

print("[ZC UI] Inventory UI loaded")