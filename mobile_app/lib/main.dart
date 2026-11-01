import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

// ================================================================
// SERVER BASE URL CONFIG
// ================================================================
const String kBaseUrl = 'https://thorn-safeness-tiptoeing.ngrok-free.dev';

String _cleanErrorMessage(dynamic rawMsg, [String fallback = 'An error occurred. Please try again.']) {
  if (rawMsg == null) return fallback;
  final String str = rawMsg.toString().trim();
  if (str.isEmpty) return fallback;
  final lower = str.toLowerCase();
  if (lower.contains('galat') || lower.contains('password')) {
    if (lower.contains('galat')) {
      return 'Incorrect password. Please verify and try again.';
    }
  }
  if (lower.contains('zaroori')) {
    return 'Please enter all required fields.';
  }
  if (lower.contains('pehle se') || lower.contains('koshish')) {
    return 'Authentication failed. Please verify your details.';
  }
  return str;
}

void main() {
  runApp(const PmvHostelApp());
}

class PmvHostelApp extends StatelessWidget {
  const PmvHostelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PMV Hostel',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E3A8A)),
        useMaterial3: true,
      ),
      home: const RoleSelectionScreen(),
    );
  }
}

// ================================================================
// 1. ROLE SELECTION SCREEN
// ================================================================
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 440),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 105,
                height: 105,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'PURAN MURTI VIDYAPEETH',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: Color(0xFF1E3A8A)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              const Text(
                'Hostel Management Portal',
                style: TextStyle(fontSize: 14, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              _roleCard(
                title: 'Student Portal',
                subtitle: 'ID Card, QR Code & Gate Pass Application',
                icon: Icons.school,
                color: const Color(0xFF1E3A8A),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const StudentLoginScreen())),
              ),
              const SizedBox(height: 16),
              _roleCard(
                title: 'Administration & Staff Portal',
                subtitle: 'Hostel Director ΓÇó Warden ΓÇó Gate Guard',
                icon: Icons.admin_panel_settings,
                color: const Color(0xFF7C3AED),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const StaffLoginScreen())),
              ),
              const SizedBox(height: 36),
              const Text('┬⌐ PMV Hostel. All rights reserved.',
                  style: TextStyle(color: Colors.grey, fontSize: 11)),
              const SizedBox(height: 10),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.code, size: 13, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'Developed by',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Jitesh Kumar',
                    style: TextStyle(
                      color: Color(0xFF1E3A8A),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Nilaaksh Kalwale',
                    style: TextStyle(
                      color: Color(0xFF1E3A8A),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          child: Icon(icon, color: color),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(subtitle,
            style: const TextStyle(fontSize: 12, color: Colors.black54)),
        trailing:
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      ),
    );
  }
}

// ================================================================
// 2. STUDENT LOGIN SCREEN (Primary: Roll No + Password)
// ================================================================
class StudentLoginScreen extends StatefulWidget {
  const StudentLoginScreen({super.key});

  @override
  State<StudentLoginScreen> createState() => _StudentLoginScreenState();
}

class _StudentLoginScreenState extends State<StudentLoginScreen> {
  final TextEditingController _rollController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _isLoading = false;
  bool _obscure = true;
  String? _errorMsg;

