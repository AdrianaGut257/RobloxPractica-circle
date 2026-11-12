-- Estado compartido de la partida y comunicación con los jugadores.
--
-- ReplicatedStorage.Estado guarda atributos que todos los jugadores ven
-- (fase del día, tiempo hasta la próxima lluvia, cajas que quedan...).
-- ReplicatedStorage.Remotos tiene los RemoteEvent para hablar con la pantalla.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Estado = {}

local REMOTOS = {
	"Notificar", -- servidor -> jugador: (texto, color?)
	"Anuncio", -- servidor -> jugador: (titulo, subtitulo)
	"Alerta", -- servidor -> jugador: (tipo, nombre) "robo" / "intruso" / "ladron"
	"AbrirAlmacen", -- servidor -> jugador
	"AbrirMejoras", -- servidor -> jugador
	"Recorrido", -- servidor -> jugador: (puntos, velocidad, tipo) para cuerdas y tirolinas
	"Usar", -- jugador -> servidor: (objeto o "comida"/"bebida"/"cura", desdeAlmacen?)
	"Guardar", -- jugador -> servidor: (objeto o "todo", cantidad?)
	"Sacar", -- jugador -> servidor: (objeto, cantidad?)
	"Mejorar", -- jugador -> servidor: (idMejora)
	"CambiarBase", -- jugador -> servidor: (indiceBase)
	"Empujon", -- servidor -> jugador: (velocidad) cuando te dan con un arma de mano
}

local obj = Instance.new("Configuration")
obj.Name = "Estado"
obj.Parent = ReplicatedStorage
Estado.obj = obj

local carpeta = Instance.new("Folder")
carpeta.Name = "Remotos"
Estado.remotos = {} :: { [string]: RemoteEvent }
for _, nombre in REMOTOS do
	local r = Instance.new("RemoteEvent")
	r.Name = nombre
	r.Parent = carpeta
	Estado.remotos[nombre] = r
end
carpeta.Parent = ReplicatedStorage

function Estado.get(clave: string)
	return obj:GetAttribute(clave)
end

function Estado.set(clave: string, valor)
	obj:SetAttribute(clave, valor)
end

-- Mensaje pequeño en pantalla. jugador = nil -> a todos.
function Estado.notificar(jugador: Player?, texto: string, color: Color3?)
	if jugador then
		Estado.remotos.Notificar:FireClient(jugador, texto, color)
	else
		Estado.remotos.Notificar:FireAllClients(texto, color)
	end
end

-- Título grande en el centro de la pantalla.
function Estado.anunciar(titulo: string, subtitulo: string?, jugador: Player?)
	if jugador then
		Estado.remotos.Anuncio:FireClient(jugador, titulo, subtitulo)
	else
		Estado.remotos.Anuncio:FireAllClients(titulo, subtitulo)
	end
end

function Estado.esNoche(): boolean
	return obj:GetAttribute("Fase") == "Noche"
end

-- Eventos internos entre sistemas del servidor
local oyentes = {}

function Estado.escuchar(evento: string, funcion)
	oyentes[evento] = oyentes[evento] or {}
	table.insert(oyentes[evento], funcion)
end

function Estado.emitir(evento: string, ...)
	for _, funcion in oyentes[evento] or {} do
		task.spawn(funcion, ...)
	end
end

return Estado
