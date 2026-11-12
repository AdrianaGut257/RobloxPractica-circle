-- Las construcciones grandes del anillo:
--   · El Árbol Madre en el centro, con el Nexo (plataforma a 50 de altura), la escalera de caracol
--     y el Nido en lo alto (donde caen las mejores cajas).
--   · Las 8 bases: torres de vigas con una plataforma de 32 x 32, cabaña, almacén y mesa de mejoras.
--   · Las pasarelas que unen cada base con el Nexo (como los radios de una rueda).
--   · Las atalayas (torres vigía) de dentro y de fuera, y las tirolinas.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Props = require(script.Parent.Props)
local Util = require(script.Parent.Util)

local Estructuras = {}

local M = Enum.Material
local rgb = Util.rgb
local DECO = Util.DECO
local V = Vector3.new
local C = Props.COLORES
local MAPA = Config.MAPA
local polar = Config.polar

local VIGA = rgb(68, 58, 50)

-- Ángulos (en grados) donde hay tirolina desde el Nexo hasta una atalaya de dentro.
-- En 22.5 y 202.5 no hay: ahí están las cuerdas para subir al Nexo desde el suelo.
Estructuras.TIROLINAS_NEXO = { 67.5, 112.5, 157.5, 247.5, 292.5, 337.5 }
Estructuras.CUERDAS_NEXO = { 22.5, 202.5 }

-- Escalera de caracol del Árbol Madre
local ESCALERA = { inicio = 250, paso = 10, sube = 1.2, peldanos = 38, radioDentro = 24.5, radioFuera = 30.5 }

-- 🧱 Torre de vigas -----------------------------------------------------------------------------

-- Barandilla de un lado de una plataforma cuadrada, dejando huecos.
-- lado: "frente" (-Z), "atras" (+Z), "izquierda" (-X), "derecha" (+X).
-- huecos: { { posición a lo largo del lado, ancho } }
local function barandillaLado(padre, cf: CFrame, medio: number, y: number, lado: string, huecos, color: Color3)
	local borde = medio - 0.3
	local desde, hasta = -borde, borde
	if lado == "izquierda" or lado == "derecha" then
		desde, hasta = -borde + 0.6, borde - 0.6 -- para no repetir los postes de las esquinas
	end
	local function punto(t: number): Vector3
		if lado == "frente" then
			return (cf * CFrame.new(t, y, -borde)).Position
		elseif lado == "atras" then
			return (cf * CFrame.new(t, y, borde)).Position
		elseif lado == "izquierda" then
			return (cf * CFrame.new(-borde, y, t)).Position
		end
		return (cf * CFrame.new(borde, y, t)).Position
	end
	local cortes = {}
	for _, hueco in huecos or {} do
		table.insert(cortes, { hueco[1] - hueco[2] / 2, hueco[1] + hueco[2] / 2 })
	end
	table.sort(cortes, function(a, b)
		return a[1] < b[1]
	end)
	local t = desde
	for _, c in cortes do
		local fin = math.min(c[1], hasta)
		if fin - t > 0.8 then
			Util.barandilla(padre, punto(t), punto(fin), color, M.Wood)
		end
		t = math.max(t, c[2])
	end
	if hasta - t > 0.8 then
		Util.barandilla(padre, punto(t), punto(hasta), color, M.Wood)
	end
end

