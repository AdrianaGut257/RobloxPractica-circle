-- 📊 Estadísticas de cada jugador: días sobrevividos, rachas, muertes, enemigos, cajas, robos...
-- Se guardan con el resto del progreso (Datos) y la pantalla las lee de los atributos del jugador:
--   E_<id>  → total de siempre (se guarda)
--   P_<id>  → solo en esta partida
--   Racha   → días seguidos sin caer (ahora mismo)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Estado = require(script.Parent.Estado)

local Estadisticas = {}

local CAMPOS: { [string]: any } = {}
for _, e in Config.ESTADISTICAS do
	CAMPOS[e.id] = e
end

local function leer(jugador: Player, clave: string): number
	local v = jugador:GetAttribute(clave)
	return if type(v) == "number" then v else 0
end

-- Suma n a una estadística (total y partida).
function Estadisticas.sumar(jugador: Player, id: string, n: number?)
	if not CAMPOS[id] or not jugador.Parent then
		return
	end
	n = n or 1
	jugador:SetAttribute("E_" .. id, leer(jugador, "E_" .. id) + n)
	jugador:SetAttribute("P_" .. id, leer(jugador, "P_" .. id) + n)
end

-- Para récords: se queda con el valor más alto.
function Estadisticas.record(jugador: Player, id: string, valor: number)
	if not CAMPOS[id] or not jugador.Parent then
		return
	end
	if valor > leer(jugador, "E_" .. id) then
		jugador:SetAttribute("E_" .. id, valor)
	end
	if valor > leer(jugador, "P_" .. id) then
		jugador:SetAttribute("P_" .. id, valor)
	end
end

-- Pone las estadísticas guardadas (al entrar).
function Estadisticas.cargar(jugador: Player, guardadas)
	guardadas = if type(guardadas) == "table" then guardadas else {}
	for id in CAMPOS do
		local v = guardadas[id]
		jugador:SetAttribute("E_" .. id, if type(v) == "number" and v >= 0 then math.floor(v) else 0)
		jugador:SetAttribute("P_" .. id, 0)
	end
	jugador:SetAttribute("Racha", 0)
end

-- Lo que se guarda.
function Estadisticas.exportar(jugador: Player)
	local t = {}
	for id in CAMPOS do
		t[id] = leer(jugador, "E_" .. id)
	end
	return t
end

-- Cuando el jugador cae.
function Estadisticas.muerte(jugador: Player)
	Estadisticas.sumar(jugador, "Muertes")
	jugador:SetAttribute("Racha", 0)
end

local function vivo(jugador: Player): boolean
	local c = jugador.Character
	local hum = c and c:FindFirstChildOfClass("Humanoid")
	return hum ~= nil and hum.Health > 0
end

function Estadisticas.iniciar()
	-- 🌅 Cada amanecer: un día más para los que siguen en pie
	Estado.escuchar("DiaEmpieza", function(dia: number)
		if dia <= 1 then
			return
		end
		for _, jugador in Players:GetPlayers() do
			if vivo(jugador) then
				Estadisticas.sumar(jugador, "Dias")
				local racha = leer(jugador, "Racha") + 1
				jugador:SetAttribute("Racha", racha)
				Estadisticas.record(jugador, "MejorRacha", racha)
			end
		end
	end)

	-- 💰 Récord de reserva
	local function vigilar(jugador: Player)
		jugador:GetAttributeChangedSignal("Reserva"):Connect(function()
			local v = jugador:GetAttribute("Reserva")
			if type(v) == "number" then
				Estadisticas.record(jugador, "MejorReserva", v)
			end
		end)
	end
	Players.PlayerAdded:Connect(vigilar)
	for _, jugador in Players:GetPlayers() do
		vigilar(jugador)
	end

	-- ⏱️ Tiempo jugado
	task.spawn(function()
		while true do
			task.wait(60)
			for _, jugador in Players:GetPlayers() do
				Estadisticas.sumar(jugador, "Minutos")
			end
		end
	end)
end

return Estadisticas
