#include "midi.h"

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
      case 1: return isHigh(bits, (idx / 6) % (int)count) && (idx % 6) == 0;
      case 2: return isHigh(bits, (idx / 6) % (int)count) && (idx % 6 / 3) == 0;
      case 3: return isHigh(bits, (idx / 6) % (int)count);
    }
  }
};

const struct Pattern Pattern::empty = {
  .bits = 0,
  .count = 16,
  .options = 0
};

struct QuadPattern {
  Pattern patterns[4];
  
  const static struct QuadPattern empty;
};

const struct QuadPattern QuadPattern::empty = {
  .patterns = { Pattern::empty, Pattern::empty, Pattern::empty, Pattern::empty }
};

struct Controls {
  float bpm;
  short bits;

  bool contains(int shape) { return bits & (1 << shape); }
  bool isRunning() { return bits & 1 << 4; }
  bool isReset() { return bits & 1 << 5; }
  bool isChangePattern() { return bits & 1 << 6; }
  bool isMIDI() { return bits & 1 << 7; }
};

struct State {
  bool isRunning;
  unsigned long nextTick;
  Controls controls;
  int idx;
  QuadPattern quad;
  QuadPattern pending;

  int trigs;
  unsigned long trigsLifetime;

  bool midi;

  const static int maxIdx;

  bool isAtStartOf(int ptnIdx) {
    return idx % 6 == 0 && (idx / 6) % quad.patterns[ptnIdx].count == 0;
  }

  unsigned long oneTick() {
    const unsigned long regular = 1000000 * 60 / controls.bpm / 4 / 6;
    return regular;
    // unsigned long dt = regular * controls.swing / 2;
    // bool isEven = idx / 6 % 2 == 0;
    // return isEven ? regular + dt : regular - dt;
  }

  bool shouldTick(unsigned long t) {
    return t >= nextTick && (t & 1 << 31) == (nextTick & 1 << 31);
  }
  bool hasExpiredTrigs(unsigned long t) {
    return trigs && t >= trigsLifetime && (t & 1 << 31) == (trigsLifetime & 1 << 31);
  }

  int tick(unsigned long t) {
    if (isAtStartOf(0)) quad = pending;
    if (controls.isReset()) reset();

    bool clock = (idx % 6 / 2) == 0;
    int bits = 1 << 4 | clock << 5;
    trigs = 0;
    for (int i = 0; i < 4; i++) {
      bool isHigh = quad.patterns[i].isHighAtIndex(idx);
      trigs |= (isHigh && quad.patterns[i].options == 0) << i;
      bits |= isHigh << i;
    }

    if (trigs) trigsLifetime = t + 15000;

    nextTick += oneTick();
    idx = (idx + 1) % State::maxIdx;

    MIDIClock();

    return bits;
  }

  int consumeTrigs() {
    int tgs = trigs;
    trigs = 0;
    return tgs;
  }

  void start(unsigned long t) {
    nextTick = t;
    isRunning = true;
    MIDIStart();
  }

  void stop() {
    isRunning = false;
    reset();
    MIDIStop();
  }

  void reset() {
    idx = 0;
    trigs = 0;
    if (isRunning) MIDISetSPP(0);
  }
};

State state = {
  .isRunning = false,
  .nextTick = 0,
  .controls = { .bpm = 0, .bits = 0 },
  .idx = 0,
  .quad = QuadPattern::empty,
  .pending = QuadPattern::empty,
  .trigs = 0,
  .trigsLifetime = 0,
  .midi = false
};

const int State::maxIdx = 40320 * 8 * 6;
