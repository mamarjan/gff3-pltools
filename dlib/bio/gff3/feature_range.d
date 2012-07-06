module bio.gff3.feature_range;

import bio.gff3.feature, bio.gff3.record, bio.gff3.validation;
import util.range_with_cache, util.dlist, util.string_hash;

/**
 * FeatureRange is a range of features from a range of records.
 * Use front, popFront() and empty for traversal.
 */
class FeatureRange : RangeWithCache!Feature {
  /**
   * Constructor of a range of features.
   * Params:
   *     records =             A range of records.
   *     feature_cache_size =  Cache size for features.
   *     link_features =       The parser will link features into parent-child relationships
   *                           if this parameter is true.
   */
  this(RangeWithCache!Record records, size_t feature_cache_size = 1000, bool link_features = false) {
    this.records = records;
    this.data = new FeatureQueue(feature_cache_size, link_features);
    this.link_features = link_features;
  }

  protected Feature next_item() {
    Feature feature;
    while((!records.empty) && (feature is null)) {
      feature = data.add_record(records.front);
      records.popFront();
    }
    if ((feature is null) && (records.empty)) {
      feature = data.remove_from_back();
    }
    return feature;
  }

  private {
    RangeWithCache!Record records;
    FeatureQueue data;
    bool link_features = false;
  }
}

private:

/**
 * Keeps the last max_size features in an array. That way there is
 * some buffer space for records which are at most max_size records
 * far from the last record which is part of the same feature.
 */
class FeatureQueue {
    this(size_t max_size = 1000, bool link_features = false) {
    this.max_size = max_size;
    this.link_features = link_features;
    this.dlist = new DList!FeatureQueueItem();
    this.list = new FeatureQueueItem[max_size];
  }

  FeatureQueueItem * find(string id) {
    if (id != null) {
      if (id in lookup_list)
        return lookup_list[id];
    }
    return null;
  }


  /**
   * If the feature with the same ID is already in the cache, this method
   * adds the new record to that feature and returns null. Otherwise it
   * adds a new feature to the cache and removes and returns the oldest
   * feature in the cache.
   */
  Feature add_record(Record new_record) {
    FeatureQueueItem * item = find(new_record.id);
    if (item !is null) {
      item.feature.add_record(new_record);
      dlist.move_to_front(item);
      return null;
    }
    auto new_item = FeatureQueueItem(hash(new_record.parent), new Feature(new_record), null, null);
    Feature result;
    if (!cache_full) {
      add_new_item(new_item);
      result = null;
    } else {
      result = replace_and_return_oldest(new_item);
    }
    if (link_features) {
      check_for_children_and_parents(result);
    }
    return result;
  }

  /**
   * Call this method when there are no more records in the data
   * source. Removes and returns the oldest feature in the cache.
   */
  Feature remove_from_back() {
    auto item = dlist.remove_back();
    if (item !is null) {
      lookup_list.remove(item.feature.id);
      if (link_features) {
        check_for_children_and_parents(item.feature);
      }
      return item.feature;
    } else {
      return null;
    }
  }

  private {
    void add_new_item(FeatureQueueItem new_item) {
      list[current_size] = new_item;
      dlist.insert_front(&(list[current_size]));
      lookup_list[new_item.feature.id] = &(list[current_size]);
      current_size++;
    }

    Feature replace_and_return_oldest(FeatureQueueItem new_item) {
      auto item = dlist.remove_back();
      auto feature = item.feature;
      *item = new_item;
      dlist.insert_front(item);
      lookup_list.remove(feature.id);
      lookup_list[new_item.feature.id] = item;
      return feature;
    }

    @property bool cache_full() { return current_size == max_size; }

    void check_for_children_and_parents(Feature feature) {
      if (feature !is null) {
        bool search_for_parent = ((feature.parent_feature is null) &&
                                  (feature.parent !is null));
        bool search_for_children = feature.id !is null;
        // Search for parents or children
        if (search_for_parent) {
          if (feature.parent in lookup_list)
            feature.set_parent_feature(lookup_list[feature.parent].feature);
        }
        if (search_for_children) {
          int feature_hash = hash(feature.id);
          int parent_hash = hash(feature.parent);
          FeatureQueueItem * item = dlist.first;
          while((item !is null) && search_for_children) {
            if (search_for_children) {
              if (item.parent_hash == feature_hash) {
                if (item.feature.parent == feature.id) {
                  item.feature.set_parent_feature(feature);
                  feature.add_child(item.feature);
                }
              }
            }
            item = item.next;
          }
        }
      }
    }

    DList!FeatureQueueItem dlist;
    FeatureQueueItem[] list;
    FeatureQueueItem*[string] lookup_list;

    size_t max_size;
    bool link_features = false;
    uint current_size = 0;
  }
}

