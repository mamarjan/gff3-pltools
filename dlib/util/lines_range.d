module util.lines_range;

import util.range_with_cache;

/**
 * This class represents a generic range of lines. The lines can come from
 * a file, from a string, etc.
 */

class LinesRange : RangeWithCache!string { }

