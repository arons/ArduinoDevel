This is a dump of the ArduinoISP of arduino development kit 022, the only that is currently working for me.

example: you can program another avr with avrdude:
{AVRDUDE} -v  -C {avrdude.dir}avrdude.conf -c avrisp -p atmega328p -b 19200 -P {dude.port} -F -U flash:w:optiboot_atmega328.hex