-- Efectos del lado del jugador:
--   · Trepar por las cuerdas: W sube, S baja, Espacio te suelta (en móvil, el joystick y el botón de saltar).
--   · Mover tu personaje por las tirolinas (el servidor dice por dónde).
--   · Los empujones de las armas de mano.
--   · Enseñar solo los botones que te tocan en cada base ("Abrir" en la tuya, "Robar" en las demás).
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Interfaz = require(script.Parent.Interfaz)

local Efectos = {}

local jugador = Players.LocalPlayer
local moviendo = false

-- 🧗🚡 Recorrer una lista de puntos. El personaje no se ancla (así los demás te ven moverte):
-- se coloca en cada fotograma y se le quita la velocidad para que no caiga.
function Efectos.recorrido(puntos: { Vector3 }, velocidad: number, tipo: string)
	if tipo == "trepar" then
		Efectos.trepar(puntos :: any, velocidad)
		return
	end
	if moviendo or type(puntos) ~= "table" or #puntos == 0 then
		return
	end
	local personaje = jugador.Character
	local raiz = personaje and personaje:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = personaje and personaje:FindFirstChildOfClass("Humanoid")
	if not raiz or not hum or hum.Health <= 0 then
		return
	end
	moviendo = true
	local camara = workspace.CurrentCamera
	local fovOriginal = camara and camara.FieldOfView or 70
	if tipo == "tirolina" and camara then
		TweenService:Create(camara, TweenInfo.new(0.6), { FieldOfView = fovOriginal + 14 }):Play()
	end
	local ok, err = pcall(function()
		hum.PlatformStand = true
		local lista = { raiz.Position }
		for _, p in puntos do
			if typeof(p) == "Vector3" then
				table.insert(lista, p)
			end
		end
		local mira = raiz.CFrame.LookVector
		mira = Vector3.new(mira.X, 0, mira.Z)
		if tipo == "cuerda" and lista[2] then
			-- Mirando a la cuerda
			local d = Vector3.new(lista[2].X - lista[1].X, 0, lista[2].Z - lista[1].Z)
			if d.Magnitude > 0.5 then
				mira = d.Unit
			end
		end
		for i = 1, #lista - 1 do
			local a, b = lista[i], lista[i + 1]
			local largo = (b - a).Magnitude
			local duracion = math.max(largo / velocidad, 0.05)
			local horizontal = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
			if tipo == "tirolina" and horizontal.Magnitude > 1 then
				mira = horizontal.Unit
			end
			if mira.Magnitude < 0.1 then
				mira = Vector3.new(0, 0, -1)
			end
			local t = 0
			while t < duracion do
				t += RunService.Heartbeat:Wait()
				if not raiz.Parent or hum.Health <= 0 then
					return
				end
				local p = a:Lerp(b, math.min(1, t / duracion))
				raiz.CFrame = CFrame.lookAt(p, p + mira)
				raiz.AssemblyLinearVelocity = Vector3.zero
				raiz.AssemblyAngularVelocity = Vector3.zero
			end
		end
	end)
	if raiz.Parent then
		hum.PlatformStand = false
		raiz.AssemblyLinearVelocity = Vector3.zero
		hum:ChangeState(Enum.HumanoidStateType.Freefall)
	end
	if camara then
		TweenService:Create(camara, TweenInfo.new(0.5), { FieldOfView = fovOriginal }):Play()
	end
	moviendo = false
	if not ok then
		warn("[Efectos] Error en el recorrido: " .. tostring(err))
	end
end

-- 🧗 Trepar ---------------------------------------------------------------------------------------

-- Lo que el jugador quiere hacer: 1 subir, -1 bajar, 0 quedarse.
-- Se usa el control de Roblox (vale para teclado W/S y flechas, mando y joystick del móvil).
local controles: any = nil
local function direccionTrepar(): number
	if controles == nil then
		local ok, res = pcall(function()
			local modulo = jugador:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule", 5)
			return (require(modulo :: ModuleScript) :: any):GetControls()
		end)
		controles = if ok and res then res else false
	end
	if controles then
		local ok, v = pcall(function()
			return controles:GetMoveVector()
		end)
		if ok and typeof(v) == "Vector3" then
			return if v.Z < -0.3 then 1 elseif v.Z > 0.3 then -1 else 0
		end
	end
	-- Por si acaso: teclas directas (si no estás escribiendo en el chat)
	if UserInputService:GetFocusedTextBox() then
		return 0
	end
	local sube = UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.Up)
	local baja = UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.Down)
	return (if sube then 1 else 0) - (if baja then 1 else 0)
end

