-- 🛠️ Herramientas de El Anillo para Roblox Studio (solo en modo edición).
-- Aparecen en la pestaña Plugins, en el grupo «El Anillo».
--
-- Para instalarlo: copia este archivo a %LOCALAPPDATA%\Roblox\Plugins y reinicia Studio.
-- Necesita que Rojo esté conectado (rojo serve), porque usa el código del mapa.
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local RunService = game:GetService("RunService")
local Selection = game:GetService("Selection")

if RunService:IsRunning() then
	return -- durante la partida no hace nada
end

local function aviso(texto: string)
	print("[El Anillo] " .. texto)
end

local function fallo(texto: string)
	warn("[El Anillo] " .. texto)
end

-- Carga una copia nueva de los módulos del mapa (así siempre usa el código más reciente).
local function cargarMundo(): Instance?
	local server = game:GetService("ServerScriptService"):FindFirstChild("Server")
	local mundo = server and server:FindFirstChild("Mundo")
	if not mundo then
		fallo("No encuentro ServerScriptService > Server > Mundo. ¿Está conectado Rojo (rojo serve)?")
		return nil
	end
	return mundo:Clone()
end

-- Ejecuta una acción que se puede deshacer con Ctrl+Z.
local function hacer(nombre: string, fn: () -> ())
	local id = ChangeHistoryService:TryBeginRecording(nombre)
	local ok, err = pcall(fn)
	if id then
		ChangeHistoryService:FinishRecording(
			id,
			if ok then Enum.FinishRecordingOperation.Commit else Enum.FinishRecordingOperation.Cancel
		)
	end
	if not ok then
		fallo("Algo ha fallado: " .. tostring(err))
	end
end

-- Mueve la cámara para ver un objeto.
local function mirar(Plantillas, objeto: Instance)
	local minimo, maximo = Plantillas.caja(objeto)
	if not minimo then
		return
	end
	local centro = (minimo + maximo) / 2
	local camara = workspace.CurrentCamera
	camara.CFrame = CFrame.lookAt(centro + Vector3.new(0, 18, 75), centro)
	camara.Focus = CFrame.new(centro)
end

local barra = plugin:CreateToolbar("El Anillo")
local function boton(nombre: string, ayuda: string)
	local b = barra:CreateButton(nombre, ayuda, "")
	b.ClickableWhenViewportHidden = true
	return b
end

-- 🌱 Poner pasto ------------------------------------------------------------------------------

boton("Poner pasto", "Genera el suelo, los caminos, las charcas y los acantilados").Click:Connect(function()
	local mundo = cargarMundo()
	if not mundo then
		return
	end
	aviso("Poniendo el pasto... espera unos segundos")
	local ok, err = pcall(function()
		require(mundo:FindFirstChild("Terreno")).construir()
	end)
	if not ok then
		fallo("Error al poner el pasto: " .. tostring(err))
		return
	end
	-- Para que al darle a Play se use ESTE pasto y no se genere otro encima
	local mapa = workspace:FindFirstChild("ElAnillo")
	if mapa then
		mapa:SetAttribute("TerrenoPropio", true)
	end
	ChangeHistoryService:SetWaypoint("El Anillo: poner pasto")
	aviso("¡Pasto listo! Guarda con Ctrl+S para que no se pierda.")
end)

-- 🧩 Crear plantillas --------------------------------------------------------------------------

boton("Crear plantillas", "Crea los árboles modelo (Pino, Roble, ArbolSeco) en el taller para editarlos").Click:Connect(function()
	local mundo = cargarMundo()
	if not mundo then
		return
	end
	local Plantillas = require(mundo:FindFirstChild("Plantillas"))
	local Props = require(mundo:FindFirstChild("Props"))

	local existente = Plantillas.carpeta()
	if existente then
		Selection:Set({ existente })
		if existente.Parent == workspace then
			mirar(Plantillas, existente)
		end
		aviso("Las plantillas ya existen (" .. existente:GetFullName() .. "). Te las he seleccionado.")
		return
	end

	hacer("El Anillo: crear plantillas", function()
		local carpeta = Instance.new("Folder")
		carpeta.Name = Plantillas.CARPETA

		local T = Plantillas.TALLER
		local mesa = Instance.new("Part")
		mesa.Name = "Mesa"
		mesa.Anchored = true
		mesa.Size = Vector3.new(84, 2, 30)
		mesa.Position = T - Vector3.new(0, 1, 0)
		mesa.Color = Color3.fromRGB(96, 104, 84)
		mesa.Material = Enum.Material.Grass
		mesa.TopSurface = Enum.SurfaceType.Smooth
		mesa.BottomSurface = Enum.SurfaceType.Smooth
		mesa.Parent = carpeta

		for i, tipo in Plantillas.ORDEN do
			local base = T + Vector3.new((i - 2) * 26, 0, 0)
			local m = Props.CONSTRUIR[tipo](carpeta, base)
			m.Name = tipo
			m.WorldPivot = CFrame.new(base) -- el pivote, a ras de suelo
			m:SetAttribute("EscalaMin", Plantillas.TIPOS[tipo].escalaMin)
			m:SetAttribute("EscalaMax", Plantillas.TIPOS[tipo].escalaMax)
		end

		carpeta.Parent = workspace
		Selection:Set({ carpeta })
		mirar(Plantillas, carpeta)
	end)
	aviso("Plantillas creadas en Workspace > Plantillas. Cámbialas como quieras y luego pulsa «Actualizar árboles».")
end)

-- 🔄 Actualizar árboles ------------------------------------------------------------------------

boton("Actualizar árboles", "Cambia los árboles del mapa por las plantillas, sin moverlos de sitio").Click:Connect(function()
	local mundo = cargarMundo()
	if not mundo then
		return
	end
	local Plantillas = require(mundo:FindFirstChild("Plantillas"))

	if not Plantillas.carpeta() then
		fallo("No hay plantillas. Pulsa primero «Crear plantillas».")
		return
	end
	local mapa = workspace:FindFirstChild("ElAnillo")
	if not mapa then
		aviso("No hay mapa pegado en Workspace, así que no hay nada que cambiar. Al darle a Play los árboles ya salen con tus plantillas.")
		return
	end

	local viejos = {}
	for _, d in mapa:GetDescendants() do
		if d:IsA("Model") and Plantillas.TIPOS[d.Name] and Plantillas.variantes(d.Name) then
			table.insert(viejos, d)
		end
	end
	if #viejos == 0 then
		aviso("No he encontrado árboles (Pino, Roble o ArbolSeco) dentro de Workspace > ElAnillo.")
		return
	end

	local cuenta = {}
	hacer("El Anillo: actualizar árboles", function()
		local azar = Random.new()
		for _, viejo in viejos do
			local apoyo = Plantillas.apoyo(viejo)
			if apoyo then
				local nuevo = Plantillas.colocar(viejo.Name, viejo.Parent, apoyo + Vector3.new(0, Plantillas.HUNDIR, 0), nil, azar)
				if nuevo then
					cuenta[viejo.Name] = (cuenta[viejo.Name] or 0) + 1
					viejo:Destroy()
				end
			end
		end
	end)

	local partes = {}
	for _, tipo in Plantillas.ORDEN do
		if cuenta[tipo] then
			table.insert(partes, tipo .. ": " .. cuenta[tipo])
		end
	end
	aviso("Árboles actualizados (" .. table.concat(partes, ", ") .. "). Si no te gusta, Ctrl+Z.")
end)
