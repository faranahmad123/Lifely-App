import 'package:flutter/material.dart';
import '../../services/ai_service.dart';
import '../../services/firebase_service.dart';
import '../../core/theme/app_theme.dart';

class ConnectionDebugScreen extends StatefulWidget {
  const ConnectionDebugScreen({super.key});

  @override
  State<ConnectionDebugScreen> createState() => _ConnectionDebugScreenState();
}

class _ConnectionDebugScreenState extends State<ConnectionDebugScreen> {
  final AiService _aiService = AiService();
  final FirebaseService _firebaseService = FirebaseService();

  String _flaskStatus = 'Not tested yet';
  String _firestoreStatus = 'Not tested yet';
  bool _isTesting = false;

  Future<void> _runTests() async {
    setState(() {
      _isTesting = true;
      _flaskStatus = 'Testing...';
      _firestoreStatus = 'Testing...';
    });

    try {
      final flaskResult = await _aiService.pingServer();
      setState(() => _flaskStatus = flaskResult);
    } catch (e) {
      setState(() => _flaskStatus = 'Backend Offline ❌: $e');
    }

    try {
      final firestoreResult = await _firebaseService.testFirestoreConnection();
      setState(() => _firestoreStatus = firestoreResult);
    } catch (e) {
      setState(() => _firestoreStatus = 'Firestore Failed ❌: $e');
    }

    setState(() => _isTesting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Connection Debug',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Flask Backend Status',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _flaskStatus,
                    style: TextStyle(
                      fontSize: 14,
                      color: _flaskStatus.contains('✅') ? AppTheme.success : (_flaskStatus.contains('❌') ? AppTheme.danger : Colors.blueGrey),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Divider(height: 32),
                  const Text(
                    'Firestore Status',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _firestoreStatus,
                    style: TextStyle(
                      fontSize: 14,
                      color: _firestoreStatus.contains('✅') ? AppTheme.success : (_firestoreStatus.contains('❌') ? AppTheme.danger : Colors.blueGrey),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isTesting ? null : _runTests,
                icon: _isTesting 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.refresh_rounded, color: Colors.white),
                label: Text(
                  _isTesting ? 'Running Tests...' : 'Run Connections Test',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryMid,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
