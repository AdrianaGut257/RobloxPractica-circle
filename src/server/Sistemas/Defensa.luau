-- 🛡️ Defensa: cuánto daño te llega.
--   · Armaduras (se fabrican en la mesa): te quitan un % de todo el daño (jugadores y enemigos).
--   · Tu base te protege: dentro, los otros jugadores te hacen la mitad de daño.
-- La armadura se ve puesta en el personaje. El atributo "Proteccion" (0-100) lo enseña la pantalla.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Estado = require(script.Parent.Estado)

local Defensa = {}

-- La mejor armadura que tiene un jugador (o nil).
function Defensa.armadura(jugador: Player)
	local mejor = nil
	for _, m in Config.MEJORAS do
		if m.proteccion and jugador:GetAttribute("Mejora_" .. m.id) == true then
			if not mejor or m.proteccion > mejor.proteccion then
				mejor = m
			end
		end
	end
	return mejor
end

-- Hace daño a un jugador teniendo en cuenta su defensa.
-- deJugador = true si el golpe viene de otro jugador.
function Defensa.danar(jugador: Player, hum: Humanoid, cantidad: number, deJugador: boolean?)
	local armadura = Defensa.armadura(jugador)
	if armadura then
		cantidad *= 1 - armadura.proteccion
	end
	if deJugador and jugador:GetAttribute("EnSuBase") then
		cantidad *= 1 - Config.DEFENSA.EN_TU_BASE
	end
	hum:TakeDamage(cantidad)
end

-- Pone (o quita) la armadura en el personaje.
function Defensa.vestir(jugador: Player)
	local armadura = Defensa.armadura(jugador)
	jugador:SetAttribute("Proteccion", if armadura then math.floor(armadura.proteccion * 100 + 0.5) else 0)
	local personaje = jugador.Character
	if not personaje then
		return
	end
	local vieja = personaje:FindFirstChild("Armadura")
	if vieja then
		vieja:Destroy()
	end
	if not armadura then
		return
	end
	local torso = (personaje:FindFirstChild("UpperTorso") or personaje:FindFirstChild("Torso")) :: BasePart?
	if not torso then
		return
	end
	local modelo = Instance.new("Model")
	modelo.Name = "Armadura"
	local function pieza(nombre: string, size: Vector3, offset: CFrame)
		local p = Instance.new("Part")
		p.Name = nombre
		p.Size = size
		p.Color = armadura.colorArmadura
		p.Material = armadura.materialArmadura
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Massless = true
		p.CastShadow = false
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.CFrame = torso.CFrame * offset
		local w = Instance.new("WeldConstraint")
		w.Part0 = torso
		w.Part1 = p
		w.Parent = p
		p.Parent = modelo
	end
	local t = torso.Size
	pieza("Peto", Vector3.new(t.X + 0.15, t.Y * 0.9, t.Z + 0.25), CFrame.new(0, 0.05, 0))
	if armadura.proteccion >= 0.3 then
		-- Hombreras
		for _, lado in { -1, 1 } do
			pieza("Hombrera", Vector3.new(0.75, 0.35, t.Z + 0.35), CFrame.new(lado * (t.X / 2 + 0.2), t.Y / 2 - 0.05, 0))
		end
	end
	if armadura.proteccion >= 0.45 then
		-- Placa del pecho
		pieza("Placa", Vector3.new(t.X * 0.6, t.Y * 0.5, 0.12), CFrame.new(0, 0.15, -(t.Z / 2 + 0.17)))
	end
	modelo.Parent = personaje
end

function Defensa.iniciar()
	local function alEntrar(jugador: Player)
		jugador.CharacterAdded:Connect(function(personaje)
			personaje:WaitForChild("Humanoid", 10)
			personaje:WaitForChild("UpperTorso", 3)
			Defensa.vestir(jugador)
		end)
		if jugador.Character then
			task.spawn(Defensa.vestir, jugador)
		end
	end
	Players.PlayerAdded:Connect(alEntrar)
	for _, jugador in Players:GetPlayers() do
		alEntrar(jugador)
	end
	Estado.escuchar("MejorasCambian", Defensa.vestir)
end

return Defensa
