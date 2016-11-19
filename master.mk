#
#  Author: Renzo Dani
#
#  This library is free software; you can redistribute it and/or
#  modify it under the terms of the GNU GENERAL PUBLIC LICENSE
#  License as published by the Free Software Foundation; either
#  version 2 of the License, or (at your option) any later version.
#
#  This library is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  
#  See the GNU General Public License for more details.
#
#  some few parts are inspired from edam's Arduino makefile (http://ed.am/dev/make/arduino-mk)
#
#
# MANDATORY:
#    ARDUINODIR
#
# OPTIONAL:
#    BOARD
#    BOARD_CPU
#    DIR_WORK
#    LIBRARYPATH
#
#    BOARD_UPLOAD_PROTOCOL
#    SERIALDEV
#
#    SERIALMON
#    INOFILE
#    ARDUINO_SDK_VERSION
#  
#    CPPFLAGS
#    LINKFLAGS
#    AVRDUDEFLAGS
#

ifndef ARDUINODIR
$(error ARDUINODIR is not set )
endif

ifndef BOARD
BOARD := uno
$(info BOARD is not set. Use default value 'uno'. Use 'make boards' to have the list of supported board )
endif


ifdef SystemRoot
OS := windows
else
ifeq ($(shell uname), Linux)
	OS := linux
endif
endif


#if not defined, define main file: search for .ino file
ifndef INOFILE
INOFILE := $(wildcard *.ino)
ifneq "$(words $(INOFILE))" "1"
$(error No .ino file found OR multiple ones!)
endif
endif



DIR_WORK ?= target
DIR_LIB := $(DIR_WORK)/lib


TARGET := $(basename $(INOFILE))
SOURCES := $(INOFILE) \
	       $(wildcard *.c *.cc *.cpp *.C)
#redirect build to work dir	       
OBJECTS := $(addprefix $(DIR_WORK)/, $(addsuffix .o, $(basename $(SOURCES))))


