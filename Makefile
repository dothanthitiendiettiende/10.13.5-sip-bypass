OUTPUT="./bin"
DEVELOPER_LIB="$(OUTPUT)/Toolchains/XcodeDefault.xctoolchain/usr/lib"

all: dylib loader kanye

prepare:
	mkdir -p $(OUTPUT)
	mkdir -p $(DEVELOPER_LIB)

dylib: prepare
	clang \
		-dynamiclib osinj/mach_inject.c injector.c \
		-o $(DEVELOPER_LIB)/libswiftDemangle.dylib
	clang \
		-dynamiclib osinj/bootstrap.c \
		-o $(OUTPUT)/bootstrap.dylib
	clang -framework Foundation \
		-dynamiclib sip.c \
		-o $(OUTPUT)/sip.dylib

loader: prepare
	clang -framework Foundation fuck.m -o $(OUTPUT)/test

kanye: prepare
	swiftc -static-stdlib -o $(OUTPUT)/taytay taylor.swift

run: all
	sudo $(OUTPUT)/test

clean:
	rm -rf $(OUTPUT)/*