-- Cartelito con las teclas mientras trepas
local ayudaTrepar: Frame? = nil
local function mostrarAyudaTrepar(visible: boolean)
	if not ayudaTrepar then
		local gui = Instance.new("ScreenGui")
		gui.Name = "AyudaTrepar"
		gui.ResetOnSpawn = false
		gui.Parent = jugador:WaitForChild("PlayerGui")
		local panel = Interfaz.panel({
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -110),
			Size = UDim2.fromOffset(0, 50),
			AutomaticSize = Enum.AutomaticSize.X,
			Visible = false,
			Parent = gui,
		})
		Interfaz.relleno(0, 18).Parent = panel
		Interfaz.texto({
			TextSize = 20,
			Size = UDim2.fromOffset(0, 50),
			AutomaticSize = Enum.AutomaticSize.X,
			Text = if Interfaz.esMovil()
				then "🧗  Joystick ⬆ subir  ·  ⬇ bajar  ·  Saltar: soltarse"
				else "🧗  W ⬆ subir   ·   S ⬇ bajar   ·   Espacio: soltarse",
			Parent = panel,
		})
		ayudaTrepar = panel
	end
	(ayudaTrepar :: Frame).Visible = visible
end

-- Animación de trepar de Roblox (la del script Animate del personaje)
local function animacionTrepar(personaje: Model, hum: Humanoid): AnimationTrack?
	local ok, pista = pcall(function()
		local animate = personaje:FindFirstChild("Animate")
		local carpeta = animate and animate:FindFirstChild("climb")
		local anim = carpeta and carpeta:FindFirstChildOfClass("Animation")
		local animator = hum:FindFirstChildOfClass("Animator")
		if anim and animator then
			local p = animator:LoadAnimation(anim)
			p.Looped = true
			p.Priority = Enum.AnimationPriority.Action
			return p
		end
		return nil
	end)
	return if ok then pista else nil
end

-- datos = { abajo, arriba, cuelgaAbajo, cuelgaArriba, empieza = "abajo" | "arriba" }
function Efectos.trepar(datos, velocidad: number)
	if moviendo or type(datos) ~= "table" then
		return
	end
	local ca, cA, salidaAbajo, salidaArriba = datos.cuelgaAbajo, datos.cuelgaArriba, datos.abajo, datos.arriba
	for _, v in { ca, cA, salidaAbajo, salidaArriba } do
		if typeof(v) ~= "Vector3" then
			return
		end
	end
	local personaje = jugador.Character
	local raiz = personaje and personaje:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = personaje and personaje:FindFirstChildOfClass("Humanoid")
	if not personaje or not raiz or not hum or hum.Health <= 0 then
		return
	end
	moviendo = true

	-- Mirando a la torre (como en una escalera), un poco separado de la cuerda.
	-- La salida de abajo está por fuera, así que «hacia la torre» es de la salida de abajo a la cuerda.
	local plano = Vector3.new(ca.X - salidaAbajo.X, 0, ca.Z - salidaAbajo.Z)
	if plano.Magnitude < 0.5 then
		plano = Vector3.new(ca.X - raiz.Position.X, 0, ca.Z - raiz.Position.Z)
	end
	local mira = if plano.Magnitude > 0.5 then plano.Unit else Vector3.new(raiz.CFrame.LookVector.X, 0, raiz.CFrame.LookVector.Z).Unit
	local alto = math.max(cA.Y - ca.Y, 1)
	local empiezaArriba = datos.empieza == "arriba"
	local y = if empiezaArriba then alto else 0
	local function enCuerda(h: number): Vector3
		return Vector3.new(ca.X, ca.Y + h, ca.Z) - mira * 1.1
	end
	local function colocar(p: Vector3)
		raiz.CFrame = CFrame.lookAt(p, p + mira)
		raiz.AssemblyLinearVelocity = Vector3.zero
		raiz.AssemblyAngularVelocity = Vector3.zero
	end
	local function deslizar(hasta: Vector3, duracion: number)
		local desde = raiz.Position
		local t = 0
		while t < duracion do
			t += RunService.Heartbeat:Wait()
			if not raiz.Parent or hum.Health <= 0 then
				return
			end
			colocar(desde:Lerp(hasta, math.min(1, t / duracion)))
		end
	end

	local pista: AnimationTrack? = nil
	local salida = "soltar"
	local ok, err = pcall(function()
		hum.PlatformStand = true
		deslizar(enCuerda(y), 0.25)
		mostrarAyudaTrepar(true)
		pista = animacionTrepar(personaje, hum)
		if pista then
			pista:Play(0.15)
			pista:AdjustSpeed(0)
		end
		local soltar = false
		local conexion = UserInputService.JumpRequest:Connect(function()
			soltar = true
		end)
		local tiempo = 0
		while true do
			local dt = RunService.Heartbeat:Wait()
			tiempo += dt
			if not raiz.Parent or hum.Health <= 0 then
				salida = "muerto"
				break
			end
			if soltar and tiempo > 0.3 then
				salida = "soltar"
				break
			end
			local dir = direccionTrepar()
			y = math.clamp(y + dir * velocidad * dt, 0, alto)
			if pista then
				pista:AdjustSpeed(dir)
			end
			colocar(enCuerda(y))
			-- Al llegar a un extremo te bajas de la cuerda (en el extremo donde empezaste,
			-- solo después de un momento: así no te bajas sin querer por llevar la tecla pulsada)
			local puedeVolver = tiempo > 0.6
			if dir > 0 and y >= alto and (not empiezaArriba or puedeVolver) then
				salida = "arriba"
				break
			elseif dir < 0 and y <= 0 and (empiezaArriba or puedeVolver) then
				salida = "abajo"
				break
			end
		end
		conexion:Disconnect()
		if pista then
			pista:Stop(0.2)
		end
		if salida == "arriba" then
			deslizar(salidaArriba, 0.3)
		elseif salida == "abajo" then
			deslizar(salidaAbajo, 0.25)
		end
	end)
	mostrarAyudaTrepar(false)
	if pista and pista.IsPlaying then
		pista:Stop()
	end
	if raiz.Parent then
		hum.PlatformStand = false
		raiz.AssemblyLinearVelocity = if salida == "soltar" then -mira * 10 + Vector3.new(0, 12, 0) else Vector3.zero
		hum:ChangeState(Enum.HumanoidStateType.Freefall)
	end
	moviendo = false
	if not ok then
		warn("[Efectos] Error trepando: " .. tostring(err))
	end
