import 'package:flutter/material.dart';

import 'api_service.dart';
import 'app_theme.dart';

class RoomSelectionPage extends StatefulWidget {
  const RoomSelectionPage({
    super.key,
  });

  @override
  State<RoomSelectionPage> createState() =>
      _RoomSelectionPageState();
}

class _RoomSelectionPageState
    extends State<RoomSelectionPage> {
  List<dynamic> dormitories = [];
  List<dynamic> rooms = [];

  int? selectedDormitoryId;

  bool loadingDormitories = true;
  bool loadingRooms = false;
  bool selectingRoom = false;

  @override
  void initState() {
    super.initState();
    loadDormitories();
  }

  // ============================================================
  // LOAD DORMITORIES
  // ============================================================

  Future<void> loadDormitories() async {
    if (!mounted) return;

    setState(() {
      loadingDormitories = true;
      rooms = [];
      selectedDormitoryId = null;
    });

    try {
      final result = await ApiService.dormitories();

      if (!mounted) return;

      if (result['success'] == true) {
        // Backend ส่งข้อมูลมาใน key "data"
        final data = result['data'];

        setState(() {
          dormitories =
              data is List ? data : [];
          loadingDormitories = false;
        });

        if (dormitories.isEmpty) {
          showMessage(
            'ไม่พบข้อมูลหอพัก',
          );
        }
      } else {
        setState(() {
          loadingDormitories = false;
        });

        showMessage(
          result['message']?.toString() ??
              'ไม่สามารถโหลดข้อมูลหอพักได้',
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loadingDormitories = false;
      });

      showMessage(
        'เกิดข้อผิดพลาดในการโหลดหอพัก\n$e',
      );
    }
  }

  // ============================================================
  // LOAD ROOMS
  // ============================================================

  Future<void> loadRooms(
    int dormitoryId,
  ) async {
    if (!mounted) return;

    setState(() {
      selectedDormitoryId = dormitoryId;
      loadingRooms = true;
      rooms = [];
    });

    try {
      final result =
          await ApiService.rooms(
        dormitoryId,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        final data = result['rooms'];

        setState(() {
          rooms =
              data is List ? data : [];
          loadingRooms = false;
        });

        if (rooms.isEmpty) {
          showMessage(
            'หอพักนี้ยังไม่มีห้องว่าง',
          );
        }
      } else {
        setState(() {
          loadingRooms = false;
          rooms = [];
        });

        showMessage(
          result['message']?.toString() ??
              'ไม่สามารถโหลดข้อมูลห้องพักได้',
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loadingRooms = false;
        rooms = [];
      });

      showMessage(
        'เกิดข้อผิดพลาดในการโหลดห้องพัก\n$e',
      );
    }
  }

  // ============================================================
  // CONFIRM ROOM
  // ============================================================

  Future<void> confirmRoom(
    Map<String, dynamic> room,
  ) async {
    if (selectingRoom) return;

    final roomId = int.tryParse(
      room['id']?.toString() ?? '',
    );

    if (roomId == null) {
      showMessage(
        'ไม่พบรหัสห้องพัก',
      );
      return;
    }

    final roomNumber =
        room['room_number']?.toString() ??
            '-';

    final roomType =
        room['room_type_name']?.toString() ??
            'ห้องพัก';

    final price =
        room['price']?.toString() ??
            '0';

    final confirm =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(18),
          ),
          title: const Text(
            'ยืนยันการเลือกห้อง',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.meeting_room_rounded,
                color: AppColors.primary,
                size: 65,
              ),
              const SizedBox(height: 15),
              Text(
                'ห้อง $roomNumber',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                roomType,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$price บาท/เดือน',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                'คุณต้องการเลือกห้องนี้ใช่หรือไม่?',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'ยกเลิก',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'ยืนยัน',
              ),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    if (confirm == true) {
      await selectRoom(
        roomId: roomId,
      );
    }
  }

  // ============================================================
  // SELECT ROOM
  // ============================================================

  Future<void> selectRoom({
    required int roomId,
  }) async {
    if (!mounted) return;

    setState(() {
      selectingRoom = true;
    });

    try {
      final now = DateTime.now();

      final startDate =
          '${now.year}-'
          '${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}';

      final end =
          DateTime(
        now.year,
        now.month,
        now.day + 30,
      );

      final endDate =
          '${end.year}-'
          '${end.month.toString().padLeft(2, '0')}-'
          '${end.day.toString().padLeft(2, '0')}';

      final result =
          await ApiService.selectRoom(
        roomId: roomId,
        startDate: startDate,
        endDate: endDate,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          selectingRoom = false;
        });

        final roomNumber =
            result['room_number']?.toString() ??
                '-';

        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            return AlertDialog(
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(18),
              ),
              icon: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 70,
              ),
              title: const Text(
                'เลือกห้องสำเร็จ!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Text(
                'คุณเลือกห้อง $roomNumber '
                'เรียบร้อยแล้ว',
                textAlign: TextAlign.center,
              ),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(
                        dialogContext,
                      );
                    },
                    child: const Text(
                      'เข้าสู่หน้าหลัก',
                    ),
                  ),
                ),
              ],
            );
          },
        );

        if (!mounted) return;

        Navigator.of(context).pop(true);
      } else {
        setState(() {
          selectingRoom = false;
        });

        showMessage(
          result['message']?.toString() ??
              'ไม่สามารถเลือกห้องได้',
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        selectingRoom = false;
      });

      showMessage(
        'เกิดข้อผิดพลาดในการเลือกห้อง\n$e',
      );
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void showMessage(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // INFO ROW
  // ============================================================

  Widget buildInfoRow(
    IconData icon,
    String title,
    String value, {
    bool bold = false,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: AppColors.textMuted,
        ),
        const SizedBox(width: 9),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontWeight: bold
                ? FontWeight.bold
                : FontWeight.w500,
            color: bold
                ? AppColors.primary
                : AppColors.textPrimary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ROOM CARD
  // ============================================================

  Widget buildRoomCard(
    Map<String, dynamic> room,
  ) {
    final roomNumber =
        room['room_number']?.toString() ??
            '-';

    final floor =
        room['floor']?.toString() ?? '-';

    final roomType =
        room['room_type_name']?.toString() ??
            'ห้องพัก';

    final price =
        room['price']?.toString() ??
            '0';

    final capacity =
        room['capacity']?.toString() ??
            '1';

    final waterRate =
        room['water_rate']?.toString() ??
            '0';

    final electricRate =
        room['electric_rate']?.toString() ??
            '0';

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 16,
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
            const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // --------------------------------------------------
            // ROOM HEADER
            // --------------------------------------------------

            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration:
                      BoxDecoration(
                    color:
                        AppColors.primaryContainer,
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                  ),
                  child: const Icon(
                    Icons.meeting_room_rounded,
                    color: AppColors.primary,
                    size: 26,
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ห้อง $roomNumber',
                        style:
                            const TextStyle(
                          fontSize: 20,
                          fontWeight:
                              FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(
                        height: 3,
                      ),
                      Text(
                        '$roomType • ชั้น $floor',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                MinimalStatusBadge.fromStatus(
                  'available',
                  customLabel: 'ว่าง',
                ),
              ],
            ),

            const SizedBox(height: 18),

            const Divider(),

            const SizedBox(height: 10),

            buildInfoRow(
              Icons.payments_outlined,
              'ค่าเช่า',
              '$price บาท/เดือน',
              bold: true,
            ),

            const SizedBox(height: 11),

            buildInfoRow(
              Icons.people_outline,
              'รองรับ',
              '$capacity คน',
            ),

            const SizedBox(height: 11),

            buildInfoRow(
              Icons.water_drop_outlined,
              'ค่าน้ำ',
              '$waterRate บาท/หน่วย',
            ),

            const SizedBox(height: 11),

            buildInfoRow(
              Icons.bolt_outlined,
              'ค่าไฟ',
              '$electricRate บาท/หน่วย',
            ),

            const SizedBox(height: 20),

            // --------------------------------------------------
            // SELECT BUTTON
            // --------------------------------------------------

            SizedBox(
              width: double.infinity,
              height: 50,
              child:
                  ElevatedButton.icon(
                onPressed:
                    selectingRoom
                        ? null
                        : () {
                            confirmRoom(
                              room,
                            );
                          },
                icon: selectingRoom
                    ? const SizedBox(
                        width: 19,
                        height: 19,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons
                            .check_circle_outline,
                      ),
                label: Text(
                  selectingRoom
                      ? 'กำลังเลือกห้อง...'
                      : 'เลือกห้องนี้',
                  style:
                      const TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                style:
                    ElevatedButton.styleFrom(
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'เลือกห้องพัก',
        ),
        centerTitle: true,
      ),

      body: loadingDormitories
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh:
                  loadDormitories,
              child: ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.all(
                  18,
                ),
                children: [
                  // =================================================
                  // TITLE
                  // =================================================

                  const Text(
                    'ยินดีต้อนรับสู่ DormEasy',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 6,
                  ),

                  Text(
                    'เลือกหอพักและห้องที่เหมาะกับคุณ',
                    style: TextStyle(
                      color:
                          Colors.grey.shade600,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(
                    height: 25,
                  ),

                  // =================================================
                  // DORMITORIES
                  // =================================================

                  const Text(
                    '1. เลือกหอพัก',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  if (dormitories.isEmpty)
                    Container(
                      padding:
                          const EdgeInsets.all(
                        25,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            Colors.grey.shade100,
                        borderRadius:
                            BorderRadius.circular(
                          16,
                        ),
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.apartment,
                            size: 50,
                            color: Colors.grey,
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Text(
                            'ไม่พบข้อมูลหอพัก',
                          ),
                        ],
                      ),
                    )
                  else
                    ...dormitories.map(
                      (dorm) {
                        final dormitory =
                            Map<String,
                                    dynamic>.from(
                          dorm,
                        );

                        final id =
                            int.tryParse(
                          dormitory['id']
                                  ?.toString() ??
                              '',
                        );

                        final name =
                            dormitory['name']
                                    ?.toString() ??
                                '-';

                        final address =
                            dormitory['address']
                                    ?.toString() ??
                                '';

                        final isSelected =
                            selectedDormitoryId ==
                                id;

                        return Card(
                          margin:
                              const EdgeInsets
                                  .only(
                            bottom: 10,
                          ),
                          elevation:
                              isSelected
                                  ? 3
                                  : 1,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              16,
                            ),
                            side: isSelected
                                ? const BorderSide(
                                    color:
                                        Colors.blue,
                                    width: 1.5,
                                  )
                                : BorderSide.none,
                          ),
                          child:
                              ListTile(
                            contentPadding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 15,
                              vertical: 5,
                            ),
                            onTap:
                                id == null ||
                                        loadingRooms
                                    ? null
                                    : () {
                                        loadRooms(
                                          id,
                                        );
                                      },
                            leading:
                                CircleAvatar(
                              radius: 25,
                              backgroundColor:
                                  isSelected
                                      ? Colors
                                          .blue
                                      : Colors
                                          .blue
                                          .shade50,
                              child: Icon(
                                Icons.apartment,
                                color:
                                    isSelected
                                        ? Colors
                                            .white
                                        : Colors
                                            .blue,
                              ),
                            ),
                            title:
                                Text(
                              name,
                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight
                                        .bold,
                                fontSize:
                                    16,
                              ),
                            ),
                            subtitle:
                                Text(
                              address,
                            ),
                            trailing:
                                isSelected
                                    ? const Icon(
                                        Icons
                                            .check_circle,
                                        color:
                                            Colors
                                                .green,
                                      )
                                    : const Icon(
                                        Icons
                                            .arrow_forward_ios,
                                        size: 16,
                                      ),
                          ),
                        );
                      },
                    ),

                  // =================================================
                  // ROOMS
                  // =================================================

                  if (selectedDormitoryId !=
                      null) ...[
                    const SizedBox(
                      height: 20,
                    ),

                    const Text(
                      '2. เลือกห้องพัก',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    if (loadingRooms)
                      const Center(
                        child:
                            Padding(
                          padding:
                              EdgeInsets.all(
                            35,
                          ),
                          child:
                              CircularProgressIndicator(),
                        ),
                      )
                    else if (rooms.isEmpty)
                      Container(
                        padding:
                            const EdgeInsets.all(
                          25,
                        ),
                        decoration:
                            BoxDecoration(
                          color:
                              Colors.grey.shade100,
                          borderRadius:
                              BorderRadius.circular(
                            16,
                          ),
                        ),
                        child:
                            const Column(
                          children: [
                            Icon(
                              Icons
                                  .meeting_room_outlined,
                              size: 55,
                              color:
                                  Colors.grey,
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Text(
                              'หอพักนี้ยังไม่มีห้องว่าง',
                              style:
                                  TextStyle(
                                fontSize:
                                    16,
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),
                            SizedBox(
                              height: 5,
                            ),
                            Text(
                              'ลองเลือกหอพักอื่น',
                              style:
                                  TextStyle(
                                color:
                                    Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ...rooms.map(
                        (room) {
                          return buildRoomCard(
                            Map<String,
                                    dynamic>.from(
                              room,
                            ),
                          );
                        },
                      ),
                  ],
                ],
              ),
            ),
    );
  }
}