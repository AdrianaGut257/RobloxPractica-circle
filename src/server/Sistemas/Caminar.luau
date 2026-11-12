-- Hace que un enemigo camine hacia un destino.
-- Si el destino está a la vista y no hay nada en medio, va en línea recta; si no, calcula un camino
-- con PathfindingService. Si se atasca, salta y vuelve a calcular.
local PathfindingService = game:GetService("PathfindingService")

local Caminar = {}
Caminar.__index = Caminar

-- Lo que los rayos de "¿lo veo?" ignoran (lo rellenan los sistemas al arrancar).
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
Caminar.params = params
local ignorados: { Instance } = {}

function Caminar.ignorar(objeto: Instance)
	table.insert(ignorados, objeto)
	params.FilterDescendantsInstances = ignorados
end

-- Punto del suelo justo debajo de "pos".
function Caminar.suelo(pos: Vector3): Vector3
	local res = workspace:Raycast(pos + Vector3.new(0, 4, 0), Vector3.new(0, -80, 0), params)
	if res then
		return res.Position + Vector3.new(0, 0.6, 0)
	end
	return pos
end

function Caminar.hayVision(desde: Vector3, hasta: Vector3): boolean
	local res = workspace:Raycast(desde, hasta - desde, params)
	if not res then
		return true
	end
	local modelo = res.Instance:FindFirstAncestorOfClass("Model")
	return modelo ~= nil and modelo:FindFirstChildOfClass("Humanoid") ~= nil
end

-- ¿Cabe el cuerpo entero en línea recta? (dos rayos, uno a cada lado)
local function hayPaso(desde: Vector3, hasta: Vector3, ancho: number): boolean
	local dir = hasta - desde
	local plano = Vector3.new(dir.X, 0, dir.Z)
	if plano.Magnitude < 0.1 then
		return true
	end
	local lado = Vector3.new(-plano.Z, 0, plano.X).Unit * ancho
	return Caminar.hayVision(desde + lado, hasta + lado) and Caminar.hayVision(desde - lado, hasta - lado)
end

-- opciones: { radio, alto }
function Caminar.nuevo(hum: Humanoid, raiz: BasePart, opciones)
	local self = setmetatable({}, Caminar)
	self.hum = hum
	self.raiz = raiz
	self.radio = (opciones.radio or 2) * 0.6
	self.ruta = nil
	self.indice = 1
	self.rutaTiempo = 0
	self.rutaDestino = nil
	self.calculando = false
	self.destino = nil
	self.ultimaPos = raiz.Position
	self.ultimoMovimiento = os.clock()
	self.path = PathfindingService:CreatePath({
		AgentRadius = opciones.radio or 2,
		AgentHeight = opciones.alto or 5,
		AgentCanJump = true,
		WaypointSpacing = 5,
		Costs = { Water = 20 },
	})
	return self
end

function Caminar:ir(destino: Vector3)
	local pos = self.raiz.Position
	local ahora = os.clock()
	self.destino = destino
	local dist = (destino - pos).Magnitude
	if dist < 45 and math.abs(destino.Y - pos.Y) < 4 and hayPaso(pos, destino, self.radio) then
		self.ruta = nil
		self.hum:MoveTo(destino)
	else
		local espera = if self.ruta then 1.5 else 2.5
		local lejos = self.rutaDestino == nil or (self.rutaDestino - destino).Magnitude > 8
		if not self.calculando and (ahora - self.rutaTiempo > espera or (lejos and ahora - self.rutaTiempo > 0.6)) then
			self.calculando = true
			task.spawn(function()
				local ok = pcall(function()
					self.path:ComputeAsync(self.raiz.Position, destino)
				end)
				self.calculando = false
				self.rutaTiempo = os.clock()
				self.rutaDestino = destino
				if ok and self.path.Status == Enum.PathStatus.Success then
					self.ruta = self.path:GetWaypoints()
					self.indice = 2
				else
					self.ruta = nil
				end
			end)
		end

		local siguiente = nil
		if self.ruta then
			local wp = self.ruta[self.indice]
			while wp and (Vector3.new(wp.Position.X, pos.Y, wp.Position.Z) - pos).Magnitude < 2.5 do
				self.indice += 1
				wp = self.ruta[self.indice]
			end
			siguiente = wp
		end
		if siguiente then
			if siguiente.Action == Enum.PathWaypointAction.Jump then
				self.hum.Jump = true
			end
			self.hum:MoveTo(siguiente.Position)
		else
			self.hum:MoveTo(destino)
		end
	end

	-- Si lleva rato atascado lejos de donde quiere ir, salta y recalcula el camino
	local lejosDelDestino = (destino - pos).Magnitude > 6
	if (pos - self.ultimaPos).Magnitude > 1.5 or not lejosDelDestino then
		self.ultimaPos = pos
		self.ultimoMovimiento = ahora
	elseif ahora - self.ultimoMovimiento > 1.5 then
		self.hum.Jump = true
		self.ruta = nil
		self.ultimoMovimiento = ahora
	end
end

function Caminar:parar()
	self.ruta = nil
	self.destino = nil
	self.hum:MoveTo(self.raiz.Position)
	self.ultimaPos = self.raiz.Position
	self.ultimoMovimiento = os.clock()
end

return Caminar