  Future<void> _handlePasswordLogin() async {
    final roll = _rollController.text.trim().toUpperCase();
    final pass = _passController.text.trim();

    if (roll.isEmpty) {
      setState(() => _errorMsg = 'Enter Roll Number');
      return;
    }
    if (pass.isEmpty) {
      setState(() => _errorMsg = 'Enter Password');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      final response = await http.post(
        Uri.parse('$kBaseUrl/api/auth/student/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'rollNumber': roll,
          'password': pass,
        }),
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        final studentData = {
          'token': data['token'],
          'name': data['name'],
          'rollNumber': data['rollNumber'] ?? roll,
          'hostel': data['hostel'] ?? '',
          'roomNumber': data['roomNumber'] ?? data['room'] ?? '',
          'branch': data['branch'] ?? '',
          'year': data['year']?.toString() ?? '2',
          'mobile': data['mobile'] ?? '',
          'parentContactNumber': data['parentContactNumber'] ?? '',
          'role': data['role'],
        };

        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (_) => StudentDashboardScreen(student: studentData)),
          (route) => false,
        );
      } else {
        setState(() => _errorMsg = _cleanErrorMessage(data['message'], 'Incorrect password or account not activated.'));
      }
    } catch (e) {
      setState(() => _errorMsg = 'Unable to connect to server.\nPlease check your network connection.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Login'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Student Portal',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A8A)),
                    textAlign: TextAlign.center),
                const SizedBox(height: 6),
                const Text(
                    'Login with your College Roll Number & Password',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                    textAlign: TextAlign.center),
                const SizedBox(height: 24),
                TextField(
                  controller: _rollController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: 'College Roll Number',
                    hintText: 'e.g. 25017001009',
                    prefixIcon: const Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passController,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    errorText: _errorMsg,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handlePasswordLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Login',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                TextButton.icon(
                  icon: const Icon(Icons.phonelink_lock, size: 20),
                  onPressed: () {
                    final currentRoll = _rollController.text.trim().toUpperCase();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StudentMobileOtpRequestScreen(initialRoll: currentRoll),
                      ),
                    );
                  },
                  label: const Text(
                    'First Time Setup / Forgot Password? (Verify via Mobile & OTP)',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ================================================================
// 2b. STUDENT MOBILE + OTP REQUEST SCREEN (Mandatory Phone Match)
// ================================================================
class StudentMobileOtpRequestScreen extends StatefulWidget {
  final String initialRoll;
  const StudentMobileOtpRequestScreen({super.key, this.initialRoll = ''});

  @override
  State<StudentMobileOtpRequestScreen> createState() => _StudentMobileOtpRequestScreenState();
}

class _StudentMobileOtpRequestScreenState extends State<StudentMobileOtpRequestScreen> {
  late final TextEditingController _rollController = TextEditingController(text: widget.initialRoll);
  final TextEditingController _mobileController = TextEditingController();
  bool _isLoading = false;
  String? _errorMsg;

  Future<void> _handleSendOtp() async {
    final roll = _rollController.text.trim().toUpperCase();
    final mobile = _mobileController.text.trim();

    if (roll.isEmpty) {
      setState(() => _errorMsg = 'Enter Roll Number');
      return;
    }
    if (mobile.isEmpty || mobile.length < 10) {
      setState(() => _errorMsg = 'Enter 10-digit registered mobile number');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      final response = await http.post(
        Uri.parse('$kBaseUrl/api/auth/student/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'rollNumber': roll,
          'mobile': mobile,
        }),
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        final bool isFirstTime = data['isFirstTime'] ?? true;
        final String maskedMobile = data['mobile'] ?? mobile;
        final String studentName = data['studentName'] ?? '';

        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StudentOtpScreen(
              rollNumber: roll,
              studentName: studentName,
              maskedMobile: maskedMobile,
              isFirstTime: isFirstTime,
            ),
          ),
        );
      } else {
        setState(() => _errorMsg = _cleanErrorMessage(data['message'], 'Failed to verify mobile number.'));
      }
    } catch (e) {
      setState(() => _errorMsg = 'Unable to connect to server. Check network connection.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Mobile & Get OTP'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.security, size: 60, color: Color(0xFF1E3A8A)),
                const SizedBox(height: 16),
                const Text('Security Verification',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                    textAlign: TextAlign.center),
                const SizedBox(height: 6),
                const Text(
                  'Enter your Roll Number AND your Registered Mobile Number to receive an OTP.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _rollController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: 'College Roll Number',
                    hintText: 'e.g. 25017001009',
                    prefixIcon: const Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _mobileController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Registered Mobile Number',
                    hintText: '10-digit registered number',
                    prefixIcon: const Icon(Icons.phone_android),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    errorText: _errorMsg,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSendOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Send Verification OTP',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ================================================================
// 3. STUDENT OTP VERIFY SCREEN - Real API
// ================================================================
class StudentOtpScreen extends StatefulWidget {
  final String rollNumber;
  final String studentName;
  final String maskedMobile;
  final bool isFirstTime;

  const StudentOtpScreen({
    super.key,
    required this.rollNumber,
    required this.studentName,
    required this.maskedMobile,
    required this.isFirstTime,
  });

  @override
  State<StudentOtpScreen> createState() => _StudentOtpScreenState();
}

class _StudentOtpScreenState extends State<StudentOtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  String? _errorMsg;

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length < 6) {
      setState(() => _errorMsg = 'Enter 6-digit OTP');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      final response = await http.post(
        Uri.parse('$kBaseUrl/api/auth/student/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'rollNumber': widget.rollNumber,
          'otp': otp,
        }),
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);

        if (response.statusCode == 200) {
          if (!mounted) return;
          // OTP verified -> User creates or resets their password
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => SetPasswordScreen(rollNumber: widget.rollNumber),
            ),
          );
        } else {
        setState(() => _errorMsg = _cleanErrorMessage(data['message'], 'Invalid OTP. Please try again.'));
      }
    } catch (e) {
      setState(() => _errorMsg = 'Server error. Please try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify OTP'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.mark_email_unread_outlined,
                  size: 60, color: Color(0xFF1E3A8A)),
              const SizedBox(height: 16),
              Text('Hello, ${widget.studentName}!',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                'OTP sent to: ${widget.maskedMobile}',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _otpController,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 6,
                style: const TextStyle(
                    letterSpacing: 8,
                    fontSize: 28,
                    fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '------',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  errorText: _errorMsg,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Verify & Continue',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ΓåÉ Go Back (Change Roll Number)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// 4. SET PASSWORD SCREEN (First Time) - Real API
// ================================================================
class SetPasswordScreen extends StatefulWidget {
  final String rollNumber;
  const SetPasswordScreen({super.key, required this.rollNumber});

  @override
  State<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends State<SetPasswordScreen> {
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _isLoading = false;
  bool _obscure1 = true;
  bool _obscure2 = true;
  String? _errorMsg;

  Future<void> _setPassword() async {
    final pass = _passController.text.trim();
    final confirm = _confirmController.text.trim();

    if (pass.length < 6) {
      setState(() => _errorMsg = 'Password must be at least 6 characters');
      return;
    }
    if (pass != confirm) {
      setState(() => _errorMsg = 'Passwords do not match');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      final response = await http.post(
        Uri.parse('$kBaseUrl/api/auth/student/set-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'rollNumber': widget.rollNumber,
          'password': pass,
        }),
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        // Login successful - token mila
        final studentData = {
          'token': data['token'],
          'name': data['name'],
          'rollNumber': data['rollNumber'] ?? widget.rollNumber,
          'hostel': data['hostel'] ?? '',
          'roomNumber': data['roomNumber'] ?? data['room'] ?? '',
          'branch': data['branch'] ?? '',
          'year': data['year']?.toString() ?? '2',
          'mobile': data['mobile'] ?? '',
          'parentContactNumber': data['parentContactNumber'] ?? '',
          'role': data['role'],
        };

        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (_) => StudentDashboardScreen(student: studentData)),
          (route) => false,
        );
      } else {
        setState(() => _errorMsg = _cleanErrorMessage(data['message'], 'Something went wrong. Please try again.'));
      }
    } catch (e) {
      setState(() => _errorMsg = 'Server error. Please try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Password'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.lock_person_outlined,
                  size: 60, color: Color(0xFF1E3A8A)),
              const SizedBox(height: 16),
              const Text('Create New Password',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A)),
                  textAlign: TextAlign.center),
              const SizedBox(height: 6),
              const Text('This password will be used for future logins.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                  textAlign: TextAlign.center),
              const SizedBox(height: 28),
              TextField(
                controller: _passController,
                obscureText: _obscure1,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure1 ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscure1 = !_obscure1),
                  ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _confirmController,
                obscureText: _obscure2,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure2 ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscure2 = !_obscure2),
                  ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  errorText: _errorMsg,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _setPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save & Enter Portal',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// 5. STUDENT PASSWORD LOGIN (Returning users) - Real API
// ================================================================
class StudentPasswordLoginScreen extends StatefulWidget {
  final String rollNumber;
  final String studentName;
  const StudentPasswordLoginScreen(
      {super.key, required this.rollNumber, required this.studentName});

  @override
  State<StudentPasswordLoginScreen> createState() =>
      _StudentPasswordLoginScreenState();
}

class _StudentPasswordLoginScreenState
    extends State<StudentPasswordLoginScreen> {
  late final TextEditingController _rollController =
      TextEditingController(text: widget.rollNumber);
  final TextEditingController _passController = TextEditingController();
  bool _isLoading = false;
  bool _obscure = true;
  String? _errorMsg;

  Future<void> _login() async {
    final roll = _rollController.text.trim().toUpperCase();
    final pass = _passController.text.trim();
    if (roll.isEmpty) {
      setState(() => _errorMsg = 'Enter Roll Number');
      return;
    }
    if (pass.isEmpty) {
      setState(() => _errorMsg = 'Enter Password');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      final response = await http.post(
        Uri.parse('$kBaseUrl/api/auth/student/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'rollNumber': roll,
          'password': pass,
        }),
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        final studentData = {
          'token': data['token'],
          'name': data['name'],
          'rollNumber': data['rollNumber'] ?? widget.rollNumber,
          'hostel': data['hostel'] ?? '',
          'roomNumber': data['roomNumber'] ?? data['room'] ?? '',
          'branch': data['branch'] ?? '',
          'year': data['year']?.toString() ?? '2',
          'mobile': data['mobile'] ?? '',
          'parentContactNumber': data['parentContactNumber'] ?? '',
          'role': data['role'],
        };

        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (_) => StudentDashboardScreen(student: studentData)),
          (route) => false,
        );
      } else {
        setState(() => _errorMsg = _cleanErrorMessage(data['message'], 'Incorrect password. Please try again.'));
      }
    } catch (e) {
      setState(() => _errorMsg = 'Server error. Please try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Password'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.login, size: 60, color: Color(0xFF1E3A8A)),
              const SizedBox(height: 16),
              Text('Welcome Back, ${widget.studentName}!',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
              if (widget.rollNumber.isNotEmpty) ...[
                Text('Roll: ${widget.rollNumber}',
                    style: const TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center),
                const SizedBox(height: 20),
              ] else ...[
                TextField(
                  controller: _rollController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: 'Roll Number',
                    hintText: 'e.g. 25017001009',
                    prefixIcon: const Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: _passController,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  errorText: _errorMsg,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Login',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Login with OTP (Forgot Password)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// 6. STAFF LOGIN SCREEN - Real API (Username + OTP + Password)
// ================================================================
class StaffLoginScreen extends StatefulWidget {
  const StaffLoginScreen({super.key});

  @override
  State<StaffLoginScreen> createState() => _StaffLoginScreenState();
}

class _StaffLoginScreenState extends State<StaffLoginScreen> {
  bool _isLoading = false;
  String? _errorMsg;

  // Authorized Staff & Admin accounts
  final List<Map<String, String>> _staffOptions = [
    {'label': '≡ƒÄô Director: Vijay Rana', 'username': 'director1'},
    {'label': '≡ƒì╜∩╕Å Mess Admin: Jitesh Kumar', 'username': 'messadmin'},
    {'label': '≡ƒæ« Gate Guard', 'username': 'guard'},
  ];

  String _selectedUsername = 'director1';

  Future<void> _sendOtp() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      final response = await http.post(
        Uri.parse('$kBaseUrl/api/auth/staff/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'username': _selectedUsername}),
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        final String staffName = data['staffName'] ?? '';
        final String role = data['role'] ?? '';
        final String maskedMobile = data['mobile'] ?? 'registered number';

        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StaffOtpScreen(
              username: _selectedUsername,
              staffName: staffName,
              role: role,
              maskedMobile: maskedMobile,
            ),
          ),
        );
      } else {
        setState(() => _errorMsg = _cleanErrorMessage(data['message'], 'Username not found'));
      }
    } catch (e) {
      setState(() => _errorMsg = 'Unable to connect to server. Please check your network connection.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff / Admin Login'),
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text('Administration & Staff Portal',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7C3AED)),
                  textAlign: TextAlign.center),
              const SizedBox(height: 4),
              const Text('Select your role and login with OTP',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),

              // Director Contact Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F0FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF7C3AED), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.person_pin, color: Color(0xFF7C3AED), size: 20),
                        SizedBox(width: 8),
                        Text('Hostel Director',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF7C3AED))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('Vijay Rana',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 16, color: Colors.green),
                        const SizedBox(width: 6),
                        const Text('7015821282',
                            style: TextStyle(fontSize: 14, color: Colors.black87)),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Admin Login Guide'),
                                content: const SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('How to login as Admin/Staff:',
                                          style: TextStyle(fontWeight: FontWeight.bold)),
                                      SizedBox(height: 10),
                                      Text('1∩╕ÅΓâú  Select your role from the dropdown below.'),
                                      SizedBox(height: 6),
                                      Text('2∩╕ÅΓâú  Tap "Send OTP" ΓÇô an OTP will be sent to your registered mobile number.'),
                                      SizedBox(height: 6),
                                      Text('3∩╕ÅΓâú  Enter the 6-digit OTP to verify your identity.'),
                                      SizedBox(height: 6),
                                      Text('4∩╕ÅΓâú  Enter your password to complete login.'),
                                      SizedBox(height: 14),
                                      Divider(),
                                      SizedBox(height: 6),
                                      Text('Admin Roles & Access:',
                                          style: TextStyle(fontWeight: FontWeight.bold)),
                                      SizedBox(height: 6),
                                      Text('≡ƒÄô Hostel Director & Management: Vijay Rana (7015821282)'),
                                      Text('≡ƒì╜∩╕Å Mess Admin & Super Admin: Jitesh Kumar (7079232001)'),
                                      Text('≡ƒæ« Gate Guard (Main Entrance)'),
                                      SizedBox(height: 14),
                                      Divider(),
                                      SizedBox(height: 6),
                                      Text('College Website: puranmurti.com',
                                          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                                      SizedBox(height: 4),
                                      Text('Emergency Helpline: Vijay Rana - 7015821282'),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: const Icon(Icons.help_outline, size: 16),
                          label: const Text('How to Login?',
                              style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF7C3AED),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedUsername,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Staff Role',
                  prefixIcon: const Icon(Icons.manage_accounts),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                items: _staffOptions.map((opt) {
                  return DropdownMenuItem<String>(
                    value: opt['username'],
                    child: Text(
                      opt['label']!,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedUsername = val);
                },
              ),
              if (_errorMsg != null) ...[
                const SizedBox(height: 12),
                Text(_errorMsg!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                    textAlign: TextAlign.center),
              ],
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Send OTP',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '┬⌐ PMV Hostel Management System',
                style: TextStyle(color: Colors.grey, fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// 7. STAFF OTP + PASSWORD SCREEN - Real API
// ================================================================
class StaffOtpScreen extends StatefulWidget {
  final String username;
  final String staffName;
  final String role;
  final String maskedMobile;

  const StaffOtpScreen({
    super.key,
    required this.username,
    required this.staffName,
    required this.role,
    required this.maskedMobile,
  });

  @override
  State<StaffOtpScreen> createState() => _StaffOtpScreenState();
}

class _StaffOtpScreenState extends State<StaffOtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _isLoading = false;
  bool _obscure = true;
  String? _errorMsg;

  Future<void> _verifyAndLogin() async {
    final otp = _otpController.text.trim();
    final pass = _passController.text.trim();

    if (otp.length < 6) {
      setState(() => _errorMsg = 'Enter 6-digit OTP');
      return;
    }
    if (pass.isEmpty) {
      setState(() => _errorMsg = 'Enter Password');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      final response = await http.post(
        Uri.parse('$kBaseUrl/api/auth/staff/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': widget.username,
          'otp': otp,
          'password': pass,
        }),
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        if (data['canSetPassword'] == true || (pass.isEmpty && data['token'] == null)) {
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StaffSetPasswordScreen(
                username: widget.username,
                staffName: widget.staffName,
                role: widget.role,
                otp: otp,
              ),
            ),
          );
          return;
        }
        final String token = data['token'] ?? '';
        final String role = data['role'] ?? widget.role;
        final String name = data['name'] ?? widget.staffName;

        if (!mounted) return;

        if (role.contains('DIRECTOR') || role.contains('SUPER_ADMIN')) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => DirectorDashboardScreen(
                  directorTitle: name, token: token),
            ),
            (route) => false,
          );
        } else if (role.contains('WARDEN')) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => WardenDashboardScreen(
                  wardenTitle: name, token: token),
            ),
            (route) => false,
          );
        } else {
          // Gate Guard
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => GuardStatusCheckScreen(token: token),
            ),
            (route) => false,
          );
        }
      } else {
        String msg = 'Invalid OTP or password. Please try again.';
        try {
          final data = json.decode(response.body);
          if (data is Map && data['message'] != null) {
            msg = data['message'].toString();
          }
        } catch (_) {}
        setState(() => _errorMsg = _cleanErrorMessage(msg));
      }
    } catch (e) {
      setState(() => _errorMsg = 'Server error. Please try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify & Login'),
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.verified_user,
                  size: 60, color: Color(0xFF7C3AED)),
              const SizedBox(height: 16),
              Text('Welcome, ${widget.staffName}!',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text(
                'Verification OTP sent to: ${widget.maskedMobile}\n(For testing, use the SMS OTP or 123456)',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _otpController,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 6,
                style: const TextStyle(
                    letterSpacing: 8, fontSize: 26, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '------',
                  labelText: '6-Digit OTP',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _passController,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  errorText: _errorMsg,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyAndLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Verify & Login',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () {
                  final otp = _otpController.text.trim();
                  if (otp.length < 6) {
                    setState(() => _errorMsg = 'Please enter the 6-digit OTP above first');
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StaffSetPasswordScreen(
                        username: widget.username,
                        staffName: widget.staffName,
                        role: widget.role,
                        otp: otp,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.key, size: 16),
                label: const Text('Forgot Password? / Create New Password',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF7C3AED),
                ),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ΓåÉ Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// 7b. STAFF SET / RESET PASSWORD SCREEN
// ================================================================
class StaffSetPasswordScreen extends StatefulWidget {
  final String username;
  final String staffName;
  final String role;
  final String otp;

  const StaffSetPasswordScreen({
    super.key,
    required this.username,
    required this.staffName,
    required this.role,
    required this.otp,
  });

  @override
  State<StaffSetPasswordScreen> createState() => _StaffSetPasswordScreenState();
}

class _StaffSetPasswordScreenState extends State<StaffSetPasswordScreen> {
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _isLoading = false;
  bool _obscure1 = true;
  bool _obscure2 = true;
  String? _errorMsg;

  Future<void> _setPassword() async {
    final pass = _passController.text.trim();
    final confirm = _confirmController.text.trim();

    if (pass.length < 6) {
      setState(() => _errorMsg = 'Password must be at least 6 characters');
      return;
    }
    if (pass != confirm) {
      setState(() => _errorMsg = 'Passwords do not match');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      final response = await http.post(
        Uri.parse('$kBaseUrl/api/auth/staff/set-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': widget.username,
          'otp': widget.otp,
          'newPassword': pass,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final String token = data['token'] ?? '';
        final String role = data['role'] ?? widget.role;
        final String name = data['name'] ?? widget.staffName;

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password set successfully! Logging in...')),
        );

        if (role.contains('DIRECTOR') || role.contains('SUPER_ADMIN') || role.contains('MESS_ADMIN')) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => DirectorDashboardScreen(
                  directorTitle: name, token: token),
            ),
            (route) => false,
          );
        } else if (role.contains('WARDEN')) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => WardenDashboardScreen(
                  wardenTitle: name, token: token),
            ),
            (route) => false,
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => GuardStatusCheckScreen(token: token),
            ),
            (route) => false,
          );
        }
      } else {
        String msg = 'Could not set password (Status ${response.statusCode}). Please try again.';
        try {
          final data = json.decode(response.body);
          if (data is Map && data['message'] != null) {
            msg = data['message'].toString();
          }
        } catch (_) {}
        setState(() => _errorMsg = _cleanErrorMessage(msg));
      }
    } catch (_) {
      setState(() => _errorMsg = 'Network error. Please try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Staff Password'),
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.lock_reset, size: 60, color: Color(0xFF7C3AED)),
              const SizedBox(height: 16),
              Text('Set Password for ${widget.staffName}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
              const SizedBox(height: 6),
              const Text('Create a secure password for future logins.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              TextField(
                controller: _passController,
                obscureText: _obscure1,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure1 ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscure1 = !_obscure1),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _confirmController,
                obscureText: _obscure2,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure2 ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscure2 = !_obscure2),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  errorText: _errorMsg,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _setPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save Password & Login',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// 8. STUDENT DASHBOARD
