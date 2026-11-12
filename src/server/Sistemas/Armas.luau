-- Armas en 3 grupos (Config.GRUPOS_ARMAS). Llevas la mejor que tengas de cada grupo:
--   👹 monstruos: cuerpo a cuerpo, SOLO hacen daño a los monstruos.
--   🎯 distancia: disparan solas al monstruo que tengas delante (también solo monstruos).
--   🧤 mano: para jugar con otros jugadores: casi no hacen daño, pero dan un buen EMPUJÓN.
-- El Tubo y las Manos gigantes las tienes siempre; las demás se fabrican en la mesa de tu base.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Defensa = require(script.Parent.Defensa)
local Estadisticas = require(script.Parent.Estadisticas)
local Estado = require(script.Parent.Estado)

local Armas = {}

local rgb = Color3.fromRGB
local V = Vector3.new
local plantillas: { [string]: Tool } = {}
local ultimoGolpe: { [Tool]: number } = {}
-- Quién golpeó por última vez a cada jugador (para saber quién lo ha derribado)
local ultimoAtacante: { [Player]: { jugador: Player, t: number } } = {}

-- Construye una herramienta. "piezas" se colocan relativas al mango (Handle).
local function construir(nombre: string, tip: string, mango, piezas, agarre: CFrame): Tool
	local t = Instance.new("Tool")
	t.Name = nombre
	t.ToolTip = tip
	t.CanBeDropped = false
	t.Grip = agarre

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = mango.size
	handle.Color = mango.color
	handle.Material = mango.material
	handle.CanCollide = false
	handle.CanQuery = false
	handle.CFrame = CFrame.new()
	handle.Parent = t

	for _, info in piezas do
		local p = Instance.new("Part")
		p.Name = info.nombre or "Pieza"
		p.Size = info.size
		p.Color = info.color
		p.Material = info.material
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Massless = true
		if info.cilindro then
			p.Shape = Enum.PartType.Cylinder
		end
		p.CFrame = handle.CFrame * info.cf
		p.Parent = t
		local w = Instance.new("WeldConstraint")
		w.Part0 = handle
		w.Part1 = p
		w.Parent = p
	end

	local sonido = Instance.new("Sound")
	sonido.Name = "Golpe"
	sonido.SoundId = "rbxasset://sounds/swordslash.wav"
	sonido.Volume = 0.5
	sonido.Parent = handle
	return t
end

