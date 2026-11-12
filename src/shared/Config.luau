-- Todos los ajustes del juego en un solo sitio.
-- Cambia los números de aquí para hacer el juego más fácil, más difícil, más rápido...
local Config = {}

local rgb = Color3.fromRGB

Config.NOMBRE = "El Anillo"
Config.NOMBRE_DATASTORE = "ElAnillo_v1"

-- 🗺️ Mapa ---------------------------------------------------------------------------------
-- Todo gira alrededor del centro (0, 0, 0). El suelo está a la altura y = 0.
Config.MAPA = {
	RADIO = 300, -- radio jugable (hay un muro invisible en el borde)
	BASES = 8,
	RADIO_BASES = 170, -- distancia del centro a cada base
	ALTURA_BASES = 50, -- altura de las plataformas de las bases
	MEDIO_BASE = 16, -- media anchura de la plataforma de una base (mide 32 x 32)
	RADIO_NEXO = 36, -- radio de la plataforma del centro (el Nexo)
	ALTURA_NEXO = 50,
	ALTURA_NIDO = 96, -- el Nido, en lo alto del Árbol Madre
	RADIO_ATALAYAS_DENTRO = 95,
	ALTURA_ATALAYAS_DENTRO = 34,
	RADIO_ATALAYAS_FUERA = 250,
	ALTURA_ATALAYAS_FUERA = 28,
	RADIO_GIGANTES = 165, -- árboles gigantes con plataforma, entre base y base
	RADIO_LUGARES = 130, -- pozos, charcas, desguace y campamento
}

-- Lo que hay en el anillo de "lugares" (uno entre cada par de bases)
Config.LUGARES = { "Pozo", "Charca", "Pozo", "Desguace", "Pozo", "Campamento", "Pozo", "Charca" }

-- Punto a partir de una distancia al centro y un ángulo en grados.
function Config.polar(r: number, grados: number, y: number?): Vector3
	local a = math.rad(grados)
	return Vector3.new(math.cos(a) * r, y or 0, math.sin(a) * r)
end

function Config.anguloBase(i: number): number
	return (i - 1) * (360 / Config.MAPA.BASES)
end

-- Centro de la plataforma de la base i (a la altura del suelo de la plataforma).
function Config.centroBase(i: number): Vector3
	return Config.polar(Config.MAPA.RADIO_BASES, Config.anguloBase(i), Config.MAPA.ALTURA_BASES)
end

-- 🏠 Bases ---------------------------------------------------------------------------------
Config.BASES = {
	{ nombre = "Roja", color = rgb(222, 72, 62) },
	{ nombre = "Azul", color = rgb(70, 132, 232) },
	{ nombre = "Verde", color = rgb(92, 192, 92) },
	{ nombre = "Amarilla", color = rgb(240, 202, 62) },
	{ nombre = "Morada", color = rgb(164, 96, 224) },
	{ nombre = "Naranja", color = rgb(246, 142, 52) },
	{ nombre = "Turquesa", color = rgb(62, 202, 202) },
	{ nombre = "Rosa", color = rgb(242, 122, 182) },
}
Config.COLOR_LIBRE = rgb(128, 128, 124)

-- 🪂 Lluvia de suministros -------------------------------------------------------------------
Config.LLUVIA = {
	PRIMERA = 180, -- segundos hasta la primera lluvia al abrir el servidor
	INTERVALO = 600, -- después, una cada 10 minutos
	AVISO = 60, -- se avisa un minuto antes
	CAJAS_BASE = 14,
	CAJAS_POR_JUGADOR = 2,
	CAJAS_MAXIMO = 30,
	DURACION_CAIDA = 35, -- las cajas se van soltando durante este tiempo
	ALTURA = 260, -- desde dónde caen
	VELOCIDAD = 16, -- velocidad de caída con paracaídas
	DURACION_CAJA = 300, -- lo que dura una caja en el mapa antes de desaparecer
	TIEMPO_ABRIR = 1.2,
	-- Dónde caen (probabilidad de cada zona). En el Nido cae siempre una caja dorada por lluvia.
	ZONAS = { Suelo = 60, Torre = 22, Copa = 12, Nexo = 6 },
	-- Tipos de caja según dónde caen: las del suelo (con los enemigos) son las mejores
	TIPOS = {
		Suelo = { Comun = 50, Militar = 38, Dorada = 12 },
		Altura = { Comun = 72, Militar = 25, Dorada = 3 }, -- atalayas y copas de los árboles
		Centro = { Comun = 86, Militar = 14, Dorada = 0 }, -- el Nexo (no hay enemigos)
	},
}

