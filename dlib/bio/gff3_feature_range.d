module bio.gff3_feature_range;

import bio.gff3_feature, bio.gff3_record_range, bio.gff3_record, bio.gff3_validation;
import util.range_with_cache, util.dlist;

class FeatureRange(SourceRangeType) : RangeWithCache!Feature {

  this(SourceRangeType data, RecordValidator validator = EXCEPTIONS_ON_ERROR,
       bool replace_esc_chars = true, size_t feature_cache_size = 1000) {
    this.records = new RecordRange!SourceRangeType(data, validator, replace_esc_chars);
    this.data = new FeatureCache(feature_cache_size);
  }

  protected Feature next_item() {
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
      item = item.next;
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

import util.split_into_lines;
import std.stdio;

unittest {
  string test_records = ".\t.\t.\t.\t.\t.\t.\t.\tID=1;value=1\n" ~
                        ".\t.\t.\t.\t.\t.\t.\t.\tID=1;value=2\n" ~
                        ".\t.\t.\t.\t.\t.\t.\t.\tID=1;value=3";
  auto features = new FeatureRange!SplitIntoLines(new SplitIntoLines(test_records));
  assert(features.front.id == "1");
  features.popFront();
  assert(features.empty == true);

  test_records = ".\t.\t.\t.\t.\t.\t.\t.\tID=1;value=1\n" ~
                 ".\t.\t.\t.\t.\t.\t.\t.\tID=1;value=2\n" ~
                 ".\t.\t.\t.\t.\t.\t.\t.\tID=1;value=3\n" ~
                 ".\t.\t.\t.\t.\t.\t.\t.\tID=2;value=4\n" ~
                 ".\t.\t.\t.\t.\t.\t.\t.\tID=2;value=5\n" ~
                 ".\t.\t.\t.\t.\t.\t.\t.\tID=2;value=6";
  features = new FeatureRange!SplitIntoLines(new SplitIntoLines(test_records));
  assert(features.empty == false);
  assert(features.front.id == "1");
  assert(features.front.records.length == 3);
  features.popFront();
  assert(features.empty == false);
  assert(features.front.id == "2");
  assert(features.front.records.length == 3);
  features.popFront();
  assert(features.empty == true);
}

