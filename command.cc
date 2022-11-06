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
#include <cstdlib>

#include <iostream>
#include <string.h>
#include "command.hh"
#include "shell.hh"
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <wait.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <termios.h> 


Command::Command() {
    // Initialize a new vector of Simple Commands
    _simpleCommands = std::vector<SimpleCommand *>();

    _outFile = NULL;
    _inFile = NULL;
    _errFile = NULL;
    _background = false;
    _append = false;
}

void Command::insertSimpleCommand( SimpleCommand * simpleCommand ) {
    // add the simple command to the vector
    _simpleCommands.push_back(simpleCommand);
}

void Command::clear() {
    // deallocate all the simple commands in the command vector
    for (auto simpleCommand : _simpleCommands) {
        delete simpleCommand;
    }

    // remove all references to the simple commands we've deallocated
    // (basically just sets the size to 0)
    _simpleCommands.clear();
    if (_outFile && _errFile) { 
      if (_outFile->c_str() == _errFile->c_str()) {
        delete _outFile;
        _outFile = NULL;
        _errFile = NULL;
      }
    }

    if ( _outFile ) {
        delete _outFile;
    }
    _outFile = NULL;

    if ( _inFile ) {
        delete _inFile;
    }
    _inFile = NULL;

    if ( _errFile ) {
        delete _errFile;
    }
    _errFile = NULL;

    _background = false;
    _append = false;
}

void Command::redirect(int i, std::string * file) {

  //infile 
  if (i == 0) {
    if (_inFile) {
      //if infile already exists, exit
      printf("Ambiguous input redirect.\n");
      exit(1);
    } else {
      _inFile = file;
    }
  }
  //outfile
  if (i == 1) {
    if (_outFile) {
      //if outfile already exists, exit
      printf("Ambiguous output redirect.\n");
      exit(1);
    } else {
      _outFile = file;
    }
  }

  //errfile
  if (i == 2) {
    if (_errFile) {
      //if outfile already exists, exit
      printf("Ambiguous error redirect.\n");
      exit(1);
    } else {
      _errFile = file;
    }
  }
}

void Command::print() {
    //return;
    printf("\n\n");
    printf("              COMMAND TABLE                \n");
    printf("\n");
    printf("  #   Simple Commands\n");
    printf("  --- ----------------------------------------------------------\n");

    int i = 0;
    // iterate over the simple commands and print them nicely
    for ( auto & simpleCommand : _simpleCommands ) {
        printf("  %-3d ", i++ );
        simpleCommand->print();
    }

    printf( "\n\n" );
    printf( "  Output       Input        Error        Background\n" );
    printf( "  ------------ ------------ ------------ ------------\n" );
    printf( "  %-12s %-12s %-12s %-12s\n",
            _outFile?_outFile->c_str():"default",
            _inFile?_inFile->c_str():"default",
            _errFile?_errFile->c_str():"default",
            _background?"YES":"NO");
    printf( "\n\n" );
}

