module bio.gff3_feature_range;

import bio.gff3_feature, bio.gff3_record_range, bio.gff3_record, bio.gff3_validation;
import util.range_with_cache, util.dlist;

class FeatureRange(SourceRangeType) : RangeWithCache!Feature {

  this(SourceRangeType data, RecordValidator validator = EXCEPTIONS_ON_ERROR,
       bool replace_esc_chars = true) {
    this.records = new RecordRange!SourceRangeType(data, validator, replace_esc_chars);
  }

  Feature next_item() {
    Feature feature;
    while((!records.empty) && (feature is null)) {
      feature = data.add_record(records.front);
      records.popFront();
    }
    if (records.empty) {
      feature = data.remove_from_back();
    }
    return feature;
  }

  void set_filename(string filename) {
    records.set_filename(filename);
  }

  private {
    RecordRange!SourceRangeType records;
    FeatureCache data;
  }
}

class FeatureCache {
  this(size_t max_size = 1000) {
    this.max_size = max_size;
    this.dlist = new DList!FeatureCacheItem();
    this.list = new FeatureCacheItem[max_size];
  }

  Feature add_record(Record new_record) {
    FeatureCacheItem * item = dlist.first;
    while(item !is null) {
      if (item.id == new_record.id) {
        item.feature.add_record(new_record);
        return null;
      }
    }
    auto new_item = FeatureCacheItem(new_record.id, new Feature(new_record), null, null);
    if (current_size != max_size) {
      list[current_size] = new_item;
      dlist.insert_front(&(list[current_size]));
      current_size++;
      return null;
    } else {
      auto feature = dlist.last.feature;
      item = dlist.remove_back();
      *item = new_item;
      dlist.insert_front(item);
      return feature;
    }
  }

  Feature remove_from_back() {
    auto item = dlist.remove_back();
    if (item !is null)
      return item.feature;
    else
      return null;
  }

  private {
    DList!FeatureCacheItem dlist;
    FeatureCacheItem[] list;

    size_t max_size;
    uint current_size = 0;
  }
}

struct FeatureCacheItem {
  string id;
  Feature feature;
  FeatureCacheItem * prev;
  FeatureCacheItem * next;
}


