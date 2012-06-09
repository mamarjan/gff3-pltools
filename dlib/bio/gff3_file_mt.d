module bio.gff3_file_mt;

import bio.gff3_file, bio.gff3_validation;
import util.split_file_mt;

/**
 * Parses a file with GFF3 data by using a second thread for reading the file.
 * Returns: a range of records.
 */
auto open_mt(string filename, RecordValidator validator = EXCEPTIONS_ON_ERROR,
             bool replace_esc_chars = true) {
  return new RecordRange!(SplitFileMT)(new SplitFileMT(filename), validator,
                                     replace_esc_chars);
}

