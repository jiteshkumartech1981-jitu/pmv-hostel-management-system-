import 'package:flutter/material.dart';

import '../../services/auth_store.dart';
import '../login_screen.dart';
import 'complaint_screen.dart';
import 'gate_pass_screen.dart';
import 'id_card_screen.dart';
import 'mess_menu_screen.dart';

class StudentHome extends StatefulWidget {
  const StudentHome({super.key});

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  int _index = 0;

  Future<void> _logout() async {
    await AuthStore.instance.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = const [
      IdCardScreen(),
      MessMenuScreen(),
      GatePassScreen(),
      ComplaintScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        title: const Text(
          'College Hostel Portal',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.qr_code_2), label: 'My ID Card'),
          NavigationDestination(icon: Icon(Icons.restaurant_menu), label: 'Mess Menu'),
          NavigationDestination(
            icon: Icon(Icons.door_sliding_outlined),
            label: 'Gate Pass',
          ),
          NavigationDestination(icon: Icon(Icons.report_gmailerrorred), label: 'Complaint'),
        ],
      ),
    );
  }
}
