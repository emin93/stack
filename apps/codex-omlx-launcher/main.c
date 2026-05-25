#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>

int main(void) {
  const char *home = getenv("HOME");
  char path[4096];
  char command[4096];
  if (home == NULL || home[0] == '\0') {
    return 127;
  }
  snprintf(path, sizeof(path), "/opt/homebrew/bin:/usr/local/bin:%s/.local/bin:/usr/bin:/bin:/usr/sbin:/sbin", home);
  snprintf(command, sizeof(command), "%s/Documents/Projects/stack/bin/.local/bin/codex-omlx", home);
  setenv("PATH", path, 1);
  execl("/bin/zsh", "zsh", "-lc", command, (char *)0);
  return 127;
}
