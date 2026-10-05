import 'package:flutter/material.dart';

import 'api_service.dart';
import 'app_theme.dart';

class ChangeRoomPage extends StatefulWidget {
  const ChangeRoomPage({super.key});

  @override
  State<ChangeRoomPage> createState() => _ChangeRoomPageState();
}

class _ChangeRoomPageState extends State<ChangeRoomPage> {
  bool loading = true;
  bool changing = false;

  Map<String, dynamic>? currentRoom;
  List<dynamic> rooms = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  // ============================================================
  // LOAD CURRENT ROOM + AVAILABLE ROOMS
  // ============================================================

  Future<void> loadData() async {
    if (mounted) {
      setState(() {
        loading = true;
      });
    }

    try {
      // --------------------------------------------------------
      // 1. โหลดห้องปัจจุบัน
      // --------------------------------------------------------

      final currentResult = await ApiService.currentRoom();

      debugPrint('========================================');
      debugPrint('CURRENT ROOM RESULT = $currentResult');
      debugPrint('========================================');

      if (!mounted) return;

      if (currentResult['success'] != true ||
          currentResult['room'] == null) {
        setState(() {
          loading = false;
          currentRoom = null;
          rooms = [];
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentResult['message']?.toString() ??
                  'ไม่พบข้อมูลห้องพักปัจจุบัน',
            ),
          ),
        );

        return;
      }

      currentRoom = Map<String, dynamic>.from(
        currentResult['room'],
      );

      // DEBUG
      debugPrint('CURRENT ROOM = $currentRoom');

      // --------------------------------------------------------
      // 2. หา dormitory_id
      // --------------------------------------------------------

      final dormitoryId = int.tryParse(
        currentRoom?['dormitory_id']?.toString() ?? '',
      );

      // DEBUG
      debugPrint('DORMITORY ID = $dormitoryId');

      if (dormitoryId == null) {
        setState(() {
          loading = false;
          rooms = [];
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'ไม่พบ dormitory_id ของห้องปัจจุบัน',
            ),
          ),
        );

        return;
      }

      // --------------------------------------------------------
      // 3. โหลดห้องทั้งหมดของหอพัก
      // --------------------------------------------------------

      final roomResult = await ApiService.rooms(
        dormitoryId,
      );

      // DEBUG
      debugPrint('========================================');
      debugPrint('ROOM RESULT = $roomResult');
      debugPrint('========================================');

      if (!mounted) return;

      final data = roomResult['rooms'];

