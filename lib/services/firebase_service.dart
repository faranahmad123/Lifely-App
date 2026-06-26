import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/scan_report_model.dart';
import '../models/appointment_model.dart';

/// ══════════════════════════════════════════════════════════════════
/// 🔥 LIFELY V2 — FIREBASE SERVICE (Unified Backend)
/// ══════════════════════════════════════════════════════════════════
/// This single file handles all Firebase Auth and Firestore operations.
/// All CRUD operations go directly to Cloud Firestore.
///
/// Collections:
///   • users         → Patient & Doctor profiles
///   • scans         → AI triage scan results
///   • appointments  → Booking transactions
/// ══════════════════════════════════════════════════════════════════

class FirebaseService {
  // ── Singleton Instance ──
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // ── Firebase References ──
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _reportsRef =>
      _db.collection('scans');
  CollectionReference<Map<String, dynamic>> get _appointmentsRef =>
      _db.collection('appointments');

  /// ══════════════════════════════════════════════════════════════════
  /// 🧪 CONNECTION TESTS
  /// ══════════════════════════════════════════════════════════════════
  
  Future<String> testFirestoreConnection() async {
    try {
      final docRef = _db.collection('connection_tests').doc('test_doc');
      
      // Attempt Write
      await docRef.set({
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'testing',
      });
      
      // Attempt Read
      final snapshot = await docRef.get();
      if (snapshot.exists) {
        return 'Firestore Connected ✅';
      } else {
        return 'Firestore Failed ❌: Document read returned null.';
      }
    } catch (e) {
      return 'Firestore Failed ❌: $e';
    }
  }

  // ══════════════════════════════════════════════════════════════════
  // 🔐 AUTHENTICATION
  // ══════════════════════════════════════════════════════════════════

