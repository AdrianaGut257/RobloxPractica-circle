-- Construye personajes R6 con piezas (para Lía y para los Brumosos).
local Cuerpos = {}

-- Animaciones R6 de Roblox
Cuerpos.ANIM = {
	andar = "rbxassetid://180426354",
	quieto = "rbxassetid://180435571",
	sentar = "rbxassetid://178130996",
}

-- datos:
--   nombre, escala, vida, velocidad
--   colores = { cabeza, torso, brazos, piernas }
--   transparencia (opcional), brazosAlFrente (como un zombi), grupo (grupo de colisión)
--   cara (textura de la cara, opcional), distanciaNombre (0 = no se ve el nombre)
--   adornos(adorno, partes, en): función para añadir piezas extra
--     adorno(nombre, size, cf, color, material?, unidoA, neon?)
function Cuerpos.crear(datos): Model
	local s = datos.escala or 1
	local col = datos.colores
	local m = Instance.new("Model")
	m.Name = datos.nombre

	local function pieza(nombre: string, size: Vector3, cf: CFrame, color: Color3, choca: boolean)
		local p = Instance.new("Part")
		p.Name = nombre
		p.Size = size * s
		p.CFrame = cf
		p.Color = color
		p.Material = Enum.Material.SmoothPlastic
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.CanCollide = choca
		p.Transparency = datos.transparencia or 0
		p.Parent = m
		return p
	end
	local function en(x: number, y: number, z: number): CFrame
		return CFrame.new(x * s, y * s, z * s)
	end

	local raiz = pieza("HumanoidRootPart", Vector3.new(2, 2, 1), en(0, 0, 0), col.torso, false)
	raiz.Transparency = 1
	local torso = pieza("Torso", Vector3.new(2, 2, 1), en(0, 0, 0), col.torso, true)
	local cabeza = pieza("Head", Vector3.new(2, 1, 1), en(0, 1.5, 0), col.cabeza, true)
	local mallaCabeza = Instance.new("SpecialMesh")
	mallaCabeza.MeshType = Enum.MeshType.Head
	mallaCabeza.Scale = Vector3.new(1.25, 1.25, 1.25)
	mallaCabeza.Parent = cabeza
	if datos.cara then
		local cara = Instance.new("Decal")
		cara.Name = "face"
		cara.Texture = datos.cara
		cara.Face = Enum.NormalId.Front
		cara.Parent = cabeza
	end
	local brazoD = pieza("Right Arm", Vector3.new(1, 2, 1), en(1.5, 0, 0), col.brazos, false)
	local brazoI = pieza("Left Arm", Vector3.new(1, 2, 1), en(-1.5, 0, 0), col.brazos, false)
	local piernaD = pieza("Right Leg", Vector3.new(1, 2, 1), en(0.5, -2, 0), col.piernas, false)
	local piernaI = pieza("Left Leg", Vector3.new(1, 2, 1), en(-0.5, -2, 0), col.piernas, false)
	local partes = {
		raiz = raiz,
		torso = torso,
		cabeza = cabeza,
		brazoD = brazoD,
		brazoI = brazoI,
		piernaD = piernaD,
		piernaI = piernaI,
	}

	-- Adornos: se sueldan al cuerpo antes de crear las articulaciones
	local function adorno(nombre: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, unido: BasePart, neon: boolean?)
		local p = pieza(nombre, size, cf, color, false)
		p.Material = if neon then Enum.Material.Neon else (material or Enum.Material.SmoothPlastic)
		p.Massless = true
		p.CanQuery = false
		p.CanTouch = false
		local w = Instance.new("WeldConstraint")
		w.Part0 = unido
		w.Part1 = p
		w.Parent = p
		return p
	end
	if datos.adornos then
		datos.adornos(adorno, partes, en)
	end

	-- Articulaciones estándar de un R6
	local function motor(nombre: string, p0: BasePart, p1: BasePart, c0: CFrame, c1: CFrame)
		local mo = Instance.new("Motor6D")
		mo.Name = nombre
		mo.Part0 = p0
		mo.Part1 = p1
		mo.C0 = CFrame.new(c0.Position * s) * c0.Rotation
		mo.C1 = CFrame.new(c1.Position * s) * c1.Rotation
		mo.MaxVelocity = 0.1
		mo.Parent = p0
		return mo
	end
	local alzado = if datos.brazosAlFrente then math.rad(80) else 0
	motor("RootJoint", raiz, torso, CFrame.new(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0), CFrame.new(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0))
	motor("Neck", torso, cabeza, CFrame.new(0, 1, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0), CFrame.new(0, -0.5, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0))
	motor(
		"Right Shoulder",
		torso,
		brazoD,
		CFrame.new(1, 0.5, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0) * CFrame.Angles(0, 0, alzado),
		CFrame.new(-0.5, 0.5, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0)
	)
	motor(
		"Left Shoulder",
		torso,
		brazoI,
		CFrame.new(-1, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0) * CFrame.Angles(0, 0, -alzado),
		CFrame.new(0.5, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0)
	)
	motor("Right Hip", torso, piernaD, CFrame.new(1, -1, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), CFrame.new(0.5, 1, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0))
	motor("Left Hip", torso, piernaI, CFrame.new(-1, -1, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0), CFrame.new(-0.5, 1, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0))

	if datos.grupo then
		for _, d in m:GetDescendants() do
			if d:IsA("BasePart") then
				d.CollisionGroup = datos.grupo
			end
		end
	end

	local hum = Instance.new("Humanoid")
	hum.RigType = Enum.HumanoidRigType.R6
	hum.DisplayName = datos.nombre
	hum.MaxHealth = datos.vida or 100
	hum.Health = datos.vida or 100
	hum.WalkSpeed = datos.velocidad or 16
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
	hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.DisplayWhenDamaged
	hum.HealthDisplayDistance = 60
	hum.NameDisplayDistance = datos.distanciaNombre or 0
	hum.Parent = m
	Instance.new("Animator").Parent = hum

	m.PrimaryPart = raiz
	return m
end

-- Carga las animaciones de andar y estar quieto, y las cambia solas según se mueva.
-- Devuelve las pistas para poder usar "sentar" desde fuera.
function Cuerpos.animar(hum: Humanoid, velocidadBase: number)
	local animator = hum:FindFirstChildOfClass("Animator")
	local pistas = {}
	if not animator then
		return pistas
	end
	for nombre, id in Cuerpos.ANIM do
		local ok, pista = pcall(function()
			local anim = Instance.new("Animation")
			anim.AnimationId = id
			return animator:LoadAnimation(anim)
		end)
		if ok and pista then
			pistas[nombre] = pista
		end
	end
	if pistas.sentar then
		pistas.sentar.Priority = Enum.AnimationPriority.Action
	end
	if pistas.andar then
		pistas.andar.Priority = Enum.AnimationPriority.Movement
	end
	if pistas.quieto then
		pistas.quieto.Looped = true
		pistas.quieto:Play(0.3)
	end
	hum.Running:Connect(function(velocidad)
		local andar = pistas.andar
		if not andar then
			return
		end
		if velocidad > 0.5 then
			if not andar.IsPlaying then
				andar:Play(0.2)
			end
			andar:AdjustSpeed(velocidad / velocidadBase)
		elseif andar.IsPlaying then
			andar:Stop(0.2)
		end
	end)
	return pistas
end

return Cuerpos
