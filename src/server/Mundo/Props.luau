-- Objetos reutilizables del mapa: árboles (normales y gigantes), rocas, arbustos de bayas,
-- pozos, coches abandonados, tiendas, bidones, faroles, cuerdas, tirolinas y cajas.
-- Los objetos con los que se interactúa llevan una etiqueta (Tag) que buscan los sistemas.
local Plantillas = require(script.Parent.Plantillas)
local Util = require(script.Parent.Util)

local Props = {}

local M = Enum.Material
local rgb = Util.rgb
local DECO = Util.DECO
local V = Vector3.new

Props.COLORES = {
	tronco = rgb(92, 70, 52),
	troncoOscuro = rgb(58, 48, 42),
	troncoGigante = rgb(86, 68, 52),
	hojas = rgb(74, 100, 58),
	hojasOscuras = rgb(40, 60, 44),
	hojasSecas = rgb(126, 108, 64),
	madera = rgb(126, 94, 64),
	maderaOscura = rgb(78, 58, 42),
	maderaVieja = rgb(112, 100, 84),
	metal = rgb(98, 102, 106),
	oxido = rgb(142, 80, 48),
	piedra = rgb(112, 112, 108),
	cuerda = rgb(172, 144, 102),
	cable = rgb(38, 38, 42),
	lona = rgb(94, 106, 82),
	luz = rgb(255, 196, 120),
}
local C = Props.COLORES

local VERDES = {
	rgb(74, 100, 58),
	rgb(62, 88, 52),
	rgb(88, 104, 60),
	rgb(104, 106, 62),
	rgb(52, 76, 50),
}

-- Carpeta donde van los marcadores invisibles (puntos de caída, de enemigos...).
Props.marcadores = nil :: Folder?

function Props.marcador(pos: Vector3, etiqueta: string, atributos)
	return Util.parte({
		Parent = Props.marcadores,
		Name = etiqueta,
		Size = V(1, 1, 1),
		Position = pos,
		Transparency = 1,
		Deco = true,
		Etiqueta = etiqueta,
		Atributos = atributos,
	})
end

-- Parte invisible que sirve para colgar el botón de interacción.
local function centro(m: Model, pos: Vector3, tam: Vector3?)
	local p = Util.bloque(m, tam or V(1.5, 1.5, 1.5), pos, Color3.new(), M.SmoothPlastic, {
		Name = "Centro",
		Transparency = 1,
		CanCollide = false,
		CanTouch = false,
		CanQuery = false,
	})
	m.PrimaryPart = p
	return p
end
Props.centro = centro

-- 🌲 Árboles normales -------------------------------------------------------------------------
-- Si hay una plantilla (ver Plantillas.luau) se usa esa. Si no, se construyen con código.
-- Props.CONSTRUIR tiene los árboles hechos con código (sirven para crear las plantillas).
Props.CONSTRUIR = {}

function Props.CONSTRUIR.Pino(padre, base: Vector3, escala: number?)
	local s = Util.entre(0.85, 1.4) * (escala or 1)
	local m = Util.modelo("Pino", padre)
	local hTronco = 5 * s
	local niveles = 4
	local alturaTotal = hTronco + niveles * 3.4 * s
	local tronco = Util.cilindroV(m, 1.3 * s, alturaTotal, base + V(0, alturaTotal / 2, 0), C.troncoOscuro, M.Wood)
	tronco.Name = "Tronco"
	local verde = rgb(40, 66, 48):Lerp(rgb(60, 78, 50), Util.entre(0, 1))
	for i = 1, niveles do
		local t = (i - 1) / (niveles - 1)
		local ancho = (10 - 6.5 * t) * s
		local alto = (4.6 - 0.8 * t) * s
		local y = hTronco + (i - 1) * 3.4 * s + alto / 2 - 0.5
		Util.elipsoide(m, V(ancho, alto, ancho), base + V(0, y, 0), verde:Lerp(rgb(20, 34, 26), Util.entre(0, 0.3)), M.LeafyGrass, DECO)
	end
	Util.elipsoide(m, V(2 * s, 4 * s, 2 * s), base + V(0, alturaTotal + 1.2 * s, 0), verde, M.LeafyGrass, DECO)
	m.PrimaryPart = tronco
	return m