Config.CAJAS = {
	Comun = { nombre = "Caja de suministros", icono = "📦", color = rgb(150, 112, 70), humo = rgb(255, 150, 70) },
	Militar = { nombre = "Caja militar", icono = "🎖️", color = rgb(86, 104, 66), humo = rgb(120, 255, 120) },
	Dorada = { nombre = "Caja dorada", icono = "⭐", color = rgb(232, 186, 70), humo = rgb(255, 230, 90) },
}

-- ☀️ Día y noche (de noche salen los Rabiosos) ----------------------------------------------
Config.CICLO = { DIA = 420, NOCHE = 240 }

-- 🍖💧 Supervivencia --------------------------------------------------------------------------
Config.SUPERVIVENCIA = {
	MAXIMO = 100,
	GASTO_HAMBRE = 0.11, -- por segundo (de 100 a 0 en unos 15 minutos)
	GASTO_SED = 0.16, -- por segundo (de 100 a 0 en unos 10 minutos)
	DANO_HAMBRE = 1.5, -- vida que pierdes por segundo sin comida
	DANO_SED = 2, -- vida que pierdes por segundo sin agua
	AL_REAPARECER = 65, -- hambre y sed mínimas al reaparecer
	REGENERA_DESDE = 60, -- con hambre y sed por encima de esto, la vida sube sola
	REGENERACION = 0.6, -- vida por segundo
	AVISO = 25, -- por debajo de esto la barra parpadea
}

-- 🎒 Objetos ---------------------------------------------------------------------------------
-- valor: lo que suma a tu Reserva 💰 cuando está guardado en tu almacén.
Config.OBJETOS = {
	Bayas = { nombre = "Bayas", icono = "🍇", valor = 1, uso = "comida", hambre = 14, color = rgb(128, 86, 210) },
	Lata = { nombre = "Lata de comida", icono = "🥫", valor = 4, uso = "comida", hambre = 40, color = rgb(214, 92, 62) },
	Agua = { nombre = "Botella de agua", icono = "💧", valor = 3, uso = "bebida", sed = 45, color = rgb(84, 172, 255) },
	Botiquin = { nombre = "Botiquín", icono = "🩹", valor = 6, uso = "cura", vida = 55, color = rgb(238, 238, 238) },
	Chatarra = { nombre = "Chatarra", icono = "⚙️", valor = 2, color = rgb(150, 152, 162) },
	Bateria = { nombre = "Batería", icono = "🔋", valor = 8, color = rgb(122, 222, 122) },
	Oro = { nombre = "Lingote de oro", icono = "🥇", valor = 20, color = rgb(255, 206, 72) },
}
Config.ORDEN_OBJETOS = { "Lata", "Bayas", "Agua", "Botiquin", "Chatarra", "Bateria", "Oro" }

-- Cuántos objetos caben en la mochila (cada objeto ocupa 1)
Config.MOCHILA = { BASE = 12, GRANDE = 20, EXPEDICION = 30 }

-- 🦹 Robar -----------------------------------------------------------------------------------
Config.ROBO = {
	TIEMPO = 2.5, -- segundos que hay que mantener E para robar
	TIEMPO_CANDADO = 5, -- ...si el dueño tiene candado reforzado
	OBJETOS = 3, -- objetos que te llevas cada vez
	OBJETOS_CANDADO = 2,
	MARCA = 30, -- segundos que todos te ven como LADRÓN (y en el radar)
	DANO_TRAMPA = 25,
	AVISO_INTRUSO = 20, -- segundos entre avisos de "alguien ha entrado en tu base"
}

