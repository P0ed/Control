const char MIDIDataClock = 0xF8;
const char MIDIDataStart = 0xFA;
const char MIDIDataContinue = 0xFB;
const char MIDIDataStop = 0xFC;

static UART *midiSerial;

static inline void MIDISetup() {
  if (midiSerial) return;
  midiSerial = new UART(digitalPinToPinName(A5), NC, NC, NC);
  midiSerial->begin(31250);
}

static inline void MIDIDeinit() {
  if (!midiSerial) return;
  midiSerial->flush();
  delete midiSerial;
  midiSerial = NULL;
}

static inline void MIDIClock() {
  if (!midiSerial) return;
  midiSerial->write(MIDIDataClock);
}

static inline void MIDIStart() {
  if (!midiSerial) return;
  midiSerial->write(MIDIDataStart);
}

static inline void MIDIStop() {
  if (!midiSerial) return;
  midiSerial->write(MIDIDataStop);
}

static inline void MIDISetSPP(short position) {
  if (!midiSerial) return;
  midiSerial->write(0xF2);
  midiSerial->write(position & 0xFF);
  midiSerial->write(position >> 8);
}
