-- Recursos del suelo: pozos, charcas, la cisterna del Nexo, arbustos de bayas, coches para
-- rebuscar chatarra, cajas viejas de las atalayas, objetos tirados y la mochila de quien cae.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Estado = require(script.Parent.Estado)
local Inventario = require(script.Parent.Inventario)
local Util = require(script.Parent.Parent.Mundo.Util)

local Recursos = {}

local CFG = Config.RECURSOS
local OBJETOS = Config.OBJETOS
local rgb = Color3.fromRGB
local V = Vector3.new
local carpeta: Folder

local function lleno(jugador: Player)
	Estado.notificar(jugador, "🎒 ¡Mochila llena! Vuelve a tu base a guardar.", rgb(255, 190, 120))
end

-- Da un contenido y avisa de lo que ha entrado. Devuelve true si ha entrado algo.
local function darYAvisar(jugador: Player, contenido, titulo: string): boolean
	local metido = Inventario.darContenido(jugador, contenido)
	if Config.total(metido) > 0 then
		local texto = titulo .. "  " .. Config.textoContenido(metido)
		if Config.total(contenido) > 0 then
			texto ..= "   (no te cabe todo)"
		end
		Estado.notificar(jugador, texto)
		return true
	end
	lleno(jugador)
	return false
end

-- Punto del suelo (o plataforma) justo debajo de "pos".
local function sueloBajo(pos: Vector3): Vector3
	local ignorar = { carpeta }
	for _, j in game:GetService("Players"):GetPlayers() do
		if j.Character then
			table.insert(ignorar, j.Character)
		end
	end
	local enemigos = workspace:FindFirstChild("Enemigos")
	if enemigos then
		table.insert(ignorar, enemigos)
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignorar
	local res = workspace:Raycast(pos + V(0, 2, 0), V(0, -80, 0), params)
	return if res then res.Position else pos
end
Recursos.sueloBajo = sueloBajo

-- Icono flotante encima de un objeto.
local function icono(parte: BasePart, texto: string, distancia: number)
	local bb = Instance.new("BillboardGui")
	bb.Name = "Icono"
	bb.Size = UDim2.fromOffset(46, 46)
	bb.StudsOffset = V(0, 2.2, 0)
	bb.MaxDistance = distancia
	bb.LightInfluence = 0
	bb.Parent = parte
	local t = Instance.new("TextLabel")
	t.Name = "Texto"
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.TextScaled = true
	t.Font = Enum.Font.GothamBold
	t.Text = texto
	t.Parent = bb
	return t
end

-- 🎁 Objeto tirado en el suelo ----------------------------------------------------------------------
function Recursos.soltar(id: string, pos: Vector3, cantidad: number?)
	local datos = OBJETOS[id]
	if not datos then
		return
	end
	local n = cantidad or 1
	pos = sueloBajo(pos)
	local parte = Util.bloque(carpeta, V(1.4, 1.4, 1.4), CFrame.new(pos + V(0, 0.7, 0)) * CFrame.Angles(0, math.random() * 3, 0), datos.color, Enum.Material.SmoothPlastic, {
		Name = "Suelto_" .. id,
		CanCollide = false,
	})
	local etiqueta = icono(parte, datos.icono, 60)
	local prompt = Util.prompt(parte, "Recoger", string.format("%s %s x%d", datos.icono, datos.nombre, n), 0, 9)
	prompt.Triggered:Connect(function(jugador)
		if not parte.Parent then
			return
		end
		local entra = Inventario.dar(jugador, id, n)
		if entra <= 0 then
			lleno(jugador)
			return
		end
		n -= entra
		Estado.notificar(jugador, string.format("+%d %s %s", entra, datos.icono, datos.nombre))
		if n <= 0 then
			parte:Destroy()
		else
			prompt.ObjectText = string.format("%s %s x%d", datos.icono, datos.nombre, n)
			etiqueta.Text = datos.icono
		end
	end)
	task.delay(CFG.DURACION_SUELTO, function()
		if parte.Parent then
			parte:Destroy()
		end
	end)
	return parte
end

-- Suelta un contenido entero repartido alrededor de un punto.
function Recursos.soltarContenido(contenido, pos: Vector3)
	local i = 0
	for id, n in contenido do
		i += 1
		local a = i * 2.1
		Recursos.soltar(id, pos + V(math.cos(a) * 2.5, 0, math.sin(a) * 2.5), n)
	end