end

-- Árbol de hoja ancha (con hojas un poco enfermas: es el fin del mundo).
function Props.CONSTRUIR.Roble(padre, base: Vector3)
	local h = Util.entre(11, 17)
	local m = Util.modelo("Roble", padre)
	local hTronco = h * 0.55
	local tronco = Util.cilindroV(m, Util.entre(1.6, 2.2), hTronco, base + V(0, hTronco / 2, 0), C.tronco, M.Wood)
	tronco.Name = "Tronco"
	local copa = base + V(0, hTronco + h * 0.15, 0)
	local color = Util.elegir(VERDES)
	Util.elipsoide(m, V(h * 0.75, h * 0.5, h * 0.75), copa, color, M.LeafyGrass, DECO)
	for i = 1, 4 do
		local a = i * math.pi / 2 + Util.entre(-0.4, 0.4)
		local offset = V(math.cos(a) * h * 0.25, Util.entre(-0.5, 1.5), math.sin(a) * h * 0.25)
		Util.elipsoide(m, V(h * 0.45, h * 0.35, h * 0.45), copa + offset, color:Lerp(C.hojasSecas, Util.entre(0, 0.45)), M.LeafyGrass, DECO)
	end
	m.PrimaryPart = tronco
	return m
end

-- Árbol muerto, sin hojas.
function Props.CONSTRUIR.ArbolSeco(padre, base: Vector3)
	local m = Util.modelo("ArbolSeco", padre)
	local alto = Util.entre(9, 16)
	local c = C.troncoOscuro:Lerp(rgb(90, 84, 78), Util.entre(0, 0.6))
	local tronco = Util.cilindroV(m, 1.6, alto, base + V(0, alto / 2, 0), c, M.Wood)
	tronco.Name = "Tronco"
	for i = 1, 4 do
		local a = i * 1.6 + Util.entre(-0.4, 0.4)
		local desde = base + V(0, alto * Util.entre(0.5, 0.9), 0)
		local hasta = desde + V(math.cos(a) * Util.entre(3, 5), Util.entre(2, 4), math.sin(a) * Util.entre(3, 5))
		Util.barra(m, 0.5, desde, hasta, c, M.Wood, DECO)
	end
	m.PrimaryPart = tronco
	return m
end

-- Si una plantilla está rota, avisa una vez y usa el árbol hecho con código (el mapa nunca se queda a medias).
local plantillaRota = {}
local function conPlantilla(tipo: string, padre, base: Vector3, escala: number?)
	if plantillaRota[tipo] then
		return nil
	end
	local ok, resultado = pcall(Plantillas.colocar, tipo, padre, base, escala)
	if ok then
		return resultado
	end
	plantillaRota[tipo] = true
	warn("[Mapa] La plantilla " .. tipo .. " da error, uso el árbol de código: " .. tostring(resultado))
	return nil
end

function Props.pino(padre, base: Vector3, escala: number?)
	return conPlantilla("Pino", padre, base, escala) or Props.CONSTRUIR.Pino(padre, base, escala)
end

function Props.roble(padre, base: Vector3)
	return conPlantilla("Roble", padre, base) or Props.CONSTRUIR.Roble(padre, base)
end

function Props.arbolSeco(padre, base: Vector3)
	return conPlantilla("ArbolSeco", padre, base) or Props.CONSTRUIR.ArbolSeco(padre, base)
end