-- 🏠 Cambiar de base (ventana «Bases», tecla B)
Config.CAMBIO_BASE = {
	ESPERA = 60, -- segundos entre una mudanza y la siguiente
}

-- 📊 Estadísticas (ventana «Estadísticas», tecla J). Se guardan con tu progreso.
Config.ESTADISTICAS = {
	{ id = "Dias", icono = "🌅", nombre = "Días sobrevividos", texto = "Amaneceres que has visto en el anillo" },
	{ id = "MejorRacha", icono = "🔥", nombre = "Mejor racha", texto = "Días seguidos sin caer", maximo = true },
	{ id = "Muertes", icono = "💀", nombre = "Veces que has caído", texto = "Por hambre, sed, enemigos o jugadores" },
	{ id = "Enemigos", icono = "🧟", nombre = "Enemigos derrotados", texto = "Errantes, Vigías, Rabiosos y Colosos" },
	{ id = "Colosos", icono = "👹", nombre = "Colosos derribados", texto = "Los gigantes que llegan con la lluvia" },
	{ id = "Cajas", icono = "🪂", nombre = "Cajas abiertas", texto = "Cajas de suministros que has saqueado" },
	{ id = "Robos", icono = "🦹", nombre = "Robos hechos", texto = "Veces que has robado un almacén" },
	{ id = "Robado", icono = "🚨", nombre = "Veces que te han robado", texto = "Robos que ha sufrido tu almacén" },
	{ id = "MejorReserva", icono = "💰", nombre = "Mejor reserva", texto = "Lo más rico que ha estado tu almacén", maximo = true },
	{ id = "Minutos", icono = "⏱️", nombre = "Tiempo jugado", texto = "Minutos en el anillo", tiempo = true },
}

