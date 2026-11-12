# El Anillo

Juego multijugador de supervivencia para Roblox (hasta 8 jugadores). El mundo se acabó y el suelo
del bosque es de los **Errantes**. Cada jugador vive en su **base**, en lo alto de una torre de vigas.
Cada 10 minutos hay una **lluvia de suministros**: caen cajas en paracaídas por todo el anillo y
todos tienen que salir a por ellas... dejando su base sin vigilar.

## El mapa (es redondo)

```
                    · · ·  acantilados  · · ·
              🗼 atalaya de fuera          🌳 árbol gigante
        🏠 base ─────────┐          ┌───────── 🏠 base
                         │  🌳 EL   │
          🗼 ──── 🚡 ─── │  ÁRBOL   │ ─── 🚡 ──── 🗼
                         │  MADRE   │
        🏠 base ─────────┘ (Nexo)   └───────── 🏠 base
              💧 pozo / charca / ⚙️ desguace / ⛺ campamento
```

- **El Árbol Madre** (centro): un árbol enorme con el **Nexo**, una plataforma a 50 de altura.
  Hay una escalera de caracol hasta el **Nido**, en lo alto, donde cae siempre una caja dorada ⭐.
  En el Nexo hay una **cisterna** para beber y dos **tablones** con las bases más ricas.
- **8 pasarelas** salen del Nexo hacia las 8 bases, como los radios de una rueda (sobre vigas altas).
- **8 bases** a la misma altura, sobre torres de vigas.
- **16 atalayas** (torres vigía): 8 dentro (a 34 de altura) y 8 fuera (a 28). Tienen una caja vieja que se
  vuelve a llenar. Desde el Nexo hay **tirolinas** hasta las de dentro; desde cada base, hasta una de fuera.
- **Árboles gigantes** con plataforma en la copa (se sube por cuerda) y el bosque normal abajo.
- **Lugares** en el suelo: 4 **pozos**, 2 **charcas**, un **desguace** lleno de coches y un **campamento** abandonado.

## Cómo se juega

### 🏠 Tu base
- Al entrar se te da una base libre (su color sale en la bandera, el cartel y el radar).
- **Almacén**: lo que guardas aquí suma a tu **Reserva 💰**, que es el marcador (Tab).
  También puedes comer o beber directamente de él.
- **Mesa de trabajo 🔨**: mejoras que se pagan con lo que tienes en el almacén y en la mochila.
- Se guarda al salir: tu almacén (más lo que lleves en la mochila), tus mejoras y tus robos.

### 🪂 La lluvia de suministros
- La primera llega a los **3 minutos** de abrir el servidor y luego **cada 10 minutos**.
- Un minuto antes se avisa y la sirena del Nido empieza a girar.
- Caen unas 14 cajas, más 2 por cada jugador (máximo 30), durante unos 35 segundos.
- **Dónde caen**: en el suelo (las mejores, pero ahí están los enemigos), en las atalayas, en las copas de
  los árboles gigantes, en el Nexo, y **siempre una dorada en el Nido**.
- Al aterrizar sueltan humo de colores: 📦 normal (naranja), 🎖️ militar (verde), ⭐ dorada (amarillo).
- Se abren manteniendo **E**. Lo que no te cabe en la mochila se queda dentro para otro.
- Con la lluvia llegan **2 Colosos**, que se quedan guardando las cajas del suelo.

### 🦹 Robar
- En la base de otro jugador, mantén **E** en «Robar» (2,5 s) y te llevas 3 objetos de su almacén
  (los valiosos salen más). Al dueño le llega una alerta 🚨 con tu nombre.
- Durante **30 segundos** eres un **LADRÓN**: brillas en rojo y todos te ven en el radar.
- Si alguien entra en tu base, también te llega un aviso 👀.
- Las armas también hacen daño a otros jugadores (la mitad). Si caes, **tu mochila se queda en el suelo**
  y cualquiera puede saquearla.

