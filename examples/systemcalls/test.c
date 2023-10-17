#include <stdlib.h>
#include <unistd.h>
#include <sys/wait.h>
#include <stdio.h>
#include <stdbool.h>
#include <stdarg.h>

bool do_exec(int count, ...)
{
    va_list args;
    va_start(args, count);
    char * command[count+1];
    int i;
    for(i=0; i<count; i++)
    {
        command[i] = va_arg(args, char *);
    }
    command[count] = NULL;
    va_end(args);

    int pid = fork();

    if (pid == -1)
        return false;

    if (pid == 0)
    {
        if (execv(command[0], &command[1]) == -1)
            return false;

        return true;
    }

    else
    {
        wait(NULL);
    }
/*
 * TODO:
 *   Execute a system command by calling fork, execv(),
 *   and wait instead of system (see LSP page 161).
 *   Use the command[0] as the full path to the command to execute
 *   (first argument to execv), and use the remaining arguments
 *   as second argument to the execv() command.
 *
*/


    return true;
}

int main()
{
    do_exec(2, "echo", "ur mom gae", NULL);
}