end

-- 🎒 La mochila de alguien que ha caído
function Recursos.bolsa(pos: Vector3, contenido, nombre: string)
	pos = sueloBajo(pos)
	local m = Util.modelo("MochilaCaida", carpeta)
	local cuerpo = Util.bloque(m, V(2, 2.6, 1.3), CFrame.new(pos + V(0, 1.1, 0)) * CFrame.Angles(math.rad(-75), math.random() * 3, 0), rgb(122, 86, 52), Enum.Material.Fabric, { CanCollide = false })
	Util.bloque(m, V(1.6, 1, 0.5), cuerpo.CFrame * CFrame.new(0, -0.4, -0.85), rgb(96, 66, 40), Enum.Material.Fabric, Util.DECO)
	m.PrimaryPart = cuerpo
	local etiqueta = icono(cuerpo, "🎒", 120)
	etiqueta.Parent.Size = UDim2.fromOffset(54, 54)
	local luz = Util.luz(cuerpo, rgb(255, 220, 150), 10, 1)
	local prompt = Util.prompt(cuerpo, "Saquear", "🎒 Mochila de " .. nombre, 1, 9)
	local function quedan(): number
		return Config.total(contenido)
	end
	prompt.Triggered:Connect(function(jugador)
		if not m.Parent then
			return
		end
		darYAvisar(jugador, contenido, "🎒 Saqueas la mochila de " .. nombre .. ":")
		if quedan() <= 0 then
			luz.Enabled = false
			m:Destroy()
		end
	end)
	task.delay(CFG.DURACION_BOLSA, function()
		if m.Parent then
			m:Destroy()
		end
	end)
	return m
end

-- 💧 Agua -----------------------------------------------------------------------------------------

local function beber(jugador: Player, cantidad: number, texto: string)
	local sed = jugador:GetAttribute("Sed") or 0
	if sed >= Config.SUPERVIVENCIA.MAXIMO - 1 then
		Estado.notificar(jugador, "No tienes sed ahora mismo.")
		return false
	end
	Inventario.beber(jugador, cantidad)
	Estado.notificar(jugador, texto .. "  +" .. cantidad .. " 💧", rgb(130, 200, 255))
	return true
end

local function iniciarAgua()
	for _, pozo in CollectionService:GetTagged("Pozo") do
		local centro = pozo.PrimaryPart
		if not centro then
			continue
		end
		local beberP = Util.prompt(centro, "Beber", "💧 Pozo", 0.6, 9)
		local llenar = Util.prompt(centro, "Llenar botella", "💧 Pozo", 1.2, 9)
		llenar.KeyboardKeyCode = Enum.KeyCode.R
		llenar.GamepadKeyCode = Enum.KeyCode.ButtonY
		local botellas = CFG.POZO_BOTELLAS
		local function mostrar()
			llenar.ObjectText = string.format("💧 Pozo (%d %s)", botellas, if botellas == 1 then "botella" else "botellas")
			llenar.Enabled = botellas > 0
		end
		mostrar()
		beberP.Triggered:Connect(function(jugador)
			beber(jugador, CFG.POZO_BEBER, "💧 Agua fresca del pozo")
		end)
		llenar.Triggered:Connect(function(jugador)
			if botellas <= 0 then
				return
			end
			if Inventario.dar(jugador, "Agua", 1) <= 0 then
				lleno(jugador)
				return
			end
			botellas -= 1
			mostrar()
			Estado.notificar(jugador, "+1 💧 Botella de agua")
		end)
		task.spawn(function()
			while pozo.Parent do
				task.wait(CFG.POZO_RECARGA)
				if botellas < CFG.POZO_BOTELLAS then
					botellas += 1
					mostrar()
				end
			end
		end)
	end

	for _, orilla in CollectionService:GetTagged("Charca") do
		local p = Util.prompt(orilla, "Beber", "🌊 Charca (agua sucia)", 0.8, 9)
		p.Triggered:Connect(function(jugador)
			if beber(jugador, CFG.CHARCA_BEBER, "🌊 Agua de charca...") and math.random() < 0.25 then
				local hum = Inventario.humanoide(jugador)
				if hum then
					hum:TakeDamage(6)
					Estado.notificar(jugador, "🤢 Puaj, estaba sucia. -6 ❤️", rgb(180, 220, 120))
				end
			end
		end)
	end

	for _, cisterna in CollectionService:GetTagged("Cisterna") do
		local centro = cisterna.PrimaryPart
		if centro then
			local p = Util.prompt(centro, "Beber", "💧 Cisterna del Nexo", 0.6, 9)
			p.Triggered:Connect(function(jugador)
				beber(jugador, CFG.CISTERNA_BEBER, "💧 Agua de la cisterna")
			end)
		end
	end
