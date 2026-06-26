import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';
import '../../services/firebase_service.dart';
import '../../models/user_model.dart';

class BookAppointmentScreen extends StatefulWidget {
  final String? initialSpecialty;
  final String? initialAiDiagnosis;

  const BookAppointmentScreen({
    super.key,
    this.initialSpecialty,
    this.initialAiDiagnosis,
  });

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  UserModel? _patientProfile;
  bool _isLoadingDoctors = true;
  List<UserModel> _doctors = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      _patientProfile = await _firebaseService.getUserProfile(_uid);
      final allDocs = await _firebaseService.getAllDoctors();
      
      if (mounted) {
        setState(() {
          if (widget.initialSpecialty != null && widget.initialSpecialty!.isNotEmpty) {
            _doctors = allDocs.where((d) => d.specialty.toLowerCase() == widget.initialSpecialty!.toLowerCase()).toList();
          } else {
            _doctors = allDocs;
          }
          _isLoadingDoctors = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingDoctors = false);
    }
  }

  Future<void> _bookDoctor(UserModel doctor) async {
    if (_patientProfile == null) return;

    // Show a bottom sheet to select time slot (or simple dialog)
    if (doctor.availableSlots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Doctor has no available slots.'),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    final selectedSlot = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _buildSlotSelector(doctor.availableSlots),
    );

    if (selectedSlot == null) return;

    try {
      await _firebaseService.requestAppointment(
        patientId: _patientProfile!.userId,
        patientName: _patientProfile!.name,
        doctorId: doctor.userId,
        doctorName: doctor.name,
        aiDiagnosis: widget.initialAiDiagnosis ?? 'General Checkup',
        patientQuery: widget.initialAiDiagnosis != null ? 'AI Triage Follow-up' : 'General Checkup',
        requestedSlot: selectedSlot,
        patientIdRef: _patientProfile!.userId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Appointment request sent!', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to book: $e'), backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  Widget _buildSlotSelector(List<String> slots) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Time Slot',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: slots.map((slot) {
              return ActionChip(
                label: Text(slot, style: const TextStyle(fontWeight: FontWeight.w600)),
                backgroundColor: const Color(0xFFEFF6FF),
                side: BorderSide.none,
                onPressed: () => Navigator.pop(context, slot),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Book Doctor',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: _isLoadingDoctors
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryMid))
          : _doctors.isEmpty
              ? const Center(
                  child: Text('No doctors available.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                  physics: const BouncingScrollPhysics(),
                  itemCount: _doctors.length,
                  itemBuilder: (context, index) => _buildDoctorCard(_doctors[index]),
                ),
    );
  }

  Widget _buildDoctorCard(UserModel doctor) {
    final initials = doctor.initials;
    final experience = doctor.experience > 0 ? '${doctor.experience} yrs' : 'New';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: AppTheme.heroGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctor.name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  doctor.specialty.isNotEmpty ? doctor.specialty : 'General Physician',
                  style: TextStyle(fontSize: 13, color: Colors.blueGrey.shade400, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.work_outline_rounded, size: 14, color: Colors.blueGrey.shade400),
                    const SizedBox(width: 4),
                    Text(
                      experience,
                      style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade400),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.local_hospital_rounded, size: 14, color: Colors.blueGrey.shade400),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        doctor.hospital,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade400),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: ElevatedButton(
                    onPressed: () => _bookDoctor(doctor),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEFF6FF),
                      foregroundColor: AppTheme.primaryMid,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Book Appointment', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

