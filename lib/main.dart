import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'api_service.dart';
import 'app_theme.dart';
import 'register_page.dart';
import 'room_selection_page.dart';
import 'change_room_page.dart';

Future<void> main() async {
WidgetsFlutterBinding.ensureInitialized();

try {
await ApiService.init();
} catch (e) {
debugPrint('ApiService.init error: $e');
}

runApp(const DormEasyApp());
}

class DormEasyApp extends StatelessWidget {
const DormEasyApp({super.key});

@override
Widget build(BuildContext context) {
return MaterialApp(
debugShowCheckedModeBanner: false,
title: 'DormEasy',
theme: AppTheme.lightTheme,
home: const StartPage(),
);
}
}

// ============================================================
// START PAGE
// ============================================================

class StartPage extends StatefulWidget {
const StartPage({super.key});

@override
State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
bool loading = true;

@override
void initState() {
super.initState();
checkLogin();
}

Future<void> checkLogin() async {
if (ApiService.token == null || ApiService.token!.isEmpty) {
  if (!mounted) return;
  setState(() => loading = false);
  return;
}

try {
  // ใช้ /me เพื่อตรวจ role ก่อน
  // ไม่ใช้ current-room เพราะ admin/staff ไม่มีห้องพัก
  final meResult = await ApiService.me();

  if (!mounted) return;

  if (meResult['success'] != true || meResult['user'] == null) {
    await ApiService.clearToken();
    if (!mounted) return;
    setState(() => loading = false);
    return;
  }

  final user = Map<String, dynamic>.from(meResult['user']);
  final role = user['role']?.toString().toLowerCase().trim();

  if (role == 'admin' || role == 'staff') {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => AdminDashboardPage(user: user),
      ),
    );
    return;
  }

  final roomResult = await ApiService.currentRoom();

  if (!mounted) return;

  final hasRoom =
      roomResult['success'] == true &&
      roomResult['has_room'] == true &&
      roomResult['room'] != null;

  if (hasRoom) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const HomePage(),
      ),
    );
  } else {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const RoomSelectionPage(),
      ),
    );
  }
} catch (e) {
  debugPrint('checkLogin error: $e');

  if (!mounted) return;

  await ApiService.clearToken();

  if (!mounted) return;

  setState(() => loading = false);
}

}

@override
Widget build(BuildContext context) {
if (loading) {
return const Scaffold(
body: Center(
child: CircularProgressIndicator(),
),
);
}

return const LoginPage();

}
}

// ============================================================
// LOGIN PAGE
// ============================================================

class LoginPage extends StatefulWidget {
const LoginPage({super.key});

@override
State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
final emailController = TextEditingController();
final passwordController = TextEditingController();

bool loading = false;
bool obscurePassword = true;

@override
void dispose() {
emailController.dispose();
passwordController.dispose();
super.dispose();
}

Future<void> login() async {
final email = emailController.text.trim();
final password = passwordController.text;

if (email.isEmpty || password.isEmpty) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      const SnackBar(
        content: Text('กรุณากรอกอีเมลและรหัสผ่าน'),
      ),
    );
  return;
}

if (loading) return;

setState(() => loading = true);

try {
  final result = await ApiService.login(
    email: email,
    password: password,
  );

  if (!mounted) return;

  if (result['success'] != true) {
    setState(() => loading = false);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            result['message']?.toString() ?? 'เข้าสู่ระบบไม่สำเร็จ',
          ),
        ),
      );
    return;
  }

  final userData = result['user'];

  if (userData is! Map) {
    setState(() => loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ไม่พบข้อมูลผู้ใช้จาก Server')),
    );
    return;
  }

  final user = Map<String, dynamic>.from(userData);
  final role = user['role']?.toString().toLowerCase().trim();

  debugPrint('LOGIN USER: $user');
  debugPrint('LOGIN ROLE: $role');

  // สำคัญ: ต้องตรวจ role ก่อนเรียก current-room
  // เพราะ admin/staff ไม่มีข้อมูลห้องของนักศึกษา
  if (role == 'admin' || role == 'staff') {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => AdminDashboardPage(user: user),
      ),
    );
    return;
  }

  // นักศึกษาเท่านั้นที่ต้องตรวจห้อง
  final roomResult = await ApiService.currentRoom();

  if (!mounted) return;

  final hasRoom =
      roomResult['success'] == true &&
      roomResult['has_room'] == true &&
      roomResult['room'] != null;

  if (hasRoom) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const HomePage(),
      ),
    );
    return;
  }

  setState(() => loading = false);

  final selected = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => const RoomSelectionPage(),
    ),
  );

  if (!mounted) return;

  if (selected == true) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const HomePage(),
      ),
    );
  }
} catch (e) {
  if (!mounted) return;

  setState(() => loading = false);

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
    );
}

}

Future<void> openRegister() async {
if (loading) return;

final registered = await Navigator.of(context).push<bool>(
  MaterialPageRoute(
    builder: (_) => const RegisterPage(),
  ),
);

if (!mounted) return;

if (registered == true) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      const SnackBar(
        backgroundColor: Colors.green,
        content: Text(
          'สมัครสมาชิกสำเร็จ กรุณาเข้าสู่ระบบ',
        ),
      ),
    );
}

}

@override
Widget build(BuildContext context) {
return Scaffold(
body: SafeArea(
child: Center(
child: SingleChildScrollView(
padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
child: ConstrainedBox(
constraints: const BoxConstraints(
maxWidth: 440,
),
child: Container(
padding: const EdgeInsets.all(28),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(28),
border: Border.all(color: AppColors.cardBorder, width: 1),
boxShadow: AppColors.cardShadow,
),
child: Column(
children: [
Container(
width: 86,
height: 86,
decoration: BoxDecoration(
color: AppColors.primaryContainer,
borderRadius: BorderRadius.circular(24),
),
child: const Icon(
Icons.apartment_rounded,
size: 46,
color: AppColors.primary,
),
),

              const SizedBox(height: 18),

              const Text(
                'DormEasy',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'ระบบจัดการหอพักสำหรับนักศึกษา',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 30),

              TextField(
                controller: emailController,
                enabled: !loading,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'อีเมล',
                  prefixIcon: Icon(
                    Icons.email_outlined,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: passwordController,
                enabled: !loading,
                obscureText: obscurePassword,
                onSubmitted: (_) {
                  if (!loading) {
                    login();
                  }
                },
                decoration: InputDecoration(
                  labelText: 'รหัสผ่าน',
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                  ),
                  suffixIcon: IconButton(
                    onPressed: loading
                        ? null
                        : () {
                            setState(() {
                              obscurePassword =
                                  !obscurePassword;
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

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: loading ? null : login,
                  child: loading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'เข้าสู่ระบบ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: loading ? null : openRegister,
                  icon: const Icon(
                    Icons.person_add_outlined,
                  ),
                  label: const Text(
                    'สมัครสมาชิก',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'บัญชีทดสอบสำหรับเข้าสู่ระบบ',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryDark,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text(
                      'student@dormeasy.com',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'รหัสผ่าน: 123456',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
),
);
}
}

// ============================================================
// ADMIN DASHBOARD
// ============================================================

class AdminDashboardPage extends StatefulWidget {
  final Map<String, dynamic> user;

  const AdminDashboardPage({
    super.key,
    required this.user,
  });

  @override
  State<AdminDashboardPage> createState() =>
      _AdminDashboardPageState();
}

class _AdminDashboardPageState
    extends State<AdminDashboardPage> {
  int selectedIndex = 0;

  Future<void> logout() async {
    try {
      await ApiService.logout();
    } catch (_) {
      await ApiService.clearToken();
    }

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
      (route) => false,
    );
  }

  Future<void> confirmLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ออกจากระบบ'),
        content: const Text('ต้องการออกจากระบบหรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('ออกจากระบบ'),
          ),
        ],
      ),
    );

    if (confirm == true) await logout();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'DormEasy Admin',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'ออกจากระบบ',
            onPressed: confirmLogout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: IndexedStack(
        index: selectedIndex,
        children: [
          AdminOverviewPage(
          user: widget.user,
          onNavigate: (index) {
            if (!mounted) return;
            setState(() {
              selectedIndex = index;
            });
          },
        ),
          const AdminDormitoryPage(),
          const AdminRoomPage(),
          const AdminBillsPage(),
          const AdminPaymentsPage(),
          const AdminRepairsPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() => selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.apartment_outlined),
            selectedIcon: Icon(Icons.apartment),
            label: 'หอพัก',
          ),
          NavigationDestination(
            icon: Icon(Icons.meeting_room_outlined),
            selectedIcon: Icon(Icons.meeting_room),
            label: 'ห้อง',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'บิล',
          ),
          NavigationDestination(
            icon: Icon(Icons.payments_outlined),
            selectedIcon: Icon(Icons.payments),
            label: 'ชำระเงิน',
          ),
          NavigationDestination(
            icon: Icon(Icons.build_outlined),
            selectedIcon: Icon(Icons.build),
            label: 'แจ้งซ่อม',
          ),
        ],
      ),
    );
  }
}

class AdminOverviewPage extends StatelessWidget {
  final Map<String, dynamic> user;
  final ValueChanged<int> onNavigate;

  const AdminOverviewPage({
    super.key,
    required this.user,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Text(
          'สวัสดี ${user['name'] ?? 'Admin'} 👋',
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Role: ${user['role'] ?? '-'}',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 20),
        const Text(
          'ระบบจัดการหอพัก',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _AdminMenuCard(
          icon: Icons.apartment,
          title: 'จัดการหอพัก',
          subtitle: 'ดูหอพักที่มีในระบบ',
          onTap: () => onNavigate(1),
        ),
        _AdminMenuCard(
          icon: Icons.meeting_room,
          title: 'จัดการห้องพัก',
          subtitle: 'ดูห้องว่าง ห้องมีผู้เช่า และข้อมูลราคา',
          onTap: () => onNavigate(2),
        ),
        _AdminMenuCard(
          icon: Icons.receipt_long,
          title: 'บิลของระบบ',
          subtitle: 'ดูรายการบิลจากข้อมูล API',
          onTap: () => onNavigate(3),
        ),
        _AdminMenuCard(
          icon: Icons.payments,
          title: 'การชำระเงิน',
          subtitle: 'ตรวจสอบรายการชำระเงิน',
          onTap: () => onNavigate(4),
        ),
        _AdminMenuCard(
          icon: Icons.build,
          title: 'แจ้งซ่อม',
          subtitle: 'ดูรายการแจ้งซ่อม',
          onTap: () => onNavigate(5),
        ),
      ],
    );
  }
}

class _AdminMenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AdminMenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppColors.textMuted,
        ),
        onTap: onTap,
      ),
    );
  }
}

