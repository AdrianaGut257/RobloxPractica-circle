-- Los enemigos del bosque. Solo andan por el suelo: no saben subir a las torres ni a las pasarelas.
--   · Errantes: patrullan los caminos SIEMPRE, día y noche.
--   · Vigías: se quedan en su puesto mirando alrededor con una luz. Si te ven, gritan y
--     avisan a los Errantes cercanos.
--   · Rabiosos: solo de noche. Rápidos y te huelen desde lejos.
--   · Colosos: llegan con la lluvia de suministros y se quedan guardando las cajas del suelo.
-- Si subes a una torre te pierden, pero se quedan un rato esperando abajo...
local CollectionService = game:GetService("CollectionService")
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Caminar = require(script.Parent.Caminar)
local Cuerpos = require(script.Parent.Cuerpos)
local Defensa = require(script.Parent.Defensa)
local Estado = require(script.Parent.Estado)
local Recursos = require(script.Parent.Recursos)
local Util = require(script.Parent.Parent.Mundo.Util)

local Enemigos = {}

local CFG = Config.ENEMIGOS
local rgb = Color3.fromRGB
local V = Vector3.new
local TICK = 0.25
local GRUPO = "Enemigos"

local carpeta: Folder
local activos = {}
local rutas: { { Vector3 } } = {}
local puntosAparicion: { Vector3 } = {}
local puestos: { Vector3 } = {}
local plantillas: { [string]: Model } = {}
local avisadoVisto: { [Player]: number } = {}

-- 🧟 Aspecto -------------------------------------------------------------------------------------

local ROPA = { rgb(84, 74, 62), rgb(62, 70, 84), rgb(96, 60, 52), rgb(70, 78, 60), rgb(110, 104, 92) }

local function crearCuerpo(tipo: string): Model
	local datos = CFG.TIPOS[tipo]
	local M = Enum.Material
	local colores, ojos
	if tipo == "Errante" then
		local piel = rgb(122, 140, 108)
		colores = { cabeza = piel, torso = Util.elegir(ROPA), brazos = piel, piernas = rgb(52, 50, 54) }
		ojos = rgb(230, 220, 120)
	elseif tipo == "Vigia" then
		local piel = rgb(184, 182, 170)
		colores = { cabeza = piel, torso = rgb(40, 38, 42), brazos = piel, piernas = rgb(40, 38, 42) }
		ojos = rgb(255, 60, 50)
	elseif tipo == "Rabioso" then
		local piel = rgb(150, 76, 64)
		colores = { cabeza = piel, torso = rgb(70, 40, 36), brazos = piel, piernas = rgb(50, 34, 32) }
		ojos = rgb(255, 80, 40)
	else
		local piel = rgb(96, 104, 88)
		colores = { cabeza = piel, torso = rgb(60, 62, 66), brazos = piel, piernas = rgb(46, 46, 50) }
		ojos = rgb(255, 160, 60)
	end
	local modelo = Cuerpos.crear({
		nombre = datos.nombre,
		escala = datos.escala,
		vida = datos.vida,
		velocidad = math.max(datos.velocidad, 1),
		colores = colores,
		brazosAlFrente = tipo ~= "Vigia",
		grupo = GRUPO,
		distanciaNombre = if datos.jefe then 120 else 0,
		adornos = function(adorno, p, en)
			if tipo == "Vigia" then
				-- Un solo ojo enorme y una capucha
				adorno("Ojo", V(0.7, 0.5, 0.1), en(0, 1.6, -0.66), ojos, nil, p.cabeza, true)
				adorno("Capucha", V(2.3, 1.6, 1.5), en(0, 1.75, 0.1), rgb(34, 32, 36), M.Fabric, p.cabeza)
				adorno("Capa", V(2.2, 3.6, 0.2), en(0, -0.8, 0.6), rgb(34, 32, 36), M.Fabric, p.torso)
			else
				for _, x in { -0.3, 0.3 } do
					adorno("Ojo", V(0.26, 0.16, 0.1), en(x, 1.62, -0.66), ojos, nil, p.cabeza, true)
				end
				-- Ropa rota
				adorno("Jiron", V(1.2, 0.8, 0.2), en(0.3, -1.1, -0.55), colores.torso:Lerp(Color3.new(), 0.3), M.Fabric, p.torso)
				adorno("Herida", V(0.6, 0.5, 0.1), en(-0.5, 0.4, -0.52), rgb(110, 30, 30), M.SmoothPlastic, p.torso)
			end
			if tipo == "Coloso" then
				adorno("Coraza", V(2.4, 1.8, 1.4), en(0, 0.3, 0), rgb(84, 86, 90), M.CorrodedMetal, p.torso)
				adorno("Hombro", V(1.4, 0.8, 1.4), en(1.5, 1.1, 0), rgb(84, 86, 90), M.CorrodedMetal, p.torso)
				adorno("Hombro", V(1.4, 0.8, 1.4), en(-1.5, 1.1, 0), rgb(84, 86, 90), M.CorrodedMetal, p.torso)
			end
			if tipo == "Rabioso" then
				adorno("Pinchos", V(0.3, 0.8, 0.3), en(0, 2.2, 0.2), rgb(40, 30, 30), M.SmoothPlastic, p.cabeza)
			end
		end,
	})
	if tipo == "Vigia" then
		local cabeza = modelo:FindFirstChild("Head") :: BasePart
		local foco = Instance.new("SpotLight")
		foco.Name = "Mirada"
		foco.Face = Enum.NormalId.Front
		foco.Color = rgb(255, 120, 100)
		foco.Range = 45
		foco.Angle = 40
		foco.Brightness = 3
		foco.Shadows = true
		foco.Parent = cabeza
	end
	return modelo