local function crearPlantillas()
	local metal = rgb(120, 124, 130)
	local cinta = rgb(40, 40, 44)

	plantillas.Tubo = construir("Tubo", "Un tubo de metal. Mejor que nada.", {
		size = V(0.4, 4.4, 0.4),
		color = metal,
		material = Enum.Material.CorrodedMetal,
	}, {
		{ nombre = "Cinta", size = V(0.5, 1.2, 0.5), cf = CFrame.new(0, -1.4, 0), color = cinta, material = Enum.Material.Fabric },
		{ nombre = "Codo", size = V(0.55, 0.6, 0.55), cf = CFrame.new(0, 2.1, 0), color = rgb(100, 100, 104), material = Enum.Material.Metal },
	}, CFrame.new(0, -1.4, 0))

	plantillas.Machete = construir("Machete", "Machete: rápido y con buen filo.", {
		size = V(0.3, 1.4, 0.4),
		color = rgb(60, 44, 32),
		material = Enum.Material.Wood,
	}, {
		{ nombre = "Hoja", size = V(0.1, 3.4, 0.9), cf = CFrame.new(0, 2.4, -0.15), color = rgb(190, 192, 196), material = Enum.Material.Metal },
		{ nombre = "Guarda", size = V(0.4, 0.2, 1), cf = CFrame.new(0, 0.75, 0), color = cinta, material = Enum.Material.Metal },
	}, CFrame.new(0, -0.3, 0))

	plantillas.Hacha = construir("Hacha", "Hacha de bombero: golpes muy fuertes.", {
		size = V(0.4, 5, 0.4),
		color = rgb(200, 40, 36),
		material = Enum.Material.SmoothPlastic,
	}, {
		{ nombre = "Cabeza", size = V(0.35, 1.2, 2.2), cf = CFrame.new(0, 2.2, -0.6), color = rgb(196, 30, 30), material = Enum.Material.Metal },
		{ nombre = "Filo", size = V(0.15, 1.5, 0.4), cf = CFrame.new(0, 2.2, -1.75), color = rgb(210, 210, 214), material = Enum.Material.Metal },
		{ nombre = "Pico", size = V(0.3, 0.4, 1.1), cf = CFrame.new(0, 2.2, 0.95), color = rgb(196, 30, 30), material = Enum.Material.Metal },
	}, CFrame.new(0, -1.6, 0))

	local madera = rgb(176, 132, 84)
	local maderaOscura = rgb(92, 66, 44)
	local acero = rgb(170, 172, 178)

	-- 🧤 De mano (para jugar con otros jugadores) ------------------------------------------
	local plastico = Enum.Material.SmoothPlastic
	plantillas.BatePlastico = construir("BatePlastico", "Bate de plástico: ¡PLONC!", {
		size = V(0.45, 4.2, 0.45),
		color = rgb(255, 214, 40),
		material = plastico,
	}, {
		{ nombre = "Grueso", size = V(0.8, 2.2, 0.8), cf = CFrame.new(0, 1.2, 0), color = rgb(255, 60, 60), material = plastico },
		{ nombre = "Tapa", size = V(0.9, 0.2, 0.9), cf = CFrame.new(0, 2.35, 0), color = rgb(255, 60, 60), material = plastico },
	}, CFrame.new(0, -1.5, 0))

	plantillas.Manos = construir("Manos", "Manos gigantes de espuma.", {
		size = V(0.5, 1.2, 0.5),
		color = rgb(255, 196, 30),
		material = plastico,
	}, {
		{ nombre = "Palma", size = V(1.5, 1.6, 0.6), cf = CFrame.new(0, 1.3, 0), color = rgb(255, 196, 30), material = plastico },
		{ nombre = "Dedo", size = V(0.42, 1.5, 0.42), cf = CFrame.new(-0.3, 2.8, 0), color = rgb(255, 196, 30), material = plastico },
		{ nombre = "Pulgar", size = V(0.4, 0.9, 0.4), cf = CFrame.new(0.85, 1.6, 0) * CFrame.Angles(0, 0, math.rad(-35)), color = rgb(255, 196, 30), material = plastico },
		{ nombre = "Numero", size = V(1.2, 0.5, 0.62), cf = CFrame.new(0, 1, 0), color = rgb(40, 110, 255), material = plastico },
	}, CFrame.new(0, -0.2, 0))

	plantillas.Almohada = construir("Almohada", "Almohada gigante: ¡guerra de almohadas!", {
		size = V(0.4, 1.4, 0.4),
		color = rgb(240, 240, 255),
		material = Enum.Material.Fabric,
	}, {
		{ nombre = "Cojin", size = V(0.9, 2.6, 1.9), cf = CFrame.new(0, 2, 0), color = rgb(245, 245, 255), material = Enum.Material.Fabric },
		{ nombre = "Funda", size = V(0.95, 0.3, 1.95), cf = CFrame.new(0, 2.9, 0), color = rgb(150, 190, 255), material = Enum.Material.Fabric },
	}, CFrame.new(0, -0.3, 0))

	plantillas.Pez = construir("Pez", "Un pez. Para dar sopapos.", {
		size = V(0.35, 1, 0.6),
		color = rgb(70, 150, 230),
		material = plastico,
	}, {
		{ nombre = "Cola", size = V(0.2, 0.7, 1.4), cf = CFrame.new(0, -0.7, 0), color = rgb(50, 120, 210), material = plastico },
		{ nombre = "Cuerpo", size = V(0.6, 2.6, 1.2), cf = CFrame.new(0, 1.7, 0), color = rgb(90, 175, 245), material = plastico },
		{ nombre = "Tripa", size = V(0.62, 1.8, 0.5), cf = CFrame.new(0, 1.6, -0.4), color = rgb(240, 240, 220), material = plastico },
		{ nombre = "Ojo", size = V(0.66, 0.3, 0.3), cf = CFrame.new(0, 2.6, -0.25), color = rgb(20, 20, 20), material = plastico },
	}, CFrame.new(0, -0.6, 0))

	plantillas.Guante = construir("Guante", "Guante de boxeo gigante: ¡el empujón más fuerte!", {
		size = V(0.45, 1.4, 0.45),
		color = rgb(250, 250, 250),
		material = plastico,
	}, {
		{ nombre = "Puno", size = V(1.8, 1.9, 2), cf = CFrame.new(0, 1.8, 0), color = rgb(230, 40, 40), material = plastico },
		{ nombre = "Pulgar", size = V(0.6, 1, 0.7), cf = CFrame.new(0.95, 1.5, -0.4), color = rgb(210, 30, 30), material = plastico },
		{ nombre = "Puno", size = V(1.4, 0.5, 1.5), cf = CFrame.new(0, 0.7, 0), color = rgb(250, 250, 250), material = plastico },
	}, CFrame.new(0, -0.4, 0))

	-- 🎯 A distancia (solo contra monstruos) ------------------------------------------------
	plantillas.Tirachinas = construir("Tirachinas", "Tirachinas: dispara piedras a los monstruos.", {
		size = V(0.3, 1.3, 0.3),
		color = madera,
		material = Enum.Material.Wood,
	}, {
		{ nombre = "Horquilla", size = V(0.25, 1, 0.25), cf = CFrame.new(-0.35, 1, 0) * CFrame.Angles(0, 0, math.rad(20)), color = madera, material = Enum.Material.Wood },
		{ nombre = "Horquilla", size = V(0.25, 1, 0.25), cf = CFrame.new(0.35, 1, 0) * CFrame.Angles(0, 0, math.rad(-20)), color = madera, material = Enum.Material.Wood },
		{ nombre = "Goma", size = V(0.9, 0.08, 0.08), cf = CFrame.new(0, 1.4, 0), color = rgb(200, 60, 50), material = plastico },
	}, CFrame.new(0, -0.3, 0))

	plantillas.Ballesta = construir("Ballesta", "Ballesta: flechas que llegan muy lejos.", {
		size = V(0.35, 0.5, 2.6),
		color = maderaOscura,
		material = Enum.Material.Wood,
	}, {
		{ nombre = "Arco", size = V(3, 0.2, 0.3), cf = CFrame.new(0, 0.1, -1.1), color = rgb(70, 70, 76), material = Enum.Material.Metal },
		{ nombre = "Flecha", size = V(0.1, 0.1, 2.2), cf = CFrame.new(0, 0.32, -0.6), color = acero, material = Enum.Material.Metal },
		{ nombre = "Culata", size = V(0.4, 0.7, 0.8), cf = CFrame.new(0, -0.2, 1.1), color = maderaOscura, material = Enum.Material.Wood },
	}, CFrame.new(0, -0.1, 0.5) * CFrame.Angles(math.rad(90), 0, 0))

	plantillas.Lanzapatatas = construir("Lanzapatatas", "Lanzapatatas: ¡PATATAZO!", {
		size = V(0.45, 1, 0.45),
		color = rgb(60, 60, 64),
		material = plastico,
	}, {
		{ nombre = "Tubo", size = V(0.8, 4, 0.8), cf = CFrame.new(0, 2.3, 0), color = rgb(240, 240, 240), material = plastico },
		{ nombre = "Camara", size = V(1.3, 1.3, 1.3), cf = CFrame.new(0, 0.2, 0.3), color = rgb(240, 240, 240), material = plastico },
		{ nombre = "Patata", size = V(0.7, 0.5, 0.7), cf = CFrame.new(0, 4.35, 0), color = rgb(196, 150, 90), material = Enum.Material.Sand },
	}, CFrame.new(0, 0, 0))

	plantillas.Llave = construir("Llave", "Llave inglesa: pesada y rápida.", {
		size = V(0.3, 2.8, 0.5),
		color = metal,
		material = Enum.Material.Metal,
	}, {
		{ nombre = "Cabeza", size = V(0.32, 0.6, 1.4), cf = CFrame.new(0, 1.5, 0), color = metal, material = Enum.Material.Metal },
		{ nombre = "Diente", size = V(0.32, 0.7, 0.32), cf = CFrame.new(0, 2.05, -0.5), color = metal, material = Enum.Material.Metal },
		{ nombre = "Diente", size = V(0.32, 0.7, 0.32), cf = CFrame.new(0, 2.05, 0.5), color = metal, material = Enum.Material.Metal },
		{ nombre = "Mango", size = V(0.36, 1, 0.56), cf = CFrame.new(0, -0.9, 0), color = rgb(170, 40, 36), material = Enum.Material.SmoothPlastic },
	}, CFrame.new(0, -0.9, 0))

	local bateClavos = {
		{ nombre = "Grueso", size = V(0.62, 2, 0.62), cf = CFrame.new(0, 1.2, 0), color = maderaOscura, material = Enum.Material.Wood },
		{ nombre = "Cinta", size = V(0.46, 1.1, 0.46), cf = CFrame.new(0, -1.5, 0), color = cinta, material = Enum.Material.Fabric },
	}
	for i, y in { 0.5, 0.9, 1.3, 1.7, 2.1 } do
		local girar = i % 2 == 0
		table.insert(bateClavos, {
			nombre = "Clavo",
			size = if girar then V(1.1, 0.08, 0.08) else V(0.08, 0.08, 1.1),
			cf = CFrame.new(0, y, 0),
			color = acero,
			material = Enum.Material.Metal,
		})
	end
	plantillas.BateClavos = construir("BateClavos", "Bate con clavos.", {
		size = V(0.4, 4.2, 0.4),
		color = maderaOscura,
		material = Enum.Material.Wood,
	}, bateClavos, CFrame.new(0, -1.5, 0))

	plantillas.Pico = construir("Pico", "Pico de minero: llega un poco más lejos.", {
		size = V(0.32, 4.8, 0.32),
		color = madera,
		material = Enum.Material.Wood,
	}, {
		{ nombre = "Cabeza", size = V(0.3, 0.45, 1.6), cf = CFrame.new(0, 2.25, 0), color = rgb(96, 100, 104), material = Enum.Material.Metal },
		{ nombre = "Punta", size = V(0.22, 0.32, 1.1), cf = CFrame.new(0, 2.05, -1.25) * CFrame.Angles(math.rad(-14), 0, 0), color = acero, material = Enum.Material.Metal },
		{ nombre = "Punta", size = V(0.22, 0.32, 1.1), cf = CFrame.new(0, 2.05, 1.25) * CFrame.Angles(math.rad(14), 0, 0), color = acero, material = Enum.Material.Metal },
	}, CFrame.new(0, -1.4, 0))

	plantillas.Lanza = construir("Lanza", "Lanza de chatarra: la que más lejos llega.", {
		size = V(0.28, 7, 0.28),
		color = maderaOscura,
		material = Enum.Material.Wood,
	}, {
		{ nombre = "Punta", size = V(0.12, 1.4, 0.5), cf = CFrame.new(0, 4.15, 0), color = acero, material = Enum.Material.Metal },
		{ nombre = "Atadura", size = V(0.4, 0.6, 0.4), cf = CFrame.new(0, 3.3, 0), color = rgb(150, 120, 80), material = Enum.Material.Fabric },
	}, CFrame.new(0, -1.6, 0))

	plantillas.Mazo = construir("Mazo", "Mazo: lento, pero aplasta.", {
		size = V(0.42, 4.6, 0.42),
		color = madera,
		material = Enum.Material.Wood,
	}, {
		{ nombre = "Cabeza", size = V(1.1, 1.1, 2.3), cf = CFrame.new(0, 2.55, 0), color = rgb(64, 66, 72), material = Enum.Material.Metal },
		{ nombre = "Cinta", size = V(0.5, 1, 0.5), cf = CFrame.new(0, -1.7, 0), color = cinta, material = Enum.Material.Fabric },
	}, CFrame.new(0, -1.7, 0))

	local motosierra = construir("Motosierra", "Motosierra: la mejor arma del anillo.", {
		size = V(0.4, 1, 0.4),
		color = cinta,
		material = Enum.Material.SmoothPlastic,
	}, {
		{ nombre = "Motor", size = V(0.9, 1.3, 1.5), cf = CFrame.new(0, 0.9, 0.15), color = rgb(232, 120, 30), material = Enum.Material.SmoothPlastic },
		{ nombre = "Tapa", size = V(0.95, 0.4, 0.9), cf = CFrame.new(0, 1.45, 0.4), color = cinta, material = Enum.Material.SmoothPlastic },
		{ nombre = "Espada", size = V(0.16, 3.4, 0.62), cf = CFrame.new(0, 3.2, -0.1), color = acero, material = Enum.Material.Metal },
		{ nombre = "Cadena", size = V(0.2, 3.5, 0.08), cf = CFrame.new(0, 3.2, -0.44), color = rgb(40, 40, 40), material = Enum.Material.DiamondPlate },
	}, CFrame.new(0, 0, 0))
	local golpe = motosierra:FindFirstChild("Handle") and (motosierra.Handle :: BasePart):FindFirstChild("Golpe") :: Sound?
	if golpe then
		golpe.PlaybackSpeed = 0.6
	end
	plantillas.Motosierra = motosierra

	-- Que el texto al pasar el ratón diga el daño
	for nombre, t in plantillas do
		local a = Config.ARMAS[nombre]
		if a then
			t.ToolTip = if a.empuje
				then string.format("%s  (empujón %d)", t.ToolTip, a.empuje)
				else string.format("%s  (daño a monstruos %d)", t.ToolTip, a.dano)
		end
	end