class AdminDormitoryPage extends StatefulWidget {
  const AdminDormitoryPage({super.key});

  @override
  State<AdminDormitoryPage> createState() =>
      _AdminDormitoryPageState();
}

class _AdminDormitoryPageState
    extends State<AdminDormitoryPage> {
  bool loading = true;
  List<dynamic> dormitories = [];

  @override
  void initState() {
    super.initState();
    loadDormitories();
  }

  Future<void> loadDormitories() async {
    setState(() {
      loading = true;
    });

    try {
      final result =
          await ApiService.adminDormitories();

      if (!mounted) return;

      final data = result['data'];

      setState(() {
        dormitories = data is List ? data : [];
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'โหลดข้อมูลหอพักไม่สำเร็จ: $e',
          ),
        ),
      );
    }
  }

  Future<void> showDormitoryDialog({
    Map<String, dynamic>? dormitory,
  }) async {
    final isEdit = dormitory != null;

    final nameController = TextEditingController(
      text: dormitory?['name']?.toString() ?? '',
    );

    final addressController = TextEditingController(
      text: dormitory?['address']?.toString() ?? '',
    );

    final phoneController = TextEditingController(
      text: dormitory?['phone']?.toString() ?? '',
    );

    final descriptionController =
        TextEditingController(
      text:
          dormitory?['description']?.toString() ?? '',
    );

    String status =
        dormitory?['status']?.toString() ?? 'active';

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                isEdit ? 'แก้ไขหอพัก' : 'เพิ่มหอพัก',
              ),

              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'ชื่อหอพัก',
                        prefixIcon:
                            Icon(Icons.apartment),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: addressController,
                      decoration: const InputDecoration(
                        labelText: 'ที่อยู่',
                        prefixIcon:
                            Icon(Icons.location_on),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: phoneController,
                      keyboardType:
                          TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'เบอร์โทรศัพท์',
                        prefixIcon:
                            Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller:
                          descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'รายละเอียด',
                        prefixIcon:
                            Icon(Icons.description),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      initialValue: status,
                      decoration:
                          const InputDecoration(
                        labelText: 'สถานะ',
                        prefixIcon:
                            Icon(Icons.toggle_on),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'active',
                          child: Text('เปิดใช้งาน'),
                        ),
                        DropdownMenuItem(
                          value: 'inactive',
                          child: Text('ปิดใช้งาน'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;

                        setDialogState(() {
                          status = value;
                        });
                      },
                    ),
                  ],
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('ยกเลิก'),
                ),

                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text
                        .trim()
                        .isEmpty) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                          content:
                              Text('กรุณากรอกชื่อหอพัก'),
                        ),
                      );
                      return;
                    }

                    final data = {
                      'name':
                          nameController.text.trim(),
                      'address':
                          addressController.text.trim(),
                      'phone':
                          phoneController.text.trim(),
                      'description':
                          descriptionController.text
                              .trim(),
                      'status': status,
                    };

                    try {
                      Map<String, dynamic> result;

                      if (isEdit) {
                        final id = int.parse(
                          dormitory!['id'].toString(),
                        );

                        result =
                            await ApiService
                                .adminUpdateDormitory(
                          id,
                          data,
                        );
                      } else {
                        result =
                            await ApiService
                                .adminCreateDormitory(
                          data,
                        );
                      }

                      if (!mounted) return;

Navigator.pop(dialogContext);

if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(
      result['message']?.toString() ??
          'ดำเนินการสำเร็จ',
    ),
  ),
);

