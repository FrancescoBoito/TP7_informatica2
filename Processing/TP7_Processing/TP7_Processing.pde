// TP7 - Informatica II - Francesco Boito Diaz - Legajo 53136.
// Abrir este archivo en Processing, modo Java; no en Arduino IDE ni p5.js.
import processing.serial.*; // Incorpora la biblioteca serie incluida en Processing.
Serial puerto; // Representa el puerto USB serie abierto; null significa cerrado.
// Un arreglo guarda varios valores del mismo tipo; [0] es el primer indice.
String[] puertos = new String[0]; // Guarda los nombres de los puertos disponibles.
int elegido = 0; // Guarda el indice del puerto seleccionado por el usuario.
String recibido = ""; // Acumula una linea serie aunque llegue en varios fragmentos.
// boolean solo puede valer true o false; sirve para recordar situaciones de si/no.
boolean descartando = false; // Descarta una linea si supera el limite de longitud.
boolean datosValidos = false; // Evita mostrar estados inventados antes de recibir Arduino.
int[] entradas = {1, 1}; // Reserva los dos niveles electricos; no se muestran hasta confirmarlos.
int[] leds = {0, 0}; // Reserva los dos estados de salida informados por Arduino.
boolean[] pendiente = {false, false}; // Impide repetir clics antes de recibir un informe posterior.
int ultimoDato = 0; // Guarda cuando se recibio el ultimo estado valido.
int inicioConexion = 0; // Guarda cuando se abrio el puerto para controlar la espera inicial.
String mensaje = "Selecciona el puerto de tu Arduino y pulsa Conectar."; // Explica el siguiente paso al usuario.

// Processing la ejecuta una sola vez al iniciar la interfaz.
// void indica que no devuelve un valor; no recibe parametros y prepara ventana y puertos.
void setup() { // Inicia la configuracion de Processing.
  size(900, 640); // Crea una ventana con espacio para controles y dos canales.
  surface.setTitle("TP7 | Arduino + Processing | Francesco Boito Diaz"); // Identifica la aplicacion en la barra de titulo.
  textFont(createFont("SansSerif", 17)); // Usa una fuente legible disponible en el sistema.
  frameRate(30); // Actualiza el dibujo hasta treinta veces por segundo.
  actualizarPuertos(); // Busca puertos sin asumir que Arduino es el primero.
} // Termina setup.

// Se llama al iniciar y al pulsar Buscar con el puerto cerrado.
// No recibe parametros ni devuelve datos; actualiza puertos, elegido y mensaje.
void actualizarPuertos() { // Actualiza la lista del selector.
  try { // Protege la busqueda frente a errores de la biblioteca serie.
    puertos = Serial.list(); // Obtiene los nombres reales de los puertos del sistema.
    elegido = 0; // Selecciona el primer elemento como punto de partida.
    // == compara igualdad; ?: elige el texto anterior a : si se cumple y el posterior si no.
    mensaje = puertos.length == 0 ? "No hay puertos: conecta Arduino y pulsa Buscar." : "Selecciona el puerto y pulsa Conectar."; // Da una indicacion segun el resultado.
  } catch (Exception error) { // Termina el intento de busqueda; atiende un fallo al enumerar puertos.
    puertos = new String[0]; // Mantiene el selector vacio ante el error.
    mensaje = "No se pudieron listar puertos: " + error.getMessage(); // Muestra el motivo disponible.
  } // Termina el manejo de errores de busqueda.
} // Termina actualizarPuertos.

