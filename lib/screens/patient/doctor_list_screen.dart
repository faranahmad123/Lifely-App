import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firebase_service.dart';
import '../../models/user_model.dart';


// ══════════════════════════════════════════════════════════════════
// 🩺 LIFELY V3 — SMART DOCTOR LIST & FIRESTORE BOOKING ENGINE
// ══════════════════════════════════════════════════════════════════
// Fetch real specialists from Cloud Firestore with automated
// specialty matching and an interactive appointment request engine.
// ══════════════════════════════════════════════════════════════════

class DoctorListScreen extends StatefulWidget {
  final String? filterSpecialty;
  final String? aiDiagnosis;

  const DoctorListScreen({
    super.key,
    this.filterSpecialty,
    this.aiDiagnosis,
  });

  @override
  State<DoctorListScreen> createState() => _DoctorListScreenState();
}

class _DoctorListScreenState extends State<DoctorListScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final String _patientId = FirebaseAuth.instance.currentUser?.uid ?? '';

  List<UserModel> _doctors = [];
  bool _isLoading = true;
  String? _patientName;

  // --- Fallback Realistic Seed Data if Firestore is empty ---
  final List<UserModel> _mockDoctors = [
    UserModel(
      userId: 'doc_sarah',
      name: 'Dr. Sarah Khan',
      email: 'sarah.khan@lifely.com',
      role: 'doctor',
      specialty: 'Hematologist',
      hospital: 'City Hospital, Lahore',
      experience: 8,
      rating: 4.9,
      reviews: 120,
      
      image: 'assets/images/doctor1.png',
      aboutMe: 'Senior Consultant Hematologist with 8+ years specializing in blood cancer and anemia.',
    ),
    UserModel(
      userId: 'doc_ali',
      name: 'Dr. Ali Raza',
      email: 'ali.raza@lifely.com',
      role: 'doctor',
      specialty: 'Hematologist',
      hospital: 'Jinnah Hospital, Lahore',
      experience: 12,
      rating: 4.7,
      reviews: 85,
      
      image: 'assets/images/doctor2.png',
      aboutMe: 'Expert in blood disorders and comprehensive transfusion therapies.',
    ),
    UserModel(
      userId: 'doc_ayesha',
      name: 'Dr. Ayesha Malik',
      email: 'ayesha.malik@lifely.com',
      role: 'doctor',
      specialty: 'Hepatologist',
      hospital: 'Children\'s Complex, Multan',
      experience: 15,
      rating: 4.8,
      reviews: 200,
      
      image: 'assets/images/doctor3.png',
      aboutMe: 'Specialized in Liver cirrhosis, Hepatitis diagnostics, and gastroenterology.',
    ),
    UserModel(
      userId: 'doc_bilal',
      name: 'Dr. Bilal Ahmed',
      email: 'bilal.ahmed@lifely.com',
      role: 'doctor',
      specialty: 'Endocrinologist',
      hospital: 'General Hospital, Sargodha',
      experience: 5,
      rating: 4.5,
      reviews: 45,
      
      image: 'assets/images/doctor4.png',
      aboutMe: 'Diabetes care expert focused on metabolic health, thyroid conditions, and weight management.',
    ),
    UserModel(
      userId: 'doc_faisal',
      name: 'Dr. Faisal Hayat',
      email: 'faisal.hayat@lifely.com',
      role: 'doctor',
      specialty: 'General Physician',
      hospital: 'Fatima Memorial Hospital, Lahore',
      experience: 10,
      rating: 4.6,
      reviews: 98,
      
      image: 'assets/images/doctor2.png',
      aboutMe: 'Experienced General Practitioner offering family medicine and diagnostic healthcare.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadPatientNameAndDoctors();
  }

  Future<void> _loadPatientNameAndDoctors() async {
    try {
      // 1. Fetch patient profile to get their real name
      if (_patientId.isNotEmpty) {
        final profile = await _firebaseService.getUserProfile(_patientId);
        _patientName = profile?.name;
      }

      // 2. Fetch doctors from Cloud Firestore
      List<UserModel> dbDoctors = await _firebaseService.getAllDoctors();

      // If database is empty, seed/fallback to mock data
      if (dbDoctors.isEmpty) {
        dbDoctors = List.from(_mockDoctors);
      }

      // 3. Filter by specialty if scanner matches one
      if (widget.filterSpecialty != null && widget.filterSpecialty!.isNotEmpty) {
        final filterLower = widget.filterSpecialty!.toLowerCase();
        dbDoctors = dbDoctors.where((doc) {
          final specLower = (doc.specialty ?? '').toLowerCase();
          return specLower.contains(filterLower) || filterLower.contains(specLower);
        }).toList();
      }

      setState(() {
        _doctors = dbDoctors;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading doctors screen: $e');
      setState(() {
        _doctors = List.from(_mockDoctors);
        _isLoading = false;
      });
    }
  }

  void _showBookingSheet(UserModel doctor) {
    final TextEditingController queryCtrl = TextEditingController(
      text: widget.aiDiagnosis != null
          ? 'Consultation for reported AI Diagnosis: ${widget.aiDiagnosis}'
          : '',
    );
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    String selectedTime = '10:30 AM';

    final List<String> timeSlots = [
      '09:00 AM',
      '10:30 AM',
      '12:00 PM',
      '02:30 PM',
      '04:00 PM',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Notch
                    Center(
                      child: Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Header Info
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppTheme.primaryMid.withValues(alpha: 0.1),
                          child: const Icon(Icons.person, color: AppTheme.primaryMid, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                doctor.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              Text(
                                doctor.specialty ?? 'General Physician',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryMid,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32),

                    // Date Picker
                    const Text(
                      'Select Appointment Date',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 30)),
                        );
                        if (picked != null) {
                          setModalState(() => selectedDate = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const Icon(Icons.calendar_today_rounded, color: AppTheme.primaryMid, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Time Slots
                    const Text(
                      'Select Time Slot',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: timeSlots.map((time) {
                        final isSel = selectedTime == time;
                        return InkWell(
                          onTap: () => setModalState(() => selectedTime = time),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSel ? AppTheme.primaryMid : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSel ? AppTheme.primaryMid : Colors.grey.shade200,
                              ),
                            ),
                            child: Text(
                              time,
                              style: TextStyle(
                                color: isSel ? Colors.white : AppTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Query Input
                    const Text(
                      'Reason for Visit / Query Message',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: queryCtrl,
                      maxLines: 3,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: 'Enter symptoms or details for your doctor...',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.all(16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    ElevatedButton(
                      onPressed: () async {
                        final reason = queryCtrl.text.trim();
                        if (reason.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a query message.')),
                          );
                          return;
                        }

                        // Dismiss Sheet
                        Navigator.pop(context);

                        // Trigger loading block in screen
                        setState(() => _isLoading = true);

                        try {
                          final slotString = '${selectedDate.day}/${selectedDate.month}/${selectedDate.year} at $selectedTime';
                          
                          await _firebaseService.requestAppointment(
                            patientId: _patientId,
                            patientName: _patientName ?? 'Faran Ahmad',
                            doctorId: doctor.userId,
                            doctorName: doctor.name,
                            aiDiagnosis: widget.aiDiagnosis ?? 'No scan data attached',
                            patientQuery: reason,
                            requestedSlot: slotString,
                            patientIdRef: 'LF-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                          );

                          if (!mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text('Appointment request sent to ${doctor.name}!'),
                                  ),
                                ],
                              ),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to book appointment: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        } finally {
                          if (mounted) {
                            setState(() => _isLoading = false);
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryMid,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Confirm Appointment Booking',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final heading = widget.filterSpecialty != null
        ? 'Find Best ${widget.filterSpecialty}'
        : 'Find Specialists';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(heading, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryMid,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryMid,
                strokeWidth: 3,
              ),
            )
          : Column(
              children: [
                // Search Header
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryMid,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        widget.filterSpecialty != null
                            ? 'Showing matching ${widget.filterSpecialty}s for your report'
                            : 'Search and book verified clinical specialists',
                        style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          hintText: "Search doctor, clinic or hospital...",
                          hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w500),
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        ),
                      ),
                    ],
                  ),
                ),

                // Doctor cards list
                Expanded(
                  child: _doctors.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_search_rounded, size: 64, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text(
                                'No matching specialists found',
                                style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: _doctors.length,
                          itemBuilder: (context, index) {
                            return _buildDoctorCard(_doctors[index]);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildDoctorCard(UserModel doctor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Doctor picture
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Colors.grey.shade100,
                  image: doctor.image != null
                      ? DecorationImage(
                          image: AssetImage(doctor.image!),
                          fit: BoxFit.cover,
                          onError: (_, __) {},
                        )
                      : null,
                ),
                child: doctor.image == null
                    ? const Icon(Icons.person, size: 40, color: Colors.grey)
                    : null,
              ),

              const SizedBox(width: 15),

              // Doctor Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            doctor.name,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            "Today",
                            style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      doctor.specialty ?? 'General Physician',
                      style: const TextStyle(color: AppTheme.primaryMid, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            doctor.hospital ?? 'Family Clinic',
                            style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Rating and Action Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '${doctor.rating ?? 4.8}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    " (${doctor.reviews ?? 45})",
                    style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () => _showBookingSheet(doctor),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryMid,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                child: const Text(
                  "Book Appointment",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}