-- 🔨 Mejoras de la base (se pagan con lo que tienes en el almacén y en la mochila) --------------
-- Mejoras que se compran en la mesa de trabajo de tu base. La ventana tiene 3 pestañas (categoria):
--   "base" 🏠 · "monstruos" 👹 · "mano" 🧤 · "proteccion" 🛡️
Config.MEJORAS = {
	-- 🏠 Base
	{ id = "Mochila1", categoria = "base", nombre = "Mochila grande", icono = "🎒", texto = "Llevas hasta 20 objetos.", coste = { Chatarra = 8 } },
	{
		id = "Mochila2",
		categoria = "base",
		nombre = "Mochila de expedición",
		icono = "🧳",
		texto = "Llevas hasta 30 objetos.",
		coste = { Chatarra = 18, Bateria = 1 },
		requiere = "Mochila1",
	},
	{
		id = "Colector",
		categoria = "base",
		nombre = "Colector de lluvia",
		icono = "🌧️",
		texto = "Llena una botella de agua cada 90 s en tu almacén.",
		coste = { Chatarra = 8 },
	},
	{ id = "Huerto", categoria = "base", nombre = "Huerto colgante", icono = "🌱", texto = "Da bayas cada 60 s en tu almacén.", coste = { Chatarra = 8, Agua = 2 } },
	{
		id = "Botiquin",
		categoria = "base",
		nombre = "Fabricar botiquín",
		icono = "🩹",
		texto = "Fabrica 1 botiquín y lo deja en tu almacén.",
		coste = { Chatarra = 3, Agua = 1 },
		repetible = true,
	},

	-- 👹 Armas contra MONSTRUOS (a las personas no les hacen nada). Cada una necesita la anterior.
	{ id = "Llave", categoria = "monstruos", nombre = "Llave inglesa", icono = "🔧", texto = "Pesada y rápida.", coste = { Chatarra = 4 } },
	{ id = "BateClavos", categoria = "monstruos", nombre = "Bate con clavos", icono = "📌", texto = "Para los Errantes.", coste = { Chatarra = 6 }, requiere = "Llave" },
	{ id = "Machete", categoria = "monstruos", nombre = "Machete", icono = "🔪", texto = "Corta la maleza... y lo demás.", coste = { Chatarra = 9 }, requiere = "BateClavos" },
	{ id = "Pico", categoria = "monstruos", nombre = "Pico", icono = "⛏️", texto = "Llega un poco más lejos.", coste = { Chatarra = 11 }, requiere = "Machete" },
	{
		id = "Hacha",
		categoria = "monstruos",
		nombre = "Hacha de bombero",
		icono = "🪓",
		texto = "Golpes muy fuertes.",
		coste = { Chatarra = 14, Bateria = 1 },
		requiere = "Pico",
	},
	{
		id = "Lanza",
		categoria = "monstruos",
		nombre = "Lanza de chatarra",
		icono = "🔱",
		texto = "Llega lejísimos.",
		coste = { Chatarra = 16, Bateria = 1 },
		requiere = "Hacha",
	},
	{ id = "Mazo", categoria = "monstruos", nombre = "Mazo", icono = "🔨", texto = "Lento, pero aplasta.", coste = { Chatarra = 20, Bateria = 2 }, requiere = "Lanza" },
	{
		id = "Motosierra",
		categoria = "monstruos",
		nombre = "Motosierra",
		icono = "⚙️",
		texto = "La mejor contra los Colosos.",
		coste = { Chatarra = 24, Bateria = 3, Oro = 1 },
		requiere = "Mazo",
	},
	-- 🎯 A distancia (también solo contra monstruos): apuntan solas al monstruo que tengas delante.
	-- ¡Puedes disparar desde lo alto de tu torre!
	{ id = "Tirachinas", categoria = "monstruos", nombre = "Tirachinas", icono = "🎯", texto = "Dispara piedras.", coste = { Chatarra = 6 } },
	{
		id = "Ballesta",
		categoria = "monstruos",
		nombre = "Ballesta",
		icono = "🏹",
		texto = "Flechas que llegan muy lejos.",
		coste = { Chatarra = 14, Bateria = 1 },
		requiere = "Tirachinas",
	},
	{
		id = "Lanzapatatas",
		categoria = "monstruos",
		nombre = "Lanzapatatas",
		icono = "🥔",
		texto = "¡PATATAZO! El que más pega de lejos.",
		coste = { Chatarra = 20, Bateria = 2, Oro = 1 },
		requiere = "Ballesta",
	},

	-- 🧤 De MANO, para jugar con otros jugadores: casi no hacen daño, pero EMPUJAN.
	-- (¡Cuidado en las pasarelas!)
	{ id = "Almohada", categoria = "mano", nombre = "Almohada gigante", icono = "☁️", texto = "¡Guerra de almohadas!", coste = { Chatarra = 3 } },
	{ id = "BatePlastico", categoria = "mano", nombre = "Bate de plástico", icono = "🏏", texto = "Hace mucho ruido.", coste = { Chatarra = 5 }, requiere = "Almohada" },
	{ id = "Pez", categoria = "mano", nombre = "Pez", icono = "🐟", texto = "Un sopapo con un pez.", coste = { Chatarra = 7 }, requiere = "BatePlastico" },
	{
		id = "Guante",
		categoria = "mano",
		nombre = "Guante de boxeo gigante",
		icono = "🥊",
		texto = "El empujón más fuerte.",
		coste = { Chatarra = 10, Bateria = 1 },
		requiere = "Pez",
	},

	-- 🛡️ Protección (contra otros jugadores... y contra los enemigos)
	{
		id = "Armadura1",
		categoria = "proteccion",
		nombre = "Chaqueta acolchada",
		icono = "🧥",
		texto = "Recibes un 15 % menos de daño.",
		coste = { Chatarra = 6 },
		proteccion = 0.15,
		colorArmadura = rgb(96, 70, 52),
		materialArmadura = Enum.Material.Fabric,
	},
	{
		id = "Armadura2",
		categoria = "proteccion",
		nombre = "Chaleco de chatarra",
		icono = "🦺",
		texto = "Recibes un 30 % menos de daño.",
		coste = { Chatarra = 14, Bateria = 1 },
		requiere = "Armadura1",
		proteccion = 0.3,
		colorArmadura = rgb(120, 112, 98),
		materialArmadura = Enum.Material.CorrodedMetal,
	},
	{
		id = "Armadura3",
		categoria = "proteccion",
		nombre = "Armadura antidisturbios",
		icono = "🛡️",
		texto = "Recibes un 45 % menos de daño.",
		coste = { Chatarra = 22, Bateria = 2, Oro = 1 },
		requiere = "Armadura2",
		proteccion = 0.45,
		colorArmadura = rgb(40, 44, 52),
		materialArmadura = Enum.Material.Metal,
	},
	{
		id = "Candado",
		categoria = "proteccion",
		nombre = "Candado reforzado",
		icono = "🔒",
		texto = "Robarte cuesta el doble de tiempo y se llevan menos cosas.",
		coste = { Chatarra = 10 },
	},
	{
		id = "Trampa",
		categoria = "proteccion",
		nombre = "Trampa eléctrica",
		icono = "⚡",
		texto = "Quien te robe se lleva una descarga de 25 de vida.",
		coste = { Chatarra = 12, Bateria = 2 },
		requiere = "Candado",
	},
}