// Se llama al desconectar, al detectar un error o al fallar la conexion.
// No recibe parametros ni devuelve datos; limpia puerto, datosValidos y recepcion pendiente.
void cerrarPuerto() { // Libera el puerto para reconectar o cargar un sketch.
  Serial anterior = puerto; // Conserva la referencia antes de marcarlo como cerrado.
  puerto = null; // Bloquea inmediatamente nuevos envios y lecturas.
  datosValidos = false; // Invalida la informacion anterior para que no parezca actual.
  pendiente[0] = pendiente[1] = false; // Borra las ordenes pendientes de la sesion anterior.
  recibido = ""; // Descarta cualquier fragmento incompleto.
  descartando = false; // Reinicia el control de longitud de las lineas.
  // if ejecuta el bloque si la condicion es verdadera; != significa distinto.
  if (anterior != null) { // Comprueba que habia una conexion abierta.
    try { // Protege el cierre frente a un cable ya desconectado.
      anterior.stop(); // Devuelve el puerto al sistema operativo.
    } catch (Exception error) { // Termina el intento de cierre; atiende un error sin detener la interfaz.
      println("Cierre del puerto: " + error.getMessage()); // Deja el detalle en la consola de Processing.
    } // Termina el intento de cierre.
  } // Termina el caso de puerto abierto.
} // Termina cerrarPuerto.

// Se llama al pulsar Conectar.
// No recibe parametros ni devuelve datos; abre puerto y actualiza el estado de conexion.
void conectar() { // Intenta abrir el puerto seleccionado.
  if (puertos.length == 0) { // Evita acceder a una lista vacia.
    mensaje = "Conecta Arduino por USB y pulsa Buscar."; // Indica como obtener un puerto.
    return; // Sale de la funcion sin intentar abrir una lista vacia.
  } // Termina la comprobacion de lista vacia.
  try { // Protege la apertura ante puerto ocupado o falta de permisos.
    puerto = new Serial(this, puertos[elegido], 9600); // Abre exactamente el puerto elegido a 9600 baudios.
    puerto.clear(); // Descarta bytes anteriores a esta sesion.
    datosValidos = false; // Espera el primer informe completo de Arduino.
    inicioConexion = millis(); // Inicia el plazo que permite el reinicio automatico de Arduino.
    mensaje = "Esperando Arduino; puede reiniciarse al abrir el puerto..."; // Explica la pausa normal de arranque.
  } catch (Exception error) { // Termina el intento de apertura; atiende errores de conexion.
    cerrarPuerto(); // Limpia cualquier conexion que haya quedado a medio abrir.
    mensaje = "No se pudo conectar. Cierra el Monitor Serie y revisa puerto/permisos."; // Presenta una accion concreta.
    println(error.getMessage()); // Conserva el detalle tecnico en la consola.
  } // Termina el intento de conexion.
} // Termina conectar.

// Se llama al terminar de recibir una linea serie.
// Recibe linea como parametro: es una copia del mensaje para analizar; no devuelve datos.
// Si el informe es valido, modifica entradas, leds, pendiente y los datos de conexion.
void interpretar(String linea) { // Valida el informe antes de cambiar la pantalla.
  // ! invierte el resultado: se descarta la linea si no coincide con el formato.
  if (!linea.matches("E,[01],[01],[01],[01]")) { // Exige cuatro valores binarios con el formato esperado.
    return; // Ignora ruido, mensajes incompletos y formatos ajenos al TP.
  } // Termina la validacion del informe.
  entradas[0] = linea.charAt(2) - '0'; // Extrae el nivel electrico E1 informado por Arduino.
  entradas[1] = linea.charAt(4) - '0'; // Extrae el nivel electrico E2 informado por Arduino.
  leds[0] = linea.charAt(6) - '0'; // Extrae el nivel aplicado a la salida L1.
  leds[1] = linea.charAt(8) - '0'; // Extrae el nivel aplicado a la salida L2.
  pendiente[0] = pendiente[1] = false; // Habilita nuevos clics tras recibir informacion de la placa.
  ultimoDato = millis(); // Renueva el tiempo de la ultima comunicacion valida.
  datosValidos = true; // Autoriza mostrar los valores recibidos como actuales.
  mensaje = "Conectado | Entradas y salidas informadas por Arduino."; // Confirma la recepcion de datos.
} // Termina interpretar.

