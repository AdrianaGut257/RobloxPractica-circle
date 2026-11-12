-- Piezas de interfaz reutilizables con el estilo CARTOON del juego: colores vivos, bordes gruesos
-- oscuros, letra redonda (Fredoka), textos con contorno y botones que rebotan al pulsarlos.
-- Para cambiar los colores de toda la pantalla, toca Interfaz.TEMA.
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Interfaz = {}

local rgb = Color3.fromRGB

Interfaz.TEMA = {
	-- Paneles
	panel = rgb(46, 56, 92), -- azul marino
	panelClaro = rgb(66, 80, 128),
	panelOscuro = rgb(30, 36, 62),
	panelTransparencia = 0.04,
	borde = rgb(18, 20, 36), -- contorno grueso de todo
	-- Textos
	texto = rgb(255, 255, 255),
	textoSuave = rgb(196, 208, 240),
	-- Colores vivos
	ambar = rgb(255, 196, 36),
	oro = rgb(255, 214, 54),
	naranja = rgb(255, 140, 40),
	rojo = rgb(255, 72, 80),
	verde = rgb(96, 222, 88),
	azul = rgb(64, 160, 255),
	morado = rgb(166, 102, 255),
	rosa = rgb(255, 102, 178),
	agua = rgb(64, 182, 255),
	comida = rgb(255, 150, 48),
	vida = rgb(255, 72, 96),
	noche = rgb(150, 156, 255),
	-- Botones
	botonVerde = rgb(76, 200, 76),
	botonAzul = rgb(56, 150, 255),
	botonNaranja = rgb(255, 150, 30),
	botonRojo = rgb(240, 70, 70),
	botonMorado = rgb(150, 92, 240),
	botonAmarillo = rgb(250, 196, 30),
	botonGris = rgb(110, 116, 140),
	-- Letras
	fuente = Enum.Font.FredokaOne,
	fuenteMedia = Enum.Font.GothamBold,
	fuenteTitulo = Enum.Font.FredokaOne,
	fuenteNumeros = Enum.Font.FredokaOne,
	fuenteCartel = Enum.Font.FredokaOne,
}
local T = Interfaz.TEMA

-- Crea una instancia con propiedades e hijos.
function Interfaz.crear(clase: string, props, hijos)
	local obj = Instance.new(clase)
	for clave, valor in props do
		if clave ~= "Parent" then
			(obj :: any)[clave] = valor
		end
	end
	if hijos then
		for _, h in hijos do
			h.Parent = obj
		end
	end
	obj.Parent = props.Parent
	return obj
end
local crear = Interfaz.crear

function Interfaz.esquinas(radio: number?)
	return crear("UICorner", { CornerRadius = UDim.new(0, radio or 14) })
end

-- Contorno de un panel o botón (por defecto: grueso y oscuro, el sello del estilo cartoon).
function Interfaz.contorno(color: Color3?, grosor: number?, transparencia: number?)
	return crear("UIStroke", {
		Color = color or T.borde,
		Thickness = grosor or 3,
		Transparency = transparencia or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Round,
	})
end

-- Brillo de arriba abajo (da volumen a paneles y botones).
function Interfaz.brillo(padre: Instance, fuerza: number?)
	local f = fuerza or 0.22
	return crear("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(1 - f, 1 - f, 1 - f)),
		Parent = padre,
	})
end

function Interfaz.relleno(px: number, horizontal: number?)
	return crear("UIPadding", {
		PaddingTop = UDim.new(0, px),
		PaddingBottom = UDim.new(0, px),
		PaddingLeft = UDim.new(0, horizontal or px),
		PaddingRight = UDim.new(0, horizontal or px),
	})
end

