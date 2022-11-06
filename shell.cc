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
#include <limits.h>


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
    //Shell::prompt();
  }
  
  if (sig == SIGCHLD) {
    pid_t pid = waitpid(-1, NULL, WNOHANG);
    while (pid > 0) {
      if (isatty(0) == 1) {

      
        printf("[%d] exited\n", pid);
      }
      pid = waitpid(-1, NULL, WNOHANG);
    } 
  }  
}



int main(int argc, char **argv) {
  struct sigaction sa;
  sa.sa_handler = disp;
  sigemptyset(&sa.sa_mask);
  sa.sa_flags = SA_RESTART;
  

  //.shellrc 
  std::string input = ".shellrc";
  FILE * in = fopen(input.c_str(), "r");
  if (in) {
    //yypush_buffer_state(yy_create_buffer(in, YY_BUF_SIZE));
    //Shell::_srcCmd = true;
    //yyparse();
    //yypop_buffer_state();
    //fclose(in);
    //Shell::_srcCmd = false;
  }

  if(sigaction(SIGINT, &sa, NULL)){
    perror("sigaction");
    exit(2);
  }
  
  if (sigaction(SIGCHLD, &sa, NULL)) {
    perror("sigaction");
    exit(2);
  }
  
  std::string s = std::to_string(getpid());
  setenv("$", s.c_str(), 1);
  
  char buff[100];
  realpath(argv[0], buff);
  setenv("SHELL", buff, 1);



  Shell::prompt();
  yyparse();




}

Command Shell::_currentCommand;