-- 🌳 Árbol gigante ----------------------------------------------------------------------------
-- opciones: { alto, diametro, plataforma (altura de la plataforma, opcional), huecoGrados }
-- Devuelve el modelo y, si tiene plataforma, { radio, altura }.
function Props.arbolGigante(padre, base: Vector3, opciones)
	local alto = opciones.alto or 100
	local d = opciones.diametro or 12
	local m = Util.modelo("ArbolGigante", padre)
	local tramos = 4
	local y = 0
	for i = 1, tramos do
		local di = d * (1 - (i - 1) * 0.14)
		local h = alto / tramos
		local t = Util.cilindroV(m, di, h + 0.4, base + V(0, y + h / 2, 0), C.troncoGigante:Lerp(C.troncoOscuro, (i - 1) * 0.1), M.Wood)
		t.Name = "Tronco"
		if i == 1 then
			m.PrimaryPart = t
		end
		y += h
	end
	-- Raíces (se puede andar por encima)
	for i = 1, 7 do
		local a = i / 7 * math.pi * 2 + Util.entre(-0.2, 0.2)
		local desde = base + V(math.cos(a) * d * 0.3, d * 0.45, math.sin(a) * d * 0.3)
		local hasta = base + V(math.cos(a) * d * 1.05, -0.6, math.sin(a) * d * 1.05)
		Util.barra(m, d * 0.26, desde, hasta, C.troncoGigante, M.Wood).Name = "Raiz"
	end
	-- Ramas con copas en la punta
	local verde = Util.elegir(VERDES)
	for i = 1, 6 do
		local a = i / 6 * math.pi * 2 + Util.entre(-0.3, 0.3)
		local yR = alto * Util.entre(0.62, 0.9)
		local largo = Util.entre(15, 24) * (d / 12)
		local desde = base + V(0, yR, 0)
		local hasta = desde + V(math.cos(a) * largo, Util.entre(4, 10), math.sin(a) * largo)
		Util.barra(m, d * 0.16, desde, hasta, C.troncoGigante, M.Wood, DECO)
		Util.elipsoide(
			m,
			V(Util.entre(18, 26), Util.entre(10, 15), Util.entre(18, 26)) * (d / 12),
			hasta + V(0, 3, 0),
			verde:Lerp(C.hojasSecas, Util.entre(0, 0.35)),
			M.LeafyGrass,
			DECO
		)
	end
	Util.elipsoide(m, V(d * 3, d * 1.5, d * 3), base + V(0, alto + 1, 0), verde, M.LeafyGrass, DECO)

	local info = nil
	if opciones.plataforma then
		local hp = opciones.plataforma
		local radio = d * 0.5 + 9
		local disco = Util.cilindroV(m, radio * 2, 1.2, base + V(0, hp - 0.6, 0), C.madera, M.WoodPlanks)
		disco.Name = "Plataforma"
		Util.pisable(disco)
		Util.cilindroV(m, radio * 2 + 0.6, 0.5, base + V(0, hp - 1.4, 0), C.maderaOscura, M.Wood, DECO)
		-- Vigas de apoyo desde el tronco
		for i = 1, 6 do
			local a = i / 6 * math.pi * 2
			Util.barra(
				m,
				0.9,
				base + V(math.cos(a) * d * 0.42, hp - 9, math.sin(a) * d * 0.42),
				base + V(math.cos(a) * (radio - 1.5), hp - 1.2, math.sin(a) * (radio - 1.5)),
				C.maderaOscura,
				M.Wood
			)
		end
		Props.barandillaCircular(m, base + V(0, hp, 0), radio - 0.5, 14, { opciones.huecoGrados or 0 }, 5)
		Props.farol(m, base + V(math.cos(1) * (radio - 2), hp, math.sin(1) * (radio - 2)), 5)
		info = { radio = radio, altura = hp }
	end
	return m, info
end

-- Barandilla redonda alrededor de "centro" (a la altura del suelo que se pisa).
-- huecos: ángulos en grados donde se deja un hueco de "anchoHueco" studs,
-- o { grados, ancho } para dar a cada hueco su propio ancho.
function Props.barandillaCircular(padre, centroPos: Vector3, radio: number, lados: number, huecos, anchoHueco: number?)
	local paso = math.pi * 2 / lados
	local function quitar(i: number): boolean
		local medio = (i + 0.5) * paso
		for _, g in huecos or {} do
			local grados, ancho = g, anchoHueco or 5
			if type(g) == "table" then
				grados, ancho = g[1], g[2]
			end
			local h = math.rad(grados)
			local medioHueco = ancho / 2 / radio
			local dif = math.abs((medio - h + math.pi) % (math.pi * 2) - math.pi)
			if dif < paso / 2 + medioHueco then
				return true
			end
		end
		return false
	end
	local alto = 3.4
	local function punto(i: number): Vector3
		local a = i * paso
		return centroPos + V(math.cos(a) * radio, 0, math.sin(a) * radio)
	end
	for i = 0, lados - 1 do
		local siguiente = (i + 1) % lados
		local anterior = (i - 1) % lados
		if not quitar(i) or not quitar(anterior) then
			Util.bloque(padre, V(0.5, alto, 0.5), punto(i) + V(0, alto / 2, 0), C.maderaOscura, M.Wood)
		end
		if not quitar(i) then
			local a, b = punto(i), punto(siguiente)
			Util.barra(padre, 0.35, a + V(0, alto, 0), b + V(0, alto, 0), C.maderaOscura, M.Wood)
			Util.barra(padre, 0.25, a + V(0, alto * 0.5, 0), b + V(0, alto * 0.5, 0), C.maderaOscura, M.Wood, DECO)
		end
	end
