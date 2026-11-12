-- 🧩 Plantillas (componentes): árboles «modelo» que se editan a mano en Studio.
--
-- En modo edición viven en Workspace > Plantillas (en el «taller», fuera del mapa) para poder verlos
-- y cambiarlos. Al darle a Play, la carpeta se mueve a ServerStorage y deja de verse.
--
-- Cada plantilla es un Model con el nombre del tipo (Pino, Roble, ArbolSeco). También puede ser una
-- Folder con ese nombre y varios Models dentro: entonces se elige uno al azar para cada árbol.
-- Atributos opcionales de cada plantilla: EscalaMin y EscalaMax (tamaño al azar de cada copia).
--
-- Si no hay plantilla de un tipo, Props construye ese árbol con código como antes.
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Util = require(script.Parent.Util)

local Plantillas = {}

Plantillas.CARPETA = "Plantillas"

-- Tipos que se pueden poner con plantilla y su tamaño al azar por defecto.
Plantillas.TIPOS = {
	Pino = { escalaMin = 0.85, escalaMax = 1.3 },
	Roble = { escalaMin = 0.8, escalaMax = 1.2 },
	ArbolSeco = { escalaMin = 0.75, escalaMax = 1.25 },
}
Plantillas.ORDEN = { "Pino", "Roble", "ArbolSeco" }

-- Cuánto se hunde cada copia en el suelo (para que no flote si el suelo no es plano).
Plantillas.HUNDIR = 0.4

-- Dónde está el taller (fuera del mapa) en modo edición.
Plantillas.TALLER = Vector3.new(0, 20, 620)

function Plantillas.carpeta(): Instance?
	return workspace:FindFirstChild(Plantillas.CARPETA) or ServerStorage:FindFirstChild(Plantillas.CARPETA)
end

-- Al empezar la partida: esconde el taller (lo mueve a ServerStorage).
function Plantillas.guardar()
	if not RunService:IsRunning() then
		return
	end
	local c = workspace:FindFirstChild(Plantillas.CARPETA)
	if c and not ServerStorage:FindFirstChild(Plantillas.CARPETA) then
		c.Parent = ServerStorage
	end
end

-- Lista de modelos que valen para un tipo (o nil si no hay plantilla).
function Plantillas.variantes(tipo: string): { Model }?
	local c = Plantillas.carpeta()
	local x = c and c:FindFirstChild(tipo)
	if not x then
		return nil
	end
	if x:IsA("Model") then
		return { x }
	end
	local lista = {}
	for _, hijo in x:GetChildren() do
		if hijo:IsA("Model") then
			table.insert(lista, hijo)
		end
	end
	return if #lista > 0 then lista else nil
end

-- Caja (alineada con el mundo) que ocupan todas las piezas de un modelo.
function Plantillas.caja(m: Instance): (Vector3?, Vector3?)
	local minimo, maximo = nil, nil
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") then
			local cf, s = p.CFrame, p.Size
			local mitad = Vector3.new(
				math.abs(cf.XVector.X) * s.X + math.abs(cf.YVector.X) * s.Y + math.abs(cf.ZVector.X) * s.Z,
				math.abs(cf.XVector.Y) * s.X + math.abs(cf.YVector.Y) * s.Y + math.abs(cf.ZVector.Y) * s.Z,
				math.abs(cf.XVector.Z) * s.X + math.abs(cf.YVector.Z) * s.Y + math.abs(cf.ZVector.Z) * s.Z
			) / 2
			local a, b = cf.Position - mitad, cf.Position + mitad
			minimo = if minimo then minimo:Min(a) else a
			maximo = if maximo then maximo:Max(b) else b
		end
	end
	if not minimo then
		return nil
	end
	return minimo, maximo
end

-- Punto del suelo donde está apoyado un modelo (centro de abajo).
function Plantillas.apoyo(m: Instance): Vector3?
	local minimo, maximo = Plantillas.caja(m)
	if not minimo then
		return nil
	end
	return Vector3.new((minimo.X + maximo.X) / 2, minimo.Y, (minimo.Z + maximo.Z) / 2)
end

-- Pone una copia de la plantilla `tipo` apoyada en `base` (en el suelo).
-- Devuelve nil si no hay plantilla de ese tipo.
function Plantillas.colocar(tipo: string, padre: Instance?, base: Vector3, escalaExtra: number?, azar: Random?): Model?
	local lista = Plantillas.variantes(tipo)
	if not lista then
		return nil
	end
	azar = azar or Util.azar
	local original = lista[azar:NextInteger(1, #lista)]
	local m = original:Clone()
	m.Name = tipo

	-- Tamaño al azar
	local def = Plantillas.TIPOS[tipo] or { escalaMin = 1, escalaMax = 1 }
	local eMin = tonumber(original:GetAttribute("EscalaMin")) or def.escalaMin
	local eMax = tonumber(original:GetAttribute("EscalaMax")) or def.escalaMax
	local escala = azar:NextNumber(math.min(eMin, eMax), math.max(eMin, eMax)) * (escalaExtra or 1)
	if math.abs(escala - 1) > 0.01 then
		m:ScaleTo(m:GetScale() * escala)
	end

	-- Giro al azar (alrededor del eje vertical)
	local pivote = m:GetPivot()
	m:PivotTo(CFrame.new(pivote.Position) * CFrame.Angles(0, azar:NextNumber(0, math.pi * 2), 0) * pivote.Rotation)

	-- Apoyarlo en el suelo, centrado en `base`
	local apoyo = Plantillas.apoyo(m)
	if apoyo then
		local mover = Vector3.new(base.X, base.Y - Plantillas.HUNDIR, base.Z) - apoyo
		m:PivotTo(CFrame.new(mover) * m:GetPivot())
	end

	-- Que no se caiga nada (los modelos de la Toolbox a veces vienen sin anclar)
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored = true
		end
	end

	m.Parent = padre
	return m
end

return Plantillas
