#include "cache_utils.h"
#include <stdio.h>
#include <unistd.h>

#ifdef __cplusplus
extern "C" {
#endif

int save_to_cache(const char *path, const char* contents, size_t len, int forceOverwrite) {
  if (access(path, F_OK) == 0 && !forceOverwrite) {
    return 1;
  }

  FILE* fp = fopen(path, "wb");

  if (fp == NULL) {
    return 0;
  }

  fwrite(contents, len, 1, fp);

  fclose(fp);
  return 1;
}

#ifdef __cplusplus
}
#endif
