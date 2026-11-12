-- Las bases de los jugadores: a cada uno se le da una al entrar.
--   · Almacén: lo que guardas aquí suma a tu Reserva 💰 (el marcador). Otros te lo pueden ROBAR.
--   · Mesa de mejoras: mochilas más grandes, armas, candado, trampa, colector de lluvia, huerto...
--   · Si alguien entra en tu base o te roba, te llega un aviso.
-- También se encarga de hacer aparecer a los jugadores (en su base) y de reaparecer al caer.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Datos = require(script.Parent.Datos)
local Estadisticas = require(script.Parent.Estadisticas)
local Estado = require(script.Parent.Estado)
local Inventario = require(script.Parent.Inventario)
local Util = require(script.Parent.Parent.Mundo.Util)

local Bases = {}

local PREFIJO = "A_"
local ROBO = Config.ROBO
local ORDEN = Config.ORDEN_OBJETOS
local OBJETOS = Config.OBJETOS
local rgb = Color3.fromRGB
local REAPARICION = 6

type InfoBase = {
	modelo: Model,
	indice: number,
	dueno: Player?,
	cofre: BasePart,
	mesa: BasePart?,
	promptAbrir: ProximityPrompt,
	promptRobar: ProximityPrompt,
	produccion: { [string]: number },
	intrusos: { [Player]: number },
}

local bases: { InfoBase } = {}
local basePorJugador: { [Player]: InfoBase } = {}
local esperando: { Player } = {}
local aparicionNexo: SpawnLocation? = nil
local ultimaMudanza: { [Player]: number } = {}

function Bases.de(jugador: Player): InfoBase?
	return basePorJugador[jugador]
end

-- 📦 Almacén ---------------------------------------------------------------------------------

local function cantidadAlmacen(info: InfoBase, id: string): number
	return info.modelo:GetAttribute(PREFIJO .. id) or 0
end

function Bases.almacen(info: InfoBase): { [string]: number }
	local c = {}
	for _, id in ORDEN do
		local n = cantidadAlmacen(info, id)
		if n > 0 then
			c[id] = n
		end
	end
	return c
end

local function rotulo(info: InfoBase): Frame?
	local parte = info.modelo:FindFirstChild("Rotulo")
	local bb = parte and parte:FindFirstChild("Rotulo")
	return bb and bb:FindFirstChild("Fondo") :: Frame?
end

-- El rótulo flotante de la base: nombre del dueño, reserva y los objetos que tiene guardados.
-- (La línea de objetos se añade aquí para que también salga en mapas copiados antes de tenerla.)
local function prepararRotulo(info: InfoBase)
	local fondo = rotulo(info)
	if not fondo or fondo:FindFirstChild("Objetos") then
		return
	end
	local bb = fondo.Parent :: BillboardGui
	bb.Size = UDim2.new(18, 0, 6.2, 0)
	local nombre = fondo:FindFirstChild("Nombre") :: TextLabel?
	local reserva = fondo:FindFirstChild("Reserva") :: TextLabel?
	if nombre then
		nombre.Position = UDim2.fromScale(0.05, 0.05)
		nombre.Size = UDim2.fromScale(0.9, 0.38)
	end
	if reserva then
		reserva.Position = UDim2.fromScale(0.05, 0.44)
		reserva.Size = UDim2.fromScale(0.9, 0.26)
	end
	local objetos = Instance.new("TextLabel")
	objetos.Name = "Objetos"
	objetos.BackgroundTransparency = 1
	objetos.Position = UDim2.fromScale(0.05, 0.72)
	objetos.Size = UDim2.fromScale(0.9, 0.22)
	objetos.Font = Enum.Font.GothamBold
	objetos.TextScaled = true
	objetos.TextColor3 = rgb(220, 214, 196)
	objetos.Text = ""
	objetos.Parent = fondo
end

local function textoObjetos(almacen: { [string]: number }): string
	local partes = {}
	for _, id in ORDEN do
		local n = almacen[id]
		if n and n > 0 then
			table.insert(partes, OBJETOS[id].icono .. " " .. n)
		end
	end
	return if #partes > 0 then table.concat(partes, "   ") else "almacén vacío"
end

