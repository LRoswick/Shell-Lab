/*
 * CS252: Shell project
 *
 * Template file.
 * You will need to add more code here to execute the command table.
 *
 * NOTE: You are responsible for fixing any bugs this code may have!
 *
 * DO NOT PUT THIS PROJECT IN A PUBLIC REPOSITORY LIKE GIT. IF YOU WANT
 * TO MAKE IT PUBLICALLY AVAILABLE YOU NEED TO REMOVE ANY SKELETON CODE
 * AND REWRITE YOUR PROJECT SO IT IMPLEMENTS FUNCTIONALITY DIFFERENT THAN
 * WHAT IS SPECIFIED IN THE HANDOUT. WE OFTEN REUSE PART OF THE PROJECTS FROM
 * SEMESTER TO SEMESTER AND PUTTING YOUR CODE IN A PUBLIC REPOSITORY
 * MAY FACILITATE ACADEMIC DISHONESTY.
 */

#include <cstdio>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <wait.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include "shell.hh"
#include <signal.h>
#include <string.h>


int yyparse(void);

void Shell::prompt() {
  if (isatty(0) == 1) {
    printf("myshell>");
  }
  fflush(stdout);
}
extern "C" void disp(int sig) {
  
  	
  if (sig == SIGINT) {
    Shell::_currentCommand.clear();
    printf("\n");
    Shell::prompt();
  }


  if (sig == SIGCHLD) {
  }
}



int main() {
  Shell::prompt();
  yyparse();

  struct sigaction sa;
  sa.sa_handler = disp;
  sigemptyset(&sa.sa_mask);
  sa.sa_flags = SA_RESTART;

  if(sigaction(SIGINT, &sa, NULL)){
    perror("sigaction");
    exit(2);
  //} else if (sigaction(SIGCHILD, &sa, NULL)) {
    //perror("sigaction");
    //exit(2);
  }
  





}

Command Shell::_currentCommand;
