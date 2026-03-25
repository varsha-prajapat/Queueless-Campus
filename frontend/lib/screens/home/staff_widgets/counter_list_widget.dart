import 'package:flutter/material.dart';
import '../../../models/counter_model.dart';
import '../../../services/staff_service/counter_service.dart';
import 'counter_card.dart';

class CounterListWidget extends StatefulWidget {
  final String staffId;

  const CounterListWidget({
    super.key,
    required this.staffId,
  });

  @override
  State<CounterListWidget> createState() => _CounterListWidgetState();
}

class _CounterListWidgetState extends State<CounterListWidget> {
  late Future<List<CounterModel>> _counterFuture;

  @override
  void initState() {
    super.initState();
    _counterFuture = CounterService.getUserCounters(staffId: widget.staffId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CounterModel>>(
      future: _counterFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No counters assigned to you"));
        }

        final counters = snapshot.data!;

        return Column(
          children: counters.map((counter) {
            return FutureBuilder<String>(
              future: CounterService.getServiceName(counter.serviceId),
              builder: (context, serviceSnapshot) {
                if (!serviceSnapshot.hasData) {
                  return CounterCard(
                    counter: counter,
                    serviceName: "Loading service...",
                  );
                }

                return CounterCard(
                  counter: counter,
                  serviceName: serviceSnapshot.data!,
                );
              },
            );
          }).toList(),
        );
      },
    );
  }
}
