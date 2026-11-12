-- Rellena el anillo: lugares (pozos, charcas, desguace, campamento), el bosque, coches,
-- puestos de vigía y los marcadores invisibles que usan los sistemas
-- (dónde caen las cajas, dónde aparecen los enemigos y por dónde patrullan).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Estructuras = require(script.Parent.Estructuras)
local Props = require(script.Parent.Props)
local Terreno = require(script.Parent.Terreno)
local Util = require(script.Parent.Util)

local Bosque = {}

local M = Enum.Material
local V = Vector3.new
local rgb = Util.rgb
local DECO = Util.DECO
local MAPA = Config.MAPA
local polar = Config.polar

-- Rutas de patrulla: radio y número de puntos
Bosque.RUTAS = {
	{ radio = 60, puntos = 16 },
	{ radio = 130, puntos = 26 },
	{ radio = 215, puntos = 34 },
	{ radio = 278, puntos = 40 },
}

-- 📍 Sitios ocupados --------------------------------------------------------------------------
local ocupado: { { any } } = {}

function Bosque.reservar(pos: Vector3, radio: number)
	table.insert(ocupado, { V(pos.X, 0, pos.Z), radio })
end

local function enCamino(pos: Vector3, margen: number): boolean
	local plano = V(pos.X, 0, pos.Z)
	local r = plano.Magnitude
	local medio = Terreno.ANCHO_CAMINO / 2
	for _, radio in Terreno.ANILLOS do
		if math.abs(r - radio) < medio + margen then
			return true
		end
	end
	if r > 36 then
		for _, g in Terreno.RADIALES do
			local a = math.rad(g)
			local dir = V(math.cos(a), 0, math.sin(a))
			if plano:Dot(dir) > 0 then
				local perp = math.abs(plano.X * dir.Z - plano.Z * dir.X)
				if perp < medio + margen then
					return true
				end
			end
		end
	end
	return false
end

function Bosque.libre(pos: Vector3, radio: number, sinCaminos: boolean?): boolean
	local plano = V(pos.X, 0, pos.Z)
	if plano.Magnitude > MAPA.RADIO - radio - 6 then
		return false
	end
	for _, o in ocupado do
		if (plano - o[1]).Magnitude < radio + o[2] then
			return false
		end
	end
	if not sinCaminos and enCamino(pos, radio) then
		return false
	end
	return true
end

-- Un sitio libre al azar entre rMin y rMax (o nil si no encuentra).
function Bosque.sitio(rMin: number, rMax: number, radio: number, sinCaminos: boolean?): Vector3?
	for _ = 1, 50 do
		local p = polar(Util.entre(rMin, rMax), Util.entre(0, 360), 0)
		if Bosque.libre(p, radio, sinCaminos) then
			return p
		end
	end
	return nil
end

-- Aparta los sitios de todas las construcciones grandes.
function Bosque.reservarConstrucciones()
	Bosque.reservar(V(0, 0, 0), 42)
	for _, g in Estructuras.CUERDAS_NEXO do
		Bosque.reservar(polar(42, g), 5)
	end
	for i = 1, MAPA.BASES do
		local ang = Config.anguloBase(i)
		local suelo = polar(MAPA.RADIO_BASES, ang)
		local cf = CFrame.lookAt(suelo, V(0, 0, 0))
		Bosque.reservar(suelo, 25)
		Bosque.reservar((cf * CFrame.new(10, 0, 21.5)).Position, 5)
		for d = 30, 105, 30 do
			Bosque.reservar(polar(MAPA.RADIO_NEXO + d, ang), 7)
		end
	end
	for k = 0, 7 do
		local g = k * 45 + 22.5
		Bosque.reservar(polar(MAPA.RADIO_ATALAYAS_DENTRO, g), 10)
		Bosque.reservar(polar(MAPA.RADIO_ATALAYAS_DENTRO + 10.5, g), 4)
		Bosque.reservar(polar(MAPA.RADIO_ATALAYAS_FUERA, g), 10)
		Bosque.reservar(polar(MAPA.RADIO_ATALAYAS_FUERA + 10.5, g), 4)
		Bosque.reservar(polar(MAPA.RADIO_GIGANTES, g), 21)
		Bosque.reservar(polar(MAPA.RADIO_GIGANTES - 19, g), 5)
		Bosque.reservar(polar(MAPA.RADIO_LUGARES, g), 20)
		Bosque.reservar(polar(268, k * 45), 17)
	end
