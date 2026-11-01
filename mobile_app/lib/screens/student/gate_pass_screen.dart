import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../services/auth_store.dart';

class GatePassScreen extends StatefulWidget {
  const GatePassScreen({super.key});

  @override
  State<GatePassScreen> createState() => _GatePassScreenState();
}

class _GatePassScreenState extends State<GatePassScreen> {
  List<dynamic> _passes = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ApiService.instance.myGatePasses();
      setState(() => _passes = data.reversed.toList());
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
      case 'EXIT_ALLOWED':
        return Colors.green;
      case 'OUT':
        return Colors.orange;
      case 'RETURNED':
        return Colors.blueGrey;
      case 'REJECTED':
        return Colors.red;
      default:
        return Colors.amber.shade800;
    }
  }

  Future<void> _apply() async {
    final session = AuthStore.instance.session;
    final reason = TextEditingController();
    final outTime = TextEditingController(text: '17:00');
    final returnTime = TextEditingController(text: '20:00');
    final phone = TextEditingController(text: '9876543210');

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apply for Gate Pass'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: reason,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  hintText: 'e.g. Market / Coaching',
                ),
              ),
              TextField(
                controller: outTime,
                decoration: const InputDecoration(labelText: 'Expected Out Time'),
              ),
              TextField(
                controller: returnTime,
                decoration: const InputDecoration(labelText: 'Expected Return Time'),
              ),
              TextField(
                controller: phone,
                decoration: const InputDecoration(labelText: 'Parent Phone Number'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Submit')),
        ],
      ),
    );

    if (ok != true) return;
    try {
      await ApiService.instance.applyGatePass({
        'studentName': session?.name ?? session?.username,
        'studentRollNumber': session?.rollNumber ?? session?.username,
        'reason': reason.text.trim(),
        'parentPhone': phone.text.trim(),
        'exitTime': outTime.text.trim(),
        'expectedReturnTime': returnTime.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gate pass saved. Parent alert queued after guard scan.')),
      );
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: const Color(0xFF1E3A8A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Need to go outside?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Apply for a digital gate pass. Warden approval is required.',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _apply,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1E3A8A),
                    ),
                    child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Recent Passes',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : _passes.isEmpty
                        ? const Center(child: Text('Abhi koi gate pass nahi hai.'))
                        : ListView.builder(
                            itemCount: _passes.length,
                            itemBuilder: (context, index) {
                              final pass = _passes[index] as Map<String, dynamic>;
                              final status = pass['status']?.toString() ?? 'PENDING';
                              final color = _statusColor(status);
                              return Card(
                                elevation: 2,
                                margin: const EdgeInsets.only(bottom: 10),
                                child: ListTile(
                                  title: Text(
                                    pass['reason']?.toString() ?? 'Gate pass',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    'Out: ${pass['exitTime'] ?? '-'} | Expected In: ${pass['expectedReturnTime'] ?? '-'}',
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      status,
                                      style: TextStyle(
                                        color: color,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
