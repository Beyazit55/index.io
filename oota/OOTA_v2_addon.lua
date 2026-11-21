-- ============================================================
-- SCP: Roleplay Server Addon - Office of The Administrator (OoTA) v2
-- Tek addon: haritayi indirir ve kurar (mesh + doku), toplanti salonu
-- tavan kapaklarini/ekranlarini komut menusune baglar, robotlari calistirir.
-- NORMAL addon olarak calistir (Run Once 10 saniyede durdurur).
-- Komutlar (:addoncommands menusu veya /command <id>):
--   ekranac    -> Tavan kapaklari acilir, 4 ekran iner
--   ekrankapat -> Ekranlar yukari cekilir, kapaklar kapanir
--   robotselam -> Resepsiyon robotu karsilama anonsu yapar
-- Konum: yapinin merkezi (ana koridor zemini) X=10, Y=10, Z=10 noktasina kurulur.
-- Zemin ust yuzeyi Y=10'dadir. Baska yere almak icin OX, OY, OZ degistir.
-- ============================================================
local OX, OY, OZ = -1490, 0, 10 -- veri X=1500,Y=10,Z=0 merkezli; bu kaydirma merkezi (10, 10, 10) yapar
-- Veri GitHub'dan (herkese acik repo) indirilir; olmazsa paste.rs yedegi denenir.
local GH = "https://raw.githubusercontent.com/Beyazit55/index.io/oota-harita/oota/"
local GM = "https://raw.githubusercontent.com/Beyazit55/index.io/main/oota/"
local URLS = {
	{GH .. "veri_01.json", GM .. "veri_01.json", "https://paste.rs/P4GHA"},
	{GH .. "veri_02.json", GM .. "veri_02.json", "https://paste.rs/mKViZ"},
	{GH .. "veri_03.json", GM .. "veri_03.json", "https://paste.rs/noGcC"},
	{GH .. "veri_04.json", GM .. "veri_04.json", "https://paste.rs/CkIzA"},
	{GH .. "veri_05.json", GM .. "veri_05.json", "https://paste.rs/FDM3j"},
}
local MOVERS_URL = {GH .. "veri_hareketli.json", GM .. "veri_hareketli.json", "https://paste.rs/hAyro"}