-- Lo que producen solas algunas mejoras (no producen si ya tienes MAXIMO de ese objeto guardado)
Config.PRODUCCION = {
	Colector = { objeto = "Agua", cada = 90 },
	Huerto = { objeto = "Bayas", cada = 60 },
	MAXIMO = 15,
}

function Config.mejora(id: string)
	for _, m in Config.MEJORAS do
		if m.id == id then
			return m
		end
	end
	return nil
end

-- ⚔️ Armas -----------------------------------------------------------------------------------
-- ⚔️ Armas. Hay 3 grupos y llevas la mejor que tengas de cada uno (hasta 3 en la barra):
--   👹 monstruos: cuerpo a cuerpo, solo hacen daño a los monstruos (el Tubo lo tienes siempre)
--   🎯 distancia: disparan solas al monstruo que tengas delante (solo monstruos)
--   🧤 mano: para jugar con otros jugadores. Poco daño y un buen EMPUJÓN (las Manos gigantes las tienes siempre)
-- dano: daño a monstruos · danoJugador: daño a jugadores · empuje: fuerza del empujón
-- cadencia: segundos entre golpes · alcance: distancia del golpe · rango: distancia del disparo
Config.GRUPOS_ARMAS = {
	{ id = "monstruos", icono = "⚔️", atributo = "Arma", lista = { "Tubo", "Llave", "BateClavos", "Machete", "Pico", "Hacha", "Lanza", "Mazo", "Motosierra" } },
	{ id = "distancia", icono = "🎯", atributo = "ArmaDistancia", lista = { "Tirachinas", "Ballesta", "Lanzapatatas" } },
	{ id = "mano", icono = "🧤", atributo = "ArmaMano", lista = { "Manos", "Almohada", "BatePlastico", "Pez", "Guante" } },
}
-- Las que tienes desde el principio (sin fabricarlas)
Config.ARMAS_GRATIS = { Tubo = true, Manos = true }
Config.ARMAS = {
	-- 👹 Contra monstruos
	Tubo = { dano = 18, cadencia = 0.55, alcance = 7 },
	Llave = { dano = 24, cadencia = 0.55, alcance = 6.5 },
	BateClavos = { dano = 28, cadencia = 0.6, alcance = 7.5 },
	Machete = { dano = 32, cadencia = 0.5, alcance = 7.5 },
	Pico = { dano = 38, cadencia = 0.58, alcance = 8.5 },
	Hacha = { dano = 55, cadencia = 0.8, alcance = 8.5 },
	Lanza = { dano = 60, cadencia = 0.8, alcance = 11 },
	Mazo = { dano = 80, cadencia = 1, alcance = 8.5 },
	Motosierra = { dano = 95, cadencia = 0.85, alcance = 8 },
	-- 🎯 A distancia
	Tirachinas = { dano = 14, cadencia = 0.6, rango = 45, proyectil = "piedra" },
	Ballesta = { dano = 40, cadencia = 1.1, rango = 75, proyectil = "flecha" },
	Lanzapatatas = { dano = 70, cadencia = 1.4, rango = 85, proyectil = "patata" },
	-- 🧤 De mano (para jugar con otros jugadores)
	Manos = { dano = 4, danoJugador = 2, empuje = 32, cadencia = 0.6, alcance = 6 },
	Almohada = { dano = 5, danoJugador = 2, empuje = 55, cadencia = 0.65, alcance = 7 },
	BatePlastico = { dano = 6, danoJugador = 4, empuje = 50, cadencia = 0.6, alcance = 7.5 },
	Pez = { dano = 6, danoJugador = 5, empuje = 62, cadencia = 0.6, alcance = 7 },
	Guante = { dano = 8, danoJugador = 7, empuje = 80, cadencia = 0.75, alcance = 7 },
}
-- ¿A qué grupo pertenece un arma?
function Config.grupoArma(nombre: string)
	for _, g in Config.GRUPOS_ARMAS do
		if table.find(g.lista, nombre) then
			return g
		end
	end
	return nil
