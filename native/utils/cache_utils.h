#ifndef __ASSET_SAVER_H
#define __ASSET_SAVER_H

#include <stddef.h>

#ifdef __EMSCRIPTEN__
#include <emscripten.h>
#else
#define EMSCRIPTEN_KEEPALIVE
#endif

#ifdef __cplusplus
extern "C" {
#endif

#if defined(MAKE_DLL) || defined(USE_DLL) || defined(_WINDOWS)
#  include <windows.h>
extern HANDLE dllhandle;        // set by swedllst::DllMain,
				// defined in sweph.c
				// used by GetModuleFilename in sweph.c
#endif

#ifdef MAKE_DLL
  #if defined (PASCAL) || defined(__stdcall)
   #if defined UNDECO_DLL
    #define CALL_CONV EMSCRIPTEN_KEEPALIVE __cdecl
   #else
    #define CALL_CONV EMSCRIPTEN_KEEPALIVE __stdcall
   #endif
  #else
    #define CALL_CONV EMSCRIPTEN_KEEPALIVE
  #endif
  /* To export symbols in the new DLL model of Win32, Microsoft
     recommends the following approach */
  #define EXP32  __declspec( dllexport )
#else
  #define CALL_CONV EMSCRIPTEN_KEEPALIVE
  #define EXP32
#endif

#define ext_def(x)	extern EXP32 x CALL_CONV
			/* ext_def(x) evaluates to x on Unix */

ext_def(int) file_exists(const char *path);

ext_def(int) save_to_cache(const char *path, const char* contents, size_t len, int forceOverwrite);

FILE * fOpen ( const char * filename, const char * mode );
int fClose ( FILE * stream );
int fSeek ( FILE * stream, long int offset, int origin );
long fTell ( FILE * stream);
size_t fRead (void * ptr, size_t size, size_t count, FILE * stream );
size_t fWrite ( const void * ptr, size_t size, size_t count, FILE * stream );
void fRewind(FILE* stream);
int printF ( const char * format, ... );

#ifdef __cplusplus
}
#endif

#endif // __ASSET_SAVER_H
