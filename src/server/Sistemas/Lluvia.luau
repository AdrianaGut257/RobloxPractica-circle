-- 🪂 La lluvia de suministros.
-- Cada 10 minutos (Config.LLUVIA.INTERVALO) caen cajas con paracaídas por todo el anillo:
-- en el suelo (las mejores, pero ahí están los enemigos), en las atalayas, en las copas de los
-- árboles gigantes, en el Nexo y siempre una dorada en el Nido. Al aterrizar sueltan humo de
-- bengala para que se vean de lejos. Se abren con E y lo que hay dentro va a tu mochila.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Estadisticas = require(script.Parent.Estadisticas)
local Estado = require(script.Parent.Estado)
local Inventario = require(script.Parent.Inventario)
local Props = require(script.Parent.Parent.Mundo.Props)
local Util = require(script.Parent.Parent.Mundo.Util)

local Lluvia = {}

local CFG = Config.LLUVIA
local PREFIJO = "C_"
local V = Vector3.new
local rgb = Color3.fromRGB

local carpeta: Folder
local puntos: { [string]: { BasePart } } = {}
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude

type Cayendo = { modelo: Model, x: number, z: number, y: number, final: number, giro: number, t: number, tipo: string, zona: string }
local cayendo: { Cayendo } = {}
local conexion: RBXScriptConnection? = nil
local sirena: BasePart? = nil
local sirenaActiva = false

local GRUPO_TIPOS = { Suelo = "Suelo", Torre = "Altura", Copa = "Altura", Nexo = "Centro", Nido = "Centro" }

local function elegirPeso(tabla: { [string]: number }): string?
	local total = 0
	for _, peso in tabla do
		total += peso
	end
	if total <= 0 then
		return nil
	end
	local r = math.random() * total
	for clave, peso in tabla do
		r -= peso
		if r <= 0 then
			return clave
		end
	end
	return next(tabla)
end

