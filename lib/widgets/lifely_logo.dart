import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LifelyLogo extends StatelessWidget {
  final double size;
  final bool withText;

  const LifelyLogo({
    super.key,
    this.size = 120,
    this.withText = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // --- LOGO ICON ---
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(size * 0.25),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.4),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.add_rounded, size: size * 0.8, color: Colors.white.withValues(alpha: 0.1)),
              Icon(Icons.monitor_heart_outlined, size: size * 0.5, color: Colors.white),
              Positioned(
                top: size * 0.15,
                right: size * 0.15,
                child: Container(
                  width: size * 0.15,
                  height: size * 0.15,
                  decoration: BoxDecoration(
                    color: const Color(0xFF43A047),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),

        // --- TEXT NAME ---
        if (withText) ...[
          SizedBox(height: size * 0.15),
          RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(
                fontSize: size * 0.25,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E88E5),
                letterSpacing: 0.5,
              ),
              children: const [
                TextSpan(text: "Life"),
                TextSpan(text: "ly", style: TextStyle(color: Color(0xFF43A047))),
              ],
            ),
          ),
        ],
      ],
    );
  }
}