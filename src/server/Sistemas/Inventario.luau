-- La mochila de cada jugador (con espacio limitado), su hambre y su sed.
-- Todo se guarda como atributos del jugador para que la pantalla lo vea al momento:
--   M_<objeto> = cantidad en la mochila · Carga · Capacidad · Hambre · Sed
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Estado = require(script.Parent.Estado)

local Inventario = {}

local S = Config.SUPERVIVENCIA
local OBJETOS = Config.OBJETOS
local ORDEN = Config.ORDEN_OBJETOS
local PREFIJO = "M_"
local rgb = Color3.fromRGB

-- Orden de objetos del más valioso al menos (para meter primero lo bueno si no cabe todo)
local POR_VALOR = table.clone(ORDEN)
table.sort(POR_VALOR, function(a, b)
	return OBJETOS[a].valor > OBJETOS[b].valor
end)
Inventario.POR_VALOR = POR_VALOR

-- Lo pone Bases al arrancar: el almacén del jugador si está junto a él (para comer de ahí).
Inventario.almacenCerca = function(_jugador: Player)
	return nil
end

-- 🎒 Mochila --------------------------------------------------------------------------------

function Inventario.cantidad(jugador: Player, id: string): number
	return jugador:GetAttribute(PREFIJO .. id) or 0
end

function Inventario.capacidad(jugador: Player): number
	return jugador:GetAttribute("Capacidad") or Config.MOCHILA.BASE
end

function Inventario.total(jugador: Player): number
	local n = 0
	for _, id in ORDEN do
		n += Inventario.cantidad(jugador, id)
	end
	return n
end

function Inventario.espacio(jugador: Player): number
	return math.max(0, Inventario.capacidad(jugador) - Inventario.total(jugador))
end

local function actualizarCarga(jugador: Player)
	jugador:SetAttribute("Carga", Inventario.total(jugador))
end

-- Mete hasta n objetos (los que quepan). Devuelve cuántos han entrado.
function Inventario.dar(jugador: Player, id: string, n: number): number
	local cabe = math.min(n, Inventario.espacio(jugador))
	if cabe <= 0 or not OBJETOS[id] then
		return 0
	end
	jugador:SetAttribute(PREFIJO .. id, Inventario.cantidad(jugador, id) + cabe)
	actualizarCarga(jugador)
	return cabe
end

-- Quita hasta n objetos. Devuelve cuántos ha quitado.
function Inventario.quitar(jugador: Player, id: string, n: number): number
	local hay = Inventario.cantidad(jugador, id)
	local quita = math.min(n, hay)
	if quita > 0 then
		jugador:SetAttribute(PREFIJO .. id, hay - quita)
		actualizarCarga(jugador)
	end
	return quita
end

function Inventario.contenido(jugador: Player): { [string]: number }
	local c = {}
	for _, id in ORDEN do
		local n = Inventario.cantidad(jugador, id)
		if n > 0 then
			c[id] = n
		end
	end
	return c
end

-- Saca todo de la mochila y lo devuelve.
function Inventario.vaciar(jugador: Player): { [string]: number }
	local c = Inventario.contenido(jugador)
	for _, id in ORDEN do
		jugador:SetAttribute(PREFIJO .. id, 0)
	end
	actualizarCarga(jugador)
	return c
end

-- Mete un contenido entero (empezando por lo más valioso). Devuelve lo que ha entrado.
-- El contenido que se pasa se queda con lo que ha sobrado.
function Inventario.darContenido(jugador: Player, contenido: { [string]: number }): { [string]: number }
	local metido = {}
	for _, id in POR_VALOR do
		local n = contenido[id]
		if n and n > 0 then
			local entra = Inventario.dar(jugador, id, n)
			if entra > 0 then
				metido[id] = entra
				contenido[id] = n - entra
				if contenido[id] <= 0 then
					contenido[id] = nil
				end
			end
		end
	end
	return metido
end