### 🍖💧 Sobrevivir
- El **hambre** baja en unos 15 minutos y la **sed** en unos 10. Si llegan a cero pierdes vida.
- La vida solo se recupera sola si tienes hambre y sed por encima del 60 %.
- **Agua**: pozos (beber o llenar botellas 💧), charcas (agua sucia: a veces hace daño) y la cisterna del Nexo.
- **Comida**: arbustos de bayas 🍇 y latas 🥫 de las cajas.
- **Chatarra** ⚙️: rebuscando en los coches abandonados y en las cajas viejas.

### 🧟 Los enemigos (solo andan por el suelo: no saben subir)
| Enemigo | Qué hace |
|---|---|
| **Errante** | Patrulla los caminos siempre, de día y de noche. Lento, pero son muchos. |
| **Vigía** | Se queda en su puesto mirando alrededor con una luz roja. Si te ve, grita y avisa a los Errantes. |
| **Rabioso** | Solo de noche. Rápido y te huele desde lejos. Al amanecer se deshace. |
| **Coloso** | Llega con la lluvia. Enorme, mucha vida; guarda las cajas del suelo y suelta buen botín. |

Si te subes a una torre te pierden... pero se quedan un rato esperando abajo.

### 🚚 Cambiar de base
Con **B** (o el botón «Bases») ves las 8 bases: de quién es cada una, su reserva y cuáles están libres.
En una libre, pulsa **Mudarme aquí**: tu almacén y tus mejoras se vienen contigo y apareces allí.
Se puede una vez por minuto y no mientras eres LADRÓN (`Config.CAMBIO_BASE`).

### 📊 Estadísticas
Con **J** (o el botón «Stats»): días sobrevividos, mejor racha sin caer, veces que has caído, enemigos y Colosos
derrotados, cajas abiertas, robos hechos y sufridos, mejor reserva y tiempo jugado. Cada una muestra el total
de siempre y lo de esta partida. Se guardan con tu progreso (`Config.ESTADISTICAS`).

### 🔨 Mesa de trabajo (3 pestañas)
Se paga con lo que tienes en el almacén y en la mochila. Los precios están en `Config.MEJORAS`.

**🏠 Base**: 🎒 Mochila grande (⚙️8, 20 objetos) · 🧳 Mochila de expedición (⚙️18 🔋1, 30 objetos) ·
🌧️ Colector de lluvia (⚙️8, agua cada 90 s) · 🌱 Huerto colgante (⚙️8 💧2, bayas cada 60 s) · 🩹 Botiquín (⚙️3 💧1, repetible)

**👹 Armas contra monstruos**: solo hacen daño a los monstruos (a las personas, nada). Llevas la mejor de cada tipo.
| # | Arma | Daño | Coste |
|---|---|---|---|
| 1 | 🔩 Tubo | 18 | gratis (siempre) |
| 2 | 🔧 Llave inglesa | 24 | ⚙️4 |
| 3 | 📌 Bate con clavos | 28 | ⚙️6 |
| 4 | 🔪 Machete | 32 | ⚙️9 |
| 5 | ⛏️ Pico | 38 | ⚙️11 |
| 6 | 🪓 Hacha de bombero | 55 | ⚙️14 🔋1 |
| 7 | 🔱 Lanza de chatarra | 60 | ⚙️16 🔋1 |
| 8 | 🔨 Mazo | 80 | ⚙️20 🔋2 |
| 9 | ⚙️ Motosierra | 95 | ⚙️24 🔋3 🥇1 |

**🎯 A distancia** (también solo monstruos): apuntan solas al monstruo que tengas delante, ¡también desde lo alto de tu torre!
🎯 Tirachinas (daño 14, ⚙️6) → 🏹 Ballesta (40, ⚙️14 🔋1) → 🥔 Lanzapatatas (70, ⚙️20 🔋2 🥇1).

**🧤 De mano**: para jugar con otros jugadores. Casi no hacen daño, pero dan un **empujón** (y sale un «¡PUM!»).
🖐️ Manos gigantes (gratis) → ☁️ Almohada gigante (⚙️3) → 🏏 Bate de plástico (⚙️5) → 🐟 Pez (⚙️7) → 🥊 Guante de boxeo gigante (⚙️10 🔋1).
En tu base los empujones son la mitad de fuertes. Los números están en `Config.ARMAS`.