-- Torre de 4 vigas con travesaños y una plataforma cuadrada arriba.
-- cf: CFrame en el suelo (centro de la torre). El frente es su -Z.
-- opciones: { viga, suelo, huecos = { frente = {...}, atras = {...}, ... }, techo }
function Estructuras.torre(padre, cf: CFrame, alto: number, ancho: number, opciones)
	opciones = opciones or {}
	local medio = ancho / 2
	local viga = opciones.viga or VIGA
	local e = medio - 1.2
	for _, p in { { e, e }, { -e, e }, { e, -e }, { -e, -e } } do
		Util.bloque(padre, V(2, alto - 1.2, 2), cf * CFrame.new(p[1], (alto - 1.2) / 2, p[2]), viga, M.Wood)
	end
	-- Travesaños cada 12 studs: horizontales y una diagonal por cara
	local caras = {
		{ V(e, 0, e), V(-e, 0, e) },
		{ V(-e, 0, e), V(-e, 0, -e) },
		{ V(-e, 0, -e), V(e, 0, -e) },
		{ V(e, 0, -e), V(e, 0, e) },
	}
	local niveles = math.max(1, math.floor((alto - 4) / 12))
	for n = 1, niveles do
		local y1 = (n - 1) * 12 + 2
		local y2 = math.min(n * 12 + 2, alto - 2)
		for k, cara in caras do
			local a = (cf * CFrame.new(cara[1])).Position
			local b = (cf * CFrame.new(cara[2])).Position
			Util.barra(padre, 0.8, a + V(0, y2, 0), b + V(0, y2, 0), viga, M.Wood)
			if (n + k) % 2 == 0 then
				Util.barra(padre, 0.6, a + V(0, y1, 0), b + V(0, y2, 0), viga, M.Wood, DECO)
			else
				Util.barra(padre, 0.6, b + V(0, y1, 0), a + V(0, y2, 0), viga, M.Wood, DECO)
			end
		end
	end
	-- Plataforma
	local suelo = Util.bloque(padre, V(ancho, 1.2, ancho), cf * CFrame.new(0, alto - 0.6, 0), opciones.suelo or C.madera, M.WoodPlanks, { Name = "Suelo" })
	Util.pisable(suelo)
	Util.bloque(padre, V(ancho + 0.6, 0.6, ancho + 0.6), cf * CFrame.new(0, alto - 1.5, 0), C.maderaOscura, M.Wood, DECO)
	local huecos = opciones.huecos or {}
	for _, lado in { "frente", "atras", "izquierda", "derecha" } do
		barandillaLado(padre, cf, medio, alto, lado, huecos[lado], C.maderaOscura)
	end
	if opciones.techo then
		-- Tejadillo solo sobre la mitad de atrás (delante pueden caer cajas de la lluvia)
		for _, p in { { medio - 1, medio - 1 }, { -(medio - 1), medio - 1 }, { medio - 1, 0.3 }, { -(medio - 1), 0.3 } } do
			Util.bloque(padre, V(0.5, 7.5, 0.5), cf * CFrame.new(p[1], alto + 3.75, p[2]), C.maderaOscura, M.Wood)
		end
		Util.bloque(padre, V(ancho + 1, 0.4, medio + 0.8), cf * CFrame.new(0, alto + 7.8, medio / 2) * CFrame.Angles(math.rad(-8), 0, 0), rgb(112, 94, 82), M.CorrodedMetal)
	end
	return suelo
end

