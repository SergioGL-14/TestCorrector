# TestCorrector

Aplicación de escritorio desarrollada en PowerShell para cargar, responder y corregir cuestionarios tipo test desde una interfaz gráfica construida con WPF.

El proyecto está orientado a entornos Windows donde PowerShell sigue siendo una herramienta habitual, tanto para automatización como para pequeñas utilidades de escritorio.

No es un sistema de exámenes online, ni una plataforma multiusuario, ni pretende competir con herramientas completas de evaluación. Su valor está en ser ligero, autocontenido, modificable y suficientemente sólido para cubrir bien un caso de uso concreto.

---

## Qué hace este proyecto

TestCorrector permite cargar un conjunto de preguntas tipo test, mostrarlas en una interfaz visual basada en tarjetas, registrar la respuesta seleccionada para cada pregunta y corregir el resultado a partir de una clave de respuestas cargada por separado. Durante la corrección, la aplicación marca visualmente las respuestas correctas, las incorrectas y las preguntas sin responder, además de mostrar un resumen final con puntuación neta, porcentaje y nota sobre 10.

El flujo de trabajo es directo. Primero se cargan las preguntas. Después se carga la clave de respuestas. A continuación, el usuario responde el test en pantalla. Finalmente, se ejecuta la corrección y se obtiene el resultado. Como complemento, el script permite reiniciar respuestas, limpiar completamente la sesión y exportar el estado de las respuestas marcadas en un formato compacto.

Todo esto se ejecuta desde un único archivo `.ps1`, con la interfaz generada por código en tiempo de ejecución.

---

## Objetivo del proyecto

La idea detrás de este proyecto no es construir una aplicación enorme ni sobredimensionada, sino resolver bien una necesidad concreta: disponer de una herramienta local, sencilla y visual para trabajar con cuestionarios tipo test sin depender de navegadores, servicios web, bases de datos ni instaladores pesados.

También tiene interés como proyecto técnico, porque demuestra varias cosas dentro del ecosistema PowerShell:

* construcción de interfaces WPF desde código
* gestión de estado en una aplicación gráfica
* uso de parsers sencillos para texto estructurado
* representación dinámica de controles visuales
* cálculo y presentación de resultados
* organización de un script largo por bloques funcionales

Por eso puede verse de dos formas: como utilidad práctica y como base de aprendizaje o ampliación.

---

## Características principales

El script incorpora una serie de funciones que lo hacen útil desde el primer momento.

### Interfaz gráfica completa en WPF

La aplicación no depende de consola para su uso normal. Presenta una ventana principal con estructura clara, separación por paneles, cabecera, pie y área central de trabajo. Toda la interfaz se construye mediante objetos WPF instanciados desde PowerShell.

### Carga de preguntas desde texto o archivo

Las preguntas pueden introducirse pegando el contenido en el área de texto o abriendo directamente un archivo `.txt` desde la propia interfaz.

### Carga de clave de respuestas

La clave se puede introducir pegando texto o cargando un archivo de texto independiente. El programa parsea la clave y normaliza las letras internamente para poder corregir después sin depender del formato exacto introducido por el usuario.

### Soporte para enunciados multilínea

Las preguntas no tienen por qué ser de una sola línea. El parser concatena correctamente el enunciado cuando ocupa varias líneas antes de las opciones.

### Opciones tipo A, B, C y D

El formato actual está orientado a preguntas con cuatro opciones. Cada una se representa como una fila interactiva dentro de la tarjeta de pregunta.

### Selección visual e interacción directa

El usuario responde haciendo clic sobre las opciones. La interfaz marca claramente qué respuesta está seleccionada en cada momento.

### Progreso de respuestas

La cabecera y el pie de la ventana muestran cuántas preguntas han sido respondidas respecto al total cargado.

### Corrección automática

