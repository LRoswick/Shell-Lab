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

\"[^\n\"]*\" {
  std::string str = std::string(yytext);
  str = str.substr(1, str.size()-2);
  yylval.cpp_string = new std::string(str);
  return WORD;
}

\`[^\n\`]*\`|\$\([^\n]*\) {
  std::string str = std::string(yytext);
  if (str.at(0) == '$') {
    str = str.substr(2, str.size()-2);
  } else {
    str = str.substr(1, str.size()-2);
  }


  int pin[2], pout[2];
  pipe(pin); pipe(pout);
  


  int ret = fork();
  if (ret == 0) {
    std::string command [2] = { "/proc/self/exe", NULL};
    execvp((const char *) command[0], command);
  }
  



}


[^ \t\n][^ \t\n]*  {
  /* Assume that file names have only alpha chars */
  yylval.cpp_string = new std::string(yytext);
  return WORD;
}