end

-- 👹 Rocas y plantas ----------------------------------------------------------------------------

function Props.roca(padre, pos: Vector3, tam: number)
	local m = Util.modelo("Roca", padre)
	local color = C.piedra:Lerp(rgb(84, 86, 80), Util.entre(0, 1))
	for i = 1, 3 do
		local s = tam * Util.entre(0.5, 1)
		local offset = if i == 1 then V() else V(Util.entre(-tam, tam) * 0.5, 0, Util.entre(-tam, tam) * 0.5)
		Util.bloque(
			m,
			V(s, s * Util.entre(0.5, 0.8), s * Util.entre(0.7, 1.1)),
			CFrame.new(pos + offset + V(0, s * 0.2, 0)) * CFrame.Angles(Util.entre(-0.3, 0.3), Util.entre(0, 6), Util.entre(-0.3, 0.3)),
			color,
			M.Slate
		)
	end
	return m
end

function Props.matorral(padre, pos: Vector3)
	local m = Util.modelo("Matorral", padre)
	local color = Util.elegir(VERDES)
	for _ = 1, 3 do
		local s = Util.entre(2.5, 4.5)
		Util.elipsoide(m, V(s, s * 0.7, s), pos + V(Util.entre(-1.5, 1.5), s * 0.25, Util.entre(-1.5, 1.5)), color:Lerp(C.hojasSecas, Util.entre(0, 0.5)), M.LeafyGrass, DECO)
	end
	return m
end

-- Arbusto de bayas (etiqueta "Bayas"): los frutos se llaman "Fruto".
function Props.arbustoBayas(padre, pos: Vector3)
	local m = Util.modelo("ArbustoBayas", padre)
	centro(m, pos + V(0, 1.6, 0))
	Util.elipsoide(m, V(5, 3.6, 5), pos + V(0, 1.5, 0), rgb(54, 88, 50), M.LeafyGrass, DECO)
	Util.elipsoide(m, V(3.6, 3, 3.6), pos + V(1.2, 2.3, 0.8), rgb(64, 98, 56), M.LeafyGrass, DECO)
	for i = 1, 7 do
		local a = i / 7 * math.pi * 2
		local p = pos + V(math.cos(a) * 2.1, Util.entre(1.4, 3), math.sin(a) * 2.1)
		Util.bola(m, 0.55, p, rgb(112, 56, 190), M.SmoothPlastic, { Name = "Fruto", Deco = true })
	end
	Util.etiquetar(m, "Bayas")
	return m
end

-- 💧 Pozo (etiqueta "Pozo")
function Props.pozo(padre, base: Vector3)
	local m = Util.modelo("Pozo", padre)
	local piedra = rgb(120, 116, 108)
	for i = 0, 9 do
		local a = i / 10 * math.pi * 2
		Util.bloque(m, V(2.2, 2.8, 1.2), CFrame.new(base + V(math.cos(a) * 3.2, 1.4, math.sin(a) * 3.2)) * CFrame.Angles(0, -a + math.pi / 2, 0), piedra:Lerp(rgb(90, 88, 82), (i % 3) / 3), M.Cobblestone)
	end
	Util.cilindroV(m, 5.6, 0.3, base + V(0, 1.7, 0), rgb(52, 96, 110), M.Glass, { Transparency = 0.15, Deco = true, Name = "Agua" })
	for _, x in { -3.6, 3.6 } do
		Util.bloque(m, V(0.6, 7.5, 0.6), base + V(x, 3.75, 0), C.maderaOscura, M.Wood)
	end
	Util.bloque(m, V(9.4, 0.4, 3.2), CFrame.new(base + V(0, 7.7, -1.3)) * CFrame.Angles(math.rad(-34), 0, 0), C.maderaVieja, M.WoodPlanks)
	Util.bloque(m, V(9.4, 0.4, 3.2), CFrame.new(base + V(0, 7.7, 1.3)) * CFrame.Angles(math.rad(34), 0, 0), C.maderaVieja, M.WoodPlanks)
	Util.cilindro(m, 0.5, 7.6, CFrame.new(base + V(0, 5.6, 0)), C.madera, M.Wood, DECO)
	Util.barra(m, 0.15, base + V(0.8, 5.6, 0), base + V(0.8, 3, 0), C.cuerda, M.Fabric, DECO)
	Util.cilindroV(m, 1.2, 1.2, base + V(0.8, 2.6, 0), C.metal, M.CorrodedMetal, DECO)
	centro(m, base + V(0, 2, 0), V(6, 3, 6))
	Util.etiquetar(m, "Pozo")
	return m
