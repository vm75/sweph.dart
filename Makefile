default: all

all: wasm

# Common
ifdef  DEBUG
    COMPILER_OPTIONS=-g3 --profiling-funcs -s ASSERTIONS=1 -fsanitize=address
    LINKER_OPTIONS=-Wl,--no-entry
else
    COMPILER_OPTIONS=-Os -fno-exceptions -fno-rtti -fno-stack-protector -ffunction-sections -fdata-sections -fno-math-errno
    LINKER_OPTIONS=-Wl,--gc-sections,--no-entry
endif

ifeq ($(OS), Windows_NT)
    NATIVE_EXEC=out/sweph_native.exe
else
	NATIVE_EXEC=out/sweph_native
endif
SOURCES_CC = $(wildcard native/sweph/src/*.c) $(wildcard native/sweph/src/*.h) $(wildcard native/utils/*.c) $(wildcard native/utils/*.h)

# Native
native: $(NATIVE_EXEC)

$(NATIVE_EXEC): $(SOURCES_CC) $(HEADERS_CC) native/tests/test.cpp
	-mkdir out
	clang++ ${COMPILER_OPTIONS} -I native/src $(SOURCES_CC) native/tests/test.cpp -o $@ && \
		llvm-strip -s -R .comment -R .gnu.version --strip-unneeded $@

flutter: assets/sweph.wasm
	flutter build -d 1

testall: test_native test_flutter

test_native: $(NATIVE_EXEC)
	$(NATIVE_EXEC)

test_flutter:

publishall: publish_flutter

publish_flutter:

# Wasm
RUNTIME_EXPORTS="EXPORTED_RUNTIME_METHODS=[\"cwrap\", \"ccall\"]"
COMPILED_EXPORTS="EXPORTED_FUNCTIONS=[\"_malloc\", \"_free\"]"

NODEJS_TARGET=wasm/dist/sweph.wasm

ifneq ($(OS), Windows_NT)
	USER_SPEC=-u $(shell id -u):$(shell id -g)
else
	USER_SPEC=
endif

wasm: assets/sweph.wasm

assets/sweph.wasm: $(SOURCES_CC)
	docker run --rm -v "$(CURDIR)/native/sweph/src:/src" -v "$(CURDIR)/native/utils:/src/utils"  -v "$(CURDIR)/assets:/dist" $(USER_SPEC) \
		emscripten/emsdk \
			emcc -o /dist/sweph.wasm $(COMPILER_OPTIONS) $(LINKER_OPTIONS) \
				swecl.c swedate.c swehel.c swehouse.c swejpl.c swemmoon.c swemplan.c sweph.c swephlib.c utils/cache_utils.c \
				-DNDEBUG \
				-D fopen=fOpen -D fclose=fClose -D fread=fRead -D fwrite=fWrite -D rewind=fRewind -D fseek=fSeek -D ftell=fTell -D printf=printF \
				-s 'EXPORT_NAME="sweph"' \
				-s 'ENVIRONMENT="web"' \
				-s $(COMPILED_EXPORTS)