end

-- 🏘️ Lugares ------------------------------------------------------------------------------------

local function pozo(f, pos: Vector3, g: number)
	Props.pozo(f, pos)
	for i = 1, 3 do
		Props.bidon(f, pos + polar(Util.entre(6.5, 8.5), g + 60 + i * 35))
	end
	local s = pos + polar(11, g - 35)
	Props.cartel(f, s, s + (s - pos), "💧 POZO")
end

local function charca(f, pos: Vector3, g: number)
	for i = 0, 3 do
		Util.bloque(f, V(3, 2, 3), pos + polar(15.5, g + 45 + i * 90, 1.5), Color3.new(), M.SmoothPlastic, {
			Name = "Orilla",
			Transparency = 1,
			Deco = true,
			Etiqueta = "Charca",
		})
	end
	for _ = 1, 26 do
		local p = pos + polar(Util.entre(13, 17), Util.entre(0, 360))
		local alto = Util.entre(2, 4.5)
		Util.cilindroV(f, 0.25, alto, p + V(0, alto / 2 - 0.3, 0), rgb(96, 120, 64), M.Grass, DECO)
	end
	local s = pos + polar(20, g - 30)
	Props.cartel(f, s, s + (s - pos), "CHARCA\n(agua sucia)")
end

local function desguace(f, pos: Vector3, g: number)
	Props.coche(f, pos, Util.entre(0, 6), true)
	Props.coche(f, pos + V(0, 4.1, 0.5), Util.entre(0, 6), false)
	for i = 1, 5 do
		local a = g + i * 72 + Util.entre(-8, 8)
		Props.coche(f, pos + polar(12.5, a), -math.rad(a) + Util.entre(-0.25, 0.25), true)
	end
	-- Valla de chapa a medio caer
	for i = 0, 9 do
		local a = g + 200 + i * 14
		local p = pos + polar(19, a)
		if i % 4 ~= 2 then
			Util.bloque(f, V(0.3, Util.entre(4, 6), 5), CFrame.new(p + V(0, 2.4, 0)) * CFrame.Angles(0, -math.rad(a), math.rad(Util.entre(-8, 8))), Props.COLORES.metal:Lerp(Props.COLORES.oxido, Util.entre(0, 1)), M.CorrodedMetal)
		end
	end
	local bidon = Props.bidon(f, pos + polar(7, g + 180), rgb(60, 60, 64))
	local fuego = Instance.new("Fire")
	fuego.Size = 4
	fuego.Heat = 8
	fuego.Parent = bidon:FindFirstChildWhichIsA("BasePart")
	Util.luz(bidon:FindFirstChildWhichIsA("BasePart") :: BasePart, rgb(255, 150, 70), 24, 1.4, true)
	local s = pos + polar(21, g - 25)
	Props.cartel(f, s, s + (s - pos), "⚙️ DESGUACE")
end

local function campamento(f, pos: Vector3, g: number)
	for i = 1, 4 do
		local a = g + i * 90 + 45
		Props.tienda(f, pos + polar(11, a), -math.rad(a), Util.elegir({ Props.COLORES.lona, rgb(140, 70, 50), rgb(60, 80, 110) }))
	end
	-- Hoguera apagada
	for i = 0, 7 do
		Util.bloque(f, V(1.2, 0.8, 1), CFrame.new(pos + polar(2.2, i * 45, 0.4)) * CFrame.Angles(0, -math.rad(i * 45), 0), rgb(90, 88, 84), M.Slate)
	end
	for i = 0, 2 do
		local a = i * 60
		Util.barra(f, 0.5, pos + polar(1.4, a, 0.3), pos + polar(1.4, a + 180, 0.6), Props.COLORES.troncoOscuro, M.Wood, DECO)
	end
	local brasas = Util.bloque(f, V(2, 0.2, 2), pos + V(0, 0.2, 0), rgb(40, 30, 26), M.Slate, DECO)
	local humo = Instance.new("Smoke")
	humo.Color = rgb(90, 90, 90)
	humo.Opacity = 0.15
	humo.RiseVelocity = 3
	humo.Size = 3
	humo.Parent = brasas
	Props.cajaVieja(f, pos + polar(6, g + 10), 0.5)
	Props.cajaVieja(f, pos + polar(6, g + 190), 1.2)
	Props.barricada(f, pos + polar(17, g + 60), pos + polar(17, g + 100))
	Props.barricada(f, pos + polar(17, g + 240), pos + polar(17, g + 280))
	Props.farol(f, pos + polar(5, g + 100), 6)
	local s = pos + polar(20, g - 25)
	Props.cartel(f, s, s + (s - pos), "⛺ CAMPAMENTO")
