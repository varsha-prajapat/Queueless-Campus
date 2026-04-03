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
  List<BannerModel> _banners = [];
  bool _loadingBanners = true;

  bool _counterAssigned = false;

  List<TokenModel> _tokens = [];
  TokenStats _tokenStats = TokenStats.empty();
  TokenModel? _currentToken;

  final SocketService _socketService = SocketService();
  StreamSubscription? _tokenSub;

  bool _socketInitialized = false;
  Timer? _debounceTimer;

  String _s(String? v) => (v ?? "").toLowerCase().trim();

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _loadInitialData();
    await _initSocket();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _tokenSub?.cancel();
    _socketService.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadBanners(),
      _checkCounterAssigned(),
    ]);

    if (_counterAssigned) {
      await _loadAllTokens();
    }
  }

  Future<void> _loadBanners() async {
    try {
      final String? depId = (widget.departmentId.trim().isEmpty ||
              widget.departmentId.trim().toLowerCase() == "null")
          ? null
          : widget.departmentId.trim();

      final banners = await BannerService.getUserBanners(
        role: "STAFF",
        departmentId: depId,
      );

      if (!mounted) return;
      setState(() => _banners = banners);
    } catch (e) {
    } finally {
      if (mounted) setState(() => _loadingBanners = false);
    }
  }

  Future<void> _checkCounterAssigned() async {
    try {
      final counters =
          await CounterService.getUserCounters(staffId: widget.staffId);

      if (!mounted) return;
      setState(() => _counterAssigned = counters.isNotEmpty);
    } catch (e) {}
  }

  Future<void> _loadAllTokens() async {
    try {
      final tokens = await TokenService.getAllTokensOfStaffDetail();

      if (!mounted) return;

      _tokens = tokens;
      _recalculateUI();
    } catch (e) {}
  }

  Future<void> _initSocket() async {
    if (_socketInitialized) return;
    _socketInitialized = true;

    _socketService.init(
      userId: widget.staffId,
      roles: ['staff'],
    );

    await _socketService.connect();

    _tokenSub?.cancel();
    _tokenSub = _socketService.tokenStream.listen(_onTokenEvent);
  }

  void _onTokenEvent(Map<String, dynamic> data) async {
    try {
      final tokens = await TokenService.getAllTokensOfStaffDetail();

      if (!mounted) return;

      setState(() {
        _tokens = tokens;
      });

      _recalculateUI();
    } catch (e) {}
  }

  List<TokenModel> get _activeTokens {
    final list = _tokens.where((t) {
      final s = _s(t.status);
      return s == "waiting" || s == "serving" || s == "called";
    }).toList();

    list.sort((a, b) {
      final sa = _s(a.status);
      final sb = _s(b.status);

      if (sa == "serving") return -1;
      if (sb == "serving") return 1;

      if (a.isUrgent && !b.isUrgent) return -1;
      if (!a.isUrgent && b.isUrgent) return 1;

      return a.tokenNumber.compareTo(b.tokenNumber);
    });

    return list;
  }

  void _applyCurrentToken() {
    final serving = _activeTokens.where((t) {
      final s = _s(t.status);
      return s == "serving" || s == "called";
    }).toList();

    serving.sort((a, b) {
      if (a.isUrgent && !b.isUrgent) return -1;
      if (!a.isUrgent && b.isUrgent) return 1;
      return a.tokenNumber.compareTo(b.tokenNumber);
    });

    _currentToken = serving.isNotEmpty ? serving.first : null;
  }

  TokenModel? _getNextToken() {
    final waiting = _activeTokens.where((t) {
      return _s(t.status) == "waiting";
    }).toList();

    waiting.sort((a, b) {
      if (a.isUrgent && !b.isUrgent) return -1;
      if (!a.isUrgent && b.isUrgent) return 1;
      return a.tokenNumber.compareTo(b.tokenNumber);
    });

    return waiting.isNotEmpty ? waiting.first : null;
  }

  void _recalculateUI() {
    _applyCurrentToken();
    final next = _getNextToken();

    setState(() {
      _tokenStats = TokenStats(
        currentToken: _currentToken?.tokenNumber.toString() ?? "-",
        nextToken: next?.tokenNumber.toString() ?? "-",
        waiting: _activeTokens.where((t) => _s(t.status) == "waiting").length,
        servedToday: _tokens.where((t) => _s(t.status) == "completed").length,
        urgentWaiting: _activeTokens
            .where((t) => t.isUrgent && _s(t.status) == "waiting")
            .length,
        completed: _tokens.where((t) => _s(t.status) == "completed").length,
        cancelled: _tokens.where((t) => _s(t.status) == "cancelled").length,
        skipped: _tokens.where((t) => _s(t.status) == "skipped").length,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasDepartment = widget.departmentId.trim().isNotEmpty &&
        widget.departmentId.trim().toLowerCase() != "null";

    final TokenModel? preselectedToken = _currentToken ??
        (_activeTokens.any(
                (t) => _s(t.status) == "waiting" || _s(t.status) == "serving")
            ? _activeTokens.firstWhere(
                (t) => _s(t.status) == "waiting" || _s(t.status) == "serving",
              )
            : null);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_loadingBanners)
              const SizedBox(height: 150)
            else if (_banners.isNotEmpty)
              BannerSlider(banners: _banners),
            const SizedBox(height: 20),
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
              TokenRows(
                stats: _tokenStats,
                currentToken: _currentToken,
                allTokens: _tokens,
              ),
              const SizedBox(height: 20),
              TokenActionButtons(
                staffId: widget.staffId,
                currentToken: preselectedToken, // ✅ FIX HERE
                tokens: _activeTokens,
                onTokenChanged: (token) {
                  _currentToken = token;
                  _recalculateUI();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