local function actualizarReserva(info: InfoBase)
	local almacen = Bases.almacen(info)
	local valor = Config.valor(almacen)
	info.modelo:SetAttribute("Reserva", valor)
	local fondo = rotulo(info)
	if fondo then
		(fondo:FindFirstChild("Reserva") :: TextLabel).Text = if info.dueno then "💰 " .. valor else ""
		local objetos = fondo:FindFirstChild("Objetos") :: TextLabel?
		if objetos then
			objetos.Text = if info.dueno then textoObjetos(almacen) else ""
		end
	end
	local dueno = info.dueno
	if dueno then
		dueno:SetAttribute("Reserva", valor)
		local reserva = Datos.stats(dueno)
		reserva.Value = valor
	end
end

function Bases.darAlmacen(info: InfoBase, id: string, n: number)
	if not OBJETOS[id] or n <= 0 then
		return
	end
	info.modelo:SetAttribute(PREFIJO .. id, cantidadAlmacen(info, id) + n)
	actualizarReserva(info)
end

function Bases.quitarAlmacen(info: InfoBase, id: string, n: number): number
	local hay = cantidadAlmacen(info, id)
	local quita = math.min(hay, n)
	if quita > 0 then
		info.modelo:SetAttribute(PREFIJO .. id, hay - quita)
		actualizarReserva(info)
	end
	return quita
end

-- ¿Está el jugador en la plataforma de su base (o de esta base)?
local function enLaBase(jugador: Player, info: InfoBase, margen: number?): boolean
	local raiz = Inventario.raiz(jugador)
	if not raiz then
		return false
	end
	local centro = info.modelo:GetAttribute("Centro") :: Vector3
	local d = Util.dist2D(raiz.Position, centro)
	return d <= Config.MAPA.MEDIO_BASE + (margen or 2) and math.abs(raiz.Position.Y - centro.Y) < 14
end

local function cercaDe(jugador: Player, parte: BasePart?, distancia: number): boolean
	local raiz = Inventario.raiz(jugador)
	return raiz ~= nil and parte ~= nil and (raiz.Position - parte.Position).Magnitude <= distancia
end

-- Para comer o beber directamente de tu almacén (desde la ventana del almacén).
Inventario.almacenCerca = function(jugador: Player)
	local info = basePorJugador[jugador]
	if not info or not enLaBase(jugador, info) then
		return nil
	end
	return {
		cantidad = function(id: string): number
			return cantidadAlmacen(info, id)
		end,
		quitar = function(id: string, n: number)
			Bases.quitarAlmacen(info, id, n)
		end,
	}
end

-- 💾 Lo que se guarda: almacén + mochila, mejoras y robos
local function instantanea(jugador: Player)
	local info = basePorJugador[jugador]
	if not info then
		return nil
	end
	local todo = Bases.almacen(info)
	for id, n in Inventario.contenido(jugador) do
		todo[id] = (todo[id] or 0) + n
	end
	local mejoras = {}
	for _, m in Config.MEJORAS do
		if not m.repetible and jugador:GetAttribute("Mejora_" .. m.id) then
			mejoras[m.id] = true
		end
	end
	local _, robos = Datos.stats(jugador)
	return { almacen = todo, mejoras = mejoras, robos = robos.Value, estadisticas = Estadisticas.exportar(jugador) }
end
Datos.proveedor = instantanea

-- 🎨 Aspecto de la base ----------------------------------------------------------------------

local function textoCartel(info: InfoBase, texto: string)
	local cartel = info.modelo:FindFirstChild("Cartel")
	if cartel then
		for _, gui in cartel:GetChildren() do
			local etiqueta = gui:FindFirstChildOfClass("TextLabel")
			if etiqueta then
				etiqueta.Text = texto
			end
		end
	end
end

local function colorear(info: InfoBase)
	local dueno = info.dueno
	local datos = Config.BASES[info.indice]
	local color = if dueno then datos.color else Config.COLOR_LIBRE
	for _, d in info.modelo:GetDescendants() do
		if d:IsA("BasePart") and (d.Name == "Color" or d.Name == "Bandera") then
			d.Color = color
		end
	end
	textoCartel(info, if dueno then "BASE DE " .. string.upper(dueno.DisplayName) else "BASE LIBRE")
	local fondo = rotulo(info)
	if fondo then
		(fondo:FindFirstChild("Borde") :: UIStroke).Color = color;
		(fondo:FindFirstChild("Nombre") :: TextLabel).Text = if dueno then "🏠 " .. dueno.DisplayName else "BASE LIBRE"
		fondo.BackgroundTransparency = if dueno then 0.25 else 0.6
	end
