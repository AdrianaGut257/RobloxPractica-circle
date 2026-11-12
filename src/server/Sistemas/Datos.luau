-- Guardado y marcador.
-- Se guarda lo que tienes en tu almacén (más lo que lleves en la mochila al salir),
-- tus mejoras, cuántos robos has hecho y tus estadísticas (días, muertes, enemigos...).
-- Para que funcione en Studio: Game Settings > Security > Enable Studio Access to API Services.
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Datos = {}

local almacen: DataStore? = nil
local cargados: { [Player]: boolean } = {} -- solo se guarda a quien se cargó bien (para no borrar nada)

-- Lo pone Bases: devuelve lo que hay que guardar de un jugador.
Datos.proveedor = function(_jugador: Player)
	return nil
end

local function clave(jugador: Player): string
	return "jugador_" .. jugador.UserId
end

local function vacio()
	return { almacen = {}, mejoras = {}, robos = 0, estadisticas = {} }
end

-- El marcador (Tab): Reserva 💰 y Robos 🦹
function Datos.stats(jugador: Player): (IntValue, IntValue)
	local ls = jugador:FindFirstChild("leaderstats")
	if not ls then
		ls = Instance.new("Folder")
		ls.Name = "leaderstats"
		local reserva = Instance.new("IntValue")
		reserva.Name = "Reserva"
		reserva.Parent = ls
		local robos = Instance.new("IntValue")
		robos.Name = "Robos"
		robos.Parent = ls
		ls.Parent = jugador
	end
	return ls:FindFirstChild("Reserva") :: IntValue, ls:FindFirstChild("Robos") :: IntValue
end

-- Carga los datos de un jugador (puede tardar un poco). Siempre devuelve una tabla.
function Datos.cargar(jugador: Player)
	if not almacen then
		return vacio()
	end
	for intento = 1, 3 do
		local ok, res = pcall(function()
			return (almacen :: DataStore):GetAsync(clave(jugador))
		end)
		if ok then
			cargados[jugador] = true
			if type(res) ~= "table" then
				return vacio()
			end
			local datos = vacio()
			for _, id in Config.ORDEN_OBJETOS do
				local n = type(res.almacen) == "table" and res.almacen[id]
				if type(n) == "number" and n > 0 then
					datos.almacen[id] = math.floor(n)
				end
			end
			if type(res.mejoras) == "table" then
				for id, tiene in res.mejoras do
					if tiene == true and Config.mejora(id) then
						datos.mejoras[id] = true
					end
				end
			end
			datos.robos = if type(res.robos) == "number" then res.robos else 0
			if type(res.estadisticas) == "table" then
				for id, n in res.estadisticas do
					if type(id) == "string" and type(n) == "number" then
						datos.estadisticas[id] = n
					end
				end
			end
			-- Las partidas guardadas antes de las estadísticas ya tenían los robos
			datos.estadisticas.Robos = math.max(datos.estadisticas.Robos or 0, datos.robos)
			return datos
		end
		warn(string.format("[Datos] No se pudieron cargar los datos de %s (intento %d): %s", jugador.Name, intento, tostring(res)))
		local texto = tostring(res)
		if string.find(texto, "Studio") or string.find(texto, "403") then
			break -- en Studio sin acceso a la API no merece la pena reintentar
		end
		task.wait(2)
	end
	return vacio()
end

function Datos.guardar(jugador: Player, datos)
	if not almacen or not cargados[jugador] or type(datos) ~= "table" then
		return
	end
	local ok, err = pcall(function()
		(almacen :: DataStore):UpdateAsync(clave(jugador), function()
			return datos
		end)
	end)
	if not ok then
		warn("[Datos] No se pudo guardar a " .. jugador.Name .. ": " .. tostring(err))
	end
end

function Datos.olvidar(jugador: Player)
	cargados[jugador] = nil
end

function Datos.iniciar()
	local ok, resultado = pcall(function()
		return DataStoreService:GetDataStore(Config.NOMBRE_DATASTORE)
	end)
	if ok then
		almacen = resultado
	else
		warn("[Datos] El progreso no se guardará: " .. tostring(resultado))
	end

	Players.PlayerAdded:Connect(function(jugador)
		Datos.stats(jugador)
	end)
	for _, jugador in Players:GetPlayers() do
		Datos.stats(jugador)
	end

	-- Guardado automático cada 2 minutos
	task.spawn(function()
		while true do
			task.wait(120)
			for _, jugador in Players:GetPlayers() do
				task.spawn(Datos.guardar, jugador, Datos.proveedor(jugador))
			end
		end
	end)
	game:BindToClose(function()
		local pendientes = 0
		for _, jugador in Players:GetPlayers() do
			pendientes += 1
			task.spawn(function()
				Datos.guardar(jugador, Datos.proveedor(jugador))
				pendientes -= 1
			end)
		end
		local inicio = os.clock()
		while pendientes > 0 and os.clock() - inicio < 25 do
			task.wait(0.2)
		end
	end)
end

return Datos
