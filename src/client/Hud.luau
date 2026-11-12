-- HUD: cuenta atrás de la lluvia, día/noche, consejo, vida/hambre/sed, tu base (reserva y flecha),
-- la mochila, alertas de robo, avisos pequeños y anuncios grandes.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Interfaz = require(script.Parent.Interfaz)

local Hud = {}

local T = Interfaz.TEMA
local crear = Interfaz.crear
local rgb = Color3.fromRGB
local S = Config.SUPERVIVENCIA
local OBJETOS = Config.OBJETOS

local function yaw(v: Vector3): number
	return math.deg(math.atan2(v.X, -v.Z))
end

-- gui: capa normal (se encoge en pantallas pequeñas). pantalla: capa a pantalla completa.
function Hud.crear(gui: ScreenGui, pantalla: ScreenGui, estado: Instance)
	local jugador = Players.LocalPlayer
	local hud = {}

	-- Escala más pequeña en pantallas bajitas (móviles)
	local escala = crear("UIScale", { Parent = gui })
	local function ajustarEscala()
		local camara = workspace.CurrentCamera
		local alto = if camara then camara.ViewportSize.Y else 800
		escala.Scale = math.clamp(alto / 900, 0.55, 1.1)
	end
	ajustarEscala()
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(ajustarEscala)
	end

	local sonidoAlerta = crear("Sound", { SoundId = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.8, Parent = gui })

	-- 🪂 Panel de la lluvia ------------------------------------------------------------------
	local panelLluvia = Interfaz.panel({
		Name = "Lluvia",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 10),
		Size = UDim2.fromOffset(450, 98),
		Parent = gui,
	})
	local trazoLluvia = panelLluvia:FindFirstChildOfClass("UIStroke") :: UIStroke
	local franja = crear("Frame", {
		Size = UDim2.new(1, -24, 0, 5),
		Position = UDim2.fromOffset(12, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Visible = false,
		Parent = panelLluvia,
	}, { Interfaz.esquinas(2) })
	Interfaz.rayas(franja)
	local iconoLluvia = crear("TextLabel", {
		Size = UDim2.fromOffset(66, 66),
		Position = UDim2.fromOffset(14, 14),
		BackgroundColor3 = T.naranja,
		Text = "🪂",
		TextSize = 36,
		Font = T.fuente,
		TextColor3 = T.texto,
		Parent = panelLluvia,
	}, { Interfaz.esquinas(33), Interfaz.contorno() })
	Interfaz.brillo(iconoLluvia, 0.3)
	local tituloLluvia = Interfaz.texto({
		Font = T.fuenteTitulo,
		TextSize = 15,
		TextColor3 = T.ambar,
		Position = UDim2.fromOffset(92, 10),
		Size = UDim2.fromOffset(230, 18),
		Text = "PRÓXIMA LLUVIA DE SUMINISTROS",
		Parent = panelLluvia,
	})
	local tiempoLluvia = Interfaz.texto({
		Font = T.fuenteNumeros,
		TextSize = 42,
		Position = UDim2.fromOffset(92, 26),
		Size = UDim2.fromOffset(210, 44),
		Text = "",
		Parent = panelLluvia,
	})
	local faseTxt = Interfaz.texto({
		TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Right,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -16, 0, 12),
		Size = UDim2.fromOffset(130, 22),
		Text = "",
		Parent = panelLluvia,
	})
	local faseTiempo = Interfaz.texto({
		Font = T.fuenteMedia,
		TextSize = 12,
		TextColor3 = T.textoSuave,
		TextXAlignment = Enum.TextXAlignment.Right,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -16, 0, 36),
		Size = UDim2.fromOffset(130, 16),
		Text = "",
		Parent = panelLluvia,
	})
	local barraLluvia = Interfaz.barra({
		Position = UDim2.new(0, 92, 1, -22),
		Size = UDim2.new(1, -108, 0, 12),
		Parent = panelLluvia,
		color = T.ambar,
	})

	-- 🎯 Consejo
	local consejo = Interfaz.panel({
		Name = "Consejo",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 118),
		Size = UDim2.fromOffset(560, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 0.12,
		Parent = gui,
	})
	Interfaz.relleno(8, 14).Parent = consejo
	local consejoTxt = Interfaz.texto({
		Font = T.fuenteMedia,
		TextSize = 16,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = "",
		Parent = consejo,
	})

	-- 🦹 Aviso de que eres un ladrón
	local chipLadron = crear("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 170),
		Size = UDim2.fromOffset(0, 36),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = T.botonRojo,
		BackgroundTransparency = 0,
		Visible = false,
		Parent = gui,
	}, { Interfaz.esquinas(18), Interfaz.relleno(0, 16), Interfaz.contorno() })
	local chipLadronTxt = Interfaz.texto({
		Font = T.fuente,
		TextSize = 17,
		Size = UDim2.fromOffset(0, 36),
		AutomaticSize = Enum.AutomaticSize.X,
		Text = "",
		Parent = chipLadron,
	})

	-- 🚨 Alerta grande (robos e intrusos)
	local alerta = crear("CanvasGroup", {
		Name = "Alerta",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 170),
		Size = UDim2.fromOffset(600, 92),
		BackgroundColor3 = T.botonRojo,
		GroupTransparency = 1,
		Visible = false,
		ZIndex = 4,
		Parent = gui,
	}, { Interfaz.esquinas(18) })
	local trazoAlerta = Interfaz.contorno(T.borde, 4, 0)
	trazoAlerta.Parent = alerta
	local rayasAlerta = crear("Frame", {
		Size = UDim2.new(1, 0, 0, 7),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Parent = alerta,
	})
	local gradienteAlerta = Interfaz.rayas(rayasAlerta, rgb(255, 80, 60))
	local alertaTitulo = Interfaz.texto({
		Font = T.fuenteTitulo,
		TextSize = 32,
		TextXAlignment = Enum.TextXAlignment.Center,
		Position = UDim2.fromOffset(0, 12),
		Size = UDim2.new(1, 0, 0, 38),
		Text = "",
		Parent = alerta,
	})
	local alertaSub = Interfaz.texto({
		Font = T.fuenteMedia,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextWrapped = true,
		Position = UDim2.fromOffset(12, 46),
		Size = UDim2.new(1, -24, 0, 30),
		Text = "",
		Parent = alerta,
	})

	-- Columna izquierda: supervivencia y base -----------------------------------------------
	local izquierda = crear("Frame", {
		Name = "Izquierda",
		Position = UDim2.fromOffset(12, 64),
		Size = UDim2.fromOffset(300, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = gui,
	}, { Interfaz.lista(12) })

	local panelVida = Interfaz.panel({ Size = UDim2.fromOffset(300, 128), LayoutOrder = 1, Parent = izquierda })
	local function fila(y: number, icono: string, color: Color3)
		Interfaz.texto({ Text = icono, TextSize = 24, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromOffset(32, 30), Position = UDim2.fromOffset(10, y - 1), Parent = panelVida })
		return Interfaz.barra({ Position = UDim2.new(0, 50, 0, y), Size = UDim2.new(1, -64, 0, 28), Parent = panelVida, color = color })
	end
	local barraVida = fila(12, "❤️", T.vida)
	local barraHambre = fila(50, "🍖", T.comida)
	local barraSed = fila(88, "💧", T.agua)

	local panelBase = Interfaz.panel({ Size = UDim2.fromOffset(300, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2, Parent = izquierda })
	local franjaBase = crear("Frame", {
		Size = UDim2.new(0, 6, 1, -16),
		Position = UDim2.fromOffset(8, 8),
		BackgroundColor3 = Config.COLOR_LIBRE,
		BorderSizePixel = 0,
		Parent = panelBase,
	}, { Interfaz.esquinas(3) })
	local contenidoBase = crear("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = panelBase,
	}, { crear("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 24), PaddingRight = UDim.new(0, 12) }), Interfaz.lista(4) })
	local baseTitulo = Interfaz.texto({ Font = T.fuenteTitulo, TextSize = 20, Size = UDim2.new(1, 0, 0, 24), LayoutOrder = 1, Text = "🏠 SIN BASE", Parent = contenidoBase })
	local reservaTxt = Interfaz.texto({ Font = T.fuenteNumeros, TextSize = 28, TextColor3 = T.oro, Size = UDim2.new(1, 0, 0, 32), LayoutOrder = 2, Text = "💰 0", Parent = contenidoBase })
	local filaDistancia = crear("Frame", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, LayoutOrder = 3, Parent = contenidoBase })
	local flecha = Interfaz.texto({ Text = "▲", TextSize = 16, TextColor3 = T.ambar, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromOffset(22, 22), Parent = filaDistancia })
	local distanciaTxt = Interfaz.texto({ Font = T.fuenteMedia, TextSize = 15, Position = UDim2.fromOffset(28, 0), Size = UDim2.new(1, -28, 1, 0), Text = "", Parent = filaDistancia })
	local mejorasTxt = Interfaz.texto({ Font = T.fuente, TextSize = 16, RichText = true, Size = UDim2.new(1, 0, 0, 22), LayoutOrder = 4, Text = "", Parent = contenidoBase })
	local armaTxt = Interfaz.texto({ Font = T.fuente, TextSize = 16, RichText = true, LineHeight = 1.1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 5, Text = "", Parent = contenidoBase })
	local botones = crear("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 6, Parent = contenidoBase }, {
		crear("UIGridLayout", { CellSize = UDim2.new(0.5, -5, 0, 42), CellPadding = UDim2.fromOffset(10, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	local botonAyuda = Interfaz.boton({ Text = "❓ Ayuda [H]", TextSize = 16, color = T.botonAmarillo, LayoutOrder = 1, Parent = botones })
	local botonMapa = Interfaz.boton({ Text = "🗺️ Mapa [M]", TextSize = 16, color = T.botonVerde, LayoutOrder = 2, Parent = botones })
	local botonBases = Interfaz.boton({ Text = "🏠 Bases [B]", TextSize = 16, color = T.rosa, LayoutOrder = 3, Parent = botones })
	local botonStats = Interfaz.boton({ Text = "📊 Stats [J]", TextSize = 16, color = T.botonMorado, LayoutOrder = 4, Parent = botones })

	-- Columna derecha: mochila (el radar va encima, lo pone Radar) --------------------------
	local movil = Interfaz.esMovil()
	local mochila = Interfaz.panel({
		Name = "Mochila",
		AnchorPoint = if movil then Vector2.new(1, 0) else Vector2.new(1, 1),
		Position = if movil then UDim2.new(1, -12, 0, 290) else UDim2.new(1, -12, 1, -250),
		Size = UDim2.fromOffset(268, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = gui,
	})
	Interfaz.relleno(12).Parent = mochila
	Interfaz.lista(8).Parent = mochila
	local cabecera = crear("Frame", { Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, LayoutOrder = 1, Parent = mochila })
	Interfaz.texto({ Text = "🎒 MOCHILA", Font = T.fuenteTitulo, TextSize = 20, TextColor3 = T.ambar, Size = UDim2.fromScale(0.6, 1), Parent = cabecera })
	local cargaTxt = Interfaz.texto({ Font = T.fuenteNumeros, TextSize = 22, TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromScale(0.4, 1), Text = "0/12", Parent = cabecera })
	local barraCarga = Interfaz.barra({ Size = UDim2.new(1, 0, 0, 12), LayoutOrder = 2, Parent = mochila, color = T.ambar })
	local rejilla = crear("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 3, Parent = mochila }, {
		crear("UIGridLayout", { CellSize = UDim2.fromOffset(54, 58), CellPadding = UDim2.fromOffset(6, 6), SortOrder = Enum.SortOrder.LayoutOrder, FillDirectionMaxCells = 4 }),
	})
	local vaciaTxt = Interfaz.texto({ Font = T.fuenteMedia, TextSize = 14, TextColor3 = T.textoSuave, Text = "Vacía. Busca cajas 🪂, bayas 🍇 y pozos 💧", TextWrapped = true, Size = UDim2.new(1, 0, 0, 34), LayoutOrder = 4, Parent = mochila })
	local valorTxt = Interfaz.texto({ Font = T.fuenteMedia, TextSize = 13, TextColor3 = T.oro, Text = "", Size = UDim2.new(1, 0, 0, 16), LayoutOrder = 5, Parent = mochila })
	local casillas = {}
	for i, id in Config.ORDEN_OBJETOS do
		local datos = OBJETOS[id]
		local casilla = crear("Frame", { BackgroundColor3 = T.panelClaro, BackgroundTransparency = 0, LayoutOrder = i, Visible = false, Parent = rejilla }, {
			Interfaz.esquinas(12),
			Interfaz.contorno(datos.color, 3, 0),
		})
		Interfaz.texto({ Text = datos.icono, TextSize = 26, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.new(1, 0, 0, 36), Position = UDim2.fromOffset(0, 2), Parent = casilla })
		local n = Interfaz.texto({ Font = T.fuenteNumeros, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.new(1, 0, 0, 16), Position = UDim2.new(0, 0, 1, -18), Text = "0", Parent = casilla })
		casillas[id] = { marco = casilla, n = n }
	end
	local acciones = crear("Frame", { Size = UDim2.new(1, 0, 0, 48), BackgroundTransparency = 1, LayoutOrder = 6, Parent = mochila }, { Interfaz.lista(8, true) })
	local function accion(texto: string, orden: number, color: Color3)
		return Interfaz.boton({ Text = texto, TextSize = 14, Size = UDim2.fromOffset(76, 48), LayoutOrder = orden, color = color, Parent = acciones })
	end
	local botonComer = accion("🍖 Comer\n[F]", 1, T.botonNaranja)
	local botonBeber = accion("💧 Beber\n[G]", 2, T.botonAzul)
	local botonCurar = accion("🩹 Curar\n[C]", 3, T.botonRojo)

	hud.alComer = function() end
	hud.alBeber = function() end
	hud.alCurar = function() end
	hud.alAyuda = function() end
	hud.alMapa = function() end
	hud.alBases = function() end
	hud.alEstadisticas = function() end
	botonComer.Activated:Connect(function()
		hud.alComer()
	end)
	botonBeber.Activated:Connect(function()
		hud.alBeber()
	end)
	botonCurar.Activated:Connect(function()
		hud.alCurar()
	end)
	botonAyuda.Activated:Connect(function()
		hud.alAyuda()
	end)
	botonBases.Activated:Connect(function()
		hud.alBases()
	end)
	botonStats.Activated:Connect(function()
		hud.alEstadisticas()
	end)
	botonMapa.Activated:Connect(function()
		hud.alMapa()
	end)

	-- 💬 Avisos pequeños --------------------------------------------------------------------
	local avisos = crear("Frame", {
		Name = "Avisos",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -100),
		Size = UDim2.fromOffset(600, 240),
		BackgroundTransparency = 1,
		Parent = gui,
	}, {
		crear("UIListLayout", {
			Padding = UDim.new(0, 6),
			VerticalAlignment = Enum.VerticalAlignment.Bottom,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	local contadorAvisos = 0

	function hud.notificar(texto: string, color: Color3?)
		contadorAvisos += 1
		local grupo = crear("CanvasGroup", {
			Size = UDim2.fromOffset(0, 0),
			AutomaticSize = Enum.AutomaticSize.XY,
			BackgroundColor3 = T.panel,
			BackgroundTransparency = 0.05,
			GroupTransparency = 1,
			LayoutOrder = contadorAvisos,
			Parent = avisos,
		}, { Interfaz.esquinas(14), Interfaz.relleno(10, 16), Interfaz.contorno() })
		local etiqueta = Interfaz.texto({
			Font = T.fuente,
			TextSize = 18,
			TextColor3 = color or T.texto,
			TextWrapped = true,
			Size = UDim2.fromOffset(0, 0),
			AutomaticSize = Enum.AutomaticSize.XY,
			Text = texto,
			Parent = grupo,
		})
		crear("UISizeConstraint", { MaxSize = Vector2.new(570, math.huge), Parent = etiqueta })
		TweenService:Create(grupo, TweenInfo.new(0.25), { GroupTransparency = 0 }):Play()
		local hijos = {}
		for _, h in avisos:GetChildren() do
			if h:IsA("CanvasGroup") then
				table.insert(hijos, h)
			end
		end
		if #hijos > 5 then
			table.sort(hijos, function(a, b)
				return a.LayoutOrder < b.LayoutOrder
			end)
			hijos[1]:Destroy()
		end
		task.delay(math.clamp(#texto / 18, 4, 9), function()
			if grupo.Parent then
				local t = TweenService:Create(grupo, TweenInfo.new(0.5), { GroupTransparency = 1 })
				t:Play()
				t.Completed:Wait()
				grupo:Destroy()
			end
		end)
	end

	-- 📣 Anuncios grandes ---------------------------------------------------------------------
	local anuncio = crear("CanvasGroup", {
		Name = "Anuncio",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.4),
		Size = UDim2.fromOffset(880, 150),
		BackgroundTransparency = 1,
		GroupTransparency = 1,
		Visible = false,
		Parent = gui,
	})
	local anuncioTitulo = Interfaz.texto({
		Font = T.fuenteTitulo,
		TextSize = 64,
		TextColor3 = T.ambar,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.new(1, 0, 0, 62),
		Text = "",
		Parent = anuncio,
	})
	local anuncioSub = Interfaz.texto({
		Font = T.fuente,
		TextSize = 24,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.new(1, 0, 0, 70),
		Position = UDim2.fromOffset(0, 68),
		Text = "",
		Parent = anuncio,
	})
	local idAnuncio = 0
	function hud.anunciar(titulo: string, subtitulo: string?)
		idAnuncio += 1
		local este = idAnuncio
		anuncioTitulo.Text = titulo
		anuncioSub.Text = subtitulo or ""
		Interfaz.fundido(anuncio, true, 0.5)
		task.delay(5, function()
			if idAnuncio == este then
				Interfaz.fundido(anuncio, false, 1.2)
			end
		end)
	end

	-- 🩸 Daño, poca vida y alertas a pantalla completa
	local dano = crear("Frame", { Name = "Dano", Size = UDim2.fromScale(1, 1), BackgroundColor3 = rgb(180, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0, Parent = pantalla })
	local bordes = {}
	for _, lado in { { 0, 0, 1, 0.22, 90 }, { 0, 0.78, 1, 0.22, -90 }, { 0, 0, 0.16, 1, 0 }, { 0.84, 0, 0.16, 1, 180 } } do
		local f = crear("Frame", {
			Position = UDim2.fromScale(lado[1], lado[2]),
			Size = UDim2.fromScale(lado[3], lado[4]),
			BackgroundColor3 = rgb(150, 0, 0),
			BorderSizePixel = 0,
			Parent = pantalla,
		})
		crear("UIGradient", { Rotation = lado[5], Transparency = NumberSequence.new(0, 1), Parent = f })
		table.insert(bordes, f)
	end
	local function ponerBordes(transparencia: number, color: Color3?)
		for _, f in bordes do
			f.BackgroundTransparency = transparencia
			if color then
				f.BackgroundColor3 = color
			end
		end
	end
	ponerBordes(1)

	local idAlerta = 0
	function hud.alerta(tipo: string, nombre: string, detalle: string?)
		idAlerta += 1
		local esta = idAlerta
		sonidoAlerta:Play()
		if tipo == "robo" then
			alerta.BackgroundColor3 = T.botonRojo
			trazoAlerta.Color = T.borde
			gradienteAlerta.Parent = rayasAlerta
			alertaTitulo.Text = "🚨 ¡TE ESTÁN ROBANDO!"
			alertaSub.Text = string.format("%s se ha llevado %s de tu almacén", nombre, detalle or "algo")
		else
			alerta.BackgroundColor3 = T.botonNaranja
			trazoAlerta.Color = T.borde
			alertaTitulo.Text = "👀 ¡ALGUIEN EN TU BASE!"
			alertaSub.Text = nombre .. " ha entrado en tu base. ¡Vuelve a defenderla!"
		end
		Interfaz.fundido(alerta, true, 0.2)
		ponerBordes(0.55, if tipo == "robo" then rgb(200, 20, 20) else rgb(220, 150, 30))
		task.spawn(function()
			for _ = 1, 6 do
				if idAlerta ~= esta then
					return
				end
				TweenService:Create(trazoAlerta, TweenInfo.new(0.3), { Transparency = 0.8 }):Play()
				task.wait(0.35)
				TweenService:Create(trazoAlerta, TweenInfo.new(0.3), { Transparency = 0 }):Play()
				task.wait(0.35)
			end
		end)
		task.delay(if tipo == "robo" then 7 else 5, function()
			if idAlerta == esta then
				Interfaz.fundido(alerta, false, 0.6)
				ponerBordes(1)
			end
		end)
	end

	-- Ocultar el HUD (con el mapa grande abierto, por ejemplo)
	function hud.mostrar(visible: boolean)
		for _, hijo in { panelLluvia, consejo, izquierda, mochila } do
			hijo.Visible = visible
		end
	end

	-- 🔄 Actualizar ------------------------------------------------------------------------------

	local function refrescarLluvia()
		local activa = estado:GetAttribute("LluviaActiva") == true
		local restante = estado:GetAttribute("ProximaLluvia") or 0
		local intervalo = estado:GetAttribute("IntervaloLluvia") or Config.LLUVIA.INTERVALO
		local cajas = estado:GetAttribute("CajasRestantes") or 0
		franja.Visible = activa
		if activa then
			tituloLluvia.Text = "¡LLUVIA DE SUMINISTROS!"
			tiempoLluvia.Text = string.format("📦 %d cajas", cajas)
			tiempoLluvia.TextColor3 = T.oro
			trazoLluvia.Color = T.ambar
			trazoLluvia.Transparency = 0
			barraLluvia.poner(1, nil, T.oro)
		else
			local aviso = restante <= Config.LLUVIA.AVISO
			tituloLluvia.Text = if aviso then "¡LA LLUVIA SE ACERCA!" else "PRÓXIMA LLUVIA DE SUMINISTROS"
			tiempoLluvia.Text = Interfaz.formatoTiempo(restante) .. (if cajas > 0 then string.format("   ·   📦 %d", cajas) else "")
			tiempoLluvia.TextColor3 = if aviso then T.ambar else T.texto
			trazoLluvia.Color = if aviso then T.ambar else T.borde
			if not aviso then
				trazoLluvia.Transparency = 0
			end
			barraLluvia.poner(1 - restante / math.max(intervalo, 1), nil, if aviso then T.ambar else T.azul)
		end
		local fase = estado:GetAttribute("Fase") or "Dia"
		local dia = estado:GetAttribute("Dia") or 1
		faseTxt.Text = if fase == "Noche" then "🌙 NOCHE " .. dia else "☀️ DÍA " .. dia
		faseTxt.TextColor3 = if fase == "Noche" then T.noche else T.texto
		faseTiempo.Text = (if fase == "Noche" then "amanece en " else "anochece en ") .. Interfaz.formatoTiempo(estado:GetAttribute("TiempoRestante") or 0)
	end

	local function base(): number?
		return jugador:GetAttribute("Base")
	end

	local function refrescarJugador()
		-- Mochila
		local carga = jugador:GetAttribute("Carga") or 0
		local capacidad = jugador:GetAttribute("Capacidad") or Config.MOCHILA.BASE
		cargaTxt.Text = string.format("%d/%d", carga, capacidad)
		cargaTxt.TextColor3 = if carga >= capacidad then T.rojo else T.texto
		barraCarga.poner(carga / math.max(capacidad, 1), nil, if carga >= capacidad then T.rojo else T.ambar)
		local valor = 0
		for id, c in casillas do
			local n = jugador:GetAttribute("M_" .. id) or 0
			c.marco.Visible = n > 0
			c.n.Text = tostring(n)
			valor += n * OBJETOS[id].valor
		end
		vaciaTxt.Visible = carga == 0
		valorTxt.Text = if carga > 0 then "💰 Llevas " .. valor .. " de valor: ¡guárdalo en tu base!" else ""
		local function cuenta(ids: { string })
			local n = 0
			for _, id in ids do
				n += jugador:GetAttribute("M_" .. id) or 0
			end
			return n
		end
		botonComer.TextTransparency = if cuenta({ "Lata", "Bayas" }) > 0 then 0 else 0.55
		botonBeber.TextTransparency = if cuenta({ "Agua" }) > 0 then 0 else 0.55
		botonCurar.TextTransparency = if cuenta({ "Botiquin" }) > 0 then 0 else 0.55

		-- Hambre y sed
		local hambre = jugador:GetAttribute("Hambre") or S.MAXIMO
		local sed = jugador:GetAttribute("Sed") or S.MAXIMO
		barraHambre.poner(hambre / S.MAXIMO, string.format("Hambre  %d%%", math.floor(hambre)), if hambre < S.AVISO then T.rojo else T.comida)
		barraSed.poner(sed / S.MAXIMO, string.format("Sed  %d%%", math.floor(sed)), if sed < S.AVISO then T.rojo else T.agua)

		-- Base
		local i = base()
		local datos = i and Config.BASES[i]
		if datos then
			baseTitulo.Text = "🏠 BASE " .. string.upper(datos.nombre)
			baseTitulo.TextColor3 = datos.color
			franjaBase.BackgroundColor3 = datos.color
		else
			baseTitulo.Text = "🏠 SIN BASE"
			baseTitulo.TextColor3 = T.textoSuave
		end
		reservaTxt.Text = "💰 Reserva  " .. (jugador:GetAttribute("Reserva") or 0)
		local partes = {}
		for _, info in { { "Candado", "🔒" }, { "Trampa", "⚡" }, { "Colector", "🌧️" }, { "Huerto", "🌱" } } do
			local tiene = jugador:GetAttribute("Mejora_" .. info[1]) == true
			table.insert(partes, if tiene then info[2] else '<font transparency="0.75">' .. info[2] .. "</font>")
		end
		mejorasTxt.Text = table.concat(partes, "  ")
		-- Armas (👹 monstruos, 🎯 distancia, 🧤 mano) y protección
		local function nombre(id: string?): string
			local m = id and Config.mejora(id)
			if m then
				return m.nombre
			end
			return if id == "Tubo" then "Tubo" elseif id == "Manos" then "Manos gigantes" else "—"
		end
		local arma = jugador:GetAttribute("Arma")
		local datosArma = arma and Config.ARMAS[arma]
		local distancia = jugador:GetAttribute("ArmaDistancia")
		local proteccion = jugador:GetAttribute("Proteccion") or 0
		local enCasa = jugador:GetAttribute("EnSuBase") == true
		local ambar = Interfaz.hex(T.ambar)
		armaTxt.Text = string.format(
			'⚔️ %s <font color="%s">%d</font>%s\n🧤 %s   🛡️ %d%%%s',
			nombre(arma),
			ambar,
			if datosArma then datosArma.dano else 0,
			if distancia then "   🎯 " .. nombre(distancia) else "",
			nombre(jugador:GetAttribute("ArmaMano")),
			proteccion,
			if enCasa then ' <font color="#8ad66e">+ en casa</font>' else ""
		)
	end

	-- 🎯 El consejo cambia según lo que te pasa
	local function textoConsejo(): string
		local hum = jugador.Character and jugador.Character:FindFirstChildOfClass("Humanoid")
		local function tiene(id: string): boolean
			return (jugador:GetAttribute("M_" .. id) or 0) > 0
		end
		local hambre = jugador:GetAttribute("Hambre") or 100
		local sed = jugador:GetAttribute("Sed") or 100
		local carga = jugador:GetAttribute("Carga") or 0
		local capacidad = jugador:GetAttribute("Capacidad") or Config.MOCHILA.BASE
		if hum and hum.Health > 0 and hum.Health < 35 then
			return if tiene("Botiquin") then "🩹 ¡Te queda poca vida! Cúrate con un botiquín [C]" else "🩹 ¡Poca vida! Come y bebe bien para recuperarte, o busca un botiquín"
		end
		if sed < S.AVISO then
			return if tiene("Agua") then "💧 Tienes mucha sed: bebe [G]" else "💧 ¡Mucha sed! Ve a un pozo o una charca (💧 en el radar) o a la cisterna del Nexo"
		end
		if hambre < S.AVISO then
			return if tiene("Lata") or tiene("Bayas") then "🍖 Tienes mucha hambre: come [F]" else "🍖 ¡Mucha hambre! Busca arbustos de bayas 🍇 o latas 🥫 en las cajas"
		end
		if jugador:GetAttribute("Ladron") then
			return "🦹 ¡Huye a tu base y guarda lo robado antes de que te atrapen!"
		end
		if estado:GetAttribute("LluviaActiva") then
			return "🪂 ¡Están cayendo cajas! Las del suelo son las mejores... pero ahí abajo están ellos"
		end
		if carga >= capacidad then
			return "🎒 Mochila llena: vuelve a tu base y guárdalo todo en el almacén"
		end
		if (estado:GetAttribute("ProximaLluvia") or 999) <= Config.LLUVIA.AVISO then
			return "⚠️ La lluvia llega enseguida: guarda lo que llevas y prepárate para salir"
		end
		if carga > 0 then
			return "🏠 Lleva lo que tienes a tu almacén: así cuenta para tu Reserva 💰"
		end
		if (estado:GetAttribute("CajasRestantes") or 0) > 0 then
			return "📦 Aún quedan cajas sin abrir por el anillo (mira el radar)"
		end
		if estado:GetAttribute("Fase") == "Noche" then
			return "🌙 De noche salen los Rabiosos: muévete por las pasarelas y las torres"
		end
		return "🌲 Mientras llega la lluvia: bayas 🍇, pozos 💧 y coches ⚙️. Con chatarra mejoras tu base 🔨"
	end

	-- Flecha y distancia hasta tu base, chip de ladrón y consejo (cada poco)
	local function refrescarCerca()
		consejoTxt.Text = "🎯  " .. textoConsejo()
		local i = base()
		local personaje = jugador.Character
		local raiz = personaje and personaje:FindFirstChild("HumanoidRootPart") :: BasePart?
		local camara = workspace.CurrentCamera
		if i and raiz and camara then
			local centro = Config.centroBase(i)
			local dif = Vector3.new(centro.X - raiz.Position.X, 0, centro.Z - raiz.Position.Z)
			local enBase = dif.Magnitude <= Config.MAPA.MEDIO_BASE + 2 and math.abs(centro.Y - raiz.Position.Y) < 14
			if enBase then
				distanciaTxt.Text = "📍 Estás en tu base"
				flecha.Visible = false
			else
				distanciaTxt.Text = string.format("a %d m de tu base", math.floor(dif.Magnitude * 0.28 + 0.5))
				flecha.Visible = true
				flecha.Rotation = yaw(dif) - yaw(camara.CFrame.LookVector)
			end
		else
			distanciaTxt.Text = ""
			flecha.Visible = false
		end
		local ladron = jugador:GetAttribute("Ladron") == true
		chipLadron.Visible = ladron and not alerta.Visible
		if ladron then
			local quedan = math.max(0, (jugador:GetAttribute("LadronHasta") or 0) - os.time())
			chipLadronTxt.Text = string.format("🦹 Eres un LADRÓN durante %d s: todos te ven en el radar", quedan)
		end
		-- El panel de la lluvia late cuando falta poco
		if not estado:GetAttribute("LluviaActiva") and (estado:GetAttribute("ProximaLluvia") or 999) <= Config.LLUVIA.AVISO then
			trazoLluvia.Transparency = if trazoLluvia.Transparency < 0.3 then 0.7 else 0
			iconoLluvia.Rotation = if iconoLluvia.Rotation == 0 then 8 else 0
		elseif estado:GetAttribute("LluviaActiva") then
			iconoLluvia.Rotation = math.sin(os.clock() * 6) * 10
		else
			iconoLluvia.Rotation = 0
		end
	end

	local function conectarPersonaje(personaje: Model)
		local hum = personaje:WaitForChild("Humanoid", 10) :: Humanoid?
		if not hum then
			return
		end
		local anterior = hum.Health
		local function vida()
			local f = hum.Health / math.max(hum.MaxHealth, 1)
			barraVida.poner(f, string.format("Vida  %d", math.ceil(hum.Health)), if f < 0.3 then T.rojo else T.vida)
			if hum.Health < anterior - 0.5 then
				dano.BackgroundTransparency = 0.78
				TweenService:Create(dano, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
			end
			anterior = hum.Health
			if not alerta.Visible then
				ponerBordes(if f < 0.3 and hum.Health > 0 then 0.45 + f else 1, rgb(150, 0, 0))
			end
		end
		vida()
		hum.HealthChanged:Connect(vida)
	end

	estado.AttributeChanged:Connect(refrescarLluvia)
	jugador.AttributeChanged:Connect(refrescarJugador)
	jugador.CharacterAdded:Connect(conectarPersonaje)
	if jugador.Character then
		task.spawn(conectarPersonaje, jugador.Character)
	end
	refrescarLluvia()
	refrescarJugador()
	task.spawn(function()
		while true do
			refrescarCerca()
			task.wait(0.25)
		end
	end)

	return hud
end

return Hud