// Se llama en cada draw para leer los bytes ya disponibles.
// No recibe parametros ni devuelve datos; arma recibido y actualiza estados al obtener informes.
void leerPuerto() { // Lee sin esperar desde el mismo hilo que dibuja la interfaz.
  if (puerto == null) { // Comprueba si hay conexion.
    return; // No intenta leer un puerto cerrado.
  } // Termina la comprobacion de conexion.
  try { // Protege lecturas ante una desconexion fisica.
    int presupuesto = 256; // Limita los caracteres procesados por fotograma.
    // while repite el bloque mientras haya datos y quede presupuesto; && exige ambas condiciones.
    while (puerto.available() > 0 && presupuesto > 0) { // Lee solo lo disponible sin congelar la ventana.
      presupuesto--; // -- resta uno al limite de caracteres de este fotograma.
      int dato = puerto.read(); // Extrae el siguiente byte o -1 si ya no queda ninguno.
      // || permite entrar si se cumple cualquiera de las dos condiciones.
      if (dato < 0 || dato == '\r') { // Reconoce ausencia de dato o retorno de carro.
        continue; // Evita acumular esos valores en la linea.
      } // Termina el filtro de caracteres.
      if (dato == '\n') { // Detecta el final de un mensaje.
        if (!descartando) { // Solo procesa una linea que no excedio el limite.
          interpretar(recibido); // Valida y aplica el informe completo.
        } // Termina el tratamiento de linea aceptable.
        recibido = ""; // Prepara la acumulacion del siguiente mensaje.
        descartando = false; // Recupera la recepcion despues de una linea demasiado larga.
      } else if (!descartando) { // Termina el caso de LF; acumula un caracter ordinario.
        if (recibido.length() < 64) { // Impide que una linea sin salto crezca indefinidamente.
          recibido += (char) dato; // += agrega este caracter al fragmento ya recibido.
        } else { // Termina el caso con espacio; atiende una linea excesiva.
          descartando = true; // Descarta todo hasta el proximo salto de linea.
        } // Termina el control de longitud.
      } // Termina el tratamiento del byte.
    } // Termina la lectura de este fotograma.
    // El operador ?: elige el primer valor si la condicion es verdadera y el segundo si es falsa.
    int referencia = datosValidos ? ultimoDato : inicioConexion; // Usa el ultimo dato o el inicio de la conexion como referencia.
    if (millis() - referencia > 5000) { // Detecta cinco segundos sin informes validos.
      cerrarPuerto(); // Libera el puerto y oculta datos que dejaron de ser actuales.
      mensaje = "Sin datos de Arduino. Revisa cable, sketch y puerto; vuelve a conectar."; // Indica como recuperar la comunicacion.
    } // Termina la deteccion de falta de datos.
  } catch (Exception error) { // Termina el intento de lectura; atiende un error serie.
    cerrarPuerto(); // Recupera el estado desconectado de forma ordenada.
    mensaje = "Conexion interrumpida. Revisa el USB y vuelve a conectar."; // Explica la accion necesaria.
    println(error.getMessage()); // Registra el detalle del error para diagnostico.
  } // Termina el manejo de errores de lectura.
} // Termina leerPuerto.

// Se llama al dibujar botones y al recibir un clic.
// Recibe la posicion y el tamano del rectangulo como parametros; no modifica estados.
// Devuelve un boolean: true si el mouse esta dentro, false si queda afuera.
boolean dentro(int x, int y, int ancho, int alto) { // Comprueba si el mouse esta dentro de un rectangulo.
  return mouseX >= x && mouseX <= x + ancho && mouseY >= y && mouseY <= y + alto; // >= y <= incluyen los bordes; return devuelve el resultado de las cuatro comparaciones.
} // Termina dentro.

// Se llama desde draw para dibujar cada boton del selector y la conexion.
// Recibe texto, posicion y ancho como parametros; dibuja en pantalla y no devuelve datos.
void boton(String etiqueta, int x, int y, int ancho) { // Dibuja un boton rectangular reutilizable.
  fill(dentro(x, y, ancho, 42) ? color(67, 88, 119) : color(43, 59, 82)); // Cambia el fondo al pasar el mouse.
  stroke(108, 129, 157); // Define el color del borde.
  rect(x, y, ancho, 42, 8); // Dibuja el contorno redondeado.
  fill(255); // Usa blanco para el texto del boton.
  textAlign(CENTER, CENTER); // Centra la etiqueta en ambos ejes.
  text(etiqueta, x + ancho / 2, y + 20); // Escribe el nombre del boton.
} // Termina boton.