end

local function plantilla(tipo: string): Model
	if not plantillas[tipo] then
		plantillas[tipo] = crearCuerpo(tipo)
	end
	return plantillas[tipo]
end

-- 🔧 Utilidades ---------------------------------------------------------------------------------

local function contar(tipo: string?): number
	local n = 0
	for _, e in activos do
		if not tipo or e.tipo == tipo then
			n += 1
		end
	end
	return n
end

local function actualizarContador()
	Estado.set("EnemigosVivos", contar())
end

-- Jugadores vivos (enSuelo = false si están en una torre o pasarela: ahí no llegan)
local function objetivos()
	local lista = {}
	for _, j in Players:GetPlayers() do
		local c = j.Character
		local h = c and c:FindFirstChildOfClass("Humanoid")
		local r = c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
		if h and r and h.Health > 0 then
			table.insert(lista, {
				jugador = j,
				hum = h,
				raiz = r,
				enSuelo = r.Position.Y < CFG.ALTURA_SEGURA,
				escudo = c:FindFirstChildOfClass("ForceField") ~= nil,
			})
		end
	end
	return lista
end

local function nube(pos: Vector3, tam: number, color: Color3)
	local p = Util.parte({ Parent = workspace, Size = V(1, 1, 1), Position = pos, Transparency = 1, Deco = true })
	local e = Util.particulas(p, {
		Texture = "rbxasset://textures/particles/smoke_main.dds",
		Color = ColorSequence.new(color),
		Transparency = NumberSequence.new(0.3, 1),
		Size = NumberSequence.new(2 * tam, 4 * tam),
		Lifetime = NumberRange.new(0.8, 1.6),
		Speed = NumberRange.new(2, 5),
		SpreadAngle = Vector2.new(180, 180),
		Rate = 0,
	})
	e:Emit(18)
	task.delay(2, function()
		p:Destroy()
	end)
end

