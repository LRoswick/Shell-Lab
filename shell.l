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

/*
 *
 * CS-252 
 * shell.l: lexical analyzer for shell
 * You have to extend it.
 *
 */

%{

#include <cstring>
#include "y.tab.hh"
#include <sys/wait.h>

#include <string.h>
#include "y.tab.h"

extern “C” char * read_line();

int mygetc(FILE * f) {
  static char *p;
  char ch;

     if (!isatty(0)) {
  // stdin is not a tty. Call real getc
    return getc(f);
  }

  // stdin is a tty. Call our read_line.
  if (p==NULL || *p == 0) {
    char * s = read_line();
    p = s;
  }

  ch = *p;
  p++;

  return ch;
}

#undef getc
#define getc(f) mygetc(f)




static  void yyunput (int c,char *buf_ptr  );

void myunputc(int c) {
  unput(c);
}

%}

%option noyywrap

%%

\n {
  return NEWLINE;
}

[ \t] {
  /* Discard spaces and tabs */
}

">" {
  return GREAT;
}

"<" {
  return LESS;
}

"2>" {
  return TWOGREAT;
}

">&" {
  return GREATAND;
}

">>" {
  return GREATGREAT;
}

">>&" {
  return GREATGREATAND;
}

"&" {
  return AND;
}

"|" {
  return PIPE;
}

~[^ \n\t]* {
  std::string str = std::string(yytext);
  if (str.size() == 1) {
    //home directory
    printf("%s", getenv("HOME"));
  } else {
    str = str.substr(1, str.size()-1);
    printf("%s", getenv(str.c_str()));
  } 
}

\"[^\n\"]*\" {
  std::string str = std::string(yytext);
  str = str.substr(1, str.size()-2);
  yylval.cpp_string = new std::string(str);
  return WORD;
}

[^ \\\t\n]*(\\[^nt])((\\[^nt])|[^ \\\t\n])* {
  std::string str = std::string(yytext);
  std::size_t index = str.find('\\');
  while(index!=-1) {
    str = str.substr(0,index) + str.substr(index+1,std::string::npos);
    index = str.find('\\', index+1);
  }
  yylval.cpp_string = new std::string(str);
  return WORD;
}




\`[^\n\`]*\`|\$\([^\n]*\) {
  std::string str = std::string(yytext);
  if (str.at(0) == '$') {
    str = str.substr(2, str.size()-3);
  } else {
    str = str.substr(1, str.size()-2);
  }
  str = str + "\n" + "exit\n";

  int pin[2], pout[2];
  pipe(pin); pipe(pout);

  
  int tempin, tempout;
  tempin = dup(0);
  tempout = dup(1);


  dup2(pin[0], 0);
  dup2(pout[1], 1);
  close(pin[0]);
  close(pout[1]);


  //write to pin[1]
  //fprintf(stderr, "%s", str.c_str());
  write(pin[1], str.c_str(), str.size());
  close(pin[1]);  

  int ret = fork();
  if (ret == 0) {
    char ** command = new char*[2]; 
    command[0] = (char *)"/proc/self/exe";
    command[1] = NULL;

    execvp(command[0], command);

    perror("execvp");
    exit(1);
  }
  waitpid(ret, NULL, 0);

  dup2(tempin, 0);
  dup2(tempout, 1);
  close(tempin);
  close(tempout);;
 
  char buffer[1025];
  //read from pout[0]
  //printf("sus");
  int string = read(pout[0], buffer, 1024);  
  for (int i = string -12; i >= 0; i--) {
    //printf("%d", buffer[i]);
    if (buffer[i] == '\n') {
      myunputc('\t');
    } else {
      myunputc(buffer[i]);
    }    
  }
  
  
  close(pout[0]);
  

  //insert back into lex


}


[^ \t\n][^ \t\n]*  {
  /* Assume that file names have only alpha chars */
  yylval.cpp_string = new std::string(yytext);
  return WORD;
}
