import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../services/ai_service.dart';
import '../../services/firebase_service.dart';
import '../../models/scan_report_model.dart';

class ScanReportScreen extends StatefulWidget {
  const ScanReportScreen({super.key});

  @override
  State<ScanReportScreen> createState() => _ScanReportScreenState();
}

class _ScanReportScreenState extends State<ScanReportScreen> {
  final AiService _aiService = AiService();
  final FirebaseService _firebaseService = FirebaseService();
  final ImagePicker _picker = ImagePicker();

  String _selectedPanel = 'cbc';
  File? _imageFile;
  bool _isAnalyzing = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source, imageQuality: 50, maxWidth: 1200);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e'), backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  Future<void> _analyzeReport() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image first.')),
      );
      return;
    }

    setState(() => _isAnalyzing = true);

    try {
      final result = await _aiService.analyzeReport(
        imageFile: _imageFile!,
        panelType: _selectedPanel,
      );

      if (mounted && result != null) {
        _showResultsDialog(result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppTheme.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  void _showResultsDialog(Map<String, dynamic> result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final diagnosis = result['diagnosis']?.toString() ?? 'Unknown';
        final confidence = (result['confidence'] ?? result['risk_score'] ?? 0.0) as num;
        final extractedValues = result['extracted_values'] as Map<String, dynamic>? ?? {};

        final isHighRisk = diagnosis.toLowerCase().contains('disease') || 
                           diagnosis.toLowerCase().contains('diabetic') || 
                           diagnosis.toLowerCase().contains('high risk');

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            top: 16,
            left: 24,
            right: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isHighRisk ? AppTheme.dangerBg : AppTheme.successBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isHighRisk ? Icons.warning_rounded : Icons.check_circle_rounded,
                      color: isHighRisk ? AppTheme.danger : AppTheme.success,
                      size: 36,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Diagnosis',
                          style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          diagnosis,
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: isHighRisk ? AppTheme.danger : AppTheme.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryMid,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Confidence',
                          style: GoogleFonts.inter(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${confidence.toStringAsFixed(1)}%',
                          style: GoogleFonts.inter(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Detected Biomarkers',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 12),
              if (extractedValues.isEmpty)
                Text('No biomarkers detected.', style: GoogleFonts.inter(color: AppTheme.textSecondary))
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: extractedValues.entries.map((e) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${e.key}: ', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13)),
                          Text('${e.value}', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppTheme.textPrimary, fontSize: 13)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 32),
              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
                      if (uid.isNotEmpty) {
                        final report = ScanReportModel(
                          reportId: '',
                          patientId: uid,
                          biomarkers: extractedValues,
                          predictionResult: diagnosis,
                          confidenceScore: confidence.toDouble(),
                          panelType: _selectedPanel,
                          timestamp: Timestamp.now(),
                        );
                        await _firebaseService.saveTriageReport(report);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Report Saved to History!'), backgroundColor: AppTheme.success),
                          );
                          Navigator.pop(context); // Close sheet
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error saving report: $e'), backgroundColor: AppTheme.danger),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.bookmark_add_rounded, color: Colors.white),
                  label: Text('Save to History', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryMid,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // ── HEADER ──
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                bottom: 24,
                left: 20,
                right: 20,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F172A), AppTheme.primaryMid],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Scan Medical Report',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 20,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Text(
                                '☁ Cloud AI · OCR + ML Pipeline',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── SCROLLABLE CONTENT ──
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── PANEL SELECTOR CARD ──
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: AppTheme.cardDecorationL1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.science_rounded, color: AppTheme.primaryMid, size: 22),
                              const SizedBox(width: 10),
                              Text(
                                'Select Panel Type',
                                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.textPrimary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: [
                                _buildPanelChip('cbc', 'CBC (Anemia)', Icons.bloodtype_rounded, const Color(0xFFEF4444), const Color(0xFFFEF2F2)),
                                const SizedBox(width: 10),
                                _buildPanelChip('lft', 'LFT (Liver)', Icons.monitor_heart_rounded, const Color(0xFFF59E0B), const Color(0xFFFFFBEB)),
                                const SizedBox(width: 10),
                                _buildPanelChip('diabetes', 'Metabolic', Icons.biotech_rounded, const Color(0xFFA855F7), const Color(0xFFFAF5FF)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── UPLOAD SECTION CARD ──
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: AppTheme.cardDecorationL1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.camera_alt_rounded, color: AppTheme.accentTeal, size: 22),
                              const SizedBox(width: 10),
                              Text(
                                'Upload Report Image',
                                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.textPrimary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          if (_imageFile == null)
                            // ── DROP ZONE ──
                            GestureDetector(
                              onTap: () => _pickImage(ImageSource.gallery),
                              child: CustomPaint(
                                painter: DashedRectPainter(color: const Color(0xFFCBD5E1), strokeWidth: 2, gap: 5),
                                child: Container(
                                  width: double.infinity,
                                  height: 180,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.image_outlined, size: 48, color: Color(0xFF94A3B8)),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Tap to select an image',
                                        style: GoogleFonts.inter(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 15),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Use camera or gallery',
                                        style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          else
                            // ── IMAGE PREVIEW ──
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.primaryMid, width: 2),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Stack(
                                  alignment: Alignment.topRight,
                                  children: [
                                    Image.file(_imageFile!, height: 250, width: double.infinity, fit: BoxFit.cover),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: IconButton(
                                        onPressed: () => setState(() => _imageFile = null),
                                        icon: const Icon(Icons.cancel_rounded, color: Colors.red, size: 32),
                                        style: IconButton.styleFrom(backgroundColor: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          // ── CAMERA / GALLERY BUTTONS ──
                          if (_imageFile == null) ...[
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _pickImage(ImageSource.camera),
                                    icon: const Icon(Icons.camera_alt_rounded, size: 18, color: AppTheme.primaryMid),
                                    label: const Text('Camera'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.primaryMid,
                                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _pickImage(ImageSource.gallery),
                                    icon: const Icon(Icons.photo_library_rounded, size: 18, color: AppTheme.success),
                                    label: const Text('Gallery'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.textPrimary,
                                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── BOTTOM ANALYZE BUTTON ──
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusPill),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentTeal.withValues(alpha: 0.40),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _isAnalyzing ? null : _analyzeReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentTeal,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.borderRadiusPill)),
                  ),
                  icon: _isAnalyzing
                      ? const SizedBox.shrink()
                      : const Text("🔬", style: TextStyle(fontSize: 18)),
                  label: _isAnalyzing
                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Text(
                          'Analyze Report',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── PANEL CHIP BUILDER ──
  Widget _buildPanelChip(String value, String label, IconData icon, Color activeColor, Color activeBg) {
    final isSelected = _selectedPanel == value;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedPanel = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.white,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? activeColor : AppTheme.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? activeColor : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Simple Dashed Rectangle Painter
class DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DashedRectPainter({required this.color, required this.strokeWidth, required this.gap});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Path path = Path();
    path.addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(12)));

    // Dash logic (simplified via a basic line drawn around bounds)
    // For a true dashed path, we use PathMetrics, but for performance/simplicity, drawing the rect is often enough if we just want a border.
    // Wait, the user asked for dashed. Let's write a simple dash generator.
    for (var metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final pathSegment = metric.extractPath(distance, distance + gap);
        canvas.drawPath(pathSegment, paint);
        distance += gap * 2;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
