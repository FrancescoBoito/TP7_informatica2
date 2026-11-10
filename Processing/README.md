# Processing: ejecutar la interfaz

## Programa correcto

Usar **Processing de escritorio, modo Java**. El archivo `.pde` no se abre en Arduino IDE, el editor web de p5.js ni Python. Descarga oficial: https://processing.org/download.

La biblioteca `processing.serial` forma parte de Processing; no se usa Firmata ni ControlP5. Arduino debe ejecutar el sketch propio incluido en este repositorio.

## Paso a paso

1. Cargar primero el programa de Arduino siguiendo el README de esa carpeta.
2. Cerrar el Monitor Serie y el Plotter Serie de Arduino IDE.
3. Abrir Processing y seleccionar **Java** como modo.
4. Abrir `TP7_Processing/TP7_Processing.pde`. Mantener carpeta y archivo con el mismo nombre.
5. Pulsar Ejecutar, el botón triangular.
6. Si Arduino no estaba enchufado, conectarlo y pulsar **Buscar**.
7. Usar `<` y `>` hasta mostrar el puerto correcto. En Windows suele tener un nombre como COM3; en Linux puede ser `/dev/ttyACM0` o `/dev/ttyUSB0`. Son ejemplos, no valores que debas copiar.
8. Pulsar **Conectar** y esperar el primer informe. Arduino puede reiniciarse al abrir USB. La interfaz permite hasta cinco segundos de espera.
9. Cuando aparezca el mensaje verde, observar E1/E2 y probar L1/L2 con un clic.
10. Pulsar **Desconectar** antes de cambiar de puerto o volver a subir código desde Arduino IDE. Cerrar la aplicación también libera el puerto mediante la biblioteca serie.

## Interpretar los colores

| Casillero | Estado | Significado |
|---|---|---|
| Entrada azul | ALTO (1) | Pulsador suelto / switch abierto |
| Entrada oscura | BAJO (0) | Pulsador presionado / switch cerrado |
| Salida verde | ENCENDIDO (1) | Arduino ordenó HIGH a ese LED |
| Salida oscura | APAGADO (0) | Arduino ordenó LOW a ese LED |
| Casillero gris | SIN DATOS | No hay una conexión confirmada |

El pulsador y el switch usan lógica activa en bajo. Por eso una entrada BAJA puede corresponder a un LED ENCENDIDO. La pantalla muestra ambas cosas explícitamente.

Solo las salidas son editables. La pantalla no cambia el estado del LED de forma anticipada: espera un informe de Arduino. Tras un clic, bloquea otro clic del mismo canal hasta recibir un informe posterior. Ese informe periódico no lleva número de secuencia; no es una confirmación transaccional individual.

## Si algo falla

| Problema | Qué revisar |
|---|---|
| No hay puertos | Cable de datos, USB, controlador de la placa y botón Buscar |
| No se puede conectar | Puerto elegido; Monitor/Plotter Serie u otra instancia de Processing abiertos |
| Se conecta pero termina en “Sin datos” | Sketch de Arduino correcto, velocidad 9600 y puerto correspondiente a esa placa |
| El LED físico no coincide | Pin, polaridad del LED, resistencia y GND; la PC no mide el LED |
| Entrada siempre BAJA | Pulsador mal orientado, contacto permanente con GND o switch cerrado |
| Entrada siempre ALTA | Falta de GND, contacto equivocado del pulsador o switch sin cerrar |
| Cambiar puerto no responde | Primero pulsar Desconectar; el selector se modifica con el puerto cerrado |
| Cable desconectado | La pantalla invalida datos al detectar el error o, como máximo, tras cinco segundos sin informes; reconectar manualmente |
| Error de biblioteca o de Java | Abrir en Processing de escritorio con modo Java y revisar la instalación |

En Linux, si aparece “Permission denied”, comprobar el grupo propietario del dispositivo con `ls -l /dev/ttyACM0` (usar el nombre real del puerto). Si pertenece a `dialout`, agregar tu usuario con `sudo usermod -aG dialout "$USER"`, cerrar sesión completamente y volver a entrar. No ejecutar Processing como root. Otros sistemas pueden usar otro grupo: revisar el dispositivo antes de aplicar el comando.

## Lectura guiada

- `setup()`: crea la ventana y busca puertos.
- `conectar()` y `cerrarPuerto()`: administran el recurso serie.
- `leerPuerto()`: recibe caracteres por partes sin congelar el dibujo.
- `interpretar()`: acepta únicamente informes del formato esperado.
- `draw()`: dibuja entradas, salidas, estados e instrucciones.
- `mousePressed()`: atiende el selector, conexión y clics de salida.
- `dentro()` y `boton()`: reutilizan la detección de clics y el dibujo de botones.