end

-- 🚗 Coche abandonado. Si registrable = true se puede rebuscar chatarra (etiqueta "Chatarra").
function Props.coche(padre, base: Vector3, giro: number, registrable: boolean?)
	local m = Util.modelo("Coche", padre)
	local cf = CFrame.new(base) * CFrame.Angles(0, giro, 0) * CFrame.Angles(Util.entre(-0.04, 0.04), 0, Util.entre(-0.06, 0.06))
	local pintura = Util.elegir({ rgb(120, 52, 44), rgb(58, 82, 104), rgb(150, 140, 120), rgb(70, 92, 70), rgb(96, 96, 100) })
	local function en(x, y, z)
		return cf * CFrame.new(x, y, z)
	end
	Util.bloque(m, V(6.4, 1.8, 12), en(0, 1.9, 0), pintura, M.CorrodedMetal)
	Util.bloque(m, V(5.8, 2.2, 5.6), en(0, 3.9, 0.6), pintura:Lerp(rgb(60, 50, 44), 0.25), M.CorrodedMetal)
	-- Cristales rotos
	Util.bloque(m, V(5.4, 1.7, 0.2), en(0, 3.95, -2.25) * CFrame.Angles(math.rad(-20), 0, 0), rgb(30, 40, 46), M.Glass, { Transparency = 0.4, Deco = true })
	Util.bloque(m, V(0.2, 1.6, 4.6), en(2.95, 3.9, 0.6), rgb(30, 40, 46), M.Glass, { Transparency = 0.4, Deco = true })
	-- Ruedas (a veces falta una)
	local falta = Util.azar:NextInteger(0, 5)
	for i, p in { { 3.1, -3.8 }, { -3.1, -3.8 }, { 3.1, 3.8 }, { -3.1, 3.8 } } do
		if i ~= falta then
			Util.cilindro(m, 2.4, 1, en(p[1], 1.1, p[2]), rgb(28, 28, 30), M.Rubber, DECO)
		end
	end
	-- Manchas de óxido
	for _ = 1, 3 do
		Util.bloque(m, V(Util.entre(1, 2.4), 0.1, Util.entre(1, 2.4)), en(Util.entre(-2, 2), 2.85, Util.entre(-5, -2)), C.oxido, M.CorrodedMetal, DECO)
	end
	if registrable then
		centro(m, cf.Position + V(0, 2.5, 0), V(7, 3, 12))
		Util.etiquetar(m, "Chatarra")
	end
	return m
end

-- ⛺ Tienda de campaña vieja
function Props.tienda(padre, base: Vector3, giro: number, color: Color3?)
	local m = Util.modelo("Tienda", padre)
	local cf = CFrame.new(base) * CFrame.Angles(0, giro, 0)
	local lona = color or C.lona
	Util.cuna(m, V(6, 4.5, 3), cf * CFrame.new(0, 2.25, -1.5) * CFrame.Angles(0, math.pi, 0), lona, M.Fabric)
	Util.cuna(m, V(6, 4.5, 3), cf * CFrame.new(0, 2.25, 1.5), lona:Lerp(Color3.new(), 0.15), M.Fabric)
	Util.bloque(m, V(6.4, 0.2, 6.4), cf * CFrame.new(0, 0.1, 0), rgb(70, 66, 56), M.Fabric, DECO)
	return m
