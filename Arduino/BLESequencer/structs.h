struct Pattern {
  unsigned char count;
  long long bits;

  const static struct Pattern empty;

  bool isHighAtIndex(int idx) {
    return bits & 1 << idx;
  }
};

const struct Pattern Pattern::empty = {
  .count = 16,
  .bits = 0
};

struct Controls {
  short bits;

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
  char idx;
  Pattern pattern;
  Pattern nextPattern;
  float valueA;
  float valueB;
  Controls controls;
};