-- 🏠 Base de jugador -----------------------------------------------------------------------------
-- Coordenadas locales: el -Z mira al centro del mapa (por ahí llega la pasarela);
-- la cabaña está atrás a la izquierda, la cuerda atrás a la derecha y la tirolina a la izquierda.
function Estructuras.base(padre, i: number)
	local angulo = Config.anguloBase(i)
	local suelo0 = polar(MAPA.RADIO_BASES, angulo, 0)
	local cf = CFrame.lookAt(suelo0, V(0, 0, 0))
	local H = MAPA.MEDIO_BASE
	local Y = MAPA.ALTURA_BASES
	local m = Util.modelo("Base" .. i, padre)
	m:SetAttribute("Indice", i)
	m:SetAttribute("Centro", suelo0 + V(0, Y, 0))
	local function en(x: number, y: number, z: number): CFrame
		return cf * CFrame.new(x, y, z)
	end
	local function p(x: number, y: number, z: number): Vector3
		return (cf * CFrame.new(x, y, z)).Position
	end
	local libre = Config.COLOR_LIBRE

	Estructuras.torre(m, cf, Y, H * 2, {
		huecos = {
			frente = { { 0, 7 } }, -- pasarela al Nexo
			atras = { { 10, 4.5 } }, -- cuerda
			izquierda = { { -7, 4.5 } }, -- tirolina
		},
	})

	-- Cabaña ---------------------------------------------------------------------------------
	local madera = C.maderaVieja
	local function muro(size: Vector3, x: number, y: number, z: number)
		return Util.bloque(m, size, en(x, y, z), madera, M.WoodPlanks)
	end
	muro(V(14.4, 9, 0.8), -6.5, Y + 4.5, 14.1) -- fondo
	muro(V(0.8, 9, 13), -14.1, Y + 4.5, 8) -- izquierda
	-- derecha, con ventana
	muro(V(0.8, 3.5, 13), 1.1, Y + 1.75, 8)
	muro(V(0.8, 2.5, 13), 1.1, Y + 7.75, 8)
	muro(V(0.8, 3, 4), 1.1, Y + 5, 3.5)
	muro(V(0.8, 3, 4.5), 1.1, Y + 5, 12.25)
	Util.bloque(m, V(0.2, 3, 4.5), en(1.1, Y + 5, 7.75), rgb(60, 80, 90), M.Glass, { Transparency = 0.6 })
	-- frente, con puerta
	muro(V(4.7, 9, 0.8), -11.35, Y + 4.5, 1.9)
	muro(V(4.7, 9, 0.8), -1.65, Y + 4.5, 1.9)
	muro(V(5, 2, 0.8), -6.5, Y + 8, 1.9)
	-- Chapas de metal oxidado clavadas por fuera
	Util.bloque(m, V(0.2, 4, 5), en(-14.6, Y + 3, 5), C.oxido, M.CorrodedMetal, DECO)
	Util.bloque(m, V(4, 3.5, 0.2), en(-11.5, Y + 2.5, 14.6), C.metal, M.CorrodedMetal, DECO)
	-- Tejado de chapa
	Util.bloque(m, V(17.6, 0.6, 14.6), en(-6.5, Y + 9.5, 8) * CFrame.Angles(math.rad(5), 0, 0), rgb(110, 96, 86), M.CorrodedMetal)
	Util.bloque(m, V(17.8, 0.4, 0.6), en(-6.5, Y + 10.15, 0.75), libre, M.SmoothPlastic, { Name = "Color", Deco = true })
	Util.bloque(m, V(15.2, 0.8, 0.2), en(-6.5, Y + 8.3, 1.4), libre, M.SmoothPlastic, { Name = "Color", Deco = true })

	-- Cama
	Util.bloque(m, V(4, 1, 7.5), en(-11.6, Y + 0.5, 8), C.maderaOscura, M.Wood)
	Util.bloque(m, V(3.6, 0.6, 7), en(-11.6, Y + 1.3, 8), rgb(200, 196, 184), M.Fabric)
	Util.bloque(m, V(3.7, 0.3, 4.5), en(-11.6, Y + 1.75, 9.2), libre, M.Fabric, { Name = "Color" })
	Util.bloque(m, V(3, 0.6, 1.5), en(-11.6, Y + 1.9, 5.2), rgb(236, 232, 222), M.Fabric)
	-- Estantería con latas
	for k = 0, 2 do
		local y = Y + 2 + k * 2
		Util.bloque(m, V(3.2, 0.2, 1.4), en(-1.6, y, 13), C.madera, M.Wood)
		for j = -1, 1 do
			Util.cilindroV(m, 0.6, 0.9, p(-1.6 + j * 0.9, y + 0.55, 13), Util.elegir({ rgb(200, 80, 60), rgb(90, 140, 200), rgb(200, 190, 80) }), M.Metal, DECO)
		end
	end
	-- Bombilla del techo
	local bombilla = Util.bloque(m, V(0.6, 0.6, 0.6), en(-6.5, Y + 8.4, 8), rgb(255, 214, 150), M.Neon, DECO)
	Util.luz(bombilla, C.luz, 18, 1.1, true)

	-- 📦 Almacén (dos botones: "Abrir" para el dueño y "Robar" para los demás)
	local almacen = Util.modelo("Almacen", m)
	local cofre = Util.bloque(almacen, V(6, 3, 3), en(-6.5, Y + 1.5, 12), rgb(70, 82, 72), M.DiamondPlate, { Name = "Cofre" })
	almacen.PrimaryPart = cofre
	Util.bloque(almacen, V(6.3, 0.5, 3.3), en(-6.5, Y + 3.25, 12), rgb(50, 56, 52), M.Metal)
	Util.bloque(almacen, V(6.1, 0.5, 0.2), en(-6.5, Y + 2.3, 10.45), libre, M.SmoothPlastic, { Name = "Color", Deco = true })
	Util.letrero(cofre, Enum.NormalId.Front, "ALMACÉN", rgb(240, 236, 220), Enum.Font.GothamBlack)
	local candado = Util.modelo("CandadoVisual", m)
	Util.bloque(candado, V(0.9, 1, 0.4), en(-6.5, Y + 2.9, 10.25), rgb(220, 190, 80), M.Metal, DECO)
	Util.bloque(candado, V(0.6, 0.6, 0.15), en(-6.5, Y + 3.5, 10.25), rgb(180, 180, 180), M.Metal, DECO)
	local trampa = Util.modelo("TrampaVisual", m)
	for _, x in { -10.2, -2.8 } do
		Util.cilindroV(trampa, 0.8, 3.2, p(x, Y + 1.6, 11.5), rgb(230, 190, 40), M.Metal, DECO)
		local punta = Util.bola(trampa, 0.9, p(x, Y + 3.5, 11.5), rgb(120, 200, 255), M.Neon, DECO)
		Util.luz(punta, rgb(120, 200, 255), 8, 1.5)
	end

	-- Punto de aparición (dentro de la cabaña)
	Util.parte({
		Clase = "SpawnLocation",
		Parent = m,
		Name = "Aparicion",
		Size = V(4, 0.2, 4),
		CFrame = en(-6.5, Y + 0.1, 6),
		Transparency = 1,
		Deco = true,
		Neutral = true,
		Duration = 6,
		Enabled = true,
	})

	-- 🔨 Mesa de mejoras (delante, a la derecha)
	local mesa = Util.modelo("Mesa", m)
	local cfM = en(9, Y, -11.5) * CFrame.Angles(0, math.pi, 0)
	Util.bloque(mesa, V(7, 0.5, 3), cfM * CFrame.new(0, 3, 0), C.madera, M.WoodPlanks)
	for _, q in { { 3.1, 1.1 }, { -3.1, 1.1 }, { 3.1, -1.1 }, { -3.1, -1.1 } } do
		Util.bloque(mesa, V(0.5, 2.8, 0.5), cfM * CFrame.new(q[1], 1.4, q[2]), C.maderaOscura, M.Wood)
	end
	Util.bloque(mesa, V(1, 0.8, 0.8), cfM * CFrame.new(2.6, 3.65, -0.6), C.metal, M.Metal, DECO)
	Util.bloque(mesa, V(2.4, 0.15, 0.6), cfM * CFrame.new(-1.6, 3.33, -0.4) * CFrame.Angles(0, 0.4, 0), rgb(180, 180, 184), M.Metal, DECO)
	Util.bloque(mesa, V(0.3, 0.3, 1.6), cfM * CFrame.new(0.4, 3.4, 0.2), C.maderaOscura, M.Wood, DECO)
	local panel = Util.bloque(mesa, V(7, 4, 0.3), cfM * CFrame.new(0, 5.5, 1.4), C.maderaVieja, M.WoodPlanks)
	Util.letrero(panel, Enum.NormalId.Front, "🔨 MEJORAS", rgb(255, 220, 150), Enum.Font.GothamBlack)
	Props.centro(mesa, (cfM * CFrame.new(0, 3.5, 0)).Position, V(7, 2, 3))

	-- 🌧️ Colector de lluvia (se ve al comprarlo)
	local colector = Util.modelo("Colector", m)
	Util.cilindroV(colector, 3, 4, p(12.5, Y + 2, -2), rgb(60, 110, 170), M.SmoothPlastic)
	Util.cilindroV(colector, 5.2, 0.4, p(12.5, Y + 4.2, -2), rgb(190, 190, 194), M.Metal)
	Util.cilindroV(colector, 4.8, 0.1, p(12.5, Y + 4.45, -2), rgb(70, 130, 170), M.Glass, { Transparency = 0.2, Deco = true })
	for _, z in { -4.6, 0.6 } do
		Util.bloque(colector, V(0.3, 7, 0.3), en(14.8, Y + 3.5, z), C.maderaOscura, M.Wood)
	end
	Util.bloque(colector, V(1.4, 0.1, 6), en(14.2, Y + 6.8, -2) * CFrame.Angles(0, 0, math.rad(25)), rgb(120, 140, 160), M.Fabric, DECO)

	-- 🌱 Huerto colgante (se ve al comprarlo)
	local huerto = Util.modelo("Huerto", m)
	for _, z in { 5, 9.5 } do
		Util.bloque(huerto, V(3, 1.4, 4), en(12.8, Y + 0.7, z), C.madera, M.WoodPlanks)
		Util.bloque(huerto, V(2.6, 0.2, 3.6), en(12.8, Y + 1.45, z), rgb(80, 60, 44), M.Ground, DECO)
		for j = -1, 1 do
			Util.elipsoide(huerto, V(1.4, 1.3, 1.4), p(12.8, Y + 2.1, z + j * 1.1), rgb(80, 150, 70), M.LeafyGrass, DECO)
			Util.bola(huerto, 0.4, p(12.4, Y + 2.4, z + j * 1.1), rgb(112, 56, 190), M.SmoothPlastic, DECO)
		end
	end

	-- 🏮 Faroles
	for _, q in { { 14.8, -14.8 }, { -14.8, -14.8 }, { 14.8, 14.8 } } do
		Props.farol(m, p(q[1], Y, q[2]), 5.5)
	end

	-- 🚩 Bandera en el tejado
	Util.bloque(m, V(0.4, 11, 0.4), en(-13.9, Y + 14.5, 13.9), C.metal, M.Metal)
	Util.bloque(m, V(0.15, 3, 5), en(-13.9, Y + 18.4, 11.3), libre, M.Fabric, { Name = "Bandera" })

	-- Arco de entrada con el cartel del dueño
	for _, x in { -4, 4 } do
		Util.bloque(m, V(0.8, 9, 0.8), en(x, Y + 4.5, -15.7), C.maderaOscura, M.Wood)
	end
	Util.bloque(m, V(8.8, 1, 0.8), en(0, Y + 9.2, -15.7), libre, M.SmoothPlastic, { Name = "Color" })
	local cartel = Util.bloque(m, V(7.2, 1.8, 0.3), en(0, Y + 7.7, -15.7), rgb(34, 32, 30), M.SmoothPlastic, { Name = "Cartel" })
	Util.letrero(cartel, Enum.NormalId.Front, "BASE LIBRE", rgb(240, 236, 220), Enum.Font.GothamBlack)
	Util.letrero(cartel, Enum.NormalId.Back, "BASE LIBRE", rgb(240, 236, 220), Enum.Font.GothamBlack)

	-- Rótulo flotante con el nombre del dueño y su reserva (se ve de lejos)
	local rotulo = Util.bloque(m, V(1, 1, 1), en(-6.5, Y + 17, 8), Color3.new(), M.SmoothPlastic, { Name = "Rotulo", Transparency = 1, Deco = true })
	local bb = Instance.new("BillboardGui")
	bb.Name = "Rotulo"
	bb.Size = UDim2.new(18, 0, 4.6, 0)
	bb.LightInfluence = 0
	bb.MaxDistance = 420
	bb.Parent = rotulo
	local fondo = Instance.new("Frame")
	fondo.Name = "Fondo"
	fondo.Size = UDim2.fromScale(1, 1)
	fondo.BackgroundColor3 = rgb(18, 20, 18)
	fondo.BackgroundTransparency = 0.25
	fondo.Parent = bb
	local esquinas = Instance.new("UICorner")
	esquinas.CornerRadius = UDim.new(0.2, 0)
	esquinas.Parent = fondo
	local trazo = Instance.new("UIStroke")
	trazo.Name = "Borde"
	trazo.Color = libre
	trazo.Thickness = 3
	trazo.Parent = fondo
	for _, info in { { "Nombre", 0.06, 0.52, Enum.Font.GothamBlack }, { "Reserva", 0.56, 0.36, Enum.Font.GothamBold } } do
		local t = Instance.new("TextLabel")
		t.Name = info[1]
		t.BackgroundTransparency = 1
		t.Position = UDim2.fromScale(0.05, info[2])
		t.Size = UDim2.fromScale(0.9, info[3])
		t.Font = info[4]
		t.TextScaled = true
		t.TextColor3 = rgb(240, 236, 220)
		t.Text = if info[1] == "Nombre" then "BASE LIBRE" else ""
		t.Parent = fondo
	end

	-- 🧗 Cuerda (atrás) y 🚡 tirolina (izquierda) hasta la atalaya de fuera
	Props.cuerda(m, p(10, 0, 21.5), p(10, Y, 12.8), p(10, 0, 16.9), Y, "BASE")
	local angAtalaya = angulo + 360 / MAPA.BASES / 2
	local atalaya = polar(MAPA.RADIO_ATALAYAS_FUERA, angAtalaya, 0)
	local desde = p(-15.2, Y + 6, -7)
	local haciaBase = (V(desde.X, 0, desde.Z) - atalaya).Unit
	local hasta = atalaya + haciaBase * 4.6 + V(0, MAPA.ALTURA_ATALAYAS_FUERA + 6, 0)
	Props.tirolina(m, desde, hasta, p(-12.5, Y, -7), "la atalaya")

	Util.etiquetar(m, "Base")
	return m
