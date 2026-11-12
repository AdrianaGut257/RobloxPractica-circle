-- Construye todo el mapa al empezar la partida.
-- Si en Workspace ya existe una carpeta "ElAnillo" (por ejemplo, porque copiaste
-- el mapa y lo editaste a mano en Studio), no se construye nada y se usa ese.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Bosque = require(script.Parent.Bosque)
local Estructuras = require(script.Parent.Estructuras)
local Plantillas = require(script.Parent.Plantillas)
local Props = require(script.Parent.Props)
local Terreno = require(script.Parent.Terreno)
local Util = require(script.Parent.Util)

local Construir = {}

Construir.NOMBRE = "ElAnillo"

local MAPA = Config.MAPA

-- Si el mapa se copió mientras se jugaba, trae cosas que los sistemas ponen al empezar
-- (botones de «Subir», «Beber», «Abrir almacén»..., iconos, tablones). Esas copias no funcionan
-- y tapan a las de verdad, así que se quitan: los sistemas las vuelven a poner bien.
function Construir.limpiar(mapa: Instance)
	local quitados = 0
	for _, d in mapa:GetDescendants() do
		local sobra = d:IsA("ProximityPrompt")
			or (d:IsA("BillboardGui") and (d.Name == "BillboardGui" or d.Name == "Icono"))
			or (d:IsA("SurfaceGui") and d.Parent ~= nil and CollectionService:HasTag(d.Parent, "Tablon"))
		if sobra then
			d:Destroy()
			quitados += 1
		end
	end
	if quitados > 0 then
		print(string.format("[Mapa] He quitado %d cosas que se copiaron de una partida (botones, iconos...)", quitados))
	end
end

function Construir.construir(): Instance
	-- Las plantillas (árboles modelo) se esconden al empezar: solo se ven en modo edición
	Plantillas.guardar()

	local existente = workspace:FindFirstChild(Construir.NOMBRE)
	if existente then
		print("[Mapa] Usando el mapa que ya existe en Workspace")
		Construir.limpiar(existente)
		-- El terreno se genera igual, salvo que la carpeta tenga el atributo TerrenoPropio = true
		if not existente:GetAttribute("TerrenoPropio") then
			Terreno.construir()
		end
		return existente
	end

	local inicio = os.clock()
	local raiz = Instance.new("Folder")
	raiz.Name = Construir.NOMBRE
	Props.marcadores = Util.carpeta("Marcadores", raiz)

	Terreno.construir()
	Util.muroCircular(raiz, MAPA.RADIO, 72, 400)
	Bosque.reservarConstrucciones()

	local pasos = {
		{
			"el Árbol Madre",
			function()
				Estructuras.nexo(raiz)
			end,
		},
		{
			"las bases",
			function()
				local f = Util.carpeta("Bases", raiz)
				for i = 1, MAPA.BASES do
					Estructuras.base(f, i)
				end
			end,
		},
		{
			"las pasarelas",
			function()
				local f = Util.carpeta("Pasarelas", raiz)
				for i = 1, MAPA.BASES do
					Estructuras.pasarela(f, Config.anguloBase(i))
				end
			end,
		},
		{
			"las atalayas",
			function()
				Bosque.atalayas(raiz)
			end,
		},
		{
			"los árboles gigantes",
			function()
				Bosque.gigantes(raiz)
			end,
		},
		{
			"los lugares",
			function()
				Bosque.lugares(raiz)
			end,
		},
		{
			"el bosque",
			function()
				Bosque.poblar(raiz)
			end,
		},
	}
	for _, paso in pasos do
		local ok, err = pcall(paso[2])
		if not ok then
			warn("[Mapa] Error construyendo " .. paso[1] .. ": " .. tostring(err))
		end
		task.wait() -- deja respirar al servidor entre paso y paso
	end

	raiz.Parent = workspace
	print(string.format("[Mapa] El Anillo construido en %.1f s", os.clock() - inicio))
	return raiz
end

return Construir