-- 🧍 Personaje ------------------------------------------------------------------------------

function Inventario.humanoide(jugador: Player): Humanoid?
	local personaje = jugador.Character
	local hum = personaje and personaje:FindFirstChildOfClass("Humanoid")
	if hum and hum.Health > 0 then
		return hum
	end
	return nil
end

function Inventario.raiz(jugador: Player): BasePart?
	local personaje = jugador.Character
	local raiz = personaje and personaje:FindFirstChild("HumanoidRootPart")
	if raiz and Inventario.humanoide(jugador) then
		return raiz :: BasePart
	end
	return nil
end

-- 🍖💧 Comer, beber y curarse ---------------------------------------------------------------

function Inventario.beber(jugador: Player, cantidad: number)
	jugador:SetAttribute("Sed", math.min(S.MAXIMO, (jugador:GetAttribute("Sed") or 0) + cantidad))
end

function Inventario.comerCantidad(jugador: Player, cantidad: number)
	jugador:SetAttribute("Hambre", math.min(S.MAXIMO, (jugador:GetAttribute("Hambre") or 0) + cantidad))
end

local function elegirComida(cuantas: (string) -> number, hambre: number): string?
	local falta = S.MAXIMO - hambre
	if falta >= 30 and cuantas("Lata") > 0 then
		return "Lata"
	end
	if cuantas("Bayas") > 0 then
		return "Bayas"
	end
	if cuantas("Lata") > 0 then
		return "Lata"
	end
	return nil
end

local QUE_FALTA = {
	comida = "No llevas comida. Coge bayas 🍇 de los arbustos o latas 🥫 de las cajas.",
	bebida = "No llevas agua. Llena una botella 💧 en un pozo o busca en las cajas.",
	cura = "No llevas botiquines 🩹. Salen en las cajas o se fabrican en tu mesa.",
}

local ultimoUso: { [Player]: number } = {}

-- que: un objeto ("Lata", "Agua"...) o una categoría ("comida", "bebida", "cura").
function Inventario.usar(jugador: Player, que: string, desdeAlmacen: boolean?)
	local ahora = os.clock()
	if ultimoUso[jugador] and ahora - ultimoUso[jugador] < 0.35 then
		return
	end
	ultimoUso[jugador] = ahora
	local hum = Inventario.humanoide(jugador)
	if not hum or type(que) ~= "string" then
		return
	end

	-- ¿De dónde se coge? De la mochila o (si estás junto a él) de tu almacén.
	local almacen = if desdeAlmacen then Inventario.almacenCerca(jugador) else nil
	local function cuantas(id: string): number
		if almacen then
			return almacen.cantidad(id)
		end
		return Inventario.cantidad(jugador, id)
	end
	local function gastar(id: string)
		if almacen then
			almacen.quitar(id, 1)
		else
			Inventario.quitar(jugador, id, 1)
		end
	end

	local hambre = jugador:GetAttribute("Hambre") or 0
	local id = que
	local categoria = que
	if que == "comida" then
		id = elegirComida(cuantas, hambre)
	elseif que == "bebida" then
		id = "Agua"
	elseif que == "cura" then
		id = "Botiquin"
	else
		local datos = OBJETOS[que]
		categoria = datos and datos.uso
	end
	if not id or cuantas(id) <= 0 then
		local texto = QUE_FALTA[categoria or ""]
		if texto then
			Estado.notificar(jugador, texto)
		end
		return
	end
	local datos = OBJETOS[id]
	if not datos or not datos.uso then
		return
	end

	if datos.uso == "comida" then
		if hambre >= S.MAXIMO - 1 then
			Estado.notificar(jugador, "No tienes hambre ahora mismo.")
			return
		end
		gastar(id)
		Inventario.comerCantidad(jugador, datos.hambre)
		Estado.notificar(jugador, string.format("%s ¡Ñam!  +%d 🍖", datos.icono, datos.hambre), rgb(240, 180, 110))
	elseif datos.uso == "bebida" then
		if (jugador:GetAttribute("Sed") or 0) >= S.MAXIMO - 1 then
			Estado.notificar(jugador, "No tienes sed ahora mismo.")
			return
		end
		gastar(id)
		Inventario.beber(jugador, datos.sed)
		Estado.notificar(jugador, string.format("%s ¡Qué fresquita!  +%d 💧", datos.icono, datos.sed), rgb(130, 200, 255))
	elseif datos.uso == "cura" then
		if hum.Health >= hum.MaxHealth - 1 then
			Estado.notificar(jugador, "Ya tienes toda la vida.")
			return
		end
		gastar(id)
		hum.Health = math.min(hum.MaxHealth, hum.Health + datos.vida)
		Estado.notificar(jugador, string.format("%s Te has curado  +%d ❤️", datos.icono, datos.vida), rgb(150, 230, 150))
	end
