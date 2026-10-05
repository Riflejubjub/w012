import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ระบบสีประจำแอปพลิเคชัน DormEasy ตามธีมมินิมอล
/// คู่สีหลัก: #92736C (Rosewood Terracotta) และ #FDF1F5 (Blush Porcelain)
class AppColors {
  // คู่สีหลักตามที่ผู้ใช้กำหนด
  static const Color primary = Color(0xFF92736C);
  static const Color background = Color(0xFFFDF1F5);

  // เฉดสีเสริมของ Primary เพื่อความมีมิติและสวยงาม
  static const Color primaryDark = Color(0xFF755852);
  static const Color primaryLight = Color(0xFFB49892);
  static const Color primaryContainer = Color(0xFFF6E6EA);
  static const Color primarySurface = Color(0xFFFAF0F3);

  // พื้นผิวและขอบ (Surface & Borders)
  static const Color surface = Colors.white;
  static const Color surfaceTint = Color(0xFFFFF8FA);
  static const Color cardBorder = Color(0xFFF0DFE3);
  static const Color divider = Color(0xFFEEDADB);

  // สีตัวอักษรที่อ่านง่าย สบายตา ไม่กระด้าง มองไม่เบื่อ
  static const Color textPrimary = Color(0xFF2C2221);
  static const Color textSecondary = Color(0xFF6E5F5E);
  static const Color textMuted = Color(0xFF9C8F8E);

  // สีสถานะแบบ Soft / Minimalist Palette ที่กลมกลืนกับธีม
  static const Color success = Color(0xFF4C8A66);
  static const Color successContainer = Color(0xFFEAF5EE);

  static const Color warning = Color(0xFFC77844);
  static const Color warningContainer = Color(0xFFFCF2EB);

  static const Color error = Color(0xFFBF4A4A);
  static const Color errorContainer = Color(0xFFFCEEEC);

  static const Color info = Color(0xFF5A7E9F);
  static const Color infoContainer = Color(0xFFECF3F9);

  // เงาละมุนสไตล์มินิมอล (Soft Minimalist Shadows)
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: primary.withValues(alpha: 0.06),
          blurRadius: 18,
          offset: const Offset(0, 5),
        ),
      ];

  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: primary.withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ];

  // Gradient หลักของแอป
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [
      Color(0xFF92736C),
      Color(0xFF785B55),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient subtleCardGradient = LinearGradient(
    colors: [
      Colors.white,
      Color(0xFFFFF9FA),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ตัวช่วยดึงสีสถานะแบบกลมกลืน
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
      case 'completed':
      case 'approved':
      case 'active':
      case 'available':
        return success;
      case 'pending':
      case 'waiting':
        return warning;
      case 'unpaid':
      case 'overdue':
      case 'rejected':
      case 'cancelled':
      case 'occupied':
        return error;
      case 'in_progress':
      case 'processing':
        return info;
      default:
        return textSecondary;
    }
  }

  static Color getStatusContainerColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
      case 'completed':
      case 'approved':
      case 'active':
      case 'available':
        return successContainer;
      case 'pending':
      case 'waiting':
        return warningContainer;
      case 'unpaid':
      case 'overdue':
      case 'rejected':
      case 'cancelled':
      case 'occupied':
        return errorContainer;
      case 'in_progress':
      case 'processing':
        return infoContainer;
      default:
        return primaryContainer;
    }
  }
}