end

-- 🧤 Empujón de un arma de mano (lo aplica tu pantalla porque es la que mueve tu personaje)
function Efectos.empujon(velocidad: Vector3)
	if typeof(velocidad) ~= "Vector3" or moviendo then
		return
	end
	local personaje = jugador.Character
	local raiz = personaje and personaje:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = personaje and personaje:FindFirstChildOfClass("Humanoid")
	if not raiz or not hum or hum.Health <= 0 then
		return
	end
	hum:ChangeState(Enum.HumanoidStateType.Freefall)
	raiz.AssemblyLinearVelocity = velocidad
end

-- 🔘 Botones de cada base según quién eres
local function ajustarBase(base: Instance)
	local dueno = base:GetAttribute("Dueno")
	local esMia = dueno == jugador.UserId
	local almacen = base:FindFirstChild("Almacen")
	local cofre = almacen and almacen:FindFirstChild("Cofre")
	if cofre then
		local abrir = cofre:FindFirstChild("Abrir") :: ProximityPrompt?
		local robar = cofre:FindFirstChild("Robar") :: ProximityPrompt?
		if abrir then
			abrir.Enabled = esMia
		end
		if robar then
			robar.Enabled = dueno ~= nil and not esMia
			robar.ObjectText = "🦹 Almacén de " .. (base:GetAttribute("DuenoNombre") or "alguien")
		end
	end
	local mesa = base:FindFirstChild("Mesa")
	local centro = mesa and mesa:FindFirstChild("Centro")
	local mejorar = centro and centro:FindFirstChild("Mejorar") :: ProximityPrompt?
	if mejorar then
		mejorar.Enabled = esMia
	end
end

local function vigilarBase(base: Instance)
	base:GetAttributeChangedSignal("Dueno"):Connect(function()
		ajustarBase(base)
	end)
	-- Los botones los crea el servidor: espera a que lleguen
	task.spawn(function()
		local almacen = base:WaitForChild("Almacen", 30)
		local cofre = almacen and almacen:WaitForChild("Cofre", 30)
		if cofre then
			cofre:WaitForChild("Abrir", 30)
			cofre:WaitForChild("Robar", 30)
		end
		local mesa = base:WaitForChild("Mesa", 30)
		local centro = mesa and mesa:WaitForChild("Centro", 30)
		if centro then
			centro:WaitForChild("Mejorar", 30)
		end
		ajustarBase(base)
	end)
end

function Efectos.iniciar()
	for _, base in CollectionService:GetTagged("Base") do
		vigilarBase(base)
	end
	CollectionService:GetInstanceAddedSignal("Base"):Connect(vigilarBase)
end

return Efectos
