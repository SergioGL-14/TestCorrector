# TestCorrector

TestCorrector es una aplicación hecha en PowerShell para cargar preguntas tipo test, responderlas desde una interfaz gráfica y corregir el resultado a partir de una plantilla de respuestas.

La idea del proyecto es simple: tener una herramienta local, directa y fácil de tocar para trabajar con cuestionarios sin depender de una web, una base de datos o un sistema más grande de lo necesario.

---

## Qué hace

La aplicación permite:

* cargar preguntas desde texto o desde un archivo
* cargar una clave de respuestas
* mostrar las preguntas en una interfaz WPF
* seleccionar respuestas de forma visual
* corregir el test automáticamente
* ver aciertos, errores, blancas y nota final
* exportar las respuestas marcadas
* reiniciar el test o limpiar toda la sesión

No pretende ser una plataforma de exámenes. Es una utilidad local para resolver y corregir tests de forma rápida.

---

## Tecnologías usadas

El proyecto está hecho con:

* PowerShell
* WPF
* `PresentationFramework`
* `PresentationCore`
* `WindowsBase`
* `System.Windows.Forms` para los diálogos de apertura de archivos

Está pensado para ejecutarse en Windows.

---

## Requisitos

Para usarlo hace falta:

* Windows
* PowerShell 5.1 o superior
* entorno gráfico de escritorio

No está planteado para Linux o macOS porque la interfaz depende de WPF.

---

## Ejecución

Clona el repositorio o descarga el script:

```powershell
git clone https://github.com/tu-usuario/TestCorrector.git
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

## Uso

El flujo es bastante directo.

### 1. Cargar preguntas

Puedes pegarlas en el cuadro de texto o abrir un archivo `.txt`.

### 2. Cargar la clave

La clave también se puede pegar o cargar desde archivo.

### 3. Responder

Cada pregunta aparece como una tarjeta con sus opciones. Al hacer clic sobre una opción, queda marcada.

### 4. Corregir

Al corregir, la aplicación compara cada respuesta con la clave y muestra el resultado tanto visualmente como en una ventana resumen.

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

Los enunciados pueden ocupar varias líneas. Las líneas vacías se ignoran.

---

## Formato de la clave

La clave admite varios formatos habituales. Por ejemplo:

```txt
1.A
2:C
3-A
4)D
```

También admite una versión más simple:

```txt
1 B
2 C
3 A
4 D
```

Internamente el script normaliza las letras para poder comparar sin depender del formato exacto.

---

## Cómo corrige

La aplicación no solo cuenta aciertos. Usa una fórmula con penalización:

```txt
A - (E / 2)
```

Donde:

* `A` = aciertos
* `E` = errores

Las preguntas en blanco no suman ni restan.

Después calcula la nota sobre 10 y el porcentaje.

---

## Resultado visual

Al corregir, cada pregunta cambia de estado para que se vea rápido qué ha pasado:

* verde si está bien
* rojo si está mal
* amarillo si se dejó en blanco

Las opciones también se remarcan para distinguir la correcta y la seleccionada erróneamente cuando toca.

---

## Exportación de respuestas

La exportación genera una salida resumida como esta:

```txt
1.A  2.C  3.__  4.B
```

Si una pregunta no tiene respuesta, se marca como `__`.

Es útil para guardar un intento rápido o comparar respuestas sin complicarse más.

---

## Limitaciones actuales

Ahora mismo el proyecto está centrado en un caso bastante concreto:

* preguntas de 4 opciones
* ejecución local
* sin base de datos
* sin usuarios
* sin temporizador
* sin aleatorización de preguntas
* sin guardado automático de resultados

Para lo que está hecho, cumple. Si se quisiera convertir en algo más grande, habría que ampliar bastante la base actual.

---

## Posibles mejoras

Algunas mejoras razonables para más adelante serían:

* soporte para más formatos de importación
* guardado de resultados
* banco de preguntas persistente
* temporizador de examen
* configuración de la penalización
* aleatorización de preguntas y respuestas
* estadísticas por intento

---

## Autor
Desarrollado por [SergioGL](https://github.com/SergioGL-14)



