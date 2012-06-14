module bio.gff3_feature_range;

import bio.gff3_feature, bio.gff3_record_range, bio.gff3_record, bio.gff3_validation;
import util.range_with_cache;

class FeatureRange(SourceRangeType) : RangeWithCache!Feature {

  this(SourceRangeType data, RecordValidator validator = EXCEPTIONS_ON_ERROR,
       bool replace_esc_chars = true) {
    this.records = new RecordRange!SourceRangeType(data, validator, replace_esc_chars);
  }

  Feature next_item() {
    return null;
  }

  void set_filename(string filename) {
    records.set_filename(filename);
  }

  private {
    RecordRange!SourceRangeType records;
  }
}