end
-- El texto de cada arma en la mesa dice lo que hace (así no hay que cambiarlo a mano)
for _, m in Config.MEJORAS do
	local a = Config.ARMAS[m.id]
	if a then
		if a.empuje then
			m.texto = string.format("Empujón %d · daño %d. %s", a.empuje, a.danoJugador or 0, m.texto)
		elseif a.rango then
			m.texto = string.format("🎯 A distancia · daño %d. %s", a.dano, m.texto)
		else
			m.texto = string.format("Daño %d · %s %s", a.dano, if a.cadencia <= 0.55 then "rápida." elseif a.cadencia >= 0.8 then "lenta." else "normal.", m.texto)
		end
	end
end

-- 🛡️ Defensa
Config.DEFENSA = {
	EN_TU_BASE = 0.5, -- dentro de tu base, los otros jugadores te hacen la mitad de daño
}

-- 🧟 Enemigos (solo caminan por el suelo: no pueden subir a las torres) -------------------------
Config.ENEMIGOS = {
	ALTURA_SEGURA = 14, -- por encima de esta altura no te pueden alcanzar
	TIPOS = {
		-- velocidad: paseando. persigue: persiguiendo. vision: distancia a la que te ven.
		Errante = { nombre = "Errante", vida = 60, velocidad = 7, persigue = 15, dano = 12, cadencia = 1.3, escala = 1, vision = 38, botin = 0.4 },
		Vigia = {
			nombre = "Vigía",
			vida = 90,
			velocidad = 0,
			persigue = 17,
			dano = 15,
			cadencia = 1.2,
			escala = 1.15,
			vision = 75,
			alarma = 110, -- al verte, avisa a los Errantes que haya a esta distancia
			correa = 45, -- no se aleja más de esto de su puesto
			botin = 0.7,
		},
		Rabioso = { nombre = "Rabioso", vida = 45, velocidad = 14, persigue = 21, dano = 9, cadencia = 0.75, escala = 0.95, vision = 70, botin = 0.4 },
		Coloso = {
			nombre = "Coloso",
			vida = 450,
			velocidad = 9,
			persigue = 13,
			dano = 35,
			cadencia = 1.8,
			escala = 1.9,
			vision = 55,
			botin = 1,
			jefe = true,
		},
	},
	ERRANTES = 22, -- siempre patrullando
	VIGIAS = 8, -- quietos en su puesto, mirando alrededor
	RABIOSOS_NOCHE = 10, -- solo de noche
	COLOSOS_LLUVIA = 2, -- aparecen con la lluvia de suministros
	REAPARICION = 35, -- segundos hasta que vuelve uno que has matado
	MAXIMO = 45,
	NOCHE_VISION = 1.25, -- de noche ven más lejos
}