// Processing la repite hasta 30 veces por segundo, segun frameRate.
// No recibe parametros ni devuelve datos; recibe informes y redibuja la pantalla.
void draw() { // Actualiza la comunicacion y redibuja toda la ventana.
  leerPuerto(); // Recibe los estados antes de representarlos.
  background(19, 28, 43); // Limpia la ventana con un fondo oscuro.
  fill(242, 246, 252); // Usa un color claro para los titulos.
  textAlign(LEFT, TOP); // Alinea el encabezado desde su esquina superior izquierda.
  textSize(28); // Destaca el titulo principal.
  text("Control de entradas y salidas", 30, 22); // Presenta el objetivo de la aplicacion.
  textSize(16); // Restaura un tamano compacto para los textos restantes.
  text("TP7 | Francesco Boito Diaz | Legajo 53136", 30, 62); // Muestra la autoria del trabajo.
  String nombre = puertos.length == 0 ? "Sin puertos disponibles" : puertos[elegido]; // Evita consultar un indice inexistente.
  text("Puerto: " + nombre, 30, 100, 830, 42); // Muestra el dispositivo seleccionado dentro de un area limitada.
  boton("<", 30, 150, 50); // Dibuja el boton para seleccionar el puerto anterior.
  boton(">", 90, 150, 50); // Dibuja el boton para seleccionar el puerto siguiente.
  boton("Buscar", 155, 150, 120); // Dibuja el boton para actualizar la lista de puertos.
  boton(puerto == null ? "Conectar" : "Desconectar", 290, 150, 180); // Adapta el boton al estado de conexion.
  textAlign(LEFT, TOP); // Alinea el mensaje de estado a la izquierda.
  fill(datosValidos ? color(97, 223, 175) : color(255, 203, 111)); // Diferencia conexion confirmada de espera o error.
  text(mensaje, 30, 207, 840, 52); // Muestra instrucciones sin invadir los canales.
  fill(235); // Prepara el color de los nombres de filas.
  text("ENTRADAS", 30, 295); // Identifica la fila que representa niveles electricos.
  text("SALIDAS", 30, 435); // Identifica la fila de LEDs controlables.
  // for empieza con i=0, repite mientras i<2 y suma uno por pasada; i es el indice del canal.
  for (int i = 0; i < 2; i++) { // Dibuja los dos canales usando las mismas medidas.
    int x = 260 + i * 310; // Ubica cada canal en su columna.
    fill(!datosValidos ? color(76) : entradas[i] == 1 ? color(47, 144, 211) : color(55, 67, 84)); // Representa HIGH azul, LOW oscuro y desconocido gris.
    stroke(150); // Define un borde visible para la entrada.
    rect(x, 280, 250, 90, 10); // Dibuja el casillero de entrada sin hacerlo editable.
    fill(255); // Prepara el texto claro sobre el casillero.
    textAlign(CENTER, CENTER); // Centra los datos del canal.
    text(i == 0 ? "E1 | pulsador D2" : "E2 | switch D3", x + 125, 300); // Identifica el control fisico de cada entrada.
    text(!datosValidos ? "SIN DATOS" : entradas[i] == 1 ? "ALTO (1) | abierto" : "BAJO (0) | cerrado", x + 125, 340); // Muestra niveles validos para pulsador y switch.
    fill(!datosValidos ? color(76) : leds[i] == 1 ? color(38, 184, 126) : color(55, 67, 84)); // Representa salida encendida verde y apagada oscura.
    rect(x, 410, 250, 100, 10); // Dibuja el casillero de salida sobre el que se puede hacer clic.
    fill(255); // Prepara el texto de la salida.
    text("L" + (i + 1) + " | D" + (i + 8), x + 125, 433); // Relaciona cada LED con D8 o D9.
    text(!datosValidos ? "SIN DATOS" : leds[i] == 1 ? "ENCENDIDO (1)" : "APAGADO (0)", x + 125, 465); // Muestra lo informado por la placa.
    text(pendiente[i] ? "Orden enviada..." : "Clic para cambiar", x + 125, 491); // Explica la accion o la espera de respuesta.
  } // Termina el dibujo de los dos canales.
  textAlign(LEFT, TOP); // Restaura la alineacion para las aclaraciones finales.
  fill(192, 204, 220); // Usa un tono secundario para las indicaciones.
  text("INPUT_PULLUP: pulsador/switch cerrado = BAJO; abierto = ALTO.", 30, 545); // Explica el nivel electrico de las entradas.
  text("Cada cambio fisico fija su LED: cerrar enciende; abrir apaga.", 30, 573); // Describe la regla del control fisico.
  text("El clic cambia el LED hasta el siguiente cambio de esa entrada.", 30, 601); // Explica como conviven mouse y entradas.
} // Termina draw.

