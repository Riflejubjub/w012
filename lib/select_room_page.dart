import 'package:flutter/material.dart';
import 'api_service.dart';

class SelectDormPage extends StatefulWidget {
  const SelectDormPage({super.key});

  @override
  State<SelectDormPage> createState() =>
      _SelectDormPageState();
}

class _SelectDormPageState extends State<SelectDormPage> {
  bool loading = true;
  String? error;
  List<dynamic> dormitories = [];

  @override
  void initState() {
    super.initState();
    loadDormitories();
  }

  Future<void> loadDormitories() async {
  try {
    final result = await ApiService.dormitories();

    if (!mounted) return;

    setState(() {
      dormitories = result['data'] ?? [];
      loading = false;
    });
  } catch (e) {
    if (!mounted) return;

    setState(() {
      loading = false;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('เลือกหอพัก'),
        centerTitle: true,
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      error!,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : dormitories.isEmpty
                  ? const Center(
                      child: Text(
                        'ยังไม่มีข้อมูลหอพัก',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: loadDormitories,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: dormitories.length,
                        itemBuilder: (context, index) {
                          final dorm = dormitories[index];

                          return DormitoryCard(
                            dorm: dorm,
                            onTap: () async {
                              final result =
                                  await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      SelectRoomPage(
                                    dormitoryId: dorm['id'],
                                    dormitoryName:
                                        dorm['name'] ?? '-',
                                    dormitoryAddress:
                                        dorm['address'] ?? '-',
                                  ),
                                ),
                              );

                              if (!mounted) return;

                              if (result == true) {
                                Navigator.pop(
                                  context,
                                  true,
                                );
                              }
                            },
                          );
                        },
                      ),
                    ),
    );
  }
}

class DormitoryCard extends StatelessWidget {
  final dynamic dorm;
  final VoidCallback onTap;

  const DormitoryCard({
    super.key,
    required this.dorm,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius:
                        BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.apartment,
                    color: Colors.blue,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    dorm['name'] ?? '-',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on,
                  color: Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    dorm['address'] ?? '-',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),

            if (dorm['phone'] != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.phone,
                    color: Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    dorm['phone'].toString(),
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: onTap,
                icon: const Icon(
                  Icons.arrow_forward,
                ),
                label: const Text(
                  'ดูห้องพัก',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================
// SELECT ROOM PAGE
// =========================================================

class SelectRoomPage extends StatefulWidget {
  final int dormitoryId;
  final String dormitoryName;
  final String dormitoryAddress;

  const SelectRoomPage({
    super.key,
    required this.dormitoryId,
    required this.dormitoryName,
    required this.dormitoryAddress,
  });

  @override
  State<SelectRoomPage> createState() =>
      _SelectRoomPageState();
}

class _SelectRoomPageState
    extends State<SelectRoomPage> {
  bool loading = true;
  String? error;
  List<dynamic> rooms = [];

  @override
  void initState() {
    super.initState();
    loadRooms();
  }

  Future<void> loadRooms() async {
    try {
      final data = await ApiService.rooms(
        widget.dormitoryId,
      );

      if (!mounted) return;

      setState(() {
        rooms = data['rooms'] ?? [];
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString().replaceFirst(
          'Exception: ',
          '',
        );
        loading = false;
      });
    }
  }

  Future<void> chooseRoom(dynamic room) async {
    final roomNumber =
        room['room_number']?.toString() ?? '-';

    final price =
        room['price']?.toString() ?? '0';

    final roomType =
        room['room_type_name']?.toString() ?? '-';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'ยืนยันการเลือกห้อง',
          ),
          content: Text(
            'ห้อง $roomNumber\n'
            '$roomType\n'
            'ค่าเช่า $price บาท/เดือน\n\n'
            'ต้องการเลือกห้องนี้หรือไม่?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text('ยืนยัน'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    // แสดง Loading
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );
    }

    try {
      final startDate = DateTime.now();

      // ตัวอย่างสัญญา 1 ปี
      final endDate = DateTime(
        startDate.year + 1,
        startDate.month,
        startDate.day,
      );

      String formatDate(DateTime date) {
        return '${date.year.toString().padLeft(4, '0')}-'
            '${date.month.toString().padLeft(2, '0')}-'
            '${date.day.toString().padLeft(2, '0')}';
      }

      await ApiService.selectRoom(
        roomId: room['id'],
        startDate: formatDate(startDate),
        endDate: formatDate(endDate),
      );

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'เลือกห้องพักสำเร็จ 🎉',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(
        context,
        true,
      );
    } catch (e) {
      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );

      loadRooms();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'เลือกห้องพัก',
        ),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : error != null
              ? Center(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(24),
                    child: Text(
                      error!,
                      textAlign:
                          TextAlign.center,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadRooms,
                  child: rooms.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(
                              height: 220,
                            ),
                            Center(
                              child: Text(
                                'ไม่มีห้องว่างในหอพักนี้',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView(
                          padding:
                              const EdgeInsets.all(16),
                          children: [
                            Text(
                              widget.dormitoryName,
                              style: const TextStyle(
                                fontSize: 23,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 5),

                            Text(
                              widget.dormitoryAddress,
                              style: const TextStyle(
                                color: Colors.grey,
                              ),
                            ),

                            const SizedBox(
                              height: 22,
                            ),

                            Text(
                              'ห้องว่าง ${rooms.length} ห้อง',
                              style:
                                  const TextStyle(
                                fontSize: 17,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            const SizedBox(
                              height: 12,
                            ),

                            ...rooms.map(
                              (room) {
                                return RoomCard(
                                  room: room,
                                  onTap: () =>
                                      chooseRoom(
                                    room,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                ),
    );
  }
}

// =========================================================
// ROOM CARD
// =========================================================

class RoomCard extends StatelessWidget {
  final dynamic room;
  final VoidCallback onTap;

  const RoomCard({
    super.key,
    required this.room,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final roomNumber =
        room['room_number']?.toString() ?? '-';

    final floor =
        room['floor']?.toString() ?? '-';

    final price =
        room['price']?.toString() ?? '0';

    final roomType =
        room['room_type_name']?.toString() ?? '-';

    final capacity =
        room['capacity']?.toString() ?? '-';

    return Card(
      margin:
          const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 55,
                  height: 55,
                  decoration:
                      BoxDecoration(
                    color:
                        Colors.green.shade50,
                    borderRadius:
                        BorderRadius.circular(
                      15,
                    ),
                  ),
                  child: const Icon(
                    Icons.meeting_room,
                    color: Colors.green,
                    size: 30,
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
                        ),
                      ),
                      const SizedBox(
                        height: 3,
                      ),
                      Text(
                        roomType,
                        style:
                            const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        Colors.green.shade50,
                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                  ),
                  child: const Text(
                    'ว่าง',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            Row(
              children: [
                const Icon(
                  Icons.layers_outlined,
                  size: 20,
                  color: Colors.grey,
                ),
                const SizedBox(width: 7),
                Text(
                  'ชั้น $floor',
                ),

                const SizedBox(width: 22),

                const Icon(
                  Icons.people_outline,
                  size: 20,
                  color: Colors.grey,
                ),
                const SizedBox(width: 7),
                Text(
                  '$capacity คน',
                ),
              ],
            ),

            const SizedBox(height: 12),

            Text(
              '$price บาท/เดือน',
              style:
                  const TextStyle(
                fontSize: 19,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              height: 47,
              child: ElevatedButton(
                onPressed: onTap,
                child: const Text(
                  'เลือกห้องนี้',
                  style:
                      TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