void Command::execute() {

    // Don't do anything if there are no simple commands
    if ( _simpleCommands.size() == 0 ) {
        Shell::prompt();
        return;
    }
    //print();
    const char * cmd = _simpleCommands[0]->_arguments[0]->c_str();

    //exit
    if (strcmp(cmd, "exit") == 0) {
      printf("Good Bye!!\n");
      struct termios tty_attr;

      tcgetattr(0,&tty_attr);

      /* Set raw mode. */
      tty_attr.c_lflag |= ICANON;
      tty_attr.c_lflag |= ECHO;

      tty_attr.c_cc[VTIME] = 0;
      tty_attr.c_cc[VMIN] = 1;

      tcsetattr(0,TCSANOW,&tty_attr);
      exit(1);
    }

    //cd
    if (strcmp(cmd, "cd") == 0) {
      if (_simpleCommands[0]->_arguments.size() == 1) {
        chdir(getenv("HOME"));
      } else {
        const char * dir = _simpleCommands[0]->_arguments[1]->c_str();
	struct stat st;
	
	if (stat(dir, &st) == 0) {
          chdir(dir);
	} else {
	  fprintf(stderr, "cd: can't cd to %s\n", dir);
	}
      }
      clear();
      Shell::prompt();
      return;
    }
    //putenv
    if (strcmp(cmd, "putenv") == 0) {
      const char * A = _simpleCommands[0]->_arguments[1]->c_str();
      putenv((char * ) A);
    }


    //printenv
    //if (strcmp(cmd, "printenv") == 0) {
      //char ** temp = environ;	    
      //while (*temp != NULL) {
        //printf("%s\n", *temp);
	//temp++;
      //}
      //exit(0);
      //clear();
      //Shell::prompt();
      //return;
    //}

    //unsetenv
    if (strcmp(cmd, "unsetenv") == 0) {
      const char * A = _simpleCommands[0]->_arguments[1]->c_str();
      unsetenv(A);
      clear();
      Shell::prompt();
      return;
    }

    //setenv
    if (strcmp(cmd, "setenv") == 0) {
      const char * A = _simpleCommands[0]->_arguments[1]->c_str();
      const char * B = _simpleCommands[0]->_arguments[2]->c_str();
      setenv(A, B, 1);
      clear();
      Shell::prompt();
      return;
    }

     
    int defaultin = dup( 0 );
    int defaultout = dup( 1 );
    int defaulterr = dup( 2 );
    int in;
    int out;
    int err;

    //in file
    if (_inFile) {
      //might need to make it a string first
      in = open((const char *) _inFile->c_str(), O_RDONLY);
      if (in < 0) {
        //handle error
      }
    } else {
      in = dup(defaultin);
    }
   
    //err file
    if (_errFile) {
      //char * err1 = _errFile->c_str(); 
      if (_append) {
        err  = open( (const char *) _errFile->c_str(), O_CREAT|O_WRONLY|O_APPEND, 0666);
      } else {
        err = open( (const char *) _errFile->c_str(), O_CREAT|O_WRONLY|O_TRUNC, 0666);
      }
      if (err < 0) {
        //error 
      }
    } else {
          err = dup(defaulterr);
    }







    int ret;
    for (int i = 0; i < (int) _simpleCommands.size(); i++) {
      
      dup2(in, 0);
      close(in);
      
      //check if its the last command in the list
      if (i == (int) _simpleCommands.size() - 1) {
        //out file
        if (_outFile) {
	  //char * out1 = _outFile->c_str();
          if (_append) {
            out = open( (const char *) _outFile->c_str(), O_CREAT|O_WRONLY|O_APPEND, 0666);
          } else {
            out = open( (const char *) _outFile->c_str(), O_CREAT|O_WRONLY|O_TRUNC, 0666);
          }
          if (out < 0) {
            //error 
          }
        } else {
          out = dup(defaultout);
        }
      
        //err file
        //if (_errFile) {
	  //char * err1 = _errFile->c_str(); 
          //if (_append) {
  
            //err  = open( (const char *) _errFile->c_str(), O_CREAT|O_WRONLY|O_APPEND, 0666);
          //} else {
            //err = open( (const char *) _errFile->c_str(), O_CREAT|O_WRONLY|O_TRUNC, 0666);
          //}
          //if (err < 0) {
            //error 
          //}
        //} else {
          //err = dup(defaulterr);
        //}
        //dup2(err, 2);
        //close(err);
	int n = _simpleCommands[i]->_arguments.size();
        char * c = strdup(_simpleCommands[i]->_arguments[n-1]->c_str());
        setenv("_", c, 1);	
      } else {
        //pipe
	int fdpipe[2];
	pipe(fdpipe);
	out = fdpipe[1];
	in = fdpipe[0];
      }
      dup2(out, 1);
      close(out);
      dup2(err, 2);
      close(err);  



      ret = fork();
      if (ret == 0) {
        //child
        //printenv
      const char * cmd1 = _simpleCommands[i]->_arguments[0]->c_str();
      if (strcmp(cmd1, "printenv") == 0) {
        char ** temp = environ;
        while (*temp != NULL) {
          dprintf(1, "%s\n", *temp);
          temp++;
        }
        exit(0);
        //clear();
        //Shell::prompt();
        //return;
    }
  

        const char * command = _simpleCommands[i]->_arguments[0]->c_str();
	//char ** args = _simpleCommands[i]->_arguments;
        int num = _simpleCommands[i]->_arguments.size();
        char ** args = new char*[num+1];
        for (int j=0; j<num; j++) {
            args[j] = (char *)_simpleCommands[i]->_arguments[j]->c_str();
        }
        args[num] = NULL;
        
	execvp(command, args); 



	//may need to be strings
	//execvp((char * )_simpleCommands[i]->_arguments[0], (char *) _simpleCommands[i]->_arguments);

	perror("execvp");
	exit(1);
      } else if (ret < 0) {
        perror("fork");
	return;
      }
      //parent shell continue
    }
    if (!_background) {
      //wait for last process
      int status;
      waitpid(ret, &status, 0);
      std::string s = std::to_string(WEXITSTATUS(status));
      setenv("?", s.c_str(), 1);


      	     
      //waitpid(ret, NULL, 0);
    } else {
      std::string s = std::to_string(ret);
      setenv("!", s.c_str(), 1);
      //Shell::_bgPIDs.push_back(ret);

    }
      //close(fdpipe[0]);
      //close(fdpipe[1]);
      //may need to set them to the original numbers
      

      dup2(defaultin, 0);
      dup2(defaultout, 1);
      dup2(defaulterr, 2);
      close( defaultin );
      close( defaultout );
      close( defaulterr );

    




    // Setup i/o redirection
    // and call exec

    // Clear to prepare for next command
    clear();

    // Print new prompt
    Shell::prompt();
}

SimpleCommand * Command::_currentSimpleCommand;
