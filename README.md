# turnix\_flutter

[![pub package](https://img.shields.io/pub/v/turnix_flutter.svg)](https://pub.dev/packages/turnix_flutter)
[![License](https://img.shields.io/pub/license/turnix_flutter.svg)](LICENSE)

A Flutter plugin for fetching WebRTC ICE (STUN/TURN) credentials from the Turnix.io API, with support for advanced options like regions, TTL, client IP, and per-call parameters.

---

## Features

* Fetch STUN/TURN credentials in a single call with built-in endpoint.
* Support for optional parameters: `initiatorClient`, `receiverClient`, `room`, `ttl`, `fixedRegion`, `preferredRegion`, `clientIp`.
* Automatic parsing of multiple URLs per ICE server.
* Provides `expiresAt` timestamp and real-time `timeLeft` handling for seamless credential renewal.
* Pure-Dart implementation: works on all Flutter platforms (iOS, Android, Web, Desktop).

## Getting Started

### Installation

Add `turnix_flutter` as a dependency in your `pubspec.yaml`:

```yaml
dependencies:
  turnix_flutter: ^0.1.0
```

Then run:

```bash
flutter pub get
```

### Usage

Import the package:

```dart
import 'package:turnix_flutter/turnix_flutter.dart';
```

Fetch credentials:

```dart
final creds = await TurnixIO.getIceCredentials(
  apiKey: 'YOUR_API_KEY',
  room: 'chat-room-42',
  ttl: 600,
  preferredRegion: 'us-west-2',
  clientIp: '203.0.113.5',
);

// Configure your RTCPeerConnection:
final pc = await createPeerConnection({
  'iceServers': creds.iceServers.map((s) => {
    'urls': s.urls,
    if (s.username  != null) 'username':   s.username,
    if (s.credential!= null) 'credential': s.credential,
  }).toList(),
});
```

## Advanced Options

All parameters are optional. Pass only those you need:

| Parameter         | Type     | Description                                                                                                                                                                                           |
| ----------------- | -------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `initiatorClient` | `String` | An identifier for the call initiator.                                                                                                                                                                 |
| `receiverClient`  | `String` | An identifier for the call receiver.                                                                                                                                                                  |
| `room`            | `String` | A room or session identifier to scope TURN URLs.                                                                                                                                                      |
| `ttl`             | `int`    | Time-to-live in seconds for the credentials.                                                                                                                                                          |
| `fixedRegion`     | `String` | **Strict region**: forces allocation in the specified region (e.g., `us-east-1`); if unavailable, the request will fail.                                                                              |
| `preferredRegion` | `String` | **Preferred region**: hints allocation in a region (e.g., `eu-central-1`); if unavailable, the server will fall back to another region.                                                               |
| `clientIp`        | `String` | Client IP for geofencing, sent as `X-TURN-CLIENT-IP` header. Defaults to the requester's IP address if unset, used to determine region when neither `fixedRegion` nor `preferredRegion` is specified. |

Example with advanced options:

```dart
final creds = await TurnixIO.getIceCredentials(
  apiKey: 'YOUR_API_KEY',
  room: 'video-room',
  ttl: 1200,
  fixedRegion: 'eu-central-1',
  clientIp: '203.0.113.8', // determines region if no fixed/preferred
);
```

## Handling Expiration

The `IceCredentials` object exposes:

* `iceServers`: a list of `IceServer(urls, username?, credential?)` for your `RTCPeerConnection`.
* `expiresAt`: a `DateTime` after which credentials are invalid.

Schedule refreshes by comparing `expiresAt` to `DateTime.now()`:

```dart
final now = DateTime.now();
final timeLeft = creds.expiresAt.difference(now);
if (timeLeft < Duration(seconds: 30)) {
  creds = await TurnixIO.getIceCredentials(apiKey: 'YOUR_API_KEY');
}
```

## Example App

See the `example/` directory for a Flutter demo app with UI, countdown timer, and advanced options panel.

## Contributing

Contributions and issues are welcome! Please open a PR or issue on [GitHub](https://github.com/turnix/turnix_flutter).

## License

This package is released under the MIT License. See [LICENSE](LICENSE) for details.

---

\<details>
\<summary>Full MIT License\</summary>

```
MIT License

Copyright (c) YEAR Turnix

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

\</details>
