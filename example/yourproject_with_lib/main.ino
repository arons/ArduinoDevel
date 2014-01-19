#include <Arduino.h>
#include <MyLib.h>


int main(void) {
	init();


	setup();

	for (;;)
		loop();

	return 0;
}



MyClass myClass;


void setup() {
	Serial.begin(9600);
	myClass.setup();
}

void loop() {
	myClass.doSomething();
}