# default path to find libraries
LIBRARYPATH ?= libraries libs lib $(ARDUINODIR)/libraries $(ARDUINODIR)/hardware/arduino/avr/libraries
# automatically determine included libraries
LIBRARIES := $(filter $(notdir $(wildcard $(addsuffix /*, $(LIBRARYPATH)))), \
	$(shell sed -ne "s/^ *\# *include *[<\"]\(.*\)\.h[>\"]/\1/p" $(SOURCES)))
LIBRARYDIRS := $(foreach lib, $(LIBRARIES), \
	$(firstword $(wildcard $(addsuffix /$(lib), $(LIBRARYPATH)))))
	
LIBRARYDIRS_util	= $(addsuffix /utility, $(LIBRARYDIRS))
LIBRARYDIRS_src  	= $(addsuffix /src, $(LIBRARYDIRS))
LIBRARYDIRS_src_avr = $(addsuffix /src/avr, $(LIBRARYDIRS))	


ARDUINO_SDK_VERSION ?= 105
ARDUINOCOREDIR := $(ARDUINODIR)/hardware/arduino/avr/cores/arduino
ARDUINOLIB := $(DIR_LIB)/arduino.a
ARDUINOLIBOBJS := $(foreach dir, $(ARDUINOCOREDIR) $(LIBRARYDIRS) $(LIBRARYDIRS_util) $(LIBRARYDIRS_src) $(LIBRARYDIRS_src_avr), \
	$(patsubst %, $(DIR_LIB)/%.o, $(wildcard $(addprefix $(dir)/, *.c *.cpp *.S))))


#********************************************************************************************************
# software source
AVRTOOLSPATH += $(ARDUINODIR)/hardware/tools $(ARDUINODIR)/hardware/tools/avr/bin $(ARDUINODIR)/hardware/tools/avr/etc /usr/bin
findfile     = $(firstword $(wildcard $(addsuffix /$(1), $(AVRTOOLSPATH))))
CC 			:= $(call findfile,avr-gcc)
CXX 		:= $(call findfile,avr-g++)
LD 			:= $(call findfile,avr-ld)
AR 			:= $(call findfile,avr-ar)
OBJCOPY 	:= $(call findfile,avr-objcopy)
AVRDUDE 	:= $(call findfile,avrdude)
AVRDUDECONF := $(call findfile,avrdude.conf)
AVRSIZE 	:= $(call findfile,avr-size)
#default serial monitor
SERIALMON 	?= picocom

#board config
BOARDSFILE := $(ARDUINODIR)/hardware/arduino/avr/boards.txt
readboardsparam = $(shell sed -ne "s/$(BOARD).$(1)=\(.*\)/\1/p" $(BOARDSFILE))
BOARD_BUILD_MCU 		:= $(call readboardsparam,build.mcu)
BOARD_BUILD_FCPU 		:= $(call readboardsparam,build.f_cpu)
BOARD_USB_VID 			:= $(call readboardsparam,build.vid)
BOARD_USB_PID 			:= $(call readboardsparam,build.pid)
BOARD_BUILD_VARIANT 	:= $(call readboardsparam,build.variant)
BOARD_UPLOAD_SPEED		:= $(call readboardsparam,upload.speed)
ifndef BOARD_UPLOAD_PROTOCOL
BOARD_UPLOAD_PROTOCOL	:= $(call readboardsparam,upload.protocol)
endif

readboardsparamManu = $(shell sed -ne "s/$(BOARD).menu.cpu.$(BOARD_CPU).$(1)=\(.*\)/\1/p" $(BOARDSFILE))
ifndef BOARD_BUILD_MCU
BOARD_BUILD_MCU	:= $(call readboardsparamManu,build.mcu)
endif
ifndef BOARD_BUILD_FCPU
BOARD_BUILD_FCPU	:= $(call readboardsparamManu,build.f_cpu)
endif
ifndef BOARD_USB_VID
BOARD_USB_VID	:= $(call readboardsparamManu,build.vid)
endif
ifndef BOARD_USB_PID
BOARD_USB_PID	:= $(call readboardsparamManu,build.pid)
endif
ifndef BOARD_BUILD_VARIANT
BOARD_BUILD_VARIANT	:= $(call readboardsparamManu,build.variant)
endif
ifndef BOARD_UPLOAD_SPEED
BOARD_UPLOAD_SPEED	:= $(call readboardsparamManu,upload.speed)
endif
ifndef BOARD_UPLOAD_PROTOCOL
BOARD_UPLOAD_PROTOCOL	:= $(call readboardsparamManu,upload.protocol)
endif


# cflags
CPPFLAGS += -Os -Wall -ffunction-sections -fdata-sections -fno-exceptions
CPPFLAGS += -funsigned-char -funsigned-bitfields -fpack-struct -fshort-enums
#board flags
#note: currently avr support only
CPPFLAGS += -DARDUINO_ARCH_AVR=true
CPPFLAGS += -mmcu=$(BOARD_BUILD_MCU) 
CPPFLAGS += -DF_CPU=$(BOARD_BUILD_FCPU)
CPPFLAGS += -DUSB_VID=$(BOARD_USB_VID)
CPPFLAGS += -DUSB_PID=$(BOARD_USB_PID)
#version 
CPPFLAGS += -DARDUINO="$(ARDUINO_SDK_VERSION)"
#includes
CPPFLAGS += -I. -I $(ARDUINOCOREDIR)
CPPFLAGS += -I $(ARDUINODIR)/hardware/arduino/avr/variants/$(BOARD_BUILD_VARIANT)/
CPPFLAGS += $(addprefix -I , $(LIBRARYDIRS) $(LIBRARYDIRS_util) $(LIBRARYDIRS_src) $(LIBRARYDIRS_src_avr))


CPPDEPFLAGS = -MMD -MP -MF $(DIR_WORK)/.dep/$<.dep


#main flags
CPPINOFLAGS := -x c++ -include $(ARDUINOCOREDIR)/Arduino.h


LINKFLAGS += -Os -Wl,--gc-sections -mmcu=$(BOARD_BUILD_MCU)


AVRDUDEFLAGS += $(addprefix -C , $(AVRDUDECONF)) -DV -v
AVRDUDEFLAGS += -p $(BOARD_BUILD_MCU)
ifdef SERIALDEV
AVRDUDEFLAGS += -P $(SERIALDEV)
endif
AVRDUDEFLAGS += -c $(BOARD_UPLOAD_PROTOCOL) -b $(BOARD_UPLOAD_SPEED)


#********************************************************************************************************
# RULES
#********************************************************************************************************
.PHONY:	help config boards board_info monitor upload dump clean target
# default rule
.DEFAULT_GOAL := target
#********************************************************************************************************	

help:
	@echo "Targets:"
	@echo ""
	@echo "help         : prints this help"
	@echo "config       : prints current config"
	@echo "boards       : prints available boards"
	@echo "board_info   : prints current board info"
	@echo "monitor      : start your serial monitor program (default: picocom) "
	@echo "upload       : upload your code to board"
	@echo "dump         : dump code from board"
	@echo "clean        : clean project"
	@echo "target       : compile project and generate hex file"
	

config:	
	@echo "OS: $(OS)"
	@echo "BOARD: $(BOARD)"
	@echo "INOFILE: $(INOFILE)"
	@echo "TARGET: $(TARGET)"
	@echo "SOURCES: $(SOURCES)"
	@echo "OBJECTS: $(OBJECTS)"
	@echo "CPPFLAGS: $(CPPFLAGS)"
	@echo "CPPDEPFLAGS: $(CPPDEPFLAGS)"
	@echo "CPPINOFLAGS: $(CPPINOFLAGS)"
	@echo "LINKFLAGS: $(LINKFLAGS)"
	@echo ""
	@echo "LIBRARIES: $(LIBRARIES)"
	@echo "LIBRARYDIRS: $(LIBRARYDIRS)"
	@echo ""
	@echo "AVRDUDE: $(AVRDUDE)"
	@echo "AVRDUDECONF: $(AVRDUDECONF)"
	@echo ""
	@echo "BOARDSFILE: $(BOARDSFILE)"
	@echo "BOARD_BUILD_MCU: $(BOARD_BUILD_MCU)"
	@echo "BOARD_BUILD_FCPU: $(BOARD_BUILD_FCPU)"
	@echo "BOARD_USB_VID: $(BOARD_USB_VID)"
	@echo "BOARD_USB_PID: $(BOARD_USB_PID)"
	@echo "BOARD_BUILD_VARIANT: $(BOARD_BUILD_VARIANT)"
	@echo "BOARD_UPLOAD_SPEED: $(BOARD_UPLOAD_SPEED)"
	
	

#********************************************************************************************************	

boards:
	@echo "Available values for BOARD:"
	@echo ""
	@echo "  board name = Description"
	@echo ""
	@awk 'match($$0, /([^.]+).name=([^.]+)/,a) {printf "%12s = %s\n",a[1],a[2] }' < $(BOARDSFILE)

board_info:
	@cat $(BOARDSFILE) | grep $(BOARD).

monitor:
	$(SERIALMON) $(SERIALDEV)	

#********************************************************************************************************	
upload:
	$(AVRDUDE) $(AVRDUDEFLAGS) -U flash:w:$(DIR_WORK)/$(TARGET).hex:i
	
dump:
	$(AVRDUDE) $(AVRDUDEFLAGS) -U flash:r:$(DIR_WORK)/dump.hex:r	

erase:
	$(AVRDUDE) $(AVRDUDEFLAGS) -e 	
	
#********************************************************************************************************	
clean:
	rm -rf $(DIR_WORK)		
	
	
target: $(DIR_WORK)/$(TARGET).hex

#hex
$(DIR_WORK)/$(TARGET).hex: $(DIR_WORK)/$(TARGET).elf
	$(OBJCOPY) -O ihex -R .eeprom $< $@
	
#elf	
$(DIR_WORK)/$(TARGET).elf: $(ARDUINOLIB) $(OBJECTS)
	$(CC) $(LINKFLAGS) $(OBJECTS) $(ARDUINOLIB) -lm -o $@
	
	
#build ino
$(DIR_WORK)/%.o: %.ino
	mkdir -p $(DIR_WORK)/.dep/$(dir $<)
	$(COMPILE.cpp) $(CPPDEPFLAGS) -o $@ $(CPPINOFLAGS) $<

		
#build sources	
$(DIR_WORK)/%.o: %.c
	mkdir -p $(DIR_WORK)/.dep/$(dir $<)
	$(COMPILE.c) $(CPPDEPFLAGS) -o $@ $<

$(DIR_WORK)/%.o: %.cpp
	mkdir -p $(DIR_WORK)/.dep/$(dir $<)
	$(COMPILE.cpp) $(CPPDEPFLAGS) -o $@ $<

$(DIR_WORK)/%.o: %.cc
	mkdir -p $(DIR_WORK)/.dep/$(dir $<)
	$(COMPILE.cpp) $(CPPDEPFLAGS) -o $@ $<

$(DIR_WORK)/%.o: %.C
	mkdir -p $(DIR_WORK)/.dep/$(dir $<)
	$(COMPILE.cpp) $(CPPDEPFLAGS) -o $@ $<

$(DIR_WORK)/%.o: %.S
	mkdir -p $(DIR_WORK)/.dep/$(dir $<)
	$(COMPILE.cpp) $(CPPDEPFLAGS) -o $@ $<
	
#build libraries
$(ARDUINOLIB): $(ARDUINOLIBOBJS)
	$(AR) rcs $@ $?

$(DIR_LIB)/%.c.o: %.c
	mkdir -p $(dir $@)
	$(COMPILE.c) -o $@ $<

$(DIR_LIB)/%.cpp.o: %.cpp
	mkdir -p $(dir $@)
	$(COMPILE.cpp) -o $@ $<

$(DIR_LIB)/%.cc.o: %.cc
	mkdir -p $(dir $@)
	$(COMPILE.cpp) -o $@ $<

$(DIR_LIB)/%.C.o: %.C
	mkdir -p $(dir $@)
	$(COMPILE.cpp) -o $@ $<	

$(DIR_LIB)/%.S.o: %.S
	mkdir -p $(dir $@)
	$(COMPILE.cpp) -o $@ $<		