struct FeatureQueueItem {
  int parent_hash;
  Feature feature;

  FeatureQueueItem * prev;
  FeatureQueueItem * next;
}

import std.stdio, std.conv;
import bio.gff3.record_range;
import util.split_into_lines;

unittest {
  writeln("Testing FeatureRange...");

  // Test with only one feature
  string test_records = ".\t.\t.\t.\t.\t.\t.\t.\tID=1;value=1\n" ~
                        ".\t.\t.\t.\t.\t.\t.\t.\tID=1;value=2\n" ~
                        ".\t.\t.\t.\t.\t.\t.\t.\tID=1;value=3";
  auto records = new RecordRange!SplitIntoLines(new SplitIntoLines(test_records));
  auto features = new FeatureRange(records);
  assert(features.front.id == "1");
  features.popFront();
  assert(features.empty == true);

  // Test with two features
  test_records = ".\t.\t.\t.\t.\t.\t.\t.\tID=1;value=1\n" ~
                 ".\t.\t.\t.\t.\t.\t.\t.\tID=1;value=2\n" ~
                 ".\t.\t.\t.\t.\t.\t.\t.\tID=1;value=3\n" ~
                 ".\t.\t.\t.\t.\t.\t.\t.\tID=2;value=1\n" ~
                 ".\t.\t.\t.\t.\t.\t.\t.\tID=2;value=2\n" ~
                 ".\t.\t.\t.\t.\t.\t.\t.\tID=2;value=3\n";
  records = new RecordRange!SplitIntoLines(new SplitIntoLines(test_records));
  features = new FeatureRange(records);
  assert(features.empty == false);
  assert(features.front.id == "1");
  assert(features.front.records.length == 3);
  features.popFront();
  assert(features.empty == false);
  assert(features.front.id == "2");
  assert(features.front.records.length == 3);
  features.popFront();
  assert(features.empty == true);

  // Test with more then the default number of features in cache
  foreach(i; 3..1003) {
    foreach(j; 1..4) {
      test_records ~= ".\t.\t.\t.\t.\t.\t.\t.\tID=" ~ to!string(i) ~ ";value=" ~ to!string(j) ~ "\n";
    }
  }
  records = new RecordRange!SplitIntoLines(new SplitIntoLines(test_records));
  features = new FeatureRange(records);
  assert(features.empty == false);
  foreach(i; 1..1003) {
    assert(features.empty == false);
    assert(features.front.id == to!string(i));
    assert(features.front.records.length == 3);
    features.popFront();
  }
  assert(features.empty == true);

  // Retest with a smaller feature cache
  records = new RecordRange!SplitIntoLines(new SplitIntoLines(test_records));
  features = new FeatureRange(records, 97);
  assert(features.empty == false);
  foreach(i; 1..1003) {
    assert(features.empty == false);
    assert(features.front.id == to!string(i));
    assert(features.front.records.length == 3);
    features.popFront();
  }
  assert(features.empty == true);

  // Test parent-child linking
  test_records = ".\t.\t.\t.\t.\t.\t.\t.\tID=1\n" ~
                 ".\t.\t.\t.\t.\t.\t.\t.\tID=2;Parent=1\n" ~
                 ".\t.\t.\t.\t.\t.\t.\t.\tID=3;Parent=1\n" ~
                 ".\t.\t.\t.\t.\t.\t.\t.\tID=4;Parent=2\n" ~
                 ".\t.\t.\t.\t.\t.\t.\t.\tID=4;Parent=2\n" ~
                 ".\t.\t.\t.\t.\t.\t.\t.\tID=5;Parent=3\n";
  records = new RecordRange!SplitIntoLines(new SplitIntoLines(test_records));
  features = new FeatureRange(records, 10, true);
  assert(features.empty == false);
  uint count_features = 0;
  foreach(feature; features) {
    if (feature.id == "1") {
      assert(feature.parent_feature is null);
      assert(features.front.children.length == 2);
    } else if (feature.id == "2") {
      assert(feature.parent_feature !is null);
      assert(feature.parent_feature.id == "1");
      assert(feature.children.length == 1);
      assert(feature.children[0].id == "4");
    } else if (feature.id == "3") {
      assert(feature.parent_feature !is null);
      assert(feature.parent_feature.id == "1");
      assert(feature.children.length == 1);
      assert(feature.children[0].id == "5");
    } else if (feature.id == "4") {
      assert(feature.parent_feature !is null);
      assert(feature.parent_feature.id == "2");
      assert(feature.children.length == 0);
    } else if (feature.id == "5") {
      assert(feature.parent_feature !is null);
      assert(feature.parent_feature.id == "3");
      assert(feature.children.length == 0);
    }
    count_features++;
  }
  assert(count_features == 5);
}

