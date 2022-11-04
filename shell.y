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
 * CS-252
 * shell.y: parser for shell
 *
 * This parser compiles the following grammar:
 *
 *	cmd [arg]* [> filename]
 *
 * you must extend it to understand the complete shell grammar
 *
 */

%code requires 
{
#include <string>

#if __cplusplus > 199711L
#define register      // Deprecated in C++11 so remove the keyword
#endif
}

%union
{
  char        *string_val;
  // Example of using a c++ type in yacc
  std::string *cpp_string;
}

%token <cpp_string> WORD
%token NOTOKEN GREAT NEWLINE LESS TWOGREAT GREATAND GREATGREAT GREATGREATAND AND PIPE

%{
//#define yylex yylex
#include <cstdio>
#include "shell.hh"
#include <cstring>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>  
#include <sys/wait.h>   
#include <string.h>
#include <signal.h>
#include <fcntl.h>      
#include <unistd.h>     
#include <pwd.h>

void yyerror(const char * s);
int yylex();
void expandWildcard(char* prefix, char* suffix);
int cmp_func(const void *name1, const void *name2);
char** array;
int num;
int arrayCounter;
%}

%%

goal:
  //commands
  command_list;
  ;

/*
commands:
  command
  | commands command
  ;

command: simple_command
       ;
*/

command_line:	
  pipe_list io_modifier_list background_optional NEWLINE {
    //printf("   Yacc: Execute command\n");
    Shell::_currentCommand.execute();
  }
  | NEWLINE 
  | error NEWLINE { yyerrok; }
  ;

command_list:
  command_line
  | command_list command_line
  ;

cmd_and_args:
  command_word arg_list{
    Shell::_currentCommand.
    insertSimpleCommand( Command::_currentSimpleCommand );
  }
  ;

arg_list:
  arg_list arg
  | /* can be empty */
  ;



arg:
  WORD {
    //printf("   Yacc: insert argument \"%s\"\n", $1->c_str());
    //expandWildcardsIfNecessary((char *)$1->c_str());
    //Command::_currentSimpleCommand->insertArgument( $1 );
    if( strchr((char *) $1->c_str(),'*') != NULL || strchr((char *)$1->c_str(),'?') != NULL){
      array = (char **)malloc(sizeof(char*)* 69);;
      int num  = 0;	
      expandWildcard(NULL, strdup((char*)$1->c_str()));
      //qsort(array, num, sizeof(char*), );
      for(int i = 0; i < num; i++){
        //Command::_currentSimpleCommand->insertArgument(strdup(array[i]));
      }
      free(array);
    } else {
      Command::_currentSimpleCommand->insertArgument($1);
    }



  }
  ;



pipe_list:
  cmd_and_args
  | pipe_list PIPE cmd_and_args
  ;



command_word:
  WORD {
    //printf("   Yacc: insert command \"%s\"\n", $1->c_str());
    Command::_currentSimpleCommand = new SimpleCommand();
    Command::_currentSimpleCommand->insertArgument( $1 );
  }
  ;

io_modifier:
  GREAT WORD {
    //printf("   Yacc: insert output \"%s\"\n", $2->c_str());
    Shell::_currentCommand._outFile = $2;
  }
  | GREATGREAT WORD {
    //printf("   Yacc: insert output \"%s\"\n", $2->c_str());
    Shell::_currentCommand._outFile = $2;
    Shell::_currentCommand._append = true;
  }
  | GREATGREATAND WORD {
    //printf("   Yacc: insert output \"%s\"\n", $2->c_str());
    Shell::_currentCommand._outFile = $2;
    Shell::_currentCommand._errFile = $2;
    Shell::_currentCommand._append = true;
  }
  | GREATAND WORD {
    //printf("   Yacc: insert output \"%s\"\n", $2->c_str());
    Shell::_currentCommand._outFile = $2;
    Shell::_currentCommand._errFile = $2;
  }
  | LESS WORD {
   // printf("   Yacc: insert input \"%s\"\n", $2->c_str());
    Shell::_currentCommand._inFile = $2;
  }
  | TWOGREAT WORD {
    Shell::_currentCommand._errFile = $2;
  }
  ;

