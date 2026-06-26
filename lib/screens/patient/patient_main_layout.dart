import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'patient_dashboard.dart';
import 'profile_screen.dart';
import '../reports/report_history_screen.dart';
import '../../core/theme/app_theme.dart';
import '../../services/firebase_service.dart';
import '../../services/receipt_service.dart';
import '../../models/appointment_model.dart';

class PatientMainLayout extends StatefulWidget {
  const PatientMainLayout({super.key});

  @override
  State<PatientMainLayout> createState() => _PatientMainLayoutState();
}

class _PatientMainLayoutState extends State<PatientMainLayout> {
  int _currentIndex = 0;
  final FirebaseService _firebaseService = FirebaseService();
  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  void _onSwitchTab(int index) {
    if (index >= 0 && index < 4) {
      setState(() => _currentIndex = index);
    } else {
      setState(() => _currentIndex = 0);
    }
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return PatientDashboard(onSwitchTab: _onSwitchTab);
      case 1:
        return const ReportHistoryScreen();
      case 2:
        return _buildAppointmentsTab();
      case 3:
        return const ProfileScreen();
      default:
        return PatientDashboard(onSwitchTab: _onSwitchTab);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: AppTheme.bodyM.copyWith(fontWeight: FontWeight.w600, color: Colors.white)),
        backgroundColor: color,
      ),
    );
  }

  Widget _buildAppointmentsTab() {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: Text("My Appointments", style: AppTheme.h2),
          backgroundColor: AppTheme.background,
          elevation: 0,
          centerTitle: true,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(70),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Container(
                height: 46,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusPill),
                ),
                child: TabBar(
                  splashBorderRadius: BorderRadius.circular(AppTheme.borderRadiusPill),
                  labelColor: AppTheme.textPrimary,
                  unselectedLabelColor: AppTheme.textMuted,
                  labelStyle: AppTheme.bodyM.copyWith(fontWeight: FontWeight.w700),
                  unselectedLabelStyle: AppTheme.bodyM.copyWith(fontWeight: FontWeight.w500),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusPill),
                    color: Colors.white,
                    boxShadow: AppTheme.shadowLevel1,
                  ),
                  tabs: const [
                    Tab(text: "Upcoming"),
                    Tab(text: "Past"),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: StreamBuilder<List<AppointmentModel>>(
          stream: _firebaseService.streamPatientAppointments(_uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryMid, strokeWidth: 2.5),
              );
            }

            final allAppts = snapshot.data ?? [];
            final upcoming = allAppts
                .where((a) => a.status.toLowerCase() == 'pending' || a.status.toLowerCase() == 'accepted')
                .toList();
            final past = allAppts
                .where((a) => a.status.toLowerCase() == 'rejected' || a.status.toLowerCase() == 'completed' || a.status.toLowerCase() == 'cancelled')
                .toList();

            return TabBarView(
              children: [
                _buildAppointmentList(upcoming, isUpcoming: true),
                _buildAppointmentList(past, isUpcoming: false),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppointmentList(List<AppointmentModel> appts, {required bool isUpcoming}) {
    if (appts.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(color: Color(0xFFEFF6FF), shape: BoxShape.circle),
                child: const Icon(Icons.event_busy_rounded, size: 56, color: AppTheme.primaryMid),
              ),
              const SizedBox(height: 18),
              Text(
                isUpcoming ? "No Upcoming Appointments" : "No Past Appointments",
                style: AppTheme.bodyL.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                isUpcoming
                    ? "You don't have any appointments scheduled. Run a health scan or book a doctor today!"
                    : "No completed or declined appointment history found.",
                textAlign: TextAlign.center,
                style: AppTheme.bodyM.copyWith(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: appts.length,
      itemBuilder: (context, index) {
        return _buildAppointmentCard(appts[index], isUpcoming);
      },
    );
  }

  Widget _buildAppointmentCard(AppointmentModel appt, bool isUpcoming) {
    final formattedDate = DateFormat('MMM d, yyyy').format(appt.date.toDate());
    final formattedTime = appt.time;
    final docInitials = appt.doctorName.isNotEmpty
        ? appt.doctorName.replaceAll("Dr. ", "").trim()[0].toUpperCase()
        : "?";

    String specialty = "General Physician";
    final diag = appt.aiDiagnosis.toLowerCase();
    if (diag.contains("metabolic") || diag.contains("diabetes")) {
      specialty = "Endocrinologist";
    } else if (diag.contains("renal")) {
      specialty = "Nephrologist";
    } else if (diag.contains("bone")) {
      specialty = "Orthopedist";
    } else if (diag.contains("cardio")) {
      specialty = "Cardiologist";
    }

    final isAccepted = appt.status.toLowerCase() == 'accepted';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecorationL2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 48, height: 48,
                decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppTheme.avatarGradient),
                child: Center(
                  child: Text(docInitials, style: AppTheme.h3.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 12),
              // Doctor info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(appt.doctorName, style: AppTheme.h3),
                    const SizedBox(height: 2),
                    Text(specialty, style: AppTheme.caption.copyWith(color: const Color(0xFF64748B))),
                  ],
                ),
              ),
              AppTheme.statusBadge(appt.status),
            ],
          ),
          const SizedBox(height: 16),

          // Date Badge Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusPill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_month_rounded, size: 16, color: AppTheme.primaryMid),
                const SizedBox(width: 8),
                Text(
                  "$formattedDate • $formattedTime",
                  style: AppTheme.bodyM.copyWith(fontWeight: FontWeight.w600, color: AppTheme.primaryMid),
                ),
              ],
            ),
          ),
          
          if (isUpcoming) ...[
            const SizedBox(height: 16),
            Container(height: 0.5, color: const Color(0xFFF1F5F9)),
            const SizedBox(height: 16),
            
            if (isAccepted) ...[
              // Download Receipt Button
              Container(
                width: double.infinity, height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
                ),
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showSnack('Generating Receipt...', AppTheme.success);
                    ReceiptService.generateAndDownloadReceipt(appt);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.receipt_long_rounded, size: 18, color: AppTheme.primaryMid),
                  label: Text('Download Receipt', style: AppTheme.bodyM.copyWith(fontWeight: FontWeight.w600, color: AppTheme.primaryMid)),
                ),
              ),
              const SizedBox(height: 12),
              // Cancel Button
              Center(
                child: GestureDetector(
                  onTap: () => _showSnack('Cancellation request sent to clinical team.', AppTheme.danger),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.close_rounded, size: 16, color: AppTheme.danger),
                        const SizedBox(width: 6),
                        Text('Cancel Appointment', style: AppTheme.bodyM.copyWith(fontWeight: FontWeight.w500, color: AppTheme.danger)),
                      ],
                    ),
                  ),
                ),
              ),
            ] else ...[
              // Pending Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showSnack('Reschedule requested! Our team will contact you.', AppTheme.primaryMid),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textSecondary,
                        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                      ),
                      child: const Text('Reschedule'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showSnack('Cancellation request sent.', AppTheme.danger),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.danger,
                        side: const BorderSide(color: AppTheme.dangerBg, width: 1.5),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      extendBody: true, // Allows body to scroll underneath if needed (dashboard handles padding)
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 10,
        selectedItemColor: const Color(0xFF0D47A1),
        unselectedItemColor: Colors.grey.shade400,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
        currentIndex: _currentIndex,
        onTap: _onSwitchTab,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long_rounded),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_month_rounded),
            label: 'Appointments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
