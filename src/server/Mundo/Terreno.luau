-- Terreno del anillo: suelo del bosque, caminos, charcas y los acantilados del borde.
-- El suelo jugable está a la altura y = 0.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Util = require(script.Parent.Util)

local Terreno = {}

local M = Enum.Material
local V = Vector3.new
local rgb = Util.rgb
local MAPA = Config.MAPA
local polar = Config.polar

-- Caminos: anillos (radio) y caminos rectos desde el centro (ángulos)
Terreno.ANILLOS = { 60, 130, 215 }
Terreno.RADIALES = { 22.5, 67.5, 112.5, 157.5, 202.5, 247.5, 292.5, 337.5 }
Terreno.ANCHO_CAMINO = 7

-- Rellena una caja de terreno. Las cajas muy grandes se hacen por trozos.
local TROZO = 256
local function caja(x1: number, x2: number, y1: number, y2: number, z1: number, z2: number, material: Enum.Material)
	local xa, xb = math.min(x1, x2), math.max(x1, x2)
	local za, zb = math.min(z1, z2), math.max(z1, z2)
	local ya, yb = math.min(y1, y2), math.max(y1, y2)
	local x = xa
	while x < xb do
		local xFin = math.min(xb, x + TROZO)
		local z = za
		while z < zb do
			local zFin = math.min(zb, z + TROZO)
			Util.terreno(V((x + xFin) / 2, (ya + yb) / 2, (z + zFin) / 2), V(xFin - x, yb - ya, zFin - z), material)
			z = zFin
		end
		x = xFin
	end
end

-- Posición de cada "lugar" (pozo, charca, desguace, campamento).
function Terreno.posLugar(k: number): Vector3
	return polar(MAPA.RADIO_LUGARES, (k - 1) * 45 + 22.5, 0)
end

-- Tramo recto de camino.
local function camino(a: Vector3, b: Vector3, ancho: number, material: Enum.Material)
	local largo = (b - a).Magnitude
	local cf = CFrame.lookAt(V((a.X + b.X) / 2, -1.5, (a.Z + b.Z) / 2), V(b.X, -1.5, b.Z))
	workspace.Terrain:FillBlock(cf, V(ancho, 3, largo + 2), material)
end

local function anilloCamino(radio: number, lados: number, material: Enum.Material)
	for i = 0, lados - 1 do
		camino(polar(radio, i / lados * 360), polar(radio, (i + 1) / lados * 360), Terreno.ANCHO_CAMINO, material)
	end
end

-- Charca redonda: hueco + barro en el fondo + agua.
local function charca(centro: Vector3, radio: number, profundidad: number)
	Util.terrenoCilindro(V(centro.X, -1.5, centro.Z), 3, radio + 3, M.Mud)
	Util.terrenoCilindro(V(centro.X, -profundidad / 2, centro.Z), profundidad + 2, radio, M.Air)
	Util.terrenoCilindro(V(centro.X, -profundidad - 1, centro.Z), 2, radio, M.Mud)
	Util.terrenoCilindro(V(centro.X, -profundidad / 2 - 1, centro.Z), profundidad, radio, M.Water)
end

function Terreno.construir()
	local t = workspace.Terrain
	t:Clear()

	pcall(function()
		t.Decoration = true -- hierba animada
	end)
	t.WaterColor = rgb(62, 86, 70)
	t.WaterTransparency = 0.7
	t.WaterReflectance = 0.4
	t.WaterWaveSize = 0.08
	t.WaterWaveSpeed = 6
	-- Colores apagados: es el fin del mundo
	t:SetMaterialColor(M.Grass, rgb(92, 112, 66))
	t:SetMaterialColor(M.LeafyGrass, rgb(62, 80, 52))
	t:SetMaterialColor(M.Ground, rgb(98, 84, 66))
	t:SetMaterialColor(M.Mud, rgb(66, 56, 46))
	t:SetMaterialColor(M.Rock, rgb(98, 98, 94))
	t:SetMaterialColor(M.Slate, rgb(80, 80, 78))

	-- Suelo
	caja(-470, 470, -16, 0, -470, 470, M.Grass)
	-- Manchas de hojarasca, barro y tierra
	for _ = 1, 170 do
		local p = polar(Util.entre(0, MAPA.RADIO), Util.entre(0, 360), -1)
		Util.terrenoCilindro(p, 2, Util.entre(6, 22), Util.elegir({ M.LeafyGrass, M.LeafyGrass, M.Mud, M.Ground, M.Grass }))
	end
	-- Tierra bajo el Árbol Madre
	Util.terrenoCilindro(V(0, -1, 0), 2, 42, M.Ground)

	-- Caminos
	anilloCamino(Terreno.ANILLOS[1], 24, M.Ground)
	anilloCamino(Terreno.ANILLOS[2], 40, M.Ground)
	anilloCamino(Terreno.ANILLOS[3], 56, M.Mud)
	for _, g in Terreno.RADIALES do
		camino(polar(40, g), polar(MAPA.RADIO - 8, g), Terreno.ANCHO_CAMINO - 1, M.Ground)
	end

	-- Charcas
	for k, lugar in Config.LUGARES do
		if lugar == "Charca" then
			charca(Terreno.posLugar(k), 14, 7)
		end
	end

	-- ⛰️ Acantilados del borde y montañas de fondo
	for g = 0, 359, 5 do
		Util.terrenoBola(polar(Util.entre(330, 345), g + Util.entre(-2, 2), Util.entre(-4, 14)), Util.entre(26, 38), M.Rock)
		Util.terrenoBola(polar(Util.entre(360, 390), g, Util.entre(10, 40)), Util.entre(40, 60), Util.elegir({ M.Rock, M.Rock, M.Grass, M.Ground }))
	end
	for g = 0, 359, 9 do
		Util.terrenoBola(polar(Util.entre(420, 460), g, Util.entre(30, 70)), Util.entre(60, 90), Util.elegir({ M.Rock, M.Grass }))
	end
end

return Terreno