end

local function mostrarMejora(info: InfoBase, nombre: string, visible: boolean)
	local m = info.modelo:FindFirstChild(nombre)
	if m then
		Util.mostrar(m, visible)
	end
end

-- Aplica el efecto de las mejoras que tiene el dueño.
local function aplicarMejoras(info: InfoBase)
	local dueno = info.dueno
	local function tiene(id: string): boolean
		return dueno ~= nil and dueno:GetAttribute("Mejora_" .. id) == true
	end
	if dueno then
		local capacidad = Config.MOCHILA.BASE
		if tiene("Mochila2") then
			capacidad = Config.MOCHILA.EXPEDICION
		elseif tiene("Mochila1") then
			capacidad = Config.MOCHILA.GRANDE
		end
		dueno:SetAttribute("Capacidad", capacidad)
		Estado.emitir("MejorasCambian", dueno)
	end
	info.promptRobar.HoldDuration = if tiene("Candado") then ROBO.TIEMPO_CANDADO else ROBO.TIEMPO
	mostrarMejora(info, "CandadoVisual", tiene("Candado"))
	mostrarMejora(info, "TrampaVisual", tiene("Trampa"))
	mostrarMejora(info, "Colector", tiene("Colector"))
	mostrarMejora(info, "Huerto", tiene("Huerto"))
end

-- 🧍 Aparecer ----------------------------------------------------------------------------------

local function cargarPersonaje(jugador: Player)
	if jugador.Parent then
		local ok, err = pcall(function()
			jugador:LoadCharacter()
		end)
		if not ok then
			warn("[Bases] No se pudo hacer aparecer a " .. jugador.Name .. ": " .. tostring(err))
		end
	end
end

-- Le da la base `info` a `jugador`, con lo que tenga que haber en el almacén.
local function ocupar(info: InfoBase, jugador: Player, almacen: { [string]: number })
	info.dueno = jugador
	basePorJugador[jugador] = info
	info.modelo:SetAttribute("Dueno", jugador.UserId)
	info.modelo:SetAttribute("DuenoNombre", jugador.DisplayName)
	jugador:SetAttribute("Base", info.indice)
	jugador.RespawnLocation = info.modelo:FindFirstChild("Aparicion") :: SpawnLocation
	for _, id in ORDEN do
		info.modelo:SetAttribute(PREFIJO .. id, almacen[id] or 0)
	end
	info.produccion = {}
	info.intrusos = {}
	colorear(info)
	aplicarMejoras(info)
	actualizarReserva(info)
end

-- Deja la base libre y vacía.
local function vaciar(info: InfoBase)
	local dueno = info.dueno
	if dueno and basePorJugador[dueno] == info then
		basePorJugador[dueno] = nil
	end
	info.dueno = nil
	info.modelo:SetAttribute("Dueno", nil)
	info.modelo:SetAttribute("DuenoNombre", nil)
	for _, id in ORDEN do
		info.modelo:SetAttribute(PREFIJO .. id, 0)
	end
	info.produccion = {}
	info.intrusos = {}
	colorear(info)
	aplicarMejoras(info)
	actualizarReserva(info)
end

local function asignar(jugador: Player, datos)
	local libre: InfoBase? = nil
	for _, info in bases do
		if not info.dueno then
			libre = info
			break
		end
	end
	if not libre then
		if not table.find(esperando, jugador) then
			table.insert(esperando, jugador)
		end
		jugador.RespawnLocation = aparicionNexo
		Estado.notificar(jugador, "😕 No quedan bases libres. Aparecerás en el Nexo hasta que se libere una.", rgb(255, 200, 120))
		return false
	end
	for _, m in Config.MEJORAS do
		if not m.repetible then
			jugador:SetAttribute("Mejora_" .. m.id, datos.mejoras[m.id] == true)
		end
	end
	local _, robos = Datos.stats(jugador)
	robos.Value = datos.robos or 0
	ocupar(libre :: InfoBase, jugador, datos.almacen)
	return true
end

local function liberar(jugador: Player)
	local info = basePorJugador[jugador]
	local idx = table.find(esperando, jugador)
	if idx then
		table.remove(esperando, idx)
	end
	if not info then
		return
	end
	vaciar(info)
	-- ¿Hay alguien esperando base?
	local siguiente = table.remove(esperando, 1)
	if siguiente and siguiente.Parent then
		task.spawn(function()
			if asignar(siguiente, Datos.cargar(siguiente)) then
				Estado.notificar(siguiente, "🏠 ¡Se ha liberado una base! Ahora es tuya.", rgb(150, 230, 150))
				cargarPersonaje(siguiente)
			end
		end)
	end
