import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/auth_wrapper.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  // --- DATA FOR SLIDES ---
  final List<Map<String, String>> _contents = [
    {
      "title": "Scan Medical Reports",
      "desc": "Upload a photo of your blood test. Our AI analyzes the parameters instantly to detect potential health issues.",
      "image": "assets/images/onboarding1.png" // You can replace with Icons if no image
    },
    {
      "title": "Smart Doctor Suggestion",
      "desc": "Detected an issue? The app automatically matches you with the best specialists for your specific condition.",
      "image": "assets/images/onboarding2.png"
    },
    {
      "title": "Digital Health Receipts",
      "desc": "Access your official medical appointment receipts on the go. Download clinical invoices in premium PDF format.",
      "image": "assets/images/onboarding3.png"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),


            // --- 1. APP NAME & LOGO ---
            // Using the Widget we created earlier, or simple Text if you prefer
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.health_and_safety_rounded, color: Color(0xFF1E88E5), size: 30),
                const SizedBox(width: 8),
                Text(
                  "Lifely",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E88E5),
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),

            // --- 2. SLIDER SECTION ---
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (index) => setState(() => _currentIndex = index),
                itemCount: _contents.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Illustration (Using Icons for now, replace with Image.asset if you have PNGs)
                        Container(
                          padding: const EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E88E5).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getIconForIndex(index),
                            size: 100,
                            color: const Color(0xFF1E88E5),
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Title
                        Text(
                          _contents[index]['title']!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Description
                        Text(
                          _contents[index]['desc']!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade600,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // --- 3. CONTROLS (Dots & Buttons) ---
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // --- SKIP BUTTON (BOLD) ---
                  TextButton(
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('hasSeenIntro', true);
                      if (context.mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const AuthWrapper()),
                        );
                      }
                    },
                    child: Text(
                      "Skip",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold, // Extra Bold
                          color: Colors.black
                      ),
                    ),
                  ),

                  // Dots Indicator
                  Row(
                    children: List.generate(
                      _contents.length,
                          (index) => _buildDot(index),
                    ),
                  ),

                  // Next / Get Started Button
                  ElevatedButton(
                    onPressed: () async {
                      if (_currentIndex == _contents.length - 1) {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('hasSeenIntro', true);
                        if (context.mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const AuthWrapper()),
                          );
                        }
                      } else {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeIn,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(16),
                      backgroundColor: const Color(0xFF1E88E5),
                    ),
                    child: const Icon(Icons.arrow_forward, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper to pick icons based on slide index
  IconData _getIconForIndex(int index) {
    switch (index) {
      case 0: return Icons.document_scanner_rounded;
      case 1: return Icons.person_search_rounded; // Doctor Search Icon
      case 2: return Icons.receipt_long_rounded;
      default: return Icons.circle;
    }
  }

  Widget _buildDot(int index) {
    return Container(
      height: 8,
      width: _currentIndex == index ? 24 : 8,
      margin: const EdgeInsets.only(right: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: _currentIndex == index ? const Color(0xFF1E88E5) : Colors.grey.shade300,
      ),
    );
  }
}