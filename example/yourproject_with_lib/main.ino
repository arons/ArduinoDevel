#include <Arduino.h>
#include <MyLib.h>

MyClass myClass;

void setup() {
	Serial.begin(9600);
	myClass.setup();
}

void loop() {
	myClass.doSomething();
}

