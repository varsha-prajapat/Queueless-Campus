import 'dart:async';
import 'package:flutter/material.dart';
import '../models/token_model.dart';
import '../services/student_service/token_service.dart';
import '../services/socket_service.dart';

class TokenProvider extends ChangeNotifier {
  bool loading = true;
  TokenStats? stats;
  TokenModel? myToken;

  StreamSubscription? _notifSub;

  /// Constructor
  TokenProvider() {
    _init();
  }

  /// ================= INIT PROVIDER =================
  Future<void> _init() async {
    // Fetch initial token stats and my token
    await refresh();
    await fetchMyToken();

    // Listen to global socket events for real-time updates
    _listenToSocket();
  }

  /// ================= REFRESH TOKEN STATS =================
  Future<void> refresh() async {
    try {
      loading = true;
      notifyListeners();

      final newStats = await TokenService.getTokenStats();

      stats = newStats;
    } catch (e) {
      stats = TokenStats.empty();
    } finally {
      loading = false;
      notifyListeners();
      print(
          "✅ Token stats updated. Current: ${stats?.currentToken}, Next: ${stats?.nextToken}");
    }
  }

  /// ================= FETCH CURRENT USER TOKEN =================
  Future<void> fetchMyToken() async {
    try {
      final tokens = await TokenService.getMyTokens();
      if (tokens.isNotEmpty) {
        myToken = tokens.first;
        print(
            "📥 My token fetched: ${myToken!.id}, Status: ${myToken!.status}");
      } else {
        myToken = null;
      }
      notifyListeners();
    } catch (e) {
      myToken = null;
      notifyListeners();
    }
  }

  /// ================= UPDATE TOKEN AFTER BOOKING/PAYMENT =================
  void updateToken(TokenModel updatedToken) {
    print(
        "🔔 updateToken called with id: ${updatedToken.id}, status: ${updatedToken.status}");

    // Update if it's the same token or user has no token yet
    if (myToken == null || myToken!.id == updatedToken.id) {
      myToken = updatedToken;
      print(
          "✅ TokenProvider updated my token: ${myToken!.id}, status: ${myToken!.status}");

      // Refresh stats as well
      refresh();
      notifyListeners();
    } else {
      print(
          "ℹ️ updateToken ignored: myToken id ${myToken!.id} does not match ${updatedToken.id}");
    }
  }

  /// ================= SOCKET LISTENER =================
  void _listenToSocket() {
    final socket = SocketService().socket;
    if (socket == null) {
      return;
    }

    // Token created
    socket.on("token:created", (data) {
      if (data != null && data is Map<String, dynamic>) {
        updateToken(TokenModel.fromJson(data));
      }
    });

    // Payment confirmed
    socket.on("token:paymentConfirmed", (data) {
      if (data != null && data is Map<String, dynamic>) {
        updateToken(TokenModel.fromJson(data));
      }
    });

    // Token called
    socket.on("token:called", (data) {
      refresh();
    });

    // Token completed
    socket.on("token:completed", (data) {
      refresh();
      if (myToken != null &&
          data != null &&
          data is Map<String, dynamic> &&
          myToken!.id == data["_id"]) {
        myToken = TokenModel.fromJson(data);
        notifyListeners();
        print(
            "✅ My token completed updated: ${myToken!.id}, status: ${myToken!.status}");
      }
    });
  }

  /// ================= DISPOSE =================
  @override
  void dispose() {
    _notifSub?.cancel();
    super.dispose();
  }
}
