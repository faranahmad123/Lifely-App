import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/firebase_service.dart';
import '../../../models/appointment_model.dart';

class PatientListScreen extends StatefulWidget {
  const PatientListScreen({super.key});

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'My Patients',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18, color: AppTheme.textPrimary),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── SEARCH BAR ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusScreen),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: AppTheme.shadowLevel1,
              ),
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  icon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary),
                  hintText: 'Search patients...',
                  hintStyle: GoogleFonts.inter(
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<List<AppointmentModel>>(
              stream: _firebaseService.streamDoctorAppointments(_uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryMid,
                      strokeWidth: 2.5,
                    ),
                  );
                }

                final appointments = snapshot.data ?? [];

                // Extract unique patients from accepted appointments
                final acceptedAppts = appointments.where((a) => a.status.toLowerCase() == 'accepted').toList();

                // Map to ensure uniqueness by patientId
                final uniquePatients = <String, AppointmentModel>{};
                for (var appt in acceptedAppts) {
                  if (!uniquePatients.containsKey(appt.patientId)) {
                    uniquePatients[appt.patientId] = appt;
                  }
                }

                var filteredPatients = uniquePatients.values.toList();
                if (_searchQuery.isNotEmpty) {
                  filteredPatients = filteredPatients.where((p) => p.patientName.toLowerCase().contains(_searchQuery)).toList();
                }

                if (filteredPatients.isEmpty) {
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
                            Icons.people_outline_rounded,
                            size: 44,
                            color: AppTheme.primaryMid,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'No Patients Found',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isNotEmpty ? 'Try adjusting your search.' : 'You have no accepted patients yet.',
                          style: GoogleFonts.inter(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: filteredPatients.length,
                  itemBuilder: (context, index) {
                    final appt = filteredPatients[index];
                    final initials = appt.patientName.isNotEmpty ? appt.patientName[0].toUpperCase() : '?';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: AppTheme.cardDecorationL1,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        leading: CircleAvatar(
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
                        title: Text(
                          appt.patientName.isNotEmpty ? appt.patientName : 'Patient',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: AppTheme.statusBadge('Accepted'),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: AppTheme.textMuted,
                        ),
                        onTap: () {
                          // View patient details if needed
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