end

function Props.bidon(padre, pos: Vector3, color: Color3?)
	local m = Util.modelo("Bidon", padre)
	local c = color or Util.elegir({ rgb(160, 60, 40), rgb(60, 90, 140), rgb(90, 110, 60), C.oxido })
	Util.cilindroV(m, 2.4, 3.4, pos + V(0, 1.7, 0), c, M.CorrodedMetal)
	for _, y in { 0.8, 2.6 } do
		Util.cilindroV(m, 2.55, 0.2, pos + V(0, y, 0), c:Lerp(Color3.new(), 0.3), M.Metal, DECO)
	end
	return m
end

-- Barricada de tablas entre dos puntos.
function Props.barricada(padre, a: Vector3, b: Vector3)
	local m = Util.modelo("Barricada", padre)
	local largo = (b - a).Magnitude
	local cf = CFrame.lookAt((a + b) / 2, b)
	for i = 1, 3 do
		Util.bloque(m, V(0.4, 1, largo), cf * CFrame.new(0, i * 1.2, 0) * CFrame.Angles(0, 0, math.rad(Util.entre(-4, 4))), C.maderaVieja, M.WoodPlanks)
	end
	for _, z in { -largo / 2 + 0.5, largo / 2 - 0.5 } do
		Util.bloque(m, V(0.6, 4.4, 0.6), cf * CFrame.new(0, 2.2, z), C.maderaOscura, M.Wood)
	end
	Util.barra(m, 0.4, (cf * CFrame.new(0, 0.6, -largo / 2)).Position, (cf * CFrame.new(0, 4, largo / 2)).Position, C.maderaVieja, M.WoodPlanks, DECO)
	-- Sacos terreros
	for k = 0, math.floor(largo / 2.2) - 1 do
		Util.elipsoide(m, V(2.2, 1.1, 1.4), cf * CFrame.new(1.2, 0.55, -largo / 2 + 1.1 + k * 2.2), rgb(150, 136, 100), M.Fabric)
	end
	return m
end

-- 🏮 Farol en un poste (de noche luce más). base: punto del suelo donde se apoya.
function Props.farol(padre, base: Vector3, alto: number?)
	local h = alto or 6
	Util.bloque(padre, V(0.5, h, 0.5), base + V(0, h / 2, 0), C.maderaOscura, M.Wood)
	Util.bloque(padre, V(0.9, 0.3, 0.9), base + V(0, h + 0.15, 0), C.metal, M.Metal, DECO)
	local bombilla = Util.bloque(padre, V(0.7, 0.9, 0.7), base + V(0, h - 0.4, 0), rgb(255, 210, 140), M.Neon, DECO)
	bombilla.Name = "Bombilla"
	local luz = Util.luz(bombilla, C.luz, 22, 1.2, false)
	Util.etiquetar(luz, "LuzNoche")
	return bombilla
end

-- Cartel de madera con un texto.
function Props.cartel(padre, base: Vector3, mirarA: Vector3, texto: string, color: Color3?)
	local m = Util.modelo("Cartel", padre)
	local cf = CFrame.lookAt(base, V(mirarA.X, base.Y, mirarA.Z))
	Util.bloque(m, V(0.5, 5, 0.5), cf * CFrame.new(0, 2.5, 0.3), C.maderaOscura, M.Wood)
	local tabla = Util.bloque(m, V(5, 2.4, 0.3), cf * CFrame.new(0, 4.4, 0), C.maderaVieja, M.WoodPlanks)
	Util.letrero(tabla, Enum.NormalId.Front, texto, color or rgb(250, 236, 200), Enum.Font.SpecialElite)
	return m
end

