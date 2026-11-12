-- Cuerdas para subir y bajar de las torres, y tirolinas para bajar deslizándose.
-- Cuerdas: al pulsar E te agarras y TÚ trepas (W sube, S baja, Espacio te suelta).
-- Tirolinas: el viaje es automático. En los dos casos, el servidor dice por dónde y la pantalla
-- del jugador mueve su personaje (así se ve suave). Los enemigos no pueden usarlas: por eso las torres son seguras.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Estado = require(script.Parent.Estado)
local Inventario = require(script.Parent.Inventario)
local Util = require(script.Parent.Parent.Mundo.Util)

local Movilidad = {}

local V = Vector3.new
local ocupado: { [Player]: number } = {}

local function libre(jugador: Player): boolean
	return not ocupado[jugador] or os.clock() > ocupado[jugador]
end

-- Manda al jugador por una lista de puntos.
local function recorrer(jugador: Player, puntos: { Vector3 }, velocidad: number, tipo: string)
	local raiz = Inventario.raiz(jugador)
	if not raiz or not libre(jugador) then
		return
	end
	local largo = (puntos[1] - raiz.Position).Magnitude
	for i = 2, #puntos do
		largo += (puntos[i] - puntos[i - 1]).Magnitude
	end
	ocupado[jugador] = os.clock() + largo / velocidad + 0.5
	Estado.remotos.Recorrido:FireClient(jugador, puntos, velocidad, tipo)
end

function Movilidad.iniciar()
	local M = Config.MOVILIDAD
	for _, cuerda in CollectionService:GetTagged("Cuerda") do
		local abajo = cuerda:FindFirstChild("PuntoAbajo") :: BasePart?
		local arriba = cuerda:FindFirstChild("PuntoArriba") :: BasePart?
		if not abajo or not arriba then
			continue
		end
		local nombre = cuerda:GetAttribute("Nombre") or "la plataforma"
		local subir = Util.prompt(abajo, "Subir", "🧗 Cuerda · " .. nombre, 0.3, 8)
		local bajar = Util.prompt(arriba, "Bajar", "🧗 Cuerda", 0.3, 7)
		subir.ActionText = "Agarrarse"
		bajar.ActionText = "Agarrarse"
		local function agarrarse(jugador: Player, empieza: string)
			if not libre(jugador) or not Inventario.raiz(jugador) then
				return
			end
			ocupado[jugador] = os.clock() + 1
			Estado.remotos.Recorrido:FireClient(jugador, {
				abajo = cuerda:GetAttribute("Abajo"),
				arriba = cuerda:GetAttribute("Arriba"),
				cuelgaAbajo = cuerda:GetAttribute("CuelgaAbajo"),
				cuelgaArriba = cuerda:GetAttribute("CuelgaArriba"),
				empieza = empieza,
			}, M.CUERDA_VELOCIDAD, "trepar")
		end
		subir.Triggered:Connect(function(jugador)
			agarrarse(jugador, "abajo")
		end)
		bajar.Triggered:Connect(function(jugador)
			agarrarse(jugador, "arriba")
		end)
	end

	for _, tirolina in CollectionService:GetTagged("Tirolina") do
		local inicio = tirolina:FindFirstChild("Inicio") :: BasePart?
		if not inicio then
			continue
		end
		local desde = tirolina:GetAttribute("Desde") :: Vector3
		local hasta = tirolina:GetAttribute("Hasta") :: Vector3
		local p = Util.prompt(inicio, "Tirarse", "🚡 Tirolina → " .. (tirolina:GetAttribute("Destino") or "abajo"), 0.3, 8)
		p.KeyboardKeyCode = Enum.KeyCode.E
		p.Triggered:Connect(function(jugador)
			local bajo = V(0, 3.2, 0)
			recorrer(jugador, { desde - bajo, hasta - bajo }, M.TIROLINA_VELOCIDAD, "tirolina")
		end)
	end

	Players.PlayerRemoving:Connect(function(jugador)
		ocupado[jugador] = nil
	end)
end

return Movilidad
