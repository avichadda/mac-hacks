# Mac Hacks

A collection of unusual things you can build by combining a Mac's sensors,
hardware, system events, and Apple ecosystem features.

This repository also includes a native macOS app for browsing and searching the
catalog. On first launch, a welcome screen explains the catalog's access labels
and safety guidance. You can reopen it later from **Help > Show Welcome**.

The app is a small hack store rather than a documentation browser. Tap a
working hack, install it inside Mac Hacks, and then select **Use Hack**:

- A battery and charging monitor powered by IOPowerSources.
- A thermal-pressure monitor powered by `ProcessInfo.thermalState`.
- A Force Touch pressure pad powered by AppKit pressure events.
- A live lid-angle gauge using the MacBook's undocumented HID sensor.
- A vibration and knock detector using the undocumented Apple SPU
  accelerometer.
- A native TuneDrop installer and runner for media the user is authorized to
  archive.

## Run the app

The app requires macOS 13 or newer and the Swift toolchain included with Xcode
or the Xcode Command Line Tools.

```sh
swift run
```

## Create the DMG

Run the packaging script from the repository root:

```sh
chmod +x scripts/build-dmg.sh
./scripts/build-dmg.sh
```

This creates:

- `dist/Mac Hacks.app`
- `dist/Mac Hacks-1.0.0.dmg`

The DMG build generates a branded app icon and a custom drag-to-Applications
installer window. The artwork is generated locally by
`scripts/generate-dmg-assets.swift`.

The default build uses ad-hoc signing, which is suitable for local testing. To
share the app without macOS Gatekeeper warnings, sign it with an Apple
Developer ID certificate:

```sh
CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
BUNDLE_ID="com.yourname.machacks" \
VERSION="1.0.0" \
./scripts/build-dmg.sh
```

Then submit and staple the DMG with Apple's notary service:

```sh
xcrun notarytool submit "dist/Mac Hacks-1.0.0.dmg" \
  --keychain-profile "notary-profile" --wait
xcrun stapler staple "dist/Mac Hacks-1.0.0.dmg"
```

> [!NOTE]
> **Public** ideas use supported Apple APIs. **Undocumented** ideas usually use
> reverse-engineered IOKit/HID/SMC interfaces, may require extra permissions,
> may work only on particular Mac models, and can break after a macOS update.

## Physical interactions

| Idea | What it could do | Access |
| --- | --- | --- |
| Lid-angle controller | Change volume or screen brightness as the lid moves, use the lid as a game controller, or trigger an action at a chosen angle | **Undocumented** HID sensor; available only on some MacBooks |
| Knock or tap gestures | Detect single, double, or triple knocks on the MacBook or desk and run Shortcuts, control media, mute a call, or lock the screen | **Undocumented** accelerometer access; model-dependent Apple silicon support |
| Tilt controller | Steer a game, pan a map, or scroll by gently tilting the MacBook | **Undocumented** accelerometer/IMU access |
| Pick-up detection | Lock the screen or pause media when the laptop is lifted from a desk | **Undocumented** accelerometer/IMU access |
| Vibration alarm | Notify you when a desk, drawer, door, or nearby machine vibrates | **Undocumented** accelerometer access |
| Earthquake or washing-machine logger | Record long-running vibration data and graph detected motion | **Undocumented** accelerometer access |
| Force-click instrument | Turn trackpad pressure into velocity, pitch bend, brush size, or throttle | **Public** AppKit pressure events |
| Trackpad scale experiment | Estimate the force applied to a Force Touch trackpad and calibrate it against known weights | **Public** pressure events, but not a real certified scale |
| Trackpad drawing tablet | Use touch position, pressure, and finger count for drawing or music controls | Mixed; pressure is public, raw multitouch commonly relies on private interfaces |
| Mouse-shake gestures | Detect circles, flicks, or edge bumps to launch commands | **Public** mouse events; Accessibility permission may be needed globally |
| Sudden-removal protection | Pause disk-heavy work when abrupt motion is detected | Legacy Intel MacBooks exposed a Sudden Motion Sensor; modern support varies |

## Light, camera, and presence

