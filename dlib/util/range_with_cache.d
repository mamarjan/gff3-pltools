module util.range_with_cache;

/**
 * This class is a template for creating new ranges with caching of values.
 * Descendants only need to implement the abstract method next_item().
 */
class RangeWithCache(T) {
  /**
   * Returns the next item in range.
   */
  @property T front() {
    if (cache is null)
      cache = next_item();
    return cache;
  }

  /**
   * Pops the next item of the range.
   */
  void popFront() {
    if (cache is null)
      next_item();
    cache = next_item();
  }

  /**
   * Return true if no more items left in the range.
   */
  @property bool empty() {
    if (cache is null)
      return (cache = next_item()) is null;
    else
      return false;
  }

  /**
   * Descendants need to implement this class. It should return
   * the next item in range every time it's called.
   */
  abstract protected T next_item();

  private T cache;
}