io_modifier_list:
  io_modifier_list io_modifier
  | /*empty*/ 
  ;

background_optional:
  AND {
    Shell::_currentCommand._background = true;
  }
  | /*empty*/
  ;

/*command_line:
  pipe_list io_modifier_list background_optional NEWLINE {
    printf("   Yacc: Execute command\n");
    Shell::_currentCommand.execute();
  }
  | NEWLINE
  | error NEWLINE{yyerrok;}
  ;

command_list:
  command_line
  | command_list command_line
*/

%%

void expandWildcardsIfNecessary(char * arg) {
    
  //if (strchr(arg,'?')==NULL & strchr(arg,'*')==NULL) {
    //Command::_currentSimpleCommand->insertArgument(arg);
    //return;

  //}

  char * reg = (char*)malloc(2*strlen(arg)+10);
  char * a = arg;
  char * r = reg;
  *r = '^'; r++; // match beginning of line
  while (*a) {
  if (*a == '*') { *r='.'; r++; *r='*'; r++; }
  else if (*a == '?') { *r='.'; r++;}
  else if (*a == '.') { *r='\\'; r++; *r='.'; r++;}
  else { *r=*a; r++;}
  a++;
  }
  *r='$'; r++; *r=0;// match end of line and add null char
  

  // 2. compile regular expression. See lab3-src/regular.cc
  //char * expbuf = regcomp( reg, ... );
  //if (expbuf==NULL) {
  //perror(“compile”);
  //return;
  //}

  // 3. List directory and add as arguments the entries
  // that match the regular expression
  //DIR * dir = opendir(“.”);
  //if (dir == NULL) {
  //perror(“opendir”);
  //return;
  //}
  

  //struct dirent * ent;
  //while ( (ent = readdir(dir))!= NULL) {
  // Check if name matches
  //if (regexec(ent->d_name, expbuf ) ==0 ) {
    // Add argument
    //Command::_currentSimpleCommand->insertArgument(strdup(ent->d_name));

  //}
//}
//closedir(dir);





}


  







// Obtain the next component in the suffix
// Also advance suffix.
//char * s = strchr(suffix, ‘/’);
//char component[MAXFILENAME];







//if (s!=NULL){ // Copy up to the first “/”

  //strncpy(component,suffix, s-suffix);
  //suffix = s + 1;
//} else { // Last part of path. Copy whole thing.

  //strcpy(component, suffix);
  //suffix = suffix + strlen(suffix);
//}

// Now we need to expand the component
//char newPrefix[MAXFILENAME];
//if (strchr(component,'*') == NULL && strchr(component,'?') == NULL) {
// component does not have wildcards
//sprintf(newPrefix,"%s/%s", prefix, component);
//expandWildcard(newPrefix, suffix);
//return;
//}
// Component has wildcards
// Convert component to regular expression

//char * expbuf = compile(...)
//char * dir;
// If prefix is empty then list current directory



//if (prefix is empty) dir =“.”; else dir=prefix;
//DIR * d=opendir(dir);
//if (d==NULL) return;

// Now we need to check what entries match
//while ((ent = readdir(d))!= NULL) {
// Check if name matches
//if (advance(ent->d_name, expbuf) ) {
// Entry matches. Add name of entry
// that matches to the prefix and
// call expandWildcard(..) recursively
//sprintf(newPrefix,"%s/%s", prefix, ent->d_name);
//expandWildcard(newPrefix,suffix);
//}
//}
//close(d);
//}




void
yyerror(const char * s)
{
  fprintf(stderr,"%s", s);
}

#if 0
main()
{
  yyparse();
}
#endif