**🛡️ Protección**: cómo defenderte de otros jugadores.
| Mejora | Coste | Qué hace |
|---|---|---|
| 🧥 Chaqueta acolchada | ⚙️6 | −15 % de daño (de jugadores y enemigos). Se ve puesta. |
| 🦺 Chaleco de chatarra | ⚙️14 🔋1 | −30 % de daño, con hombreras |
| 🛡️ Armadura antidisturbios | ⚙️22 🔋2 🥇1 | −45 % de daño |
| 🔒 Candado reforzado | ⚙️10 | Robarte cuesta 5 s y se llevan 2 objetos |
| ⚡ Trampa eléctrica | ⚙️12 🔋2 | Quien te roba pierde 25 de vida (necesita el candado) |

Además, **dentro de tu base** los otros jugadores te hacen la mitad de daño (`Config.DEFENSA`), y al aparecer
tienes unos segundos de escudo.

### 🎒 Objetos
| Objeto | Para qué | Valor 💰 |
|---|---|---|
| 🍇 Bayas | +14 hambre | 1 |
| 🥫 Lata de comida | +40 hambre | 4 |
| 💧 Botella de agua | +45 sed | 3 |
| 🩹 Botiquín | +55 vida | 6 |
| ⚙️ Chatarra | Mejoras | 2 |
| 🔋 Batería | Mejoras | 8 |
| 🥇 Lingote de oro | Solo vale dinero | 20 |

### Controles
- **E**: interactuar (agarrarse a la cuerda, abrir cajas, robar, beber...)
- **En la cuerda**: **W** sube · **S** baja · **Espacio** te suelta (en móvil: joystick y botón de saltar) · **R**: llenar botella en un pozo
- **Clic**: golpear con el arma
- **F** comer · **G** beber · **C** curarse · **M** mapa grande · **B** bases · **J** estadísticas · **H** ayuda
- En móvil, los botones de comer/beber/curar/mapa/ayuda están en pantalla.

## La pantalla
- **Arriba**: cuenta atrás de la lluvia (late cuando falta poco y se pone de rayas cuando llueve),
  día/noche y un **consejo** que cambia según lo que te pasa.
- **Izquierda**: vida, hambre y sed; tu base, tu reserva, una flecha que apunta a tu base y tus mejoras.
- **Derecha**: el **radar redondo** (tú, las bases, el Nexo, el agua, las cajas, mochilas caídas,
  ladrones y enemigos cerca) y la **mochila** con lo que llevas.
- **Alertas** grandes cuando te roban o entra alguien en tu base.

## Archivos

| Archivo | Qué hace |
|---|---|
| `src/shared/Config.luau` | **Todos los ajustes**: tiempos de la lluvia, hambre, sed, objetos, mejoras, enemigos, botín… |
| `src/server/Main.server.luau` | Arranca todo en orden |
| `src/server/Mundo/Construir.luau` | Construye el mapa al darle a Play |
| `src/server/Mundo/Estructuras.luau` | Árbol Madre, Nexo, Nido, bases, pasarelas y atalayas |
| `src/server/Mundo/Bosque.luau` | Lugares (pozos, charcas, desguace, campamento), árboles gigantes, bosque y marcadores |
| `src/server/Mundo/Props.luau` | Árboles, rocas, pozos, coches, cuerdas, tirolinas, cajas… |
| `src/server/Mundo/Plantillas.luau` | Árboles modelo: buscar la plantilla y poner copias |
| `src/server/Mundo/Terreno.luau` | Suelo, caminos, charcas y acantilados del borde |
| `src/server/Mundo/Util.luau` | Funciones pequeñas para construir con código |
| `src/server/Sistemas/Bases.luau` | Bases: asignarlas, almacén, robar, alertas, mejoras, producción y tablones |
| `src/server/Sistemas/Lluvia.luau` | La lluvia de suministros y las cajas |
| `src/server/Sistemas/Inventario.luau` | Mochila, hambre, sed, comer/beber/curarse y la mochila al caer |
| `src/server/Sistemas/Recursos.luau` | Pozos, charcas, cisterna, bayas, coches, cajas viejas y objetos sueltos |
| `src/server/Sistemas/Enemigos.luau` | Errantes, Vigías, Rabiosos y Colosos |
| `src/server/Sistemas/Movilidad.luau` | Cuerdas y tirolinas |
| `src/server/Sistemas/Armas.luau` | Armas contra monstruos, a distancia y de mano (empujones) |
| `src/server/Sistemas/Defensa.luau` | Armaduras y daño reducido en tu base |
| `src/server/Sistemas/Ciclo.luau` | Día, noche y luz |
| `src/server/Sistemas/Estadisticas.luau` | Estadísticas de cada jugador (se guardan con Datos) |
| `src/server/Sistemas/Datos.luau` | Guardado y marcador (Reserva y Robos) |
| `src/personaje/Health.server.luau` | Quita la vida que se recupera sola de Roblox |
| `src/client/` | Pantalla: HUD, radar, almacén, mejoras, ayuda y el movimiento por cuerdas/tirolinas |

