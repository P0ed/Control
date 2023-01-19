bool isHigh(int value, int bit) {
  return value & 1 << bit;
}

struct Pattern {
  unsigned char count;
  long long bits;

  const static struct Pattern empty;

  bool isHighAtIndex(int idx) {
    return isHigh(bits, idx % count);
  }
};

const struct Pattern Pattern::empty = {
  .count = 16,
  .bits = 0
};

struct Field {
  Pattern patterns[4];

  const static struct Field empty;
};

const struct Field Field::empty = {
  .patterns = { Pattern::empty, Pattern::empty, Pattern::empty, Pattern::empty }
};

struct Controls {
  short bits;

  bool isRunning() { return bits & Controls::run.bits; }
  bool isReset() { return bits & Controls::reset.bits; }
  bool isChangePattern() { return bits & Controls::changePattern.bits; }

  const static struct Controls run;
  const static struct Controls reset;
  const static struct Controls changePattern;
};

const struct Controls Controls::run = {1 << 0};
const struct Controls Controls::reset = {1 << 1};
const struct Controls Controls::changePattern = {1 << 2};

bool operator &(Controls lhs, Controls rhs) {
  return lhs.bits & rhs.bits;
}

struct State {
  bool isRunning;
  unsigned long nextTick;
  float clockBPM;
  Controls controls;
  unsigned long idx;
  Field field;
  Field pending;

  const static unsigned long maxIdx;

  bool isAtStartOf(int ptnIdx) {
    return idx % 4 == 0 && (idx >> 2) % field.patterns[ptnIdx].count == 0;
  }

  unsigned long oneTick() {
    return 1000000 * 60 / clockBPM / 4 / 4;
  }

  bool shouldTick(unsigned long t) {
    return t >= nextTick && (t & 1 << 31) == (nextTick & 1 << 31);
  }

  int tick() {
    if (isAtStartOf(0)) field = pending;
    if (controls.isReset()) reset();
    bool clock = (idx % 4) / 2 == 0;

    int bits = 1 << 0 | clock << 1;
    for (int i = 0; i < 4; i++) bits |= (field.patterns[i].isHighAtIndex(idx >> 2) && (idx % 4) == 0) << (i + 2);

    nextTick += oneTick();
    idx = (idx + 1) % State::maxIdx;

    return bits;
  }

  void start(unsigned long t) {
    nextTick = t;
    isRunning = true;
  }

  void reset() {
    isRunning = false;
    idx = 0;
  }
};

const unsigned long State::maxIdx = 40320 << 2;