end

-- 🚚 Mudarse a otra base libre: el almacén y las mejoras se vienen contigo.
local function mudarse(jugador: Player, indice: any)
	if type(indice) ~= "number" then
		return
	end
	local destino: InfoBase? = nil
	for _, info in bases do
		if info.indice == indice then
			destino = info
		end
	end
	if not destino then
		return
	end
	local actual = basePorJugador[jugador]
	local nombre = Config.BASES[destino.indice].nombre
	if destino == actual then
		Estado.notificar(jugador, "🏠 Esa ya es tu base.")
		return
	end
	if destino.dueno then
		Estado.notificar(jugador, "🚫 La base " .. string.upper(nombre) .. " ya es de " .. destino.dueno.DisplayName .. ".", rgb(255, 170, 150))
		return
	end
	if jugador:GetAttribute("Ladron") then
		Estado.notificar(jugador, "🦹 No te puedes mudar mientras eres LADRÓN.", rgb(255, 150, 150))
		return
	end
	local falta = Config.CAMBIO_BASE.ESPERA - (os.clock() - (ultimaMudanza[jugador] or -math.huge))
	if falta > 0 then
		Estado.notificar(jugador, string.format("⏳ Espera %d s para volver a mudarte.", math.ceil(falta)), rgb(255, 200, 120))
		return
	end
	ultimaMudanza[jugador] = os.clock()

	local almacen = {}
	if actual then
		almacen = Bases.almacen(actual)
		vaciar(actual)
	else
		local idx = table.find(esperando, jugador)
		if idx then
			table.remove(esperando, idx)
		end
	end
	ocupar(destino :: InfoBase, jugador, almacen)

	-- Te lleva a tu base nueva
	local aparicion = (destino :: InfoBase).modelo:FindFirstChild("Aparicion") :: BasePart?
	local personaje = jugador.Character
	if aparicion and personaje then
		personaje:PivotTo(CFrame.new(aparicion.Position + Vector3.new(0, 4, 0)))
	end
	Estado.notificar(jugador, "🚚 ¡Te has mudado a la base " .. string.upper(nombre) .. "! Tu almacén y tus mejoras vienen contigo.", Config.BASES[destino.indice].color)
end

local function alEntrar(jugador: Player)
	jugador.CharacterAdded:Connect(function(personaje)
		local hum = personaje:WaitForChild("Humanoid", 10) :: Humanoid?
		if hum then
			hum.Died:Connect(function()
				Estadisticas.muerte(jugador)
				task.delay(REAPARICION, function()
					if jugador.Parent and jugador.Character == personaje then
						cargarPersonaje(jugador)
					end
				end)
			end)
		end
		-- La marca de ladrón sigue aunque reaparezcas
		if jugador:GetAttribute("Ladron") then
			task.defer(Bases.marcarLadron, jugador, nil)
		end
	end)
	local datos = Datos.cargar(jugador)
	if not jugador.Parent then
		return
	end
	Estadisticas.cargar(jugador, datos.estadisticas)
	local tieneBase = asignar(jugador, datos)
	cargarPersonaje(jugador)
	if tieneBase then
		local info = basePorJugador[jugador] :: InfoBase
		local nombre = Config.BASES[info.indice].nombre
		task.delay(3, function()
			Estado.notificar(jugador, string.format("🏠 Tu base es la %s. ¡Guarda en el almacén lo que encuentres!", string.upper(nombre)), Config.BASES[info.indice].color)
		end)
		-- A los demás: quién ha llegado y dónde vive
		for _, otro in Players:GetPlayers() do
			if otro ~= jugador then
				Estado.notificar(otro, string.format("👋 %s ha llegado y vive en la base %s", jugador.DisplayName, string.upper(nombre)), Config.BASES[info.indice].color)
			end
		end
	end
end

-- 🦹 Robar ------------------------------------------------------------------------------------