## Editar el mapa a mano

El mapa se construye al darle a **Play**. Si quieres retocarlo en Studio:
1. Dale a Play, selecciona la carpeta `Workspace > ElAnillo` y cópiala (Ctrl+C).
2. Para la partida y pégala en Workspace (Ctrl+V).
3. A partir de ahí el juego usa tu copia en lugar de construir una nueva. Al darle a Play se quitan solos
   los botones e iconos que se copiaron de la partida (si no, se quedarían «muertos» tapando a los buenos).
   (El terreno se sigue generando; para que no, pon a la carpeta el atributo `TerrenoPropio = true`.)

### 🧩 Árboles modelo (plantillas)

Los árboles normales (**Pino**, **Roble**, **ArbolSeco**) salen de un árbol «modelo» que puedes cambiar a mano.
El plugin [herramientas/ElAnilloHerramientas.lua](herramientas/ElAnilloHerramientas.lua) (cópialo a
`%LOCALAPPDATA%\Roblox\Plugins`) añade en la pestaña **Plugins** estos botones:

- **Poner pasto**: genera el terreno en modo edición.
- **Crear plantillas**: pone un árbol de cada tipo en `Workspace > Plantillas`, en un taller fuera del mapa.
  Cámbialos como quieras (o pon un modelo de la Toolbox con el mismo nombre). Para tener varias versiones
  de un tipo, mete varios Models dentro de una Folder con ese nombre.
  Los atributos `EscalaMin` y `EscalaMax` dicen cuánto cambia el tamaño de cada copia.
- **Actualizar árboles**: cambia los árboles del mapa pegado por las plantillas, sin moverlos de sitio.

Al darle a Play, el taller se esconde (pasa a ServerStorage). Si no hay plantilla de un tipo, ese árbol se hace con código.

Los objetos importantes se reconocen por **etiquetas** (Tags), así que puedes moverlos o duplicarlos:
`Base`, `Pozo`, `Charca`, `Cisterna`, `Bayas`, `Chatarra`, `CajaVieja`, `Cuerda`, `Tirolina`, `Tablon`,
`Sirena`, `PuntoCaida` (con el atributo `Zona`), `PuntoEnemigo`, `PuntoRuta`, `PuntoVigia`.

## Compilar y probar

```bash
rojo build -o ElAnillo.rbxlx
```

Abre `ElAnillo.rbxlx` en Roblox Studio y, para ver los cambios del código en directo:

```bash
rojo serve
```

- Para probar con varios jugadores: *Test > Clients and Servers* (2 o 3 jugadores) y así puedes robarte a ti mismo.
- Para que el guardado funcione en Studio: *Game Settings > Security > Enable Studio Access to API Services*.
- Al publicar, pon **8 jugadores como máximo** por servidor (*Game Settings > Places*): hay 8 bases.
  Si entra un noveno, aparece en el Nexo y espera a que se libere una base.
- Para probar la lluvia rápido, baja `Config.LLUVIA.PRIMERA` (por ejemplo a 20).