end

-- 🌉 Pasarela del Nexo a una base -------------------------------------------------------------------
function Estructuras.pasarela(padre, angulo: number)
	local m = Util.modelo("Pasarela", padre)
	local Y = MAPA.ALTURA_BASES
	local r1 = MAPA.RADIO_NEXO -- empieza justo en el borde del Nexo...
	local r2 = MAPA.RADIO_BASES - MAPA.MEDIO_BASE -- ...y acaba en el borde de la base (sin solaparse)
	local a = polar(r1, angulo, Y)
	local b = polar(r2, angulo, Y)
	local cf = CFrame.lookAt(a, b) -- el -Z va de a hacia b
	local largo = (b - a).Magnitude
	local ancho = 7
	-- Tablones
	local paso = 3
	local n = math.floor(largo / paso)
	for k = 0, n - 1 do
		local tablon = Util.bloque(m, V(ancho, 0.8, paso - 0.25), cf * CFrame.new(0, -0.4, -(k + 0.5) * paso), C.madera:Lerp(C.maderaVieja, Util.entre(0, 1)), M.Wood)
		Util.pisable(tablon)
	end
	local resto = largo - n * paso
	if resto > 0.3 then
		Util.pisable(Util.bloque(m, V(ancho, 0.8, resto), cf * CFrame.new(0, -0.4, -(n * paso + resto / 2)), C.madera, M.Wood))
	end
	-- Vigas de debajo
	for _, x in { -(ancho / 2 - 0.6), ancho / 2 - 0.6 } do
		Util.bloque(m, V(0.9, 0.9, largo), cf * CFrame.new(x, -1.25, -largo / 2), C.maderaOscura, M.Wood)
	end
	-- Barandillas de cuerda
	for _, x in { -(ancho / 2 - 0.25), ancho / 2 - 0.25 } do
		Util.barandilla(m, (cf * CFrame.new(x, 0, 0)).Position, (cf * CFrame.new(x, 0, -largo)).Position, C.maderaOscura, M.Wood)
	end
	-- Apoyos: vigas altas hasta el suelo cada ~30 studs
	for d = 30, largo - 15, 30 do
		local izq = (cf * CFrame.new(-(ancho / 2 + 0.6), 0, -d)).Position
		local der = (cf * CFrame.new(ancho / 2 + 0.6, 0, -d)).Position
		for _, q in { izq, der } do
			Util.bloque(m, V(1.6, Y + 1, 1.6), V(q.X, (Y - 1) / 2, q.Z), VIGA, M.Wood)
		end
		Util.barra(m, 0.9, V(izq.X, Y - 1.6, izq.Z), V(der.X, Y - 1.6, der.Z), VIGA, M.Wood)
		for _, y in { 12, 30 } do
			Util.barra(m, 0.6, V(izq.X, y, izq.Z), V(der.X, y + 12, der.Z), VIGA, M.Wood, DECO)
			Util.barra(m, 0.6, V(der.X, y, der.Z), V(izq.X, y + 12, izq.Z), VIGA, M.Wood, DECO)
		end
	end
	return m
