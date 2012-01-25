#include <Arduino.h>

extern "C" void __cxa_pure_virtual() {
	while (1) ;
}


int main(void) {
	init();

	setup();

	for (;;)
		loop();

	return 0;
}

void setup() {
	Serial.begin(9600);
	Serial.println("Start");
}

void loop() {
	Serial.println("loop");
}