-- Marca a un jugador como LADRÓN durante un rato: brilla en rojo y sale en el radar de todos.
function Bases.marcarLadron(jugador: Player, segundos: number?)
	if segundos then
		jugador:SetAttribute("Ladron", true)
		jugador:SetAttribute("LadronHasta", os.time() + segundos)
		local hasta = os.time() + segundos
		task.delay(segundos, function()
			if jugador.Parent and (jugador:GetAttribute("LadronHasta") or 0) <= hasta then
				jugador:SetAttribute("Ladron", false)
				local personaje = jugador.Character
				if personaje then
					for _, nombre in { "MarcaLadron", "CartelLadron" } do
						local d = personaje:FindFirstChild(nombre, true)
						if d then
							d:Destroy()
						end
					end
				end
			end
		end)
	end
	local personaje = jugador.Character
	if not personaje or personaje:FindFirstChild("MarcaLadron") then
		return
	end
	local resalte = Instance.new("Highlight")
	resalte.Name = "MarcaLadron"
	resalte.FillColor = rgb(255, 40, 40)
	resalte.FillTransparency = 0.7
	resalte.OutlineColor = rgb(255, 60, 60)
	resalte.Parent = personaje
	local cabeza = personaje:FindFirstChild("Head")
	if cabeza then
		local bb = Instance.new("BillboardGui")
		bb.Name = "CartelLadron"
		bb.Size = UDim2.fromOffset(130, 34)
		bb.StudsOffset = Vector3.new(0, 3, 0)
		bb.AlwaysOnTop = true
		bb.MaxDistance = 200
		bb.Parent = cabeza
		local t = Instance.new("TextLabel")
		t.Size = UDim2.fromScale(1, 1)
		t.BackgroundColor3 = rgb(140, 20, 20)
		t.BackgroundTransparency = 0.2
		t.Font = Enum.Font.GothamBlack
		t.TextScaled = true
		t.TextColor3 = rgb(255, 240, 240)
		t.Text = "🦹 LADRÓN"
		t.Parent = bb
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0.3, 0)
		c.Parent = t
	end
end

-- Elige un objeto del almacén al azar (los valiosos salen más).
local function elegirParaRobar(info: InfoBase): string?
	local total = 0
	for _, id in ORDEN do
		total += cantidadAlmacen(info, id) * OBJETOS[id].valor
	end
	if total <= 0 then
		return nil
	end
	local r = math.random() * total
	for _, id in ORDEN do
		r -= cantidadAlmacen(info, id) * OBJETOS[id].valor
		if r <= 0 then
			return id
		end
	end
	return nil
end

local function descarga(jugador: Player)
	local raiz = Inventario.raiz(jugador)
	local hum = Inventario.humanoide(jugador)
	if not raiz or not hum then
		return
	end
	hum:TakeDamage(ROBO.DANO_TRAMPA)
	local chispa = Instance.new("ParticleEmitter")
	chispa.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	chispa.Color = ColorSequence.new(rgb(140, 210, 255))
	chispa.LightEmission = 1
	chispa.Size = NumberSequence.new(1.2, 0)
	chispa.Speed = NumberRange.new(8, 14)
	chispa.SpreadAngle = Vector2.new(180, 180)
	chispa.Lifetime = NumberRange.new(0.3, 0.6)
	chispa.Rate = 0
	chispa.Parent = raiz
	chispa:Emit(40)
	task.delay(1, function()
		chispa:Destroy()
	end)
end

local function robar(jugador: Player, info: InfoBase)
	local dueno = info.dueno
	if not dueno or dueno == jugador or not cercaDe(jugador, info.cofre, 14) then
		return
	end
	local espacio = Inventario.espacio(jugador)
	if espacio <= 0 then
		Estado.notificar(jugador, "🎒 Tu mochila está llena. ¡Llévalo a tu base!")
		return
	end
	local tieneCandado = dueno:GetAttribute("Mejora_Candado") == true
	local n = math.min(espacio, if tieneCandado then ROBO.OBJETOS_CANDADO else ROBO.OBJETOS)
	local robado = {}
	for _ = 1, n do
		local id = elegirParaRobar(info)
		if not id then
			break
		end
		Bases.quitarAlmacen(info, id, 1)
		robado[id] = (robado[id] or 0) + 1
	end
	if Config.total(robado) == 0 then
		Estado.notificar(jugador, "📦 El almacén de " .. dueno.DisplayName .. " está vacío.")
		return
	end
	Inventario.darContenido(jugador, robado)
	Estado.notificar(jugador, "🦹 Has robado:  " .. Config.textoContenido(robado), rgb(255, 150, 150))
	Estado.remotos.Alerta:FireClient(dueno, "robo", jugador.DisplayName, Config.textoContenido(robado, "-"))
	Bases.marcarLadron(jugador, ROBO.MARCA)
	local _, robos = Datos.stats(jugador)
	robos.Value += 1
	Estadisticas.sumar(jugador, "Robos")
	Estadisticas.sumar(dueno, "Robado")
	if dueno:GetAttribute("Mejora_Trampa") then
		descarga(jugador)
		Estado.notificar(jugador, "⚡ ¡AY! Una trampa eléctrica... -" .. ROBO.DANO_TRAMPA .. " ❤️", rgb(140, 210, 255))
	end
