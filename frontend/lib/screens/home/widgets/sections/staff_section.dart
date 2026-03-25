import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../shared/widgets/banner_slider.dart';
import '../../../../shared/services/Banner_Service.dart';
import '../../../../models/banner_model.dart';
import '../../staff_widgets/counter_list_widget.dart';
import '../../../home/staff_widgets/token_rows.dart';
import '../../staff_widgets/TokenActionButtons.dart';
import '../../../../services/staff_service/token_service.dart';
import '../../../../models/token_model.dart';
import '../../../../shared/screens/admin_contact_card.dart';
import '../../../../services/staff_service/counter_service.dart';
import '../../../../services/socket_service.dart';

class StaffSection extends StatefulWidget {
  final String departmentId;
  final String staffId;
  final int? pendingTokens;

  const StaffSection({
    super.key,
    required this.departmentId,
    required this.staffId,
    this.pendingTokens,
  });

  @override
  State<StaffSection> createState() => _StaffSectionState();
}

class _StaffSectionState extends State<StaffSection> {
  // Banner state
  List<BannerModel> _banners = [];
  bool _loadingBanners = true;

  // Counter state
  bool _counterAssigned = false;

  // Token state
  TokenStats? _tokenStats;
  TokenModel? _currentToken;
  bool _loadingStats = true;
  bool _loadingToken = true;

  // Socket
  final SocketService _socketService = SocketService();
  StreamSubscription? _tokenSub;

  @override
  void initState() {
    super.initState();
    _initData();
    _initSocket();
  }

  @override
  void dispose() {
    _tokenSub?.cancel();
    _socketService.dispose();
    super.dispose();
  }

  /// Initialize socket connection
  void _initSocket() {
    _socketService.init(userId: widget.staffId, roles: ['STAFF']);
    _socketService.connect().then((_) {
      _tokenSub = _socketService.tokenStream.listen((tokenData) {
        debugPrint('🔔 Token Event: $tokenData');

        if (tokenData['status'] == 'serving' ||
            tokenData['status'] == 'waiting' ||
            tokenData['status'] == 'skipped') {
          _refreshTokens();
        }
      });
    });
  }

  /// Load all initial data
  Future<void> _initData() async {
    await Future.wait([
      _loadBannersOnce(),
      _checkCounterAssignedOnce(),
    ]);

    if (_counterAssigned) {
      await _refreshTokens();
    }
  }

  /// Load banners once
  Future<void> _loadBannersOnce() async {
    setState(() => _loadingBanners = true);
    try {
      final String? depId = (widget.departmentId.trim().isEmpty ||
              widget.departmentId.trim().toLowerCase() == "null")
          ? null
          : widget.departmentId.trim();

      _banners = await BannerService.getUserBanners(
        role: "STAFF",
        departmentId: depId,
      );

      debugPrint("🎯 BANNERS: ${_banners.map((b) => b.title).toList()}");
    } catch (e) {
      debugPrint("❌ Banner Error: $e");
      _banners = [];
    } finally {
      if (mounted) setState(() => _loadingBanners = false);
    }
  }

  /// Check if counter assigned
  Future<void> _checkCounterAssignedOnce() async {
    try {
      final counters =
          await CounterService.getUserCounters(staffId: widget.staffId);
      _counterAssigned = counters.isNotEmpty;
    } catch (e) {
      debugPrint("Counter Error: $e");
      _counterAssigned = false;
    } finally {
      if (mounted) setState(() {});
    }
  }

  /// Refresh tokens & stats
  Future<void> _refreshTokens() async {
    await Future.wait([
      _loadTokenStats(),
      _loadCurrentToken(),
    ]);
  }

  Future<void> _loadTokenStats() async {
    try {
      setState(() => _loadingStats = true);
      final stats = await TokenService.getTokenStats();

      if (!mounted) return;

      setState(() {
        _tokenStats = stats;
        _loadingStats = false;
      });
    } catch (e) {
      debugPrint("Stats Error: $e");
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  Future<void> _loadCurrentToken() async {
    try {
      setState(() => _loadingToken = true);
      final token = await TokenService.fetchServingToken();

      if (!mounted) return;

      setState(() => _currentToken = token);
    } catch (e) {
      debugPrint("Serving token error: $e");
    } finally {
      if (mounted) setState(() => _loadingToken = false);
    }
  }

  /// Refresh everything (tokens + banners)
  Future<void> _refreshAll() async {
    await Future.wait([
      _refreshTokens(),
      _loadBannersOnce(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final bool hasDepartment = widget.departmentId.trim().isNotEmpty &&
        widget.departmentId.trim().toLowerCase() != "null";

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Banner
            if (_loadingBanners)
              const SizedBox(
                  height: 150,
                  child: Center(child: CircularProgressIndicator()))
            else if (_banners.isNotEmpty)
              BannerSlider(banners: _banners),

            const SizedBox(height: 20),

            // Admin card if no department or counter
            if (!hasDepartment || !_counterAssigned)
              AdminContactCard(
                role: "STAFF",
                departmentId: hasDepartment ? widget.departmentId : null,
                counterAssigned: _counterAssigned,
                pendingTokens: widget.pendingTokens,
              )
            else ...[
              CounterListWidget(staffId: widget.staffId),
              const SizedBox(height: 20),
              _loadingStats
                  ? const Center(child: CircularProgressIndicator())
                  : TokenRows(),
              const SizedBox(height: 20),
              if (_loadingToken)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(),
                ),
              TokenActionButtons(
                staffId: widget.staffId,
                onRefresh: _refreshAll,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