| Idea | What it could do | Access |
| --- | --- | --- |
| Ambient-light automation | Switch themes, adjust smart lights, or change display warmth based on room light | **Undocumented** ambient-light sensor access |
| Flashlight signal receiver | Blink a phone flashlight at the Mac to send simple commands | **Public** camera capture; Camera permission required |
| Hand-gesture controls | Control slides or media with hand poses | **Public** camera + Vision/Core ML; Camera permission required |
| Face-distance reminder | Warn when you sit too close to the screen | **Public** camera + Vision; Camera permission required |
| Look-away pause | Pause video when no face is visible or when the user leaves | **Public** camera + Vision; Camera permission required |
| Webcam motion detector | Record or notify when movement occurs in view | **Public** AVFoundation/Vision; respect privacy and consent |
| Camera-cover detector | Warn that the camera is covered before joining a call | **Public** camera frames; Camera permission required |
| Screen-color room lighting | Sample on-screen colors and mirror them to HomeKit/Matter lights | **Public** ScreenCaptureKit; Screen Recording permission required |
| Presence via Bluetooth | Lock, unlock, or change Focus when a paired phone/watch approaches or leaves | CoreBluetooth is public, but reliable proximity is approximate |

## Audio and vibration

| Idea | What it could do | Access |
| --- | --- | --- |
| Clap or snap shortcuts | Run an action after a clap pattern | **Public** microphone capture; Microphone permission required |
| Whistle remote | Map recognized tones to media or presentation controls | **Public** microphone + audio analysis |
| Ultrasonic data link | Exchange tiny messages between nearby devices using near-ultrasonic sound | **Public** audio APIs; hardware and hearing-safety limitations apply |
| Room-noise automation | Enable Focus, lower notification sounds, or show a noise alert | **Public** microphone capture; avoid storing raw audio |
| Keyboard-sound activity detector | Infer that someone is typing without recording key events | **Public** audio capture, but privacy-sensitive and imprecise |
| Speaker-to-accelerometer experiment | Play frequency sweeps and measure chassis vibration/resonance | Public audio output + **undocumented** accelerometer access |
| Audio spectrum visualizer in the menu bar | Show microphone or system-audio frequency activity | Public microphone APIs or ScreenCaptureKit for system audio |

## Power, temperature, and performance

| Idea | What it could do | Access |
| --- | --- | --- |
| Charging chime or automation | Trigger actions when power is connected, removed, or charging completes | **Public** IOPowerSources |
| Battery-health dashboard | Track cycles, capacity, charge rate, and time on battery | Basic data is public; deeper battery details may be undocumented |
| Charge-level smart plug | Turn a smart plug off at 80% and back on at a lower threshold | Battery status + HomeKit/Matter or a vendor API |
| Thermal-state automation | Pause builds, reduce concurrency, or enable a cooling scene when the Mac gets hot | **Public** `ProcessInfo.thermalState` |
| Per-sensor temperature monitor | Display CPU/GPU/SSD temperatures and fan behavior | **Undocumented** SMC/IOKit access |
| Fan-controlled music visual | Map fan speed or temperature to lights, animation, or sound | **Undocumented** SMC access |
| Energy-cost tracker | Combine power-source telemetry with local electricity prices | Power data availability varies; external smart-plug data is more accurate |
| Battery motion alarm | On battery, sound an alarm when a closed or sleeping MacBook is moved | Model- and sleep-state-dependent; likely undocumented |

## Display, keyboard, and system events

| Idea | What it could do | Access |
| --- | --- | --- |
| Notch companion | Put meters, media controls, timers, or a drop target around the display notch | **Public** AppKit/SwiftUI display geometry |
| Menu-bar hardware visualizer | Animate CPU, network, battery, microphone, or motion data in the menu bar | Mostly public; sensor choice determines support |
| Keyboard-backlight notifications | Flash or pulse the keyboard backlight for alerts | Usually **undocumented** and model-dependent |
| Caps Lock as a mode switch | Use Caps Lock or another key as a Hyper key for app-specific shortcuts | Event taps/key remapping; Input Monitoring permission may be needed |
| Screen-edge actions | Throw the pointer into a corner or screen edge to run custom actions | **Public** event monitoring; Accessibility permission may be needed |
| Window-position automations | Trigger actions when a window is moved to a display, side, or zone | Accessibility API; Accessibility permission required |
| Screenshot watcher | OCR a new screenshot, rename it, redact secrets, or file it automatically | **Public** file events + Vision |
| USB insertion actions | Start backup, open a workspace, or change settings for a specific device | **Public** Disk Arbitration/IOKit notifications |
| Headphone-jack or audio-route actions | Launch a music app, change EQ, or mute speakers when the route changes | **Public** Core Audio |
| Network-location modes | Change defaults, mount shares, or enable Focus based on Wi-Fi/network changes | Public networking APIs; SSID access can be restricted |

