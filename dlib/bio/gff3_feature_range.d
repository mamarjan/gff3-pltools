module bio.gff3_feature_range;

import bio.gff3_feature, bio.gff3_record_range, bio.gff3_record;
import util.range_with_cache;

class FeatureRange : RangeWithCache!Feature {

  this(RangeWithCache!Record records) {
    this.records = records;
  }

  Feature next_item() {
    return null;
  }

  private {
    RangeWithCache!Record records;
  }
}

