import 'package:flutter/material.dart';

import 'api_service.dart';
import 'app_theme.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nameController = TextEditingController();
  final studentCodeController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool loading = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  @override
  void dispose() {
    nameController.dispose();
    studentCodeController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();

    super.dispose();
  }

  // ===========================================================
  // ตรรกะการสมัครสมาชิก (คงเดิมทุกอย่าง ไม่มีการแก้ไข)
  // ===========================================================
  Future<void> register() async {
    final name = nameController.text.trim();
    final studentCode = studentCodeController.text.trim();
    final phone = phoneController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (name.isEmpty) {
      showMessage('กรุณากรอกชื่อ');
      return;
    }

    if (studentCode.isEmpty) {
      showMessage('กรุณากรอกรหัสนักศึกษา');
      return;
    }

    if (email.isEmpty) {
      showMessage('กรุณากรอกอีเมล');
      return;
    }

    if (!email.contains('@')) {
      showMessage('กรุณากรอกอีเมลให้ถูกต้อง');
      return;
    }

    if (password.isEmpty) {
      showMessage('กรุณากรอกรหัสผ่าน');
      return;
    }

    if (password.length < 6) {
      showMessage('รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร');
      return;
    }

    if (password != confirmPassword) {
      showMessage('รหัสผ่านไม่ตรงกัน');
      return;
    }

    if (loading) return;

    setState(() {
      loading = true;
    });

    try {
      final result = await ApiService.register(
        name: name,
        email: email,
        password: password,
        studentCode: studentCode,
        phone: phone.isEmpty ? null : phone,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          loading = false;
        });

        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            return AlertDialog(
              icon: Container(
                width: 84,
                height: 84,
                decoration: const BoxDecoration(
                  color: AppColors.successContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 52,
                ),
              ),
              title: const Text(
                'สมัครสมาชิกสำเร็จ',
                textAlign: TextAlign.center,
              ),
              content: const Text(
                'สร้างบัญชี DormEasy เรียบร้อยแล้ว\n'
                'กรุณาเข้าสู่ระบบเพื่อเริ่มใช้งาน',
                textAlign: TextAlign.center,
              ),
              actionsPadding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              actions: [
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                    },
                    child: const Text('ไปหน้าเข้าสู่ระบบ'),
                  ),
                ),
              ],
            );
          },
        );

        if (!mounted) return;

        Navigator.pop(context, true);
      } else {
        setState(() {
          loading = false;
        });

        showMessage(
          result['message']?.toString() ?? 'สมัครสมาชิกไม่สำเร็จ',
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      showMessage('เกิดข้อผิดพลาด: $e');
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  // ===========================================================
  // ส่วนประกอบ UI (ตกแต่งอย่างเดียว ไม่แตะตรรกะ)
  // ===========================================================

  /// ป้ายกำกับช่องกรอก พร้อมเครื่องหมาย * หรือข้อความ "ไม่บังคับ"
  Widget _label(
    String text, {
    bool required = false,
    bool optional = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Text.rich(
        TextSpan(
          text: text,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
          children: [
            if (required)
              const TextSpan(
                text: '  *',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (optional)
              const TextSpan(
                text: '  (ไม่บังคับ)',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.normal,
                  fontSize: 12,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// หัวข้อกลุ่มข้อมูล พร้อมไอคอนในกรอบโค้งมน
  Widget _sectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(
            icon,
            size: 19,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  /// ส่วนหัวของหน้า: โลโก้ไอคอนไล่สี + ชื่อ + คำอธิบาย
  Widget _buildHeader() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryContainer.withValues(alpha: 0.7),
              ),
            ),
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.person_add_alt_1_rounded,
                size: 42,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const Text(
          'สร้างบัญชี DormEasy',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'กรอกข้อมูลสำหรับสมัครสมาชิก\nเพื่อเริ่มต้นใช้งานหอพักของคุณ',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  /// ปุ่มสมัครสมาชิกแบบไล่สี (กดแล้วเรียก register() เหมือนเดิม)
  Widget _buildSubmitButton() {
    final borderRadius = BorderRadius.circular(16);

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: loading ? null : AppColors.primaryGradient,
          color: loading ? AppColors.primary.withValues(alpha: 0.4) : null,
          borderRadius: borderRadius,
          boxShadow: loading
              ? []
              : [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.30),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: borderRadius,
            onTap: loading ? null : register,
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.how_to_reg_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'สมัครสมาชิก',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('สมัครสมาชิก'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),

              const SizedBox(height: 26),

              // ===== การ์ดฟอร์ม =====
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.cardBorder,
                    width: 1,
                  ),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ---------- ข้อมูลส่วนตัว ----------
                    _sectionTitle(
                      Icons.assignment_ind_outlined,
                      'ข้อมูลส่วนตัว',
                    ),

                    const SizedBox(height: 18),

                    _label('ชื่อ-นามสกุล', required: true),
                    TextField(
                      controller: nameController,
                      enabled: !loading,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        fillColor: AppColors.surfaceTint,
                        hintText: 'กรอกชื่อ-นามสกุล',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),

                    const SizedBox(height: 16),

                    _label('รหัสนักศึกษา', required: true),
                    TextField(
                      controller: studentCodeController,
                      enabled: !loading,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        fillColor: AppColors.surfaceTint,
                        hintText: 'เช่น 6714421017',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                    ),

                    const SizedBox(height: 16),

                    _label('เบอร์โทรศัพท์', optional: true),
                    TextField(
                      controller: phoneController,
                      enabled: !loading,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        fillColor: AppColors.surfaceTint,
                        hintText: 'เช่น 0812345678',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),

                    const SizedBox(height: 22),
                    const Divider(height: 1),
                    const SizedBox(height: 22),

                    // ---------- ข้อมูลบัญชี ----------
                    _sectionTitle(
                      Icons.lock_person_outlined,
                      'ข้อมูลบัญชีผู้ใช้',
                    ),

                    const SizedBox(height: 18),

                    _label('อีเมล', required: true),
                    TextField(
                      controller: emailController,
                      enabled: !loading,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        fillColor: AppColors.surfaceTint,
                        hintText: 'example@email.com',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),

                    const SizedBox(height: 16),

                    _label('รหัสผ่าน', required: true),
                    TextField(
                      controller: passwordController,
                      enabled: !loading,
                      obscureText: obscurePassword,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        fillColor: AppColors.surfaceTint,
                        hintText: 'อย่างน้อย 6 ตัวอักษร',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: loading
                              ? null
                              : () {
                                  setState(() {
                                    obscurePassword = !obscurePassword;
                                  });
                                },
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    _label('ยืนยันรหัสผ่าน', required: true),
                    TextField(
                      controller: confirmPasswordController,
                      enabled: !loading,
                      obscureText: obscureConfirmPassword,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) {
                        if (!loading) {
                          register();
                        }
                      },
                      decoration: InputDecoration(
                        fillColor: AppColors.surfaceTint,
                        hintText: 'กรอกรหัสผ่านอีกครั้ง',
                        prefixIcon: const Icon(Icons.lock_reset_outlined),
                        suffixIcon: IconButton(
                          onPressed: loading
                              ? null
                              : () {
                                  setState(() {
                                    obscureConfirmPassword =
                                        !obscureConfirmPassword;
                                  });
                                },
                          icon: Icon(
                            obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    _buildSubmitButton(),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ===== ลิงก์กลับไปหน้าเข้าสู่ระบบ =====
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'มีบัญชีอยู่แล้ว?',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  TextButton(
                    onPressed: loading
                        ? null
                        : () {
                            Navigator.pop(context);
                          },
                    child: const Text('เข้าสู่ระบบ'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
