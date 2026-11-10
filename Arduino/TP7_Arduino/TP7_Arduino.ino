// TP7 - Informatica II - Francesco Boito Diaz - Legajo 53136.
// Montaje: Nano clasico con ATmega328P; pulsador en D2 y switch en D3.
// Cada cambio estable fija el LED: entrada cerrada = encendido; abierta = apagado.
// El mouse puede cambiar ese LED hasta el siguiente cambio fisico de su entrada.
// byte es un entero de 8 bits sin signo; alcanza para contar canales y guardar pines.
const byte CANTIDAD = 2; // Define los dos canales independientes.
// Un arreglo guarda varios datos del mismo tipo; [0] es el primer canal y [1] el segundo.
const byte PIN_ENTRADA[CANTIDAD] = {2, 3}; // Asocia E1 al pulsador D2 y E2 al switch D3.
const byte PIN_LED[CANTIDAD] = {8, 9}; // Asocia L1 con D8 y L2 con D9.
const unsigned long REBOTE_MS = 30; // Exige 30 milisegundos sin cambios para aceptar una entrada.
const unsigned long ENVIO_MS = 100; // Envia el estado a la PC cada 100 milisegundos.
byte lecturaAnterior[CANTIDAD]; // Guarda la ultima lectura instantanea de cada entrada.
byte entradaEstable[CANTIDAD]; // Guarda el nivel electrico confirmado: HIGH o LOW.
byte estadoLed[CANTIDAD] = {LOW, LOW}; // Guarda el nivel que Arduino ordeno a cada salida.
unsigned long ultimoCambio[CANTIDAD] = {0, 0}; // Guarda cuando comenzo cada posible cambio fisico.
unsigned long ultimoEnvio = 0; // Guarda cuando se transmitio el ultimo informe.
char comando[16]; // Reserva un arreglo fijo para recibir una linea sin usar String dinamico.
byte usados = 0; // Cuenta los caracteres recibidos de la linea actual.
// bool solo admite true o false; aca indica si se descarta una linea larga.
bool descartando = false; // Indica que una linea demasiado larga debe ignorarse hasta el salto.

// Informa los dos niveles estables y los dos estados de LED cuando se la llama.
// No recibe parametros ni devuelve datos: void indica eso. Actualiza ultimoEnvio.
void enviarEstado() { // Empieza el envio del estado de Arduino.
  Serial.print("E,"); // Identifica el mensaje de estado mediante la letra E.
  Serial.print(entradaEstable[0]); // Escribe E1 como 1 para HIGH o 0 para LOW.
  Serial.print(','); // Separa el primer campo del segundo.
  Serial.print(entradaEstable[1]); // Escribe el nivel electrico estable de E2.
  Serial.print(','); // Separa las entradas de las salidas.
  Serial.print(estadoLed[0]); // Escribe el nivel aplicado a L1.
  Serial.print(','); // Separa las dos salidas.
  Serial.println(estadoLed[1]); // Escribe L2 y termina el mensaje con un salto de linea.
  ultimoEnvio = millis(); // Registra el momento del informe para programar el siguiente.
} // Termina enviarEstado.

// Se ejecuta cuando llega una linea completa desde Processing.
// No recibe parametros ni devuelve datos; puede cambiar estadoLed y los pines de salida.
void aplicarComando() { // Interpreta la linea recibida.
  // if ejecuta su bloque solo si la condicion es verdadera; == compara igualdad y && exige ambas condiciones.
  if (usados == 1 && comando[0] == 'Q') { // Reconoce Q como pedido de estado inmediato.
    enviarEstado(); // Responde con el estado sin modificar salidas.
    return; // Sale de la funcion sin seguir con las pruebas de orden de salida.
  } // Termina el caso de consulta.
  // != significa distinto y || significa que alcanza con una condicion verdadera.
  if (usados != 5 || comando[0] != 'S' || comando[1] != ',' || comando[3] != ',') { // Exige exactamente S,canal,valor.
    return; // Ignora mensajes mal formados para no cambiar LEDs por error.
  } // Termina la validacion de formato.
  if ((comando[2] != '0' && comando[2] != '1') || (comando[4] != '0' && comando[4] != '1')) { // Solo acepta canal y valor binarios.
    return; // Descarta canales inexistentes y valores no permitidos.
  } // Termina la validacion de valores.
  byte canal = comando[2] - '0'; // Resta el codigo de '0' para obtener el indice numerico 0 o 1.
  estadoLed[canal] = comando[4] - '0'; // Convierte el caracter de valor en LOW o HIGH.
  digitalWrite(PIN_LED[canal], estadoLed[canal]); // Aplica la orden al pin del LED correspondiente.
  enviarEstado(); // Confirma la orden con el estado actualizado de ambos canales.
} // Termina aplicarComando.