await loadDormitories();

                      await loadDormitories();
                    } catch (e) {
                      if (!mounted) return;

                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        SnackBar(
                          content:
                              Text('เกิดข้อผิดพลาด: $e'),
                        ),
                      );
                    }
                  },
                  child: Text(
                    isEdit ? 'บันทึกการแก้ไข' : 'เพิ่มหอพัก',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    addressController.dispose();
    phoneController.dispose();
    descriptionController.dispose();
  }

  Future<void> deleteDormitory(
    int id,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ลบหอพัก'),
          content: const Text(
            'ต้องการลบหอพักนี้ใช่หรือไม่?\n'
            'ถ้าหอพักมีห้องอยู่ ระบบจะไม่อนุญาตให้ลบ',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, false),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(context, true),
              child: const Text('ลบ'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      final result =
          await ApiService.adminDeleteDormitory(id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message']?.toString() ??
                'ดำเนินการสำเร็จ',
          ),
        ),
      );

      await loadDormitories();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('ลบหอพักไม่สำเร็จ: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: loadDormitories,

              child: ListView(
                padding: const EdgeInsets.all(18),

                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'หอพักทั้งหมด',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),

                      ElevatedButton.icon(
                        onPressed: () {
                          showDormitoryDialog();
                        },
                        icon:
                            const Icon(Icons.add),
                        label:
                            const Text('เพิ่ม'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  if (dormitories.isEmpty)
                    const Padding(
                      padding:
                          EdgeInsets.only(top: 100),
                      child: Center(
                        child: Text(
                          'ไม่พบข้อมูลหอพัก',
                        ),
                      ),
                    ),

                  ...dormitories.map((item) {
                    final dorm =
                        Map<String, dynamic>.from(
                      item,
                    );

                    final id = int.tryParse(
                      dorm['id'].toString(),
                    );

                    return Card(
                      margin:
                          const EdgeInsets.only(
                        bottom: 12,
                      ),

                      child: ListTile(
                        contentPadding:
                            const EdgeInsets.all(15),

                        leading:
                            const CircleAvatar(
                          child: Icon(
                            Icons.apartment,
                          ),
                        ),

                        title: Text(
                          dorm['name']
                                  ?.toString() ??
                              '-',
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        subtitle: Text(
                          'ที่อยู่: ${dorm['address'] ?? '-'}\n'
                          'โทร: ${dorm['phone'] ?? '-'}\n'
                          'สถานะ: ${dorm['status'] ?? '-'}',
                        ),

                        isThreeLine: true,

                        trailing:
                            PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              showDormitoryDialog(
                                dormitory: dorm,
                              );
                            }

                            if (value == 'delete' &&
                                id != null) {
                              deleteDormitory(id);
                            }

                            if (value == 'rooms' &&
                                id != null) {
                              Navigator.of(context)
                                  .push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AdminRoomPage(
                                    initialDormitoryId:
                                        id,
                                  ),
                                ),
                              );
                            }
                          },
                          itemBuilder:
                              (context) => const [
                            PopupMenuItem(
                              value: 'rooms',
                              child:
                                  Text('ดูห้องพัก'),
                            ),
                            PopupMenuItem(
                              value: 'edit',
                              child:
                                  Text('แก้ไข'),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child:
                                  Text('ลบ'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}

class AdminRoomPage extends StatefulWidget {
  final int? initialDormitoryId;

  const AdminRoomPage({
    super.key,
    this.initialDormitoryId,
  });

  @override
  State<AdminRoomPage> createState() => _AdminRoomPageState();
}

class _AdminRoomPageState extends State<AdminRoomPage> {
  bool loadingDorms = true;
  bool loadingRooms = false;

  List<dynamic> dormitories = [];
  List<dynamic> rooms = [];

  int? selectedDormitoryId;

  @override
  void initState() {
    super.initState();

    selectedDormitoryId = widget.initialDormitoryId;

    loadDormitories();
  }

  Future<void> loadDormitories() async {
    try {
      final result = await ApiService.dormitories();

      if (!mounted) return;

      final data = result['data'];

      setState(() {
        dormitories = data is List ? data : [];
        loadingDorms = false;
      });

      if (selectedDormitoryId == null && dormitories.isNotEmpty) {
        final first =
            Map<String, dynamic>.from(dormitories.first);

        selectedDormitoryId =
            int.tryParse(first['id'].toString());
      }

      if (selectedDormitoryId != null) {
        await loadRooms(selectedDormitoryId!);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loadingDorms = false;
      });
    }
  }

  Future<void> loadRooms(int dormitoryId) async {
  if (!mounted) return;

  setState(() {
    selectedDormitoryId = dormitoryId;
    loadingRooms = true;
    rooms = [];
  });

  try {
    final result = await ApiService.adminRooms(
      dormitoryId: dormitoryId,
    );

    if (!mounted) return;

    final data = result['rooms'];

    setState(() {
      rooms = data is List ? data : [];
      loadingRooms = false;
    });
  } catch (e) {
    if (!mounted) return;

    setState(() {
      loadingRooms = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'โหลดข้อมูลห้องไม่สำเร็จ: $e',
        ),
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text('จัดการห้อง'),
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: loadingDorms
                ? const LinearProgressIndicator()
                : DropdownButtonFormField<int>(
                    initialValue: selectedDormitoryId,

                    decoration: const InputDecoration(
                      labelText: 'เลือกหอพัก',
                      prefixIcon:
                          Icon(Icons.apartment),
                      border: OutlineInputBorder(),
                    ),

                    items: dormitories.map((item) {
                      final dorm =
                          Map<String, dynamic>.from(item);

                      final id = int.tryParse(
                        dorm['id'].toString(),
                      );

                      return DropdownMenuItem<int>(
                        value: id,
                        child: Text(
                          dorm['name']?.toString() ?? '-',
                        ),
                      );
                    }).toList(),

                    onChanged: (value) {
                      if (value != null) {
                        loadRooms(value);
                      }
                    },
                  ),
          ),

          Expanded(
            child: loadingRooms
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : rooms.isEmpty
                    ? const Center(
                        child: Text(
                          'ไม่พบข้อมูลห้อง',
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                        itemCount: rooms.length,
                        itemBuilder: (context, index) {
                          final room =
                              Map<String, dynamic>.from(
                            rooms[index],
                          );

                          return Card(
                            margin: const EdgeInsets.only(
                              bottom: 12,
                            ),

                            child: ListTile(
                              leading: const CircleAvatar(
                                child: Icon(
                                  Icons.meeting_room,
                                ),
                              ),

                              title: Text(
                                'ห้อง ${room['room_number'] ?? '-'}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              subtitle: Text(
                                'ชั้น ${room['floor'] ?? '-'}\n'
                                'สถานะ: ${room['status'] ?? '-'}',
                              ),

                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class AdminBillsPage extends StatefulWidget {
  const AdminBillsPage({super.key});

  @override
  State<AdminBillsPage> createState() => _AdminBillsPageState();
}

class _AdminBillsPageState extends State<AdminBillsPage> {
  bool loading = true;
  List<dynamic> bills = [];
  List<dynamic> contracts = [];

  @override
  void initState() {
    super.initState();
    loadBills();
  }

  Future<void> loadBills() async {
    setState(() => loading = true);

    try {
      final result = await ApiService.adminBills();

      if (!mounted) return;

      final data = result['bills'];

      setState(() {
        bills = data is List ? data : [];
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('โหลดข้อมูลบิลไม่สำเร็จ: $e'),
        ),
      );
    }
  }

  Future<void> loadContracts() async {
    try {
      final result = await ApiService.adminContracts();

      if (!mounted) return;

      final data = result['contracts'];

      setState(() {
        contracts = data is List ? data : [];
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('โหลดข้อมูลสัญญาไม่สำเร็จ: $e'),
        ),
      );
    }
  }

  Future<void> showBillDialog({
    Map<String, dynamic>? bill,
  }) async {
    await loadContracts();

    if (!mounted) return;

    final isEdit = bill != null;

    int? contractId = isEdit
        ? int.tryParse(bill!['contract_id'].toString())
        : null;

    String billMonth =
        bill?['bill_month']?.toString() ??
        DateTime.now().toString().substring(0, 7);

    String roomRent =
        bill?['room_rent']?.toString() ?? '3000';

    String waterFee =
        bill?['water_fee']?.toString() ?? '100';

    String electricFee =
        bill?['electric_fee']?.toString() ?? '100';

    String otherFee =
        bill?['other_fee']?.toString() ?? '0';

    String dueDate =
        bill?['due_date']?.toString() ??
        DateTime.now()
            .add(const Duration(days: 7))
            .toString()
            .substring(0, 10);

    String status =
        bill?['status']?.toString() ?? 'unpaid';

    final monthController =
        TextEditingController(text: billMonth);

    final rentController =
        TextEditingController(text: roomRent);

    final waterController =
        TextEditingController(text: waterFee);

    final electricController =
        TextEditingController(text: electricFee);

    final otherController =
        TextEditingController(text: otherFee);

    final dueController =
        TextEditingController(text: dueDate);

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                isEdit ? 'แก้ไขบิล' : 'เพิ่มบิล',
              ),

              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isEdit)
                      DropdownButtonFormField<int>(
                        initialValue: contractId,
                        decoration: const InputDecoration(
                          labelText: 'สัญญา',
                          border: OutlineInputBorder(),
                        ),
                        items: contracts.map((item) {
                          final c =
                              Map<String, dynamic>.from(item);

                          final id = int.tryParse(
                            c['id'].toString(),
                          );

                          return DropdownMenuItem<int>(
                            value: id,
                            child: Text(
                              'สัญญา #$id ห้อง ${c['room_number'] ?? '-'}',
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            contractId = value;
                          });
                        },
                      ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: monthController,
                      decoration: const InputDecoration(
                        labelText: 'เดือนบิล เช่น 2026-10',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: rentController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'ค่าเช่า',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: waterController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'ค่าน้ำ',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: electricController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'ค่าไฟ',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: otherController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'ค่าใช้จ่ายอื่น',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: dueController,
                      decoration: const InputDecoration(
                        labelText: 'วันครบกำหนด เช่น 2026-10-05',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      initialValue: status,
                      decoration: const InputDecoration(
                        labelText: 'สถานะ',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'unpaid',
                          child: Text('ยังไม่ชำระ'),
                        ),
                        DropdownMenuItem(
                          value: 'paid',
                          child: Text('ชำระแล้ว'),
                        ),
                        DropdownMenuItem(
                          value: 'overdue',
                          child: Text('เกินกำหนด'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            status = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('ยกเลิก'),
                ),

                ElevatedButton(
                  onPressed: () async {
                    if (monthController.text.isEmpty ||
                        rentController.text.isEmpty ||
                        waterController.text.isEmpty ||
                        electricController.text.isEmpty ||
                        dueController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('กรุณากรอกข้อมูลให้ครบ'),
                        ),
                      );
                      return;
                    }

                    if (!isEdit && contractId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('กรุณาเลือกสัญญา'),
                        ),
                      );
                      return;
                    }

                    final data = {
                      if (!isEdit)
                        'contract_id': contractId,
                      'bill_month': monthController.text.trim(),
                      'room_rent':
                          double.tryParse(rentController.text) ?? 0,
                      'water_fee':
                          double.tryParse(waterController.text) ?? 0,
                      'electric_fee':
                          double.tryParse(electricController.text) ?? 0,
                      'other_fee':
                          double.tryParse(otherController.text) ?? 0,
                      'due_date': dueController.text.trim(),
                      'status': status,
                    };

                    try {
                      Map<String, dynamic> result;

                      if (isEdit) {
                        final id =
                            int.parse(bill!['id'].toString());

                        result =
                            await ApiService.adminUpdateBill(
                          id,
                          data,
                        );
                      } else {
                        result =
                            await ApiService.adminCreateBill(data);
                      }

                      if (!mounted) return;

                      Navigator.pop(dialogContext);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            result['message']?.toString() ??
                                'ดำเนินการสำเร็จ',
                          ),
                        ),
                      );

                      await loadBills();
                    } catch (e) {
                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('เกิดข้อผิดพลาด: $e'),
                        ),
                      );
                    }
                  },
                  child: Text(
                    isEdit ? 'บันทึก' : 'เพิ่มบิล',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    monthController.dispose();
    rentController.dispose();
    waterController.dispose();
    electricController.dispose();
    otherController.dispose();
    dueController.dispose();
  }

  Future<void> deleteBill(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ลบบิล'),
          content: const Text(
            'ต้องการลบบิลนี้ใช่หรือไม่?',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, false),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(context, true),
              child: const Text('ลบ'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      final result =
          await ApiService.adminDeleteBill(id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message']?.toString() ??
                'ลบบิลสำเร็จ',
          ),
        ),
      );

      await loadBills();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ลบบิลไม่สำเร็จ: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: loadBills,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'บิลทั้งหมด',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      ElevatedButton.icon(
                        onPressed: () {
                          showBillDialog();
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('เพิ่มบิล'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  if (bills.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 100),
                      child: Center(
                        child: Text(
                          'ไม่พบข้อมูลบิล',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),

                  ...bills.map((item) {
                    final bill =
                        Map<String, dynamic>.from(item);

                    return Card(
                      margin:
                          const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(
                            Icons.receipt_long,
                          ),
                        ),

                        title: Text(
                          bill['bill_number']
                                  ?.toString() ??
                              '-',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        subtitle: Text(
                          'ห้อง ${bill['room_number'] ?? '-'}\n'
                          'เดือน ${bill['bill_month'] ?? '-'}\n'
                          'ยอด ${bill['total_amount'] ?? 0} บาท\n'
                          'สถานะ: ${bill['status'] ?? '-'}',
                        ),

                        isThreeLine: true,

                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              showBillDialog(
                                bill: bill,
                              );
                            }

                            if (value == 'delete') {
                              deleteBill(
                                int.parse(
                                  bill['id'].toString(),
                                ),
                              );
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'edit',
                              child: Text('แก้ไข'),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('ลบ'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}

class AdminPaymentsPage extends StatefulWidget {
  const AdminPaymentsPage({super.key});

  @override
  State<AdminPaymentsPage> createState() =>
      _AdminPaymentsPageState();
}

class _AdminPaymentsPageState
    extends State<AdminPaymentsPage> {
  bool loading = true;
  List<dynamic> payments = [];

  @override
  void initState() {
    super.initState();
    loadPayments();
  }

  Future<void> loadPayments() async {
    setState(() => loading = true);

    try {
      final result =
          await ApiService.adminPayments();

      if (!mounted) return;

      final data = result['payments'];

      setState(() {
        payments = data is List ? data : [];
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('โหลดข้อมูลการชำระเงินไม่สำเร็จ: $e'),
        ),
      );
    }
  }

  Future<void> changeStatus(
    int id,
    String status,
  ) async {
    try {
      final result =
          await ApiService.adminUpdatePaymentStatus(
        id,
        status,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message']?.toString() ??
                'อัปเดตสถานะสำเร็จ',
          ),
        ),
      );

      await loadPayments();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('อัปเดตสถานะไม่สำเร็จ: $e'),
        ),
      );
    }
  }

  void showStatusDialog(
    Map<String, dynamic> payment,
  ) {
    final id =
        int.parse(payment['id'].toString());

    String status =
        payment['status']?.toString() ??
            'pending';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'จัดการการชำระเงิน',
          ),

          content: DropdownButtonFormField<String>(
            initialValue: status,
            decoration: const InputDecoration(
              labelText: 'สถานะ',
              border: OutlineInputBorder(),
            ),

            items: const [
              DropdownMenuItem(
                value: 'pending',
                child: Text('รอตรวจสอบ'),
              ),
              DropdownMenuItem(
                value: 'approved',
                child: Text('อนุมัติ'),
              ),
              DropdownMenuItem(
                value: 'rejected',
                child: Text('ปฏิเสธ'),
              ),
            ],

            onChanged: (value) {
              if (value == null) return;

              status = value;
            },
          ),

          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext),
              child: const Text('ยกเลิก'),
            ),

            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                await changeStatus(
                  id,
                  status,
                );
              },
              child: const Text('บันทึก'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return RefreshIndicator(
      onRefresh: loadPayments,

      child: ListView(
        padding: const EdgeInsets.all(16),

        children: [
          Text(
            'รายการชำระเงิน ${payments.length} รายการ',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          if (payments.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 100),
              child: Center(
                child: Text(
                  'ไม่พบข้อมูลการชำระเงิน',
                ),
              ),
            ),

          ...payments.map((item) {
            final payment =
                Map<String, dynamic>.from(item);

            return Card(
              margin:
                  const EdgeInsets.only(bottom: 12),

              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.payments),
                ),

                title: Text(
                  '${payment['amount'] ?? 0} บาท',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                subtitle: Text(
                  'บิล: ${payment['bill_number'] ?? '-'}\n'
                  'ห้อง: ${payment['room_number'] ?? '-'}\n'
                  'นักศึกษา: ${payment['student_code'] ?? '-'}\n'
                  'วิธีชำระ: ${payment['payment_method'] ?? '-'}\n'
                  'สถานะ: ${payment['status'] ?? '-'}',
                ),

                isThreeLine: true,

                trailing: IconButton(
                  icon: const Icon(
                    Icons.edit,
                  ),
                  onPressed: () {
                    showStatusDialog(payment);
                  },
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class AdminRepairsPage extends StatefulWidget {
  const AdminRepairsPage({super.key});

  @override
  State<AdminRepairsPage> createState() =>
      _AdminRepairsPageState();
}

class _AdminRepairsPageState
    extends State<AdminRepairsPage> {
  bool loading = true;
  List<dynamic> repairs = [];

  @override
  void initState() {
    super.initState();
    loadRepairs();
  }

  Future<void> loadRepairs() async {
    setState(() => loading = true);

    try {
      final result =
          await ApiService.adminRepairs();

      if (!mounted) return;

      final data = result['repairs'];

      setState(() {
        repairs = data is List ? data : [];
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('โหลดข้อมูลแจ้งซ่อมไม่สำเร็จ: $e'),
        ),
      );
    }
  }

  Future<void> changeStatus(
    int id,
    String status,
  ) async {
    try {
      final result =
          await ApiService.adminUpdateRepairStatus(
        id,
        status,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message']?.toString() ??
                'อัปเดตสถานะสำเร็จ',
          ),
        ),
      );

      await loadRepairs();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('อัปเดตสถานะไม่สำเร็จ: $e'),
        ),
      );
    }
  }

  void showStatusDialog(
    Map<String, dynamic> repair,
  ) {
    final id =
        int.parse(repair['id'].toString());

    String status =
        repair['status']?.toString() ??
            'pending';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'อัปเดตสถานะแจ้งซ่อม',
          ),

          content: DropdownButtonFormField<String>(
            initialValue: status,
            decoration: const InputDecoration(
              labelText: 'สถานะ',
              border: OutlineInputBorder(),
            ),

            items: const [
              DropdownMenuItem(
                value: 'pending',
                child: Text('รอดำเนินการ'),
              ),
              DropdownMenuItem(
                value: 'in_progress',
                child: Text('กำลังดำเนินการ'),
              ),
              DropdownMenuItem(
                value: 'completed',
                child: Text('เสร็จแล้ว'),
              ),
              DropdownMenuItem(
                value: 'cancelled',
                child: Text('ยกเลิก'),
              ),
            ],

            onChanged: (value) {
              if (value == null) return;

              status = value;
            },
          ),

          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext),
              child: const Text('ยกเลิก'),
            ),

            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                await changeStatus(
                  id,
                  status,
                );
              },
              child: const Text('บันทึก'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return RefreshIndicator(
      onRefresh: loadRepairs,

      child: ListView(
        padding: const EdgeInsets.all(16),

        children: [
          Text(
            'รายการแจ้งซ่อม ${repairs.length} รายการ',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          if (repairs.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 100),
              child: Center(
                child: Text(
                  'ไม่พบรายการแจ้งซ่อม',
                ),
              ),
            ),

          ...repairs.map((item) {
            final repair =
                Map<String, dynamic>.from(item);

            return Card(
              margin:
                  const EdgeInsets.only(bottom: 12),

              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.build),
                ),

                title: Text(
                  repair['title']?.toString() ??
                      '-',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                subtitle: Text(
                  'ห้อง: ${repair['room_number'] ?? '-'}\n'
                  'นักศึกษา: ${repair['student_code'] ?? '-'}\n'
                  'รายละเอียด: ${repair['description'] ?? '-'}\n'
                  'สถานะ: ${repair['status'] ?? '-'}',
                ),

                isThreeLine: true,

                trailing: IconButton(
                  icon: const Icon(
                    Icons.edit,
                  ),
                  onPressed: () {
                    showStatusDialog(repair);
                  },
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ============================================================
// HOME PAGE
// ============================================================

class HomePage extends StatefulWidget {
const HomePage({super.key});

@override
State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
int currentIndex = 0;

late final List<Widget> pages;

@override
void initState() {
super.initState();

pages = [
  DashboardTab(
    onNavigate: changeTab,
  ),
  const BillTab(),
  const RepairTab(),
  const ProfileTab(),
];

}

void changeTab(int index) {
if (!mounted) return;

setState(() {
  currentIndex = index;
});

}

Future<void> logout() async {
await ApiService.logout();

if (!mounted) return;

Navigator.of(context).pushAndRemoveUntil(
  MaterialPageRoute(
    builder: (_) => const LoginPage(),
  ),
  (route) => false,
);

}

String get title {
switch (currentIndex) {
case 1:
return 'บิลและค่าใช้จ่าย';
case 2:
return 'แจ้งซ่อม';
case 3:
return 'โปรไฟล์';
default:
return 'DormEasy';
}
}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: Text(
title,
style: const TextStyle(
fontWeight: FontWeight.bold,
),
),
),
body: IndexedStack(
index: currentIndex,
children: pages,
),
bottomNavigationBar: NavigationBar(
selectedIndex: currentIndex,
onDestinationSelected: changeTab,
destinations: const [
NavigationDestination(
icon: Icon(Icons.home_outlined),
selectedIcon: Icon(Icons.home),
label: 'หน้าหลัก',
),
NavigationDestination(
icon: Icon(Icons.receipt_long_outlined),
selectedIcon: Icon(Icons.receipt_long),
label: 'บิล',
),
NavigationDestination(
icon: Icon(Icons.build_outlined),
selectedIcon: Icon(Icons.build),
label: 'แจ้งซ่อม',
),
NavigationDestination(
icon: Icon(Icons.person_outline),
selectedIcon: Icon(Icons.person),
label: 'โปรไฟล์',
),
],
),
);
}
}

// ============================================================
// DASHBOARD
// ============================================================

class DashboardTab extends StatefulWidget {
final Function(int) onNavigate;

const DashboardTab({
super.key,
required this.onNavigate,
});

@override
State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
Map<String, dynamic>? room;
Map<String, dynamic>? user;

bool loading = true;

@override
void initState() {
super.initState();
loadData();
}

Future<void> loadData() async {
try {
final results = await Future.wait([
ApiService.currentRoom(),
ApiService.me(),
]);

  if (!mounted) return;

  final roomResult = results[0];
  final meResult = results[1];

  setState(() {
    if (roomResult['success'] == true &&
        roomResult['room'] != null) {
      room = Map<String, dynamic>.from(
        roomResult['room'],
      );
    }

    if (meResult['success'] == true &&
        meResult['user'] != null) {
      user = Map<String, dynamic>.from(
        meResult['user'],
      );
    }

    loading = false;
  });
} catch (e) {
  debugPrint('Dashboard error: $e');

  if (!mounted) return;

  setState(() {
    loading = false;
  });
}

}

@override
Widget build(BuildContext context) {
if (loading) {
return const Center(
child: CircularProgressIndicator(),
);
}

final userName =
    user?['name']?.toString() ?? 'นักศึกษา';

final roomNumber =
    room?['room_number']?.toString() ?? '-';

final dormName =
    room?['dormitory_name']?.toString() ?? '-';

final rent =
    room?['monthly_rent']?.toString() ?? '0';

return RefreshIndicator(
  onRefresh: loadData,
  child: ListView(
    padding: const EdgeInsets.all(18),
    children: [
      Text(
        'สวัสดี 👋',
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 16,
        ),
      ),

      const SizedBox(height: 4),

      Text(
        userName,
        style: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
        ),
      ),

      const SizedBox(height: 20),

      Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.22),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ห้องพักของฉัน',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'ใช้งานอยู่',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              'ห้อง $roomNumber',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              dormName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                const Icon(
                  Icons.payments_outlined,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '$rent บาท/เดือน',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          const ChangeRoomPage(),
                    ),
                  );

                  if (!mounted) return;

                  await loadData();
                },
                icon: const Icon(
                  Icons.swap_horiz,
                  size: 20,
                ),
                label: const Text(
                  'เปลี่ยนห้องพัก',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
       

      const SizedBox(height: 24),

      const Text(
        'เมนูหลัก',
        style: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),

      const SizedBox(height: 14),

      Row(
        children: [
          Expanded(
            child: _MenuCard(
              icon: Icons.receipt_long,
              title: 'บิล',
              subtitle: 'ดูค่าใช้จ่าย',
              color: AppColors.warning,
              onTap: () {
                widget.onNavigate(1);
              },
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _MenuCard(
              icon: Icons.build_rounded,
              title: 'แจ้งซ่อม',
              subtitle: 'แจ้งปัญหา',
              color: AppColors.error,
              onTap: () {
                widget.onNavigate(2);
              },
            ),
          ),
        ],
      ),

      const SizedBox(height: 14),

      Row(
        children: [
          Expanded(
            child: _MenuCard(
              icon: Icons.history_rounded,
              title: 'ประวัติ',
              subtitle: 'รายการที่ผ่านมา',
              color: AppColors.success,
              onTap: () {
                widget.onNavigate(1);
              },
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _MenuCard(
              icon: Icons.person_rounded,
              title: 'โปรไฟล์',
              subtitle: 'ข้อมูลของฉัน',
              color: AppColors.primary,
              onTap: () {
                widget.onNavigate(3);
              },
            ),
          ),
        ],
      ),

      const SizedBox(height: 24),

      Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.cardBorder, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'ข้อมูลห้องพัก',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),

              const Divider(height: 24),

              _InfoRow(
                label: 'ห้อง',
                value: roomNumber,
              ),

              _InfoRow(
                label: 'ประเภทห้อง',
                value:
                    room?['room_type_name']?.toString() ?? '-',
              ),

              _InfoRow(
                label: 'ชั้น',
                value: room?['floor']?.toString() ?? '-',
              ),

              _InfoRow(
                label: 'ค่าน้ำ',
                value:
                    '${room?['water_rate'] ?? '-'} บาท/หน่วย',
              ),

              _InfoRow(
                label: 'ค่าไฟ',
                value:
                    '${room?['electric_rate'] ?? '-'} บาท/หน่วย',
              ),
            ],
          ),
        ),
      ),
    ],
  ),
);

}
}

// ============================================================
// MENU CARD
// ============================================================

class _MenuCard extends StatelessWidget {
final IconData icon;
final String title;
final String subtitle;
final Color color;
final VoidCallback onTap;

const _MenuCard({
required this.icon,
required this.title,
required this.subtitle,
required this.color,
required this.onTap,
});

@override
Widget build(BuildContext context) {
return InkWell(
onTap: onTap,
borderRadius: BorderRadius.circular(20),
child: Container(
padding: const EdgeInsets.all(18),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(20),
border: Border.all(color: AppColors.cardBorder, width: 1),
boxShadow: AppColors.cardShadow,
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Container(
width: 44,
height: 44,
decoration: BoxDecoration(
color: color.withValues(alpha: 0.12),
borderRadius: BorderRadius.circular(14),
),
child: Icon(
icon,
color: color,
size: 22,
),
),

        const SizedBox(height: 14),

        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
      ],
    ),
  ),
);

}
}

// ============================================================
// INFO ROW
// ============================================================

class _InfoRow extends StatelessWidget {
final String label;
final String value;

const _InfoRow({
required this.label,
required this.value,
});

@override
Widget build(BuildContext context) {
return Padding(
padding: const EdgeInsets.only(bottom: 12),
child: Row(
children: [
Text(
label,
style: const TextStyle(
color: AppColors.textSecondary,
fontSize: 14,
),
),
const Spacer(),
Flexible(
child: Text(
value,
textAlign: TextAlign.right,
style: const TextStyle(
fontWeight: FontWeight.w600,
color: AppColors.textPrimary,
fontSize: 14,
),
),
),
],
),
);
}
}

// ============================================================
// BILL TAB
// ============================================================

class BillTab extends StatefulWidget {
const BillTab({super.key});

@override
State<BillTab> createState() => _BillTabState();
}

class _BillTabState extends State<BillTab> {
List<dynamic> bills = [];
bool loading = true;

@override
void initState() {
super.initState();
loadBills();
}

Future<void> loadBills() async {
if (mounted) {
setState(() {
loading = true;
});
}

try {
  final result = await ApiService.bills();

  if (!mounted) return;

  if (result['success'] == true) {
    setState(() {
      bills = List<dynamic>.from(
        result['bills'] ?? [],
      );
      loading = false;
    });
  } else {
    setState(() {
      loading = false;
    });
  }
} catch (e) {
  debugPrint('loadBills error: $e');

  if (!mounted) return;

  setState(() {
    loading = false;
  });
}

}

Color getStatusColor(String status) {
return AppColors.getStatusColor(status);
}

String getStatusText(String status) {
switch (status) {
case 'paid':
return 'ชำระแล้ว';
case 'unpaid':
return 'ยังไม่ชำระ';
case 'pending':
return 'รอตรวจสอบ';
default:
return status;
}
}

@override
Widget build(BuildContext context) {
if (loading) {
return const Center(
child: CircularProgressIndicator(),
);
}

if (bills.isEmpty) {
  return RefreshIndicator(
    onRefresh: loadBills,
    child: ListView(
      children: const [
        SizedBox(height: 180),
        Center(
          child: Column(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 56,
                color: AppColors.textMuted,
              ),
              SizedBox(height: 12),
              Text(
                'ยังไม่มีข้อมูลบิล',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

return RefreshIndicator(
  onRefresh: loadBills,
  child: ListView(
    padding: const EdgeInsets.all(18),
    children: [
      const Text(
        'รายการค่าใช้จ่าย',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),

      const SizedBox(height: 14),

      ...bills.map(
        (item) {
          final bill =
              Map<String, dynamic>.from(item);

          final status =
              bill['status']?.toString() ?? '';

          final total =
              bill['total_amount']?.toString() ?? '0';

          return Container(
            margin: const EdgeInsets.only(
              bottom: 14,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cardBorder, width: 1),
              boxShadow: AppColors.cardShadow,
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.receipt_long_rounded,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              bill['bill_number']
                                      ?.toString() ??
                                  'บิล',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'ห้อง ${bill['room_number'] ?? '-'}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),

                      MinimalStatusBadge.fromStatus(status),
                    ],
                  ),

                  const Divider(height: 24),

                  _InfoRow(
                    label: 'ค่าเช่าห้อง',
                    value:
                        '${bill['room_rent'] ?? 0} บาท',
                  ),

                  _InfoRow(
                    label: 'ค่าน้ำ',
                    value:
                        '${bill['water_fee'] ?? 0} บาท',
                  ),

                  _InfoRow(
                    label: 'ค่าไฟ',
                    value:
                        '${bill['electric_fee'] ?? 0} บาท',
                  ),

                  _InfoRow(
                    label: 'ค่าใช้จ่ายอื่น',
                    value:
                        '${bill['other_fee'] ?? 0} บาท',
                  ),

                  const Divider(),

                  Row(
                    children: [
                      const Text(
                        'รวมทั้งหมด',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$total บาท',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),

                  if (status == 'unpaid') ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PaymentPage(
                                bill: bill,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.payment_rounded, size: 20),
                        label: const Text('ชำระเงิน'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    ],
  ),
);

}
}

// ============================================================
// PAYMENT PAGE
// ============================================================

class PaymentPage extends StatefulWidget {
final Map<String, dynamic> bill;

const PaymentPage({
super.key,
required this.bill,
});

@override
State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
final ImagePicker picker = ImagePicker();

File? slipImage;

String paymentMethod = 'transfer';

bool submitting = false;

Future<void> pickSlip() async {
final image = await picker.pickImage(
source: ImageSource.gallery,
);

if (image == null) return;

if (!mounted) return;

setState(() {
  slipImage = File(image.path);
});

}

Future<void> submitPayment() async {
final billId = int.tryParse(
widget.bill['id']?.toString() ?? '',
);

final amount = double.tryParse(
  widget.bill['total_amount']?.toString() ?? '0',
);

if (billId == null || amount == null) {
  return;
}

if (paymentMethod == 'transfer' &&
    slipImage == null) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      const SnackBar(
        content: Text(
          'กรุณาแนบสลิปการโอนเงิน',
        ),
      ),
    );

  return;
}

if (submitting) return;

setState(() {
  submitting = true;
});

try {
  final result =
      await ApiService.createPayment(
    billId: billId,
    amount: amount,
    paymentMethod: paymentMethod,
    slipImage: slipImage,
  );

  if (!mounted) return;

  if (result['success'] == true) {
    setState(() {
      submitting = false;
    });

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.check_circle_rounded,
            color: AppColors.success,
            size: 60,
          ),
          title: const Text(
            'ส่งข้อมูลสำเร็จ',
          ),
          content: const Text(
            'ระบบได้รับข้อมูลการชำระเงินแล้ว\n'
            'กรุณารอเจ้าหน้าที่ตรวจสอบ',
            textAlign: TextAlign.center,
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text('ตกลง'),
              ),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    Navigator.pop(context);
  } else {
    setState(() {
      submitting = false;
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            result['message']?.toString() ??
                'ไม่สามารถชำระเงินได้',
          ),
        ),
      );
  }
} catch (e) {
  if (!mounted) return;

  setState(() {
    submitting = false;
  });

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          'เกิดข้อผิดพลาด: $e',
        ),
      ),
    );
}

}

@override
Widget build(BuildContext context) {
final total =
widget.bill['total_amount']?.toString() ?? '0';

return Scaffold(
  appBar: AppBar(
    title: const Text('ชำระเงิน'),
  ),
  body: ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cardBorder, width: 1),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          children: [
            const Text(
              'ยอดที่ต้องชำระ',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$total บาท',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),

      const SizedBox(height: 24),

      const Text(
        'วิธีชำระเงิน',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),

      RadioGroup<String>(
        groupValue: paymentMethod,
        onChanged: (value) {
          if (submitting || value == null) return;
          setState(() {
            paymentMethod = value;
          });
        },
        child: Column(
          children: const [
            RadioListTile<String>(
              value: 'transfer',
              title: Text('โอนเงิน'),
            ),
            RadioListTile<String>(
              value: 'cash',
              title: Text('เงินสด'),
            ),
          ],
        ),
      ),

      if (paymentMethod == 'transfer') ...[
        const SizedBox(height: 15),

        OutlinedButton.icon(
          onPressed:
              submitting ? null : pickSlip,
          icon: const Icon(
            Icons.upload_file,
          ),
          label: Text(
            slipImage == null
                ? 'เลือกรูปสลิป'
                : 'เปลี่ยนรูปสลิป',
          ),
        ),

        if (slipImage != null) ...[
          const SizedBox(height: 15),
          ClipRRect(
            borderRadius:
                BorderRadius.circular(15),
            child: Image.file(
              slipImage!,
              height: 220,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ],

      const SizedBox(height: 25),

      SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed:
              submitting ? null : submitPayment,
          child: submitting
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'ยืนยันการชำระเงิน',
                ),
        ),
      ),
    ],
  ),
);

}
}

// ============================================================
// REPAIR TAB
// ============================================================

// ============================================================
// REPAIR TAB
// ============================================================

class RepairTab extends StatefulWidget {
  const RepairTab({super.key});

  @override
  State<RepairTab> createState() => _RepairTabState();
}

class _RepairTabState extends State<RepairTab> {
  List<dynamic> repairs = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadRepairs();
  }

  // ============================================================
  // LOAD REPAIRS
  // ============================================================

  Future<void> loadRepairs() async {
    if (!mounted) return;

    setState(() {
      loading = true;
    });

    try {
      final result = await ApiService.repairs();

      if (!mounted) return;

      if (result['success'] == true) {
        final data = result['repairs'];

        setState(() {
          repairs = data is List ? data : [];
          loading = false;
        });
      } else {
        setState(() {
          repairs = [];
          loading = false;
        });
      }
    } catch (e) {
      debugPrint(
        'loadRepairs error: $e',
      );

      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'โหลดรายการแจ้งซ่อมไม่สำเร็จ: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // STATUS COLOR
  // ============================================================

  Color getStatusColor(String status) {
    return AppColors.getStatusColor(status);
  }

  // ============================================================
  // STATUS TEXT
  // ============================================================

  String getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'รอดำเนินการ';

      case 'in_progress':
        return 'กำลังดำเนินการ';

      case 'completed':
        return 'เสร็จแล้ว';

      case 'cancelled':
        return 'ยกเลิก';

      default:
        return status;
    }
  }

  // ============================================================
  // SHOW CREATE REPAIR
  // ============================================================

  Future<void> showCreateRepair() async {
    final messenger =
        ScaffoldMessenger.of(context);

    // ----------------------------------------------------------
    // ตรวจสอบห้องปัจจุบัน
    // ----------------------------------------------------------

    try {
      final roomResult =
          await ApiService.currentRoom();

      if (!mounted) return;

      if (roomResult['success'] != true ||
          roomResult['room'] == null) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'ไม่พบข้อมูลห้องพักของคุณ',
            ),
          ),
        );

        return;
      }

      final room =
          Map<String, dynamic>.from(
        roomResult['room'],
      );

      // --------------------------------------------------------
      // หา room_id
      // --------------------------------------------------------

      final roomId = int.tryParse(
        room['room_id']?.toString() ??
            room['id']?.toString() ??
            '',
      );

      if (roomId == null) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'ไม่พบรหัสห้องพัก',
            ),
          ),
        );

        return;
      }

      // --------------------------------------------------------
      // เปิด Dialog
      // --------------------------------------------------------

      await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return _RepairDialog(
            roomId: roomId,
            roomNumber:
                room['room_number']?.toString() ??
                    '-',
            onSuccess: () async {
              await loadRepairs();
            },
          );
        },
      );

      if (!mounted) return;

      // --------------------------------------------------------
      // ไม่ต้องทำอะไรเพิ่ม
      //
      // _RepairDialog จะจัดการ Controller
      // และส่งผลกลับมาเอง
      // --------------------------------------------------------
    } catch (e) {
      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'เกิดข้อผิดพลาด: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: loadRepairs,
          child: repairs.isEmpty
              ? ListView(
                  physics:
                      const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 180),

                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.build_outlined,
                            size: 60,
                            color: Colors.grey,
                          ),

                          SizedBox(height: 12),

                          Text(
                            'ยังไม่มีรายการแจ้งซ่อม',
                            style: TextStyle(
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : ListView(
                  physics:
                      const AlwaysScrollableScrollPhysics(),
                  padding:
                      const EdgeInsets.all(18),
                  children: [
                    const Text(
                      'รายการแจ้งซ่อม',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 14),

                    ...repairs.map(
                      (item) {
                        final repair =
                            Map<String, dynamic>.from(
                          item,
                        );

                        final status =
                            repair['status']
                                    ?.toString() ??
                                '';

                        final statusColor =
                            getStatusColor(
                          status,
                        );

                        return Container(
                          margin:
                              const EdgeInsets.only(
                            bottom: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.cardBorder,
                              width: 1,
                            ),
                            boxShadow: AppColors.cardShadow,
                          ),
                          child: Padding(
                            padding:
                                const EdgeInsets.all(
                              18,
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                // ------------------------------------------------
                                // Header
                                // ------------------------------------------------

                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration:
                                          BoxDecoration(
                                        color:
                                            statusColor
                                                .withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius:
                                            BorderRadius
                                                .circular(
                                          14,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.build_rounded,
                                        color:
                                            statusColor,
                                        size: 22,
                                      ),
                                    ),

                                    const SizedBox(
                                      width: 12,
                                    ),

                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment
                                                .start,
                                        children: [
                                          Text(
                                            repair['title']
                                                    ?.toString() ??
                                                '-',
                                            style:
                                                const TextStyle(
                                              fontSize:
                                                  16,
                                              fontWeight:
                                                  FontWeight
                                                      .bold,
                                              color: AppColors
                                                  .textPrimary,
                                            ),
                                          ),

                                          const SizedBox(
                                            height: 4,
                                          ),

                                          Text(
                                            'ห้อง ${repair['room_number'] ?? '-'}',
                                            style:
                                                const TextStyle(
                                              color: AppColors
                                                  .textSecondary,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    MinimalStatusBadge.fromStatus(
                                      status,
                                      customLabel:
                                          getStatusText(status),
                                    ),
                                  ],
                                ),

                                const SizedBox(
                                  height: 14,
                                ),

                                // ------------------------------------------------
                                // Description
                                // ------------------------------------------------

                                Container(
                                  width:
                                      double.infinity,
                                  padding:
                                      const EdgeInsets
                                          .all(
                                    14,
                                  ),
                                  decoration:
                                      BoxDecoration(
                                    color: AppColors
                                        .primarySurface,
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                      14,
                                    ),
                                    border: Border.all(
                                      color: AppColors
                                          .cardBorder,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    repair['description']
                                            ?.toString() ??
                                        '-',
                                    style:
                                        const TextStyle(
                                      fontSize: 14,
                                      color: AppColors
                                          .textSecondary,
                                    ),
                                  ),
                                ),

                                // ------------------------------------------------
                                // Date
                                // ------------------------------------------------

                                if (repair['created_at'] !=
                                    null) ...[
                                  const SizedBox(
                                    height: 12,
                                  ),

                                  Row(
                                    children: [
                                      const Icon(
                                        Icons
                                            .access_time_rounded,
                                        size: 15,
                                        color: AppColors
                                            .textMuted,
                                      ),

                                      const SizedBox(
                                        width: 6,
                                      ),

                                      Text(
                                        repair[
                                                    'created_at']
                                                ?.toString() ??
                                            '-',
                                        style:
                                            const TextStyle(
                                          fontSize: 12,
                                          color: AppColors
                                              .textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
        ),

        // ========================================================
        // ปุ่มเพิ่มแจ้งซ่อม
        // ========================================================

        Positioned(
          right: 20,
          bottom: 20,
          child: FloatingActionButton.extended(
            onPressed: showCreateRepair,
            icon: const Icon(
              Icons.add,
            ),
            label: const Text(
              'แจ้งซ่อม',
            ),
          ),
        ),
      ],
    );
  }
}


// ============================================================
// REPAIR DIALOG
// ============================================================

class _RepairDialog extends StatefulWidget {
  final int roomId;
  final String roomNumber;
  final Future<void> Function() onSuccess;

  const _RepairDialog({
    required this.roomId,
    required this.roomNumber,
    required this.onSuccess,
  });

  @override
  State<_RepairDialog> createState() =>
      _RepairDialogState();
}

class _RepairDialogState
    extends State<_RepairDialog> {
  // ==========================================================
  // Controllers
  // ==========================================================

  final titleController =
      TextEditingController();

  final descriptionController =
      TextEditingController();

  bool submitting = false;

  // ==========================================================
  // Dispose
  // ==========================================================

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();

    super.dispose();
  }

  // ==========================================================
  // SUBMIT REPAIR
  // ==========================================================

  Future<void> submitRepair() async {
    if (submitting) return;

    final title =
        titleController.text.trim();

    final description =
        descriptionController.text.trim();

    // --------------------------------------------------------
    // ตรวจสอบหัวข้อ
    // --------------------------------------------------------

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'กรุณากรอกหัวข้อปัญหา',
          ),
        ),
      );

      return;
    }

    // --------------------------------------------------------
    // ตรวจสอบรายละเอียด
    // --------------------------------------------------------

    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'กรุณากรอกรายละเอียดปัญหา',
          ),
        ),
      );

      return;
    }

    // --------------------------------------------------------
    // Loading
    // --------------------------------------------------------

    setState(() {
      submitting = true;
    });

    try {
      final result =
          await ApiService.createRepair(
        roomId: widget.roomId,
        title: title,
        description: description,
      );

      if (!mounted) return;

      // ------------------------------------------------------
      // สำเร็จ
      // ------------------------------------------------------

      if (result['success'] == true) {
        // ปิด Dialog
        Navigator.of(context).pop(true);

        // โหลดรายการใหม่
        await widget.onSuccess();

        return;
      }

      // ------------------------------------------------------
      // API ตอบว่าไม่สำเร็จ
      // ------------------------------------------------------

      setState(() {
        submitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message']?.toString() ??
                'แจ้งซ่อมไม่สำเร็จ',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        submitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'เกิดข้อผิดพลาด: $e',
          ),
        ),
      );
    }
  }

  // ==========================================================
  // BUILD DIALOG
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'แจ้งซ่อม',
        style: TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),

      content: SingleChildScrollView(
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            // --------------------------------------------------
            // ห้อง
            // --------------------------------------------------

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(12),
              margin:
                  const EdgeInsets.only(
                bottom: 16,
              ),
              decoration:
                  BoxDecoration(
                color:
                    AppColors.primaryContainer,
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.meeting_room_rounded,
                    color:
                        AppColors.primaryDark,
                    size: 20,
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  Text(
                    'ห้อง ${widget.roomNumber}',
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
            ),

            // --------------------------------------------------
            // หัวข้อ
            // --------------------------------------------------

            TextField(
              controller:
                  titleController,
              enabled:
                  !submitting,
              textInputAction:
                  TextInputAction.next,
              decoration:
                  InputDecoration(
                labelText:
                    'หัวข้อปัญหา',
                hintText:
                    'เช่น แอร์ไม่เย็น',
                prefixIcon:
                    const Icon(
                  Icons.build,
                ),
                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 14,
            ),

            // --------------------------------------------------
            // รายละเอียด
            // --------------------------------------------------

            TextField(
              controller:
                  descriptionController,
              enabled:
                  !submitting,
              maxLines: 4,
              textInputAction:
                  TextInputAction.newline,
              decoration:
                  InputDecoration(
                labelText:
                    'รายละเอียด',
                hintText:
                    'อธิบายปัญหาที่พบ',
                alignLabelWithHint:
                    true,
                prefixIcon:
                    const Icon(
                  Icons.description,
                ),
                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // ========================================================
      // BUTTONS
      // ========================================================

      actions: [
        // ยกเลิก
        TextButton(
          onPressed: submitting
              ? null
              : () {
                  Navigator.of(
                    context,
                  ).pop(false);
                },
          child: const Text(
            'ยกเลิก',
          ),
        ),

        // ส่งแจ้งซ่อม
        ElevatedButton(
          onPressed: submitting
              ? null
              : submitRepair,
          child: submitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'ส่งแจ้งซ่อม',
                ),
        ),
      ],
    );
  }
}

// ============================================================

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  bool loading = true;
  Map<String, dynamic>? user;
  Map<String, dynamic>? room;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    try {
      final meResult = await ApiService.me();
      final roomResult = await ApiService.currentRoom();

      if (!mounted) return;

      setState(() {
        user = meResult['user'];
        room = roomResult['room'];
        loading = false;
      });
    } catch (e) {
      debugPrint('Profile error: $e');

      if (!mounted) return;

      setState(() {
        loading = false;
      });
    }
  }

  Future<void> logout() async {
    try {
      await ApiService.logout();
    } catch (e) {
      debugPrint('Logout API error: $e');

      // ถึง API จะมีปัญหา
      // ก็ล้าง Token ออกจากเครื่องอยู่ดี
      await ApiService.clearToken();
    }

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const LoginPage(),
      ),
      (route) => false,
    );
  }

  Future<void> confirmLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'ออกจากระบบ',
          ),
          content: const Text(
            'คุณต้องการออกจากระบบใช่หรือไม่?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text(
                'ยกเลิก',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text(
                'ออกจากระบบ',
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 10),
        Center(
          child: Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.cardBorder, width: 2),
            ),
            child: const Icon(
              Icons.person_rounded,
              size: 46,
              color: AppColors.primary,
            ),
          ),
        ),

        const SizedBox(height: 16),

        Center(
          child: Text(
            user?['name']?.toString() ?? '-',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),

        const SizedBox(height: 4),

        Center(
          child: Text(
            user?['email']?.toString() ?? '-',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ),

        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.cardBorder, width: 1),
            boxShadow: AppColors.cardShadow,
          ),
          child: Column(
            children: [
              _InfoRow(
                label: 'ชื่อ',
                value: user?['name']?.toString() ?? '-',
              ),

              _InfoRow(
                label: 'Email',
                value: user?['email']?.toString() ?? '-',
              ),

              _InfoRow(
                label: 'Role',
                value: user?['role']?.toString() ?? 'student',
              ),

              if (room != null) ...[
                const Divider(),

                _InfoRow(
                  label: 'ห้อง',
                  value: room?['room_number']?.toString() ?? '-',
                ),

                _InfoRow(
                  label: 'หอพัก',
                  value: room?['dormitory_name']?.toString() ?? '-',
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: confirmLogout,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: BorderSide(
                color: AppColors.error.withValues(alpha: 0.5),
                width: 1.2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(
              Icons.logout_rounded,
              color: AppColors.error,
              size: 20,
            ),
            label: const Text(
              'ออกจากระบบ',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }
}