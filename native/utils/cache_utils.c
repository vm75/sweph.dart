#include "cache_utils.h"
#include <stdio.h>
#include <string.h>
#include  <stdlib.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct File {
  char name[32];
  const char* buffer;
  size_t size;
  size_t cursor;
  struct File* next;
} File;

File* files = NULL;

int file_exists(const char *path) {
  File* filePtr = files;
  while (filePtr != NULL) {
    if (strcmp(filePtr->name, path)) {
      return 1;
    }
    filePtr = filePtr->next;
  }
  return 0;
}

int save_to_cache(const char *path, const char* contents, size_t len, int forceOverwrite) {
  if (file_exists(path) && !forceOverwrite) {
    return 1;
  }

  File* file = (File*)malloc(sizeof(File));
  if (file == NULL) {
     return 0;
  }
  strcpy(file->name, path);
  file->buffer = contents;
  file->size = len;
  file->cursor = 0;
  file->next = files;
  files = file;

  return 1;
}

FILE * fOpen ( const char * filename, const char * mode ) {
  struct File* filePtr = files;
  while (filePtr != NULL) {
    if (!strcmp(filePtr->name, filename)) {
      filePtr->cursor = 0;
      return (FILE*)filePtr;
    }
    filePtr = filePtr->next;
  }

  return NULL;
}

int fClose ( FILE * stream ) {
  if (stream == NULL) {
    return -1;
  }

  File* file = (File*)stream;
  file->cursor = 0;
  return 0;
}

int fSeek ( FILE * stream, long int offset, int origin ) {
  File* file = (File*)stream;
  switch(origin) {
    case SEEK_SET:
      file->cursor = offset;
      break;
    case SEEK_CUR:
      file->cursor += offset;
      break;
    case SEEK_END:
      file->cursor = file->size - offset;
      break;
  }
  return 1;
}

long fTell ( FILE * stream) {
  File* file = (File*)stream;
  if (file == NULL) {
     return 0;
  }
  return (long)file->cursor;
}

size_t fRead (void * ptr, size_t size, size_t count, FILE * stream ) {
  if (stream == NULL) {
    return -1;
  }
  File* file = (File*)stream;
  char* buffer = (char*)ptr;
  size_t readCount = 0;
  while (file->size-file->cursor > size) {
    memcpy(buffer, file->buffer+file->cursor, size);
    buffer += size;
    file->cursor += size;
    readCount++;
  }

  return readCount;
}

size_t fWrite ( const void * ptr, size_t size, size_t count, FILE * stream ) {
  return 0;
}

void fRewind(FILE* stream) {
  File* file = (File*)stream;
  if (file == NULL) {
    return;
  }
  file->cursor = 0;
}

int printF ( const char * format, ... ) {
  return 0;
}

#ifdef __cplusplus
}
#endif
