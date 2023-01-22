bool isHigh(long long value, int bit) {
  return value & (1LL << bit);
}

struct Pattern {
  long long bits;
  char count;
  char options;

  const static struct Pattern empty;

  bool isHighAtIndex(int idx) {
    switch (options) {
      case 0:
      case 1: return isHigh(bits, (idx / 4) % (int)count) && (idx % 4) == 0;
      case 2: return isHigh(bits, (idx / 4) % (int)count) && (idx / 2 % 2) == 0;
      case 3: return isHigh(bits, (idx / 4) % (int)count);
    }
  }
};

const struct Pattern Pattern::empty = {
  .bits = 0,
  .count = 16
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

struct Clock {
  float bpm;
  float swing;
};

struct State {
  bool isRunning;
  unsigned long nextTick;
  Clock clock;
  Controls controls;
  int idx;
  Field field;
  Field pending;

  int trigs;
  unsigned long trigsLifetime;

  const static int maxIdx;

  bool isAtStartOf(int ptnIdx) {
    return idx % 4 == 0 && (idx / 4) % field.patterns[ptnIdx].count == 0;
  }

  unsigned long oneTick() {
    unsigned long regular = 1000000 * 60 / clock.bpm / 4 / 4;
    unsigned long dt = regular * clock.swing / 2;
    bool isEven = idx / 4 % 2 == 0;
    return isEven ? regular + dt : regular - dt;
  }

  bool shouldTick(unsigned long t) {
    return t >= nextTick && (t & 1 << 31) == (nextTick & 1 << 31);
  }
  bool hasExpiredTrigs(unsigned long t) {
    return trigs && t >= trigsLifetime && (t & 1 << 31) == (trigsLifetime & 1 << 31);
  }

  int tick(unsigned long t) {
    if (isAtStartOf(0)) field = pending;
    if (controls.isReset()) reset();

    bool clock = (idx % 4) / 2 == 0;
    int bits = 1 << 0 | clock << 1;
    int tgs = 0;
    for (int i = 0; i < 4; i++) {
      bool isHigh = field.patterns[i].isHighAtIndex(idx);
      tgs |= (isHigh && field.patterns[i].options == 0) << (i + 2);
      bits |= isHigh << (i + 2);
    }

    trigs = tgs;
    if (tgs) trigsLifetime = t + 15000;

    nextTick += oneTick();
    idx = (idx + 1) % State::maxIdx;

    return bits;
  }

  int consumeTrigs() {
    int t = trigs;
    trigs = 0;
    return t;
  }

  void start(unsigned long t) {
    nextTick = t;
    isRunning = true;
  }

  void reset() {
    isRunning = false;
    idx = 0;
    trigs = 0;    
  }
};

State state = {
  .isRunning = false,
  .nextTick = 0,
  .clock = { .bpm = 0, .swing = 0 },
  .controls = { 0 },
  .idx = 0,
  .field = Field::empty,
  .pending = Field::empty,
  .trigs = 0,
  .trigsLifetime = 0
};

const int State::maxIdx = 40320 << 5;