end

-- 🔨 Mejoras -----------------------------------------------------------------------------------

-- ¿Cuánto tiene el jugador de un objeto entre su almacén y su mochila?
local function disponible(jugador: Player, info: InfoBase, id: string): number
	return cantidadAlmacen(info, id) + Inventario.cantidad(jugador, id)
end

local function mejorar(jugador: Player, id: string)
	local info = basePorJugador[jugador]
	local mejora = type(id) == "string" and Config.mejora(id)
	if not info or not mejora then
		return
	end
	if not enLaBase(jugador, info) then
		Estado.notificar(jugador, "Tienes que estar en tu base para mejorarla.")
		return
	end
	if not mejora.repetible and jugador:GetAttribute("Mejora_" .. id) then
		return
	end
	if mejora.requiere and not jugador:GetAttribute("Mejora_" .. mejora.requiere) then
		local antes = Config.mejora(mejora.requiere)
		Estado.notificar(jugador, "🔒 Primero necesitas: " .. (if antes then antes.nombre else mejora.requiere))
		return
	end
	for objeto, n in mejora.coste do
		if disponible(jugador, info, objeto) < n then
			Estado.notificar(jugador, "Te falta material: necesitas " .. Config.textoContenido(mejora.coste, ""), rgb(255, 170, 120))
			return
		end
	end
	-- Se paga primero con lo del almacén y luego con lo de la mochila
	for objeto, n in mejora.coste do
		local falta = n - Bases.quitarAlmacen(info, objeto, n)
		if falta > 0 then
			Inventario.quitar(jugador, objeto, falta)
		end
	end
	if mejora.repetible then
		Bases.darAlmacen(info, "Botiquin", 1)
	else
		jugador:SetAttribute("Mejora_" .. id, true)
		aplicarMejoras(info)
	end
	Estado.notificar(jugador, string.format("🔨 ¡Hecho! %s %s", mejora.icono, mejora.nombre), rgb(150, 230, 150))
end

-- 🔄 Guardar y sacar -----------------------------------------------------------------------------

local function guardar(jugador: Player, id, cantidad)
	local info = basePorJugador[jugador]
	if not info or not enLaBase(jugador, info) then
		return
	end
	local lista = if id == "todo" then ORDEN else { id }
	local movido = {}
	for _, objeto in lista do
		if type(objeto) == "string" and OBJETOS[objeto] then
			local n = Inventario.cantidad(jugador, objeto)
			if id ~= "todo" and type(cantidad) == "number" then
				n = math.min(n, math.max(1, math.floor(cantidad)))
			end
			local quitado = Inventario.quitar(jugador, objeto, n)
			if quitado > 0 then
				Bases.darAlmacen(info, objeto, quitado)
				movido[objeto] = quitado
			end
		end
	end
	if id == "todo" then
		if Config.total(movido) > 0 then
			Estado.notificar(jugador, "📦 Guardado en tu almacén:  " .. Config.textoContenido(movido), rgb(150, 230, 150))
		else
			Estado.notificar(jugador, "No llevas nada en la mochila.")
		end
	end
end

local function sacar(jugador: Player, id, cantidad)
	local info = basePorJugador[jugador]
	if not info or type(id) ~= "string" or not OBJETOS[id] or not enLaBase(jugador, info) then
		return
	end
	local n = cantidadAlmacen(info, id)
	if type(cantidad) == "number" then
		n = math.min(n, math.max(1, math.floor(cantidad)))
	end
	n = math.min(n, Inventario.espacio(jugador))
	if n <= 0 then
		if Inventario.espacio(jugador) <= 0 then
			Estado.notificar(jugador, "🎒 Tu mochila está llena.")
		end
		return
	end
	local quitado = Bases.quitarAlmacen(info, id, n)
	Inventario.dar(jugador, id, quitado)