end

function Bosque.lugares(raiz: Instance)
	local f = Util.carpeta("Lugares", raiz)
	for k, tipo in Config.LUGARES do
		local g = (k - 1) * 45 + 22.5
		local pos = Terreno.posLugar(k)
		if tipo == "Pozo" then
			pozo(f, pos, g)
		elseif tipo == "Charca" then
			charca(f, pos, g)
		elseif tipo == "Desguace" then
			desguace(f, pos, g)
		elseif tipo == "Campamento" then
			campamento(f, pos, g)
		end
	end
end

-- 🌳 Árboles gigantes y atalayas -------------------------------------------------------------------

function Bosque.gigantes(raiz: Instance)
	local f = Util.carpeta("ArbolesGigantes", raiz)
	for k = 0, 7 do
		local g = k * 45 + 22.5
		local base = polar(MAPA.RADIO_GIGANTES, g)
		local hacia = g + 180 -- la cuerda cuelga del lado que mira al centro
		local d = Util.entre(11, 14)
		local arbol, info = Props.arbolGigante(f, base, {
			alto = Util.entre(95, 115),
			diametro = d,
			plataforma = 58,
			huecoGrados = hacia,
		})
		if info then
			Props.cuerda(
				arbol,
				base + polar(info.radio + 3.5, hacia),
				base + polar(info.radio - 2.5, hacia, info.altura),
				base + polar(info.radio + 0.8, hacia),
				info.altura,
				"COPA"
			)
			Props.marcador(base + polar(d / 2 + 4.5, hacia + 120, info.altura + 1), "PuntoCaida", { Zona = "Copa", Radio = 0 })
		end
		-- Árboles grandes del fondo, detrás de cada base
		Props.arbolGigante(f, polar(268, k * 45), { alto = Util.entre(80, 100), diametro = Util.entre(9, 12) })
	end
end

function Bosque.atalayas(raiz: Instance)
	local f = Util.carpeta("Atalayas", raiz)
	for k = 0, 7 do
		local g = k * 45 + 22.5
		Estructuras.atalaya(f, polar(MAPA.RADIO_ATALAYAS_DENTRO, g), MAPA.ALTURA_ATALAYAS_DENTRO, "ATALAYA")
		Estructuras.atalaya(f, polar(MAPA.RADIO_ATALAYAS_FUERA, g), MAPA.ALTURA_ATALAYAS_FUERA, "ATALAYA")
	end
end

-- 🌲 El bosque y los marcadores ---------------------------------------------------------------------

local CARTELES = {
	"NO BAJES\nDE NOCHE",
	"ELLOS NO\nSABEN SUBIR",
	"🪂 CADA 10 MIN\nCAEN COSAS",
	"¿QUEDA\nALGUIEN?",
	"EL NEXO ↑\nEN EL CENTRO",
	"CUIDADO\nCON LOS VIGÍAS",
}