end

-- 🍇 Bayas ----------------------------------------------------------------------------------------

local function iniciarBayas()
	for _, arbusto in CollectionService:GetTagged("Bayas") do
		local centro = arbusto.PrimaryPart
		if not centro then
			continue
		end
		local frutos = {}
		for _, d in arbusto:GetChildren() do
			if d.Name == "Fruto" and d:IsA("BasePart") then
				table.insert(frutos, d)
			end
		end
		local prompt = Util.prompt(centro, "Coger bayas", "🍇 Arbusto", 0.4, 9)
		local quedan = CFG.BAYAS_POR_ARBUSTO
		local function mostrar()
			local visibles = math.ceil(#frutos * quedan / CFG.BAYAS_POR_ARBUSTO)
			for i, f in frutos do
				f.Transparency = if i <= visibles then 0 else 1
			end
			prompt.Enabled = quedan > 0
			prompt.ObjectText = string.format("🍇 Arbusto (%d)", quedan)
		end
		mostrar()
		prompt.Triggered:Connect(function(jugador)
			if quedan <= 0 then
				return
			end
			if Inventario.dar(jugador, "Bayas", 1) <= 0 then
				lleno(jugador)
				return
			end
			quedan -= 1
			Estado.notificar(jugador, "+1 🍇 Bayas")
			mostrar()
		end)
		task.spawn(function()
			while arbusto.Parent do
				task.wait(CFG.BAYA_RECRECE)
				if quedan < CFG.BAYAS_POR_ARBUSTO then
					quedan += 1
					mostrar()
				end
			end
		end)
	end
end

-- ⚙️ Coches y 📦 cajas viejas: se registran y tardan en volver a tener algo --------------------------

local function registrable(etiqueta: string, accion: string, nombre: string, duracion: number, recarga: number, tabla: string)
	for _, modelo in CollectionService:GetTagged(etiqueta) do
		local centro = modelo.PrimaryPart
		if not centro then
			continue
		end
		local prompt = Util.prompt(centro, accion, nombre, duracion, 10)
		local tapa = modelo:FindFirstChild("Tapa") :: BasePart?
		local tapaCF = tapa and tapa.CFrame
		prompt.Triggered:Connect(function(jugador)
			if not prompt.Enabled then
				return
			end
			if Inventario.espacio(jugador) <= 0 then
				lleno(jugador)
				return
			end
			local botin = Config.tirarBotin(tabla)
			if Config.total(botin) == 0 then
				botin = { Chatarra = 1 }
			end
			darYAvisar(jugador, botin, nombre .. ":")
			prompt.Enabled = false
			prompt.ObjectText = nombre .. " (vacío)"
			if tapa and tapaCF then
				tapa.CFrame = tapaCF * CFrame.new(0, 0.6, 0.9) * CFrame.Angles(math.rad(-50), 0, 0)
			end
			task.delay(recarga, function()
				prompt.Enabled = true
				prompt.ObjectText = nombre
				if tapa and tapaCF then
					TweenService:Create(tapa, TweenInfo.new(0.4), { CFrame = tapaCF }):Play()
				end
			end)
		end)
	end
end

function Recursos.iniciar()
	carpeta = Instance.new("Folder")
	carpeta.Name = "Recogibles"
	carpeta.Parent = workspace
	Recursos.carpeta = carpeta

	iniciarAgua()
	iniciarBayas()
	registrable("Chatarra", "Rebuscar", "⚙️ Coche abandonado", 2, CFG.DESGUACE_RECARGA, "Desguace")
	registrable("CajaVieja", "Abrir", "📦 Caja vieja", 1, CFG.CAJA_VIEJA_RECARGA, "Vieja")

	-- Al caer, la mochila se queda en el suelo
	Estado.escuchar("JugadorMuerto", function(jugador: Player, pos: Vector3, contenido)
		Recursos.bolsa(pos, contenido, jugador.DisplayName)
	end)
end

return Recursos
