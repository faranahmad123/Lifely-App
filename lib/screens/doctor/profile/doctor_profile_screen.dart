import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../services/firebase_service.dart';
import '../../../models/user_model.dart';
import 'edit_doctor_profile_screen.dart';

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  UserModel? _doctorProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = await _firebaseService.getUserProfile(_uid);
      if (mounted) {
        setState(() {
          _doctorProfile = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(color: Color(0xFFFEF2F2), shape: BoxShape.circle),
              child: const Icon(Icons.logout_rounded, color: AppTheme.danger, size: 28),
            ),
            const SizedBox(height: 16),
            Text("Logout?", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            Text(
              "Are you sure you want to logout from your\nLifely Doctor account?",
              style: GoogleFonts.inter(fontWeight: FontWeight.w400, fontSize: 14, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(14)),
                      child: Center(
                        child: Text("Cancel", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15, color: AppTheme.textSecondary)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      Navigator.pop(ctx);
                      await _firebaseService.logout();
                      if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                    },
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.danger,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: AppTheme.danger.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 4))],
                      ),
                      child: Center(
                        child: Text("Logout", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                      ),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
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

    final name = _doctorProfile?.name ?? 'Dr. Name';
    final specialty = _doctorProfile?.specialty.isNotEmpty == true ? _doctorProfile!.specialty : 'General Physician';
    final initials = _doctorProfile?.initials ?? '?';
    final experience = _doctorProfile?.experience ?? 0;
    final pmdc = _doctorProfile?.pmdcNumber.isNotEmpty == true ? _doctorProfile!.pmdcNumber : 'Not Provided';
    final about = _doctorProfile?.aboutMe.isNotEmpty == true ? _doctorProfile!.aboutMe : 'No bio provided yet.';
    final hospital = _doctorProfile?.hospital.isNotEmpty == true ? _doctorProfile!.hospital : 'No hospital provided.';
    final address = _doctorProfile?.hospitalAddress.isNotEmpty == true ? _doctorProfile!.hospitalAddress : '';

    return Scaffold(
      backgroundColor: AppTheme.background,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            children: [
              _buildHeroHeader(name, specialty, initials),
              const SizedBox(height: 24),
              _buildProfessionalInfo(experience, pmdc),
              const SizedBox(height: 24),
              _buildAbout(about),
              const SizedBox(height: 24),
              _buildLocation(hospital, address),
              const SizedBox(height: 24),
              _buildQuickActions(),
              _buildLogoutButton(),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  "Lifely Doctor v1.0.0 · 👨‍⚕️ Medical Professional",
                  style: GoogleFonts.inter(fontWeight: FontWeight.w400, fontSize: 11, color: const Color(0xFFCBD5E1)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader(String name, String specialty, String initials) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 16, bottom: 40, left: 24, right: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D2E8A), Color(0xFF1A56DB), Color(0xFF2563EB), Color(0xFF3B82F6)],
        ),
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
        boxShadow: [BoxShadow(color: const Color(0xFF1A56DB).withValues(alpha: 0.40), blurRadius: 48, offset: const Offset(0, 16))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Doctor Profile", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white)),
                  Text("Professional Dashboard", style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 12, color: Colors.white.withValues(alpha: 0.65))),
                ],
              ),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.25))),
                    child: const Icon(Icons.settings_outlined, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _showLogoutDialog,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha: 0.20), shape: BoxShape.circle, border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.40))),
                      child: const Icon(Icons.logout_rounded, color: Color(0xFFFCA5A5), size: 20),
                    ),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 24),
          Hero(
            tag: 'doctor-avatar',
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 116,
                  height: 116,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(colors: [Color(0xFF60A5FA), Color(0xFF2DD4BF), Color(0xFF8B5CF6), Color(0xFF60A5FA)]),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Container(
                    decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.20), blurRadius: 32, offset: const Offset(0, 8))]),
                    child: Center(child: Text(initials, style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 36, color: AppTheme.primaryMid))),
                  ),
                ),
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppTheme.accentTeal, Color(0xFF14B8A6)]), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)),
                    child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 15),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white)),
          Text(specialty, style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14, color: Colors.white.withValues(alpha: 0.75))),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(color: AppTheme.success.withValues(alpha: 0.20), borderRadius: BorderRadius.circular(50), border: Border.all(color: AppTheme.success.withValues(alpha: 0.50))),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_rounded, color: Color(0xFF6EE7B7), size: 14),
                const SizedBox(width: 6),
                Text("VERIFIED PROFESSIONAL", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11, color: const Color(0xFF6EE7B7), letterSpacing: 0.8)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), border: Border.all(color: Colors.white.withValues(alpha: 0.20)), borderRadius: BorderRadius.circular(16)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildTopStat("0", "Patients"),
                    Container(width: 1, height: 30, color: Colors.white.withValues(alpha: 0.25)),
                    _buildTopStat("0", "Appointments"),
                    Container(width: 1, height: 30, color: Colors.white.withValues(alpha: 0.25)),
                    _buildTopStat("5★", "Rating"),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
        Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 11, color: Colors.white.withValues(alpha: 0.8))),
      ],
    );
  }

  Widget _buildSectionHeader(String title, Color barColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          Container(width: 4, height: 20, decoration: BoxDecoration(color: barColor, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary, letterSpacing: 0.8)),
        ],
      ),
    );
  }

  Widget _buildProfessionalInfo(int experience, String pmdc) {
    return Column(
      children: [
        _buildSectionHeader("PROFESSIONAL INFO", AppTheme.primaryMid),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 4))], border: const Border(top: BorderSide(color: Color(0xFFF59E0B), width: 3))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 36, height: 36, decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.work_outline_rounded, color: Color(0xFFF59E0B), size: 20)),
                      const SizedBox(height: 10),
                      Text("Experience", style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 11, color: AppTheme.textMuted)),
                      Text("$experience Years", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textPrimary)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 4))], border: const Border(top: BorderSide(color: AppTheme.primaryMid, width: 3))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 36, height: 36, decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.badge_rounded, color: AppTheme.primaryMid, size: 20)),
                      const SizedBox(height: 10),
                      Text("PMDC No.", style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 11, color: AppTheme.textMuted)),
                      Text(pmdc, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAbout(String about) {
    return Column(
      children: [
        _buildSectionHeader("ABOUT", AppTheme.accentTeal),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 4))]),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(about, style: GoogleFonts.inter(fontWeight: FontWeight.w400, fontSize: 14, color: AppTheme.textSecondary, height: 1.6)),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => const EditDoctorProfileScreen()));
                  _loadProfile();
                },
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFBFDBFE))),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.edit_rounded, color: AppTheme.primaryMid, size: 16),
                      const SizedBox(width: 6),
                      Text("Edit Bio", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.primaryMid)),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocation(String hospital, String address) {
    return Column(
      children: [
        _buildSectionHeader("PRACTICE LOCATION", AppTheme.success),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 4))]),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppTheme.success, Color(0xFF059669)]), borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: AppTheme.success.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))]),
                child: const Icon(Icons.local_hospital_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(hospital, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary)),
                    const SizedBox(height: 4),
                    if (address.isNotEmpty) Text(address, style: GoogleFonts.inter(fontWeight: FontWeight.w400, fontSize: 13, color: AppTheme.textSecondary)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(50), border: Border.all(color: const Color(0xFFA7F3D0))),
                      child: Text("ACTIVE PRACTICE", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11, color: const Color(0xFF059669), letterSpacing: 0.5)),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      children: [
        _buildSectionHeader("QUICK ACTIONS", const Color(0xFF8B5CF6)),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, 4))]),
          child: Column(
            children: [
              _buildActionTile(icon: Icons.edit_rounded, bg: const Color(0xFFEFF6FF), color: AppTheme.primaryMid, title: "Edit Profile", subtitle: "Update professional info", onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const EditDoctorProfileScreen())); _loadProfile(); }),
              _buildDivider(),
              _buildActionTile(icon: Icons.schedule_rounded, bg: const Color(0xFFFFFBEB), color: const Color(0xFFF59E0B), title: "Manage Schedule", subtitle: "Set availability & timings"),
              _buildDivider(),
              _buildActionTile(icon: Icons.people_rounded, bg: const Color(0xFFECFDF5), color: AppTheme.success, title: "My Patients", subtitle: "View patient records"),
              _buildDivider(),
              _buildActionTile(icon: Icons.notifications_rounded, bg: const Color(0xFFFAF5FF), color: const Color(0xFF8B5CF6), title: "Notifications", subtitle: "Manage alerts"),
              _buildDivider(),
              _buildActionTile(icon: Icons.help_outline_rounded, bg: const Color(0xFFF0FDF4), color: const Color(0xFF059669), title: "Help & Support", subtitle: "FAQs and contact"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile({required IconData icon, required Color bg, required Color color, required String title, required String subtitle, VoidCallback? onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 20)),
      title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary)),
      subtitle: Text(subtitle, style: GoogleFonts.inter(fontWeight: FontWeight.w400, fontSize: 13, color: AppTheme.textSecondary)),
      trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1), size: 24),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.only(left: 76),
      child: Divider(height: 1, color: Color(0xFFF1F5F9)),
    );
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: _showLogoutDialog,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 24, 16, 12),
        height: 56,
        decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(50), border: Border.all(color: const Color(0xFFFECACA), width: 1.5), boxShadow: [BoxShadow(color: AppTheme.danger.withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, 4))]),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded, color: AppTheme.danger, size: 22),
            const SizedBox(width: 10),
            Text("Logout", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.danger)),
          ],
        ),
      ),
    );
  }
}
