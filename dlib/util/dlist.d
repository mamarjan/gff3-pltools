module util.dlist;

/**
 * Basic doubly linked list implementation with pointers.
 * The type T has to have prev and next pointers to a value of itself.
 */
class DList(T) {
  /**
   * Return pointer to the first item in the list.
   */
  @property T * first() {
    return start;
  }

  /**
   * Return pointer to the last item in the list.
   */
  @property T * last() {
    return end;
  }

  /**
   * Add item to the front of the list.
   */
  void insert_front(T * new_item) {
    if (start is null) {
      new_item.prev = null;
      new_item.next = null;
      start = new_item;
      end = new_item;
    } else {
      new_item.prev = null;
      new_item.next = start;
      start.prev = new_item;
      start = new_item;
    }
  }

  /**
   * Remove item from the list, wherever it is.
   */
  void remove(T * item) {
    if (start == item) {
      remove_front();
    } else if (end == item) {
      remove_back();
    } else {
      auto after = item.next;
      auto before = item.prev;
      before.next = item.next;
      after.prev = item.prev;
    }
  }

  /**
   * Remove and return the first item in the list.
   */
  T * remove_front() {
    T * item;
    if (start == null) {
      item = null;
    } else if (start == end) {
      item = start;
      start = null;
      end = null;
    } else {
      item = start;
      start = item.next;
      start.prev = null;
    }
    return item;
  }

  /**
   * Remove and return the last item in the list.
   */
  T * remove_back() {
    T * item;
    if (end is null) {
      item = null;
    } else if (start == end) {
      item = end;
      start = null;
      end = null;
    } else {
      item = end;
      end = item.prev;
      end.next = null;
    }
    return item;
  }

  private {
    T * start = null;
    T * end = null;
  }
}

import std.stdio;

unittest {
  writeln("Testing DList...");

  struct TestItem {
    int value;
    TestItem * next;
    TestItem * prev;
  }

  TestItem item1 = TestItem(1, null, null);
  TestItem item2 = TestItem(2, null, null);
  TestItem item3 = TestItem(3, null, null);

  auto list = new DList!TestItem();
  assert(list.first is null);
  assert(list.last is null);

  list.insert_front(&item1);
  assert(list.first !is null);
  assert(list.last !is null);
  assert(list.first.value == 1);
  assert(list.last.value == 1);
  assert(list.remove_front().value == 1);
  assert(list.first is null);
  assert(list.last is null);

  list.insert_front(&item3);
  list.insert_front(&item2);
  list.insert_front(&item1);
  assert(list.first.value == 1);
  assert(list.first.prev is null);
  assert(list.first.next.value == 2);
  assert(list.first.next.prev.value == 1);
  assert(list.first.next.next.value == 3);
  assert(list.last.value == 3);
  assert(list.last.next is null);
  assert(list.last.prev.prev.value == 1);
  assert(list.last.prev.next.value == 3);

  assert(list.remove_front().value == 1);
  assert(list.remove_front().value == 2);
  assert(list.remove_front().value == 3);
  assert(list.remove_front() is null);

  list.insert_front(&item3);
  list.insert_front(&item2);
  list.insert_front(&item1);
  assert(list.remove_back().value == 3);
  assert(list.remove_back().value == 2);
  assert(list.remove_back().value == 1);
  assert(list.remove_back() is null);

  list.insert_front(&item3);
  list.insert_front(&item2);
  list.insert_front(&item1);
  list.remove(list.first.next);
  assert(list.first.value == 1);
  assert(list.first.next.value == 3);
  assert(list.last.value == 3);
  assert(list.last.prev.value == 1);
  list.remove(list.last);
  assert(list.first.value == 1);
  assert(list.first.next is null);
  assert(list.last.value == 1);
  assert(list.last.prev is null);
  list.remove(list.first);
  assert(list.first is null);
  assert(list.last is null);
}