/// ธีมหลักของแอปพลิเคชัน DormEasy
class AppTheme {
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.promptTextTheme();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.primaryDark,
        secondary: AppColors.primaryLight,
        onSecondary: Colors.white,
        secondaryContainer: AppColors.primarySurface,
        onSecondaryContainer: AppColors.primaryDark,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
        onError: Colors.white,
        errorContainer: AppColors.errorContainer,
        onErrorContainer: AppColors.error,
      ),

      // จัดฟอนต์ Prompt ให้สวยงาม อ่านง่าย และมองไม่เบื่อ
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        displayMedium: baseTextTheme.displayMedium?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: baseTextTheme.headlineSmall?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: baseTextTheme.titleSmall?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.normal,
          height: 1.45,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.normal,
          height: 1.45,
        ),
        bodySmall: baseTextTheme.bodySmall?.copyWith(
          color: AppColors.textMuted,
          fontWeight: FontWeight.normal,
        ),
        labelLarge: baseTextTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),

      // แถบ AppBar สไตล์มินิมอล สะอาดตา ไร้เส้นขอบหนา
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.prompt(
          color: AppColors.textPrimary,
          fontSize: 19,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.textPrimary,
          size: 22,
        ),
      ),

      // Card สไตล์มินิมอล ขอบมน พร้อมเส้นขอบบางประณีต
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(
            color: AppColors.cardBorder,
            width: 1,
          ),
        ),
      ),

      // ช่องกรอกข้อมูล (TextField) เรียบหรู สะอาดตา
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: GoogleFonts.prompt(
          color: AppColors.textMuted,
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.prompt(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        prefixIconColor: AppColors.primaryLight,
        suffixIconColor: AppColors.primaryLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.cardBorder,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.cardBorder,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.8,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 1.2,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 1.8,
          ),
        ),
      ),

      // ปุ่มหลัก (ElevatedButton) นุ่มนวล ทันสมัย
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.35),
          disabledForegroundColor: Colors.white70,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.prompt(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ปุ่มเส้นขอบ (OutlinedButton)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          disabledForegroundColor: AppColors.textMuted,
          side: const BorderSide(
            color: AppColors.primary,
            width: 1.4,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.prompt(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ปุ่มตัวอักษร (TextButton)
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.prompt(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // แถบนำทางด้านล่าง (NavigationBar) มินิมอล
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primaryContainer,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.prompt(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            );
          }
          return GoogleFonts.prompt(
            color: AppColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: AppColors.primary,
              size: 24,
            );
          }
          return const IconThemeData(
            color: AppColors.textMuted,
            size: 24,
          );
        }),
      ),

      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),

      // Dialog และ Modal
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.cardBorder, width: 1),
        ),
        titleTextStyle: GoogleFonts.prompt(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: GoogleFonts.prompt(
          color: AppColors.textSecondary,
          fontSize: 15,
          height: 1.45,
        ),
      ),

      // SnackBar แจ้งเตือนสไตล์ลอย มินิมอล
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: GoogleFonts.prompt(
          color: Colors.white,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Divider เส้นคั่นบางเบา
      dividerTheme: const DividerThemeData(
        color: AppColors.cardBorder,
        thickness: 1,
        space: 24,
      ),

      // Checkbox, Radio, Switch
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return Colors.transparent;
        }),
        side: const BorderSide(color: AppColors.cardBorder, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}

/// Widget สำหรับ Badge สถานะแบบมินิมอล สบายตา
class MinimalStatusBadge extends StatelessWidget {
  final String text;
  final Color color;
  final Color backgroundColor;
  final IconData? icon;

  const MinimalStatusBadge({
    super.key,
    required this.text,
    required this.color,
    required this.backgroundColor,
    this.icon,
  });

  factory MinimalStatusBadge.fromStatus(String status, {String? customLabel}) {
    final color = AppColors.getStatusColor(status);
    final bgColor = AppColors.getStatusContainerColor(status);
    String label = customLabel ?? status;

    if (customLabel == null) {
      switch (status.toLowerCase()) {
        case 'paid':
          label = 'ชำระแล้ว';
          break;
        case 'unpaid':
          label = 'ยังไม่ชำระ';
          break;
        case 'pending':
          label = 'รอตรวจสอบ';
          break;
        case 'in_progress':
          label = 'กำลังซ่อม';
          break;
        case 'completed':
          label = 'เสร็จสิ้น';
          break;
        case 'cancelled':
          label = 'ยกเลิก';
          break;
        case 'available':
          label = 'ว่าง';
          break;
        case 'occupied':
          label = 'มีผู้เช่าแล้ว';
          break;
      }
    }

    return MinimalStatusBadge(
      text: label,
      color: color,
      backgroundColor: bgColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: GoogleFonts.prompt(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
