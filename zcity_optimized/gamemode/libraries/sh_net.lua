-- ZCity Optimized - Networking Library
-- Optimized network message handling with compression and batching

hg.Net = hg.Net or {}
hg.Net.Messages = {}
hg.Net.Handlers = {}
hg.Net.BatchQueue = {}
hg.Net.BatchTimer = "ZC_NetBatch"

-- Message types for compression
hg.Net.Types = {
	BOOL = 1,
	INT8 = 2,
	INT16 = 3,
	INT32 = 4,
	UINT8 = 5,
	UINT16 = 6,
	UINT32 = 7,
	FLOAT = 8,
	DOUBLE = 9,
	STRING = 10,
	ENTITY = 11,
	VECTOR = 12,
	ANGLE = 13,
	COLOR = 14,
	TABLE = 15,
}

-- Register a network message
function hg.Net.Register(name, handler)
	hg.Net.Handlers[name] = handler
	if SERVER then
		util.AddNetworkString("ZC_Net_" .. name)
	end
	hg.DebugPrint("Registered net message: " .. name)
end

-- Send a message (server -> client or broadcast)
function hg.Net.Send(name, data, recipients)
	if not hg.Net.Handlers[name] then
		hg.DebugPrint("Warning: Sending unregistered net message: " .. name)
	end
	
	net.Start("ZC_Net_" .. name)
	hg.Net.WriteTable(data or {})
	
	if recipients then
		if istable(recipients) then
			net.Send(recipients)
		else
			net.Send(recipients)
		end
	else
		net.Broadcast()
	end
end

-- Send to specific player
function hg.Net.SendPly(ply, name, data)
	hg.Net.Send(name, data, ply)
end

-- Send to multiple players
function hg.Net.SendPlys(plys, name, data)
	hg.Net.Send(name, data, plys)
end

-- Send from client to server
function hg.Net.SendToServer(name, data)
	net.Start("ZC_Net_" .. name)
	hg.Net.WriteTable(data or {})
	net.SendToServer()
end

-- Batch multiple messages for efficiency
function hg.Net.BatchSend(name, data, recipients)
	table.insert(hg.Net.BatchQueue, {
		name = name,
		data = data,
		recipients = recipients,
		time = CurTime()
	})
	
	if not timer.Exists(hg.Net.BatchTimer) then
		timer.Create(hg.Net.BatchTimer, 0.01, 1, hg.Net.FlushBatch)
	end
end

function hg.Net.FlushBatch()
	if #hg.Net.BatchQueue == 0 then return end
	
	-- Group by message name
	local grouped = {}
	for _, msg in ipairs(hg.Net.BatchQueue) do
		grouped[msg.name] = grouped[msg.name] or {}
		table.insert(grouped[msg.name], msg)
	end
	
	-- Send batched messages
	for name, messages in pairs(grouped) do
		if #messages == 1 then
			hg.Net.Send(name, messages[1].data, messages[1].recipients)
		else
			-- Send as array
			local batchData = {}
			for _, msg in ipairs(messages) do
				table.insert(batchData, msg.data)
			end
			hg.Net.Send(name .. "_Batch", batchData, messages[1].recipients)
		end
	end
	
	hg.Net.BatchQueue = {}
end

-- Optimized table writing
function hg.Net.WriteTable(tbl)
	if not tbl then return end
	
	net.WriteUInt(table.Count(tbl), 16)
	
	for k, v in pairs(tbl) do
		net.WriteString(k)
		hg.Net.WriteValue(v)
	end
end

function hg.Net.ReadTable()
	local count = net.ReadUInt(16)
	local tbl = {}
	for i = 1, count do
		local key = net.ReadString()
		tbl[key] = hg.Net.ReadValue()
	end
	return tbl
end