end

-- 🏆 Tablones del Nexo con las bases más ricas ------------------------------------------------------

local lineasTablon: { { TextLabel } } = {}

local function prepararTablones()
	for _, tablon in CollectionService:GetTagged("Tablon") do
		local gui = Instance.new("SurfaceGui")
		gui.Name = "Lista"
		gui.Face = Enum.NormalId.Front
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 30
		gui.LightInfluence = 0.3
		gui.Parent = tablon
		local lista = Instance.new("Frame")
		lista.Size = UDim2.fromScale(1, 1)
		lista.BackgroundTransparency = 1
		lista.Parent = gui
		local relleno = Instance.new("UIPadding")
		relleno.PaddingTop = UDim.new(0.05, 0)
		relleno.PaddingLeft = UDim.new(0.06, 0)
		relleno.PaddingRight = UDim.new(0.06, 0)
		relleno.Parent = lista
		local orden = Instance.new("UIListLayout")
		orden.SortOrder = Enum.SortOrder.LayoutOrder
		orden.Padding = UDim.new(0.01, 0)
		orden.Parent = lista
		local titulo = Instance.new("TextLabel")
		titulo.Size = UDim2.fromScale(1, 0.16)
		titulo.BackgroundTransparency = 1
		titulo.Font = Enum.Font.GothamBlack
		titulo.TextScaled = true
		titulo.TextColor3 = rgb(255, 205, 100)
		titulo.Text = "🏆 LAS BASES MÁS RICAS"
		titulo.LayoutOrder = 0
		titulo.Parent = lista
		local lineas = {}
		for i = 1, Config.MAPA.BASES do
			local t = Instance.new("TextLabel")
			t.Size = UDim2.fromScale(1, 0.095)
			t.BackgroundTransparency = 1
			t.Font = Enum.Font.GothamBold
			t.TextScaled = true
			t.RichText = true
			t.TextXAlignment = Enum.TextXAlignment.Left
			t.TextColor3 = rgb(236, 230, 214)
			t.Text = ""
			t.LayoutOrder = i
			t.Parent = lista
			lineas[i] = t
		end
		table.insert(lineasTablon, lineas)
	end
end

local function hex(c: Color3): string
	return string.format("#%02x%02x%02x", math.floor(c.R * 255), math.floor(c.G * 255), math.floor(c.B * 255))
end

local function actualizarTablones()
	local filas = {}
	for _, info in bases do
		if info.dueno then
			table.insert(filas, { info = info, valor = info.modelo:GetAttribute("Reserva") or 0 })
		end
	end
	table.sort(filas, function(a, b)
		return a.valor > b.valor
	end)
	for _, lineas in lineasTablon do
		for i, t in lineas do
			local fila = filas[i]
			if fila then
				local datos = Config.BASES[fila.info.indice]
				local medalla = ({ "🥇", "🥈", "🥉" })[i] or (i .. ".")
				t.Text = string.format('%s <font color="%s">■</font> %s  ·  💰 %d', medalla, hex(datos.color), (fila.info.dueno :: Player).DisplayName, fila.valor)
			else
				t.Text = if i == 1 then "Todavía no hay nadie..." else ""
			end
		end
	end
end

-- 🚀 Arranque ------------------------------------------------------------------------------------

