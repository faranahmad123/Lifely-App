import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../services/firebase_service.dart';
import '../../models/user_model.dart';
import 'edit_patient_profile_screen.dart';
import '../reports/report_history_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();

  UserModel? _user;
  bool _isLoading = true;
  String? _errorMessage;
  int _reportsCount = 0;
  int _appointmentsCount = 0;

  late AnimationController _particlesController;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _particlesController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _particlesController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null || currentUser.uid.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No user is currently logged in.';
        });
      }
      return;
    }

    try {
      final user = await _firebaseService.getUserProfile(currentUser.uid);
      
      // Load quick stats concurrently
      final reports = await _firebaseService.streamPatientReports(currentUser.uid).first;
      final appts = await _firebaseService.streamPatientAppointments(currentUser.uid).first;
      
      if (mounted) {
        setState(() {
          _user = user;
          _reportsCount = reports.length;
          _appointmentsCount = appts.where((a) => a.status.toLowerCase() != 'cancelled').length;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load profile. Please try again.';
        });
      }
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          title: Text(
            "Logout?",
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18, color: AppTheme.textPrimary),
          ),
          content: Text(
            "Are you sure you want to logout from Lifely?",
            style: GoogleFonts.inter(fontWeight: FontWeight.w400, fontSize: 14, color: const Color(0xFF64748B)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                "Cancel",
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await FirebaseAuth.instance.signOut();
                if (mounted) Navigator.pushReplacementNamed(context, '/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                "Logout",
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryMid, strokeWidth: 2.5)),
      );
    }

    if (_errorMessage != null || _user == null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, size: 56, color: AppTheme.danger),
                const SizedBox(height: 16),
                Text(_errorMessage ?? 'No profile found.', textAlign: TextAlign.center, style: AppTheme.bodyM),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() { _isLoading = true; _errorMessage = null; });
                    _loadProfile();
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final user = _user!;
    final name = user.name.isNotEmpty ? user.name : 'Patient';
    final email = user.email.isNotEmpty ? user.email : (FirebaseAuth.instance.currentUser?.email ?? 'No email provided');
    final initials = user.name.isNotEmpty ? user.initials : '?';

    final bloodGroup = user.bloodGroup.isNotEmpty ? user.bloodGroup : '-';
    final weight = user.weight != 0 ? '${user.weight.toStringAsFixed(1)} kg' : '-';
    final height = user.height != 0 ? '${user.height.toStringAsFixed(1)} cm' : '-';
    final age = user.age != 0 ? '${user.age} yrs' : '-';

    return Scaffold(
      backgroundColor: const Color(0xFFEEF2FF),
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        top: false, // Extend to top edge
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 100), // Space for bottom nav
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 🎯 SECTION 1 — Hero Profile Header
              _buildHeroHeader(name, email, initials, bloodGroup),

              // 🎯 SECTION 2 — Health Overview Grid
              _buildSectionHeader("Health Overview", const Color(0xFF1A56DB), actionText: "Edit →", onActionTap: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const EditPatientProfileScreen()));
                _loadProfile();
              }),
              _buildHealthGrid(bloodGroup, weight, height, age),

              // 🎯 SECTION 3 — Quick Actions List
              _buildSectionHeader("Quick Actions", const Color(0xFF0D9488)),
              _buildQuickActionsList(),

              // 🎯 SECTION 4 — Logout CTA
              _buildLogoutButton(),

              // 🎯 SECTION 5 — App Version Footer
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
                child: Center(
                  child: Text(
                    "Lifely v1.0.0 · Built with ❤️",
                    style: GoogleFonts.inter(fontWeight: FontWeight.w400, fontSize: 11, color: const Color(0xFFCBD5E1)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader(String name, String email, String initials, String bloodGroup) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 24, 24, 40),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D2E8A), Color(0xFF1A56DB), Color(0xFF2563EB), Color(0xFF3B82F6)],
          stops: [0.0, 0.35, 0.70, 1.0],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A56DB).withValues(alpha: 0.40),
            blurRadius: 48,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Decorative Elements
          Positioned(
            top: -50, right: -80,
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.05)),
            ),
          ),
          Positioned(
            bottom: -20, left: -40,
            child: Container(
              width: 120, height: 120,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.06)),
            ),
          ),
          ...List.generate(5, (index) {
            final random = math.Random(index);
            final left = random.nextDouble() * 300;
            final top = random.nextDouble() * 200;
            return AnimatedBuilder(
              animation: _particlesController,
              builder: (context, child) {
                final offset = math.sin((_particlesController.value * math.pi) + index) * 8;
                return Positioned(
                  left: left, top: top + offset,
                  child: Container(
                    width: 6.0 + random.nextDouble() * 4,
                    height: 6.0 + random.nextDouble() * 4,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.15)),
                  ),
                );
              },
            );
          }),

          // Content
          Column(
            children: [
              // Top App Bar Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("My Profile", style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 22, color: Colors.white)),
                      Text("Personal Health Record", style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 12, color: Colors.white.withValues(alpha: 0.65))),
                    ],
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          await Navigator.push(context, MaterialPageRoute(builder: (_) => const EditPatientProfileScreen()));
                          _loadProfile();
                        },
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                          ),
                          child: const Icon(Icons.settings_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _showLogoutDialog,
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.20),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.40)),
                          ),
                          child: const Icon(Icons.logout_rounded, color: Color(0xFFFCA5A5), size: 20),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 32),

              // Avatar Block
              Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Outer glow ring
                    Container(
                      width: 116, height: 116,
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          colors: [Color(0xFF60A5FA), Color(0xFF2DD4BF), Color(0xFF8B5CF6), Color(0xFF60A5FA)],
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.20), blurRadius: 32, offset: const Offset(0, 8))],
                        ),
                        child: Center(
                          child: Text(
                            initials,
                            style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 38, color: const Color(0xFF1A56DB)),
                          ),
                        ),
                      ),
                    ),
                    // Camera Badge
                    Positioned(
                      bottom: 2, right: 2,
                      child: GestureDetector(
                        onTap: () async {
                          await Navigator.push(context, MaterialPageRoute(builder: (_) => const EditPatientProfileScreen()));
                          _loadProfile();
                        },
                        child: Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(colors: [Color(0xFF0D9488), Color(0xFF14B8A6)]),
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [BoxShadow(color: const Color(0xFF0D9488).withValues(alpha: 0.50), blurRadius: 12, offset: const Offset(0, 4))],
                          ),
                          child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Name & Email
              Text(
                name,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700, fontSize: 24, color: Colors.white,
                  shadows: [Shadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 2))],
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mail_rounded, color: Colors.white.withValues(alpha: 0.65), size: 13),
                  const SizedBox(width: 6),
                  Text(
                    email,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13, color: Colors.white.withValues(alpha: 0.70)),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Stats Strip (Frosted Glass)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(_reportsCount.toString(), "Reports"),
                        Container(width: 1, height: 30, color: Colors.white.withValues(alpha: 0.25)),
                        _StatItem(_appointmentsCount.toString(), "Appointments"),
                        Container(width: 1, height: 30, color: Colors.white.withValues(alpha: 0.25)),
                        _StatItem(bloodGroup, "Blood Type"),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color barColor, {String? actionText, VoidCallback? onActionTap}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 4, height: 20, decoration: BoxDecoration(color: barColor, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18, color: const Color(0xFF0F172A))),
            ],
          ),
          if (actionText != null && onActionTap != null)
            TextButton(
              onPressed: onActionTap,
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              child: Text(actionText, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: const Color(0xFF1A56DB))),
            ),
        ],
      ),
    );
  }

  Widget _buildHealthGrid(String bg, String wt, String ht, String age) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildMetricCard("Blood Group", bg, Icons.water_drop_rounded, const Color(0xFFEF4444), const Color(0xFFFEF2F2))),
              const SizedBox(width: 12),
              Expanded(child: _buildMetricCard("Weight", wt, Icons.monitor_weight_rounded, const Color(0xFF1A56DB), const Color(0xFFEFF6FF))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildMetricCard("Height", ht, Icons.height_rounded, const Color(0xFFF59E0B), const Color(0xFFFFFBEB))),
              const SizedBox(width: 12),
              Expanded(child: _buildMetricCard("Age", age, Icons.cake_rounded, const Color(0xFF8B5CF6), const Color(0xFFFAF5FF))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color accentColor, Color softBg) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(height: 3, color: accentColor),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(color: softBg, shape: BoxShape.circle),
                    child: Icon(icon, color: accentColor, size: 24),
                  ),
                  const SizedBox(height: 24),
                  Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 26, color: const Color(0xFF0F172A))),
                  const SizedBox(height: 2),
                  Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 12, color: const Color(0xFF64748B), letterSpacing: 0.3)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.shadowLevel2,
      ),
      child: Column(
        children: [
          _ActionTile(
            icon: Icons.edit_rounded, iconBg: const Color(0xFFEFF6FF), iconColor: const Color(0xFF1A56DB),
            title: "Edit Profile", subtitle: "Update your personal info",
            onTap: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const EditPatientProfileScreen()));
              _loadProfile();
            },
          ),
          const Divider(height: 0.5, color: Color(0xFFF1F5F9), indent: 68),
          _ActionTile(
            icon: Icons.content_paste_rounded, iconBg: const Color(0xFFECFDF5), iconColor: const Color(0xFF10B981),
            title: "Medical History", subtitle: "View past diagnoses",
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportHistoryScreen()));
            },
          ),
          const Divider(height: 0.5, color: Color(0xFFF1F5F9), indent: 68),
          _ActionTile(
            icon: Icons.notifications_rounded, iconBg: const Color(0xFFFFFBEB), iconColor: const Color(0xFFF59E0B),
            title: "Notifications", subtitle: "Manage alerts",
            onTap: () => _showComingSoon('Notifications'),
          ),
          const Divider(height: 0.5, color: Color(0xFFF1F5F9), indent: 68),
          _ActionTile(
            icon: Icons.security_rounded, iconBg: const Color(0xFFFAF5FF), iconColor: const Color(0xFF8B5CF6),
            title: "Privacy & Security", subtitle: "Password, 2FA",
            onTap: () => _showComingSoon('Privacy & Security'),
          ),
          const Divider(height: 0.5, color: Color(0xFFF1F5F9), indent: 68),
          _ActionTile(
            icon: Icons.help_outline_rounded, iconBg: const Color(0xFFF0FDF4), iconColor: const Color(0xFF059669),
            title: "Help & Support", subtitle: "FAQs and contact us",
            onTap: () => _showComingSoon('Help & Support'),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$feature coming soon!')));
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: _showLogoutDialog,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 24, 16, 12),
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: const Color(0xFFFECACA), width: 1.5),
          boxShadow: [BoxShadow(color: const Color(0xFFEF4444).withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 22),
            const SizedBox(width: 10),
            Text("Logout", style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: const Color(0xFFEF4444))),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20, color: Colors.white)),
        Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 11, color: Colors.white.withValues(alpha: 0.65))),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon, required this.iconBg, required this.iconColor,
    required this.title, required this.subtitle, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), // 14px roughly achieved via internal sizing
      leading: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15, color: const Color(0xFF0F172A))),
      subtitle: Text(subtitle, style: GoogleFonts.inter(fontWeight: FontWeight.w400, fontSize: 12, color: const Color(0xFF94A3B8))),
      trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1), size: 18),
    );
  }
}
