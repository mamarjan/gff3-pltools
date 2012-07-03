module util.version_helper;

/**
 * Fetches at compile time the version string from
 * file VERSION, which has to be in a path fir files
 * which can be imported, e.g. the path to the
 * directory where the file is located has to
 * be specified on the command line using the -Jpath
 * option.
 */
string fetch_version() {
  return mixin("\"" ~ import("VERSION") ~ "\"");
}

