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
 * CS252: Systems Programming
 * Purdue University
 * Example that shows how to read one line with simple editing
 * using raw terminal.
 */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <stdbool.h>
#define MAX_BUFFER_LINE 2048
#define HISTORY_SIZE 32
extern void tty_raw_mode(void);

// Buffer where line is stored
int line_length;
int right_side_length;
char right_side_buffer[MAX_BUFFER_LINE];
char line_buffer[MAX_BUFFER_LINE];

// Simple history array
// This history does not change. 
// Yours have to be updated.

//std::vector<string> Shell::history;

int history_index = 0;
int history_index_rev = 0;
int history_full = 0;
//char * history [HISTORY_SIZE];
char * history [] = {
  "ls -al | grep x", 
  "ps -e",
  "cat read-line-example.c",
  "vi hello.c",
  "make",
  "ls -al | grep xxx | grep yyy"
};





int history_length = sizeof(history)/sizeof(char *);

void read_line_print_usage()
{
  char * usage = "\n"
    " ctrl-?       Print usage\n"
    " Backspace    Deletes last character\n"
    " up arrow     See last command in the history\n";

  write(1, usage, strlen(usage));
}

/* 
 * Input a line with some basic editing.
 */
char * read_line() {

  // Set terminal in raw mode
  tty_raw_mode();

  line_length = 0;
  

  bool sus = false;
  // Read one line until enter is typed
  while (1) {

    // Read one character in raw mode.
    char ch;
    read(0, &ch, 1);

    if (ch>=32) {
      // It is a printable character. 

      // Do echo
      write(1,&ch,1);

      // If max number of character reached return.
      if (line_length==MAX_BUFFER_LINE-2) break; 

      // add char to buffer.
      line_buffer[line_length]=ch;
      line_length++;
    }
    else if (ch==10) {
      write(1,&ch,1);
      break;

      	    
      // <Enter> was typed. Return line
      //std::string s = line_buffer;
      
      //history.push_back(s);   
      if (right_side_length) {
        for (int i=right_side_length-1; i>=0; i--) {
          char c = right_side_buffer[i];

          line_buffer[line_length]=c;
          line_length++;
        }
      }

      if (line_length != 0) {
        if (history[history_index]==NULL) { 
          history[history_index] = (char *)malloc(MAX_BUFFER_LINE);
        }
        strcpy(history[history_index], line_buffer);
        history_index_rev = history_index;
        history_index++;
        if (history_index>=history_length) {
          history_index = 0;
          history_full = 1;
        }
      }


      right_side_length=0;




      write(1,&ch,1);
      break;
    }
    else if (ch == 31) {
      // ctrl-?
      read_line_print_usage();
      line_buffer[0]=0;
      break;
    } else if (ch == 1) {
      //ctrl A
      
      int temp = line_length;
      for (int i = 0; i < temp; i++) {
        ch = 8;
        write(1,&ch,1);  
        right_side_buffer[right_side_length] = line_buffer[line_length-1];
        right_side_length++;
        line_length--;
      }



    } else if (ch == 4) {
      //ctrl D
    


    } else if (ch == 5) {
      //ctrl E


    }







    else if (ch == 8) {
      // <backspace> was typed. Remove previous character read.

      // Go back one character
      ch = 8;
      write(1,&ch,1);

      // Write a space to erase the last character read
      ch = ' ';
      write(1,&ch,1);

      // Go back one character
      ch = 8;
      write(1,&ch,1);

      // Remove one character from buffer
      line_length--;
          
    } else if (ch==27) {
      // Escape sequence. Read two chars more
      //
      // HINT: Use the program "keyboard-example" to
      // see the ascii code for the different chars typed.
      //
      char ch1; 
      char ch2;
      read(0, &ch1, 1);
      read(0, &ch2, 1);
      if (ch1==91 && (ch2==65 || ch2==66)) {
	// Up arrow. Print next line in history.

	// Erase old line
	// Print backspaces
	int i = 0;
	for (i =0; i < line_length; i++) {
	  ch = 8;
	  write(1,&ch,1);
	}

	// Print spaces on top
	for (i =0; i < line_length; i++) {
	  ch = ' ';
	  write(1,&ch,1);
	}

	// Print backspaces
	for (i =0; i < line_length; i++) {
	  ch = 8;
	  write(1,&ch,1);
	}	
        
	// Copy line from history
	if (!sus && ch2 == 65) {

          //sus = true;
	  strcpy(line_buffer, history[history_index]);
	  line_length = strlen(line_buffer);
        }

        if (ch2 == 65 && sus) {

	  history_index=(history_index+1)%history_length;
        } else if (ch2 == 66 && sus)  {
	  
          history_index = (history_index - 1)%history_length;  
          if (history_index < 0) {
            history_index = history_length - 1;
	  }
	}
	if (sus) {	
          strcpy(line_buffer, history[history_index]);
          line_length = strlen(line_buffer);
        }
        sus = true;

	// echo line
	write(1, line_buffer, line_length);
      }
      
    }

  }

  // Add eol and null char at the end of string
  line_buffer[line_length]=10;
  line_length++;
  line_buffer[line_length]=0;

  return line_buffer;
}