-- 🎲 Botín: { objeto, probabilidad, mínimo, máximo }
Config.BOTIN = {
	Comun = {
		{ "Lata", 0.6, 1, 2 },
		{ "Agua", 0.7, 1, 2 },
		{ "Bayas", 0.3, 1, 3 },
		{ "Chatarra", 0.6, 1, 3 },
		{ "Botiquin", 0.2, 1, 1 },
		{ "Bateria", 0.15, 1, 1 },
	},
	Militar = {
		{ "Lata", 0.8, 2, 3 },
		{ "Agua", 0.8, 2, 3 },
		{ "Botiquin", 0.5, 1, 2 },
		{ "Chatarra", 0.8, 2, 5 },
		{ "Bateria", 0.45, 1, 2 },
		{ "Oro", 0.15, 1, 1 },
	},
	Dorada = {
		{ "Oro", 1, 2, 4 },
		{ "Bateria", 0.8, 1, 3 },
		{ "Botiquin", 0.7, 1, 2 },
		{ "Lata", 0.6, 2, 3 },
		{ "Agua", 0.6, 2, 3 },
	},
	Vieja = {
		{ "Lata", 0.35, 1, 1 },
		{ "Agua", 0.4, 1, 1 },
		{ "Chatarra", 0.6, 1, 2 },
		{ "Bayas", 0.3, 1, 2 },
		{ "Bateria", 0.06, 1, 1 },
	},
	Desguace = {
		{ "Chatarra", 1, 1, 3 },
		{ "Bateria", 0.12, 1, 1 },
	},
	Enemigo = {
		{ "Chatarra", 0.6, 1, 2 },
		{ "Bayas", 0.3, 1, 2 },
		{ "Lata", 0.15, 1, 1 },
		{ "Agua", 0.15, 1, 1 },
	},
	Coloso = {
		{ "Oro", 1, 1, 2 },
		{ "Bateria", 1, 1, 2 },
		{ "Botiquin", 0.8, 1, 1 },
		{ "Lata", 0.8, 1, 2 },
	},
}

-- 🌿 Recursos del suelo ------------------------------------------------------------------------
Config.RECURSOS = {
	BAYAS_POR_ARBUSTO = 3,
	BAYA_RECRECE = 40,
	POZO_BEBER = 35, -- sed que recuperas al beber del pozo
	POZO_BOTELLAS = 3, -- botellas que puedes llenar antes de que haya que esperar
	POZO_RECARGA = 30, -- segundos por botella
	CHARCA_BEBER = 20,
	CISTERNA_BEBER = 25, -- la cisterna del Nexo
	DESGUACE_RECARGA = 120,
	CAJA_VIEJA_RECARGA = 180,
	DURACION_SUELTO = 120, -- lo que dura un objeto tirado en el suelo
	DURACION_BOLSA = 240, -- lo que dura la mochila de alguien que ha caído
}

Config.MOVILIDAD = {
	CUERDA_VELOCIDAD = 18, -- studs por segundo trepando por la cuerda (W sube, S baja)
	TIROLINA_VELOCIDAD = 50,
}

-- 🔧 Funciones de ayuda ------------------------------------------------------------------------

-- Tira los dados de una tabla de botín. Devuelve { objeto = cantidad }.
function Config.tirarBotin(nombreTabla: string): { [string]: number }
	local resultado = {}
	for _, fila in Config.BOTIN[nombreTabla] or {} do
		if math.random() < fila[2] then
			resultado[fila[1]] = (resultado[fila[1]] or 0) + math.random(fila[3], fila[4])
		end
	end
	return resultado
end

-- Cuántos objetos hay en un contenido { objeto = cantidad }.
function Config.total(contenido): number
	local n = 0
	for _, c in contenido do
		n += c
	end
	return n
end

-- Valor 💰 de un contenido.
function Config.valor(contenido): number
	local v = 0
	for id, c in contenido do
		local datos = Config.OBJETOS[id]
		if datos then
			v += datos.valor * c
		end
	end
	return v
end

-- "+2 🥫  +1 💧"
function Config.textoContenido(contenido, signo: string?): string
	local partes = {}
	for _, id in Config.ORDEN_OBJETOS do
		local n = contenido[id]
		if n and n > 0 then
			table.insert(partes, string.format("%s%d %s", signo or "+", n, Config.OBJETOS[id].icono))
		end
	end
	return table.concat(partes, "  ")
end

return Config