// ================================================================
class StudentDashboardScreen extends StatelessWidget {
  final Map<String, dynamic> student;
  const StudentDashboardScreen({super.key, required this.student});

  void _showMessMenuDialog(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    // Official 7-day weekly schedule from hostel administration
    final Map<String, Map<String, String>> weeklySchedule = {
      'MONDAY': {
        'BREAKFAST': 'Parantha, Curd & Tea',
        'LUNCH': 'Roti, Chawal, Dal, Kadu Sabzi, Raita',
        'SNACK': 'Pakoda, Tea',
        'DINNER': 'Roti, Chawal, Dal, Aloo Gobhi Sabzi',
      },
      'TUESDAY': {
        'BREAKFAST': 'Milk and Banana',
        'LUNCH': 'Kadi, Chawal, Sabzi, Salad',
        'SNACK': 'Rusk, Tea',
        'DINNER': 'Roti, Kheer, Aloo Chana Sabzi',
      },
      'WEDNESDAY': {
        'BREAKFAST': 'Pasta',
        'LUNCH': 'Roti, Chawal, Lauki Sabzi, Raita',
        'SNACK': 'Fried Rice, Tea',
        'DINNER': 'Roti, Chawal, Dal, Soya Chaap Sabzi',
      },
      'THURSDAY': {
        'BREAKFAST': 'Poha',
        'LUNCH': 'Roti, Chawal, Bhindi Sabzi, Raita',
        'SNACK': 'Manchurian, Tea',
        'DINNER': 'Roti, Chawal, Dal, Bhindi Sabzi',
      },
      'FRIDAY': {
        'BREAKFAST': 'Masala Chana',
        'LUNCH': 'Puri, Sabzi, Halwa, Raita, Salad',
        'SNACK': 'Fried Beaten Rice, Tea',
        'DINNER': 'Roti, Chawal, Chicken Curry, Paneer Curry',
      },
      'SATURDAY': {
        'BREAKFAST': 'Khichdi',
        'LUNCH': 'Roti, Chawal, Aloo Palak, Raita',
        'SNACK': 'Matthi, Tea',
        'DINNER': 'Roti, Chawal, Dal, Aloo Soyabean Sabzi',
      },
      'SUNDAY': {
        'BREAKFAST': 'Idly or Pasta',
        'LUNCH': 'Chole, Bhature',
        'SNACK': 'Noodles, Tea',
        'DINNER': 'Roti, Chawal, Anda Curry, Paneer Curry',
      },
    };

    final days = ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'];
    final dayLabels = {'MONDAY': 'Mon', 'TUESDAY': 'Tue', 'WEDNESDAY': 'Wed', 'THURSDAY': 'Thu', 'FRIDAY': 'Fri', 'SATURDAY': 'Sat', 'SUNDAY': 'Sun'};

    // Determine today's day of week
    final nowDt = DateTime.now();
    final todayDayName = days[nowDt.weekday - 1];
    String selectedDay = todayDayName;

    List apiMenuList = [];
    List timingList = [];

    try {
      final menuRes = await http.get(Uri.parse('$kBaseUrl/api/mess-menu/today')).timeout(const Duration(seconds: 6));
      final timingRes = await http.get(Uri.parse('$kBaseUrl/api/mess-timing')).timeout(const Duration(seconds: 6));
      if (menuRes.statusCode == 200) apiMenuList = json.decode(menuRes.body);
      if (timingRes.statusCode == 200) timingList = json.decode(timingRes.body);
    } catch (_) {}

    if (!context.mounted) return;
    Navigator.pop(context); // Close loading spinner

    final mealIcons = {'BREAKFAST': '≡ƒîà', 'LUNCH': 'ΓÿÇ∩╕Å', 'SNACK': '≡ƒì╡', 'DINNER': '≡ƒîÖ'};
    final defaultTimings = {
      'BREAKFAST': {'start': '08:00', 'end': '09:30'},
      'LUNCH': {'start': '12:15', 'end': '14:15'},
      'SNACK': {'start': '17:00', 'end': '18:00'},
      'DINNER': {'start': '19:30', 'end': '21:30'},
    };

    final String roll = student['rollNumber'] ?? '';
    final now = TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setMenuState) {
          final isViewingToday = (selectedDay == todayDayName);
          final dayMenu = weeklySchedule[selectedDay] ?? {};

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.restaurant_menu, color: Color(0xFFD97706)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text("Mess Menu & Timetable",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isViewingToday ? 'Today ($selectedDay)' : selectedDay,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF92400E)),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Day of Week Selector Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: days.map((d) {
                          final isSelected = (d == selectedDay);
                          final isToday = (d == todayDayName);
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(
                                isToday ? '${dayLabels[d]} (Today)' : dayLabels[d]!,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? Colors.white : Colors.black87,
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: const Color(0xFFD97706),
                              backgroundColor: Colors.grey.shade100,
                              onSelected: (_) {
                                setMenuState(() => selectedDay = d);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Information Note
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Color(0xFF92400E)),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              "Mess entry strictly allowed during schedule timings. Rate meals daily to help improve food quality!",
                              style: TextStyle(color: Color(0xFF92400E), fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Meals List for Selected Day
                    ...['BREAKFAST', 'LUNCH', 'SNACK', 'DINNER'].map((meal) {
                      // Determine items text
                      String itemsText = dayMenu[meal] ?? 'Meal details not set';
                      // If viewing today and API returned items for today, use API items
                      int? menuId;
                      if (isViewingToday && apiMenuList.isNotEmpty) {
                        final found = apiMenuList.firstWhere(
                          (m) => m['mealType'] == meal,
                          orElse: () => null,
                        );
                        if (found != null && found['items'] != null && (found['items'] as String).isNotEmpty) {
                          itemsText = found['items'];
                          menuId = found['id'];
                        }
                      }

                      // Determine timing
                      final timingFromApi = timingList.firstWhere(
                        (t) => t['mealType'] == meal,
                        orElse: () => null,
                      );
                      String startTime = timingFromApi != null && timingFromApi['startTime'] != null
                          ? timingFromApi['startTime'].toString().substring(0, 5)
                          : defaultTimings[meal]!['start']!;
                      String endTime = timingFromApi != null && timingFromApi['endTime'] != null
                          ? timingFromApi['endTime'].toString().substring(0, 5)
                          : defaultTimings[meal]!['end']!;

                      String timeStatus = '';
                      Color statusColor = Colors.grey;

                      if (isViewingToday) {
                        final startParts = startTime.split(':');
                        final endParts = endTime.split(':');
                        final startMinutes = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
                        final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

                        if (nowMinutes < startMinutes) {
                          timeStatus = 'Not Available Yet (Opens at $startTime)';
                          statusColor = Colors.orange.shade800;
                        } else if (nowMinutes >= startMinutes && nowMinutes <= endMinutes) {
                          timeStatus = 'Active Now (Mess Open)';
                          statusColor = Colors.green.shade700;
                        } else {
                          timeStatus = 'Service Ended';
                          statusColor = Colors.grey.shade600;
                        }
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isViewingToday && timeStatus.contains('Active')
                              ? const Color(0xFFF0FDF4)
                              : const Color(0xFFFFFBEB),
                          border: Border.all(
                            color: isViewingToday && timeStatus.contains('Active')
                                ? Colors.green.shade300
                                : const Color(0xFFFDE68A),
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('${mealIcons[meal] ?? '≡ƒì╜∩╕Å'} $meal',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF92400E))),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.black12),
                                  ),
                                  child: Text(
                                    '$startTime - $endTime',
                                    style: const TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            if (isViewingToday && timeStatus.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.access_time, size: 12, color: statusColor),
                                  const SizedBox(width: 4),
                                  Text(timeStatus, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ],
                            const SizedBox(height: 6),
                            Text(itemsText, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                            if (isViewingToday) ...[
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    _showRateMealDialog(context, menuId ?? 1, meal, roll);
                                  },
                                  icon: const Icon(Icons.star, size: 16, color: Colors.amber),
                                  label: const Text('Rate Meal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFD97706),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showRateMealDialog(BuildContext context, dynamic menuId, String mealType, String rollNumber) {
    int selectedRating = 5;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Rate $mealType Quality', style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please rate the meal served today:', style: TextStyle(fontSize: 13, color: Colors.black54)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starNum = index + 1;
                  return IconButton(
                    icon: Icon(
                      starNum <= selectedRating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 36,
                    ),
                    onPressed: () {
                      setDialogState(() => selectedRating = starNum);
                    },
                  );
                }),
              ),
              const SizedBox(height: 8),
              Text(
                selectedRating == 5
                    ? 'Excellent Γ¡ÉΓ¡ÉΓ¡ÉΓ¡ÉΓ¡É'
                    : selectedRating == 4
                        ? 'Good Γ¡ÉΓ¡ÉΓ¡ÉΓ¡É'
                        : selectedRating == 3
                            ? 'Average Γ¡ÉΓ¡ÉΓ¡É'
                            : selectedRating == 2
                                ? 'Poor Γ¡ÉΓ¡É'
                                : 'Very Bad Γ¡É',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFD97706)),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  final res = await http.post(
                    Uri.parse('$kBaseUrl/api/meal-rating'),
                    headers: {'Content-Type': 'application/json'},
                    body: json.encode({
                      'menuId': menuId,
                      'studentRollNumber': rollNumber,
                      'rating': selectedRating,
                    }),
                  );
                  if (!context.mounted) return;
                  if (res.statusCode == 200) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Thank you! Your $selectedRating-star rating for $mealType has been recorded.')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Rating saved! Thank you for your feedback.')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Network error saving rating.')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
                foregroundColor: Colors.white,
              ),
              child: const Text('Submit Rating'),
            ),
          ],
        ),
      ),
    );
  }

  void _showComplaintsDialog(BuildContext context, String roll, String name) {
    final descController = TextEditingController();
    String selectedCategory = 'Mess & Food Quality';
    XFile? recordedVideo;
    bool isSubmitting = false;
    final categories = [
      'Mess & Food Quality',
      'Room Maintenance',
      'Electricity & Fan',
      'Water Supply & Geyser',
      'Cleanliness & Washroom',
      'Wi-Fi / Internet',
      'Other',
    ];

    showDialog(
      context: context,
      builder: (ctx) => DefaultTabController(
        length: 2,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Hostel Complaints Portal', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: double.maxFinite,
            height: 480,
            child: Column(
              children: [
                const TabBar(
                  labelColor: Color(0xFF1E3A8A),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Color(0xFF1E3A8A),
                  tabs: [
                    Tab(icon: Icon(Icons.edit_note), text: 'New Complaint'),
                    Tab(icon: Icon(Icons.history), text: 'My History'),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: TabBarView(
                    children: [
                      // Tab 1: New Complaint Form
                      StatefulBuilder(
                        builder: (context, setFormState) => SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<String>(
                                value: selectedCategory,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                items: categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat, style: const TextStyle(fontSize: 13)))).toList(),
                                onChanged: (val) {
                                  if (val != null) setFormState(() => selectedCategory = val);
                                },
                              ),
                              const SizedBox(height: 10),
                              const Text('Description of Issue', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                              const SizedBox(height: 4),
                              TextField(
                                controller: descController,
                                maxLines: 3,
                                decoration: InputDecoration(
                                  hintText: 'Describe the issue clearly...',
                                  hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text('20s Video Proof (Optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: isSubmitting
                                          ? null
                                          : () async {
                                              try {
                                                final picker = ImagePicker();
                                                final picked = await picker.pickVideo(
                                                  source: ImageSource.camera,
                                                  maxDuration: const Duration(seconds: 20),
                                                );
                                                if (picked != null) {
                                                  setFormState(() => recordedVideo = picked);
                                                }
                                              } catch (e) {
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text('Could not record video: $e')),
                                                  );
                                                }
                                              }
                                            },
                                      icon: const Icon(Icons.videocam, size: 18),
                                      label: const Text('Record 20s Video', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                        foregroundColor: const Color(0xFF1E3A8A),
                                        side: const BorderSide(color: Color(0xFF1E3A8A)),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    onPressed: isSubmitting
                                        ? null
                                        : () async {
                                            try {
                                              final picker = ImagePicker();
                                              final picked = await picker.pickVideo(
                                                source: ImageSource.gallery,
                                                maxDuration: const Duration(seconds: 20),
                                              );
                                              if (picked != null) {
                                                setFormState(() => recordedVideo = picked);
                                              }
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Could not pick video: $e')),
                                                );
                                              }
                                            }
                                          },
                                    icon: const Icon(Icons.file_upload_outlined, size: 18),
                                    label: const Text('Gallery', style: TextStyle(fontSize: 11)),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                      foregroundColor: Colors.black87,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ],
                              ),
                              if (recordedVideo != null) ...[
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFF3B82F6)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.check_circle, size: 16, color: Color(0xFF2563EB)),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Attached: ${recordedVideo!.name}',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      InkWell(
                                        onTap: isSubmitting ? null : () => setFormState(() => recordedVideo = null),
                                        child: const Padding(
                                          padding: EdgeInsets.all(2),
                                          child: Icon(Icons.close, size: 16, color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 4),
                              const Text(
                                'Γä╣∩╕Å Short proof (max 20s). Auto-deletes 24 hrs after review.',
                                style: TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                height: 44,
                                child: ElevatedButton.icon(
                                  onPressed: isSubmitting
                                      ? null
                                      : () async {
                                          final desc = descController.text.trim();
                                          if (desc.isEmpty) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Please enter a description for the complaint.')),
                                            );
                                            return;
                                          }
                                          setFormState(() => isSubmitting = true);

                                          try {
                                            final uri = Uri.parse('/api/complaints/submit-with-video');
                                            final req = http.MultipartRequest('POST', uri);
                                            req.headers['ngrok-skip-browser-warning'] = 'true';
                                            req.fields['studentName'] = name;
                                            req.fields['studentRollNumber'] = roll;
                                            req.fields['category'] = selectedCategory;
                                            req.fields['description'] = desc;

                                            if (recordedVideo != null) {
                                              req.files.add(await http.MultipartFile.fromPath('file', recordedVideo!.path));
                                            }

                                            final sRes = await req.send().timeout(const Duration(seconds: 60));
                                            final resp = await http.Response.fromStream(sRes);

                                            if (!context.mounted) return;
                                            Navigator.pop(ctx);

                                            if (resp.statusCode == 200) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Complaint with video proof registered successfully! The Warden & Director will review it.')),
                                              );
                                            } else {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Complaint submitted successfully.')),
                                              );
                                            }
                                          } catch (e) {
                                            if (context.mounted) {
                                              Navigator.pop(ctx);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Network notice: ')),
                                              );
                                            }
                                          }
                                        },
                                  icon: isSubmitting
                                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                      : const Icon(Icons.send, size: 18),
                                  label: Text(
                                    isSubmitting ? 'Uploading & Submitting...' : 'Submit Complaint',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFDC2626),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Tab 2: My Complaints History
                      FutureBuilder<http.Response>(
                        future: http.get(Uri.parse('$kBaseUrl/api/complaints/my?rollNumber=$roll')),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (!snapshot.hasData || snapshot.data?.statusCode != 200) {
                            return const Center(child: Text('Could not fetch complaints history.'));
                          }
                          final List list = json.decode(snapshot.data!.body);
                          if (list.isEmpty) {
                            return const Center(
                              child: Text('You have not filed any complaints yet.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                            );
                          }
                          return ListView.builder(
                            itemCount: list.length,
                            itemBuilder: (context, i) {
                              final item = list[i];
                              final status = item['status'] ?? 'Submitted';
                              final color = status == 'Resolved'
                                  ? Colors.green
                                  : status == 'In Progress'
                                      ? Colors.blue
                                      : Colors.orange;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(item['category'] ?? 'Complaint',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: color.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(item['description'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                                      if (item['videoUrl'] != null && item['videoUrl'].toString().isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Row(
                                          children: const [
                                            Icon(Icons.videocam, size: 14, color: Color(0xFF2563EB)),
                                            SizedBox(width: 4),
                                            Text('20s Video Proof Attached', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                                          ],
                                        ),
                                      ] else if (item['videoDeleted'] == true) ...[
                                        const SizedBox(height: 6),
                                        Row(
                                          children: const [
                                            Icon(Icons.auto_delete, size: 14, color: Colors.grey),
                                            SizedBox(width: 4),
                                            Text('Video proof expired and auto-deleted', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ],
        ),
      ),
    );
  }

  void _showGatePassStatusDialog(BuildContext context, String roll) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final res = await http.get(Uri.parse('$kBaseUrl/api/gatepass/status/$roll')).timeout(const Duration(seconds: 8));
      if (!context.mounted) return;
      Navigator.pop(context);

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final status = data['status'] ?? 'UNKNOWN';
        final statusColor = status == 'APPROVED'
            ? Colors.green
            : status == 'OUT'
                ? Colors.blue
                : status == 'RETURNED'
                    ? Colors.purple
                    : Colors.orange;

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(children: [
              Icon(Icons.badge, color: Color(0xFF2563EB)),
              SizedBox(width: 8),
              Text('My Gate Pass Status', style: TextStyle(fontWeight: FontWeight.bold)),
            ]),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                    child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 16),
                _statusRow('Reason', data['reason'] ?? 'Going out'),
                _statusRow('Expected Out', data['exitTime'] ?? '-'),
                _statusRow('Expected Return', data['expectedReturnTime'] ?? '-'),
                if (data['actualExitTime'] != null) _statusRow('Actual Gate Exit', data['actualExitTime']),
                if (data['actualReturnTime'] != null) _statusRow('Actual Gate Return', data['actualReturnTime']),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No active gate pass found. You can apply for one below.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not fetch gate pass status.')),
        );
      }
    }
  }

  Widget _statusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text('$label:', style: const TextStyle(color: Colors.black54, fontSize: 12))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        ],
      ),
    );
  }

  void _showApplyGatePassDialog(BuildContext context) {
    final reasonController = TextEditingController();
    final outController = TextEditingController(text: '09:00');
    final returnController = TextEditingController(text: '17:00');

    final now = DateTime.now();
    final isWeekend = (now.weekday == DateTime.saturday || now.weekday == DateTime.sunday);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.exit_to_app, color: Color(0xFF059669)),
          SizedBox(width: 8),
          Text('Apply for Gate Pass', style: TextStyle(fontWeight: FontWeight.bold)),
        ]),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gate Pass Hostel Rules Notice
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isWeekend ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isWeekend ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isWeekend ? Icons.check_circle : Icons.warning_amber_rounded,
                          size: 18,
                          color: isWeekend ? const Color(0xFF059669) : const Color(0xFFDC2626),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isWeekend ? 'Weekend Outing Window Active' : 'Notice: Weekday Outing Restricted',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: isWeekend ? const Color(0xFF059669) : const Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'ΓÇó Gate pass permitted ONLY on Saturday & Sunday.\nΓÇó All students must return by 05:00 PM (17:00).\nΓÇó Approved solely by Hostel Director (Vijay Rana).',
                      style: TextStyle(fontSize: 11, color: Colors.black87, height: 1.4),
                    ),
                    const Divider(height: 12),
                    const Text(
                      '≡ƒÜ¿ Emergency Notice:\nFor urgent weekday leave, contact Hostel Director Vijay Rana directly at 7015821282.',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFB91C1C)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              TextField(
                controller: reasonController,
                decoration: InputDecoration(
                  labelText: 'Reason for Outing',
                  hintText: 'e.g. Market, Medical, Emergency',
                  prefixIcon: const Icon(Icons.edit_note),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: outController,
                decoration: InputDecoration(
                  labelText: 'Expected Out Time (HH:MM)',
                  hintText: '09:00',
                  prefixIcon: const Icon(Icons.access_time),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: returnController,
                decoration: InputDecoration(
                  labelText: 'Expected Return Time (Max 17:00)',
                  hintText: '17:00',
                  prefixIcon: const Icon(Icons.alarm),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  helperText: 'Return deadline is 05:00 PM (17:00)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              final outTime = outController.text.trim();
              final returnTime = returnController.text.trim();

              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter reason for going out.')),
                );
                return;
              }

              // Validate return time <= 17:00
              if (returnTime.contains(':')) {
                final parts = returnTime.split(':');
                final hour = int.tryParse(parts[0]) ?? 0;
                final min = int.tryParse(parts[1]) ?? 0;
                if (hour > 17 || (hour == 17 && min > 0)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Return time cannot be later than 05:00 PM (17:00). Please adjust.')),
                  );
                  return;
                }
              }

              Navigator.pop(ctx);
              try {
                final token = student['token'] ?? '';
                final res = await http.post(
                  Uri.parse('$kBaseUrl/api/gatepass'),
                  headers: {
                    'Content-Type': 'application/json',
                    if (token.isNotEmpty) 'Authorization': 'Bearer $token',
                  },
                  body: json.encode({
                    'studentName': student['name'],
                    'studentRollNumber': student['rollNumber'],
                    'reason': reason,
                    'parentPhone': student['parentContactNumber'] ?? '',
                    'exitTime': outTime,
                    'expectedReturnTime': returnTime,
                  }),
                ).timeout(const Duration(seconds: 10));

                if (!context.mounted) return;
                if (res.statusCode == 200) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gate Pass Applied! Submitted to Hostel Director (Vijay Rana) for approval.')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(res.body.isNotEmpty ? res.body : 'Could not submit gate pass.')),
                  );
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Network error submitting gate pass. Please retry.')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
            ),
            child: const Text('Submit to Director'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String name = student['name'] ?? 'Student';
    final String roll = student['rollNumber'] ?? '';
    final String hostel = student['hostel'] ?? '';
    final String room = student['roomNumber'] ?? '';
    final String branch = student['branch'] ?? '';
    final String year = student['year']?.toString() ?? '2';
    final String mobile = student['mobile'] ?? '';
    final String parentPhone = student['parentContactNumber'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: const Text('Student Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
              (route) => false,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Digital Identity Card with QR
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    const Text('PURAN MURTI VIDYAPEETH',
                        style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.bold)),
                    const Text('DIGITAL IDENTITY CARD',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    const SizedBox(height: 16),
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'S',
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(name,
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 2),
                    Text('Roll No: $roll', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 4),
                    if (branch.isNotEmpty)
                      Text('$branch ΓÇó Year $year',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center),
                    const SizedBox(height: 4),
                    if (hostel.isNotEmpty)
                      Text('$hostel | Room: $room', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    if (mobile.isNotEmpty)
                      Text('Student Mobile: +91 $mobile', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    if (parentPhone.isNotEmpty)
                      Text('Parent Mobile: +91 $parentPhone', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    const SizedBox(height: 20),
                    // Live QR Code
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: QrImageView(
                        data: roll,
                        version: QrVersions.auto,
                        size: 140,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Scan for Mess Entry & Gate Pass',
                        style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Action Buttons in 2x2 Grid
            Row(
              children: [
                Expanded(
                  child: _actionBtn(
                    label: 'Gate Pass Apply',
                    subtitle: 'Request leave',
                    icon: Icons.exit_to_app,
                    color: const Color(0xFF059669),
                    onTap: () => _showApplyGatePassDialog(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _actionBtn(
                    label: 'Pass Status',
                    subtitle: 'Check approval',
                    icon: Icons.badge_outlined,
                    color: const Color(0xFF2563EB),
                    onTap: () => _showGatePassStatusDialog(context, roll),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _actionBtn(
                    label: 'Mess Menu & Rating',
                    subtitle: 'Daily meals & ratings',
                    icon: Icons.restaurant_menu,
                    color: const Color(0xFFD97706),
                    onTap: () => _showMessMenuDialog(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _actionBtn(
                    label: 'Hostel Complaints',
                    subtitle: 'File room/food issue',
                    icon: Icons.report_problem_outlined,
                    color: const Color(0xFFDC2626),
                    onTap: () => _showComplaintsDialog(context, roll, name),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // College & Hostel Information Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.apartment, size: 20, color: Color(0xFF1E3A8A)),
                      SizedBox(width: 8),
                      Text('Hostel Campus Information',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A8A))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('ΓÇó Boys Hostel: Block 1, Block 2, Block 3, Block 4\nΓÇó Girls Hostel: Building G1\nΓÇó Official Website: puranmurti.com',
                      style: TextStyle(fontSize: 12, color: Colors.black87, height: 1.4)),
                  const Divider(height: 14),
                  const Row(
                    children: [
                      Icon(Icons.support_agent, size: 16, color: Colors.green),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '≡ƒÅ¢∩╕Å Chairman: Vijay Pal Nain\n≡ƒÄô Hostel Director: Vijay Rana (7015821282)\n≡ƒì╜∩╕Å Mess Admin: Jitesh Kumar (7079232001)',
                          style: TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.w500, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn({
    required String label,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 6),
            Text(label,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                textAlign: TextAlign.center),
            const SizedBox(height: 2),
            Text(subtitle,
                style: const TextStyle(color: Colors.white70, fontSize: 10),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// 9. DIRECTOR DASHBOARD
// ================================================================
class DirectorDashboardScreen extends StatefulWidget {
  final String directorTitle;
  final String token;
  const DirectorDashboardScreen(
      {super.key, required this.directorTitle, required this.token});

  @override
  State<DirectorDashboardScreen> createState() =>
      _DirectorDashboardScreenState();
}

class _DirectorDashboardScreenState extends State<DirectorDashboardScreen> {
  int _currentTab = 0; // 0: Gate Pass, 1: Mess Entry, 2: Complaints
  int _gatePassSubTab = 0; // 0: Pending, 1: Approved Today

  List<dynamic> _pendingPasses = [];
  List<dynamic> _approvedPasses = [];
  List<dynamic> _todayMessScans = [];
  List<dynamic> _complaints = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _loadGatePasses(),
      _loadMessScans(),
      _loadComplaints(),
    ]);
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadGatePasses() async {
    try {
      final pRes = await http.get(
        Uri.parse('$kBaseUrl/api/gatepass/pending'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      ).timeout(const Duration(seconds: 10));
      if (pRes.statusCode == 200) {
        _pendingPasses = json.decode(pRes.body);
      }
      final aRes = await http.get(
        Uri.parse('$kBaseUrl/api/gatepass/approved/today'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      ).timeout(const Duration(seconds: 10));
      if (aRes.statusCode == 200) {
        _approvedPasses = json.decode(aRes.body);
      }
    } catch (_) {}
  }

  Future<void> _loadMessScans() async {
    try {
      final res = await http.get(
        Uri.parse('$kBaseUrl/api/scan/today'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        _todayMessScans = json.decode(res.body);
      }
    } catch (_) {}
  }

  Future<void> _loadComplaints() async {
    try {
      final res = await http.get(
        Uri.parse('$kBaseUrl/api/complaints'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        _complaints = json.decode(res.body);
      }
    } catch (_) {}
  }

  Future<void> _approvePass(int passId) async {
    try {
      await http.post(
        Uri.parse('$kBaseUrl/api/gatepass/$passId/approve'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gate Pass Approved! Γ£à')));
      _loadGatePasses().then((_) {
        if (mounted) setState(() {});
      });
    } catch (_) {}
  }

  Future<void> _rejectPass(int passId) async {
    try {
      await http.post(
        Uri.parse('$kBaseUrl/api/gatepass/$passId/reject'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gate Pass Rejected! Γ¥î')));
      _loadGatePasses().then((_) {
        if (mounted) setState(() {});
      });
    } catch (_) {}
  }

  Future<void> _updateComplaintStatus(int complaintId, String status) async {
    try {
      final res = await http.post(
        Uri.parse('$kBaseUrl/api/complaints/$complaintId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: json.encode({'status': status}),
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Complaint status marked as "$status"!')),
        );
        _loadComplaints().then((_) {
          if (mounted) setState(() {});
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(widget.directorTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'QR Scanner',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LiveQrScannerScreen(token: widget.token),
              ),
            ).then((_) => _loadAllData()),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadAllData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
              (route) => false,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAllData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildCurrentTab(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab,
        onTap: (idx) {
          setState(() => _currentTab = idx);
          if (idx == 2) _loadComplaints();
          if (idx == 1) _loadMessScans();
          if (idx == 0) _loadGatePasses();
        },
        selectedItemColor: const Color(0xFF1E3A8A),
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: Badge(
              label: Text('${_pendingPasses.length}'),
              isLabelVisible: _pendingPasses.isNotEmpty,
              child: const Icon(Icons.sensor_door),
            ),
            label: 'Gate Pass',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              label: Text('${_todayMessScans.length}'),
              isLabelVisible: _todayMessScans.isNotEmpty,
              child: const Icon(Icons.restaurant),
            ),
            label: 'Mess Entry',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              label: Text('${_complaints.where((c) => c['status'] != 'Resolved').length}'),
              isLabelVisible: _complaints.any((c) => c['status'] != 'Resolved'),
              child: const Icon(Icons.report_problem),
            ),
            label: 'Complaints',
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentTab() {
    switch (_currentTab) {
      case 0:
        return _buildGatePassTab();
      case 1:
        return _buildMessEntryTab();
      case 2:
        return _buildComplaintsTab();
      default:
        return _buildGatePassTab();
    }
  }

  // ==================== TAB 1: GATE PASS ====================
  Widget _buildGatePassTab() {
    return Column(
      children: [
        // Sub-tab toggles
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: Center(
                    child: Text('Pending (${_pendingPasses.length})',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _gatePassSubTab == 0 ? Colors.white : Colors.black87)),
                  ),
                  selected: _gatePassSubTab == 0,
                  selectedColor: const Color(0xFF1E3A8A),
                  backgroundColor: const Color(0xFFF3F4F6),
                  onSelected: (val) {
                    if (val) setState(() => _gatePassSubTab = 0);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ChoiceChip(
                  label: Center(
                    child: Text('Approved Today (${_approvedPasses.length})',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _gatePassSubTab == 1 ? Colors.white : Colors.black87)),
                  ),
                  selected: _gatePassSubTab == 1,
                  selectedColor: const Color(0xFF16A34A),
                  backgroundColor: const Color(0xFFF3F4F6),
                  onSelected: (val) {
                    if (val) setState(() => _gatePassSubTab = 1);
                  },
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _gatePassSubTab == 0 ? _buildPendingPassesList() : _buildApprovedPassesList(),
        ),
      ],
    );
  }

  Widget _buildPendingPassesList() {
    if (_pendingPasses.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
            SizedBox(height: 12),
            Text('No pending gate passes!',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
            SizedBox(height: 4),
            Text('All requests have been reviewed.', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingPasses.length,
      itemBuilder: (ctx, i) {
        final pass = _pendingPasses[i];
        final String name = pass['studentName'] ?? 'Student';
        final String roll = pass['studentRollNumber'] ?? '';
        final String exitTime = pass['exitTime'] ?? '';
        final String returnTime = pass['expectedReturnTime'] ?? '';
        final String reason = pass['reason'] ?? '';

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFFFEF3C7),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'S',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 2),
                          Text('Roll No: $roll', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('PENDING',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('≡ƒòÆ Outing: Exit $exitTime ΓåÆ Return $returnTime',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('≡ƒô¥ Reason: $reason', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _rejectPass(pass['id']),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: () => _approvePass(pass['id']),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildApprovedPassesList() {
    if (_approvedPasses.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sensor_door_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('No approved gate passes today.',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
            SizedBox(height: 4),
            Text('Approved passes for today will appear here.', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _approvedPasses.length,
      itemBuilder: (ctx, i) {
        final pass = _approvedPasses[i];
        final String name = pass['studentName'] ?? 'Student';
        final String roll = pass['studentRollNumber'] ?? '';
        final String mobile = pass['mobile'] ?? '';
        final String exitTime = pass['exitTime'] ?? '';
        final String returnTime = pass['expectedReturnTime'] ?? '';
        final String status = pass['status'] ?? 'APPROVED';

        Color statusColor = const Color(0xFF16A34A);
        if (status == 'OUT') statusColor = const Color(0xFFD97706);
        if (status == 'RETURNED') statusColor = const Color(0xFF2563EB);

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: statusColor.withOpacity(0.15),
                      child: Icon(Icons.check_circle, color: statusColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 2),
                          Text('Roll No: $roll', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                          if (mobile.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text('≡ƒô▒ Mobile: +91 $mobile',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E3A8A))),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(status,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text('Exit: $exitTime  ΓÇó  Return: $returnTime',
                          style: const TextStyle(fontSize: 12, color: Colors.black87)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==================== TAB 2: MESS ENTRY ====================
  Widget _buildMessEntryTab() {
    return Column(
      children: [
        // Action banner
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Today's Mess Entries",
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('${_todayMessScans.length} students entered today',
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => LiveQrScannerScreen(token: widget.token)),
                ).then((_) => _loadMessScans()),
                icon: const Icon(Icons.qr_code_scanner, size: 18),
                label: const Text('Scan QR', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _todayMessScans.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.restaurant_outlined, size: 64, color: Colors.grey),
                      const SizedBox(height: 12),
                      const Text('No mess entries recorded today yet.',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
                      const SizedBox(height: 6),
                      const Text('Tap "Scan QR" to start recording student meal entries.',
                          style: TextStyle(color: Colors.grey, fontSize: 13)),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => LiveQrScannerScreen(token: widget.token)),
                        ).then((_) => _loadMessScans()),
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('Open QR Scanner'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _todayMessScans.length,
                  itemBuilder: (ctx, i) {
                    final scan = _todayMessScans[i];
                    final String name = scan['name'] ?? 'Student';
                    final String roll = scan['rollNumber'] ?? '';
                    final String mobile = scan['mobile'] ?? '';
                    final String mealType = scan['mealType'] ?? 'MEAL';
                    final String time = scan['scanTime'] ?? '';

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFFEF3C7),
                          child: const Icon(Icons.restaurant, color: Color(0xFFD97706), size: 20),
                        ),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('Roll No: $roll', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                            if (mobile.isNotEmpty)
                              Text('≡ƒô▒ Mobile: +91 $mobile',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E3A8A))),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF16A34A).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(mealType,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                            ),
                            if (time.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(time, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ==================== TAB 3: COMPLAINTS ====================
  Widget _buildComplaintsTab() {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Hostel Complaints Portal",
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('${_complaints.length} total complaints filed by students',
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Color(0xFF1E3A8A)),
                onPressed: _loadComplaints,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _complaints.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                      SizedBox(height: 12),
                      Text('No complaints registered.',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                      SizedBox(height: 4),
                      Text('When students submit complaints, they will appear here.',
                          style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _complaints.length,
                  itemBuilder: (ctx, i) {
                    final c = _complaints[i];
                    final int id = c['id'] ?? 0;
                    final String name = c['studentName'] ?? 'Student';
                    final String roll = c['studentRollNumber'] ?? '';
                    final String mobile = c['studentMobile'] ?? '';
                    final String category = c['category'] ?? 'General';
                    final String desc = c['description'] ?? '';
                    final String status = c['status'] ?? 'Submitted';
                    final String date = c['createdAt'] ?? '';

                    Color statusColor = const Color(0xFFD97706);
                    if (status == 'In Progress') statusColor = const Color(0xFF2563EB);
                    if (status == 'Resolved') statusColor = const Color(0xFF16A34A);

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  backgroundColor: const Color(0xFFFEE2E2),
                                  child: const Icon(Icons.report_problem, color: Color(0xFFDC2626), size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      const SizedBox(height: 2),
                                      Text('Roll No: $roll', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                                      if (mobile.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text('≡ƒô▒ Mobile: +91 $mobile',
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E3A8A))),
                                      ],
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(status,
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(10),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFE5E7EB)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE0E7FF),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(category,
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF3730A3))),
                                      ),
                                      const Spacer(),
                                      if (date.isNotEmpty)
                                        Text(date, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(desc, style: const TextStyle(fontSize: 14, color: Colors.black87)),
                                ],
                              ),
                            ),
                            if (c['videoUrl'] != null && c['videoUrl'].toString().isNotEmpty) ...[
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    final rawUrl = c['videoUrl'].toString();
                                    final fullUrl = rawUrl.startsWith('http') ? rawUrl : '$kBaseUrl$rawUrl';
                                    final uri = Uri.parse(fullUrl);
                                    try {
                                      bool launched = false;
                                      try {
                                        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
                                      } catch (_) {}
                                      if (!launched) {
                                        try {
                                          launched = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
                                        } catch (_) {}
                                      }
                                      if (!launched) {
                                        try {
                                          launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
                                        } catch (_) {}
                                      }
                                      if (!launched && mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Could not open video player.')),
                                        );
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Error playing video: ')),
                                        );
                                      }
                                    }
                                  },
                                  icon: const Icon(Icons.play_circle_fill, size: 20),
                                  label: const Text('Watch 20s Video Proof', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1E3A8A),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Center(
                                child: Text(
                                  'Γä╣∩╕Å Video will auto-delete in 24-48 hours after being viewed.',
                                  style: TextStyle(fontSize: 10, color: Colors.grey),
                                ),
                              ),
                            ] else if (c['videoDeleted'] == true) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.auto_delete_outlined, size: 15, color: Colors.grey),
                                    SizedBox(width: 6),
                                    Text('20s Video proof expired & auto-deleted after review',
                                        style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic)),
                                  ],
                                ),
                              ),
                            ],
                            if (status != 'Resolved') ...[
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (status != 'In Progress') ...[
                                    OutlinedButton(
                                      onPressed: () => _updateComplaintStatus(id, 'In Progress'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(0xFF2563EB),
                                        side: const BorderSide(color: Color(0xFF2563EB)),
                                      ),
                                      child: const Text('Mark In Progress'),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  ElevatedButton.icon(
                                    onPressed: () => _updateComplaintStatus(id, 'Resolved'),
                                    icon: const Icon(Icons.check_circle_outline, size: 16),
                                    label: const Text('Resolve Γ£à'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF16A34A),
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ================================================================
// 10. WARDEN DASHBOARD
// ================================================================
class WardenDashboardScreen extends StatelessWidget {
  final String wardenTitle;
  final String token;
  const WardenDashboardScreen(
      {super.key, required this.wardenTitle, required this.token});

  @override
  Widget build(BuildContext context) {
    return DirectorDashboardScreen(
      directorTitle: wardenTitle,
      token: token,
    );
  }
}

// ================================================================
// 11. GATE GUARD SCREEN - Real API
// ================================================================
class GuardStatusCheckScreen extends StatefulWidget {
  final String token;
  const GuardStatusCheckScreen({super.key, required this.token});

  @override
  State<GuardStatusCheckScreen> createState() => _GuardStatusCheckScreenState();
}

class _GuardStatusCheckScreenState extends State<GuardStatusCheckScreen> {
  final TextEditingController _rollController = TextEditingController();
  Map<String, dynamic>? _passInfo;
  bool _isLoading = false;
  String? _errorMsg;

  Future<void> _checkStatus() async {
    final roll = _rollController.text.trim().toUpperCase();
    if (roll.isEmpty) return;

    setState(() {
      _isLoading = true;
      _passInfo = null;
      _errorMsg = null;
    });

    try {
      final response = await http.get(
        Uri.parse('$kBaseUrl/api/gatepass/status/$roll'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        setState(() => _passInfo = json.decode(response.body));
      } else {
        setState(() => _errorMsg = 'No active gate pass found.');
      }
    } catch (e) {
      setState(() => _errorMsg = 'Server error.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gate Guard - Pass Check'),
        backgroundColor: const Color(0xFF374151),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LiveQrScannerScreen(token: widget.token),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
              (route) => false,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _rollController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'Student Roll Number',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.check_circle, color: Colors.green),
                  onPressed: _checkStatus,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _checkStatus,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF374151),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Check Status',
                        style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            if (_errorMsg != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_errorMsg!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center),
              ),
            ],
            if (_passInfo != null) ...[
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_passInfo!['studentName'] ?? '',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const Divider(),
                      _infoRow('Roll', _passInfo!['studentRollNumber'] ?? ''),
                      _infoRow('Status', _passInfo!['status'] ?? ''),
                      _infoRow('Reason', _passInfo!['reason'] ?? ''),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    Color color = Colors.black87;
    if (value == 'APPROVED') color = Colors.green;
    if (value == 'PENDING') color = Colors.orange;
    if (value == 'RETURNED') color = Colors.blue;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ',
              style: const TextStyle(
                  color: Colors.black54, fontWeight: FontWeight.w500)),
          Text(value,
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

// ================================================================
// 12. LIVE QR SCANNER SCREEN - Real API
// ================================================================
class LiveQrScannerScreen extends StatefulWidget {
  final String token;
  const LiveQrScannerScreen({super.key, required this.token});

  @override
  State<LiveQrScannerScreen> createState() => _LiveQrScannerScreenState();
}

class _LiveQrScannerScreenState extends State<LiveQrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _scanned = false;
  String _mode = 'GATE_PASS'; // 'GATE_PASS', 'MESS_ENTRY', 'MESS_EXIT'
  String _selectedMeal = 'LUNCH';
  String _resultMsg = '';
  String _studentName = '';
  String _studentRoll = '';
  String _scanTimestamp = '';
  bool _resultOk = false;

  @override
  void initState() {
    super.initState();
    _autoSelectCurrentMeal();
  }

  void _autoSelectCurrentMeal() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 11) {
      _selectedMeal = 'BREAKFAST';
    } else if (hour >= 11 && hour < 16) {
      _selectedMeal = 'LUNCH';
    } else if (hour >= 16 && hour < 19) {
      _selectedMeal = 'SNACK';
    } else {
      _selectedMeal = 'DINNER';
    }
  }

  Future<void> _handleScan(String qrData) async {
    if (_scanned) return;
    final roll = qrData.trim().toUpperCase();
    if (roll.isEmpty) return;

    setState(() {
      _scanned = true;
      _studentRoll = roll;
      _scanTimestamp = TimeOfDay.now().format(context);
    });

    try {
      if (_mode == 'GATE_PASS') {
        final resp = await http.post(
          Uri.parse('$kBaseUrl/api/gatepass/scan'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${widget.token}',
          },
          body: json.encode({'studentRollNumber': roll}),
        ).timeout(const Duration(seconds: 10));

        final data = json.decode(resp.body);
        setState(() {
          _resultOk = data['allowed'] ?? false;
          _resultMsg = data['message'] ?? '';
          _studentName = data['studentName'] ?? roll;
        });
      } else {
        // MESS_ENTRY
        final resp = await http.post(
          Uri.parse('$kBaseUrl/api/scan/mess'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${widget.token}',
          },
          body: json.encode({
            'studentRollNumber': roll,
            'mealType': _selectedMeal,
          }),
        ).timeout(const Duration(seconds: 10));

        final data = json.decode(resp.body);
        setState(() {
          _resultOk = data['allowed'] ?? false;
          _resultMsg = data['message'] ?? '';
          _studentName = data['studentName'] ?? roll;
        });
      }
    } catch (e) {
      setState(() {
        _resultOk = false;
        _resultMsg = 'Scan failed: Check server connection.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          _mode == 'GATE_PASS'
              ? 'Gate Pass Scanner'
              : 'Mess Entry Scanner',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1F2937),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Mode Selection Header
          Container(
            color: const Color(0xFF111827),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _modeChip('Gate Pass', 'GATE_PASS', Icons.sensor_door),
                    _modeChip('Mess Entry', 'MESS_ENTRY', Icons.restaurant),
                  ],
                ),
                if (_mode == 'MESS_ENTRY') ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Meal: ', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      _mealChip('BREAKFAST', '≡ƒîà'),
                      const SizedBox(width: 4),
                      _mealChip('LUNCH', 'ΓÿÇ∩╕Å'),
                      const SizedBox(width: 4),
                      _mealChip('SNACK', '≡ƒì╡'),
                      const SizedBox(width: 4),
                      _mealChip('DINNER', '≡ƒîÖ'),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Camera Viewfinder
          Expanded(
            flex: 3,
            child: Stack(
              alignment: Alignment.center,
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: (capture) {
                    final barcode = capture.barcodes.first;
                    if (barcode.rawValue != null) {
                      _handleScan(barcode.rawValue!);
                    }
                  },
                ),
                Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    border: Border.all(color: _scanned ? (_resultOk ? Colors.green : Colors.red) : Colors.amber, width: 3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ],
            ),
          ),

          // Results Section
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              color: const Color(0xFF1F2937),
              padding: const EdgeInsets.all(20),
              child: _scanned
                  ? SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _resultOk ? Icons.check_circle : Icons.cancel,
                            color: _resultOk ? Colors.greenAccent : Colors.redAccent,
                            size: 56,
                          ),
                          const SizedBox(height: 8),
                          if (_studentName.isNotEmpty) ...[
                            Text(
                              _studentName,
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Roll: $_studentRoll  ΓÇó  Time: $_scanTimestamp',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: (_resultOk ? Colors.green : Colors.red).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: _resultOk ? Colors.greenAccent : Colors.redAccent),
                            ),
                            child: Text(
                              _resultMsg,
                              style: TextStyle(
                                color: _resultOk ? Colors.greenAccent : Colors.redAccent,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: 180,
                            height: 44,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _scanned = false;
                                  _resultMsg = '';
                                  _studentName = '';
                                  _studentRoll = '';
                                });
                              },
                              icon: const Icon(Icons.qr_code_scanner),
                              label: const Text('Next Scan', style: TextStyle(fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3B82F6),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.qr_code_scanner, color: Colors.white38, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          _mode == 'GATE_PASS'
                              ? 'Point camera at Student Gate Pass QR'
                              : 'Point camera for $_selectedMeal Entry',
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Timestamps are verified and recorded automatically',
                          style: TextStyle(color: Colors.white38, fontSize: 11),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeChip(String label, String modeKey, IconData icon) {
    final isSelected = _mode == modeKey;
    return ChoiceChip(
      avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.white70),
      label: Text(label, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.white70, fontWeight: FontWeight.bold)),
      selected: isSelected,
      selectedColor: const Color(0xFF2563EB),
      backgroundColor: const Color(0xFF374151),
      onSelected: (_) {
        setState(() {
          _mode = modeKey;
          _scanned = false;
          _resultMsg = '';
        });
      },
    );
  }

  Widget _mealChip(String meal, String emoji) {
    final isSelected = _selectedMeal == meal;
    return GestureDetector(
      onTap: () => setState(() => _selectedMeal = meal),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD97706) : const Color(0xFF374151),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '$emoji $meal',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}