-- metin siniri yuzunden print hata verebilir; addon durmasin diye hep pcall ile yazilir
local function log(...) pcall(print, ...) end
local function wlog(...) pcall(warn, ...) end
log("OoTA v2 yukleyici basladi, dosya:", #URLS + 1)
local KINDS = {"Part", "WedgePart", "CornerWedgePart", "TrussPart", "Seat"}
local failed = {}
local made, bad, firstErr, recovered = 0, 0, nil, 0
local stage = ""
local stages = {}
local allParts = {}
local function try(what, fn)
	local ok = pcall(fn)
	if not ok then failed[what] = (failed[what] or 0) + 1 end
	return ok
end

-- ================= 1) map builder =================
local function build(D, onPart)
	local T, ST, ROT, MESH, DSET, LSET, MAT = D.T, D.ST, D.ROT, D.MESH, D.DSET, D.LSET, D.MAT
	local function one(i)
		stage = "veri"
		local q = (T[i + 4] - 1) * 16
		local r = (T[i + 3] - 1) * 9
		local k = ST[q + 1]
		local p
		if k ~= 1 then try(KINDS[k], function() p = Instance.new(KINDS[k]) end) end
		stage = "Instance.new"
		if not p then p = Instance.new("Part") end
		stage = "ozellik"
		p.Anchored = true
		p.Size = Vector3.new(ST[q + 2], ST[q + 3], ST[q + 4])
		p.CFrame = CFrame.new(T[i] + OX, T[i + 1] + OY, T[i + 2] + OZ, ROT[r + 1], ROT[r + 2], ROT[r + 3], ROT[r + 4], ROT[r + 5], ROT[r + 6], ROT[r + 7], ROT[r + 8], ROT[r + 9])
		p.Color = Color3.new(ST[q + 5] / 255, ST[q + 6] / 255, ST[q + 7] / 255)
		local m = MAT[ST[q + 8]]
		if m ~= "Plastic" then try("Material", function() p.Material = Enum.Material[m] end) end
		try("Surface", function()
			p.TopSurface = Enum.SurfaceType.Smooth
			p.BottomSurface = Enum.SurfaceType.Smooth
		end)
		if ST[q + 9] ~= 0 then p.Transparency = ST[q + 9] end
		if ST[q + 10] == 0 then p.CanCollide = false end
		if ST[q + 11] == 0 then try("CastShadow", function() p.CastShadow = false end) end
		if ST[q + 12] ~= 0 then try("Reflectance", function() p.Reflectance = ST[q + 12] end) end
		if ST[q + 13] == 1 then try("Shape", function() p.Shape = Enum.PartType.Ball end) end
		if ST[q + 13] == 2 then try("Shape", function() p.Shape = Enum.PartType.Cylinder end) end
		stage = "f(parca)"
		f(p)
		allParts[#allParts + 1] = p
		stage = "mesh/doku"
		local e = MESH[ST[q + 14]]
		if e then
			try("SpecialMesh", function()
				local x = Instance.new("SpecialMesh")
				if e[12] then x.MeshType = Enum.MeshType[e[12]] else x.MeshType = Enum.MeshType.FileMesh end
				if e[1] ~= "" then x.MeshId = e[1] end
				if e[2] ~= "" then x.TextureId = e[2] end
				x.Scale = Vector3.new(e[3], e[4], e[5])
				if e[6] ~= 0 or e[7] ~= 0 or e[8] ~= 0 then x.Offset = Vector3.new(e[6], e[7], e[8]) end
				if e[9] ~= 1 or e[10] ~= 1 or e[11] ~= 1 then x.VertexColor = Vector3.new(e[9], e[10], e[11]) end
				x.Parent = p
			end)
		end
		local ds = DSET[ST[q + 15]]
		if ds then
			for j = 1, #ds do
				local d = ds[j]
				local cls = "Decal"
				if d[1] == 1 then cls = "Texture" end
				try(cls, function()
					local x = Instance.new(cls)
					x.Texture = d[2]
					x.Face = Enum.NormalId[d[3]]
					if d[4] ~= 255 or d[5] ~= 255 or d[6] ~= 255 then x.Color3 = Color3.new(d[4] / 255, d[5] / 255, d[6] / 255) end
					if d[7] ~= 0 then x.Transparency = d[7] end
					if d[1] == 1 then
						x.StudsPerTileU = d[8]
						x.StudsPerTileV = d[9]
						if d[10] ~= 0 then x.OffsetStudsU = d[10] end
						if d[11] ~= 0 then x.OffsetStudsV = d[11] end
					end
					x.Parent = p
				end)
			end
		end
		local ls = LSET[ST[q + 16]]
		if ls then
			for j = 1, #ls do
				local l = ls[j]
				try(l[1], function()
					local x = Instance.new(l[1])
					x.Brightness = l[2]
					x.Color = Color3.new(l[3] / 255, l[4] / 255, l[5] / 255)
					x.Range = l[6]
					if l[1] ~= "PointLight" then
						x.Angle = l[7]
						x.Face = Enum.NormalId[l[8]]
					end
					x.Shadows = l[9]
					x.Enabled = l[10]
					x.Parent = p
				end)
			end
		end
		if onPart then onPart((i - 1) / 5 + 1, p) end
	end
	local retry = {}
	local i = 1
	local c = 0
	while i <= #T do
		local ok, err = pcall(one, i)
		if ok then
			made = made + 1
		else
			retry[#retry + 1] = i
			stages[stage] = (stages[stage] or 0) + 1
			if not firstErr then firstErr = stage .. ": " .. tostring(err) end
		end
		c = c + 1
		if c % 20 == 0 then task.wait(0.03) end
		i = i + 5
	end
	if #retry > 0 then
		task.wait(3)
		for j = 1, #retry do
			local ok = pcall(one, retry[j])
			if ok then made = made + 1 recovered = recovered + 1 else bad = bad + 1 end
			task.wait(0.1)
		end
	end
end

local lastErr = ""
local function getOne(url)
	for attempt = 1, 2 do
		local ok, res = pcall(http, url)
		if ok and type(res) == "table" and res.Success and type(res.Body) == "string" then
			local ok2, data = pcall(jsonDecode, res.Body)
			if ok2 and type(data) == "table" and data.T then return data end
			lastErr = "json:" .. tostring(data)
		else
			lastErr = ok and ("durum " .. tostring(type(res) == "table" and res.StatusCode or res)) or tostring(res)
		end
		task.wait(2)
	end
	return nil
end
local function get(list)
	for k = 1, #list do
		local D = getOne(list[k])
		if D then return D end
	end
	log("Indirme basarisiz:", list[1], lastErr)
	return nil
end

local n = 1
while n <= #URLS do
	local D = get(URLS[n])
	if D then
		local ok, err = pcall(build, D)
		if not ok then log("Kurulum hatasi:", tostring(err)) end
	end
	n = n + 1
end
log("Harita kuruldu, parca:", made)

-- ================= 2) meeting room hatches + screens =================
local groups = {}
local HATCHES, SCREENS = {}, {}
pcall(function()
	local D = get(MOVERS_URL)
	if D then
		for gi = 1, #D.GN do
			groups[gi] = {off = D.GO[gi], parts = {}, base = {}}
			if D.GT[gi] == "kapak" then HATCHES[#HATCHES + 1] = gi else SCREENS[#SCREENS + 1] = gi end
		end
		build(D, function(idx, p)
			local g = groups[D.G[idx]]
			if g then
				g.parts[#g.parts + 1] = p
				g.base[#g.base + 1] = {p.CFrame:GetComponents()}
			end
		end)
	end
end)
local function setAlpha(g, a)
	local o = g.off
	for i = 1, #g.parts do
		local b = g.base[i]
		pcall(function()
			g.parts[i].CFrame = CFrame.new(b[1] + o[1] * a, b[2] + o[2] * a, b[3] + o[3] * a, b[4], b[5], b[6], b[7], b[8], b[9], b[10], b[11], b[12])
		end)
	end
end
local function animate(list, from, to, steps)
	for s = 1, steps do
		local t = s / steps
		local a = from + (to - from) * (t * t * (3 - 2 * t))
		for k = 1, #list do
			local g = groups[list[k]]
			if g then setAlpha(g, a) end
		end
		task.wait(0.03)
	end
end
local screenState, busy = "kapali", false
local function openScreens()
	if busy or screenState == "acik" then return end
	busy = true
	animate(HATCHES, 0, 1, 40)
	animate(SCREENS, 0, 1, 90)
	screenState = "acik"
	busy = false
end
local function closeScreens()
	if busy or screenState == "kapali" then return end
	busy = true
	animate(SCREENS, 1, 0, 90)
	animate(HATCHES, 1, 0, 40)
	screenState = "kapali"
	busy = false
end

-- ================= 3) robots =================
local LX, LY = 1500, 10 -- harita yerel orijini
local ROOTY = LY + 3.25
-- {sizeX,sizeY,sizeZ, offX,offY,offZ, r,g,b, material, transparency, ball(0/1), name or false}
local RP = {
	{2, 2, 1, 0, 0, 0, 30, 30, 30, "SmoothPlastic", 1, 0, "HumanoidRootPart"},
	{2.2, 2.2, 1.3, 0, 0.6, 0, 225, 228, 234, "SmoothPlastic", 0, 0, false},
	{1.6, 1.2, 0.1, 0, 0.8, -0.68, 30, 32, 37, "Metal", 0, 0, false},
	{0.7, 0.15, 0.05, 0, 0.95, -0.75, 255, 205, 120, "Neon", 0, 0, false},
	{1.6, 0.5, 1.0, 0, -0.75, 0, 40, 42, 48, "Metal", 0, 0, false},
	{0.6, 0.4, 0.6, 0, 1.85, 0, 40, 42, 48, "Metal", 0, 0, false},
	{1.5, 1.2, 1.3, 0, 2.6, 0, 225, 228, 234, "SmoothPlastic", 0, 0, "Head"},
	{1.25, 0.35, 0.05, 0, 2.65, -0.67, 120, 200, 255, "Neon", 0, 0, false},
	{0.12, 0.6, 0.12, 0.5, 3.5, 0, 40, 42, 48, "Metal", 0, 0, false},
	{0.28, 0.28, 0.28, 0.5, 3.85, 0, 255, 45, 45, "Neon", 0, 1, false},
	{0.9, 0.9, 0.9, -1.55, 1.3, 0, 40, 42, 48, "Metal", 0, 1, false},
	{0.9, 0.9, 0.9, 1.55, 1.3, 0, 40, 42, 48, "Metal", 0, 1, false},
	{0.7, 2.2, 0.7, -1.55, 0.1, 0, 225, 228, 234, "SmoothPlastic", 0, 0, false},
	{0.7, 2.2, 0.7, 1.55, 0.1, 0, 225, 228, 234, "SmoothPlastic", 0, 0, false},
	{0.05, 1.2, 0.2, -1.92, 0.3, 0, 120, 200, 255, "Neon", 0, 0, false},
	{0.05, 1.2, 0.2, 1.92, 0.3, 0, 120, 200, 255, "Neon", 0, 0, false},
	{0.6, 0.5, 0.6, -1.55, -1.2, 0, 40, 42, 48, "Metal", 0, 0, false},
	{0.6, 0.5, 0.6, 1.55, -1.2, 0, 40, 42, 48, "Metal", 0, 0, false},
	{0.8, 2.4, 0.9, -0.55, -2.1, 0, 225, 228, 234, "SmoothPlastic", 0, 0, false},
	{0.8, 2.4, 0.9, 0.55, -2.1, 0, 225, 228, 234, "SmoothPlastic", 0, 0, false},
	{0.9, 0.4, 1.3, -0.55, -3.05, -0.15, 40, 42, 48, "Metal", 0, 0, false},
	{0.9, 0.4, 1.3, 0.55, -3.05, -0.15, 40, 42, 48, "Metal", 0, 0, false},
}
local ROBOT_NAME = "OOTA Robot"
local robots = {}
local function placeRobot(r, bob)
	local dx, dz = r.dx, r.dz
	local a, b2, c2, d2 = -dz, -dx, dx, -dz
	for i = 1, #r.parts do
		local d = RP[i]
		local ox, oy, oz = d[4], d[5], d[6]
		r.parts[i].CFrame = CFrame.new(LX + r.x + a * ox + b2 * oz + OX, ROOTY + oy + bob + OY, r.z + c2 * ox + d2 * oz + OZ, a, 0, b2, 0, 1, 0, c2, 0, d2)
	end
end
-- route: list of {x,z} in local coords; one point = standing guard; face = {dx,dz}
local function buildRobot(route, face, talker)
	local r = {x = route[1][1], z = route[1][2], dx = face[1], dz = face[2], parts = {}, wait = 0, target = 2, route = route}
	local m = Instance.new("Model")
	f(m)
	r.model = m
	for i = 1, #RP do
		local d = RP[i]
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = (i == 2)
		p.Size = Vector3.new(d[1], d[2], d[3])
		p.Color = Color3.new(d[7] / 255, d[8] / 255, d[9] / 255)
		if d[10] ~= "Plastic" then try("Material", function() p.Material = Enum.Material[d[10]] end) end
		try("Surface", function()
			p.TopSurface = Enum.SurfaceType.Smooth
			p.BottomSurface = Enum.SurfaceType.Smooth
		end)
		if d[11] ~= 0 then p.Transparency = d[11] end
		if d[12] == 1 then try("Shape", function() p.Shape = Enum.PartType.Ball end) end
		if not pcall(function() p.Parent = m end) then f(p) end
		r.parts[i] = p
	end
	placeRobot(r, 0)
	if talker then
		try("Humanoid", function()
			local h = Instance.new("Humanoid")
			h.Parent = m
			r.humanoid = h
			try("HumanoidAyar", function() h.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end)
		end)
	end
	return r
end
-- 1: resepsiyon (konusan), 2-5: sabit gardiyanlar, 6-8: devriye
local ROBOTS = {
	{{{19.5, 88}}, {-1, 0}, true},
	{{{-6, 63}}, {0, 1}},
	{{{5, 64}}, {0, 1}},
	{{{-8.5, 43.5}}, {0, 1}},
	{{{8.5, 43.5}}, {0, 1}},
	{{{-8, 83}, {8, 83}, {8, 96}, {-8, 96}}, {1, 0}},
	{{{0, 32}, {0, -28}}, {0, -1}},
	{{{46, -68}, {100, -68}}, {1, 0}},
}
for k = 1, #ROBOTS do
	local d = ROBOTS[k]
	local ok, r = pcall(buildRobot, d[1], d[2], d[3])
	if ok and r then robots[#robots + 1] = r else failed["Robot"] = (failed["Robot"] or 0) + 1 end
end
local pendingNames = {}
if robots[1] then
	for i = 1, #RP do if RP[i][13] then pendingNames[#pendingNames + 1] = {robots[1].parts[i], RP[i][13]} end end
	pendingNames[#pendingNames + 1] = {robots[1].model, ROBOT_NAME}
end
local namesOk = false
local nameIdx = 1
local function tryNextName()
	local item = pendingNames[nameIdx]
	if not item then namesOk = true return false end
	local ok = pcall(function() item[1].Name = item[2] end)
	if ok and item[1].Name == item[2] then
		nameIdx = nameIdx + 1
		if nameIdx > #pendingNames then namesOk = true end
		return true
	end
	return false
end
while not namesOk and tryNextName() do end
local nextNameTry = 61

local clock = 0
local lastSay = -1000
local LINES = {
	"Bu alan OoTA guvenligi tarafindan izlenmektedir.",
	"Lutfen tarayicidan tek tek gecin.",
	"Kimlik dogrulamasi olmadan gecis yasaktir.",
}
local lineIndex = 0
local function say(msg, force)
	if not force and clock - lastSay < 65 then return false end
	lastSay = clock
	local ok = pcall(rigSay, ROBOT_NAME, msg)
	return ok
end
-- sensors inside the two metal detector arches
for _, ax in ipairs({-10, -2}) do
	pcall(function()
		local s = Instance.new("Part")
		s.Anchored = true
		s.CanCollide = false
		s.Transparency = 1
		s.Size = Vector3.new(3.4, 6, 1.6)
		s.CFrame = CFrame.new(LX + ax + OX, LY + 3 + OY, 70 + OZ)
		f(s)
		allParts[#allParts + 1] = s
		s.Touched:Connect(function(hit)
			say("Tarama yapiliyor... Kimlik dogrulandi. Gecebilirsiniz.")
		end)
	end)
end

-- ================= 4) commands =================
local cmdOk = pcall(function()
	registerAddonCommand("ekranac", "Toplanti Ekranlarini Ac", function(player) openScreens() end)
	registerAddonCommand("ekrankapat", "Toplanti Ekranlarini Kapat", function(player) closeScreens() end)
	registerAddonCommand("robotselam", "Robot Karsilama Anonsu", function(player)
		say("OoTA tesisine hos geldiniz. Lutfen guvenlik prosedurlerine uyun.", true)
	end)
end)
log("Ekranlar ve robotlar hazir. Robot:", #robots, "Komutlar:", cmdOk)

-- ================= 5) patrol loop =================
local SPEED = 4
local DT = 0.05
local summaryDone = false
local nextIdle = 120
while true do
	clock = clock + DT
	for k = 1, #robots do
		local r = robots[k]
		if #r.route > 1 then
			local bob = 0
			if r.wait > 0 then
				r.wait = r.wait - DT
			else
				local tgt = r.route[r.target]
				local vx, vz = tgt[1] - r.x, tgt[2] - r.z
				local dist = (vx * vx + vz * vz) ^ 0.5
				if dist < 0.2 then
					r.wait = 2.5
					r.target = r.target % #r.route + 1
				else
					local step = SPEED * DT
					if step > dist then step = dist end
					r.dx, r.dz = vx / dist, vz / dist
					r.x = r.x + r.dx * step
					r.z = r.z + r.dz * step
					bob = 0.08 * math.sin(clock * 9 + k)
				end
			end
			pcall(placeRobot, r, bob)
		end
	end
	if not namesOk and clock >= nextNameTry then
		while not namesOk and tryNextName() do end
		nextNameTry = clock + 61
	end
	if clock >= nextIdle then
		nextIdle = clock + 120
		lineIndex = lineIndex % #LINES + 1
		say(LINES[lineIndex])
	end
	if not summaryDone and clock >= 61 then
		summaryDone = true
		log("OZET. Kurulan:", made, "Kurtarilan:", recovered, "Kurulamayan:", bad, "Robot isimleri:", namesOk)
		if bad > 0 and firstErr then
			local list = ""
			for kk, v in pairs(stages) do list = list .. kk .. "=" .. v .. " " end
			wlog("Hata adimlari:", list, "| Ilk hata:", firstErr)
		end
		for w, v in pairs(failed) do wlog("Desteklenmeyen ozellik:", w, "x", v) end
	end
	task.wait(DT)
end
