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
#include <algorithm>
#include <regex.h>
#include <dirent.h>

void yyerror(const char * s);
int yylex();
void expandWildcard(char* prefix, char* suffix);
bool cmp_func(char * name1, char * name2);
static std::vector<char *> array = std::vector<char *>();
int num;
#define MAXFILENAME 1024




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
      //array = (char **)malloc(sizeof(char*)* 69);;
      int num  = 0;	
      expandWildcard(NULL, (char*) $1->c_str());
      std::sort(array.begin(), array.end(), cmp_func);
      //qsort(array, num, sizeof(char*), );
      for (auto a: array) {
        std::string * argToInsert = new std::string(a);
        Command::_currentSimpleCommand->insertArgument(argToInsert);
      }
      array.clear();
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


bool cmp_func (char * name1, char * name2) { 
  return strcmp(name1,name2)<0; 
}



void expandWildcard(char * prefix, char * suffix){
  if (suffix[0] == 0) {
    array.push_back(strdup(prefix));    
    return;
  }



  // Obtain the next component in the suffix
  // Also advance suffix.
  char * s = strchr(suffix,'/');
  char component[MAXFILENAME];
  if(s != NULL){
    if(s-suffix != 0){
      strncpy(component, suffix, s-suffix);
      component[strlen(suffix)-strlen(s)] = '\0';
    } else {
      component[0] = '\0';
    }
    suffix = s+1;
  } else {
    strcpy(component, suffix);
    suffix = suffix + strlen(suffix);
  }

  // Now we need to expand the component
  char newPrefix[MAXFILENAME];
  if (strchr(component,'*') == NULL && strchr(component,'?') == NULL) {
    if(prefix == NULL && component[0] != '\0'){
      sprintf(newPrefix, "%s", component);
    } else {
      sprintf(newPrefix,"%s/%s",prefix,component);
    } 
    if (component[0] == '\0') {
      char * s = (char*)"";
      expandWildcard(s,suffix);	
    } else {
      expandWildcard(newPrefix,suffix);
    }
    return;
  }

  char * exp = (char*)malloc(sizeof(char) * (2*(strlen(component)+10)));
  char * a = component;
  char * r = exp;
	
  *r = '^'; r++;
  while(*a != '\0'){
    if (*a == '*') { *r = '.'; r++; *r = '*'; r++;} 
    else if (*a == '?') { *r = '.'; r++;}
    else if (*a == '.') { *r='\\'; r++; *r='.'; r++;} 
    else { *r=*a; r++;}
    a++;
  }
  *r='$'; r++; *r='\0';

  regex_t tmp;
  int check = regcomp(&tmp, exp, 0);

  
  if (check > 0) {
    perror("compile");
    return;
  }

  DIR * dir;
  if (prefix == NULL) {
    dir = opendir(".\0");
  } else if (strcmp(prefix, "") == 0) {
    dir = opendir("/\0");
  } else {
    dir = opendir(prefix);	
  }



  if (dir == NULL) {
    return;
  }	
  struct dirent * ent;

  while((ent = readdir(dir)) != NULL) {
    //printf("%s\n", ent->d_name);
    if(regexec(&tmp,ent->d_name,0,NULL,0) == 0) {
      //printf("%s\n",ent->d_name);
      //printf("sus\n");
      if(ent->d_name[0] == '.'){
        if(component[0] == '.'){



	  if(prefix == NULL){	
	    sprintf(newPrefix, "%s", ent->d_name);
	  } else {
	    sprintf(newPrefix, "%s/%s", prefix, ent->d_name);
	  }


	  expandWildcard(newPrefix,suffix);
	}
      } else {
        if(component[0] != '.'){
	//printf("sus\n");
          if(prefix == NULL){
	    sprintf(newPrefix, "%s", ent->d_name);
	  } else {
	    sprintf(newPrefix, "%s/%s", prefix, ent->d_name);
	  }
          expandWildcard(newPrefix,suffix);
        }
      }
    } 
  }	
  closedir(dir);
}

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