// Processing la llama una vez por cada clic del mouse.
// No recibe parametros ni devuelve datos; cambia el selector o envia una orden de LED.
void mousePressed() { // Atiende una vez cada pulsacion del mouse.
  if (dentro(290, 150, 180, 42)) { // Detecta el boton de conexion.
    if (puerto == null) { // Decide si corresponde abrir el puerto.
      conectar(); // Inicia una nueva conexion.
    } else { // Termina el caso de puerto cerrado; atiende la desconexion.
      cerrarPuerto(); // Libera el puerto serie.
      mensaje = "Desconectado. Puedes elegir otro puerto o cargar el sketch."; // Confirma que el recurso quedo disponible.
    } // Termina la decision de conexion.
    return; // Evita tratar este clic como otra accion.
  } // Termina el tratamiento del boton de conexion.
  if (puerto == null) { // Permite cambiar el selector solo sin conexion activa.
    if (dentro(155, 150, 120, 42)) { // Detecta el boton de busqueda.
      actualizarPuertos(); // Renueva la lista tras conectar o desconectar dispositivos.
    } // Termina el tratamiento de busqueda.
    if (puertos.length > 0 && dentro(30, 150, 50, 42)) { // Detecta anterior y verifica que exista una lista.
      elegido = (elegido + puertos.length - 1) % puertos.length; // % obtiene el resto y permite volver al final si estaba en el primero.
    } // Termina el tratamiento de puerto anterior.
    if (puertos.length > 0 && dentro(90, 150, 50, 42)) { // Detecta siguiente sin acceder a una lista vacia.
      elegido = (elegido + 1) % puertos.length; // Avanza y vuelve al primero al superar el ultimo.
    } // Termina el tratamiento de puerto siguiente.
    return; // Impide enviar ordenes mientras el puerto este cerrado.
  } // Termina el tratamiento de seleccion de puerto.
  if (!datosValidos || millis() - ultimoDato > 500) { // Exige datos recientes antes de aceptar un clic de salida.
    return; // Evita operar durante el arranque o usando informacion desactualizada.
  } // Termina la comprobacion de datos recientes.
  for (int i = 0; i < 2; i++) { // Comprueba los dos casilleros de salida.
    if (dentro(260 + i * 310, 410, 250, 100) && !pendiente[i]) { // Detecta un clic valido sin otra orden pendiente del canal.
      try { // Protege el envio frente a una desconexion USB.
        puerto.write("S," + i + "," + (1 - leds[i]) + "\n"); // Pide a Arduino el valor opuesto al ultimo estado recibido.
        pendiente[i] = true; // Espera un informe posterior antes de otro clic en ese canal.
      } catch (Exception error) { // Termina el intento de envio; atiende un fallo de escritura.
        cerrarPuerto(); // Invalida la conexion y los estados anteriores.
        mensaje = "No se pudo enviar. Revisa el cable y vuelve a conectar."; // Indica como recuperarse.
        return; // Finaliza el evento sin intentar otros envios.
      } // Termina el intento de envio.
    } // Termina el tratamiento de un casillero de salida.
  } // Termina la busqueda de canal pulsado.
} // Termina mousePressed.