-- 🧗 Cuerda para subir a una plataforma (etiqueta "Cuerda").
-- abajo: donde te pones en el suelo. arriba: donde llegas en la plataforma.
-- cuelga: punto del suelo justo debajo de donde cuelga la cuerda. alto: altura de la plataforma.
function Props.cuerda(padre, abajo: Vector3, arriba: Vector3, cuelga: Vector3, alto: number, nombre: string?)
	local m = Util.modelo("Cuerda", padre)
	local x, z = cuelga.X, cuelga.Z
	Util.cilindroV(m, 0.35, alto + 1, V(x, alto / 2, z), C.cuerda, M.Fabric, DECO)
	for y = 6, alto - 2, 6 do
		Util.bola(m, 0.7, V(x, y, z), C.cuerda:Lerp(Color3.new(), 0.15), M.Fabric, DECO)
	end
	-- Viga con polea arriba
	Util.bloque(m, V(0.8, 0.8, 0.8), V(x, alto + 1.2, z), C.metal, M.Metal, DECO)
	-- Poste con cartel abajo
	local cf = CFrame.lookAt(abajo, V(x, abajo.Y, z))
	local tabla = Util.bloque(m, V(3.2, 1.4, 0.25), cf * CFrame.new(-2.2, 3.4, 0), C.maderaVieja, M.WoodPlanks)
	Util.bloque(m, V(0.4, 3.6, 0.4), cf * CFrame.new(-2.2, 1.6, 0.2), C.maderaOscura, M.Wood)
	Util.letrero(tabla, Enum.NormalId.Back, "↑ " .. (nombre or "SUBIR"), rgb(250, 236, 200), Enum.Font.SpecialElite)
	Util.letrero(tabla, Enum.NormalId.Front, "↑ " .. (nombre or "SUBIR"), rgb(250, 236, 200), Enum.Font.SpecialElite)
	local pAbajo = Util.bloque(m, V(2, 2, 2), abajo + V(0, 2.5, 0), Color3.new(), M.SmoothPlastic, { Name = "PuntoAbajo", Transparency = 1, Deco = true })
	local pArriba = Util.bloque(m, V(2, 2, 2), arriba + V(0, 2.5, 0), Color3.new(), M.SmoothPlastic, { Name = "PuntoArriba", Transparency = 1, Deco = true })
	m.PrimaryPart = pAbajo
	m:SetAttribute("Abajo", abajo + V(0, 3, 0))
	m:SetAttribute("Arriba", arriba + V(0, 3, 0))
	m:SetAttribute("CuelgaAbajo", V(x, abajo.Y + 3, z))
	m:SetAttribute("CuelgaArriba", V(x, alto + 3, z))
	m:SetAttribute("Nombre", nombre or "la plataforma")
	Util.etiquetar(m, "Cuerda")
	return m, pArriba
end

-- 🚡 Tirolina (etiqueta "Tirolina"): un cable de "desde" a "hasta" (puntos del cable).
-- pie: donde te pones para cogerla. El cable va a unos 6 studs sobre el suelo que pisas.
function Props.tirolina(padre, desde: Vector3, hasta: Vector3, pie: Vector3, destino: string)
	local m = Util.modelo("Tirolina", padre)
	Util.barra(m, 0.2, desde, hasta, C.cable, M.Metal, DECO)
	-- Postes en los dos extremos
	for _, p in { desde, hasta } do
		Util.bloque(m, V(0.7, 7.5, 0.7), p - V(0, 2.75, 0), C.metal, M.CorrodedMetal)
		Util.bloque(m, V(1.6, 0.5, 0.5), p + V(0, 0.6, 0), C.metal, M.Metal, DECO)
	end
	-- Asa colgando al principio
	Util.barra(m, 0.15, desde + (hasta - desde).Unit * 1.5, desde + (hasta - desde).Unit * 1.5 - V(0, 2, 0), C.cable, M.Metal, DECO)
	Util.bloque(m, V(1.4, 0.3, 0.3), desde + (hasta - desde).Unit * 1.5 - V(0, 2.1, 0), rgb(200, 60, 40), M.SmoothPlastic, DECO)
	local inicio = Util.bloque(m, V(2, 2, 2), pie + V(0, 2.5, 0), Color3.new(), M.SmoothPlastic, { Name = "Inicio", Transparency = 1, Deco = true })
	m.PrimaryPart = inicio
	m:SetAttribute("Desde", desde)
	m:SetAttribute("Hasta", hasta)
	m:SetAttribute("Destino", destino)
	Util.etiquetar(m, "Tirolina")
	return m
end

