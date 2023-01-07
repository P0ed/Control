struct Pattern {
  unsigned char count;
  long long bits;

  const static struct Pattern empty;

  bool isHighAtIndex(int idx) {
    return bits & 1 << (idx % count);
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
  const static struct Controls mute;
  const static struct Controls changePattern;
};

const struct Controls Controls::run = {1 << 0};
const struct Controls Controls::reset = {1 << 1};
const struct Controls Controls::mute = {1 << 2};
const struct Controls Controls::changePattern = {1 << 3};

bool operator &(Controls lhs, Controls rhs) {
  return lhs.bits & rhs.bits;
}

struct State {
  unsigned long lastTick;
  float clockBPM;
  Controls controls;
  char tick;
  unsigned long idx;
  Field field;
  Field pending;

  const static unsigned long maxIdx;
  const static char ticksPerClock;

  bool isAtStartOf(int ptnIdx) {
    return idx / 2 % field.patterns[ptnIdx].count == 0;
  }

  void nextStep(unsigned long time) {
    lastTick = time;
    tick = (tick + 1) % State::ticksPerClock;
    if (!tick) idx = (idx + 1) % State::maxIdx;
  }

  void reset() {
    lastTick = 0;
    idx = 0;
  }
};

const unsigned long State::maxIdx = 40320;    // 8!
const char State::ticksPerClock = 32;
