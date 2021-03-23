# OFDM-Matlab

La Universidad de La Salle os ha contratado para simular parte del transceptor para su proyecto Antártico. Concretamente nos ocuparemos de la modulación y demodulación en banda base de una modulación de banda ancha OFDM basada en subportadoras 16QAM. Dado que el canal puede variar en la Antártida deberemos implementar un código genérico de tal forma que podamos configurar diferentes parámetros según el canal y los requisitos del usuario. Las características propias de la OFDM (número de subportadoras, ancho de banda de subportadoras, tiempo de prefijo cíclico, tiempo de símbolo OFDM, etc) deberán generarse automáticamente según los requisitos.
Los requisitos a tener en cuenta son los siguientes:
* El número de bits que pueden ser modulados es variable según la aplicación (entre 1 bit y 500.000 bits), por lo que se deberá realizar zero padding.
* Los parámetros de la OFDM se deben generar según se configure el canal multicamino.
* El ancho de banda del canal de transmisión y recepción puede variar (Puede ser 3 KHz o 6 KHz).
* El ruido gaussiano y el multicamino deben poder desactivarse en cualquier simulación por separado.
* El sistema en banda base debe tener una frecuencia de muestreo de 100 KSPS.
* El código no puede presentar ningún error al ejecutarse.
Dado que nosotros generaremos una simulación en Matlab nos interesara poder caracterizar la robustez de la señal OFDM a través de una gráfica BER-EbNo que varíe entre 0 dB y 30 dB.
