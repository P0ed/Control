struct Pattern {
  short bits;

  const static struct Pattern straight;

  bool isHighAtIndex(int idx) {
    return bits & 1 << idx;
  }
};

const struct Pattern Pattern::straight = {
  .bits = 1 << 0 | 1 << 4 | 1 << 8 | 1 << 12
};

struct Controls {
  short bits;

  const static struct Controls mute;
  const static struct Controls nextPattern;
};

const struct Controls Controls::mute = {1 << 0};
const struct Controls Controls::nextPattern = {1 << 1};

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
