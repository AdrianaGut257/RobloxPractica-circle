-- Funciones pequeñas para construir el mapa con código.
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local Util = {}

Util.rgb = Color3.fromRGB
Util.azar = Random.new(2026) -- semilla fija: el mapa sale siempre igual
Util.DECO = { Deco = true } -- piezas decorativas: no chocan ni bloquean nada

local M = Enum.Material

-- Propiedades que se tratan aparte (no son propiedades reales de la pieza
-- o tienen que ponerse en un orden concreto).
local ESPECIALES = {
	Parent = true,
	Clase = true,
	Etiqueta = true,
	Atributos = true,
	Deco = true,
	Shape = true,
	Size = true,
	CFrame = true,
	Position = true,
}

-- Crea una pieza con una tabla de propiedades.
-- Extras: Clase ("Part", "WedgePart", "Seat"...), Etiqueta, Atributos, Deco.
function Util.parte(props)
	local p = Instance.new(props.Clase or "Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = M.SmoothPlastic
	if props.Shape then
		p.Shape = props.Shape
	end
	if props.Size then
		p.Size = props.Size
	end
	if props.CFrame then
		p.CFrame = props.CFrame
	elseif props.Position then
		p.Position = props.Position
	end
	if props.Deco then
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
	end
	for clave, valor in props do
		if not ESPECIALES[clave] then
			p[clave] = valor
		end
	end
	if props.Etiqueta then
		CollectionService:AddTag(p, props.Etiqueta)
	end
	if props.Atributos then
		for nombre, valor in props.Atributos do
			p:SetAttribute(nombre, valor)
		end
	end
	p.Parent = props.Parent
	return p
end

local function aCFrame(cf)
	if typeof(cf) == "Vector3" then
		return CFrame.new(cf)
	end
	return cf
end

local function mezclar(base, extra)
	if extra then
		for clave, valor in extra do
			base[clave] = valor
		end
	end
	return base
end

-- Bloque normal. cf puede ser un CFrame o una posición (Vector3).
function Util.bloque(padre, size: Vector3, cf, color: Color3, material, extra)
	return Util.parte(mezclar({
		Parent = padre,
		Size = size,
		CFrame = aCFrame(cf),
		Color = color,
		Material = material or M.SmoothPlastic,
	}, extra))
end

-- Esfera.
function Util.bola(padre, diametro: number, pos: Vector3, color: Color3, material, extra)
	return Util.parte(mezclar({
		Parent = padre,
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(diametro, diametro, diametro),
		CFrame = CFrame.new(pos),
		Color = color,
		Material = material or M.SmoothPlastic,
	}, extra))
end

-- Esfera estirada (elipsoide). Se ve redonda pero choca como un bloque,
-- así que normalmente se usa como decoración (copas de árbol, arbustos...).
function Util.elipsoide(padre, size: Vector3, cf, color: Color3, material, extra)
	local p = Util.parte(mezclar({
		Parent = padre,
		Size = size,
		CFrame = aCFrame(cf),
		Color = color,
		Material = material or M.SmoothPlastic,
	}, extra))
	local malla = Instance.new("SpecialMesh")
	malla.MeshType = Enum.MeshType.Sphere
	malla.Parent = p
	return p
end

-- Cilindro tumbado: su eje va por el eje X del CFrame.
function Util.cilindro(padre, diametro: number, largo: number, cf, color: Color3, material, extra)
	return Util.parte(mezclar({
		Parent = padre,
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(largo, diametro, diametro),
		CFrame = aCFrame(cf),
		Color = color,
		Material = material or M.SmoothPlastic,
	}, extra))
end

-- Cilindro de pie, centrado en "centro".
function Util.cilindroV(padre, diametro: number, alto: number, centro: Vector3, color: Color3, material, extra)
	return Util.cilindro(padre, diametro, alto, CFrame.new(centro) * CFrame.Angles(0, 0, math.pi / 2), color, material, extra)
end

-- Cuña. Su lado alto queda hacia el +Z del CFrame.
function Util.cuna(padre, size: Vector3, cf, color: Color3, material, extra)
	return Util.parte(mezclar({
		Clase = "WedgePart",
		Parent = padre,
		Size = size,
		CFrame = aCFrame(cf),
		Color = color,
		Material = material or M.SmoothPlastic,
	}, extra))
end

-- Losa inclinada cuya cara de arriba va del punto a al punto b (rampas, escaleras, puentes).
function Util.rampa(padre, ancho: number, a: Vector3, b: Vector3, color: Color3, material, extra, grosor: number?)
	local g = grosor or 1
	local largo = (b - a).Magnitude
	local cf = CFrame.lookAt((a + b) / 2, b) * CFrame.new(0, -g / 2, 0)
	return Util.bloque(padre, Vector3.new(ancho, g, largo), cf, color, material, extra)
end

-- Barra entre dos puntos (ramas, arcos, barandillas).
function Util.barra(padre, grosor: number, a: Vector3, b: Vector3, color: Color3, material, extra)
	local largo = (b - a).Magnitude
	local cf = CFrame.lookAt((a + b) / 2, b)
	return Util.bloque(padre, Vector3.new(grosor, grosor, largo), cf, color, material, extra)
end

-- Frontón triangular (como el de un tejado a dos aguas visto de frente).
-- centroBase: punto medio del lado de abajo. El triángulo queda en el plano X-Y.
function Util.fronton(padre, centroBase: Vector3, ancho: number, alto: number, fondo: number, color: Color3, material, extra)
	local mitad = ancho / 2
	Util.cuna(
		padre,
		Vector3.new(fondo, alto, mitad),
		CFrame.new(centroBase + Vector3.new(-mitad / 2, alto / 2, 0)) * CFrame.Angles(0, math.pi / 2, 0),
		color,
		material,
		extra
	)
	Util.cuna(
		padre,
		Vector3.new(fondo, alto, mitad),
		CFrame.new(centroBase + Vector3.new(mitad / 2, alto / 2, 0)) * CFrame.Angles(0, -math.pi / 2, 0),
		color,
		material,
		extra
	)
end

function Util.carpeta(nombre: string, padre: Instance?)
	local c = Instance.new("Folder")
	c.Name = nombre
	c.Parent = padre
	return c
end

function Util.modelo(nombre: string, padre: Instance?)
	local m = Instance.new("Model")
	m.Name = nombre
	m.Parent = padre
	return m
end

function Util.etiquetar(objeto: Instance, etiqueta: string)
	CollectionService:AddTag(objeto, etiqueta)
	return objeto
end

function Util.luz(parte: Instance, color: Color3, rango: number, brillo: number, sombras: boolean?)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = rango
	l.Brightness = brillo
	l.Shadows = sombras == true
	l.Parent = parte
	return l
end

function Util.prompt(parte: Instance, accion: string, objeto: string, duracion: number?, distancia: number?)
	local p = Instance.new("ProximityPrompt")
	p.ActionText = accion
	p.ObjectText = objeto
	p.HoldDuration = duracion or 0
	p.MaxActivationDistance = distancia or 10
	p.RequiresLineOfSight = false
	p.Parent = parte
	return p
end

function Util.particulas(parte: Instance, props)
	local e = Instance.new("ParticleEmitter")
	for clave, valor in props do
		e[clave] = valor
	end
	e.Parent = parte
	return e
end

function Util.soldar(a: BasePart, b: BasePart)
	local w = Instance.new("WeldConstraint")
	w.Part0 = a
	w.Part1 = b
	w.Parent = a
	return w
end

-- Mueve un modelo poco a poco hasta "destino" (para abrir puertas y verjas).
function Util.pivotar(modelo: Model, destino: CFrame, duracion: number)
	local inicio = modelo:GetPivot()
	local valor = Instance.new("NumberValue")
	local conexion = valor.Changed:Connect(function(alfa)
		modelo:PivotTo(inicio:Lerp(destino, alfa))
	end)
	local tween = TweenService:Create(
		valor,
		TweenInfo.new(duracion, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
		{ Value = 1 }
	)
	tween.Completed:Connect(function()
		conexion:Disconnect()
		valor:Destroy()
		modelo:PivotTo(destino)
	end)
	tween:Play()
	return tween
end

-- Hace transparente un objeto (y lo que tiene dentro) y luego lo borra.
function Util.desvanecer(objeto: Instance, duracion: number)
	local partes = {}
	if objeto:IsA("BasePart") then
		table.insert(partes, objeto)
	end
	for _, d in objeto:GetDescendants() do
		if d:IsA("BasePart") then
			table.insert(partes, d)
		elseif d:IsA("Decal") then
			d:Destroy()
		end
	end
	for _, p in partes do
		p.CanCollide = false
		TweenService:Create(p, TweenInfo.new(duracion), { Transparency = 1 }):Play()
	end
	task.delay(duracion, function()
		objeto:Destroy()
	end)
end

function Util.elegir(lista)
	return lista[Util.azar:NextInteger(1, #lista)]
end

function Util.entre(a: number, b: number): number
	return Util.azar:NextNumber(a, b)
end

-- Terreno
function Util.terreno(centro: Vector3, size: Vector3, material: Enum.Material)
	workspace.Terrain:FillBlock(CFrame.new(centro), size, material)
end

function Util.terrenoCilindro(centro: Vector3, alto: number, radio: number, material: Enum.Material)
	workspace.Terrain:FillCylinder(CFrame.new(centro), alto, radio, material)
end

function Util.terrenoBola(centro: Vector3, radio: number, material: Enum.Material)
	workspace.Terrain:FillBall(centro, radio, material)
end

-- Rampa de terreno: la parte alta queda hacia el +Z del CFrame.
function Util.terrenoCuna(cf: CFrame, size: Vector3, material: Enum.Material)
	workspace.Terrain:FillWedge(cf, size, material)
end

-- Distancia en el plano (ignora la altura).
function Util.dist2D(a: Vector3, b: Vector3): number
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

-- Pared invisible que no deja pasar (bordes del mapa).
function Util.muroInvisible(padre, a: Vector3, b: Vector3, alto: number?)
	local h = alto or 80
	local largo = Vector3.new(b.X - a.X, 0, b.Z - a.Z).Magnitude
	local centro = Vector3.new((a.X + b.X) / 2, h / 2 - 4, (a.Z + b.Z) / 2)
	return Util.parte({
		Parent = padre,
		Name = "MuroInvisible",
		Size = Vector3.new(2, h, largo),
		CFrame = CFrame.lookAt(centro, Vector3.new(b.X, centro.Y, b.Z)),
		Transparency = 1,
		CanQuery = false,
		CanTouch = false,
	})
end

-- Cartel de texto en una cara de una pieza.
function Util.letrero(parte: BasePart, cara: Enum.NormalId, texto: string, color: Color3?, fuente: Enum.Font?)
	local gui = Instance.new("SurfaceGui")
	gui.Face = cara
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0.6
	gui.Parent = parte
	local etiqueta = Instance.new("TextLabel")
	etiqueta.Size = UDim2.fromScale(1, 1)
	etiqueta.BackgroundTransparency = 1
	etiqueta.Text = texto
	etiqueta.TextScaled = true
	etiqueta.TextWrapped = true
	etiqueta.Font = fuente or Enum.Font.Garamond
	etiqueta.TextColor3 = color or Color3.fromRGB(245, 235, 210)
	etiqueta.Parent = gui
	local margen = Instance.new("UIPadding")
	margen.PaddingLeft = UDim.new(0.06, 0)
	margen.PaddingRight = UDim.new(0.06, 0)
	margen.PaddingTop = UDim.new(0.08, 0)
	margen.PaddingBottom = UDim.new(0.08, 0)
	margen.Parent = etiqueta
	return gui
end


-- Marca una pieza como "suelo que se puede pisar" (las cajas de la lluvia pueden caer encima).
function Util.pisable(p: BasePart)
	p:SetAttribute("Pisable", true)
	return p
end

-- Muestra u oculta un modelo entero (para las mejoras de la base que aparecen al comprarlas).
-- La primera vez apunta la transparencia y la colisión originales de cada pieza.
function Util.mostrar(objeto: Instance, visible: boolean)
	local lista = objeto:GetDescendants()
	if objeto:IsA("BasePart") then
		table.insert(lista, objeto)
	end
	for _, d in lista do
		if d:IsA("BasePart") then
			if d:GetAttribute("T0") == nil then
				d:SetAttribute("T0", d.Transparency)
				d:SetAttribute("C0", d.CanCollide)
			end
			d.Transparency = if visible then d:GetAttribute("T0") else 1
			d.CanCollide = visible and d:GetAttribute("C0") == true
		elseif d:IsA("Light") or d:IsA("ParticleEmitter") or d:IsA("Fire") or d:IsA("Smoke") then
			(d :: any).Enabled = visible
		elseif d:IsA("SurfaceGui") or d:IsA("BillboardGui") then
			d.Enabled = visible
		end
	end
end

-- Muro invisible redondo (el borde del mapa).
function Util.muroCircular(padre, radio: number, segmentos: number, alto: number)
	local f = Util.carpeta("Borde", padre)
	for i = 0, segmentos - 1 do
		local a1 = i / segmentos * math.pi * 2
		local a2 = (i + 1) / segmentos * math.pi * 2
		Util.muroInvisible(
			f,
			Vector3.new(math.cos(a1) * radio, 0, math.sin(a1) * radio),
			Vector3.new(math.cos(a2) * radio, 0, math.sin(a2) * radio),
			alto
		)
	end
	return f
end

-- Barandilla de postes y cuerdas entre dos puntos (a la altura del suelo que pisas).
function Util.barandilla(padre, a: Vector3, b: Vector3, color: Color3, material, alto: number?)
	local h = alto or 3.4
	local largo = (b - a).Magnitude
	local n = math.max(1, math.ceil(largo / 8))
	for i = 0, n do
		local p = a:Lerp(b, i / n)
		Util.bloque(padre, Vector3.new(0.5, h, 0.5), p + Vector3.new(0, h / 2, 0), color, material)
	end
	Util.barra(padre, 0.35, a + Vector3.new(0, h, 0), b + Vector3.new(0, h, 0), color, material)
	Util.barra(padre, 0.25, a + Vector3.new(0, h * 0.5, 0), b + Vector3.new(0, h * 0.5, 0), color, material, Util.DECO)
end

return Util