Cuando se ejecuta la corrección, el sistema recorre todas las preguntas evaluables, compara la respuesta elegida con la clave y actualiza el aspecto visual de la tarjeta y de sus opciones.

### Sistema de penalización

La nota no se limita a contar aciertos. El cálculo usa una fórmula con penalización por error, lo que permite simular un comportamiento de examen más realista.

### Ventana de resultados

El usuario recibe un resumen visual con porcentaje, nota final, número de aciertos, errores, preguntas en blanco y penalización aplicada.

### Exportación de respuestas

Existe una función específica para exportar las respuestas marcadas en un formato compacto y fácilmente copiable.

### Reinicio y limpieza

Se puede reiniciar la selección del test actual o limpiar completamente toda la sesión para empezar de nuevo.

### Zoom de la zona de preguntas

El panel derecho incorpora control de zoom mediante slider y también mediante `Ctrl + rueda del ratón`, algo útil cuando hay muchas preguntas o cuando se quiere trabajar con distinta escala visual.

---

## Tecnologías utilizadas

El proyecto está desarrollado con tecnologías nativas del ecosistema Windows y PowerShell.

* PowerShell
* WPF (Windows Presentation Foundation)
* .NET Framework / ensamblados de presentación de Windows
* `System.Windows.Forms` para la apertura de archivos desde diálogo gráfico

Los ensamblados cargados por el script son los siguientes:

* `PresentationFramework`
* `PresentationCore`
* `WindowsBase`

Este planteamiento evita dependencias externas y permite que el script funcione en entornos Windows razonablemente estándar.

---

## Requisitos

Para ejecutar la aplicación se necesita:

* Windows
* PowerShell 5.1 o superior
* entorno gráfico de escritorio
* .NET Framework disponible en el sistema

El proyecto está claramente orientado a Windows. No está planteado para PowerShell multiplataforma en Linux o macOS, porque la interfaz depende de WPF, que es una tecnología propia del stack gráfico de Windows.

---

## Instalación

No requiere una instalación formal. Basta con descargar o clonar el repositorio y ejecutar el script.

### Clonar el repositorio

```powershell
git clone https://github.com/tu-usuario/TestCorrector.git
cd TestCorrector
```

### Ejecutar el script

```powershell
.\TestCorrector.ps1
```

Si la política de ejecución del sistema impide iniciar scripts, puede ser necesario habilitar la ejecución para el usuario actual:

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

Como siempre en PowerShell, conviene revisar el contenido del script antes de ejecutarlo si se ha descargado desde una fuente externa.

---

## Formato de las preguntas

El proyecto trabaja con preguntas en texto plano. No utiliza un formato propietario ni estructuras complejas. El parser reconoce preguntas y opciones basándose en patrones simples.

### Ejemplo básico

```txt
¿Qué comando se utiliza para listar archivos en Linux?
A) ls
B) cd
C) mkdir
D) pwd
```

### Variante válida con punto

```txt
¿Qué extensión se usa para un script de PowerShell?
A. .bat
B. .ps1
C. .cmd
D. .vbs
```

### Soporte de enunciado multilínea

```txt
¿Qué instrucción permite comparar si una variable
contiene un valor nulo dentro de un script de PowerShell?
A) .Count
B) $null
C) -contains
D) -match
```

### Cómo interpreta el parser el contenido

El parser sigue una lógica deliberadamente sencilla:

* ignora líneas vacías
* detecta opciones que empiecen por `A`, `B`, `C` o `D`, seguidas de `)` o `.`
* considera el resto como parte del enunciado
* cuando una pregunta ya tiene opciones y aparece un nuevo bloque de texto, asume que empieza una nueva pregunta
* concatena varias líneas del enunciado cuando corresponde

### Consideraciones prácticas

Conviene mantener cierta limpieza en el archivo de entrada. El parser es flexible, pero no hace magia. Si el texto mezcla formatos incoherentes, numeraciones partidas o estructuras ambiguas, el resultado puede no ser el esperado.