-- "❗" encima de la cabeza cuando te ven
local function exclamacion(e)
	local cabeza = e.modelo:FindFirstChild("Head")
	if not cabeza or cabeza:FindFirstChild("Exclamacion") then
		return
	end
	local bb = Instance.new("BillboardGui")
	bb.Name = "Exclamacion"
	bb.Size = UDim2.fromOffset(40, 40)
	bb.StudsOffset = V(0, 2.5 * e.datos.escala, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 120
	bb.Parent = cabeza
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.GothamBlack
	t.TextScaled = true
	t.TextColor3 = rgb(255, 70, 60)
	t.TextStrokeTransparency = 0.3
	t.Text = "!"
	t.Parent = bb
	task.delay(1.6, function()
		bb:Destroy()
	end)
end

-- Un punto de aparición lejos de los jugadores.
local function puntoLejos(minimo: number): Vector3?
	local lista = objetivos()
	local candidatos = {}
	for _, p in puntosAparicion do
		local lejos = true
		for _, o in lista do
			if Util.dist2D(o.raiz.Position, p) < minimo then
				lejos = false
				break
			end
		end
		if lejos then
			table.insert(candidatos, p)
		end
	end
	if #candidatos == 0 then
		return nil
	end
	return candidatos[math.random(1, #candidatos)]
end

-- 💀 Morir ----------------------------------------------------------------------------------------

local programarReaparicion

local function morir(e)
	if e.muerto then
		return
	end
	e.muerto = true
	activos[e.modelo] = nil
	actualizarContador()
	local pos = e.raiz.Position
	nube(pos, e.datos.escala, rgb(90, 96, 80))
	if not e.sinBotin and math.random() < e.datos.botin then
		local botin = Config.tirarBotin(if e.datos.jefe then "Coloso" else "Enemigo")
		if Config.total(botin) > 0 then
			Recursos.soltarContenido(botin, pos)
		end
	end
	if e.datos.jefe and not e.sinBotin then
		Estado.notificar(nil, "💥 ¡Han derribado a un Coloso! Ha soltado buen botín.", rgb(255, 200, 120))
	end
	for _, d in e.modelo:GetDescendants() do
		if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
			TweenService:Create(d, TweenInfo.new(1.2), { Transparency = 1 }):Play()
		elseif d:IsA("Light") then
			d.Enabled = false
		end
	end
	task.delay(1.3, function()
		e.modelo:Destroy()
	end)
	if e.reaparece and not e.sinReaparecer then
		programarReaparicion(e.tipo, e.rutaNumero, e.post)
	end
end

-- 🌱 Aparecer -------------------------------------------------------------------------------------

-- opciones: { ruta = número, post = Vector3, temporal = true }
function Enemigos.aparecer(tipo: string, pos: Vector3, opciones)
	opciones = opciones or {}
	if contar() >= CFG.MAXIMO then
		return nil
	end
	local datos = CFG.TIPOS[tipo]
	local m = plantilla(tipo):Clone()
	if tipo == "Errante" then
		local torso = m:FindFirstChild("Torso") :: BasePart?
		if torso then
			torso.Color = Util.elegir(ROPA)
		end
	end
	local hum = m:FindFirstChildOfClass("Humanoid") :: Humanoid
	local raiz = m:FindFirstChild("HumanoidRootPart") :: BasePart
	m:PivotTo(CFrame.new(pos + V(0, 3 * datos.escala - 2.5, 0)) * CFrame.Angles(0, math.random() * 6.28, 0))
	m.Parent = carpeta
	pcall(function()
		raiz:SetNetworkOwner(nil)
	end)
	CollectionService:AddTag(m, "Enemigo")
	m:SetAttribute("Tipo", tipo)
	local e = {
		modelo = m,
		hum = hum,
		raiz = raiz,
		tipo = tipo,
		datos = datos,
		estado = if tipo == "Vigia" then "guardia" else "patrulla",
		rutaNumero = opciones.ruta,
		ruta = opciones.ruta and rutas[opciones.ruta],
		idx = 1,
		sentido = if math.random() < 0.5 then 1 else -1,
		post = opciones.post,
		reaparece = not opciones.temporal,
		ultimoAtaque = 0,
		giro = math.random() * 6.28,
		agente = Caminar.nuevo(hum, raiz, { radio = 1.6 * datos.escala, alto = 5 * datos.escala }),
	}
	-- Empieza en el punto de la ruta más cercano
	if e.ruta then
		local mejor, mejorD = 1, math.huge
		for i, p in e.ruta do
			local d = Util.dist2D(p, pos)
			if d < mejorD then
				mejor, mejorD = i, d
			end
		end
		e.idx = mejor
	end
	activos[m] = e
	actualizarContador()
	Cuerpos.animar(hum, 12)
	hum.Died:Connect(function()
		morir(e)
	end)
	return e
end

programarReaparicion = function(tipo: string, ruta: number?, post: Vector3?)
	task.delay(CFG.REAPARICION + math.random() * 10, function()
		if tipo == "Vigia" and post then
			-- El vigía vuelve a su puesto cuando no hay nadie cerca
			for _ = 1, 30 do
				local cerca = false
				for _, o in objetivos() do
					if Util.dist2D(o.raiz.Position, post) < 60 then
						cerca = true
						break
					end
				end
				if not cerca then
					break
				end
				task.wait(5)
			end
			Enemigos.aparecer("Vigia", post, { post = post })
		else
			local pos = puntoLejos(70)
			if pos then
				Enemigos.aparecer(tipo, pos, { ruta = ruta })
			else
				programarReaparicion(tipo, ruta, post)
			end
		end
	end)
end

-- 🧠 Comportamiento -------------------------------------------------------------------------------

local function atacar(e, o)
	local ahora = os.clock()
	if ahora - e.ultimoAtaque < e.datos.cadencia or o.escudo then
		return
	end
	e.ultimoAtaque = ahora
	if o.jugador then
		Defensa.danar(o.jugador, o.hum, e.datos.dano, false)
	else
		o.hum:TakeDamage(e.datos.dano)
	end
end

local function puedeVer(e, o, vision: number): boolean
	local desde = e.raiz.Position + V(0, 1.5 * e.datos.escala, 0)
	local dir = o.raiz.Position - desde
	local d = dir.Magnitude
	if d > vision then
		return false
	end
	if d < 9 then
		return true -- te oye aunque no te vea
	end
	if e.tipo == "Vigia" and e.estado == "guardia" then
		local frente = e.raiz.CFrame.LookVector
		if frente:Dot(dir.Unit) < 0.5 then
			return false
		end
	end
	return Caminar.hayVision(desde, o.raiz.Position)
end

-- El Vigía da la alarma: los Errantes y Rabiosos cercanos van a donde estás.
local function alarma(e, o)
	exclamacion(e)
	local pos = o.raiz.Position
	for _, otro in activos do
		if otro ~= e and otro.estado ~= "persigue" and otro.tipo ~= "Vigia" and (otro.raiz.Position - e.raiz.Position).Magnitude <= e.datos.alarma then
			otro.estado = "investiga"
			otro.investigar = pos
			otro.hasta = os.clock() + 15
			exclamacion(otro)
		end
	end
	local ultimo = avisadoVisto[o.jugador]
	if not ultimo or os.clock() - ultimo > 20 then
		avisadoVisto[o.jugador] = os.clock()
		Estado.notificar(o.jugador, "👁️ ¡Un Vigía te ha visto! Los Errantes vienen hacia ti...", rgb(255, 110, 100))
	end
end

-- La caja del suelo más cercana (para los Colosos).
local function cajaCercana(pos: Vector3): Vector3?
	local mejor, mejorD = nil, 260
	for _, caja in CollectionService:GetTagged("CajaSuministros") do
		if caja:GetAttribute("Zona") == "Suelo" then
			local p = caja:GetPivot().Position
			local d = Util.dist2D(p, pos)
			if d < mejorD then
				mejor, mejorD = p, d
			end
		end
	end
	return mejor
end

local function actualizar(e, lista, ahora: number)
	local datos = e.datos
	local pos = e.raiz.Position
	local vision = datos.vision * (if Estado.esNoche() then CFG.NOCHE_VISION else 1)

	-- ¿Ve a alguien en el suelo?
	local mejor, mejorD = nil, math.huge
	for _, o in lista do
		if o.enSuelo then
			local d = (o.raiz.Position - pos).Magnitude
			local yaLoSigue = e.objetivo == o.jugador and d < vision * 1.6
			if d < mejorD and (yaLoSigue or puedeVer(e, o, vision)) then
				mejor, mejorD = o, d
			end
		end
	end

	if mejor and e.tipo == "Vigia" and e.post and (mejor.raiz.Position - e.post).Magnitude > datos.correa then
		mejor = nil -- el vigía no se aleja de su puesto
	end

	if mejor then
		if e.estado ~= "persigue" then
			e.estado = "persigue"
			exclamacion(e)
			if e.tipo == "Vigia" then
				alarma(e, mejor)
			end
		end
		e.objetivo = mejor.jugador
		e.ultimaVista = mejor.raiz.Position
		e.hum.WalkSpeed = datos.persigue
		if mejorD <= 3.4 * datos.escala + 1.6 then
			atacar(e, mejor)
		end
		e.agente:ir(mejor.raiz.Position)
		return
	end

	if e.estado == "persigue" then
		-- Lo ha perdido (o se ha subido a una torre): va a donde lo vio por última vez y espera
		e.estado = "investiga"
		e.objetivo = nil
		local ultima = e.ultimaVista or pos
		e.investigar = V(ultima.X, pos.Y, ultima.Z)
		e.hasta = ahora + 9
	end

	if e.estado == "investiga" then
		if ahora < (e.hasta or 0) then
			e.hum.WalkSpeed = (math.max(datos.velocidad, 6) + datos.persigue) / 2
			e.agente:ir(e.investigar)
			return
		end
		e.estado = if e.tipo == "Vigia" then "guardia" else "patrulla"
	end

	-- 👁️ Vigía: vuelve a su puesto y mira alrededor
	if e.tipo == "Vigia" then
		local post = e.post or pos
		if Util.dist2D(pos, post) > 3 then
			e.hum.WalkSpeed = datos.persigue * 0.6
			e.agente:ir(post)
			return
		end
		e.estado = "guardia"
		e.agente:parar()
		e.giro += 0.55 * TICK
		e.raiz.CFrame = CFrame.new(pos) * CFrame.Angles(0, e.giro, 0)
		return
	end

	e.hum.WalkSpeed = datos.velocidad

	-- 👹 Coloso: guarda las cajas del suelo
	if e.tipo == "Coloso" then
		local caja = cajaCercana(pos)
		if caja then
			if Util.dist2D(pos, caja) > 8 then
				e.agente:ir(caja)
			else
				e.agente:parar()
			end
			return
		end
	end

	-- 🐺 Rabioso: te huele desde lejos aunque no te vea
	if e.tipo == "Rabioso" then
		for _, o in lista do
			if o.enSuelo and Util.dist2D(o.raiz.Position, pos) < 120 then
				e.estado = "investiga"
				e.investigar = o.raiz.Position
				e.hasta = ahora + 4
				e.hum.WalkSpeed = datos.persigue * 0.8
				e.agente:ir(e.investigar)
				return
			end
		end
	end

	-- 🚶 Patrulla
	if e.ruta and #e.ruta > 0 then
		local destino = e.ruta[e.idx]
		if Util.dist2D(pos, destino) < 5 then
			e.idx = (e.idx - 1 + e.sentido) % #e.ruta + 1
			destino = e.ruta[e.idx]
		end
		e.agente:ir(destino)
	else
		if not e.paseo or Util.dist2D(pos, e.paseo) < 5 or ahora > (e.paseoHasta or 0) then
			e.paseo = puntosAparicion[math.random(1, math.max(1, #puntosAparicion))] or pos
			e.paseoHasta = ahora + 25
		end
		e.agente:ir(e.paseo)
	end
end

-- Se deshacen todos los de un tipo (los Rabiosos al amanecer, los Colosos al rato de la lluvia).
local function deshacer(tipo: string)
	for _, e in activos do
		if e.tipo == tipo then
			e.sinBotin = true
			e.sinReaparecer = true
			e.hum.Health = 0
		end
	end
end

-- 🚀 Arranque --------------------------------------------------------------------------------------

function Enemigos.iniciar()
	pcall(function()
		PhysicsService:RegisterCollisionGroup(GRUPO)
	end)
	pcall(function()
		PhysicsService:CollisionGroupSetCollidable(GRUPO, GRUPO, false)
	end)

	carpeta = Instance.new("Folder")
	carpeta.Name = "Enemigos"
	carpeta.Parent = workspace
	Caminar.ignorar(carpeta)
	Caminar.ignorar(Recursos.carpeta)
	local suministros = workspace:FindFirstChild("Suministros")
	if suministros then
		Caminar.ignorar(suministros)
	end

	-- Rutas de patrulla (marcadores "PuntoRuta" con Ruta y Orden)
	local porRuta = {}
	for _, p in CollectionService:GetTagged("PuntoRuta") do
		local n = p:GetAttribute("Ruta") or 1
		porRuta[n] = porRuta[n] or {}
		table.insert(porRuta[n], p)
	end
	for n, lista in porRuta do
		table.sort(lista, function(a, b)
			return (a:GetAttribute("Orden") or 0) < (b:GetAttribute("Orden") or 0)
		end)
		rutas[n] = {}
		for _, p in lista do
			table.insert(rutas[n], (p :: BasePart).Position)
		end
	end
	for _, p in CollectionService:GetTagged("PuntoEnemigo") do
		table.insert(puntosAparicion, (p :: BasePart).Position)
	end
	for _, p in CollectionService:GetTagged("PuntoVigia") do
		table.insert(puestos, (p :: BasePart).Position)
	end
	if #puntosAparicion == 0 then
		warn("[Enemigos] No hay puntos de aparición (etiqueta 'PuntoEnemigo')")
		return
	end

	-- Errantes repartidos por las rutas (más en las rutas largas)
	local totalPuntos = 0
	for _, r in rutas do
		totalPuntos += #r
	end
	local creados = 0
	for n, r in rutas do
		local cuantos = math.max(1, math.floor(CFG.ERRANTES * #r / math.max(totalPuntos, 1) + 0.5))
		for _ = 1, cuantos do
			if creados >= CFG.ERRANTES then
				break
			end
			creados += 1
			Enemigos.aparecer("Errante", r[math.random(1, #r)], { ruta = n })
		end
	end
	for i, post in puestos do
		if i <= CFG.VIGIAS then
			Enemigos.aparecer("Vigia", post, { post = post })
		end
	end

	-- 🌙 De noche salen los Rabiosos; al amanecer se deshacen
	Estado.escuchar("NocheEmpieza", function()
		Estado.notificar(nil, "🌙 Se oyen aullidos... Los Rabiosos han salido. Mejor quedarse en alto.", rgb(255, 120, 100))
		for _ = 1, CFG.RABIOSOS_NOCHE do
			if not Estado.esNoche() then
				break
			end
			local pos = puntoLejos(60)
			if pos then
				Enemigos.aparecer("Rabioso", pos, { temporal = true })
			end
			task.wait(3)
		end
	end)
	Estado.escuchar("DiaEmpieza", function()
		deshacer("Rabioso")
	end)

	-- 🪂 Con la lluvia llegan los Colosos; las cajas del suelo atraen a los demás
	Estado.escuchar("LluviaEmpieza", function()
		for _ = 1, CFG.COLOSOS_LLUVIA do
			local pos = puntoLejos(80)
			if pos then
				Enemigos.aparecer("Coloso", pos, { temporal = true })
			end
		end
		Estado.notificar(nil, "👹 Los Colosos han oído los aviones... Van a por las cajas del suelo.", rgb(255, 170, 110))
	end)
	Estado.escuchar("LluviaTermina", function()
		task.delay(240, function()
			if not Estado.get("LluviaActiva") then
				deshacer("Coloso")
			end
		end)
	end)
	Estado.escuchar("CajaAterriza", function(pos: Vector3, zona: string)
		if zona ~= "Suelo" then
			return
		end
		for _, e in activos do
			if (e.tipo == "Errante" or e.tipo == "Rabioso") and e.estado == "patrulla" and Util.dist2D(e.raiz.Position, pos) < 90 then
				e.estado = "investiga"
				e.investigar = pos
				e.hasta = os.clock() + 20
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(jugador)
		avisadoVisto[jugador] = nil
	end)

	-- Bucle de comportamiento
	local avisado = false
	task.spawn(function()
		while true do
			task.wait(TICK)
			local lista = objetivos()
			local ahora = os.clock()
			for modelo, e in activos do
				if e.muerto or not modelo.Parent then
					activos[modelo] = nil
					continue
				end
				local ok, err = pcall(actualizar, e, lista, ahora)
				if not ok and not avisado then
					avisado = true
					warn("[Enemigos] Error en el comportamiento: " .. tostring(err))
				end
			end
		end
	end)
end

return Enemigos
