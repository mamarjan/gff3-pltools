module util.string_hash;

/**
 * A basic hash function for strings and char arrays. The algorithm is the
 * djb2 algorithm from this web page:
 *
 * http://www.cse.yorku.ca/~oz/hash.html
 */
int hash(Char)(Char[] str) {
  uint hash = 5381;
  foreach(c; str)
    hash = ((hash << 5) + hash) + cast(byte)c;

  return hash;
}

