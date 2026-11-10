# TP7 — Entorno gráfico de Arduino con Processing

**Autor:** Francesco Boito Diaz  
**Legajo:** 53136  
**Materia:** Informática II — Ingeniería Telecom, UTN FRM  
**Ciclo lectivo:** 2026

Este trabajo permite observar dos entradas digitales de Arduino y controlar dos LEDs desde una interfaz de Processing. El pulsador y el switch también controlan sus LEDs correspondientes. Arduino transmite los niveles de entrada y los estados de salida para mantener actualizada la pantalla.

## Video de demostración 

https://youtube.com/shorts/2NnKx0Wrlv8  

## Empezar desde cero

1. Descargar el repositorio completo o descomprimir el ZIP. No abrir los archivos dentro del ZIP.
2. Reunir un **Nano clásico ATmega328P**, un pulsador, un switch, dos LEDs, dos resistencias de **330 Ω**, protoboard, cables y cable USB de datos.
3. Armar el circuito con el USB desconectado siguiendo [Arduino/README.md](Arduino/README.md).
4. Cargar [TP7_Arduino.ino](Arduino/TP7_Arduino/TP7_Arduino.ino) con Arduino IDE y cerrar el Monitor Serie.
5. Abrir [TP7_Processing.pde](Processing/TP7_Processing/TP7_Processing.pde) en **Processing, modo Java**, y pulsar Ejecutar.
6. Elegir el puerto de Arduino con las flechas y pulsar **Conectar**. Esperar el mensaje verde de conexión.
7. Probar el pulsador y el switch, y hacer clic en los casilleros de salida. Seguir [Processing/README.md](Processing/README.md) si aparece un problema.

El esquema corresponde al montaje previsto: Nano clásico, pulsador en D2, switch en D3 y LEDs en D8/D9. Falta comprobarlo en el circuito real.

## Circuito

![Esquema eléctrico del TP7](Documentacion/esquema.png)


| Canal | Entrada | Control físico | Salida | LED |
|---|---|---|---|---|
| 1 | D2, INPUT_PULLUP | Pulsador entre D2 y GND | D8 | D8 → 330 Ω → ánodo L1; cátodo → GND |
| 2 | D3, INPUT_PULLUP | Switch entre D3 y GND | D9 | D9 → 330 Ω → ánodo L2; cátodo → GND |

## Cómo interactúan el mouse y las entradas

- **Entrada abierta:** nivel eléctrico ALTO, valor 1. **Entrada cerrada:** BAJO, valor 0. Esto se debe a INPUT_PULLUP.
- Un cambio físico confirmado durante 30 ms fija la salida correspondiente: al cerrar enciende y al abrir apaga.
- Un clic en L1 o L2 pide el estado contrario al último recibido. La pantalla cambia cuando Arduino informa su estado; no simula el LED.
- La orden del mouse se conserva hasta el siguiente cambio físico de **esa** entrada, o hasta otra orden del mouse. Mantener el control físico inmóvil no sobrescribe continuamente el mouse.
- Si una orden y un cambio físico estable coinciden en la misma vuelta del programa, tiene prioridad el cambio físico: `loop()` procesa primero los comandos y después las entradas.
- Los canales son independientes. Reiniciar Arduino restablece las salidas según las entradas presentes al arrancar.
- El funcionamiento de las entradas continúa aunque Processing esté cerrado.

Ejemplo: con el pulsador de D2 suelto, un clic en L1 enciende el LED; pulsarlo lo deja encendido; soltarlo lo apaga. El siguiente clic vuelve a encenderlo.

## Correspondencia con la consigna

| Requisito | Implementación |
|---|---|
| Mostrar entradas y salidas mediante colores | E1/E2 muestran ALTO/BAJO; L1/L2 muestran encendido/apagado |
| Activar salidas con el mouse | Clic en L1 o L2 envía una orden serie |
| Activar la salida frente a cada entrada | El pulsador D2 controla L1; el switch D3 controla L2 |
| Intercambio de información en ambos sentidos | Processing envía órdenes; Arduino informa entradas y salidas |
| Código fuente y esquema | Carpetas Arduino, Processing y Documentacion |




## Referencias

- [Processing: biblioteca Serial](https://processing.org/reference/libraries/serial/).
- [Arduino: INPUT_PULLUP](https://docs.arduino.cc/language-reference/en/variables/constants/inputOutputPullup/).
