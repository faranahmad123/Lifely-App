import 'package:cloud_firestore/cloud_firestore.dart';

class ScanReportModel {
  final String reportId;
  final String patientId;
  final Map<String, dynamic> biomarkers;
  final String predictionResult;
  final double? confidenceScore;
  final String? panelType;
  final Timestamp timestamp;

  ScanReportModel({
    required this.reportId,
    required this.patientId,
    required this.biomarkers,
    required this.predictionResult,
    this.confidenceScore,
    this.panelType,
    required this.timestamp,
  });

  factory ScanReportModel.fromJson(Map<String, dynamic> json) {
    return ScanReportModel(
      reportId: json['reportId'] ?? '',
      patientId: json['patientId'] ?? '',
      biomarkers: json['biomarkers'] != null ? Map<String, dynamic>.from(json['biomarkers']) : {},
      predictionResult: json['predictionResult'] ?? 'Unknown',
      confidenceScore: (json['confidenceScore'] as num?)?.toDouble(),
      panelType: json['panelType'],
      timestamp: json['timestamp'] as Timestamp? ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reportId': reportId,
      'patientId': patientId,
      'biomarkers': biomarkers,
      'predictionResult': predictionResult,
      'confidenceScore': confidenceScore,
      'panelType': panelType,
      'timestamp': timestamp,
    };
  }

  String get riskLabel => predictionResult;
  String get panelLabel => panelType?.toUpperCase() ?? 'REPORT';
}
