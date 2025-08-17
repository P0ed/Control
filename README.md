# Control

A quad 64-bit gate sequencer system with clock and gamepad controls, featuring an Arduino Nano 33 BLE hardware controller and iOS companion app.

## Overview

Control is a sophisticated sequencing system that combines hardware and software to create a powerful pattern-based gate sequencer. The system consists of two main components:

- **Arduino Hardware**: Arduino Nano 33 BLE running the BLE sequencer firmware
- **iOS App**: SwiftUI-based control interface with gamepad support

## Features

### Hardware (Arduino)
- **64-bit Pattern Sequencing**: Advanced pattern generation and playback
- **Dual Output Modes**: Analog gate outputs or MIDI transmission
- **BLE Connectivity**: Wireless communication with iOS app
- **Real-time Clock**: Precise timing control with configurable BPM
- **7-Pin GPIO Control**: Direct hardware gate outputs

### iOS App
- **Wireless Control**: BLE connection to Arduino hardware
- **Gamepad Integration**: Full gamepad controller support
- **Pattern Visualization**: Real-time pattern display and editing
- **Transport Controls**: Play/pause/stop with BPM adjustment
- **Bank Management**: Multiple pattern banks with 64-bit patterns each
- **Euclidean Rhythms**: Built-in euclidean pattern generation
- **Battery Monitoring**: Controller battery level display
- **Duty Cycle Control**: Adjustable gate timing

## Architecture

### Arduino Component (`Arduino/BLESequencer/`)
- **BLESequencer.ino**: Main firmware with sequencer logic
- **ble.h**: Bluetooth Low Energy communication
- **midi.h**: MIDI output functionality
- **structs.h**: Data structures for patterns and state

### iOS Component (`iOS/Control/`)
- **SwiftUI Interface**: Modern iOS app with reactive UI
- **BLE Communication**: Wireless connection to Arduino
- **Pattern Management**: Advanced pattern editing and storage
- **Gamepad Support**: Full controller integration
- **Real-time Visualization**: Live pattern and status display

## Hardware Requirements

- Arduino Nano 33 BLE
- iOS device (iPhone/iPad) with iOS 14.0+
- Gamepad

## Installation

### Arduino Setup
1. Install Arduino IDE with Arduino Nano 33 BLE board support
2. Install required libraries:
   - ArduinoBLE
   - Mbed OS
3. Upload `Arduino/BLESequencer/BLESequencer.ino` to your Arduino Nano 33 BLE

### iOS Setup
1. Open `iOS/Control.xcodeproj` in Xcode
2. Build and install on your iOS device
3. Ensure Bluetooth permissions are granted

## Usage

1. **Power on** the Arduino Nano 33 BLE
2. **Launch** the Control app on your iOS device
3. **Connect** via Bluetooth (☮︎ symbol indicates connection)
4. **Control playback** using the app interface or connected gamepad
5. **Adjust patterns** using the pattern editor
6. **Switch modes** between analog gate output and MIDI transmission

### Controls
- **Transport**: Play/pause/stop sequencer
- **BPM**: Adjust playback speed
- **Pattern Selection**: Navigate between banks and patterns
- **Duty Cycle**: Adjust gate timing
- **Euclidean**: Generate euclidean rhythm patterns
- **Output Mode**: Toggle between analog and MIDI output

## Technical Details

### Communication Protocol
The system uses BLE (Bluetooth Low Energy) for wireless communication between the iOS app and Arduino hardware. Custom characteristics handle:
- Pattern data transmission
- Control state synchronization
- Real-time parameter updates

### Pattern Format
Patterns are stored as 64-bit values, allowing for complex rhythmic sequences with precise timing control.

### Clock Synchronization
The Arduino maintains precise timing using microsecond-resolution clocks, ensuring stable sequencer performance.

## Development

### Building from Source
- **Arduino**: Use Arduino IDE 1.8.x or newer
- **iOS**: Requires Xcode 12.0+ and iOS 14.0+ deployment target

![camphoto_1903590565](https://github.com/user-attachments/assets/b153df51-e88c-4c13-86eb-d00f3a7ba66b)
![photo_2025-08-15 13 45 03](https://github.com/user-attachments/assets/ab89ee23-fff1-4eee-9d38-ba6c7cd4386b)
![photo_2025-08-15 13 45 05](https://github.com/user-attachments/assets/62cfe0b9-e525-482b-908f-4142e535905e)
