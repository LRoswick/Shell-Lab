%{

#include <cstring>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include "y.tab.hh"
#include "shell.hh"
#include <sys/types.h>
#include <sys/wait.h>
#include <string.h>

extern "C" char * read_line();

int mygetc(FILE * f) {
  static char *p;
  char ch;

  if (!isatty(0)) {
    //stdin is not a tty. Call real getc
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

%x src


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

source BEGIN(src);

<src>[ \t]*
<src>[^ \t\n]+ {
FILE * yyin = fopen( yytext, "r" );
if ( !yyin ) {
 perror("fopen");
}

  yypush_buffer_state(yy_create_buffer( yyin, YY_BUF_SIZE ));
  BEGIN(INITIAL);
}

<<EOF>> {
  yypop_buffer_state();

  if ( !YY_CURRENT_BUFFER ) {
    yyterminate();
  }
}


~[^ \n\t]* {
  std::string str = std::string(yytext);
  std::string home = getenv("HOME");
  if (str.size() == 1) {
    yylval.cpp_string = new std::string(home);
  } else {

    if (str[1] == '/') {
      str = home + str.substr(1, -1);
    } else {
      str = std::string("/homes/") + str.substr(1,-1);
    }
    yylval.cpp_string = new std::string(str);
  }
  return WORD;
} 


\"[^\n\"]*\" {
  std::string str = std::string(yytext);
  str = str.substr(1, str.size()-2);
  yylval.cpp_string = new std::string(str);
  return WORD;
}

[^ \\\t\n]*(\\[^\n\t])((\\[^\n\t])|[^ \\\t\n])* {
  std::string str = std::string(yytext);
  std::size_t index = str.find('\\');
  while(index!=-1) {
    str = str.substr(0,index) + str.substr(index+1,std::string::npos);
    index = str.find('\\', index+1);
  }
  yylval.cpp_string = new std::string(str);
  return WORD;
}

$\{[^ \}\n]*\}([^ \n]*|$\{[^ \}\n]*\})* {
  std::string str = std::string(yytext);
  std::size_t index = str.find('$');
  while(index!=-1) {
    std::string name = "";
    std::string var = "";
    if (str[index + 1] == '{') {
      std::size_t end = str.find('}');
      name = str.substr(index + 2, end - index - 2);
      std::string x = std::string(getenv(name.c_str()));
      var = x;
    }

    std::string str2 = str.substr(0,index) + var;
    if (index + name.size() + 3 < str.size()) { 
      str2 = str2 + str.substr(index + name.size() + 3, str.size() - index - name.size() - 3);
    }
    str = str2;
   
    //str = str.substr(0,index) + str.substr(index+1,std::string::npos);
    index = str.find('$', index+1);
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


[^ <>&\t\n][^ <>&\t\n]*  {
  /* Assume that file names have only alpha chars */
  yylval.cpp_string = new std::string(yytext);
  return WORD;
}