function Bosque.poblar(raiz: Instance)
	local f = Util.carpeta("Bosque", raiz)

	-- Puntos donde pueden caer cajas en el suelo (se apartan primero para que no crezcan árboles encima)
	for _ = 1, 46 do
		local p = Bosque.sitio(45, MAPA.RADIO - 12, 6, true)
		if p then
			Props.marcador(p + V(0, 1, 0), "PuntoCaida", { Zona = "Suelo", Radio = 3 })
			Bosque.reservar(p, 5)
		end
	end

	-- Puestos de vigía: sacos terreros, un farol y el punto donde se queda el Vigía
	for k = 0, 7 do
		local g = k * 45 + 22.5 + 9
		local p = polar(148, g)
		Props.barricada(f, p + polar(3.5, g - 50), p + polar(3.5, g + 50))
		Props.farol(f, p + polar(2.5, g + 150), 7)
		Props.marcador(p + V(0, 3, 0), "PuntoVigia", { Numero = k + 1 })
		Bosque.reservar(p, 7)
	end

	-- Rutas de patrulla (siguen los caminos; si un punto cae encima de algo, se aparta un poco)
	for numero, ruta in Bosque.RUTAS do
		for i = 1, ruta.puntos do
			local g = (i - 1) / ruta.puntos * 360
			local elegido = polar(ruta.radio, g)
			for _, dr in { 0, 6, -6, 12, -12, 18, -18, 24, -24 } do
				local p = polar(ruta.radio + dr, g)
				if Bosque.libre(p, 2.5, true) then
					elegido = p
					break
				end
			end
			Props.marcador(elegido + V(0, 3, 0), "PuntoRuta", { Ruta = numero, Orden = i })
		end
	end

	-- Puntos donde aparecen los enemigos
	for _ = 1, 44 do
		local p = Bosque.sitio(50, MAPA.RADIO - 10, 3, true)
		if p then
			Props.marcador(p + V(0, 3, 0), "PuntoEnemigo")
		end
	end

	-- Coches abandonados (algunos ardiendo)
	for i = 1, 12 do
		local p = Bosque.sitio(50, MAPA.RADIO - 12, 7, true)
		if p then
			local coche = Props.coche(f, p, Util.entre(0, 6), i <= 8)
			Bosque.reservar(p, 7)
			if i > 9 then
				local motor = coche:FindFirstChildWhichIsA("BasePart") :: BasePart
				local fuego = Instance.new("Fire")
				fuego.Size = 6
				fuego.Heat = 10
				fuego.Parent = motor
				local humo = Instance.new("Smoke")
				humo.Color = rgb(40, 40, 40)
				humo.Opacity = 0.25
				humo.RiseVelocity = 6
				humo.Size = 6
				humo.Parent = motor
				Util.luz(motor, rgb(255, 140, 60), 30, 1.6, true)
			end
		end
	end

	-- Barricadas que cortan medio camino y carteles
	for i = 1, 8 do
		local g = (i - 1) * 45 + Util.entre(5, 15)
		local r = Util.elegir(Terreno.ANILLOS)
		Props.barricada(f, polar(r - 4, g), polar(r + 1, g))
		Bosque.reservar(polar(r - 1.5, g), 4)
	end
	for i, texto in CARTELES do
		local g = (i - 1) * 60 + 30
		Props.cartel(f, polar(66, g), polar(58, g), texto)
		Bosque.reservar(polar(66, g), 3)
	end

	-- Árboles
	local tipos = {
		{ Props.pino, 135, 3.5 },
		{ Props.roble, 60, 5 },
		{ Props.arbolSeco, 55, 3 },
	}
	for _, t in tipos do
		for _ = 1, t[2] do
			local p = Bosque.sitio(40, MAPA.RADIO - 6, t[3])
			if p then
				t[1](f, p)
				Bosque.reservar(p, t[3] - 1)
			end
		end
	end

	-- Arbustos de bayas
	for _ = 1, 34 do
		local p = Bosque.sitio(45, MAPA.RADIO - 10, 3.5)
		if p then
			Props.arbustoBayas(f, p)
			Bosque.reservar(p, 3)
		end
	end

	-- Rocas, matorrales y bidones
	for _ = 1, 45 do
		local p = Bosque.sitio(40, MAPA.RADIO - 4, 3)
		if p then
			Props.roca(f, p, Util.entre(2.5, 6))
			Bosque.reservar(p, 3)
		end
	end
	for _ = 1, 80 do
		local p = Bosque.sitio(38, MAPA.RADIO - 4, 2)
		if p then
			Props.matorral(f, p)
		end
	end
	for _ = 1, 22 do
		local p = Bosque.sitio(45, MAPA.RADIO - 10, 2, true)
		if p then
			Props.bidon(f, p)
			Bosque.reservar(p, 1.5)
		end
	end

end

return Bosque