end

-- 🎒 Mochila que se ve en la espalda (más grande con las mejoras) ---------------------------------

local function ponerMochila(jugador: Player, personaje: Model)
	local torso = (personaje:FindFirstChild("UpperTorso") or personaje:FindFirstChild("Torso")) :: BasePart?
	if not torso then
		return
	end
	local vieja = personaje:FindFirstChild("MochilaVisual")
	if vieja then
		vieja:Destroy()
	end
	local capacidad = Inventario.capacidad(jugador)
	local s = if capacidad >= Config.MOCHILA.EXPEDICION then 1.3 elseif capacidad >= Config.MOCHILA.GRANDE then 1.15 else 1
	local m = Instance.new("Model")
	m.Name = "MochilaVisual"
	local atras = torso.Size.Z / 2
	local ancho = torso.Size.X * 0.75
	local alto = torso.Size.Y * 1.05
	local function pieza(size: Vector3, offset: CFrame, color: Color3, cilindro: boolean?)
		local p = Instance.new("Part")
		p.Size = size
		p.Color = color
		p.Material = Enum.Material.Fabric
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Massless = true
		if cilindro then
			p.Shape = Enum.PartType.Cylinder
		end
		p.CFrame = torso.CFrame * offset
		local w = Instance.new("WeldConstraint")
		w.Part0 = torso
		w.Part1 = p
		w.Parent = p
		p.Parent = m
		return p
	end
	local fondo = 0.75 * s
	pieza(Vector3.new(ancho * s, alto * s, fondo), CFrame.new(0, 0, atras + fondo / 2), rgb(118, 84, 52))
	pieza(Vector3.new(ancho * s + 0.05, 0.3, fondo + 0.05), CFrame.new(0, alto * s / 2 - 0.1, atras + fondo / 2), rgb(92, 64, 40))
	pieza(Vector3.new(ancho * 0.7 * s, alto * 0.35 * s, 0.35), CFrame.new(0, -alto * s * 0.22, atras + fondo + 0.17), rgb(96, 68, 42))
	if capacidad >= Config.MOCHILA.EXPEDICION then
		-- Saco de dormir enrollado encima
		pieza(Vector3.new(ancho * 1.25, 0.7, 0.7), CFrame.new(0, alto * s / 2 + 0.35, atras + fondo / 2), rgb(60, 92, 70), true)
	end
	m.Parent = personaje
end

-- 💀 Al caer, la mochila se queda en el suelo --------------------------------------------------

local function alAparecer(jugador: Player, personaje: Model)
	local hum = personaje:WaitForChild("Humanoid", 10) :: Humanoid?
	if not hum then
		return
	end
	for _, atributo in { "Hambre", "Sed" } do
		jugador:SetAttribute(atributo, math.max(jugador:GetAttribute(atributo) or 0, S.AL_REAPARECER))
	end
	task.delay(0.5, function()
		if personaje.Parent then
			ponerMochila(jugador, personaje)
		end
	end)
	hum.Died:Connect(function()
		local raiz = personaje:FindFirstChild("HumanoidRootPart") :: BasePart?
		local pos = if raiz then raiz.Position else nil
		local contenido = Inventario.vaciar(jugador)
		if pos and Config.total(contenido) > 0 then
			Estado.emitir("JugadorMuerto", jugador, pos, contenido)
			Estado.notificar(jugador, "💀 Has caído... Tu mochila se ha quedado donde caíste. ¡Corre a por ella antes que otros!", rgb(255, 120, 120))
		end
	end)