function Bases.iniciar()
	for _, modelo in CollectionService:GetTagged("Base") do
		local almacen = modelo:FindFirstChild("Almacen") :: Model?
		local cofre = almacen and almacen.PrimaryPart
		if not cofre then
			warn("[Bases] A la base " .. modelo.Name .. " le falta el almacén")
			continue
		end
		-- Si el mapa se copió durante una partida, puede traer el dueño y el almacén de entonces
		modelo:SetAttribute("Dueno", nil)
		modelo:SetAttribute("DuenoNombre", nil)
		modelo:SetAttribute("Reserva", 0)
		for _, id in ORDEN do
			modelo:SetAttribute(PREFIJO .. id, 0)
		end
		local abrir = Util.prompt(cofre, "Abrir almacén", "📦 Tu almacén", 0, 9)
		abrir.Name = "Abrir"
		local robarPrompt = Util.prompt(cofre, "Robar", "🦹 Almacén", ROBO.TIEMPO, 9)
		robarPrompt.Name = "Robar"
		local mesaModelo = modelo:FindFirstChild("Mesa") :: Model?
		local mesa = mesaModelo and mesaModelo.PrimaryPart
		local info: InfoBase = {
			modelo = modelo,
			indice = modelo:GetAttribute("Indice") or (#bases + 1),
			dueno = nil,
			cofre = cofre,
			mesa = mesa,
			promptAbrir = abrir,
			promptRobar = robarPrompt,
			produccion = {},
			intrusos = {},
		}
		table.insert(bases, info)
		prepararRotulo(info)
		abrir.Triggered:Connect(function(jugador)
			if info.dueno == jugador then
				Estado.remotos.AbrirAlmacen:FireClient(jugador)
			elseif info.dueno then
				Estado.notificar(jugador, "Este almacén es de " .. info.dueno.DisplayName .. ". Mantén E en «Robar» para llevarte algo...")
			end
		end)
		robarPrompt.Triggered:Connect(function(jugador)
			robar(jugador, info)
		end)
		if mesa then
			local p = Util.prompt(mesa, "Mejorar la base", "🔨 Mesa de trabajo", 0, 9)
			p.Name = "Mejorar"
			p.Triggered:Connect(function(jugador)
				if info.dueno == jugador then
					Estado.remotos.AbrirMejoras:FireClient(jugador)
				elseif info.dueno then
					Estado.notificar(jugador, "Esta mesa es de " .. info.dueno.DisplayName .. ".")
				end
			end)
		end
		colorear(info)
		aplicarMejoras(info)
	end
	table.sort(bases, function(a, b)
		return a.indice < b.indice
	end)
	aparicionNexo = workspace:FindFirstChild("AparicionNexo", true) :: SpawnLocation?
	prepararTablones()

	Estado.remotos.Guardar.OnServerEvent:Connect(guardar)
	Estado.remotos.Sacar.OnServerEvent:Connect(sacar)
	Estado.remotos.Mejorar.OnServerEvent:Connect(mejorar)
	Estado.remotos.CambiarBase.OnServerEvent:Connect(mudarse)

	Players.PlayerAdded:Connect(alEntrar)
	for _, jugador in Players:GetPlayers() do
		task.spawn(alEntrar, jugador)
	end
	Players.PlayerRemoving:Connect(function(jugador)
		Datos.guardar(jugador, instantanea(jugador))
		Datos.olvidar(jugador)
		liberar(jugador)
		ultimaMudanza[jugador] = nil
		for _, info in bases do
			info.intrusos[jugador] = nil
		end
	end)

	-- Cada segundo: producción de las mejoras y avisos de intrusos
	task.spawn(function()
		while true do
			task.wait(1)
			for _, info in bases do
				local dueno = info.dueno
				if not dueno then
					continue
				end
				-- 🛡️ En tu base los otros jugadores te hacen menos daño (lo usa Defensa)
				local enCasa = enLaBase(dueno, info)
				if dueno:GetAttribute("EnSuBase") ~= enCasa then
					dueno:SetAttribute("EnSuBase", enCasa)
				end
				for mejoraId, datos in Config.PRODUCCION do
					if type(datos) == "table" and dueno:GetAttribute("Mejora_" .. mejoraId) then
						info.produccion[mejoraId] = (info.produccion[mejoraId] or 0) + 1
						if info.produccion[mejoraId] >= datos.cada then
							info.produccion[mejoraId] = 0
							if cantidadAlmacen(info, datos.objeto) < Config.PRODUCCION.MAXIMO then
								Bases.darAlmacen(info, datos.objeto, 1)
							end
						end
					end
				end
				for _, otro in Players:GetPlayers() do
					if otro ~= dueno and enLaBase(otro, info, 0) then
						local ultimo = info.intrusos[otro]
						if not ultimo or os.clock() - ultimo > ROBO.AVISO_INTRUSO then
							Estado.remotos.Alerta:FireClient(dueno, "intruso", otro.DisplayName)
							Estado.notificar(otro, "👀 Estás en la base de " .. dueno.DisplayName .. ". ¡Le ha llegado un aviso!", rgb(255, 200, 120))
						end
						info.intrusos[otro] = os.clock()
					end
				end
			end
		end
	end)
	task.spawn(function()
		while true do
			actualizarTablones()
			task.wait(5)
		end
	end)
end

return Bases
