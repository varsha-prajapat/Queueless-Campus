import 'package:flutter/material.dart';
import '../../../models/counter_model.dart';
import '../../../services/staff_service/counter_service.dart';
import '../../../services/socket_service.dart';
import 'counter_card.dart';

class CounterListWidget extends StatefulWidget {
  final String staffId;

  const CounterListWidget({super.key, required this.staffId});

  @override
  State<CounterListWidget> createState() => _CounterListWidgetState();
}

class _CounterListWidgetState extends State<CounterListWidget> {
  final SocketService _socketService = SocketService();

  List<CounterWithService> _counters = [];

  // ✅ keep reference of listener
  late final Function(dynamic) _counterListener;

  @override
  void initState() {
    super.initState();
    _loadCounters();
    _setupSocketListener();
  }

  /// ---------------- LOAD COUNTERS ----------------
  Future<void> _loadCounters() async {
    try {
      final counters =
          await CounterService.getUserCounters(staffId: widget.staffId);

      // 🔥 optimize: fetch all service names in parallel
      final countersWithServices =
          await Future.wait(counters.map((counter) async {
        final serviceName =
            await CounterService.getServiceName(counter.serviceId);

        return CounterWithService(
          counter: counter,
          serviceName: serviceName,
        );
      }));

      if (!mounted) return;

      setState(() {
        _counters = countersWithServices;
      });
    } catch (e) {
      debugPrint("Counter load error: $e");
    }
  }

  /// ---------------- SOCKET LISTENER ----------------
  void _setupSocketListener() {
    _counterListener = (data) {
      if (data == null || data is! Map) return;

      final updatedCounterId = data['counterId']?.toString();
      final updatedServiceName = data['serviceName']?.toString();

      if (updatedCounterId == null || updatedServiceName == null) return;

      final index = _counters
          .indexWhere((c) => c.counter.id.toString() == updatedCounterId);

      if (index != -1) {
        final oldServiceName = _counters[index].serviceName;

        if (oldServiceName != updatedServiceName) {
          if (!mounted) return;

          setState(() {
            _counters[index] = CounterWithService(
              counter: _counters[index].counter,
              serviceName: updatedServiceName,
            );
          });
        }
      }
    };

    // ✅ register listener
    _socketService.on('counter:update', _counterListener);
  }

  @override
  void dispose() {
    // ✅ remove only this listener
    _socketService.socket?.off('counter:update', _counterListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_counters.isEmpty) {
      return const SizedBox(); // no spinner
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _counters.length,
      itemBuilder: (context, index) {
        final item = _counters[index];

        return CounterCard(
          counter: item.counter,
          serviceName: item.serviceName,
        );
      },
    );
  }
}

/// ---------------- HELPER MODEL ----------------
class CounterWithService {
  final CounterModel counter;
  final String serviceName;

  const CounterWithService({
    required this.counter,
    required this.serviceName,
  });
}
