import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/router/app_router.dart';
import '../../services/firebase_service.dart';
import '../../models/user_model.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> with TickerProviderStateMixin {
  bool isDoctor = false;
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();
  final _firebaseService = FirebaseService();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _ageController = TextEditingController();
  final _bloodGroupController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();

  final _specialtyController = TextEditingController();
  final _hospitalController = TextEditingController();
  final _hospitalAddressController = TextEditingController();
  final _experienceController = TextEditingController();
  final _pmdcController = TextEditingController();
  final _aboutMeController = TextEditingController();

  late AnimationController _buttonScaleController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _buttonScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.97,
      upperBound: 1.0,
      value: 1.0,
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _ageController.dispose();
    _bloodGroupController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _specialtyController.dispose();
    _hospitalController.dispose();
    _hospitalAddressController.dispose();
    _experienceController.dispose();
    _pmdcController.dispose();
    _aboutMeController.dispose();
    _buttonScaleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    
    _buttonScaleController.reverse().then((_) => _buttonScaleController.forward());
    
    setState(() => _isLoading = true);

    final result = await _firebaseService.signUp(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (result.error != null) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error!), backgroundColor: AppTheme.danger),
      );
      return;
    }

    final uid = result.credential!.user!.uid;
    final role = isDoctor ? 'doctor' : 'patient';

    final userProfile = UserModel(
      userId: uid,
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      role: role,
      age: int.tryParse(_ageController.text.trim()) ?? 0,
      bloodGroup: _bloodGroupController.text.trim(),
      weight: double.tryParse(_weightController.text.trim()) ?? 0.0,
      height: double.tryParse(_heightController.text.trim()) ?? 0.0,
      specialty: _specialtyController.text.trim(),
      hospital: _hospitalController.text.trim(),
      hospitalAddress: _hospitalAddressController.text.trim(),
      experience: int.tryParse(_experienceController.text.trim()) ?? 0,
      pmdcNumber: _pmdcController.text.trim(),
      aboutMe: _aboutMeController.text.trim(),
    );

    try {
      await _firebaseService.createUserProfile(userProfile);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save profile: $e'), backgroundColor: AppTheme.danger),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (isDoctor) {
      Navigator.pushReplacementNamed(context, AppRouter.doctorDashboard);
    } else {
      Navigator.pushReplacementNamed(context, AppRouter.patientDashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── HEADER ──
              Container(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                decoration: const BoxDecoration(
                  gradient: AppTheme.heroGradient,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          ...List.generate(3, (index) {
                            return AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                double value = (_pulseController.value + (index * 0.33)) % 1.0;
                                double scale = 1.0 + (value * 0.6);
                                double opacity = 0.15 * (1.0 - value);
                                return Transform.scale(
                                  scale: scale,
                                  child: Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: opacity)),
                                  ),
                                );
                              },
                            );
                          }),
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.25)),
                            child: const Icon(Icons.person_add_alt_1_rounded, size: 40, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text("Create Account", style: AppTheme.display.copyWith(color: Colors.white, fontSize: 28)),
                    const SizedBox(height: 4),
                    Text("Join Lifely for secure clinical diagnostics", style: AppTheme.bodyM.copyWith(color: Colors.white.withValues(alpha: 0.8))),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),
                      
                      // ── PROFILE SELECTOR ──
                      Row(
                        children: [
                          Expanded(child: GestureDetector(onTap: () => setState(() => isDoctor = false), child: _buildProfileCard(title: "Patient", icon: Icons.person_rounded, isSelected: !isDoctor))),
                          const SizedBox(width: 12),
                          Expanded(child: GestureDetector(onTap: () => setState(() => isDoctor = true), child: _buildProfileCard(title: "Doctor", icon: Icons.medical_services_rounded, isSelected: isDoctor))),
                        ],
                      ),
                      
                      const SizedBox(height: 28),

                      // ── REQUIRED INFORMATION ──
                      Row(
                        children: [
                          Container(width: 3, height: 18, decoration: BoxDecoration(color: AppTheme.primaryMid, borderRadius: BorderRadius.circular(2))),
                          const SizedBox(width: 8),
                          Text("Required Information", style: AppTheme.bodyL.copyWith(fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: AppTheme.cardDecorationL1.copyWith(borderRadius: BorderRadius.circular(20)),
                        child: Column(
                          children: [
                            _buildTextFormField(controller: _nameController, hint: "Full Name", icon: Icons.person_rounded, iconColor: const Color(0xFF8B5CF6), validator: (v) => v!.trim().isEmpty ? 'Required' : null),
                            const SizedBox(height: 12),
                            _buildTextFormField(controller: _emailController, hint: "Email Address", icon: Icons.mail_rounded, iconColor: AppTheme.primaryMid, validator: (v) => v!.trim().isEmpty ? 'Required' : (!v.contains('@') ? 'Invalid' : null)),
                            const SizedBox(height: 12),
                            _buildTextFormField(controller: _passwordController, hint: "Password", icon: Icons.lock_rounded, iconColor: AppTheme.accentTeal, isPassword: true, validator: (v) => v!.length < 6 ? 'Min 6 chars' : null),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── SPECIFIC SECTION ──
                      Row(
                        children: [
                          Container(width: 3, height: 18, decoration: BoxDecoration(color: AppTheme.pending, borderRadius: BorderRadius.circular(2))),
                          const SizedBox(width: 8),
                          Text(isDoctor ? "Professional Details" : "Health Metrics", style: AppTheme.bodyL.copyWith(fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      if (!isDoctor)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: AppTheme.cardDecorationL1.copyWith(borderRadius: BorderRadius.circular(20)),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(child: _buildMetricTile("Age", Icons.cake_rounded, const Color(0xFF8B5CF6), const Color(0xFFFAF5FF), _ageController)),
                                  const SizedBox(width: 10),
                                  Expanded(child: _buildMetricTile("Blood Group", Icons.water_drop_rounded, const Color(0xFFEF4444), const Color(0xFFFEF2F2), _bloodGroupController)),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(child: _buildMetricTile("Weight (kg)", Icons.monitor_weight_rounded, const Color(0xFF1A56DB), const Color(0xFFEFF6FF), _weightController)),
                                  const SizedBox(width: 10),
                                  Expanded(child: _buildMetricTile("Height (cm)", Icons.height_rounded, const Color(0xFFF59E0B), const Color(0xFFFFFBEB), _heightController)),
                                ],
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: AppTheme.cardDecorationL1.copyWith(borderRadius: BorderRadius.circular(20)),
                          child: Column(
                            children: [
                              _buildTextFormField(controller: _specialtyController, hint: "Specialization", icon: Icons.local_hospital_rounded, iconColor: AppTheme.primaryMid),
                              const SizedBox(height: 12),
                              _buildTextFormField(controller: _hospitalController, hint: "Hospital Name", icon: Icons.domain_rounded, iconColor: AppTheme.primaryMid),
                              const SizedBox(height: 12),
                              _buildTextFormField(controller: _pmdcController, hint: "PMDC Number", icon: Icons.badge_rounded, iconColor: AppTheme.primaryMid),
                            ],
                          ),
                        ),

                      const SizedBox(height: 36),

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
                            onPressed: _isLoading ? null : _handleSignup,
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
                                      const Icon(Icons.person_add_rounded, size: 18, color: Colors.white),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Register Now",
                                        style: AppTheme.bodyL.copyWith(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 17),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Already have an account? ", style: AppTheme.bodyM.copyWith(color: AppTheme.textSecondary)),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Text("Log In", style: AppTheme.bodyM.copyWith(color: AppTheme.primaryMid, fontWeight: FontWeight.w700, decoration: TextDecoration.underline)),
                          ),
                        ],
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
            Positioned(top: 8, right: 8, child: Container(width: 12, height: 12, decoration: const BoxDecoration(color: AppTheme.primaryMid, shape: BoxShape.circle), child: const Icon(Icons.check, size: 8, color: Colors.white))),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: isSelected ? AppTheme.primaryMid : const Color(0xFFF1F5F9), shape: BoxShape.circle),
                  child: Icon(icon, size: 22, color: isSelected ? Colors.white : const Color(0xFF94A3B8)),
                ),
                const SizedBox(height: 6),
                Text(title, style: AppTheme.bodyM.copyWith(fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: isSelected ? AppTheme.primaryMid : AppTheme.textMuted, fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, IconData icon, Color iconColor, Color iconBgColor, TextEditingController controller) {
    return Container(
      height: 70,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: AppTheme.badge.copyWith(color: AppTheme.textMuted)),
                SizedBox(
                  height: 24,
                  child: TextFormField(
                    controller: controller,
                    style: AppTheme.bodyM.copyWith(fontWeight: FontWeight.w500, fontSize: 14),
                    decoration: const InputDecoration(
                      border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero, isDense: true, hintText: "-",
                    ),
                  ),
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
    required Color iconColor,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(AppTheme.borderRadiusInput)),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword && !_isPasswordVisible,
        validator: validator,
        style: AppTheme.bodyM.copyWith(fontSize: 15, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTheme.bodyM.copyWith(color: AppTheme.textMuted, fontSize: 14),
          prefixIcon: Icon(icon, color: iconColor, size: 20),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.borderRadiusInput), borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.borderRadiusInput), borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.borderRadiusInput), borderSide: const BorderSide(color: AppTheme.primaryMid, width: 2)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.borderRadiusInput), borderSide: const BorderSide(color: AppTheme.danger, width: 1.5)),
          suffixIcon: isPassword ? IconButton(icon: Icon(_isPasswordVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded, color: _isPasswordVisible ? AppTheme.primaryMid : AppTheme.textMuted, size: 20), onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible)) : null,
        ),
      ),
    );
  }
}