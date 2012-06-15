module bio.gff3_feature_range;

import bio.gff3_feature, bio.gff3_record_range, bio.gff3_record, bio.gff3_validation;
import util.range_with_cache;

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
      feature = data.remove_from_back().feature;
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
  this(uint max_size = 1000) {
    this.list = FixedSizeDlist!FeatureCacheItem(max_size);
  }

  Feature add_record(Record new_record) {
    FeatureCacheItem * item = list.start;
    while(item !is null) {
      if (current.id == new_record.id) {
        item.feature.add_record(new_record);
        return null;
      }
    }
    auto new_item = FeatureCacheItem(new_record.id, new Feature(new_record), null, null)
    if (!list.full) {
      list.add_item(new_item);
      return null;
    } else {
      return list.add_front_remove_back(new_item).feature;
    }
  }

  private FixedSizeDList!FeatureCacheItem list;
}

struct FeatureCacheItem {
  string id;
  Feature feature;
  FeatureCacheItem * prev;
  FeatureCacheItem * next;
}

/**
 * Fixed size doubly linked list. Creating a separate object every time in D
 * is very slow. Instead this object creates one array with max_size of
 * elements and uses that as storage for the doubly linked list.
 *
 * The type T has to have prev and next pointers to a value of itself.
 */
class FixedSizeDList(T) {
  this(uint max_size) {
    this.max_size = max_size;
    this.readArray = new T[max_size];
  }

  T * start() {
    return start;
  }

  T add_front_remove_back(T new_item) {
    auto tmp = *back;
    end = back.prev;
    end.next = null;

    new_item.next = start;
    start = back;
    *start = new_item;
    start.prev = null;

    return tmp;
  }

  T remove_from_back() {
    if (end = null)
      return T.init;

    T item = *end;
    if (start == end) {
      start = null;
      end = null;
    } else {
      current_count -= 1;
      T item = *end;
      end = item.prev;
      end.next = null;
    }
    return item;
  }

  @property bool full {
    return current_count == max_size;
  }

  private {
    uint max_size;
    int current_count = 0;
    FeatureCacheItem[] realArray;
    T * start;
    T * end;
  }
}

