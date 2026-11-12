-- Ventanas: el almacén de tu base, la mesa de mejoras, las bases (para mudarte), tus estadísticas
-- y la ayuda (sale la primera vez).
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Interfaz = require(script.Parent.Interfaz)

local Ventanas = {}

local T = Interfaz.TEMA
local crear = Interfaz.crear
local OBJETOS = Config.OBJETOS
local ORDEN = Config.ORDEN_OBJETOS

function Ventanas.crear(gui: ScreenGui, remotos: Folder)
	local jugador = Players.LocalPlayer
	local v = {}
	local ventanas: { [string]: CanvasGroup } = {}

	local function miBase(): Instance?
		local i = jugador:GetAttribute("Base")
		if not i then
			return nil
		end
		for _, b in CollectionService:GetTagged("Base") do
			if b:GetAttribute("Indice") == i then
				return b
			end
		end
		return nil
	end
	local function enAlmacen(id: string): number
		local b = miBase()
		return if b then (b:GetAttribute("A_" .. id) or 0) else 0
	end
	local function enMochila(id: string): number
		return jugador:GetAttribute("M_" .. id) or 0
	end

	-- Esqueleto de una ventana: cabecera con título, subtítulo y ✕
	local function ventana(nombre: string, ancho: number, alto: number, acento: Color3)
		local g = crear("CanvasGroup", {
			Name = nombre,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.53),
			Size = UDim2.fromOffset(ancho, alto),
			BackgroundColor3 = T.panel,
			BackgroundTransparency = 0,
			GroupTransparency = 1,
			Visible = false,
			ZIndex = 10,
			Parent = gui,
		}, { Interfaz.esquinas(22), Interfaz.contorno(T.borde, 4) })
		local cabecera = crear("Frame", { Size = UDim2.new(1, 0, 0, 72), BackgroundColor3 = acento, BorderSizePixel = 0, Parent = g })
		Interfaz.brillo(cabecera, 0.25)
		local linea = crear("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 5), BackgroundColor3 = T.borde, BorderSizePixel = 0, Parent = cabecera })
		local titulo = Interfaz.texto({ Font = T.fuenteTitulo, TextSize = 30, Position = UDim2.fromOffset(20, 8), Size = UDim2.new(1, -230, 0, 34), Text = "", Parent = cabecera })
		local sub = Interfaz.texto({ Font = T.fuenteMedia, TextSize = 13, TextWrapped = true, Position = UDim2.fromOffset(20, 42), Size = UDim2.new(1, -230, 0, 24), Text = "", Parent = cabecera })
		local cerrar = Interfaz.botonCerrar(g)
		local cuerpo = crear("Frame", { Position = UDim2.fromOffset(0, 72), Size = UDim2.new(1, 0, 1, -72), BackgroundTransparency = 1, Parent = g })
		ventanas[nombre] = g
		cerrar.Activated:Connect(function()
			Interfaz.fundido(g, false)
		end)
		return { grupo = g, titulo = titulo, sub = sub, cuerpo = cuerpo, cabecera = cabecera, linea = linea }
	end

	function v.cerrarTodo()
		for _, g in ventanas do
			if g.Visible then
				Interfaz.fundido(g, false)
			end
		end
	end

	local function abrir(nombre: string)
		for otro, g in ventanas do
			if otro ~= nombre and g.Visible then
				Interfaz.fundido(g, false, 0.1)
			end
		end
		Interfaz.fundido(ventanas[nombre], true)
	end

	-- 📦 Almacén ----------------------------------------------------------------------------------
	local alm = ventana("Almacen", 820, 560, T.naranja)
	alm.titulo.Text = "📦 TU ALMACÉN"
	alm.sub.Text = "Lo que guardas aquí suma a tu Reserva 💰 (el marcador). ¡Pero otros jugadores te lo pueden robar!"
	local reservaAlm = Interfaz.texto({
		Font = T.fuenteNumeros,
		TextSize = 32,
		TextColor3 = T.oro,
		TextXAlignment = Enum.TextXAlignment.Right,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -56, 0, 16),
		Size = UDim2.fromOffset(160, 40),
		Text = "💰 0",
		Parent = alm.cabecera,
	})

	local function columna(x: number, titulo: string)
		local c = crear("Frame", { Position = UDim2.new(x, 16, 0, 12), Size = UDim2.new(0.5, -24, 1, -92), BackgroundTransparency = 1, Parent = alm.cuerpo })
		local cab = Interfaz.texto({ Font = T.fuenteTitulo, TextSize = 15, TextColor3 = T.ambar, Size = UDim2.new(1, 0, 0, 22), Text = titulo, Parent = c })
		local lista = crear("ScrollingFrame", {
			Position = UDim2.fromOffset(0, 28),
			Size = UDim2.new(1, 0, 1, -28),
			BackgroundColor3 = T.panelOscuro,
			BackgroundTransparency = 0.3,
			BorderSizePixel = 0,
			ScrollBarThickness = 5,
			ScrollBarImageColor3 = T.ambar,
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			Parent = c,
		}, { Interfaz.esquinas(10), Interfaz.relleno(8), Interfaz.lista(6) })
		local vacio = Interfaz.texto({ Font = T.fuenteMedia, TextSize = 14, TextColor3 = T.textoSuave, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.new(1, 0, 0, 60), LayoutOrder = 99, Text = "", Parent = lista })
		return cab, lista, vacio
	end
	local cabMochila, listaMochila, vacioMochila = columna(0, "🎒 TU MOCHILA")
	local cabAlmacen, listaAlmacen, vacioAlmacen = columna(0.5, "🏠 EN TU ALMACÉN")
	vacioMochila.Text = "No llevas nada.\nSal a buscar cajas 🪂, bayas 🍇 y agua 💧"
	vacioAlmacen.Text = "El almacén está vacío.\nGuarda aquí lo que traigas."

	local function fila(lista: ScrollingFrame, id: string, orden: number, botones)
		local datos = OBJETOS[id]
		local f = crear("Frame", { Size = UDim2.new(1, 0, 0, 52), BackgroundColor3 = T.panelClaro, BackgroundTransparency = 0.1, LayoutOrder = orden, Visible = false, Parent = lista }, { Interfaz.esquinas(10) })
		crear("TextLabel", {
			Position = UDim2.fromOffset(8, 8),
			Size = UDim2.fromOffset(36, 36),
			BackgroundColor3 = T.panelOscuro,
			Text = datos.icono,
			TextSize = 22,
			Font = T.fuente,
			TextColor3 = T.texto,
			Parent = f,
		}, { Interfaz.esquinas(18), Interfaz.contorno(datos.color, 3, 0) })
		Interfaz.texto({ Font = T.fuente, TextSize = 14, Position = UDim2.fromOffset(52, 8), Size = UDim2.new(1, -200, 0, 18), Text = datos.nombre, TextTruncate = Enum.TextTruncate.AtEnd, Parent = f })
		local detalle = Interfaz.texto({ Font = T.fuenteMedia, TextSize = 12, TextColor3 = T.textoSuave, Position = UDim2.fromOffset(52, 28), Size = UDim2.new(1, -200, 0, 16), Text = "", Parent = f })
		local n = Interfaz.texto({ Font = T.fuenteNumeros, TextSize = 24, TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -140, 0, 10), Size = UDim2.fromOffset(46, 32), Text = "0", Parent = f })
		local caja = crear("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(126, 34), BackgroundTransparency = 1, Parent = f }, {
			crear("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
		})
		for i, b in botones do
			local boton = Interfaz.boton({ Text = b[1], TextSize = 13, Size = UDim2.fromOffset(b[3] or 60, 34), LayoutOrder = i, color = b[4], Parent = caja })
			boton.Activated:Connect(b[2])
		end
		return { marco = f, n = n, detalle = detalle }
	end

	local filasMochila, filasAlmacen = {}, {}
	for i, id in ORDEN do
		filasMochila[id] = fila(listaMochila, id, i, {
			{
				"Guardar",
				function()
					remotos.Guardar:FireServer(id, 1)
				end,
				64,
			},
			{
				"Todo",
				function()
					remotos.Guardar:FireServer(id, 9999)
				end,
				56,
				T.botonAmarillo,
			},
		})
		local botones = {
			{
				"Sacar",
				function()
					remotos.Sacar:FireServer(id, 1)
				end,
				58,
			},
		}
		if OBJETOS[id].uso then
			table.insert(botones, {
				"Usar",
				function()
					remotos.Usar:FireServer(id, true)
				end,
				54,
				T.botonVerde,
			})
		end
		filasAlmacen[id] = fila(listaAlmacen, id, i, botones)
	end

	local pie = crear("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 16, 1, -14), Size = UDim2.new(1, -32, 0, 52), BackgroundTransparency = 1, Parent = alm.cuerpo })
	local guardarTodo = Interfaz.boton({ Text = "⬇  GUARDAR TODO", Font = T.fuenteTitulo, TextSize = 17, Size = UDim2.fromOffset(250, 48), color = T.botonNaranja, Parent = pie })
	Interfaz.texto({
		Font = T.fuenteMedia,
		TextSize = 13,
		TextColor3 = T.textoSuave,
		TextWrapped = true,
		Position = UDim2.fromOffset(266, 0),
		Size = UDim2.new(1, -266, 1, 0),
		Text = "💡 Con chatarra ⚙️ puedes poner un candado 🔒 y una trampa ⚡ en la mesa de trabajo 🔨. Los «Usar» comen o beben directamente del almacén.",
		Parent = pie,
	})
	guardarTodo.Activated:Connect(function()
		remotos.Guardar:FireServer("todo")
	end)

	local function refrescarAlmacen()
		if not alm.grupo.Visible then
			return
		end
		local carga, capacidad = jugador:GetAttribute("Carga") or 0, jugador:GetAttribute("Capacidad") or Config.MOCHILA.BASE
		cabMochila.Text = string.format("🎒 TU MOCHILA   %d/%d", carga, capacidad)
		local totalAlm = 0
		for _, id in ORDEN do
			local datos = OBJETOS[id]
			local m, a = enMochila(id), enAlmacen(id)
			totalAlm += a
			local fm, fa = filasMochila[id], filasAlmacen[id]
			fm.marco.Visible = m > 0
			fm.n.Text = tostring(m)
			fm.detalle.Text = string.format("vale %d 💰 cada uno", datos.valor)
			fa.marco.Visible = a > 0
			fa.n.Text = tostring(a)
			fa.detalle.Text = string.format("vale %d 💰  ·  total %d", datos.valor, datos.valor * a)
		end
		vacioMochila.Visible = carga == 0
		vacioAlmacen.Visible = totalAlm == 0
		cabAlmacen.Text = string.format("🏠 EN TU ALMACÉN   %d objetos", totalAlm)
		reservaAlm.Text = "💰 " .. (jugador:GetAttribute("Reserva") or 0)
		local i = jugador:GetAttribute("Base")
		if i and Config.BASES[i] then
			alm.linea.BackgroundColor3 = Config.BASES[i].color
		end
	end

	function v.abrirAlmacen()
		abrir("Almacen")
		refrescarAlmacen()
	end

	-- 🔨 Mejoras -----------------------------------------------------------------------------------
	local mej = ventana("Mejoras", 860, 620, T.azul)
	mej.titulo.Text = "🔨 MESA DE TRABAJO"
	mej.sub.Text = "Mejora tu base, fabrica armas y protégete. Pagas con lo que tienes en el almacén y en la mochila."
	local materiales = Interfaz.texto({
		Font = T.fuente,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Right,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -56, 0, 24),
		Size = UDim2.fromOffset(200, 24),
		Text = "",
		Parent = mej.cabecera,
	})

	-- Pestañas: 🏠 Base · 👹 Monstruos · 🧤 De mano · 🛡️ Protección
	local PESTANAS = {
		{ id = "base", texto = "🏠 BASE" },
		{ id = "monstruos", texto = "👹 MONSTRUOS" },
		{ id = "mano", texto = "🧤 DE MANO" },
		{ id = "proteccion", texto = "🛡️ PROTECCIÓN" },
	}
	local pestanaActual = "base"
	local barraPestanas = crear("Frame", { Position = UDim2.fromOffset(16, 12), Size = UDim2.new(1, -32, 0, 36), BackgroundTransparency = 1, Parent = mej.cuerpo }, { Interfaz.lista(8, true) })
	local botonesPestana = {}
	local consejoPestana = Interfaz.texto({
		Font = T.fuenteMedia,
		TextSize = 13,
		TextColor3 = T.textoSuave,
		TextWrapped = true,
		Position = UDim2.fromOffset(16, 54),
		Size = UDim2.new(1, -32, 0, 34),
		Text = "",
		Parent = mej.cuerpo,
	})
	local CONSEJOS = {
		base = "Mochilas más grandes, agua y comida que salen solas, y botiquines.",
		monstruos = "Solo hacen daño a los monstruos. Las 🎯 disparan solas al que tengas delante (¡también desde tu torre!). Llevas la mejor de cada tipo.",
		mano = "Para jugar con otros jugadores: casi no hacen daño, pero EMPUJAN. ¡Cuidado en las pasarelas!",
		proteccion = string.format(
			"La armadura te quita daño de jugadores y enemigos. Dentro de tu base los jugadores te hacen un %d %% menos.",
			math.floor(Config.DEFENSA.EN_TU_BASE * 100)
		),
	}
	local refrescarMejoras: () -> ()
	local rejilla = crear("ScrollingFrame", {
		Position = UDim2.fromOffset(16, 94),
		Size = UDim2.new(1, -32, 1, -108),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 5,
		ScrollBarImageColor3 = T.ambar,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = mej.cuerpo,
	}, {
		crear("UIGridLayout", { CellSize = UDim2.new(0.5, -8, 0, 124), CellPadding = UDim2.fromOffset(10, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	local tarjetas = {}
	for i, m in Config.MEJORAS do
		local t = crear("Frame", { BackgroundColor3 = T.panelClaro, LayoutOrder = i, Parent = rejilla }, { Interfaz.esquinas(12) })
		local trazo = Interfaz.contorno(T.borde, 3, 0)
		trazo.Parent = t
		crear("TextLabel", {
			Position = UDim2.fromOffset(12, 14),
			Size = UDim2.fromOffset(56, 56),
			BackgroundColor3 = T.panelOscuro,
			Text = m.icono,
			TextSize = 32,
			Font = T.fuente,
			TextColor3 = T.texto,
			Parent = t,
		}, { Interfaz.esquinas(12) })
		Interfaz.texto({ Font = T.fuenteTitulo, TextSize = 16, Position = UDim2.fromOffset(80, 12), Size = UDim2.new(1, -92, 0, 20), Text = m.nombre, Parent = t })
		Interfaz.texto({ Font = T.fuenteMedia, TextSize = 13, TextColor3 = T.textoSuave, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, Position = UDim2.fromOffset(80, 34), Size = UDim2.new(1, -92, 0, 34), Text = m.texto, Parent = t })
		local coste = Interfaz.texto({ Font = T.fuente, TextSize = 15, RichText = true, Position = UDim2.new(0, 12, 1, -40), Size = UDim2.new(1, -170, 0, 30), Text = "", Parent = t })
		local boton = Interfaz.boton({ Text = "", Font = T.fuenteTitulo, TextSize = 13, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -12, 1, -10), Size = UDim2.fromOffset(146, 34), Parent = t })
		boton.Activated:Connect(function()
			remotos.Mejorar:FireServer(m.id)
		end)
		tarjetas[m.id] = { boton = boton, coste = coste, trazo = trazo, marco = t, categoria = m.categoria or "base" }
	end

	local function ponerPestana(id: string)
		pestanaActual = id
		for pid, b in botonesPestana do
			local activa = pid == id
			b.BackgroundColor3 = if activa then T.botonNaranja else T.botonGris
			b.TextColor3 = if activa then T.texto else T.textoSuave
		end
		for _, t in tarjetas do
			t.marco.Visible = t.categoria == id
		end
		consejoPestana.Text = CONSEJOS[id] or ""
		rejilla.CanvasPosition = Vector2.zero
	end
	for i, p in PESTANAS do
		local b = Interfaz.boton({ Text = p.texto, Font = T.fuenteTitulo, TextSize = 15, Size = UDim2.fromOffset(190, 36), LayoutOrder = i, Parent = barraPestanas })
		b.Activated:Connect(function()
			ponerPestana(p.id)
		end)
		botonesPestana[p.id] = b
	end
	ponerPestana(pestanaActual)

	function refrescarMejoras()
		if not mej.grupo.Visible then
			return
		end
		local function disponible(id: string): number
			return enMochila(id) + enAlmacen(id)
		end
		materiales.Text = string.format("Tienes:  ⚙️ %d   🔋 %d   💧 %d   🥇 %d", disponible("Chatarra"), disponible("Bateria"), disponible("Agua"), disponible("Oro"))
		for _, m in Config.MEJORAS do
			local t = tarjetas[m.id]
			local partes = {}
			local puede = true
			for _, id in ORDEN do
				local n = m.coste[id]
				if n then
					local hay = disponible(id)
					local ok = hay >= n
					puede = puede and ok
					table.insert(partes, string.format('<font color="%s">%s %d</font>', Interfaz.hex(if ok then T.verde else T.rojo), OBJETOS[id].icono, n))
				end
			end
			t.coste.Text = table.concat(partes, "   ")
			local hecho = not m.repetible and jugador:GetAttribute("Mejora_" .. m.id) == true
			local bloqueado = m.requiere and not jugador:GetAttribute("Mejora_" .. m.requiere)
			if hecho then
				t.boton.Text = "✓ HECHO"
				t.boton.BackgroundColor3 = T.botonVerde
				t.boton.AutoButtonColor = false
				t.trazo.Color = T.verde
				t.trazo.Transparency = 0
				t.coste.Text = '<font color="#8ad66e">Ya lo tienes</font>'
			elseif bloqueado then
				local antes = Config.mejora(m.requiere)
				t.boton.Text = "🔒 " .. (if antes then antes.nombre else "")
				t.boton.BackgroundColor3 = T.botonGris
				t.boton.AutoButtonColor = false
				t.trazo.Color = T.borde
				t.trazo.Transparency = 0
			else
				t.boton.Text = if not puede then "FALTA MATERIAL" elseif m.repetible then "FABRICAR" else "CONSTRUIR"
				t.boton.BackgroundColor3 = if puede then T.botonNaranja else T.botonRojo
				t.boton.AutoButtonColor = false
				t.trazo.Color = if puede then T.ambar else T.borde
				t.trazo.Transparency = 0
			end
		end
	end

	function v.abrirMejoras()
		abrir("Mejoras")
		refrescarMejoras()
	end

	-- 🏠 Bases (mudarse) ----------------------------------------------------------------------------
	local vb = ventana("Bases", 740, 600, T.rosa)
	vb.titulo.Text = "🏠 LAS BASES"
	vb.sub.Text = "Puedes mudarte a una base libre. Tu almacén y tus mejoras se vienen contigo."
	local listaBases = crear("ScrollingFrame", {
		Position = UDim2.fromOffset(16, 14),
		Size = UDim2.new(1, -32, 1, -64),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 5,
		ScrollBarImageColor3 = T.ambar,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = vb.cuerpo,
	}, { Interfaz.lista(8) })
	Interfaz.texto({
		Font = T.fuenteMedia,
		TextSize = 13,
		TextColor3 = T.textoSuave,
		TextXAlignment = Enum.TextXAlignment.Center,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 16, 1, -12),
		Size = UDim2.new(1, -32, 0, 30),
		TextWrapped = true,
		Text = string.format("⏳ Solo puedes mudarte una vez cada %d segundos, y no mientras eres LADRÓN 🦹.", Config.CAMBIO_BASE.ESPERA),
		Parent = vb.cuerpo,
	})
	local filasBases = {}
	for i, datos in Config.BASES do
		local f = crear("Frame", { Size = UDim2.new(1, -6, 0, 54), BackgroundColor3 = T.panelClaro, LayoutOrder = i, Parent = listaBases }, { Interfaz.esquinas(10) })
		local trazo = Interfaz.contorno(datos.color, 3, 0.6)
		trazo.Parent = f
		crear("Frame", { Position = UDim2.fromOffset(10, 9), Size = UDim2.fromOffset(36, 36), BackgroundColor3 = datos.color, Parent = f }, { Interfaz.esquinas(18) })
		Interfaz.texto({ Font = T.fuenteTitulo, TextSize = 16, Position = UDim2.fromOffset(58, 8), Size = UDim2.new(1, -230, 0, 20), Text = "BASE " .. string.upper(datos.nombre), TextColor3 = datos.color, Parent = f })
		local estadoTxt = Interfaz.texto({ Font = T.fuenteMedia, TextSize = 13, TextColor3 = T.textoSuave, Position = UDim2.fromOffset(58, 29), Size = UDim2.new(1, -230, 0, 18), Text = "", Parent = f })
		local boton = Interfaz.boton({ Text = "", Font = T.fuenteTitulo, TextSize = 13, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(150, 36), Parent = f })
		boton.Activated:Connect(function()
			remotos.CambiarBase:FireServer(i)
		end)
		filasBases[i] = { estado = estadoTxt, boton = boton, trazo = trazo }
	end

	local function baseConIndice(i: number): Instance?
		for _, b in CollectionService:GetTagged("Base") do
			if b:GetAttribute("Indice") == i then
				return b
			end
		end
		return nil
	end

	local function refrescarBases()
		if not vb.grupo.Visible then
			return
		end
		local mia = jugador:GetAttribute("Base")
		for i, fila in filasBases do
			local b = baseConIndice(i)
			local dueno = b and b:GetAttribute("Dueno")
			if i == mia then
				fila.estado.Text = "Es tu base  ·  💰 " .. tostring(jugador:GetAttribute("Reserva") or 0)
				fila.boton.Text = "✓ AQUÍ VIVES"
				fila.boton.BackgroundColor3 = T.botonVerde
				fila.boton.AutoButtonColor = false
				fila.trazo.Transparency = 0.1
			elseif dueno and b then
				fila.estado.Text = "De " .. tostring(b:GetAttribute("DuenoNombre") or "alguien") .. "  ·  💰 " .. tostring(b:GetAttribute("Reserva") or 0)
				fila.boton.Text = "OCUPADA"
				fila.boton.BackgroundColor3 = T.botonGris
				fila.boton.AutoButtonColor = false
				fila.trazo.Transparency = 0.75
			else
				fila.estado.Text = "Libre"
				fila.boton.Text = "🚚 MUDARME AQUÍ"
				fila.boton.BackgroundColor3 = T.botonNaranja
				fila.boton.AutoButtonColor = false
				fila.trazo.Transparency = 0.4
			end
		end
	end

	function v.alternarBases()
		if vb.grupo.Visible then
			Interfaz.fundido(vb.grupo, false)
		else
			abrir("Bases")
			refrescarBases()
		end
	end

	local function vigilarCambiosBase(b: Instance)
		b.AttributeChanged:Connect(function(nombre)
			if nombre == "Dueno" or nombre == "DuenoNombre" or nombre == "Reserva" then
				refrescarBases()
			end
		end)
	end
	for _, b in CollectionService:GetTagged("Base") do
		vigilarCambiosBase(b)
	end
	CollectionService:GetInstanceAddedSignal("Base"):Connect(vigilarCambiosBase)

	-- 📊 Estadísticas --------------------------------------------------------------------------------
	local ve = ventana("Estadisticas", 780, 620, T.morado)
	ve.titulo.Text = "📊 TUS ESTADÍSTICAS"
	ve.sub.Text = "Todo lo que has hecho en el anillo. Se guarda aunque salgas del juego."
	local diaTxt = Interfaz.texto({
		Font = T.fuenteNumeros,
		TextSize = 22,
		TextColor3 = T.oro,
		TextXAlignment = Enum.TextXAlignment.Right,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -56, 0, 12),
		Size = UDim2.fromOffset(220, 26),
		Text = "",
		Parent = ve.cabecera,
	})
	local rachaTxt = Interfaz.texto({
		Font = T.fuenteMedia,
		TextSize = 13,
		TextColor3 = T.textoSuave,
		TextXAlignment = Enum.TextXAlignment.Right,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -56, 0, 40),
		Size = UDim2.fromOffset(220, 20),
		Text = "",
		Parent = ve.cabecera,
	})
	local rejillaStats = crear("ScrollingFrame", {
		Position = UDim2.fromOffset(16, 14),
		Size = UDim2.new(1, -32, 1, -28),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 5,
		ScrollBarImageColor3 = T.ambar,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = ve.cuerpo,
	}, {
		crear("UIGridLayout", { CellSize = UDim2.new(0.5, -8, 0, 84), CellPadding = UDim2.fromOffset(10, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	local tarjetasStats = {}
	for i, e in Config.ESTADISTICAS do
		local t = crear("Frame", { BackgroundColor3 = T.panelClaro, LayoutOrder = i, Parent = rejillaStats }, { Interfaz.esquinas(14), Interfaz.contorno() })
		Interfaz.texto({ Text = e.icono, TextSize = 28, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(8, 0), Size = UDim2.new(0, 46, 1, 0), Parent = t })
		Interfaz.texto({ Font = T.fuenteTitulo, TextSize = 14, Position = UDim2.fromOffset(60, 10), Size = UDim2.new(1, -150, 0, 18), Text = e.nombre, TextTruncate = Enum.TextTruncate.AtEnd, Parent = t })
		Interfaz.texto({ Font = T.fuenteMedia, TextSize = 12, TextColor3 = T.textoSuave, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, Position = UDim2.fromOffset(60, 30), Size = UDim2.new(1, -150, 0, 30), Text = e.texto, Parent = t })
		local total = Interfaz.texto({ Font = T.fuenteNumeros, TextSize = 30, TextColor3 = T.oro, TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 8), Size = UDim2.fromOffset(84, 36), Text = "0", Parent = t })
		local partida = Interfaz.texto({ Font = T.fuenteMedia, TextSize = 12, TextColor3 = T.textoSuave, TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 50), Size = UDim2.fromOffset(110, 18), Text = "", Parent = t })
		tarjetasStats[e.id] = { total = total, partida = partida, datos = e }
	end

	local estadoPartida = ReplicatedStorage:WaitForChild("Estado")
	local function formato(e, n: number): string
		if e.tiempo then
			return if n >= 60 then string.format("%dh %02dm", n // 60, n % 60) else n .. " min"
		end
		return tostring(n)
	end
	local function refrescarEstadisticas()
		if not ve.grupo.Visible then
			return
		end
		for id, t in tarjetasStats do
			local total = jugador:GetAttribute("E_" .. id) or 0
			local hoy = jugador:GetAttribute("P_" .. id) or 0
			t.total.Text = formato(t.datos, total)
			t.partida.Text = if t.datos.maximo then "hoy: " .. formato(t.datos, hoy) else "hoy: +" .. formato(t.datos, hoy)
		end
		local dia = estadoPartida:GetAttribute("Dia")
		diaTxt.Text = if dia then "🗓️ Día " .. tostring(dia) .. " del servidor" else ""
		rachaTxt.Text = "🔥 Racha ahora: " .. tostring(jugador:GetAttribute("Racha") or 0) .. " días sin caer"
	end
	estadoPartida:GetAttributeChangedSignal("Dia"):Connect(refrescarEstadisticas)

	function v.alternarEstadisticas()
		if ve.grupo.Visible then
			Interfaz.fundido(ve.grupo, false)
		else
			abrir("Estadisticas")
			refrescarEstadisticas()
		end
	end

	-- ❓ Ayuda ---------------------------------------------------------------------------------------
	local ayuda = ventana("Ayuda", 820, 620, T.verde)
	ayuda.titulo.Text = "🌲 EL ANILLO"
	ayuda.sub.Text = "El mundo se acabó y el suelo es de ellos. Vive en lo alto, baja a por las cajas... y guarda lo que puedas."
	local tarjetasAyuda = crear("Frame", { Position = UDim2.fromOffset(16, 14), Size = UDim2.new(1, -32, 1, -118), BackgroundTransparency = 1, Parent = ayuda.cuerpo }, {
		crear("UIGridLayout", { CellSize = UDim2.new(0.5, -8, 0, 116), CellPadding = UDim2.fromOffset(10, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	local SECCIONES = {
		{ "🏠", "Tu base", "Vives en lo alto de una torre. Lo que metes en tu ALMACÉN suma a tu Reserva 💰, que es el marcador. Con chatarra ⚙️ mejoras la base en la mesa 🔨." },
		{
			"🪂",
			"La lluvia de suministros",
			string.format("Cada %d minutos caen cajas por todo el anillo. Las del suelo son las mejores. En el Nido, arriba del Árbol Madre, cae siempre una dorada ⭐.", Config.LLUVIA.INTERVALO // 60),
		},
		{ "🦹", "Robar", "Cuando sales, otros pueden robar tu almacén... y tú el suyo: mantén E en «Robar». El ladrón brilla en rojo y sale en el radar de todos." },
		{ "🍖", "Sobrevivir", "El hambre y la sed bajan solas. Come [F], bebe [G] y cúrate [C]. Hay pozos 💧, charcas, bayas 🍇 y coches ⚙️ para rebuscar." },
		{ "🧟", "El suelo", "Los Errantes patrullan siempre. Los Vigías miran con su luz y avisan a los demás. De noche salen los Rabiosos. ¡No saben subir a las torres!" },
		{ "🧗", "Moverse", "En las cuerdas pulsa E para agarrarte: W sube, S baja, Espacio te suelta. Las pasarelas unen todas las bases con el Nexo del centro. Las tirolinas 🚡 te bajan rápido a las atalayas." },
	}
	for i, s in SECCIONES do
		local t = crear("Frame", { BackgroundColor3 = T.panelClaro, LayoutOrder = i, Parent = tarjetasAyuda }, { Interfaz.esquinas(12) })
		Interfaz.texto({ Text = s[1], TextSize = 30, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(8, 10), Size = UDim2.fromOffset(46, 40), Parent = t })
		Interfaz.texto({ Font = T.fuenteTitulo, TextSize = 16, TextColor3 = T.ambar, Position = UDim2.fromOffset(60, 12), Size = UDim2.new(1, -70, 0, 20), Text = s[2], Parent = t })
		Interfaz.texto({ Font = T.fuenteMedia, TextSize = 13, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, Position = UDim2.fromOffset(60, 36), Size = UDim2.new(1, -70, 1, -42), Text = s[3], Parent = t })
	end
	local pieAyuda = crear("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 16, 1, -14), Size = UDim2.new(1, -32, 0, 88), BackgroundTransparency = 1, Parent = ayuda.cuerpo })
	Interfaz.texto({
		Font = T.fuente,
		TextSize = 14,
		TextColor3 = T.textoSuave,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.new(1, 0, 0, 22),
		Text = "E interactuar  ·  Clic golpear  ·  F comer  ·  G beber  ·  C curar  ·  M mapa  ·  B bases  ·  J estadísticas  ·  H ayuda",
		Parent = pieAyuda,
	})
	local empezar = Interfaz.boton({
		Text = "¡A SOBREVIVIR!",
		Font = T.fuenteTitulo,
		TextSize = 20,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, 0),
		Size = UDim2.fromOffset(280, 52),
		color = T.botonVerde,
		Parent = pieAyuda,
	})
	empezar.Activated:Connect(function()
		Interfaz.fundido(ayuda.grupo, false)
	end)

	function v.alternarAyuda()
		if ayuda.grupo.Visible then
			Interfaz.fundido(ayuda.grupo, false)
		else
			abrir("Ayuda")
		end
	end

	-- Refrescar cuando cambia algo
	local conectadas: { [Instance]: boolean } = {}
	local function vigilarBase()
		local b = miBase()
		if b and not conectadas[b] then
			conectadas[b] = true
			b.AttributeChanged:Connect(function()
				refrescarAlmacen()
				refrescarMejoras()
			end)
		end
	end
	jugador.AttributeChanged:Connect(function(nombre)
		if nombre == "Base" then
			vigilarBase()
		end
		local prefijo = string.sub(nombre, 1, 2)
		if prefijo == "E_" or prefijo == "P_" or nombre == "Racha" then
			refrescarEstadisticas()
			return
		end
		refrescarAlmacen()
		refrescarMejoras()
		refrescarBases()
	end)
	vigilarBase()

	return v
end

return Ventanas
