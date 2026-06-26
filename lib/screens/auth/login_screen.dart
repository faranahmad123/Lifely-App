import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/router/app_router.dart';
import '../../services/firebase_service.dart';
import 'connection_debug_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  bool isDoctor = false;
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firebaseService = FirebaseService();

  late AnimationController _pulseController;
  late AnimationController _buttonScaleController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    _buttonScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.97,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _buttonScaleController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    
    _buttonScaleController.reverse().then((_) => _buttonScaleController.forward());
    
    setState(() => _isLoading = true);

    final result = await _firebaseService.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error!), backgroundColor: AppTheme.danger),
      );
      return;
    }

    final uid = result.credential?.user?.uid;
    if (uid != null) {
      final userProfile = await _firebaseService.getUserProfile(uid);
      if (!mounted) return;

      if (userProfile != null && userProfile.role == 'doctor') {
        Navigator.pushReplacementNamed(context, AppRouter.doctorDashboard);
      } else {
        Navigator.pushReplacementNamed(context, AppRouter.patientDashboard);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final minHeight = mq.size.height - mq.padding.top - mq.padding.bottom;

    return Scaffold(
      backgroundColor: AppTheme.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── HERO HEADER (Flex proportion) ──
                  Expanded(
                    flex: 38,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: AppTheme.heroGradient,
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Radial subtle glow (simulated with a container)
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Colors.white.withValues(alpha: 0.1), blurRadius: 100, spreadRadius: 40)
                              ],
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Pulsing icon
                              SizedBox(
                                width: 160,
                                height: 160,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Concentric rings
                                    ...List.generate(3, (index) {
                                      return AnimatedBuilder(
                                        animation: _pulseController,
                                        builder: (context, child) {
                                          // Staggered animation
                                          double value = (_pulseController.value + (index * 0.33)) % 1.0;
                                          double scale = 1.0 + (value * 0.6); // 100% to 160%
                                          double opacity = 0.15 * (1.0 - value); // Fade out
                                          
                                          return Transform.scale(
                                            scale: scale,
                                            child: Container(
                                              width: 100,
                                              height: 100,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.white.withValues(alpha: opacity),
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    }),
                                    // Center Icon
                                    Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withValues(alpha: 0.25),
                                      ),
                                      child: const Icon(Icons.health_and_safety_rounded, size: 72, color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: Text(
                                  "Welcome back to Lifely",
                                  textAlign: TextAlign.center,
                                  style: AppTheme.display.copyWith(color: Colors.white, fontSize: 28),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: Text(
                                  "Securely access clinical-grade health diagnostics",
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  style: AppTheme.bodyM.copyWith(color: Colors.white.withValues(alpha: 0.80)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── BOTTOM CONTENT ──
                  Expanded(
                    flex: 62,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          
                          // ── PROFILE SELECTOR ──
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => isDoctor = false),
                                  child: _buildProfileCard(
                                    title: "Patient",
                                    icon: Icons.person_rounded,
                                    isSelected: !isDoctor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => isDoctor = true),
                                  child: _buildProfileCard(
                                    title: "Doctor",
                                    icon: Icons.medical_services_rounded,
                                    isSelected: isDoctor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 24),

                          // ── FORM CARD ──
                          Form(
                            key: _formKey,
                            child: Container(
                              decoration: AppTheme.cardDecorationL2,
                              clipBehavior: Clip.antiAlias,
                              child: Column(
                                children: [
                                  // Decorative blue line top
                                  Container(
                                    height: 3,
                                    width: 40,
                                    margin: const EdgeInsets.only(top: 16),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryMid,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        _buildTextFormField(
                                          controller: _emailController,
                                          hint: isDoctor ? "Doctor Email" : "Patient Email",
                                          icon: Icons.mail_outline_rounded,
                                          validator: (v) => v!.trim().isEmpty ? 'Required' : (!v.contains('@') ? 'Invalid email' : null),
                                        ),
                                        const SizedBox(height: 16),
                                        _buildTextFormField(
                                          controller: _passwordController,
                                          hint: "Password",
                                          icon: Icons.lock_outline_rounded,
                                          isPassword: true,
                                          validator: (v) => v!.isEmpty ? 'Required' : null,
                                        ),
                                        const SizedBox(height: 8),
                                        TextButton(
                                          onPressed: () {},
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            minimumSize: const Size(50, 30),
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                          child: Text(
                                            "Forgot Password?",
                                            style: AppTheme.bodyM.copyWith(
                                              color: AppTheme.primaryMid,
                                              fontWeight: FontWeight.w600,
                                              decoration: TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                        
                                        const SizedBox(height: 24),
                                        
                                        // ── CTA BUTTON ──
                                        ScaleTransition(
                                          scale: _buttonScaleController,
                                          child: Container(
                                            width: double.infinity,
                                            height: 56,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(AppTheme.borderRadiusPill),
                                              gradient: AppTheme.tealCtaGradient,
                                              boxShadow: [
                                                ...AppTheme.shadowBlueGlow,
                                                BoxShadow(color: const Color(0xFF0D9488).withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4)),
                                              ],
                                            ),
                                            child: ElevatedButton(
                                              onPressed: _isLoading ? null : _handleLogin,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.transparent,
                                                shadowColor: Colors.transparent,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.borderRadiusPill)),
                                              ),
                                              child: _isLoading
                                                  ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                                  : Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        const Icon(Icons.lock_rounded, size: 18, color: Colors.white),
                                                        const SizedBox(width: 8),
                                                        Text(
                                                          isDoctor ? "Login as Doctor" : "Login as Patient",
                                                          style: AppTheme.bodyL.copyWith(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 17),
                                                        ),
                                                      ],
                                                    ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          const Spacer(),

                          // ── SIGN UP LINK ──
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("Don't have an account? ", style: AppTheme.bodyM.copyWith(color: AppTheme.textSecondary)),
                                GestureDetector(
                                  onTap: () => Navigator.pushNamed(context, AppRouter.signup),
                                  child: Text("Sign Up", style: AppTheme.bodyM.copyWith(color: AppTheme.primaryMid, fontWeight: FontWeight.w700, decoration: TextDecoration.underline)),
                                ),
                              ],
                            ),
                          ),
                          
                          // Debug Button
                          TextButton.icon(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ConnectionDebugScreen())),
                            icon: const Icon(Icons.bug_report_rounded, color: AppTheme.textMuted, size: 14),
                            label: Text('Test Connections', style: AppTheme.caption.copyWith(color: AppTheme.textMuted)),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard({required String title, required IconData icon, required bool isSelected}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: 90,
      decoration: BoxDecoration(
        gradient: isSelected ? const LinearGradient(colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)]) : null,
        color: isSelected ? null : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusCard),
        border: Border.all(color: isSelected ? AppTheme.primaryMid : const Color(0xFFE2E8F0), width: isSelected ? 2 : 1.5),
        boxShadow: isSelected ? [] : AppTheme.shadowLevel2,
      ),
      child: Stack(
        children: [
          if (isSelected)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(color: AppTheme.primaryMid, shape: BoxShape.circle),
                child: const Icon(Icons.check, size: 8, color: Colors.white),
              ),
            ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryMid : const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 22, color: isSelected ? Colors.white : const Color(0xFF94A3B8)),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: isSelected
                      ? AppTheme.bodyM.copyWith(fontWeight: FontWeight.w700, color: AppTheme.primaryMid, fontSize: 15)
                      : AppTheme.bodyM.copyWith(fontWeight: FontWeight.w500, color: AppTheme.textMuted, fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return Container(
      height: 56, // Fixed exact height as requested
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusInput),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword && !_isPasswordVisible,
        validator: validator,
        style: AppTheme.bodyM.copyWith(fontSize: 15, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTheme.bodyM.copyWith(color: AppTheme.textMuted, fontSize: 14),
          prefixIcon: Icon(icon, color: AppTheme.primaryMid, size: 20),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusInput),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusInput),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusInput),
            borderSide: const BorderSide(color: AppTheme.primaryMid, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusInput),
            borderSide: const BorderSide(color: AppTheme.danger, width: 1.5),
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(_isPasswordVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded, color: _isPasswordVisible ? AppTheme.primaryMid : AppTheme.textMuted, size: 20),
                  onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                )
              : null,
        ),
      ),
    );
  }
}