function hg.Net.WriteValue(val)
	local t = type(val)
	
	if t == "nil" then
		net.WriteUInt(0, 4)
	elseif t == "boolean" then
		net.WriteUInt(hg.Net.Types.BOOL, 4)
		net.WriteBool(val)
	elseif t == "number" then
		if val == math.floor(val) then
			if val >= -128 and val <= 127 then
				net.WriteUInt(hg.Net.Types.INT8, 4)
				net.WriteInt(val, 8)
			elseif val >= -32768 and val <= 32767 then
				net.WriteUInt(hg.Net.Types.INT16, 4)
				net.WriteInt(val, 16)
			else
				net.WriteUInt(hg.Net.Types.INT32, 4)
				net.WriteInt(val, 32)
			end
		else
			net.WriteUInt(hg.Net.Types.FLOAT, 4)
			net.WriteFloat(val)
		end
	elseif t == "string" then
		net.WriteUInt(hg.Net.Types.STRING, 4)
		net.WriteString(val)
	elseif t == "Entity" or t == "Player" or t == "Vehicle" or t == "Weapon" or t == "NPC" then
		net.WriteUInt(hg.Net.Types.ENTITY, 4)
		net.WriteEntity(val)
	elseif t == "Vector" then
		net.WriteUInt(hg.Net.Types.VECTOR, 4)
		net.WriteVector(val)
	elseif t == "Angle" then
		net.WriteUInt(hg.Net.Types.ANGLE, 4)
		net.WriteAngle(val)
	elseif t == "table" and val.r and val.g and val.b and val.a then
		-- Assume Color
		net.WriteUInt(hg.Net.Types.COLOR, 4)
		net.WriteColor(val)
	elseif t == "table" then
		net.WriteUInt(hg.Net.Types.TABLE, 4)
		hg.Net.WriteTable(val)
	else
		-- Fallback to generic
		net.WriteUInt(hg.Net.Types.TABLE, 4)
		hg.Net.WriteTable({_type = t, _value = tostring(val)})
	end
end

function hg.Net.ReadValue()
	local typeID = net.ReadUInt(4)
	
	if typeID == 0 then return nil end
	if typeID == hg.Net.Types.BOOL then return net.ReadBool() end
	if typeID == hg.Net.Types.INT8 then return net.ReadInt(8) end
	if typeID == hg.Net.Types.INT16 then return net.ReadInt(16) end
	if typeID == hg.Net.Types.INT32 then return net.ReadInt(32) end
	if typeID == hg.Net.Types.UINT8 then return net.ReadUInt(8) end
	if typeID == hg.Net.Types.UINT16 then return net.ReadUInt(16) end
	if typeID == hg.Net.Types.UINT32 then return net.ReadUInt(32) end
	if typeID == hg.Net.Types.FLOAT then return net.ReadFloat() end
	if typeID == hg.Net.Types.DOUBLE then return net.ReadDouble() end
	if typeID == hg.Net.Types.STRING then return net.ReadString() end
	if typeID == hg.Net.Types.ENTITY then return net.ReadEntity() end
	if typeID == hg.Net.Types.VECTOR then return net.ReadVector() end
	if typeID == hg.Net.Types.ANGLE then return net.ReadAngle() end
	if typeID == hg.Net.Types.COLOR then return net.ReadColor() end
	if typeID == hg.Net.Types.TABLE then return hg.Net.ReadTable() end
	
	return nil
end

-- Receiver
if SERVER then
	net.Receive("ZC_Net_", function(len, ply)
		local msgName = net.ReadString()
		local data = hg.Net.ReadTable()
		
		local handler = hg.Net.Handlers[msgName]
		if handler then
			local ok, err = pcall(handler, ply, data)
			if not ok then
				ErrorNoHalt("[ZC Net] Error in handler " .. msgName .. ": " .. err .. "\n")
			end
		else
			hg.DebugPrint("Received unhandled net message: " .. msgName)
		end
	end)
else
	net.Receive("ZC_Net_", function(len)
		local msgName = net.ReadString()
		local data = hg.Net.ReadTable()
		
		local handler = hg.Net.Handlers[msgName]
		if handler then
			local ok, err = pcall(handler, data)
			if not ok then
				ErrorNoHalt("[ZC Net] Error in handler " .. msgName .. ": " .. err .. "\n")
			end
		else
			hg.DebugPrint("Received unhandled net message: " .. msgName)
		end
	end)
end

-- Helper: Register client->server message
function hg.Net.RegisterServer(name, handler)
	hg.Net.Register(name, handler)