El script asigna numeración interna automáticamente a las preguntas según el orden en el que se reconocen. En otras palabras, la numeración se deriva del bloque cargado, no de un identificador externo complejo.

---

## Formato de la clave de respuestas

La clave de corrección también se introduce en texto plano. El script admite varios formatos habituales, lo cual facilita reutilizar claves escritas de formas distintas.

### Formatos admitidos

```txt
1.B
2:C
3-A
4)D
```

También admite una variante más simple como esta:

```txt
1 B
2 C
3 A
4 D
```

### Comportamiento del parser de la clave

* acepta letras en mayúscula o minúscula
* normaliza internamente la letra a mayúscula
* reconoce varios separadores comunes
* intenta un segundo patrón si el formato principal no produce resultados

### Qué ocurre si faltan entradas

Si una pregunta no tiene entrada en la clave, la aplicación no la evalúa ni la colorea al corregir. Esto permite cargar bancos de preguntas donde la clave esté incompleta, aunque lo ideal sigue siendo trabajar con un conjunto consistente.

---

## Corrección y sistema de puntuación

Uno de los detalles más importantes del proyecto es que la puntuación no se limita al clásico aciertos sobre total. El script aplica una penalización por errores.

### Fórmula utilizada

La puntuación neta se calcula así:

```txt
A - (E / 2)
```

Donde:

* `A` es el número de aciertos
* `E` es el número de errores
* las preguntas en blanco no suman ni restan

Después, esa puntuación neta se transforma en nota sobre 10 y en porcentaje respecto al total de preguntas evaluadas.

### Ejemplo

Supongamos un bloque de 20 preguntas evaluadas con este resultado:

* 12 correctas
* 4 incorrectas
* 4 en blanco

Entonces:

```txt
Puntuación neta = 12 - (4 / 2) = 10
Nota sobre 10   = 10 / 20 * 10 = 5
Porcentaje      = 10 / 20 * 100 = 50%
```

Además, el script limita la puntuación neta mínima a 0 para evitar resultados finales negativos.

---

## Comportamiento visual durante la corrección

La corrección no solo genera un número final. También transforma la interfaz para que se vea con claridad qué ha ocurrido en cada pregunta.

### Opciones

Al corregir, cada opción puede quedar en uno de estos estados:

* correcta, si coincide con la clave
* incorrecta, si fue seleccionada por el usuario pero no coincide con la clave
* neutra, si no es ni la correcta ni la seleccionada erróneamente

### Tarjetas

Cada tarjeta incorpora un badge numérico que también cambia de estado:

* verde si la respuesta es correcta
* rojo si la respuesta es incorrecta
* amarillo si está en blanco

Esto permite revisar el test visualmente sin depender solo de la ventana final de resultados.

---

## Ventana de resultados

Cuando finaliza la corrección, la aplicación abre una ventana específica con el resumen del examen.

La ventana muestra:

* porcentaje obtenido
* nota sobre 10
* fórmula aplicada
* número de respuestas correctas
* número de respuestas incorrectas
* número de respuestas sin responder
* penalización total aplicada

La nota principal también cambia de color en función del resultado, de forma que la lectura sea inmediata.

---

## Exportación de respuestas

El proyecto incluye una función útil para sacar una representación rápida del estado del test. No exporta una hoja compleja ni genera informes pesados. Genera un listado compacto, práctico y fácil de reutilizar.

### Ejemplo de salida

```txt
1.A  2.C  3.__  4.B  5.D
```

Si una pregunta no tiene respuesta, se exporta con `__`.

La salida se agrupa por bloques para que sea legible y se muestra en una ventana desde la que puede copiarse al portapapeles.

### Para qué puede servir

* registrar un intento manualmente
* guardar una copia rápida del estado del test
* comparar respuestas con otra persona
* trasladar el resultado a otro formato
* hacer comprobaciones rápidas sin necesidad de base de datos

