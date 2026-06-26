import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/appointment_model.dart';

class ReceiptService {
  static Future<void> generateAndDownloadReceipt(AppointmentModel appt) async {
    try {
      final receiptData = appt.receipt ?? {};

      String hospitalName = receiptData['locationName'] ?? 'No Hospital Listed';
      String hospitalAddress = receiptData['fullAddress'] ?? 'No Address Listed';
      String meetingDate = receiptData['meetingDate'] ?? 'Date TBD';
      String meetingTime = receiptData['meetingTime'] ?? 'Time TBD';
      String instructions = receiptData['instructions'] ??
          'Please bring your printed AI Health Scan report to the clinic. Fasting is not required.';
      
      String rawPatientId = appt.patientId;
      String verificationCode = rawPatientId.length >= 6
          ? "LIFELY-${rawPatientId.substring(0, 6).toUpperCase()}"
          : "LIFELY-000000";

      // Determine specialty placeholder if missing
      String specialty = "General Checkup";
      if (appt.patientQuery.toLowerCase().contains("triage")) {
        specialty = "AI Triage Review";
      }

      final doc = pw.Document();

      doc.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    'LIFELY DIGITAL RECEIPT',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Text(
                  'APPOINTMENT DETAILS',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 10),
                pw.Text('Date & Time: $meetingDate at $meetingTime'),
                pw.Text('Doctor Name: ${appt.doctorName}'),
                pw.Text('Specialty: $specialty'),
                pw.Text('Hospital/Clinic: $hospitalName'),
                pw.Text('Address: $hospitalAddress'),
                pw.Text('Status: ACCEPTED'),
                pw.Text('Consultation Fee: Paid: \$50.00'),
                pw.SizedBox(height: 20),
                pw.Text(
                  'PATIENT DETAILS',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 10),
                pw.Text('Patient Name: ${appt.patientName}'),
                pw.Text('Patient ID: $verificationCode'),
                pw.Text('Reason for Visit: ${appt.patientQuery.isNotEmpty ? appt.patientQuery : 'General Checkup'}'),
                pw.Text('AI Diagnosis Attached: ${appt.aiDiagnosis.isNotEmpty ? appt.aiDiagnosis : 'None'}'),
                pw.SizedBox(height: 20),
                pw.Text(
                  'INSTRUCTIONS',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 10),
                pw.Text(instructions),
                pw.SizedBox(height: 30),
                pw.Divider(),
                pw.Center(
                  child: pw.Text(
                    'Thank you for using Lifely',
                    style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey),
                  ),
                ),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => doc.save(),
        name: 'Lifely_Receipt_${appt.patientName.replaceAll(' ', '_')}.pdf',
      );
    } catch (e) {
      debugPrint('Error generating receipt: $e');
    }
  }
}
