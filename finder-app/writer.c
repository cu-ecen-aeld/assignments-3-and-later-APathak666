#include <stdio.h>
#include <syslog.h>
#include <stdlib.h>

int main(int argc, char* argv[])
{
    openlog(NULL, 0, LOG_USER);

    if (argc != 3)
    {
        syslog(LOG_ERR, "Invalid number of arguments: %d passed, 3 required.\n", argc);
        exit(1);
    }

    FILE* fp = fopen(argv[1], "w");

    if (fp == NULL)
    {
        syslog(LOG_ERR, "Error opening file.\n");
        exit(1);
    }

    syslog(LOG_DEBUG, "Writing %s to %s", argv[2], argv[1]);
    fprintf(fp, "%s", argv[2]);

    fclose(fp);
    closelog();
}