  Future<firebase_auth.UserCredential> signInWithEmailPassword(
      String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
        email: email, password: password);
  }

  Future<firebase_auth.UserCredential> signUpWithEmailPassword(
      String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
  }

  /// Convenience login method that returns `null` on success or an
  /// error message string on failure, suitable for displaying in a SnackBar.
  Future<({firebase_auth.UserCredential? credential, String? error})> login(
      String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Fetch user profile from Firestore to cache the role
      final userProfile = await getUserProfile(credential.user!.uid);
      if (userProfile != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userRole', userProfile.role);
      }
      
      return (credential: credential, error: null);
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint('❌ Login failed: ${e.code} — ${e.message}');
      return (
        credential: null,
        error: e.message ?? 'Authentication failed. Please try again.',
      );
    } catch (e) {
      debugPrint('❌ Unexpected login error: $e');
      return (
        credential: null,
        error: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  /// Convenience sign-up method that returns `null` on success or an
  /// error message string on failure, suitable for displaying in a SnackBar.
  Future<({firebase_auth.UserCredential? credential, String? error})> signUp(
      String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return (credential: credential, error: null);
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint('❌ Sign-up failed: ${e.code} — ${e.message}');
      return (
        credential: null,
        error: e.message ?? 'Registration failed. Please try again.',
      );
    } catch (e) {
      debugPrint('❌ Unexpected sign-up error: $e');
      return (
        credential: null,
        error: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  Future<void> signOut() async {
    await logout();
  }

  /// Logs the user out of Firebase AND clears the local shared_preferences cache
  Future<void> logout() async {
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userRole');
  }

  // ══════════════════════════════════════════════════════════════════
  // 👤 USER PROFILE OPERATIONS
  // ══════════════════════════════════════════════════════════════════

  /// Creates or overwrites a user profile document.
  Future<void> createUserProfile(UserModel user) async {
    try {
      await _usersRef.doc(user.userId).set(user.toJson());
      
      // Cache role locally during sign up
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userRole', user.role);
      
      debugPrint('✅ User profile created: ${user.email}');
    } catch (e) {
      debugPrint('❌ Error creating user profile: $e');
      rethrow;
    }
  }

  /// Fetches a user profile by Firebase Auth UID.
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _usersRef.doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromJson(doc.data()!);
      }
      debugPrint('⚠️ No user profile found for UID: $uid');
      return null;
    } catch (e) {
      debugPrint('❌ Error fetching user profile: $e');
      rethrow;
    }
  }

  /// Updates specific fields on an existing user profile.
  Future<void> updateUserProfile(String uid, Map<String, dynamic> updates) async {
    try {
      await _usersRef.doc(uid).update(updates);
      debugPrint('✅ User profile updated: $uid');
    } catch (e) {
      debugPrint('❌ Error updating user profile: $e');
      rethrow;
    }
  }

  /// Saves the patient profile fields to Firestore with merge enabled.
  Future<void> savePatientProfile({
    required int age,
    required double weight,
    required double height,
    required String bloodGroup,
    required String address,
  }) async {
    try {
      String uid = _auth.currentUser!.uid;
      await _usersRef.doc(uid).set({
        'age': age,
        'weight': weight,
        'height': height,
        'bloodGroup': bloodGroup,
        'address': address,
      }, SetOptions(merge: true));
      debugPrint("✅ Patient Profile Updated Successfully!");
    } catch (e) {
      debugPrint("❌ Error updating patient profile: $e");
      rethrow;
    }
  }

  /// Saves the doctor profile fields to Firestore with merge enabled.
  Future<void> saveDoctorProfile({
    required String specialty,
    required String hospital,
    required String hospitalAddress,
    required String pmdcNumber,
    required int experience,
    required String aboutMe,
    List<String>? availableSlots,
  }) async {
    try {
      String uid = _auth.currentUser!.uid;
      final data = {
        'specialty': specialty,
        'hospital': hospital,
        'hospitalName': hospital, // Safe sync for both schemas
        'hospitalAddress': hospitalAddress,
        'pmdcNumber': pmdcNumber,
        'experience': experience,
        'aboutMe': aboutMe,
      };
      if (availableSlots != null) {
        data['availableSlots'] = availableSlots;
      }
      await _usersRef.doc(uid).set(data, SetOptions(merge: true));
      debugPrint("✅ Doctor Profile Updated Successfully!");
    } catch (e) {
      debugPrint("❌ Error updating doctor profile: $e");
      rethrow;
    }
  }

  /// Updates the doctor's availability for a specific day
  Future<void> updateDoctorAvailability(String day, List<String> timeSlots) async {
    try {
      String uid = _auth.currentUser!.uid;
      await _usersRef.doc(uid).set({
        'schedule': {
          day: timeSlots,
        }
      }, SetOptions(merge: true));
      debugPrint("✅ Doctor Schedule Updated for $day Successfully!");
    } catch (e) {
      debugPrint("❌ Error updating doctor schedule: $e");
      rethrow;
    }
  }

  /// Fetches the doctor's availability for a specific day
  Future<List<String>> getDoctorAvailability(String day) async {
    try {
      String uid = _auth.currentUser!.uid;
      DocumentSnapshot doc = await _usersRef.doc(uid).get();
      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('schedule') && data['schedule'] != null) {
          Map<String, dynamic> schedule = data['schedule'] as Map<String, dynamic>;
          if (schedule.containsKey(day) && schedule[day] != null) {
            // Need to handle both List<dynamic> and List<String> cases
            return (schedule[day] as List).map((e) => e.toString()).toList();
          }
        }
      }
      return [];
    } catch (e) {
      debugPrint("❌ Error fetching doctor schedule for $day: $e");
      return [];
    }
  }

  /// Fetches all doctors for the patient's "Book Appointment" screen.
  Future<List<UserModel>> getAllDoctors() async {
    try {
      final snapshot = await _usersRef.where('role', isEqualTo: 'doctor').get();
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching doctors: $e');
      return [];
    }
  }

  // ══════════════════════════════════════════════════════════════════
  // 🧪 AI TRIAGE REPORT OPERATIONS
  // ══════════════════════════════════════════════════════════════════

  /// Saves a new AI triage scan report to Firestore.
  Future<String> saveTriageReport(ScanReportModel report) async {
    try {
      final docRef = await _reportsRef.add(report.toJson());
      await docRef.update({'reportId': docRef.id});
      debugPrint('✅ Report saved with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error saving report: $e');
      rethrow;
    }
  }

  /// Fetches all reports for a specific patient, sorted newest first.
  Future<List<ScanReportModel>> getPatientReports(String patientId) async {
    try {
      final snapshot = await _reportsRef
          .where('patientId', isEqualTo: patientId)
          .orderBy('timestamp', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => ScanReportModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching patient reports: $e');
      return [];
    }
  }

  /// Real-time stream of a patient's reports (for live UI updates).
  Stream<List<ScanReportModel>> streamPatientReports(String patientId) {
    return _reportsRef
        .where('patientId', isEqualTo: patientId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ScanReportModel.fromJson(doc.data()))
            .toList());
  }

  // ══════════════════════════════════════════════════════════════════
  // 📋 APPOINTMENT OPERATIONS
  // ══════════════════════════════════════════════════════════════════

  /// Books a new appointment. Auto-generates the document ID.
  Future<String> bookAppointment(AppointmentModel appointment) async {
    try {
      final docRef = await _appointmentsRef.add(appointment.toJson());
      await docRef.update({'appointmentId': docRef.id});
      debugPrint('✅ Appointment booked: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error booking appointment: $e');
      rethrow;
    }
  }

  /// 🔥 REAL-TIME LISTENER: Doctor's incoming appointment requests.
  Stream<List<AppointmentModel>> getDoctorAppointments(String doctorId) {
    return _appointmentsRef
        .where('doctorId', isEqualTo: doctorId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => AppointmentModel.fromJson(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => (b.createdAt ?? Timestamp.now())
          .compareTo(a.createdAt ?? Timestamp.now()));
      return list;
    });
  }

  /// Fetches all appointments for a patient (non-realtime).
  Future<List<AppointmentModel>> getPatientAppointments(String patientId) async {
    try {
      final snapshot = await _appointmentsRef
          .where('patientId', isEqualTo: patientId)
          .get();
      final list = snapshot.docs
          .map((doc) => AppointmentModel.fromJson(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => (b.createdAt ?? Timestamp.now())
          .compareTo(a.createdAt ?? Timestamp.now()));
      return list;
    } catch (e) {
      debugPrint('❌ Error fetching patient appointments: $e');
      return [];
    }
  }

  /// Updates the status of an appointment (Accept/Reject).
  Future<void> updateAppointmentStatus(
    String appointmentId,
    String status, {
    String? rejectionReason,
    String? receiptId,
  }) async {
    try {
      final updates = <String, dynamic>{'status': status};
      if (rejectionReason != null) {
        updates['rejectionReason'] = rejectionReason;
      }
      if (receiptId != null) {
        updates['receiptId'] = receiptId;
      }
      await _appointmentsRef.doc(appointmentId).update(updates);
      debugPrint('✅ Appointment $appointmentId → $status');
    } catch (e) {
      debugPrint('❌ Error updating appointment status: $e');
      rethrow;
    }
  }

  // ══════════════════════════════════════════════════════════════════
  // 🔧 UTILITY METHODS
  // ══════════════════════════════════════════════════════════════════

  /// Updates the FCM token for push notifications.
  Future<void> updateFCMToken(String uid, String token) async {
    try {
      await _usersRef.doc(uid).update({'fcmToken': token});
      debugPrint('✅ FCM token updated for $uid');
    } catch (e) {
      debugPrint('❌ Error updating FCM token: $e');
    }
  }

  /// Checks if a user profile already exists in Firestore.
  Future<bool> userExists(String uid) async {
    final doc = await _usersRef.doc(uid).get();
    return doc.exists;
  }

  // ════════════════════════════════════════════════════════════════
  // 🔥 CONVENIENCE STREAM METHODS
  // ════════════════════════════════════════════════════════════════

  Stream<List<AppointmentModel>> streamDoctorAppointments(String doctorId) {
    return getDoctorAppointments(doctorId);
  }

  Stream<List<AppointmentModel>> streamPatientAppointments(String patientId) {
    return _appointmentsRef
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => AppointmentModel.fromJson(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => (b.createdAt ?? Timestamp.now())
          .compareTo(a.createdAt ?? Timestamp.now()));
      return list;
    });
  }

  Stream<List<ScanReportModel>> streamAllReports() {
    return _reportsRef
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ScanReportModel.fromJson(doc.data()))
            .toList());
  }

  Future<String> createAppointment({
    required String patientId,
    required String patientName,
    required String doctorId,
    required String doctorName,
    required Timestamp date,
    required String time,
    String patientQuery = 'AI Triage Consultation',
    String aiDiagnosis = '',
    String requestedSlot = '',
    String patientIdRef = '',
    String? queryMessage,
  }) async {
    final appointment = AppointmentModel(
      id: '',
      patientId: patientId,
      doctorId: doctorId,
      patientName: patientName,
      doctorName: doctorName,
      date: date,
      time: time,
      patientQuery: patientQuery,
      aiDiagnosis: aiDiagnosis,
      requestedSlot: requestedSlot,
      patientIdRef: patientIdRef,
      status: 'pending',
      queryMessage: queryMessage,
    );
    return await bookAppointment(appointment);
  }

  // ══════════════════════════════════════════════════════════════════
  // 🩺 SPECIALTY-FILTERED DOCTOR LOOKUP
  // ══════════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> getDoctorsBySpecialty(
      String specialty) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('users')
          .where('role', isEqualTo: 'doctor')
          .where('specialty', isEqualTo: specialty)
          .get();

      return snapshot.docs
          .map((doc) => {"id": doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching doctors by specialty: $e');
      return [];
    }
  }

  // ══════════════════════════════════════════════════════════════════
  // 📨 PATIENT: REQUEST APPOINTMENT
  // ══════════════════════════════════════════════════════════════════

  Future<void> requestAppointment({
    required String patientId,
    required String patientName,
    required String doctorId,
    required String doctorName,
    required String aiDiagnosis,
    required String patientQuery,
    required String requestedSlot,
    required String patientIdRef,
    String? queryMessage,
  }) async {
    try {
      await _db.collection('appointments').add({
        'patientId': patientId,
        'patientName': patientName,
        'doctorId': doctorId,
        'doctorName': doctorName,
        'aiDiagnosis': aiDiagnosis,
        'patientQuery': patientQuery,
        'queryMessage': queryMessage ?? patientQuery,
        'requestedSlot': requestedSlot,
        'patientIdRef': patientIdRef,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Appointment request sent to Dr. $doctorName');
    } catch (e) {
      debugPrint('❌ Error requesting appointment: $e');
      rethrow;
    }
  }

  // ══════════════════════════════════════════════════════════════════
  // ✅ DOCTOR: ACCEPT APPOINTMENT + GENERATE DIGITAL RECEIPT
  // ══════════════════════════════════════════════════════════════════

  Future<void> acceptAppointment({
    required String appointmentId,
    required String meetingTime,
    required String meetingDate,
    required String doctorId,
    required String patientIdRef,
  }) async {
    try {
      DocumentSnapshot doctorProfile =
          await _db.collection('users').doc(doctorId).get();
      Map<String, dynamic> doctorData =
          doctorProfile.data() as Map<String, dynamic>;

      String realHospital = doctorData['hospital'] ?? 'No Hospital Set';
      String realAddress = doctorData['hospitalAddress'] ?? 'No Address Set';

      await _db.collection('appointments').doc(appointmentId).update({
        'status': 'accepted',
        'receipt': {
          'meetingDate': meetingDate,
          'meetingTime': meetingTime,
          'locationName': realHospital,
          'fullAddress': realAddress,
          'patientIdRef': patientIdRef,
          'instructions':
              'Please bring your printed AI Health Scan report. Fasting is not required.',
          'generatedAt': DateTime.now().toIso8601String(),
          'paymentStatus': 'Pay at Clinic',
        },
      });
      debugPrint('✅ Appointment $appointmentId accepted with receipt');
    } catch (e) {
      debugPrint('❌ Error accepting appointment: $e');
      rethrow;
    }
  }

  // ══════════════════════════════════════════════════════════════════
  // ❌ DOCTOR: REJECT APPOINTMENT
  // ══════════════════════════════════════════════════════════════════

  Future<void> rejectAppointment(String appointmentId, String reason) async {
    try {
      await _db.collection('appointments').doc(appointmentId).update({
        'status': 'Rejected',
        'rejectionReason': reason,
      });
      debugPrint('✅ Appointment $appointmentId rejected: $reason');
    } catch (e) {
      debugPrint('❌ Error rejecting appointment: $e');
      rethrow;
    }
  }
}
