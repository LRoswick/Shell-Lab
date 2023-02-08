#ifndef shell_hh
#define shell_hh

#include "command.hh"

struct Shell {

  static void prompt();
  //static std::vector<int> _bgPIDs;

  static Command _currentCommand;
};

#endif
