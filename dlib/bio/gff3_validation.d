module bio.gff3_validation;

import std.exception;

auto WARNINGS_ON_ERROR = function bool(string line) {
  try {
    throw new Exception("A record with invalid number of columns");
  } catch (Exception e) {
  }
  return false;
};