## Apple ecosystem combinations

| Idea | What it could do | Access |
| --- | --- | --- |
| Watch/phone proximity lock | Lock the Mac when your personal device leaves and prepare it when you return | Bluetooth/UWB capabilities and background behavior are limited |
| Continuity Camera machine vision | Use an iPhone camera as a movable sensor for object or document recognition | **Public** Continuity Camera + AVFoundation where supported |
| AirPods head-gesture controls | React to supported AirPods head gestures in compatible app contexts | Availability depends on Apple's current public APIs and hardware |
| AirPods motion experiments | Use headphone motion to control spatial audio or an app | **Public** Core Motion headphone APIs on supported AirPods |
| Handoff clipboard workflow | Detect copied content locally and route it into an automation | Pasteboard APIs are public; Universal Clipboard itself is not programmable |
| Shortcuts hardware bridge | Turn any sensor event into a Shortcut, AppleScript, URL scheme, or shell command | Shortcuts/Apple Events are public; automation permissions may apply |
| Find My-style desk status | Combine device presence and Mac state to show whether a workspace is occupied | Build with consent; Find My data itself has no general-purpose public API |

## Network and radio experiments

| Idea | What it could do | Access |
| --- | --- | --- |
| Wi-Fi signal mapper | Walk around and build a rough signal-strength map | Wi-Fi details are permission- and OS-version-dependent |
| Bluetooth beacon dashboard | Show nearby opted-in BLE sensors, tags, and devices | **Public** CoreBluetooth; do not use it to track people |
| Network gesture remote | Use a phone webpage as a touchpad, macro pad, or presentation remote | **Public** local networking APIs |
| AirDrop-style local transfer | Discover nearby copies of your app and exchange files peer-to-peer | **Public** MultipeerConnectivity/Network framework |
| Internet outage automation | Switch status lights, start a timer, or fail over tasks when connectivity changes | **Public** Network framework |

## Good starting points

- [lidder](https://github.com/mhjort/lidder) — Swift command-line access
  to the MacBook lid-angle sensor.
- [mac-angle](https://github.com/ufoym/mac-angle) — a C++ lid-angle sensor
  library and example.
- [MacTap](https://github.com/jaskirat1616/mactap-app) — maps knocks on
  supported MacBooks to actions.
- [apple-silicon-accelerometer](https://github.com/olvvier/apple-silicon-accelerometer)
  — research into the undocumented Apple silicon accelerometer.
- [Apple AppKit event documentation](https://developer.apple.com/documentation/appkit/nsevent)
  — keyboard, mouse, tablet, touch, and pressure events.
- [Apple LocalAuthentication documentation](https://developer.apple.com/documentation/localauthentication)
  — Touch ID authentication without access to fingerprint data.
- [Apple Vision documentation](https://developer.apple.com/documentation/vision)
  — face, pose, text, and image analysis.
- [Apple ScreenCaptureKit documentation](https://developer.apple.com/documentation/screencapturekit)
  — screen and system-audio capture.
- [Apple IOPowerSources documentation](https://developer.apple.com/documentation/iokit/iopowersources_h)
  — battery and power-source information.

## Safety and privacy

- Ask only for permissions that a feature actually needs, and explain why.
- Keep camera, microphone, location, and biometric processing on-device where
  possible.
- Never record people, infer their presence, or track nearby devices without
  clear consent.
- Avoid repeatedly striking, shaking, loading, or partially closing a MacBook;
  these ideas should react to gentle input, not risk the hardware.
- Treat sensor values as approximate. Do not use these experiments for safety,
  health, security, or certified measurement.
- Prefer supported APIs for distributed or production apps. Clearly label
  anything that depends on private APIs or specific hardware.