      setState(() {
        rooms = data is List ? data : [];
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      debugPrint('CHANGE ROOM ERROR = $e');

      setState(() {
        loading = false;
        rooms = [];
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

  // ============================================================
  // CONFIRM CHANGE ROOM
  // ============================================================

  Future<void> confirmChangeRoom(
    Map<String, dynamic> room,
  ) async {
    final roomId = int.tryParse(
      room['id']?.toString() ?? '',
    );

    if (roomId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'ไม่พบรหัสห้อง',
          ),
        ),
      );

      return;
    }

    final newRoomNumber =
        room['room_number']?.toString() ?? '-';

    final oldRoomNumber =
        currentRoom?['room_number']?.toString() ?? '-';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'ยืนยันการเปลี่ยนห้อง',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'ต้องการเปลี่ยนจากห้อง '
            '$oldRoomNumber ไปห้อง '
            '$newRoomNumber ใช่หรือไม่?',
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
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text(
                'ยืนยัน',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await changeRoom(roomId);
  }

  // ============================================================
  // CHANGE ROOM API
  // ============================================================

  Future<void> changeRoom(int roomId) async {
    if (changing) return;

    setState(() {
      changing = true;
    });

    try {
      debugPrint(
        'CHANGE ROOM => room_id: $roomId',
      );

      final result = await ApiService.changeRoom(
        roomId: roomId,
      );

      debugPrint(
        'CHANGE ROOM RESULT = $result',
      );

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.success,
            content: Text(
              'เปลี่ยนห้องพักสำเร็จ',
            ),
          ),
        );

        // โหลดข้อมูลใหม่
        await loadData();

        if (mounted) {
          setState(() {
            changing = false;
          });
        }
      } else {
        setState(() {
          changing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message']?.toString() ??
                  'เปลี่ยนห้องไม่สำเร็จ',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      debugPrint(
        'CHANGE ROOM ERROR = $e',
      );

      setState(() {
        changing = false;
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

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // ----------------------------------------------------------
    // Current room information
    // ----------------------------------------------------------

    final currentRoomNumber =
        currentRoom?['room_number']?.toString() ?? '-';

    final dormitoryName =
        currentRoom?['dormitory_name']?.toString() ??
            currentRoom?['dormitory']?.toString() ??
            '-';

    // ----------------------------------------------------------
    // Filter available rooms
    // ----------------------------------------------------------

    final availableRooms = rooms.where((item) {
      if (item is! Map) {
        return false;
      }

      final room = Map<String, dynamic>.from(item);

      final status =
          room['status']?.toString().toLowerCase();

      final roomId = int.tryParse(
        room['id']?.toString() ?? '',
      );

      final currentRoomId = int.tryParse(
        currentRoom?['room_id']?.toString() ??
            currentRoom?['id']?.toString() ??
            '',
      );

      // ต้องเป็นห้อง available
      if (status != 'available') {
        return false;
      }

      // ไม่แสดงห้องปัจจุบัน
      if (roomId != null &&
          currentRoomId != null &&
          roomId == currentRoomId) {
        return false;
      }

      return true;
    }).toList();

    // ----------------------------------------------------------
    // UI
    // ----------------------------------------------------------

    return Scaffold(
      backgroundColor: AppColors.background,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        title: const Text(
          'เปลี่ยนห้องพัก',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: RefreshIndicator(
        onRefresh: loadData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(18),
          children: [

            // ==================================================
            // CURRENT ROOM
            // ==================================================

            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius:
                    BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.22),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  const Text(
                    'ห้องพักปัจจุบัน',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'ห้อง $currentRoomNumber',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    dormitoryName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ==================================================
            // TITLE
            // ==================================================

            const Text(
              'เลือกห้องใหม่',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 4),

            const Text(
              'ห้องที่แสดงด้านล่างเป็นห้องที่สามารถย้ายเข้าได้',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 16),

            // ==================================================
            // NO AVAILABLE ROOM
            // ==================================================

            if (availableRooms.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),

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

                child: const Column(
                  children: [

                    Icon(
                      Icons.meeting_room_outlined,
                      size: 56,
                      color: AppColors.textMuted,
                    ),

                    SizedBox(height: 12),

                    Text(
                      'ไม่มีห้องว่างในขณะนี้',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    SizedBox(height: 4),

                    Text(
                      'กรุณาลองใหม่อีกครั้งในภายหลัง',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

            // ==================================================
            // AVAILABLE ROOM LIST
            // ==================================================

            ...availableRooms.map((item) {
              final room =
                  Map<String, dynamic>.from(item);

              final roomNumber =
                  room['room_number']?.toString() ??
                      '-';

              final floor =
                  room['floor']?.toString() ??
                      '-';

              final roomType =
                  room['room_type_name']
                          ?.toString() ??
                      room['room_type']
                          ?.toString() ??
                      '-';

              final price =
                  room['price']?.toString() ??
                      room['monthly_rent']
                          ?.toString() ??
                      '0';

              return Container(
                margin: const EdgeInsets.only(
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
                  padding: const EdgeInsets.all(16),

                  child: Row(
                    children: [

                      // ----------------------------------------
                      // ROOM ICON
                      // ----------------------------------------

                      Container(
                        width: 52,
                        height: 52,

                        decoration: BoxDecoration(
                          color:
                              AppColors.primaryContainer,
                          borderRadius:
                              BorderRadius.circular(16),
                        ),

                        child: const Icon(
                          Icons.meeting_room_rounded,
                          color:
                              AppColors.primary,
                          size: 26,
                        ),
                      ),

                      const SizedBox(width: 14),

                      // ----------------------------------------
                      // ROOM INFORMATION
                      // ----------------------------------------

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,

                          children: [

                            Text(
                              'ห้อง $roomNumber',

                              style:
                                  const TextStyle(
                                fontSize: 17,
                                fontWeight:
                                    FontWeight.bold,
                                color: AppColors
                                    .textPrimary,
                              ),
                            ),

                            const SizedBox(height: 3),

                            Text(
                              'ชั้น $floor • $roomType',

                              style: const TextStyle(
                                color:
                                    AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),

                            const SizedBox(height: 3),

                            Text(
                              '$price บาท/เดือน',

                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                                color: AppColors.primary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // ----------------------------------------
                      // SELECT BUTTON
                      // ----------------------------------------

                      ElevatedButton(
                        onPressed: changing
                            ? null
                            : () =>
                                confirmChangeRoom(
                                  room,
                                ),

                        child: const Text(
                          'เลือก',
                        ),
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