local function contar()
	Estado.set("CajasRestantes", #CollectionService:GetTagged("CajaSuministros") + #cayendo)
end

local function actualizarFiltro()
	local ignorar: { Instance } = { carpeta }
	for _, nombre in { "Enemigos", "Recogibles" } do
		local f = workspace:FindFirstChild(nombre)
		if f then
			table.insert(ignorar, f)
		end
	end
	for _, j in Players:GetPlayers() do
		if j.Character then
			table.insert(ignorar, j.Character)
		end
	end
	params.FilterDescendantsInstances = ignorar
end

-- Busca dónde aterrizaría una caja que cae sobre este punto (suelo o plataforma pisable).
local function destino(punto: BasePart): Vector3?
	local radio = punto:GetAttribute("Radio") or 0
	for _ = 1, 6 do
		local a = math.random() * math.pi * 2
		local r = math.random() * radio
		local x = punto.Position.X + math.cos(a) * r
		local z = punto.Position.Z + math.sin(a) * r
		local res = workspace:Raycast(V(x, CFG.ALTURA + 30, z), V(0, -(CFG.ALTURA + 80), 0), params)
		if res then
			local inst = res.Instance
			local esSuelo = inst == workspace.Terrain and res.Position.Y < 8 and res.Material ~= Enum.Material.Water
			if esSuelo or inst:GetAttribute("Pisable") then
				return res.Position
			end
		end
	end
	return nil
end

-- 📦 Abrir una caja -----------------------------------------------------------------------------

local function contenidoDe(modelo: Model): { [string]: number }
	local c = {}
	for _, id in Config.ORDEN_OBJETOS do
		local n = modelo:GetAttribute(PREFIJO .. id) or 0
		if n > 0 then
			c[id] = n
		end
	end
	return c
end

local function quitarCaja(modelo: Model)
	if not modelo.Parent then
		return
	end
	CollectionService:RemoveTag(modelo, "CajaSuministros")
	Util.desvanecer(modelo, 0.8)
	task.defer(contar)
end

local function abrir(jugador: Player, modelo: Model)
	if not modelo.Parent then
		return
	end
	local info = Config.CAJAS[modelo:GetAttribute("Tipo") or "Comun"]
	local contenido = contenidoDe(modelo)
	if Inventario.espacio(jugador) <= 0 then
		Estado.notificar(jugador, "🎒 ¡Mochila llena! Vuelve a tu base a guardar.", rgb(255, 190, 120))
		return
	end
	local primera = not modelo:GetAttribute("Abierta")
	local metido = Inventario.darContenido(jugador, contenido)
	if Config.total(metido) > 0 and not modelo:GetAttribute("Saqueada_" .. jugador.UserId) then
		modelo:SetAttribute("Saqueada_" .. jugador.UserId, true)
		Estadisticas.sumar(jugador, "Cajas")
	end
	for _, id in Config.ORDEN_OBJETOS do
		modelo:SetAttribute(PREFIJO .. id, contenido[id] or 0)
	end
	modelo:SetAttribute("Abierta", true)
	local texto = info.icono .. " " .. info.nombre .. ":  " .. Config.textoContenido(metido)
	if Config.total(contenido) > 0 then
		texto ..= "   (queda algo dentro: no te cabe)"
	end
	Estado.notificar(jugador, texto, rgb(255, 220, 140))
	if primera and modelo:GetAttribute("Tipo") == "Dorada" then
		Estado.notificar(nil, "⭐ " .. jugador.DisplayName .. " ha abierto una CAJA DORADA", rgb(255, 214, 90))
	end
	if Config.total(contenido) <= 0 then
		quitarCaja(modelo)
	else
		local prompt = (modelo.PrimaryPart :: BasePart):FindFirstChildOfClass("ProximityPrompt")
		if prompt then
			prompt.ObjectText = info.icono .. " " .. info.nombre .. " (queda " .. Config.textoContenido(contenido, "") .. ")"
		end
	end
end

-- 🪂 Aterrizar -------------------------------------------------------------------------------------

local function aterrizar(c: Cayendo)
	local modelo = c.modelo
	local info = Config.CAJAS[c.tipo]
	local cuerpo = modelo.PrimaryPart :: BasePart
	modelo:PivotTo(CFrame.new(c.x, c.final, c.z) * CFrame.Angles(0, c.giro, 0))
	local para = modelo:FindFirstChild("Paracaidas")
	if para then
		Util.desvanecer(para, 1.5)
	end
	local estela = cuerpo:FindFirstChild("Estela")
	local emisor = estela and estela:FindFirstChildOfClass("ParticleEmitter")
	if emisor then
		emisor.Enabled = false
	end
	-- Polvo al tocar el suelo
	local polvo = Instance.new("ParticleEmitter")
	polvo.Texture = "rbxasset://textures/particles/smoke_main.dds"
	polvo.Color = ColorSequence.new(rgb(150, 140, 120))
	polvo.Transparency = NumberSequence.new(0.4, 1)
	polvo.Size = NumberSequence.new(2, 5)
	polvo.Lifetime = NumberRange.new(0.8, 1.4)
	polvo.Speed = NumberRange.new(6, 10)
	polvo.SpreadAngle = Vector2.new(80, 80)
	polvo.Rate = 0
	polvo.Parent = cuerpo
	polvo:Emit(24)
	-- Columna de humo de bengala (se ve desde lejos)
	local bengala = Instance.new("Attachment")
	bengala.Name = "Bengala"
	bengala.Position = V(0, 1.8, 0)
	bengala.Parent = cuerpo
	local humo = Util.particulas(bengala, {
		Texture = "rbxasset://textures/particles/smoke_main.dds",
		Color = ColorSequence.new(info.humo),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) }),
		Size = NumberSequence.new(1.5, 6),
		Lifetime = NumberRange.new(5, 7),
		Rate = 10,
		Speed = NumberRange.new(9, 12),
		SpreadAngle = Vector2.new(6, 6),
		Acceleration = V(0, 1, 0),
		LightEmission = 0.4,
	})
	local luz = Util.luz(cuerpo, info.humo, 18, 2)
	task.delay(90, function()
		if humo.Parent then
			humo.Enabled = false
		end
		if luz.Parent then
			luz.Brightness = 0.6
		end
	end)
	-- Icono que se ve desde lejos
	local bb = Instance.new("BillboardGui")
	bb.Name = "Marca"
	bb.Size = UDim2.fromOffset(38, 38)
	bb.StudsOffset = V(0, 4, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 700
	bb.LightInfluence = 0
	bb.Parent = cuerpo
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundColor3 = rgb(20, 20, 18)
	t.BackgroundTransparency = 0.35
	t.TextScaled = true
	t.Font = Enum.Font.GothamBold
	t.Text = info.icono
	t.Parent = bb
	local esquina = Instance.new("UICorner")
	esquina.CornerRadius = UDim.new(0.5, 0)
	esquina.Parent = t
	local trazo = Instance.new("UIStroke")
	trazo.Color = info.humo
	trazo.Thickness = 2
	trazo.Parent = t

	local prompt = Util.prompt(cuerpo, "Abrir", info.icono .. " " .. info.nombre, CFG.TIEMPO_ABRIR, 9)
	prompt.Triggered:Connect(function(jugador)
		abrir(jugador, modelo)
	end)
	modelo:SetAttribute("Zona", c.zona)
	CollectionService:AddTag(modelo, "CajaSuministros")
	Estado.emitir("CajaAterriza", modelo:GetPivot().Position, c.zona, modelo)
	contar()
	task.delay(CFG.DURACION_CAJA, function()
		quitarCaja(modelo)
	end)
end

local function paso(dt: number)
	for i = #cayendo, 1, -1 do
		local c = cayendo[i]
		c.t += dt
		c.y -= CFG.VELOCIDAD * dt
		if c.y <= c.final or not c.modelo.Parent then
			table.remove(cayendo, i)
			if c.modelo.Parent then
				aterrizar(c)
			end
		else
			local balanceo = CFrame.Angles(math.sin(c.t * 1.3) * 0.08, c.giro + c.t * 0.25, math.cos(c.t * 1.1) * 0.08)
			c.modelo:PivotTo(CFrame.new(c.x + math.sin(c.t * 0.7) * 1.5, c.y, c.z + math.cos(c.t * 0.6) * 1.5) * balanceo)
		end
	end
	if #cayendo == 0 and conexion then
		conexion:Disconnect()
		conexion = nil
	end
end

-- Suelta una caja sobre un punto. Devuelve true si ha encontrado dónde caer.
local function soltarCaja(punto: BasePart, zona: string, tipoForzado: string?): boolean
	local suelo = destino(punto)
	if not suelo then
		return false
	end
	local tipo = tipoForzado or elegirPeso(CFG.TIPOS[GRUPO_TIPOS[zona] or "Suelo"]) or "Comun"
	local info = Config.CAJAS[tipo]
	local modelo = Props.cajaSuministros(tipo, info.color, info.humo)
	modelo:SetAttribute("Tipo", tipo)
	local contenido = Config.tirarBotin(tipo)
	if Config.total(contenido) == 0 then
		contenido = { Lata = 1, Agua = 1 }
	end
	for id, n in contenido do
		modelo:SetAttribute(PREFIJO .. id, n)
	end
	local c: Cayendo = {
		modelo = modelo,
		x = suelo.X,
		z = suelo.Z,
		y = CFG.ALTURA + math.random() * 30,
		final = suelo.Y + 1.6,
		giro = math.random() * math.pi * 2,
		t = math.random() * 5,
		tipo = tipo,
		zona = zona,
	}
	modelo:PivotTo(CFrame.new(c.x, c.y, c.z))
	modelo.Parent = carpeta
	table.insert(cayendo, c)
	if not conexion then
		conexion = RunService.Heartbeat:Connect(paso)
	end
	contar()
	return true
end

-- 🚨 La sirena del Nido gira mientras se acerca o dura la lluvia
local function encenderSirena(activa: boolean)
	sirenaActiva = activa
	local s = sirena
	if not s then
		return
	end
	local foco = s:FindFirstChildOfClass("SpotLight")
	if foco then
		foco.Brightness = if activa then 8 else 0
	end
	if activa then
		task.spawn(function()
			while sirenaActiva and s.Parent do
				s.CFrame *= CFrame.Angles(0, math.rad(12), 0)
				task.wait(0.05)
			end
		end)
	end
end

-- Elige un punto de una zona que no se haya usado en esta lluvia.
local function elegirPunto(zona: string, usados: { [BasePart]: boolean }): BasePart?
	local lista = puntos[zona]
	if not lista or #lista == 0 then
		return nil
	end
	local libres = {}
	for _, p in lista do
		if not usados[p] then
			table.insert(libres, p)
		end
	end
	if #libres == 0 then
		return nil
	end
	return libres[math.random(1, #libres)]
end

local function lluvia()
	actualizarFiltro()
	local total = math.min(CFG.CAJAS_MAXIMO, CFG.CAJAS_BASE + CFG.CAJAS_POR_JUGADOR * #Players:GetPlayers())
	Estado.set("LluviaActiva", true)
	Estado.set("LluviasHoy", (Estado.get("LluviasHoy") or 0) + 1)
	Estado.anunciar("🪂 ¡LLUVIA DE SUMINISTROS!", "Caen cajas por todo el anillo. Las del suelo son las mejores... ¡y vigila tu base!")
	Estado.emitir("LluviaEmpieza")
	encenderSirena(true)

	local usados: { [BasePart]: boolean } = {}
	local intervalo = CFG.DURACION_CAIDA / math.max(total, 1)
	-- Primero, la dorada del Nido
	local nido = elegirPunto("Nido", usados)
	if nido then
		usados[nido] = true
		soltarCaja(nido, "Nido", "Dorada")
	end
	local soltadas = 0
	local intentos = 0
	while soltadas < total and intentos < total * 4 do
		intentos += 1
		local zona = elegirPeso(CFG.ZONAS) or "Suelo"
		local punto = elegirPunto(zona, usados) or elegirPunto("Suelo", usados)
		if punto then
			usados[punto] = true
			if soltarCaja(punto, punto:GetAttribute("Zona") or zona) then
				soltadas += 1
				task.wait(intervalo)
			end
		end
	end

	-- Espera a que aterricen todas
	local inicio = os.clock()
	while #cayendo > 0 and os.clock() - inicio < 60 do
		task.wait(0.5)
	end
	Estado.set("LluviaActiva", false)
	encenderSirena(false)
	Estado.emitir("LluviaTermina")
	Estado.notificar(nil, string.format("🪂 Han caído %d cajas. Las que nadie abra desaparecerán en %d minutos.", soltadas + (if nido then 1 else 0), CFG.DURACION_CAJA // 60), rgb(255, 220, 140))
end

function Lluvia.iniciar()
	carpeta = Instance.new("Folder")
	carpeta.Name = "Suministros"
	carpeta.Parent = workspace

	for _, p in CollectionService:GetTagged("PuntoCaida") do
		local zona = p:GetAttribute("Zona") or "Suelo"
		puntos[zona] = puntos[zona] or {}
		table.insert(puntos[zona], p :: BasePart)
	end
	sirena = CollectionService:GetTagged("Sirena")[1]
	Estado.set("LluviaActiva", false)
	Estado.set("CajasRestantes", 0)

	task.spawn(function()
		local siguiente = CFG.PRIMERA
		Estado.set("IntervaloLluvia", CFG.PRIMERA)
		while true do
			while siguiente > 0 do
				Estado.set("ProximaLluvia", siguiente)
				if siguiente == CFG.AVISO then
					Estado.anunciar("⚠️ LLUVIA EN 1 MINUTO", "Se oyen los aviones... Prepara la mochila.")
					encenderSirena(true)
				elseif siguiente == 10 then
					Estado.notificar(nil, "🪂 ¡10 segundos! Mirad al cielo...", rgb(255, 220, 140))
				end
				task.wait(1)
				siguiente -= 1
			end
			Estado.set("ProximaLluvia", 0)
			task.spawn(lluvia)
			siguiente = CFG.INTERVALO
			Estado.set("IntervaloLluvia", CFG.INTERVALO)
		end
	end)
end

return Lluvia
