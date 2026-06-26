import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/firebase_service.dart';
import '../../../models/appointment_model.dart';

class AppointmentRequestsScreen extends StatelessWidget {
  final Function(int)? onSwitchTab;
  const AppointmentRequestsScreen({super.key, this.onSwitchTab});

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    final firebaseService = FirebaseService();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: Text(
            "Appointments",
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18, color: AppTheme.textPrimary),
          ),
          backgroundColor: AppTheme.pureWhite,
          elevation: 0,
          centerTitle: true,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(64),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TabBar(
                  padding: const EdgeInsets.all(3),
                  labelColor: Colors.white,
                  unselectedLabelColor: AppTheme.textSecondary,
                  labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                  unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(11),
                    color: AppTheme.primaryMid,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryMid.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  tabs: const [
                    Tab(text: "Requests"),
                    Tab(text: "Upcoming"),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: StreamBuilder<List<AppointmentModel>>(
          stream: firebaseService.streamDoctorAppointments(_uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryMid, strokeWidth: 2.5),
              );
            }

            final all = snapshot.data ?? [];
            final requests = all.where((a) => a.status.toLowerCase() == 'pending').toList();
            final upcoming = all.where((a) => a.status.toLowerCase() == 'accepted').toList();

            return TabBarView(
              children: [
                _buildList(context, requests, isEmpty: requests.isEmpty, emptyLabel: 'No new requests'),
                _buildList(context, upcoming, isEmpty: upcoming.isEmpty, emptyLabel: 'No upcoming appointments'),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<AppointmentModel> appts, {required bool isEmpty, required String emptyLabel}) {
    if (isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFE3F2FD),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inbox_rounded,
                size: 44,
                color: AppTheme.primaryMid,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              emptyLabel,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'New appointment requests will appear here.',
              style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      itemCount: appts.length,
      itemBuilder: (context, index) => _buildRequestCard(context, appts[index]),
    );
  }

  Widget _buildRequestCard(BuildContext context, AppointmentModel appt) {
    final firebaseService = FirebaseService();
    final formattedDate = DateFormat('MMM d, yyyy').format(appt.date.toDate());
    final initials = appt.patientName.isNotEmpty ? appt.patientName[0].toUpperCase() : '?';
    final isPending = appt.status.toLowerCase() == 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.cardDecorationL1,
      child: Column(
        children: [
          Row(
            children: [
              // ── AVATAR ──
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFE3F2FD),
                child: Text(
                  initials,
                  style: GoogleFonts.inter(
                    color: AppTheme.primaryMid,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appt.patientName.isNotEmpty ? appt.patientName : 'Patient',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      appt.patientQuery.isNotEmpty ? appt.patientQuery : 'AI Triage Consultation',
                      style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formattedDate,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    appt.time,
                    style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          if (isPending) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleReject(context, firebaseService, appt),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.danger,
                      side: const BorderSide(color: AppTheme.danger),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      "Decline",
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleAccept(context, firebaseService, appt),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    child: Text(
                      "Accept",
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: AppTheme.statusBadge('Accepted'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleAccept(BuildContext context, FirebaseService fs, AppointmentModel appt) async {
    try {
      await fs.acceptAppointment(
        appointmentId: appt.id,
        meetingTime: appt.requestedSlot.isNotEmpty ? appt.requestedSlot : appt.time,
        meetingDate: DateFormat('MMM d, yyyy').format(appt.date.toDate()),
        doctorId: FirebaseAuth.instance.currentUser!.uid,
        patientIdRef: appt.patientId,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Appointment Accepted!",
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  Future<void> _handleReject(BuildContext context, FirebaseService fs, AppointmentModel appt) async {
    try {
      await fs.rejectAppointment(appt.id, 'Declined by doctor');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Request declined.",
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppTheme.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: AppTheme.danger),
        );
      }
    }
  }
}
