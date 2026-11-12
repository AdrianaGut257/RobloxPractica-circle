-- Día y noche, y la luz del fin del mundo (niebla verdosa, colores apagados).
-- Fase "Dia": los Errantes y Vigías rondan. Fase "Noche": además salen los Rabiosos.
-- Durante la lluvia de suministros el cielo se tiñe un poco de naranja.
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Estado = require(script.Parent.Estado)

local Ciclo = {}

local rgb = Color3.fromRGB
local atmosfera: Atmosphere
local correccion: ColorCorrectionEffect

local TONOS = {
	dia = {
		Color = rgb(170, 176, 156),
		Decay = rgb(96, 104, 88),
		Density = 0.36,
		Haze = 2,
		tinte = rgb(240, 244, 226),
		sat = -0.22,
		ambiente = rgb(118, 120, 108),
		brillo = 2.2,
	},
	noche = {
		Color = rgb(40, 52, 58),
		Decay = rgb(16, 22, 26),
		Density = 0.5,
		Haze = 2.6,
		tinte = rgb(190, 214, 220),
		sat = -0.3,
		ambiente = rgb(40, 48, 58),
		brillo = 0.9,
	},
}

local function prepararIluminacion()
	Lighting.EnvironmentDiffuseScale = 1
	Lighting.EnvironmentSpecularScale = 0.6
	Lighting.GlobalShadows = true
	Lighting.ClockTime = 9
	Lighting.GeographicLatitude = 30

	atmosfera = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
	atmosfera.Offset = 0.12
	atmosfera.Glare = 0.1
	atmosfera.Parent = Lighting

	local cielo = Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky")
	cielo.StarCount = 2000
	cielo.CelestialBodiesShown = true
	cielo.Parent = Lighting

	local brillo = Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect")
	brillo.Intensity = 0.7
	brillo.Size = 26
	brillo.Threshold = 1.5
	brillo.Parent = Lighting

	local rayos = Lighting:FindFirstChildOfClass("SunRaysEffect") or Instance.new("SunRaysEffect")
	rayos.Intensity = 0.06
	rayos.Spread = 0.7
	rayos.Parent = Lighting

	correccion = Lighting:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect")
	correccion.Parent = Lighting
end

local function cambiarAmbiente(instantaneo: boolean?)
	local noche = Estado.esNoche()
	local lluvia = Estado.get("LluviaActiva") == true
	local t = if noche then TONOS.noche else TONOS.dia
	local info = TweenInfo.new(if instantaneo then 0.1 else 8, Enum.EasingStyle.Sine)
	TweenService:Create(Lighting, info, {
		Brightness = t.brillo,
		OutdoorAmbient = t.ambiente,
		Ambient = t.ambiente:Lerp(Color3.new(), 0.5),
		ExposureCompensation = if noche then 0.2 else 0,
	}):Play()
	TweenService:Create(atmosfera, info, {
		Color = if lluvia then t.Color:Lerp(rgb(220, 150, 100), 0.35) else t.Color,
		Decay = t.Decay,
		Density = t.Density,
		Haze = t.Haze,
	}):Play()
	TweenService:Create(correccion, info, {
		TintColor = if lluvia then t.tinte:Lerp(rgb(255, 210, 170), 0.3) else t.tinte,
		Saturation = t.sat,
		Contrast = if noche then 0.12 else 0.08,
	}):Play()
	for _, luz in CollectionService:GetTagged("LuzNoche") do
		if luz:IsA("Light") then
			luz.Brightness = if noche then 2 else 0.6
		end
	end
end

local function correrFase(fase: string, duracion: number)
	Estado.set("Fase", fase)
	Estado.set("DuracionFase", duracion)
	local inicio = os.clock()
	local avisado = false
	while true do
		local t = os.clock() - inicio
		local p = math.clamp(t / duracion, 0, 1)
		local restante = math.max(0, duracion - t)
		if fase == "Dia" then
			Lighting.ClockTime = 7 + p * 11 -- de 7:00 a 18:00
			if not avisado and restante <= 30 then
				avisado = true
				Estado.notificar(nil, "🌇 Está anocheciendo... De noche salen los Rabiosos.", rgb(255, 190, 120))
			end
		else
			Lighting.ClockTime = (18.5 + p * 12) % 24 -- de 18:30 a 6:30
		end
		Estado.set("TiempoRestante", math.ceil(restante))
		if t >= duracion then
			break
		end
		task.wait(0.2)
	end
end

function Ciclo.iniciar()
	prepararIluminacion()
	Estado.set("Dia", 1)
	Estado.set("Fase", "Dia")
	cambiarAmbiente(true)
	Estado.obj:GetAttributeChangedSignal("LluviaActiva"):Connect(function()
		cambiarAmbiente()
	end)
	task.spawn(function()
		while true do
			local dia = Estado.get("Dia") or 1
			Estado.set("Fase", "Dia")
			cambiarAmbiente()
			if dia > 1 then
				Estado.anunciar("DÍA " .. dia, "Habéis sobrevivido a otra noche.")
			end
			Estado.emitir("DiaEmpieza", dia)
			correrFase("Dia", Config.CICLO.DIA)

			Estado.set("Fase", "Noche")
			cambiarAmbiente()
			Estado.anunciar("NOCHE " .. dia, "Los Rabiosos han salido a cazar. Quedaos en las alturas.")
			Estado.emitir("NocheEmpieza", dia)
			correrFase("Noche", Config.CICLO.NOCHE)
			Estado.set("Dia", dia + 1)
		end
	end)
end

return Ciclo