// Se llama en cada vuelta de loop para leer las ordenes que ya llegaron.
// No recibe parametros ni devuelve datos; modifica comando, usados y descartando.
void recibirComandos() { // Lee el puerto sin esperar una linea completa.
  byte presupuesto = 32; // Limita el trabajo por vuelta para seguir leyendo las entradas.
  // while repite mientras haya bytes y quede presupuesto; > compara si un valor es mayor que otro.
  while (Serial.available() > 0 && presupuesto > 0) { // Procesa solo los bytes disponibles y hasta el limite.
    presupuesto--; // -- resta uno al presupuesto luego de procesar un byte.
    char recibido = (char) Serial.read(); // Extrae el siguiente caracter del puerto USB serie.
    if (recibido == '\r') { // Reconoce el retorno de carro usado por algunos terminales.
      continue; // Lo ignora para aceptar tanto LF como CRLF.
    } // Termina el caso de retorno de carro.
    if (recibido == '\n') { // Detecta el final de una orden.
      if (!descartando) { // ! invierte el valor: solo interpreta si no se desbordo el arreglo.
        aplicarComando(); // Valida y ejecuta la orden completa.
      } // Termina el tratamiento de una linea valida en longitud.
      usados = 0; // Prepara el arreglo para la siguiente linea.
      descartando = false; // Permite recibir una nueva linea despues de cualquier error.
    } else if (!descartando) { // Termina el caso de LF; acumula otros caracteres si la linea sigue valida.
      if (usados < sizeof(comando)) { // < compara el espacio usado con la capacidad del arreglo.
        comando[usados++] = recibido; // Guarda el caracter; ++ avanza el indice libre en uno.
      } else { // Termina el caso con espacio; atiende una linea demasiado larga.
        descartando = true; // Ignora el resto de esa linea para evitar ordenes parciales.
      } // Termina la comprobacion de espacio.
    } // Termina la clasificacion del caracter recibido.
  } // Termina la lectura de esta vuelta.
} // Termina recibirComandos.

// Arduino la ejecuta una vez al encender o reiniciar.
// No recibe parametros ni devuelve datos; configura pines, serie y estados iniciales.
void setup() { // Inicia la configuracion de Arduino.
  Serial.begin(9600); // Abre la comunicacion a la misma velocidad que Processing.
  // for inicia i en 0, repite mientras i sea menor que CANTIDAD y suma uno al terminar cada pasada.
  for (byte i = 0; i < CANTIDAD; i++) { // Configura los dos canales.
    pinMode(PIN_ENTRADA[i], INPUT_PULLUP); // Conecta la pull-up: abierto HIGH; pulsado o cerrado LOW.
    pinMode(PIN_LED[i], OUTPUT); // Configura el pin del LED como salida digital.
    lecturaAnterior[i] = digitalRead(PIN_ENTRADA[i]); // Lee el estado fisico inicial de esa entrada.
    entradaEstable[i] = lecturaAnterior[i]; // Usa esa lectura como estado inicial estable.
    // El operador ?: elige HIGH si la condicion es verdadera y LOW si es falsa.
    estadoLed[i] = (entradaEstable[i] == LOW) ? HIGH : LOW; // Enciende el LED si la entrada arranca cerrada.
    digitalWrite(PIN_LED[i], estadoLed[i]); // Aplica el estado inicial al LED fisico.
    ultimoCambio[i] = millis(); // Inicializa la referencia temporal de antirrebote.
  } // Termina la configuracion de los canales.
  enviarEstado(); // Publica el primer informe de entradas y salidas.
} // Termina setup.

// Arduino la repite continuamente despues de setup.
// No recibe parametros ni devuelve datos; atiende la PC y actualiza entradas y LEDs.
void loop() { // Repite la atencion de las entradas y la PC.
  recibirComandos(); // Atiende primero las ordenes del mouse que hayan llegado.
  unsigned long ahora = millis(); // Toma una referencia de tiempo comun para esta vuelta.
  bool cambio = false; // Recuerda si hubo algun cambio fisico confirmado en esta vuelta.
  for (byte i = 0; i < CANTIDAD; i++) { // Examina pulsador y switch por separado.
    byte lectura = digitalRead(PIN_ENTRADA[i]); // Lee el nivel electrico instantaneo del pin.
    if (lectura != lecturaAnterior[i]) { // Detecta el comienzo de un cambio o rebote.
      lecturaAnterior[i] = lectura; // Guarda la lectura mas reciente.
      ultimoCambio[i] = ahora; // Reinicia los 30 milisegundos de estabilizacion.
    } // Termina la deteccion de un posible cambio.
    if (lectura != entradaEstable[i] && ahora - ultimoCambio[i] >= REBOTE_MS) { // Acepta solo cambios que se mantuvieron estables.
      entradaEstable[i] = lectura; // Actualiza el nivel confirmado de la entrada.
      estadoLed[i] = (lectura == LOW) ? HIGH : LOW; // Fija el LED: pulsado/cerrado enciende; suelto/abierto apaga.
      digitalWrite(PIN_LED[i], estadoLed[i]); // Actualiza fisicamente solo la salida de este canal.
      cambio = true; // Solicita informar inmediatamente este cambio a Processing.
    } // Termina el tratamiento de un cambio estable.
  } // Termina el recorrido de entradas.
  if (cambio || ahora - ultimoEnvio >= ENVIO_MS) { // Informa por cambios o al cumplirse el periodo de actualizacion.
    enviarEstado(); // Transmite ambos niveles de entrada y ambos estados de salida.
  } // Termina la decision de envio.
} // Termina loop.
