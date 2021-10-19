#include <stdio.h>
#include <stdlib.h>

/*===========================================================================*/

#define MAX_LINE_LENGTH 1000

/*===========================================================================*/

void process_line(const char *line, int min, int max) {
  int addr, count;
  char ignored;
  if (sscanf(line, "al %x .%n%c", &addr, &count, &ignored) != 2) return;
  if (addr < min || addr > max) return;
  const char* symbol = line + count;
  // See https://fceux.com/web/help/NLFilesFormat.html
  fprintf(stdout, "$%04X#%s#\n", addr, symbol);
}

int main(int argc, char **argv) {
  if (argc < 3) {
    fprintf(stderr, "Usage: %s min max < in.labels.txt > out.nl\n", argv[0]);
    return EXIT_FAILURE;
  }
  const unsigned int min = strtoul(argv[1], NULL, 16);
  const unsigned int max = strtoul(argv[2], NULL, 16);
  char buffer[MAX_LINE_LENGTH + 1];
  int line_length = 0;
  while (1) {
    const int ch = fgetc(stdin);
    if (ch == EOF || ch == '\n') {
      buffer[line_length] = '\0';
      process_line(buffer, min, max);
      if (ch == EOF) break;
      line_length = 0;
    } else if (line_length >= MAX_LINE_LENGTH) {
      fprintf(stderr, "Overlong input line.\n");
      return EXIT_FAILURE;
    } else {
      buffer[line_length++] = ch;
    }
  }
  return EXIT_SUCCESS;
}

/*===========================================================================*/
