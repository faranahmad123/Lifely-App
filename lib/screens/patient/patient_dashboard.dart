import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../../core/theme/app_theme.dart';
import '../../services/firebase_service.dart';
import '../../models/user_model.dart';
import '../../models/scan_report_model.dart';
import 'scan_report_screen.dart';
import 'doctor_list_screen.dart';

class PatientDashboard extends StatefulWidget {
  final Function(int)? onSwitchTab;
  const PatientDashboard({super.key, this.onSwitchTab});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> with TickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  UserModel? _user;
  bool _isLoadingUser = true;

  late AnimationController _particlesController;

  @override
  void initState() {
    super.initState();
    _loadUser();
    
    _particlesController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _particlesController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    try {
      final user = await _firebaseService.getUserProfile(_uid);
      if (mounted) {
        setState(() {
          _user = user;
          _isLoadingUser = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingUser = false);
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: _isLoadingUser
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryMid, strokeWidth: 2.5))
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 80),
                child: Column(
                  children: [
                    _buildHeader(),
                    _buildScanBanner(),
                    _buildQuickActions(),
                    _buildRecentScans(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    final name = _user?.name ?? 'User';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_getGreeting(), style: AppTheme.caption.copyWith(color: AppTheme.textMuted)),
                const SizedBox(height: 2),
                Text(
                  'Hello, $name 👋',
                  style: AppTheme.h1,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              if (widget.onSwitchTab != null) widget.onSwitchTab!(3);
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.avatarGradient,
                boxShadow: AppTheme.shadowLevel2,
              ),
              child: Center(
                child: Text(
                  initials,
                  style: AppTheme.h2.copyWith(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: AppTheme.heroGradient,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusScreen),
          boxShadow: AppTheme.shadowLevel4,
        ),
        child: Stack(
          children: [
            // Floating Particles
            ...List.generate(6, (index) {
              final random = math.Random(index);
              final left = random.nextDouble() * 300;
              final top = random.nextDouble() * 150;
              return AnimatedBuilder(
                animation: _particlesController,
                builder: (context, child) {
                  final offset = math.sin((_particlesController.value * math.pi) + index) * 6;
                  return Positioned(
                    left: left,
                    top: top + offset,
                    child: Container(
                      width: 4, height: 4,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.3), shape: BoxShape.circle),
                    ),
                  );
                },
              );
            }),
            
            // Faded large background icon
            Positioned(
              right: -10,
              bottom: -10,
              child: Icon(Icons.document_scanner_rounded, size: 120, color: Colors.white.withValues(alpha: 0.08)),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(
                          'AI POWERED',
                          style: AppTheme.badge.copyWith(color: Colors.white),
                        ),
                      ),
                      Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.document_scanner_rounded, color: Colors.white, size: 28),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Run AI Health Scan',
                    style: AppTheme.display.copyWith(color: Colors.white, fontSize: 26),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your blood panel values\nfor an instant triage assessment',
                    style: AppTheme.bodyM.copyWith(color: Colors.white.withValues(alpha: 0.82)),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanReportScreen()));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.primaryMid,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                      shadowColor: Colors.transparent,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Start Scan', style: AppTheme.bodyL.copyWith(fontWeight: FontWeight.w700, color: AppTheme.primaryMid, fontSize: 15)),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_rounded, size: 18, color: AppTheme.primaryMid),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Row(
        children: [
          _buildActionCard(
            icon: Icons.calendar_month_rounded,
            label: 'Book\nDoctor',
            iconColor: const Color(0xFF10B981),
            bgColor: const Color(0xFFF0FDF4),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const DoctorListScreen()));
            },
          ),
          const SizedBox(width: 10),
          _buildActionCard(
            icon: Icons.history_rounded,
            label: 'Report\nHistory',
            iconColor: const Color(0xFFF59E0B),
            bgColor: const Color(0xFFFFFBEB),
            onTap: () {
              if (widget.onSwitchTab != null) widget.onSwitchTab!(1);
            },
          ),
          const SizedBox(width: 10),
          _buildActionCard(
            icon: Icons.auto_awesome_rounded,
            label: 'AI\nAnalysis',
            iconColor: const Color(0xFF8B5CF6),
            bgColor: const Color(0xFFFAF5FF),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanReportScreen()));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: ActionCard(
        icon: icon,
        label: label,
        iconColor: iconColor,
        bgColor: bgColor,
        onTap: onTap,
      ),
    );
  }

  Widget _buildRecentScans() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Scans', style: AppTheme.h3),
              TextButton(
                onPressed: () {
                  if (widget.onSwitchTab != null) widget.onSwitchTab!(1);
                },
                child: Text('See All', style: AppTheme.bodyM.copyWith(color: AppTheme.primaryMid, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<ScanReportModel>>(
            stream: _firebaseService.streamPatientReports(_uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: AppTheme.primaryMid, strokeWidth: 2.5)),
                );
              }
              final scans = snapshot.data ?? [];
              if (scans.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: AppTheme.cardDecorationL1,
                  child: Column(
                    children: [
                      const Icon(Icons.document_scanner_outlined, size: 32, color: AppTheme.textMuted),
                      const SizedBox(height: 12),
                      Text('No recent scans found.', style: AppTheme.bodyM.copyWith(color: AppTheme.textSecondary)),
                    ],
                  ),
                );
              }

              return Column(
                children: scans.take(3).map((scan) => _buildScanTile(scan)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildScanTile(ScanReportModel scan) {
    final bool isHighRisk = scan.predictionResult.toLowerCase().contains('high');
    final String badgeText = isHighRisk ? 'High Risk' : 'Low Risk';
    final Color barColor = isHighRisk ? AppTheme.danger : AppTheme.success;
    final Color iconBg = isHighRisk ? AppTheme.dangerBg : AppTheme.successBg;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      decoration: AppTheme.cardDecorationL1,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left color indicator bar
            Container(width: 4, decoration: BoxDecoration(color: barColor, borderRadius: BorderRadius.circular(2))),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                      child: Icon(Icons.description_rounded, color: barColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${scan.panelLabel} Report', style: AppTheme.bodyL.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(DateFormat('MMM d, yyyy').format(scan.timestamp.toDate()), style: AppTheme.caption),
                        ],
                      ),
                    ),
                    AppTheme.statusBadge(badgeText),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom interactive card for scaling effect
class ActionCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color bgColor;
  final VoidCallback onTap;

  const ActionCard({super.key, required this.icon, required this.label, required this.iconColor, required this.bgColor, required this.onTap});

  @override
  State<ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<ActionCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 120), lowerBound: 0.95, upperBound: 1.0, value: 1.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.reverse(),
      onTapUp: (_) {
        _controller.forward();
        widget.onTap();
      },
      onTapCancel: () => _controller.forward(),
      child: ScaleTransition(
        scale: _controller,
        child: Container(
          height: 110,
          decoration: AppTheme.cardDecorationL1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(color: widget.bgColor, shape: BoxShape.circle),
                child: Icon(widget.icon, color: widget.iconColor, size: 24),
              ),
              const SizedBox(height: 10),
              Text(
                widget.label,
                textAlign: TextAlign.center,
                style: AppTheme.bodyM.copyWith(fontWeight: FontWeight.w600, fontSize: 13, height: 1.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