-- 📦 Caja vieja en las atalayas (etiqueta "CajaVieja"): se vuelve a llenar con el tiempo.
function Props.cajaVieja(padre, pos: Vector3, giro: number)
	local m = Util.modelo("CajaVieja", padre)
	local cf = CFrame.new(pos) * CFrame.Angles(0, giro, 0)
	Util.bloque(m, V(3.6, 2.4, 2.6), cf * CFrame.new(0, 1.2, 0), C.maderaVieja, M.WoodPlanks)
	Util.bloque(m, V(3.8, 0.35, 2.8), cf * CFrame.new(0, 2.55, 0), C.maderaOscura, M.Wood, { Name = "Tapa" })
	for _, x in { -1.4, 1.4 } do
		Util.bloque(m, V(0.3, 2.5, 2.7), cf * CFrame.new(x, 1.25, 0), C.metal, M.CorrodedMetal, DECO)
	end
	centro(m, cf.Position + V(0, 1.5, 0), V(4, 3, 3))
	Util.etiquetar(m, "CajaVieja")
	return m
end

-- 🪂 Caja de la lluvia de suministros (sin padre: la coloca el sistema de la lluvia).
-- El pivote del modelo es el centro de la caja. Dentro tiene "Paracaidas" y "Estela".
function Props.cajaSuministros(tipo: string, color: Color3, colorHumo: Color3): Model
	local m = Instance.new("Model")
	m.Name = "Caja" .. tipo
	local cuerpo = Util.bloque(m, V(4.4, 3.2, 4.4), CFrame.new(), color, if tipo == "Dorada" then M.Metal else M.WoodPlanks, { Name = "Cuerpo" })
	m.PrimaryPart = cuerpo
	local borde = if tipo == "Militar" then rgb(50, 60, 40) elseif tipo == "Dorada" then rgb(255, 236, 150) else rgb(90, 66, 44)
	Util.bloque(m, V(4.6, 0.4, 4.6), CFrame.new(0, 1.7, 0), borde, M.Metal, { Name = "Tapa" })
	for _, x in { -1.6, 1.6 } do
		Util.bloque(m, V(0.35, 3.3, 4.5), CFrame.new(x, 0, 0), borde, M.Metal, DECO)
	end
	-- Marca en los lados
	local marca = if tipo == "Dorada" then "★" elseif tipo == "Militar" then "✚" else "⬆"
	for _, cara in { Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right } do
		Util.letrero(cuerpo, cara, marca, if tipo == "Dorada" then rgb(120, 80, 20) else rgb(240, 230, 200), Enum.Font.GothamBlack)
	end
	if tipo == "Dorada" then
		Util.luz(cuerpo, rgb(255, 220, 120), 16, 1.5)
	end

	-- Paracaídas
	local para = Instance.new("Model")
	para.Name = "Paracaidas"
	para.Parent = m
	local colorTela = if tipo == "Militar" then rgb(112, 128, 88) elseif tipo == "Dorada" then rgb(255, 214, 90) else rgb(236, 236, 230)
	local franja = if tipo == "Comun" then rgb(232, 110, 50) else colorTela:Lerp(Color3.new(), 0.25)
	Util.elipsoide(para, V(15, 5, 15), CFrame.new(0, 12.5, 0), colorTela, M.Fabric, DECO)
	Util.elipsoide(para, V(15.4, 2.2, 6), CFrame.new(0, 13.6, 0), franja, M.Fabric, DECO)
	for _, p in { V(6, 11, 6), V(-6, 11, 6), V(6, 11, -6), V(-6, 11, -6) } do
		Util.barra(para, 0.1, p, V(p.X * 0.3, 1.7, p.Z * 0.3), rgb(220, 220, 210), M.Fabric, DECO)
	end

	-- Estela de humo mientras cae
	local adjunto = Instance.new("Attachment")
	adjunto.Name = "Estela"
	adjunto.Parent = cuerpo
	Util.particulas(adjunto, {
		Texture = "rbxasset://textures/particles/smoke_main.dds",
		Color = ColorSequence.new(colorHumo),
		Transparency = NumberSequence.new(0.4, 1),
		Size = NumberSequence.new(2, 5),
		Lifetime = NumberRange.new(1.5, 2.5),
		Rate = 14,
		Speed = NumberRange.new(1, 2),
		SpreadAngle = Vector2.new(25, 25),
		LightEmission = 0.3,
	})
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
		end
	end
	return m
end

return Props
