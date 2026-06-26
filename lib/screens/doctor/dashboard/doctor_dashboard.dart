import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/firebase_service.dart';
import '../../../models/appointment_model.dart';
import '../../../core/theme/app_theme.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  String _doctorName = 'Doctor';
  String _initials = 'DR';

  late AnimationController _animController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideIn;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideIn = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = await _firebaseService.getUserProfile(_uid);
    if (user != null && mounted) {
      final parts = user.name.split(' ');
      setState(() {
        _doctorName = user.name;
        _initials = parts.length > 1
            ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
            : (user.name.isNotEmpty ? user.name[0].toUpperCase() : 'D');
      });
    }
  }

  String formatDoctorName(String rawName) {
    if (rawName.isEmpty) return 'Doctor';
    String trimmed = rawName.trim();
    if (trimmed.toLowerCase().startsWith('dr.') || trimmed.toLowerCase().startsWith('dr ')) {
      return trimmed;
    }
    return 'Dr. $trimmed';
  }

  Future<void> _handleAccept(AppointmentModel appt) async {
    try {
      await _firebaseService.acceptAppointment(
        appointmentId: appt.id,
        meetingTime: appt.requestedSlot.isNotEmpty ? appt.requestedSlot : 'Time TBD',
        meetingDate: DateFormat('MMM d, yyyy').format(appt.date.toDate()),
        doctorId: _uid,
        patientIdRef: appt.patientId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text("Appointment Accepted!", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to accept: $e"), backgroundColor: AppTheme.danger));
    }
  }

  Future<void> _handleReject(AppointmentModel appt) async {
    // simplified reject for styling demonstration
    try {
      await _firebaseService.updateAppointmentStatus(appt.id, 'Rejected', rejectionReason: 'Schedule Conflict');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.info_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text("Request declined.", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
          backgroundColor: AppTheme.danger,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: AppTheme.danger));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeIn,
          child: SlideTransition(
            position: _slideIn,
            child: StreamBuilder<List<AppointmentModel>>(
              stream: _firebaseService.streamDoctorAppointments(_uid),
              builder: (context, snapshot) {
                final appointments = snapshot.data ?? [];
                final total = appointments.length;
                final pending = appointments.where((a) => a.status.toLowerCase() == 'pending').toList();
                final accepted = appointments.where((a) => a.status.toLowerCase() == 'accepted').toList();
                final rejected = appointments.where((a) => a.status.toLowerCase() == 'rejected').toList();

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTopBar(),
                      _buildStatsRow(total, pending.length, accepted.length, rejected.length),
                      _buildManageBookingSlots(),
                      _buildPendingHeader(pending.length),
                      if (pending.isEmpty) _buildEmptyState() else ...pending.map((appt) => _buildRequestCard(appt)),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Good Morning ☀️",
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 4),
                Text(
                  "${formatDoctorName(_doctorName)} 👨‍⚕️",
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 24, color: AppTheme.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 4)),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(Icons.notifications_outlined, color: AppTheme.textSecondary, size: 22),
                    Positioned(
                      top: 10,
                      right: 12,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: AppTheme.danger, borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/doctor_profile'),
                child: Hero(
                  tag: 'doctor-avatar',
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(colors: [AppTheme.primaryMid, AppTheme.accentTeal]),
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: [
                        BoxShadow(color: AppTheme.primaryMid.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _initials,
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                      ),
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

  Widget _buildStatsRow(int total, int pending, int accepted, int rejected) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Row(
        children: [
          _buildStatCard('Total', total.toString(), AppTheme.primaryMid, const Color(0xFFEFF6FF), Icons.calendar_month_rounded),
          const SizedBox(width: 10),
          _buildStatCard('Pending', pending.toString(), const Color(0xFFF59E0B), const Color(0xFFFFFBEB), Icons.hourglass_top_rounded),
          const SizedBox(width: 10),
          _buildStatCard('Accepted', accepted.toString(), AppTheme.success, const Color(0xFFECFDF5), Icons.check_circle_rounded),
          const SizedBox(width: 10),
          _buildStatCard('Rejected', rejected.toString(), AppTheme.danger, const Color(0xFFFEF2F2), Icons.cancel_rounded),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String count, Color accentColor, Color softBg, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 4)),
          ],
          border: Border(top: BorderSide(width: 3, color: accentColor)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: softBg, shape: BoxShape.circle),
              child: Icon(icon, color: accentColor, size: 16),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  count,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 22, color: AppTheme.textPrimary),
                ),
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 10, color: AppTheme.textMuted, letterSpacing: 0.3),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManageBookingSlots() {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/doctor_schedule'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.edit_calendar_rounded, color: AppTheme.primaryMid, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Manage Booking Slots",
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Set availability & timings",
                    style: GoogleFonts.inter(fontWeight: FontWeight.w400, fontSize: 13, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryMid,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryMid.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                "Set",
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingHeader(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 4, height: 20, decoration: BoxDecoration(color: const Color(0xFFF59E0B), borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              Text("PENDING REQUESTS", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary, letterSpacing: 0.8)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFFFFBEB), border: Border.all(color: const Color(0xFFFDE68A)), borderRadius: BorderRadius.circular(50)),
                child: Text(count.toString(), style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: const Color(0xFFF59E0B))),
              ),
            ],
          ),
          Text("See All", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.primaryMid)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)]),
            ),
            child: const Icon(Icons.inbox_outlined, color: AppTheme.primaryMid, size: 36),
          ),
          const SizedBox(height: 20),
          Text("All caught up! 🎉", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          Text(
            "No pending appointment requests.\nNew requests will appear here automatically.",
            style: GoogleFonts.inter(fontWeight: FontWeight.w400, fontSize: 14, color: AppTheme.textSecondary, height: 1.6),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(AppointmentModel appt) {
    final date = DateFormat('MMM d, yyyy').format(appt.date.toDate());
    final time = appt.requestedSlot.isNotEmpty ? appt.requestedSlot : 'Time TBD';
    final initials = appt.patientName.isNotEmpty ? appt.patientName[0].toUpperCase() : '?';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 4))],
        border: const Border(left: BorderSide(width: 4, color: Color(0xFFF59E0B))),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)])),
                child: Center(child: Text(initials, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(appt.patientName, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary)),
                    Text("General Consultation", style: GoogleFonts.inter(fontWeight: FontWeight.w400, fontSize: 13, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFFFFBEB), border: Border.all(color: const Color(0xFFFDE68A)), borderRadius: BorderRadius.circular(50)),
                child: Text("PENDING", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11, color: const Color(0xFFF59E0B), letterSpacing: 0.5)),
              )
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Icon(Icons.calendar_month_rounded, color: AppTheme.primaryMid, size: 16),
                const SizedBox(width: 6),
                Text(date, style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13, color: AppTheme.textSecondary)),
                const SizedBox(width: 16),
                Icon(Icons.schedule_rounded, color: AppTheme.accentTeal, size: 16),
                const SizedBox(width: 6),
                Text(time, style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _handleReject(appt),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(color: const Color(0xFFFEF2F2), border: Border.all(color: const Color(0xFFFECACA)), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.close_rounded, color: AppTheme.danger, size: 18),
                        const SizedBox(width: 6),
                        Text("Reject", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.danger)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => _handleAccept(appt),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: const Color(0xFF10B981).withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 4))],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                        const SizedBox(width: 6),
                        Text("Accept", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
