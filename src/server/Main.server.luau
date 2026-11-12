-- Punto de entrada del servidor: construye el mapa y arranca todos los sistemas en orden.
local Players = game:GetService("Players")

-- Los personajes los hace aparecer el sistema de Bases (cada uno en su base),
-- así que Roblox no los carga solo.
Players.CharacterAutoLoads = false

local Sistemas = script.Parent.Sistemas
require(Sistemas.Estado) -- crea ReplicatedStorage.Estado y ReplicatedStorage.Remotos

require(script.Parent.Mundo.Construir).construir()

local ORDEN = {
	"Datos",
	"Estadisticas",
	"Inventario",
	"Bases",
	"Defensa",
	"Recursos",
	"Movilidad",
	"Lluvia",
	"Enemigos",
	"Armas",
	"Ciclo",
}
for _, nombre in ORDEN do
	local ok, err = pcall(function()
		require(Sistemas[nombre]).iniciar()
	end)
	if not ok then
		warn("[El Anillo] No se pudo arrancar " .. nombre .. ": " .. tostring(err))
	end
end

print("[El Anillo] ¡Todo listo! Que empiece la lluvia.")
