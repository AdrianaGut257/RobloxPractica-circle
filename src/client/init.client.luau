-- Pantalla del jugador: HUD, radar, ventanas (almacén, mejoras, ayuda) y efectos.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local Efectos = require(script.Efectos)
local Hud = require(script.Hud)
local Interfaz = require(script.Interfaz)
local Radar = require(script.Radar)
local Ventanas = require(script.Ventanas)

local jugador = Players.LocalPlayer
local estado = ReplicatedStorage:WaitForChild("Estado")
local remotos = ReplicatedStorage:WaitForChild("Remotos") :: Folder
local playerGui = jugador:WaitForChild("PlayerGui")

-- La barra de vida la pone nuestro HUD
pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
end)

local gui = Interfaz.crear("ScreenGui", {
	Name = "InterfazAnillo",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = playerGui,
})
local pantalla = Interfaz.crear("ScreenGui", {
	Name = "InterfazPantalla",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = -1,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = playerGui,
})

local hud = Hud.crear(gui, pantalla, estado)
local radar = Radar.crear(gui)
local ventanas = Ventanas.crear(gui, remotos)
Efectos.iniciar()

local function usar(que: string)
	remotos:WaitForChild("Usar"):FireServer(que)
end
local function alternarMapa()
	local grande = radar.alternar()
	hud.mostrar(not grande)
end
hud.alComer = function()
	usar("comida")
end
hud.alBeber = function()
	usar("bebida")
end
hud.alCurar = function()
	usar("cura")
end
hud.alAyuda = ventanas.alternarAyuda
hud.alMapa = alternarMapa
hud.alBases = ventanas.alternarBases
hud.alEstadisticas = ventanas.alternarEstadisticas

remotos:WaitForChild("Notificar").OnClientEvent:Connect(hud.notificar)
remotos:WaitForChild("Anuncio").OnClientEvent:Connect(hud.anunciar)
remotos:WaitForChild("Alerta").OnClientEvent:Connect(hud.alerta)
remotos:WaitForChild("AbrirAlmacen").OnClientEvent:Connect(ventanas.abrirAlmacen)
remotos:WaitForChild("AbrirMejoras").OnClientEvent:Connect(ventanas.abrirMejoras)
remotos:WaitForChild("Recorrido").OnClientEvent:Connect(Efectos.recorrido)
remotos:WaitForChild("Empujon").OnClientEvent:Connect(Efectos.empujon)

UserInputService.InputBegan:Connect(function(entrada, procesado)
	if procesado then
		return
	end
	local tecla = entrada.KeyCode
	if tecla == Enum.KeyCode.F then
		usar("comida")
	elseif tecla == Enum.KeyCode.G then
		usar("bebida")
	elseif tecla == Enum.KeyCode.C then
		usar("cura")
	elseif tecla == Enum.KeyCode.H then
		ventanas.alternarAyuda()
	elseif tecla == Enum.KeyCode.M then
		alternarMapa()
	elseif tecla == Enum.KeyCode.B then
		ventanas.alternarBases()
	elseif tecla == Enum.KeyCode.J then
		ventanas.alternarEstadisticas()
	end
end)

-- La primera vez que apareces, sale la ayuda
local vista = false
local function alAparecer()
	if not vista then
		vista = true
		task.delay(1.5, ventanas.alternarAyuda)
	end
end
jugador.CharacterAdded:Connect(alAparecer)
if jugador.Character then
	alAparecer()
end