end

local function destello(modelo: Model)
	local h = Instance.new("Highlight")
	h.FillColor = rgb(255, 255, 255)
	h.FillTransparency = 0.4
	h.OutlineTransparency = 1
	h.Parent = modelo
	task.delay(0.15, function()
		h:Destroy()
	end)
end

-- 💥 Cartelito de cómic encima de quien recibe un empujón
local ONOMATOPEYAS = { "¡PUM!", "¡PAF!", "¡PLONC!", "¡ZAS!", "¡BOING!", "¡TOMA!" }
local function onomatopeya(cabeza: BasePart)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(120, 50)
	bb.StudsOffset = V(0, 2.5, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 80
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.FredokaOne
	t.TextScaled = true
	t.TextColor3 = rgb(255, 220, 40)
	t.Text = ONOMATOPEYAS[math.random(1, #ONOMATOPEYAS)]
	t.Rotation = math.random(-15, 15)
	t.Parent = bb
	local borde = Instance.new("UIStroke")
	borde.Thickness = 3
	borde.Color = rgb(20, 20, 30)
	borde.Parent = t
	bb.Parent = cabeza
	TweenService:Create(bb, TweenInfo.new(0.7), { StudsOffset = V(0, 4.5, 0) }):Play()
	TweenService:Create(t, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { TextTransparency = 1 }):Play()
	TweenService:Create(borde, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Transparency = 1 }):Play()
	task.delay(0.8, function()
		bb:Destroy()
	end)
end

local function animarGolpe(tool: Tool)
	local anim = Instance.new("StringValue")
	anim.Name = "toolanim"
	anim.Value = "Slash"
	anim.Parent = tool
	local sonido = tool:FindFirstChild("Handle") and (tool.Handle :: BasePart):FindFirstChild("Golpe") :: Sound?
	if sonido then
		sonido:Play()
	end
end

-- Daño a un monstruo (y cuenta para las estadísticas si cae).
local function danarMonstruo(jugador: Player, enemigo: Model, eHum: Humanoid, dano: number)
	if eHum.Health <= 0 then
		return
	end
	eHum:TakeDamage(dano)
	destello(enemigo)
	if eHum.Health <= 0 then
		Estadisticas.sumar(jugador, "Enemigos")
		if enemigo:GetAttribute("Tipo") == "Coloso" then
			Estadisticas.sumar(jugador, "Colosos")
		end
	end
end

-- Cuerpo a cuerpo
local function golpear(jugador: Player, tool: Tool, stats)
	local personaje = jugador.Character
	local raiz = personaje and personaje:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not personaje or not raiz then
		return
	end
	local ahora = os.clock()
	animarGolpe(tool)

	local frente = raiz.CFrame.LookVector
	local function enAlcance(otra: BasePart): boolean
		local dir = otra.Position - raiz.Position
		local distancia = dir.Magnitude
		local alcance = stats.alcance + otra.Size.X / 2
		return distancia <= alcance and (distancia < 2.5 or frente:Dot(dir.Unit) > 0.25)
	end

	-- Monstruos
	for _, enemigo in CollectionService:GetTagged("Enemigo") do
		local eRaiz = enemigo:FindFirstChild("HumanoidRootPart") :: BasePart?
		local eHum = enemigo:FindFirstChildOfClass("Humanoid")
		if eRaiz and eHum and eHum.Health > 0 and enAlcance(eRaiz) then
			danarMonstruo(jugador, enemigo, eHum, stats.dano)
		end
	end

	-- Otros jugadores: solo las armas de mano (poco daño y un empujón)
	if not stats.empuje then
		return
	end
	for _, otro in Players:GetPlayers() do
		local c = otro.Character
		if otro ~= jugador and c then
			local oRaiz = c:FindFirstChild("HumanoidRootPart") :: BasePart?
			local oHum = c:FindFirstChildOfClass("Humanoid")
			if oRaiz and oHum and oHum.Health > 0 and not c:FindFirstChildOfClass("ForceField") and enAlcance(oRaiz) then
				ultimoAtacante[otro] = { jugador = jugador, t = ahora }
				if (stats.danoJugador or 0) > 0 then
					Defensa.danar(otro, oHum, stats.danoJugador, true)
				end
				-- Empujón (lo aplica la pantalla del que lo recibe, que es quien mueve su personaje)
				local dir = oRaiz.Position - raiz.Position
				dir = V(dir.X, 0, dir.Z)
				dir = if dir.Magnitude > 0.1 then dir.Unit else frente
				local fuerza = stats.empuje * (if otro:GetAttribute("EnSuBase") then 0.5 else 1)
				Estado.remotos.Empujon:FireClient(otro, dir * fuerza + V(0, fuerza * 0.45, 0))
				destello(c)
				local cabeza = c:FindFirstChild("Head") :: BasePart?
				if cabeza then
					onomatopeya(cabeza)
				end
			end
		end
	end
end

-- 🎯 Busca el monstruo al que apuntas: el más cercano que tengas delante (arriba o abajo da igual)
local function objetivo(personaje: Model, raiz: BasePart, rango: number): (Model?, BasePart?)
	local frente = V(raiz.CFrame.LookVector.X, 0, raiz.CFrame.LookVector.Z)
	if frente.Magnitude < 0.1 then
		return nil, nil
	end
	frente = frente.Unit
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local mejor, mejorRaiz, mejorD = nil, nil, math.huge
	for _, enemigo in CollectionService:GetTagged("Enemigo") do
		local eRaiz = enemigo:FindFirstChild("HumanoidRootPart") :: BasePart?
		local eHum = enemigo:FindFirstChildOfClass("Humanoid")
		if eRaiz and eHum and eHum.Health > 0 then
			local dir = eRaiz.Position - raiz.Position
			local d = dir.Magnitude
			local plano = V(dir.X, 0, dir.Z)
			if d <= rango and d < mejorD and plano.Magnitude > 0.1 and frente:Dot(plano.Unit) > 0.8 then
				-- ¿Se le ve? (que no haya una pared o el suelo en medio)
				params.FilterDescendantsInstances = { personaje, enemigo }
				local res = workspace:Raycast(raiz.Position + V(0, 1.5, 0), eRaiz.Position - raiz.Position - V(0, 1.5, 0), params)
				local inst = res and res.Instance
				if not res or (inst and not inst.CanCollide) then
					mejor, mejorRaiz, mejorD = enemigo, eRaiz, d
				end
			end
		end
	end
	return mejor, mejorRaiz
end

local PROYECTILES = {
	piedra = { size = V(0.5, 0.5, 0.5), color = rgb(130, 130, 130), forma = Enum.PartType.Ball, velocidad = 110 },
	flecha = { size = V(0.15, 0.15, 2.2), color = rgb(150, 110, 70), forma = Enum.PartType.Block, velocidad = 170 },
	patata = { size = V(0.9, 0.7, 0.9), color = rgb(196, 150, 90), forma = Enum.PartType.Ball, velocidad = 90 },
}

local function disparar(jugador: Player, tool: Tool, stats)
	local personaje = jugador.Character
	local raiz = personaje and personaje:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not personaje or not raiz then
		return
	end
	local sonido = tool:FindFirstChild("Handle") and (tool.Handle :: BasePart):FindFirstChild("Golpe") :: Sound?
	if sonido then
		sonido:Play()
	end
	local mano = tool:FindFirstChild("Handle") :: BasePart?
	local desde = if mano then mano.Position else raiz.Position + V(0, 1.5, 0)
	local enemigo, eRaiz = objetivo(personaje, raiz, stats.rango)
	local hasta = if eRaiz then eRaiz.Position else desde + raiz.CFrame.LookVector * stats.rango
	local info = PROYECTILES[stats.proyectil] or PROYECTILES.piedra

	local p = Instance.new("Part")
	p.Name = "Proyectil"
	p.Shape = info.forma
	p.Size = info.size
	p.Color = info.color
	p.Material = Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CFrame = CFrame.lookAt(desde, hasta)
	p.Parent = workspace
	local duracion = math.max((hasta - desde).Magnitude / info.velocidad, 0.05)
	TweenService:Create(p, TweenInfo.new(duracion, Enum.EasingStyle.Linear), { CFrame = CFrame.lookAt(hasta, hasta + (hasta - desde).Unit) }):Play()
	task.delay(duracion, function()
		p:Destroy()
		if enemigo and enemigo.Parent then
			local eHum = enemigo:FindFirstChildOfClass("Humanoid")
			if eHum then
				danarMonstruo(jugador, enemigo, eHum, stats.dano)
			end
		end
	end)
end

local function usar(jugador: Player, tool: Tool, stats)
	local personaje = jugador.Character
	if not personaje or tool.Parent ~= personaje then
		return
	end
	local raiz = personaje:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = personaje:FindFirstChildOfClass("Humanoid")
	if not raiz or not hum or hum.Health <= 0 or raiz.Anchored then
		return
	end
	local ahora = os.clock()
	if ultimoGolpe[tool] and ahora - ultimoGolpe[tool] < stats.cadencia then
		return
	end
	ultimoGolpe[tool] = ahora
	if stats.rango then
		disparar(jugador, tool, stats)
	else
		golpear(jugador, tool, stats)
	end
end

-- Da una herramienta al jugador (si no la tiene ya).
function Armas.dar(jugador: Player, nombre: string)
	local mochila = jugador:FindFirstChildOfClass("Backpack")
	if not mochila or not plantillas[nombre] then
		return
	end
	if mochila:FindFirstChild(nombre) or (jugador.Character and jugador.Character:FindFirstChild(nombre)) then
		return
	end
	local t = plantillas[nombre]:Clone()
	local stats = Config.ARMAS[nombre]
	t.Activated:Connect(function()
		usar(jugador, t, stats)
	end)
	t.Destroying:Connect(function()
		ultimoGolpe[t] = nil
	end)
	t.Parent = mochila
end

-- La mejor arma que tiene el jugador de un grupo (o nil si no tiene ninguna).
function Armas.mejor(jugador: Player, grupo): string?
	local mejor = nil
	for _, nombre in grupo.lista do
		if Config.ARMAS_GRATIS[nombre] or jugador:GetAttribute("Mejora_" .. nombre) == true then
			mejor = nombre
		end
	end
	return mejor
end

-- Le deja la mejor arma de cada grupo (al aparecer o al fabricar una nueva).
local function darArmas(jugador: Player)
	local quedan = {}
	for _, grupo in Config.GRUPOS_ARMAS do
		local mejor = Armas.mejor(jugador, grupo)
		jugador:SetAttribute(grupo.atributo, mejor)
		if mejor then
			quedan[mejor] = true
		end
	end
	for _, sitio in { jugador:FindFirstChildOfClass("Backpack"), jugador.Character } do
		if sitio then
			for _, t in sitio:GetChildren() do
				if t:IsA("Tool") and Config.ARMAS[t.Name] and not quedan[t.Name] then
					t:Destroy()
				end
			end
		end
	end
	for _, grupo in Config.GRUPOS_ARMAS do
		local mejor = jugador:GetAttribute(grupo.atributo)
		if mejor then
			Armas.dar(jugador, mejor)
		end
	end
end

function Armas.iniciar()
	crearPlantillas()

	local function alEntrar(jugador: Player)
		jugador.CharacterAdded:Connect(function(personaje)
			jugador:WaitForChild("Backpack", 10)
			darArmas(jugador)
			local hum = personaje:WaitForChild("Humanoid", 10) :: Humanoid?
			if hum then
				hum.Died:Connect(function()
					local info = ultimoAtacante[jugador]
					ultimoAtacante[jugador] = nil
					if info and os.clock() - info.t < 8 and info.jugador.Parent then
						Estado.notificar(info.jugador, "⚔️ Has derribado a " .. jugador.DisplayName .. ". ¡Su mochila está en el suelo!", rgb(255, 200, 120))
						Estado.notificar(jugador, "⚔️ " .. info.jugador.DisplayName .. " te ha derribado.", rgb(255, 120, 120))
					end
				end)
			end
		end)
		if jugador.Character then
			task.spawn(darArmas, jugador)
		end
	end
	Players.PlayerAdded:Connect(alEntrar)
	for _, jugador in Players:GetPlayers() do
		alEntrar(jugador)
	end
	Players.PlayerRemoving:Connect(function(jugador)
		ultimoAtacante[jugador] = nil
	end)
	Estado.escuchar("MejorasCambian", function(jugador: Player)
		if jugador.Character then
			darArmas(jugador)
		end
	end)
end

return Armas