end

-- 🗼 Atalaya ----------------------------------------------------------------------------------------
-- Torre vigía con una caja vieja arriba y una cuerda para subir (mira al centro del mapa).
function Estructuras.atalaya(padre, pos: Vector3, alto: number, nombre: string)
	local m = Util.modelo("Atalaya", padre)
	local cf = CFrame.lookAt(pos, V(0, 0, 0))
	local function p(x: number, y: number, z: number): Vector3
		return (cf * CFrame.new(x, y, z)).Position
	end
	Estructuras.torre(m, cf, alto, 12, { huecos = { atras = { { 0, 4 } } }, techo = true })
	Props.cuerda(m, p(0, 0, 10.5), p(0, alto, 3.2), p(0, 0, 6.9), alto, nombre)
	Props.cajaVieja(m, p(-3, alto, 3), 0.3)
	Props.marcador(p(-2.8, alto + 1, -1.8), "PuntoCaida", { Zona = "Torre", Radio = 0 })
	local bombilla = Util.bloque(m, V(0.6, 0.6, 0.6), p(0, alto + 7.2, 0), rgb(255, 214, 150), M.Neon, DECO)
	Util.luz(bombilla, C.luz, 20, 1, false)
	return m, cf
end

-- 🌳 El Árbol Madre, el Nexo y el Nido ----------------------------------------------------------------
function Estructuras.nexo(padre)
	local m = Util.modelo("Nexo", padre)
	local A = MAPA.ALTURA_NEXO
	local R = MAPA.RADIO_NEXO
	local N = MAPA.ALTURA_NIDO
	local ALTO = 150

	-- Tronco: de 28 a 14 de diámetro
	local tramos = 6
	for i = 1, tramos do
		local d = 28 - (i - 1) * (14 / (tramos - 1))
		local h = ALTO / tramos
		local t = Util.cilindroV(m, d, h + 0.4, V(0, (i - 0.5) * h, 0), C.troncoGigante:Lerp(C.troncoOscuro, i * 0.06), M.Wood)
		t.Name = "Tronco"
	end
	-- Raíces enormes
	for i = 0, 9 do
		local a = i / 10 * math.pi * 2
		Util.barra(m, 6, V(math.cos(a) * 11, 10, math.sin(a) * 11), V(math.cos(a) * 34, -0.8, math.sin(a) * 34), C.troncoGigante, M.Wood).Name = "Raiz"
	end
	-- Musgo y setas que brillan entre las raíces
	for i = 1, 14 do
		local a = Util.entre(0, math.pi * 2)
		local r = Util.entre(15, 30)
		local pie = V(math.cos(a) * r, 0, math.sin(a) * r)
		Util.cilindroV(m, 0.4, 1.4, pie + V(0, 0.7, 0), rgb(220, 214, 200), M.SmoothPlastic, DECO)
		local sombrero = Util.elipsoide(m, V(1.6, 0.7, 1.6), pie + V(0, 1.5, 0), rgb(120, 230, 210), M.Neon, DECO)
		if i % 3 == 0 then
			Util.luz(sombrero, rgb(120, 230, 210), 10, 0.8)
		end
	end
	for _ = 1, 10 do
		local a = Util.entre(0, math.pi * 2)
		local y = Util.entre(4, 120)
		local d = 28 - (math.floor(y / 25)) * 2.8
		Util.bloque(m, V(Util.entre(4, 7), Util.entre(3, 6), 0.6), CFrame.new(V(math.cos(a) * (d / 2 + 0.1), y, math.sin(a) * (d / 2 + 0.1))) * CFrame.Angles(0, -a + math.pi / 2, 0), rgb(70, 96, 56), M.Grass, DECO)
	end
	-- Ramas y copa
	for i = 1, 9 do
		local a = i / 9 * math.pi * 2 + Util.entre(-0.2, 0.2)
		local y = Util.entre(108, 138)
		local desde = V(0, y, 0)
		local hasta = V(math.cos(a) * Util.entre(30, 42), y + Util.entre(6, 16), math.sin(a) * Util.entre(30, 42))
		Util.barra(m, 3.5, desde, hasta, C.troncoGigante, M.Wood, DECO)
		Util.elipsoide(m, V(Util.entre(30, 40), Util.entre(14, 20), Util.entre(30, 40)), hasta + V(0, 4, 0), rgb(58, 84, 52):Lerp(C.hojasSecas, Util.entre(0, 0.3)), M.LeafyGrass, DECO)
	end
	Util.elipsoide(m, V(60, 30, 60), V(0, ALTO + 6, 0), rgb(56, 80, 50), M.LeafyGrass, DECO)

	-- Plataforma del Nexo
	local disco = Util.cilindroV(m, R * 2, 1.4, V(0, A - 0.7, 0), C.madera, M.WoodPlanks, { Name = "SueloNexo" })
	Util.pisable(disco)
	Util.cilindroV(m, R * 2 + 1, 0.6, V(0, A - 1.6, 0), C.maderaOscura, M.Wood, DECO)
	for i = 0, 15 do
		local a = i / 16 * math.pi * 2
		Util.barra(m, 1, V(math.cos(a) * 13, A - 16, math.sin(a) * 13), V(math.cos(a) * (R - 2), A - 1.4, math.sin(a) * (R - 2)), C.maderaOscura, M.Wood)
	end
	local huecos = {}
	for k = 0, MAPA.BASES - 1 do
		table.insert(huecos, { k * 45, 7 })
	end
	for _, g in Estructuras.CUERDAS_NEXO do
		table.insert(huecos, { g, 3 })
	end
	Props.barandillaCircular(m, V(0, A, 0), R - 0.6, 48, huecos)
	for k = 0, 7 do
		Props.farol(m, polar(R - 1.8, k * 45 + 11.25, A), 6)
	end

	-- Cartel del Nexo y tablones con las bases más ricas
	for _, g in { 67.5, 247.5 } do
		local pos = polar(11.9, g, A + 6)
		local fuera = polar(20, g, A + 6)
		local tablon = Util.bloque(m, V(14, 9, 0.6), CFrame.lookAt(pos, fuera), rgb(46, 40, 34), M.WoodPlanks, { Name = "Tablon" })
		Util.etiquetar(tablon, "Tablon")
		Util.bloque(m, V(14.8, 0.6, 1), CFrame.lookAt(pos, fuera) * CFrame.new(0, 4.8, 0), C.maderaOscura, M.Wood, DECO)
	end

	-- Cisterna (para beber en el Nexo)
	local cisterna = Util.modelo("Cisterna", m)
	local posC = polar(19.5, 112.5, A)
	Util.cilindroV(cisterna, 5, 5, posC + V(0, 2.5, 0), rgb(110, 120, 128), M.CorrodedMetal)
	Util.cilindroV(cisterna, 5.3, 0.4, posC + V(0, 3.8, 0), rgb(80, 86, 92), M.Metal, DECO)
	Util.cilindroV(cisterna, 4.6, 0.2, posC + V(0, 5.05, 0), rgb(60, 110, 130), M.Glass, { Transparency = 0.2, Deco = true })
	Util.barra(cisterna, 0.4, posC + polar(2.4, 292.5, 1.5), posC + polar(3.4, 292.5, 1.5), C.metal, M.Metal, DECO)
	Props.centro(cisterna, posC + V(0, 2.5, 0), V(5.5, 5, 5.5))
	Util.etiquetar(cisterna, "Cisterna")

	-- Escalera de caracol hasta el Nido
	local E = ESCALERA
	local rMedio = (E.radioDentro + E.radioFuera) / 2
	for k = 1, E.peldanos do
		local g = E.inicio + k * E.paso
		local y = A + k * E.sube
		local pos = polar(rMedio, g, y - 0.6)
		local peldano = Util.bloque(m, V(E.radioFuera - E.radioDentro, 1.2, 5.2), CFrame.lookAt(pos, V(0, pos.Y, 0)) * CFrame.Angles(0, math.pi / 2, 0), C.madera:Lerp(C.maderaVieja, (k % 3) / 3), M.WoodPlanks)
		peldano.Name = "Peldano"
		if k >= 8 and k % 2 == 0 then
			Util.barra(m, 0.7, polar(E.radioDentro, g, y - 1.4), polar(11, g, y - 6), C.maderaOscura, M.Wood, DECO)
		end
		if k % 3 == 0 then
			Util.bloque(m, V(0.35, 3.2, 0.35), polar(E.radioFuera - 0.3, g, y + 1.6), C.maderaOscura, M.Wood, DECO)
		end
	end

	-- 🐦 El Nido
	local nido = Util.cilindroV(m, 48, 1.2, V(0, N - 0.6, 0), C.madera, M.WoodPlanks, { Name = "SueloNido" })
	Util.pisable(nido)
	for i = 0, 7 do
		local a = i / 8 * math.pi * 2
		Util.barra(m, 0.9, V(math.cos(a) * 9.5, N - 12, math.sin(a) * 9.5), V(math.cos(a) * 22, N - 1.2, math.sin(a) * 22), C.maderaOscura, M.Wood)
	end
	local llegada = E.inicio + E.peldanos * E.paso
	Props.barandillaCircular(m, V(0, N, 0), 23.4, 32, { { llegada % 360, 8 } })
	Props.farol(m, polar(21, llegada + 40, N), 6)
	Props.farol(m, polar(21, llegada + 200, N), 6)
	-- Sirena que gira cuando llega la lluvia
	local poste = polar(20, llegada + 120, N)
	Util.bloque(m, V(0.6, 9, 0.6), poste + V(0, 4.5, 0), C.metal, M.Metal)
	local sirena = Util.bloque(m, V(1.6, 1.2, 1.6), poste + V(0, 9.6, 0), rgb(255, 70, 50), M.Neon, { Name = "Sirena", Deco = true })
	local foco = Instance.new("SpotLight")
	foco.Color = rgb(255, 80, 60)
	foco.Range = 60
	foco.Angle = 50
	foco.Brightness = 0
	foco.Face = Enum.NormalId.Front
	foco.Parent = sirena
	Util.etiquetar(sirena, "Sirena")
	Props.marcador(polar(15, llegada + 90, N + 1), "PuntoCaida", { Zona = "Nido", Radio = 0 })
	Props.marcador(polar(15, llegada + 250, N + 1), "PuntoCaida", { Zona = "Nido", Radio = 0 })

	-- Puntos de caída en el Nexo
	for _, g in { 33.75, 123.75, 213.75, 303.75 } do
		Props.marcador(polar(32.6, g, A + 1), "PuntoCaida", { Zona = "Nexo", Radio = 0 })
	end

	-- Punto de aparición para quien se quede sin base (si el servidor está lleno)
	Util.parte({
		Clase = "SpawnLocation",
		Parent = m,
		Name = "AparicionNexo",
		Size = V(4, 0.2, 4),
		Position = polar(32.8, 168.75, A + 0.1),
		Transparency = 1,
		Deco = true,
		Neutral = true,
		Duration = 6,
		Enabled = true,
	})

	-- Cuerdas desde el suelo
	for _, g in Estructuras.CUERDAS_NEXO do
		Props.cuerda(m, polar(42, g, 0), polar(32.5, g, A), polar(R + 0.8, g, 0), A, "NEXO")
	end

	-- Tirolinas hasta las atalayas de dentro
	for _, g in Estructuras.TIROLINAS_NEXO do
		Props.tirolina(
			m,
			polar(R - 1.2, g, A + 6),
			polar(MAPA.RADIO_ATALAYAS_DENTRO - 4.6, g, MAPA.ALTURA_ATALAYAS_DENTRO + 6),
			polar(R - 4, g, A),
			"la atalaya"
		)
	end
	return m
end

return Estructuras
