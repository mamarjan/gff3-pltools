module util.logger;

import std.stdio, std.c.stdlib;

void init_default_logger(int verbosity_level) {
  default_logger = new Logger(verbosity_level);
}

/**
 * Level > 1
 */
void info(string message) {
  check_default_logger();
  default_logger.info(message);
}

/**
 * Level > 0
 */
void warn(string message) {
  check_default_logger();
  default_logger.warn(message);
}

/**
 * Level > -1
 */
void error(string message) {
  check_default_logger();
  default_logger.error(message);
}

class Logger {
  this(int verbosity_level) {
    this.verbosity_level = verbosity_level;
  }

  /**
   * Level > 1
   */
  void info(string message) {
    if (verbosity_level > 1)
      stderr.writeln("Info: ", message);
  }

  /**
   * Level > 0
   */
  void warn(string message) {
    if (verbosity_level > 0)
      stderr.writeln("Warning: ", message);
  }

  /**
   * Level > -1
   */
  void error(string message) {
    if (verbosity_level > -1) {
      stderr.writeln("Error: ", message);
      exit(1);
    }
  }

  int verbosity_level = 0;
}

private {
  void check_default_logger() {
    if (default_logger is null) {
      init_default_logger(0);
    }
  }

  Logger default_logger;
}

