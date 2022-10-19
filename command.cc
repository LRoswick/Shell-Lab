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

#include "command.hh"
#include "shell.hh"
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <wait.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>


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
}

void Command::print() {
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

    // Print contents of Command data structure
    print();

    // Add execution here
    // For every simple command fork a new process
    
    int defaultin = dup( 0 );
    int defaultout = dup( 1 );
    int defaulterr = dup( 2 );
    int in;
    int out;
    int err;


    //in file
    if (_inFile) {
      //might need to make it a string first
      in = open((const char *) _inFile, O_RDONLY);
      if (in < 0) {
        //handle error
      }
    } else {
      in = dup(defaultin);
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
            out = open( (const char *) _outFile, O_CREAT|O_WRONLY|O_APPEND, 0666);
          } else {
            out = open( (const char *) _outFile, O_CREAT|O_WRONLY|O_TRUNC, 0666);
          }
          if (out < 0) {
            //error 
          }
        } else {
          out = dup(defaultout);
        }
      
        //err file
        if (_errFile) {
	  //char * err1 = _errFile->c_str(); 
          if (_append) {
  
            out = open( (const char *) _errFile, O_CREAT|O_WRONLY|O_APPEND, 0666);
          } else {
            out = open( (const char *) _errFile, O_CREAT|O_WRONLY|O_TRUNC, 0666);
          }
          if (err < 0) {
            //error 
          }
        } else {
          err = dup(defaulterr);
        }
        dup2(err, 2);
        close(err);	
      } else {
        //pipe
	int fdpipe[2];
	pipe(fdpipe);
	out = fdpipe[1];
	in = fdpipe[0];
      }
      dup2(out, 1);
      close(out);



      ret = fork();
      if (ret == 0) {
        //child
        

        const char * command = _simpleCommands[i]->_arguments[0];
	char ** args = _simpleCommands[i]->_arguments;
        //int num = _simpleCommands[i]->_arguments.size();
        //char ** args = new char*[num+1];
        //for (int j=0; j<num; j++) {
        //    args[j] = (char *)_simpleCommands[i]->_arguments[j]->c_str();
        //}
        //args[num] = NULL;
        
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
      waitpid(ret, NULL, 0);
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
