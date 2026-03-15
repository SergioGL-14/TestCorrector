# TestCorrector

TestCorrector es una aplicación de escritorio hecha en PowerShell para cargar preguntas tipo test, responderlas desde una interfaz gráfica WPF y corregir el resultado a partir de una plantilla de respuestas. El repositorio incluye además dos prompts orientados a preparar material de estudio y a localizar recursos reales de examen, por lo que el proyecto no se queda solo en la corrección visual del test, sino que también cubre la parte previa de búsqueda y generación de contenido de práctica. ([github.com](https://github.com/SergioGL-14/TestCorrector/tree/main))

La idea del repositorio es bastante directa: disponer de una herramienta local para resolver y corregir cuestionarios, y acompañarla con dos prompts reutilizables que permitan montar mejor el flujo completo de preparación. Uno sirve para generar exámenes tipo test técnicos con formato limpio y plantilla final de respuestas, y el otro está pensado para buscar exámenes reales, convocatorias anteriores, simulacros docentes y materiales auténticos de evaluación. ([github.com](https://github.com/SergioGL-14/TestCorrector/raw/refs/heads/main/Prompt%20Realizador%20Examenes))

---

## Qué incluye el repositorio

Actualmente el repositorio contiene estos elementos principales:

* `TestCorrector.ps1`
* `Prompt Realizador Examenes`
* `Promt Buscador Examenes`
* `README.md`
* `LICENSE` ([github.com](https://github.com/SergioGL-14/TestCorrector/tree/main))

La pieza central es la aplicación WPF, pero los dos prompts complementan muy bien el uso del proyecto porque ayudan a crear o localizar material con el que luego trabajar dentro del corrector.

---

## Qué hace la aplicación

La aplicación permite:

* cargar preguntas desde texto o desde archivo
* cargar una clave de respuestas
* mostrar las preguntas en una interfaz WPF
* seleccionar respuestas de forma visual
* corregir automáticamente el test
* ver aciertos, errores, blancas y nota final
* exportar las respuestas marcadas
* reiniciar el test o limpiar toda la sesión

La corrección usa una fórmula con penalización:

```txt
A - (E / 2)
```

Donde `A` son los aciertos y `E` los errores. Las preguntas en blanco no suman ni restan. Después calcula la nota sobre 10 y el porcentaje final. ([github.com](https://github.com/SergioGL-14/TestCorrector/tree/main))

---

## Papel de los prompts dentro del proyecto

### 1. Prompt Realizador Examenes

Este prompt está pensado para generar exámenes tipo test técnicos con un formato bastante controlado. Obliga a que las preguntas tengan exactamente cuatro opciones, pide que el examen tenga tono realista, técnico y útil para estudiar, y exige que al final se devuelva una plantilla compacta de respuestas en formato tipo `1.B 2.C 3.A ...`. También da prioridad al material aportado por el usuario y, si se dispone de acceso a Internet, pide contrastar conceptos, comandos, sintaxis y estilo real de evaluación con fuentes fiables.

La utilidad práctica dentro de este repositorio es clara: ese prompt permite generar contenido de práctica que luego puede adaptarse al formato de carga de TestCorrector para resolverlo y corregirlo visualmente.

### 2. Promt Buscador Examenes

El segundo prompt no crea exámenes. Hace justo lo contrario: fuerza a buscar, verificar, filtrar y clasificar materiales reales de evaluación, priorizando exámenes auténticos, convocatorias anteriores, recuperaciones, simulacros docentes, programaciones y otros recursos publicados por centros, departamentos o fuentes fiables. Además, exige clasificar la fidelidad de cada recurso encontrado y dejar claras las limitaciones si no aparecen materiales realmente buenos.

### Flujo

Visto en conjunto, el flujo es así:

1. Buscar material real o muy fiel con `Promt Buscador Examenes`.
2. Generar un examen técnico nuevo o adaptado con `Prompt Realizador Examenes` cuando haga falta practicar un tema concreto.
3. Cargar preguntas y plantilla en `TestCorrector` para responder, corregir y revisar resultados.

---

## Tecnologías usadas

El proyecto está hecho con:

* PowerShell
* WPF
* `PresentationFramework`
* `PresentationCore`
* `WindowsBase`
* `System.Windows.Forms` para la apertura de archivos desde diálogo gráfico

Está pensado para ejecutarse en Windows. La parte gráfica depende de WPF, así que no está planteado como proyecto multiplataforma.

---

## Ejecución

Clona el repositorio o descarga el script:

```powershell
git clone https://github.com/SergioGL-14/TestCorrector.git
cd TestCorrector
```

Después ejecuta:

```powershell
.\TestCorrector.ps1
```

Si la política de ejecución bloquea scripts:

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```
---

## Uso básico

### 1. Cargar preguntas

Puedes pegarlas en el cuadro de texto o abrir un archivo `.txt`. Una vez cargadas, la aplicación las representa como tarjetas en el panel derecho.

### 2. Cargar la clave

La clave también se puede pegar o cargar desde archivo. El script acepta varios formatos habituales y normaliza internamente las letras de respuesta.

### 3. Responder

Cada pregunta aparece como una tarjeta con sus opciones. Al hacer clic sobre una opción, queda marcada.

### 4. Corregir

Al corregir, la aplicación compara las respuestas con la clave, colorea los estados y muestra un resumen final.

### 5. Exportar

Se puede sacar un resumen de respuestas seleccionadas en formato compacto para copiarlo o guardarlo.

---

## Formato de preguntas

El script espera preguntas en texto plano con opciones tipo `A`, `B`, `C` y `D`.

Ejemplo:

```txt
¿Qué comando se utiliza para listar archivos en Linux?
A) ls
B) cd
C) mkdir
D) pwd
```

También reconoce variantes como:

```txt
A. opción
B. opción
```

Los enunciados pueden ocupar varias líneas y las líneas vacías se ignoran.

---

## Formato de la clave

La clave admite formatos como estos:

```txt
1.A
2:C
3-A
4)D
```

O una versión más simple:

```txt
1 B
2 C
3 A
4 D
```
---

## Limitaciones actuales

Ahora mismo el proyecto está centrado en un caso concreto:

* preguntas de 4 opciones
* ejecución local
* sin base de datos
* sin usuarios
* sin temporizador
* sin aleatorización de preguntas
* sin guardado automático de resultados

Además, los prompts no están integrados dentro de la interfaz como funciones automáticas. Forman parte del repositorio como recursos de apoyo y su uso depende de aplicarlos fuera de la aplicación, por ejemplo en ChatGPT u otra herramienta compatible.

---

## Posibles mejoras

Algunas mejoras razonables para más adelante serían:

* soporte para más formatos de importación
* guardado de resultados
* banco de preguntas persistente
* temporizador de examen
* configuración de la penalización
* aleatorización de preguntas y respuestas
* integración más directa entre la aplicación y los prompts del repositorio
* conversión automática de exámenes generados al formato de carga de la app
* importación rápida de claves generadas por el prompt realizador
---

## Autor

Desarrollado por [SergioGL-14](https://github.com/SergioGL-14).