end

function Inventario.iniciar()
	local function alEntrar(jugador: Player)
		for _, id in ORDEN do
			jugador:SetAttribute(PREFIJO .. id, 0)
		end
		jugador:SetAttribute("Carga", 0)
		jugador:SetAttribute("Capacidad", Config.MOCHILA.BASE)
		jugador:SetAttribute("Hambre", S.MAXIMO)
		jugador:SetAttribute("Sed", S.MAXIMO)
		jugador.CharacterAdded:Connect(function(personaje)
			alAparecer(jugador, personaje)
		end)
		jugador:GetAttributeChangedSignal("Capacidad"):Connect(function()
			local personaje = jugador.Character
			if personaje and Inventario.humanoide(jugador) then
				ponerMochila(jugador, personaje)
			end
		end)
		if jugador.Character then
			task.spawn(alAparecer, jugador, jugador.Character)
		end
	end
	Players.PlayerAdded:Connect(alEntrar)
	for _, jugador in Players:GetPlayers() do
		task.spawn(alEntrar, jugador)
	end
	Players.PlayerRemoving:Connect(function(jugador)
		ultimoUso[jugador] = nil
	end)

	Estado.remotos.Usar.OnServerEvent:Connect(function(jugador, que, desdeAlmacen)
		Inventario.usar(jugador, que, desdeAlmacen == true)
	end)

	-- Cada segundo bajan el hambre y la sed. Si llegan a cero, pierdes vida.
	-- Si las dos están altas, la vida sube sola poco a poco.
	task.spawn(function()
		local avisos: { [Player]: { [string]: boolean } } = {}
		while true do
			task.wait(1)
			for _, jugador in Players:GetPlayers() do
				local hum = Inventario.humanoide(jugador)
				if not hum then
					continue
				end
				local hambre = math.max(0, (jugador:GetAttribute("Hambre") or 0) - S.GASTO_HAMBRE)
				local sed = math.max(0, (jugador:GetAttribute("Sed") or 0) - S.GASTO_SED)
				jugador:SetAttribute("Hambre", hambre)
				jugador:SetAttribute("Sed", sed)
				if hambre <= 0 then
					hum:TakeDamage(S.DANO_HAMBRE)
				end
				if sed <= 0 then
					hum:TakeDamage(S.DANO_SED)
				end
				if hambre >= S.REGENERA_DESDE and sed >= S.REGENERA_DESDE and hum.Health < hum.MaxHealth then
					hum.Health = math.min(hum.MaxHealth, hum.Health + S.REGENERACION)
				end
				-- Avisos (una vez cada vez que bajan del límite)
				avisos[jugador] = avisos[jugador] or {}
				local a = avisos[jugador]
				if hambre < S.AVISO and not a.hambre then
					a.hambre = true
					Estado.notificar(jugador, "🍖 ¡Tienes mucha hambre! Come algo [F]", rgb(255, 170, 90))
				elseif hambre >= S.AVISO + 10 then
					a.hambre = false
				end
				if sed < S.AVISO and not a.sed then
					a.sed = true
					Estado.notificar(jugador, "💧 ¡Tienes mucha sed! Bebe algo [G]", rgb(120, 190, 255))
				elseif sed >= S.AVISO + 10 then
					a.sed = false
				end
			end
			for jugador in avisos do
				if not jugador.Parent then
					avisos[jugador] = nil
				end
			end
		end
	end)
end

return Inventario