function Interfaz.lista(espacio: number?, horizontal: boolean?)
	return crear("UIListLayout", {
		Padding = UDim.new(0, espacio or 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		FillDirection = if horizontal then Enum.FillDirection.Horizontal else Enum.FillDirection.Vertical,
	})
end

-- Panel azul con esquinas redondas, borde grueso oscuro y un poco de brillo.
function Interfaz.panel(props)
	props.BackgroundColor3 = props.BackgroundColor3 or T.panel
	props.BackgroundTransparency = props.BackgroundTransparency or T.panelTransparencia
	props.BorderSizePixel = 0
	local p = crear("Frame", props, { Interfaz.esquinas(16), Interfaz.contorno() })
	Interfaz.brillo(p, 0.18)
	return p
end

-- Contorno oscuro alrededor de las letras (como en los dibujos animados).
local function bordeTexto(etiqueta: TextLabel | TextButton, tam: number)
	crear("UIStroke", {
		Color = T.borde,
		Thickness = math.clamp(tam / 9, 1.2, 3.5),
		Transparency = 0.05,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
		LineJoinMode = Enum.LineJoinMode.Round,
		Parent = etiqueta,
	})
end

-- Texto. Por defecto lleva contorno oscuro; props.sinBorde = true para quitarlo.
function Interfaz.texto(props)
	local sinBorde = props.sinBorde
	props.sinBorde = nil
	props.BackgroundTransparency = 1
	props.Font = props.Font or T.fuente
	props.TextColor3 = props.TextColor3 or T.texto
	props.TextSize = props.TextSize or 16
	props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
	local t = crear("TextLabel", props)
	if not sinBorde then
		bordeTexto(t, props.TextSize)
	end
	return t
end

-- Hace que un botón rebote: crece al pasar el ratón y se aplasta al pulsar.
function Interfaz.rebote(boton: GuiButton)
	local escala = boton:FindFirstChild("Rebote") :: UIScale?
	if not escala then
		escala = crear("UIScale", { Name = "Rebote", Parent = boton })
	end
	local info = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local function a(valor: number)
		TweenService:Create(escala :: UIScale, info, { Scale = valor }):Play()
	end
	boton.MouseEnter:Connect(function()
		a(1.06)
	end)
	boton.MouseLeave:Connect(function()
		a(1)
	end)
	boton.MouseButton1Down:Connect(function()
		a(0.92)
	end)
	boton.MouseButton1Up:Connect(function()
		TweenService:Create(escala :: UIScale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	end)
end

-- Botón de color con borde grueso, brillo y rebote. props.color = color de fondo.
function Interfaz.boton(props)
	local color = props.color or T.botonAzul
	props.color = nil
	props.BackgroundColor3 = color
	props.BorderSizePixel = 0
	props.Font = props.Font or T.fuente
	props.TextColor3 = props.TextColor3 or T.texto
	props.TextSize = props.TextSize or 15
	props.AutoButtonColor = false
	local b = crear("TextButton", props, { Interfaz.esquinas(12), Interfaz.contorno() })
	Interfaz.brillo(b, 0.28)
	bordeTexto(b, props.TextSize)
	Interfaz.rebote(b)
	return b
end

-- Barra de progreso gorda y redonda. Devuelve una tabla con poner(fraccion, texto?, color?).
function Interfaz.barra(props)
	local color = props.color or T.ambar
	props.color = nil
	props.BackgroundColor3 = T.panelOscuro
	props.BackgroundTransparency = 0
	props.BorderSizePixel = 0
	local marco = crear("Frame", props, {
		crear("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
		Interfaz.contorno(T.borde, 2.5),
	})
	local relleno = crear("Frame", {
		Name = "Relleno",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Parent = marco,
	}, { crear("UICorner", { CornerRadius = UDim.new(0.5, 0) }) })
	Interfaz.brillo(relleno, 0.3)
	-- Reflejo blanco arriba
	crear("Frame", {
		Position = UDim2.new(0, 4, 0.14, 0),
		Size = UDim2.new(1, -8, 0.24, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.65,
		BorderSizePixel = 0,
		Parent = relleno,
	}, { crear("UICorner", { CornerRadius = UDim.new(0.5, 0) }) })
	local etiqueta = Interfaz.texto({
		Size = UDim2.fromScale(1, 1),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextSize = 14,
		Text = "",
		ZIndex = 2,
		Parent = marco,
	})
	local barra = { marco = marco, relleno = relleno }
	function barra.poner(fraccion: number, texto: string?, nuevoColor: Color3?)
		local f = math.clamp(fraccion, 0, 1)
		TweenService:Create(relleno, TweenInfo.new(0.25), { Size = UDim2.fromScale(f, 1) }):Play()
		relleno.Visible = f > 0.001
		if texto then
			etiqueta.Text = texto
		end
		if nuevoColor then
			relleno.BackgroundColor3 = nuevoColor
		end
	end
	return barra
end

-- Rayas de peligro (para la lluvia y las alertas).
function Interfaz.rayas(padre: GuiObject, color: Color3?)
	local c = color or T.ambar
	local negro = T.borde
	local puntos = {}
	local bandas = 9
	for i = 0, bandas - 1 do
		local a = i / bandas
		local b = (i + 1) / bandas
		local col = if i % 2 == 0 then c else negro
		table.insert(puntos, ColorSequenceKeypoint.new(a, col))
		table.insert(puntos, ColorSequenceKeypoint.new(math.max(a, b - 0.001), col))
	end
	puntos[#puntos] = ColorSequenceKeypoint.new(1, puntos[#puntos].Value)
	return crear("UIGradient", { Color = ColorSequence.new(puntos), Rotation = 20, Parent = padre })
end

-- Muestra u oculta una ventana (CanvasGroup) con un fundido y un pequeño «salto».
function Interfaz.fundido(objeto: CanvasGroup, visible: boolean, duracion: number?)
	local d = duracion or 0.2
	local salto = objeto:FindFirstChild("Salto") :: UIScale?
	if not salto then
		salto = crear("UIScale", { Name = "Salto", Parent = objeto })
	end
	local escala = salto :: UIScale
	if visible then
		objeto.Visible = true
		escala.Scale = 0.85
		TweenService:Create(escala, TweenInfo.new(d + 0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	else
		TweenService:Create(escala, TweenInfo.new(d, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.9 }):Play()
	end
	local t = TweenService:Create(objeto, TweenInfo.new(d), { GroupTransparency = if visible then 0 else 1 })
	t:Play()
	if not visible then
		t.Completed:Connect(function(estado)
			if estado == Enum.PlaybackState.Completed then
				objeto.Visible = false
			end
		end)
	end
end

-- En móvil (pantalla táctil sin teclado) el radar va arriba; en ordenador, abajo a la derecha
-- (arriba a la derecha está la lista de jugadores de Roblox y lo taparía).
function Interfaz.esMovil(): boolean
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

function Interfaz.formatoTiempo(segundos: number): string
	local s = math.max(0, math.floor(segundos))
	return string.format("%d:%02d", s // 60, s % 60)
end

function Interfaz.hex(c: Color3): string
	return string.format("#%02x%02x%02x", math.floor(c.R * 255), math.floor(c.G * 255), math.floor(c.B * 255))
end

-- Botón ✕ rojo y redondo para cerrar ventanas (Modal: libera el ratón aunque estés en primera persona).
function Interfaz.botonCerrar(padre: Instance, _color: Color3?)
	local b = crear("TextButton", {
		Text = "✕",
		Font = T.fuente,
		TextSize = 22,
		TextColor3 = T.texto,
		BackgroundColor3 = T.botonRojo,
		AutoButtonColor = false,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 12),
		Size = UDim2.fromOffset(42, 42),
		Modal = true,
		ZIndex = 5,
		Parent = padre,
	}, { crear("UICorner", { CornerRadius = UDim.new(0.5, 0) }), Interfaz.contorno() })
	Interfaz.brillo(b, 0.3)
	bordeTexto(b, 22)
	Interfaz.rebote(b)
	return b
end

return Interfaz
