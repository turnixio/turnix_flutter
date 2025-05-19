library turnix_flutter;

import 'dart:convert';
import 'package:http/http.dart' as http;

// Turnix ICE-credentials endpoint
const _ENDPOINT = "https://turnix.io/api/v1/credentials/ice";

/// Represents a single ICE server entry.
class IceServer {
  /// One or more STUN/TURN URLs
  final List<String> urls;

  final String? username;
  final String? credential;

  IceServer({
    required this.urls,
    this.username,
    this.credential,
  });

  factory IceServer.fromJson(Map<String, dynamic> json) {
    // JSON might contain "urls" (list) or legacy "url" (single string)
    final raw = json['urls'] ??
        json['url']   ??
        <String>[];
    // normalize to List<String>
    final urls = raw is List
        ? List<String>.from(raw)
        : <String>[raw as String];

    return IceServer(
      urls: urls,
      username: json['username'] as String?,
      credential: json['credential'] as String?,
    );
  }
}


/// The full ICE credentials payload.
class IceCredentials {
  final List<IceServer> iceServers;
  final DateTime expiresAt;

  IceCredentials({ required this.iceServers, required this.expiresAt });

  factory IceCredentials.fromJson(Map<String, dynamic> json) {
    final servers = (json['iceServers'] as List)
        .map((s) => IceServer.fromJson(s as Map<String, dynamic>))
        .toList();
    return IceCredentials(
      iceServers: servers,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }
}

/// Main plugin class.
class TurnixIO {
  /// Fetches ICE credentials from the Turnix backend.
  ///
  /// [apiKey] – your Turnix-issued API key.
  ///
  /// Optional parameters correspond to the query‐params documented by Turnix;
  /// they’ll be serialized in the POST body JSON. If you need to send a client
  /// IP for geofencing, provide [clientIp] and it will be set as a header.
  static Future<IceCredentials> getIceCredentials({
    required String apiKey,
    String? initiatorClient,
    String? receiverClient,
    String? room,
    int? ttl,
    String? fixedRegion,
    String? preferredRegion,
    String? clientIp,
  }) async {
    // Build the JSON payload
    final bodyJson = <String, dynamic>{};
    if (initiatorClient != null) bodyJson['initiator_client'] = initiatorClient;
    if (receiverClient  != null) bodyJson['receiver_client']  = receiverClient;
    if (room            != null) bodyJson['room']             = room;
    if (ttl             != null) bodyJson['ttl']              = ttl;
    if (fixedRegion     != null) bodyJson['fixed_region']     = fixedRegion;
    if (preferredRegion != null) bodyJson['preferred_region'] = preferredRegion;

    // Build headers
    final headers = <String, String>{
      'Authorization': 'Bearer $apiKey',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (clientIp != null) {
      headers['X-TURN-CLIENT-IP'] = clientIp;
    }

    // Issue POST
    final response = await http.post(
      Uri.parse(_ENDPOINT),
      headers: headers,
      body: json.encode(bodyJson),
    );

    if (response.statusCode != 200) {
      throw http.ClientException(
        'Failed to fetch ICE credentials (${response.statusCode})',
        Uri.parse(_ENDPOINT),
      );
    }

    final body = json.decode(response.body) as Map<String, dynamic>;
    return IceCredentials.fromJson(body);
  }
}
