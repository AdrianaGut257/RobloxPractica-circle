-- 🧭 Radar redondo (el mapa también es redondo). Arriba a la derecha; con M se hace grande.
-- Muestra: tú (flecha), las bases (con el color de su dueño), el Nexo y las pasarelas,
-- pozos y charcas, las cajas de la lluvia, mochilas caídas, ladrones y enemigos cerca de ti.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Interfaz = require(script.Parent.Interfaz)

local Radar = {}

local T = Interfaz.TEMA
local crear = Interfaz.crear
local rgb = Color3.fromRGB
local MAPA = Config.MAPA
local polar = Config.polar
local R = MAPA.RADIO + 10 -- radio del mundo que cabe en el radar

local PEQUENO = 210
local GRANDE = 560

-- Posición en el radar (0..1) de un punto del mundo.
local function aRadar(pos: Vector3): UDim2
	return UDim2.fromScale(0.5 + pos.X / (2 * R), 0.5 + pos.Z / (2 * R))
end

function Radar.crear(gui: ScreenGui)
	local jugador = Players.LocalPlayer
	local radar = {}

	-- En ordenador va abajo a la derecha (arriba está la lista de jugadores); en móvil, arriba.
	local movil = Interfaz.esMovil()
	local ANCLA = if movil then Vector2.new(1, 0) else Vector2.new(1, 1)
	local SITIO = if movil then UDim2.new(1, -12, 0, 64) else UDim2.new(1, -16, 1, -16)
	local marco = crear("Frame", {
		Name = "Radar",
		AnchorPoint = ANCLA,
		Position = SITIO,
		Size = UDim2.fromOffset(PEQUENO, PEQUENO),
		BackgroundColor3 = rgb(70, 132, 84),
		BackgroundTransparency = 0,
		ZIndex = 2,
		Parent = gui,
	}, {
		crear("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
		Interfaz.contorno(T.borde, 5),
	})
	Interfaz.brillo(marco, 0.25)
	-- Anillos
	local function anillo(diametro: number, color: Color3, transparencia: number, grosor: number?)
		return crear("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(diametro / (2 * R), diametro / (2 * R)),
			BackgroundTransparency = 1,
			ZIndex = 2,
			Parent = marco,
		}, {
			crear("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
			crear("UIStroke", { Color = color, Transparency = transparencia, Thickness = grosor or 1 }),
		})
	end
	anillo(130 * 2, Color3.new(1, 1, 1), 0.75)
	anillo(215 * 2, Color3.new(1, 1, 1), 0.8)
	anillo(MAPA.RADIO * 2, Color3.new(1, 1, 1), 0.35, 2)
	-- Pasarelas (líneas del centro a cada base)
	for i = 1, MAPA.BASES do
		local ang = Config.anguloBase(i)
		local largo = (MAPA.RADIO_BASES - MAPA.MEDIO_BASE - MAPA.RADIO_NEXO) / (2 * R)
		local medio = polar((MAPA.RADIO_NEXO + MAPA.RADIO_BASES - MAPA.MEDIO_BASE) / 2, ang)
		crear("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = aRadar(medio),
			Size = UDim2.new(largo, 0, 0, 2),
			Rotation = ang,
			BackgroundColor3 = rgb(170, 130, 80),
			BackgroundTransparency = 0.25,
			BorderSizePixel = 0,
			ZIndex = 3,
			Parent = marco,
		})
	end
	-- El Nexo
	crear("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(MAPA.RADIO_NEXO * 2 / (2 * R), MAPA.RADIO_NEXO * 2 / (2 * R)),
		BackgroundColor3 = rgb(110, 84, 54),
		ZIndex = 3,
		Parent = marco,
	}, { crear("UICorner", { CornerRadius = UDim.new(0.5, 0) }), crear("UIStroke", { Color = rgb(230, 200, 140), Transparency = 0.3 }) })
	local function icono(pos: Vector3, texto: string, tam: number, z: number?)
		return Interfaz.texto({
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = aRadar(pos),
			Size = UDim2.fromOffset(tam, tam),
			TextXAlignment = Enum.TextXAlignment.Center,
			TextSize = tam - 2,
			Text = texto,
			ZIndex = z or 4,
			Parent = marco,
		})
	end
	-- Atalayas, árboles gigantes y lugares
	for k = 0, 7 do
		local g = k * 45 + 22.5
		for _, r in { MAPA.RADIO_ATALAYAS_DENTRO, MAPA.RADIO_ATALAYAS_FUERA } do
			crear("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = aRadar(polar(r, g)),
				Size = UDim2.fromOffset(5, 5),
				BackgroundColor3 = rgb(190, 170, 130),
				BorderSizePixel = 0,
				ZIndex = 3,
				Parent = marco,
			})
		end
		crear("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = aRadar(polar(MAPA.RADIO_GIGANTES, g)),
			Size = UDim2.fromOffset(9, 9),
			BackgroundColor3 = rgb(70, 120, 60),
			ZIndex = 3,
			Parent = marco,
		}, { crear("UICorner", { CornerRadius = UDim.new(0.5, 0) }) })
		local lugar = Config.LUGARES[k + 1]
		local texto = if lugar == "Pozo" or lugar == "Charca" then "💧" elseif lugar == "Desguace" then "⚙️" else "⛺"
		icono(polar(MAPA.RADIO_LUGARES, g), texto, 13)
	end
	Interfaz.texto({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 3),
		Size = UDim2.fromOffset(16, 14),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextSize = 15,
		TextColor3 = T.ambar,
		Font = T.fuenteTitulo,
		Text = "N",
		ZIndex = 6,
		Parent = marco,
	})

	-- Bases (cambian de color según el dueño)
	local marcasBase = {}
	for i = 1, MAPA.BASES do
		local pos = Config.centroBase(i)
		local m = crear("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = aRadar(pos),
			Size = UDim2.fromOffset(14, 14),
			BackgroundColor3 = Config.COLOR_LIBRE,
			Text = "",
			TextSize = 11,
			Font = T.fuente,
			TextColor3 = T.texto,
			ZIndex = 5,
			Parent = marco,
		}, { Interfaz.esquinas(3), crear("UIStroke", { Color = rgb(20, 20, 20), Thickness = 1 }) })
		marcasBase[i] = m
	end
	local function refrescarBases()
		local mia = jugador:GetAttribute("Base")
		for _, modelo in CollectionService:GetTagged("Base") do
			local i = modelo:GetAttribute("Indice")
			local m = i and marcasBase[i]
			if m then
				local dueno = modelo:GetAttribute("Dueno")
				m.BackgroundColor3 = if dueno then Config.BASES[i].color else Config.COLOR_LIBRE
				m.BackgroundTransparency = if dueno then 0 else 0.4
				local esMia = i == mia
				m.Size = if esMia then UDim2.fromOffset(20, 20) else UDim2.fromOffset(14, 14)
				m.Text = if esMia then "🏠" else ""
				local trazo = m:FindFirstChildOfClass("UIStroke") :: UIStroke
				trazo.Color = if esMia then Color3.new(1, 1, 1) else rgb(20, 20, 20)
				trazo.Thickness = if esMia then 2 else 1
			end
		end
	end
	for _, modelo in CollectionService:GetTagged("Base") do
		modelo:GetAttributeChangedSignal("Dueno"):Connect(refrescarBases)
	end
	jugador:GetAttributeChangedSignal("Base"):Connect(refrescarBases)
	refrescarBases()

	-- Puntos que se mueven (se reutilizan)
	local reserva: { TextLabel } = {}
	local usados = 0
	local function punto(pos: Vector3, color: Color3, tam: number, texto: string?)
		usados += 1
		local p = reserva[usados]
		if not p then
			p = crear("TextLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BorderSizePixel = 0,
				Font = T.fuente,
				TextColor3 = T.texto,
				ZIndex = 7,
				Parent = marco,
			}, { crear("UICorner", { CornerRadius = UDim.new(0.5, 0) }) })
			reserva[usados] = p
		end
		p.Visible = true
		p.Position = aRadar(pos)
		p.Size = UDim2.fromOffset(tam, tam)
		p.BackgroundColor3 = color
		p.BackgroundTransparency = if texto then 1 else 0
		p.Text = texto or ""
		p.TextSize = tam
	end

	-- Tu flecha
	local yo = Interfaz.texto({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(18, 18),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextSize = 16,
		TextColor3 = Color3.new(1, 1, 1),
		TextStrokeTransparency = 0,
		Font = T.fuenteTitulo,
		Text = "▲",
		ZIndex = 9,
		Parent = marco,
	})

	-- Leyenda (solo con el mapa grande)
	local leyenda = Interfaz.panel({
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(1, 16, 0.5, 0),
		Size = UDim2.fromOffset(210, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Visible = false,
		ZIndex = 8,
		Parent = marco,
	})
	Interfaz.relleno(12).Parent = leyenda
	Interfaz.lista(5).Parent = leyenda
	for i, linea in {
		"▲  Tú",
		"🏠  Tu base",
		"■  Otras bases (color del dueño)",
		"🟤  El Nexo y las pasarelas",
		"🟡  Cajas de la lluvia",
		"🎒  Mochilas caídas",
		"🦹  Ladrones",
		"🔴  Enemigos cerca",
		"💧 Agua  ·  ⚙️ Desguace  ·  ⛺ Campamento",
		"🟢  Árboles gigantes (con plataforma)",
	} do
		Interfaz.texto({ Text = linea, Font = T.fuenteMedia, TextSize = 13, TextWrapped = true, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = i, ZIndex = 9, Parent = leyenda })
	end

	local grande = false
	function radar.alternar()
		grande = not grande
		if grande then
			marco.AnchorPoint = Vector2.new(0.5, 0.5)
			marco.Position = UDim2.new(0.5, -110, 0.5, 0)
			marco.Size = UDim2.fromOffset(GRANDE, GRANDE)
		else
			marco.AnchorPoint = ANCLA
			marco.Position = SITIO
			marco.Size = UDim2.fromOffset(PEQUENO, PEQUENO)
		end
		leyenda.Visible = grande
		return grande
	end
	function radar.esGrande(): boolean
		return grande
	end

	local COLOR_CAJA = { Comun = rgb(255, 200, 90), Militar = rgb(140, 230, 110), Dorada = rgb(255, 240, 120) }

	local function actualizar()
		usados = 0
		local personaje = jugador.Character
		local raiz = personaje and personaje:FindFirstChild("HumanoidRootPart") :: BasePart?
		local factor = if grande then 1.6 else 1
		-- Cajas de la lluvia (las que caen y las que ya están en el suelo)
		local suministros = workspace:FindFirstChild("Suministros")
		if suministros then
			for _, caja in suministros:GetChildren() do
				if caja:IsA("Model") and caja.PrimaryPart then
					local tipo = caja:GetAttribute("Tipo") or "Comun"
					punto(caja.PrimaryPart.Position, COLOR_CAJA[tipo] or COLOR_CAJA.Comun, (if tipo == "Dorada" then 9 else 7) * factor)
				end
			end
		end
		-- Mochilas caídas
		local recogibles = workspace:FindFirstChild("Recogibles")
		if recogibles then
			for _, m in recogibles:GetChildren() do
				if m.Name == "MochilaCaida" and m:IsA("Model") and m.PrimaryPart then
					punto(m.PrimaryPart.Position, Color3.new(), 12 * factor, "🎒")
				end
			end
		end
		-- Enemigos cerca de ti
		local enemigos = workspace:FindFirstChild("Enemigos")
		if enemigos and raiz then
			for _, e in enemigos:GetChildren() do
				local r = e:FindFirstChild("HumanoidRootPart") :: BasePart?
				if r and (r.Position - raiz.Position).Magnitude < 70 then
					punto(r.Position, rgb(230, 50, 40), 5 * factor)
				end
			end
		end
		-- Ladrones (todos los ven)
		for _, otro in Players:GetPlayers() do
			if otro ~= jugador and otro:GetAttribute("Ladron") then
				local r = otro.Character and otro.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
				if r then
					punto(r.Position, Color3.new(), 14 * factor, "🦹")
				end
			end
		end
		for i = usados + 1, #reserva do
			reserva[i].Visible = false
		end
		-- Tú
		local camara = workspace.CurrentCamera
		if raiz and camara then
			yo.Visible = true
			yo.Position = aRadar(raiz.Position)
			local mira = camara.CFrame.LookVector
			yo.Rotation = math.deg(math.atan2(mira.X, -mira.Z))
		else
			yo.Visible = false
		end
	end

	local acumulado = 0
	RunService.RenderStepped:Connect(function(dt)
		acumulado += dt
		if acumulado >= 0.1 then
			acumulado = 0
			actualizar()
		end
	end)

	return radar
end

return Radar