---

## Estructura interna del script

El archivo está organizado por bloques visibles, lo cual facilita mucho su lectura y mantenimiento. En scripts grandes de PowerShell esto no siempre ocurre, y aquí sí se ha tenido en cuenta.

### Resumen de bloques

* **Bloque 1**: estado global
* **Bloque 2**: paleta de colores
* **Bloque 3**: parser de preguntas y clave
* **Bloque 4**: helpers de controles WPF
* **Bloque 5**: ventana principal
* **Bloque 6**: cabecera
* **Bloque 7**: contenido
* **Bloque 8**: panel izquierdo
* **Bloque 9**: panel derecho
* **Bloque 10**: pie de ventana
* **Bloque 11**: tarjeta de pregunta y opciones
* **Bloque 12**: progreso
* **Bloque 12b**: zoom
* **Bloque 13**: acciones del usuario
* **Bloque 14**: ventana de resultados
* **Bloque 15**: ventana de exportación
* **Bloque 16**: arranque

### Variables de estado principales

El script utiliza varias variables en ámbito `Script:` para mantener el estado de la sesión.

#### `$Script:Questions`

Lista de preguntas reconocidas y cargadas en memoria.

#### `$Script:AnswerKeys`

Diccionario con la clave de respuestas parseada.

#### `$Script:UIState`

Estructura donde se guarda el estado visual e interactivo de cada tarjeta, incluyendo badge, controles de opciones y respuesta seleccionada.

#### `$Script:CurrentZoom`

Nivel de zoom actual aplicado sobre el panel de preguntas.

---

## Casos de uso razonables

TestCorrector encaja bien en escenarios donde se quiere una herramienta local, rápida y sin infraestructura adicional.

Por ejemplo:

* simulacros de examen
* autocorrección de cuestionarios
* ejercicios de aula
* prácticas internas
* revisiones rápidas de bancos de preguntas
* prototipos de aplicaciones educativas en PowerShell
* demostraciones de WPF sin XAML

También puede servir como base para otros desarrollos más completos si se quiere evolucionar el proyecto.

---

## Limitaciones actuales

Conviene dejar claras las limitaciones reales del proyecto.

Actualmente el proyecto:

* está orientado a preguntas de cuatro opciones (`A-D`)
* no guarda resultados automáticamente en disco
* no persiste sesiones entre ejecuciones
* no usa base de datos
* no gestiona usuarios ni autenticación
* no tiene temporizador de examen
* no randomiza preguntas ni respuestas
* no está diseñado para entorno web
* no es multiusuario
* depende de Windows por el uso de WPF

---

## Posibles mejoras futuras

La base actual permite ampliar bastante el proyecto sin tener que tirarlo todo abajo. Algunas mejoras razonables serían estas.

### Persistencia de resultados

Guardar intentos, puntuaciones y fechas en archivos o base de datos ligera.

### Integración con SQLite

Tener un banco de preguntas persistente, categorías, estadísticas o historial de exámenes.

### Más formatos de importación

Permitir carga desde `CSV`, `JSON` o `XML` además del texto plano.

### Temporizador

Añadir un modo examen con tiempo límite.

### Configuración de penalización

Hacer que la fórmula de corrección sea configurable.

### Más tipos de preguntas

Ampliar el modelo para soportar más de cuatro opciones o incluso otros formatos de ejercicio.

### Aleatorización

Mezclar preguntas y respuestas para reducir memorización mecánica.

### Exportación a archivo

Guardar las respuestas o resultados a `.txt`, `.csv` o incluso PDF mediante una capa adicional.

### Panel de estadísticas

Mostrar medias, aciertos por bloque o evolución de intentos.

### Mejor separación interna

Si el proyecto creciera mucho, sería razonable separar lógica de interfaz, parser y motor de corrección.


---

## Autor
Desarrollado por [SergioGL](https://github.com/SergioGL-14)]



