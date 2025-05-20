import 'package:flutter/material.dart';
import 'package:turnix_flutter/turnix_flutter.dart';
import 'dart:async';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  IceCredentials? creds;
  String? error;
  Timer? _timer; // to update the countdown every second

  @override
  void initState() {
    super.initState();
    _fetchCreds();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();


  }

  Future<void> _fetchCreds() async {
    setState(() {
      error = null;
      creds = null;
    });
    try {
      final fetched = await TurnixIO.getIceCredentials(
        apiToken:
            'YOU_API_TOKEN', // <- get it on https://turnix.io/, additionally you can provide following optional parameters:
        // fixedRegion: 'singapore',
        // preferredRegion: "singapore",
        // clientIp: "1.21.224.0",
        // initiatorClient: "initiator_id"
        // receiverClient: "receiver_id",
        // room: "secret_room_id"
        // ttl: 6000
      );
      setState(() => creds = fetched);
      // start a timer to tick every second so "time left" updates
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } catch (e) {
      setState(() => error = e.toString());
    }
  }

  String _formatDuration(Duration d) {
    if (d.isNegative) return 'Expired';
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final timeLeft =
        creds != null ? creds!.expiresAt.difference(now) : Duration.zero;

    return MaterialApp(
      title: 'Turnix Flutter Plugin Demo',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Turnix ICE Demo'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchCreds,
              tooltip: 'Re-fetch credentials',
            ),
          ],
        ),
        body: Center(
          child:
              error != null
                  ? Text('Error: $error')
                  : creds == null
                  ? const CircularProgressIndicator()
                  : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Expires at: ${creds!.expiresAt.toLocal()}'),
                        const SizedBox(height: 4),
                        Text('Time left: ${_formatDuration(timeLeft)}'),
                        const Divider(),
                        ...creds!.iceServers.map((s) {
                          return ListTile(
                            title: Text(s.urls.join('\n')),
                            subtitle: Text(
                              s.username != null
                                  ? 'User: ${s.username}\nCred: ${s.credential}'
                                  : 'No username',
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
        ),
      ),
    );
  }
}
