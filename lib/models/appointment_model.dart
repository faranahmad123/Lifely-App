import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentModel {
  final String id;
  final String patientId;
  final String doctorId;
  final String patientName;
  final String doctorName;
  final Timestamp date;
  final String time;
  final String patientQuery;
  final String aiDiagnosis;
  final String requestedSlot;
  final String patientIdRef;
  final String status;
  final String? queryMessage;
  final Timestamp? createdAt;
  final Map<String, dynamic>? receipt;

  AppointmentModel({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.patientName,
    required this.doctorName,
    required this.date,
    required this.time,
    required this.patientQuery,
    required this.aiDiagnosis,
    required this.requestedSlot,
    required this.patientIdRef,
    required this.status,
    this.queryMessage,
    this.createdAt,
    this.receipt,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json, String documentId) {
    return AppointmentModel(
      id: documentId,
      patientId: json['patientId'] ?? '',
      doctorId: json['doctorId'] ?? '',
      patientName: json['patientName'] ?? '',
      doctorName: json['doctorName'] ?? '',
      date: json['timeSlot'] ?? Timestamp.now(), // Mapping 'timeSlot' to 'date'
      time: json['timeDisplay'] ?? '',
      patientQuery: json['patientQuery'] ?? '',
      aiDiagnosis: json['aiDiagnosis'] ?? '',
      requestedSlot: json['requestedSlot'] ?? '',
      patientIdRef: json['patientIdRef'] ?? '',
      status: json['status'] ?? 'pending',
      queryMessage: json['queryMessage'],
      createdAt: json['createdAt'] as Timestamp?,
      receipt: json['receipt'] != null ? Map<String, dynamic>.from(json['receipt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patientId': patientId,
      'doctorId': doctorId,
      'patientName': patientName,
      'doctorName': doctorName,
      'timeSlot': date,
      'timeDisplay': time,
      'patientQuery': patientQuery,
      'aiDiagnosis': aiDiagnosis,
      'requestedSlot': requestedSlot,
      'patientIdRef': patientIdRef,
      'status': status,
      'queryMessage': queryMessage,
      if (createdAt != null) 'createdAt': createdAt,
      if (receipt != null) 'receipt': receipt,
    };
  }

  // Getters for properties used in UI
  String get appointmentId => id;
}
