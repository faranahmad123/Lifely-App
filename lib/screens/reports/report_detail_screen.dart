import 'package:flutter/material.dart';

class ReportDetailScreen extends StatelessWidget {
  const ReportDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Retrieve arguments passed from History Screen
    final Map<String, dynamic>? report = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    // Default title if accessed directly
    final String disease = report?['disease'] ?? "Unknown";
    final String date = report?['date'] ?? "Unknown Date";

    // --- FULL DATASET PARAMETERS (Mock Values for UI) ---
    // These match your CSV columns exactly
    final Map<String, String> parameters = {
      "Glucose": "0.85 (High)",
      "Cholesterol": "0.45",
      "Hemoglobin": "0.65",
      "Platelets": "0.50",
      "White Blood Cells": "0.48",
      "Red Blood Cells": "0.52",
      "Hematocrit": "0.49",
      "Mean Corpuscular Volume": "0.51",
      "Mean Corpuscular Hemoglobin": "0.47",
      "MCH Concentration": "0.55",
      "Insulin": "0.60",
      "BMI": "0.40",
      "Systolic BP": "0.35",
      "Diastolic BP": "0.42",
      "Triglycerides": "0.38",
      "HbA1c": "0.75",
      "LDL Cholesterol": "0.44",
      "HDL Cholesterol": "0.50",
      "ALT": "0.30",
      "AST": "0.32",
      "Heart Rate": "0.58",
      "Creatinine": "0.41",
      "Troponin": "0.10",
      "C-reactive Protein": "0.15"
    };

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Report Details"),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER CARD ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10)],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: disease == 'Healthy' ? Colors.green.shade100 : Colors.red.shade100,
                    child: Icon(
                      disease == 'Healthy' ? Icons.check : Icons.warning_amber_rounded,
                      color: disease == 'Healthy' ? Colors.green : Colors.red,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Diagnosis", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                      Text(disease, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 5),
                      Text("Date: $date", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),
            const Text("Detailed Parameters (24)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),

            // --- 24 PARAMETERS GRID ---
            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: parameters.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                String key = parameters.keys.elementAt(index);
                String value = parameters.values.elementAt(index);
                return Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(key, style: const TextStyle(fontWeight: FontWeight.w500))),
                      Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 30),

            // --- ACTION BUTTON ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Placeholder for PDF download
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Downloading PDF...")));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88E5),
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.download, color: Colors.white),
                label: const Text("Download Full Report", style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            )
          ],
        ),
      ),
    );
  }
}