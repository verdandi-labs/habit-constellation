class SeededRng {
  int _s;
  SeededRng(String seed) : _s = _hash(seed);

  static int _hash(String s) {
    int h = 5381;
    for (int i = 0; i < s.length; i++) h = ((h << 5) + h) ^ s.codeUnitAt(i);
    return h >>> 0;
  }

  double next() {
    _s = (_s + 0x6d2b79f5) & 0xFFFFFFFF;
    int t = (_s ^ (_s >> 15)) * (1 | _s) & 0xFFFFFFFF;
    t = (t + (t ^ (t >> 7)) * (61 | t)) & 0xFFFFFFFF;
    return ((t ^ (t >> 14)) & 0xFFFFFFFF) / 4294967296.0;
  }
}
