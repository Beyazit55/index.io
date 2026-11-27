-- ============================================================
-- SCP: Roleplay Server Addon - "Medikal" modeli, PARCA 2/3 (1364 parca)
-- Uc addonu da (1, 2, 3) sirayla ayri ayri calistir; OX, OY, OZ hepsinde AYNI kalmali.
-- Veriyi GitHub'dan indirir ve parcalari birebir kurar (mesh, doku, isik).
-- NORMAL addon olarak calistir (Run Once 10 saniyede durdurur).
-- Konum: modelin TABAN ORTASI X=240, Y=10, Z=10 noktasina kurulur
-- (Prison (10,10,10) ile ust uste binmesin diye yanina, 20 stud bosluklu).
-- Baska yere almak icin asagidaki OX, OY, OZ degerlerini degistir.
-- Model boyutu: yaklasik 303 x 60 x 262 stud (X, Y, Z).
-- ============================================================
local OX, OY, OZ = 240, 10, 10
local GH = "https://raw.githubusercontent.com/Beyazit55/index.io/oota-harita/medikal/"
local GM = "https://raw.githubusercontent.com/Beyazit55/index.io/main/medikal/"
local FILES = {"medikal_04", "medikal_05", "medikal_06"}

-- metin siniri yuzunden print hata verebilir; addon durmasin diye hep pcall ile yazilir
local function log(...) pcall(print, ...) end
local function wlog(...) pcall(warn, ...) end
log("Medikal 2/3 yukleyici basladi, dosya:", #FILES)
local KINDS = {"Part", "WedgePart", "CornerWedgePart", "TrussPart", "Seat"}
local failed = {}
local made, bad, firstErr, recovered = 0, 0, nil, 0
local stage = ""
local stages = {}
local function try(what, fn)
	local ok = pcall(fn)
	if not ok then failed[what] = (failed[what] or 0) + 1 end
	return ok
end

local function build(D)
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
local function get(name)
	local list = {GH .. name .. ".json", GM .. name .. ".json"}
	for k = 1, #list do
		local D = getOne(list[k])
		if D then return D end
	end
	log("Indirme basarisiz:", name, lastErr)
	return nil
end

local okFiles = 0
for n = 1, #FILES do
	local D = get(FILES[n])
	if D then
		okFiles = okFiles + 1
		local ok, err = pcall(build, D)
		if not ok then log("Kurulum hatasi:", tostring(err)) end
	end
end
log("Medikal 2/3 kuruldu. Parca:", made, "Dosya:", okFiles, "/", #FILES)
-- ozet, oyunun metin sinirina takilmasin diye 1 dakika sonra yazilir
task.wait(61)
log("OZET. Kurulan:", made, "Kurtarilan:", recovered, "Kurulamayan:", bad, "Beklenen: 1364")
if bad > 0 and firstErr then
	local list = ""
	for k, v in pairs(stages) do list = list .. k .. "=" .. v .. " " end
	wlog("Hata adimlari:", list, "| Ilk hata:", firstErr)
end
for w, v in pairs(failed) do wlog("Desteklenmeyen ozellik:", w, "x", v) end