end

-- Helper: Register server->client message
function hg.Net.RegisterClient(name, handler)
	hg.Net.Register(name, handler)
end

-- Entity networking (optimized)
hg.Net.EntityVars = {}

function hg.Net.SetEntityVar(ent, key, value, broadcast)
	if not IsValid(ent) then return end
	
	hg.Net.EntityVars[ent] = hg.Net.EntityVars[ent] or {}
	hg.Net.EntityVars[ent][key] = value
	
	if SERVER then
		net.Start("ZC_EntVar")
		net.WriteEntity(ent)
		net.WriteString(key)
		hg.Net.WriteValue(value)
		if broadcast then net.Broadcast() else net.SendPVS(ent:GetPos()) end
	end
end

function hg.Net.GetEntityVar(ent, key)
	if not IsValid(ent) then return nil end
	return hg.Net.EntityVars[ent] and hg.Net.EntityVars[ent][key]
end

if CLIENT then
	net.Receive("ZC_EntVar", function()
		local ent = net.ReadEntity()
		local key = net.ReadString()
		local value = hg.Net.ReadValue()
		
		hg.Net.EntityVars[ent] = hg.Net.EntityVars[ent] or {}
		hg.Net.EntityVars[ent][key] = value
		
		hook.Run("ZC_EntityVarChanged", ent, key, value)
	end)
end

-- Player var helpers
function hg.Net.SetPlayerVar(ply, key, value)
	hg.Net.SetEntityVar(ply, key, value, true)
end

function hg.Net.GetPlayerVar(ply, key)
	return hg.Net.GetEntityVar(ply, key)
end

-- Sync organism data (compressed)
function hg.Net.SyncOrganism(ply, organism)
	if not organism then return end
	
	local data = {
		health = math.floor(organism.health or 100),
		maxhealth = math.floor(organism.maxhealth or 100),
		armor = math.floor(organism.armor or 0),
		bleeding = organism.bleeding and 1 or 0,
		broken_bones = organism.broken_bones or {},
		stamina = math.floor((organism.stamina or 100) * 10) / 10,
		hunger = math.floor((organism.hunger or 100) * 10) / 10,
		thirst = math.floor((organism.thirst or 100) * 10) / 10,
		radiation = math.floor((organism.radiation or 0) * 10) / 10,
		poisoned = organism.poisoned and 1 or 0,
		unconscious = organism.unconscious and 1 or 0,
	}
	
	hg.Net.SendPly(ply, "OrganismSync", data)
end

-- Sync inventory (delta compressed)
function hg.Net.SyncInventory(ply, inventory, full)
	if not inventory then return end
	
	local data = {
		full = full and 1 or 0,
		weight = math.floor((inventory.weight or 0) * 10) / 10,
		maxweight = math.floor(inventory.maxweight or 50),
		slots = {}
	}
	
	for slot, item in pairs(inventory.slots or {}) do
		data.slots[slot] = {
			class = item.class,
			count = item.count or 1,
			data = item.data or {}
		}
	end
	
	hg.Net.SendPly(ply, "InventorySync", data)
end

-- Effect network (lightweight)
function hg.Net.SendEffect(pos, effectName, data, radius)
	if SERVER then
		net.Start("ZC_Effect")
		net.WriteVector(pos)
		net.WriteString(effectName)
		hg.Net.WriteTable(data or {})
		if radius then
			net.SendPVS(pos)
		else
			net.Broadcast()
		end
	end
end

if CLIENT then
	net.Receive("ZC_Effect", function()
		local pos = net.ReadVector()
		local name = net.ReadString()
		local data = hg.Net.ReadTable()
		
		local effectData = EffectData()
		effectData:SetOrigin(pos)
		for k, v in pairs(data) do
			effectData["Set" .. k:sub(1,1):upper() .. k:sub(2)](effectData, v)
		end
		util.Effect(name, effectData, true, true)
	end)
end

-- Console command networking
function hg.Net.ConsoleCommand(ply, cmd, args)
	hg.Net.SendPly(ply, "ConsoleCmd", {cmd = cmd, args = args})
end

print("[ZC Net] Networking library loaded")