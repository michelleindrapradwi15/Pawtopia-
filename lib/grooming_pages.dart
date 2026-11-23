import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'main.dart';
import 'widgets.dart';
import 'home_page.dart';
import 'profile_page.dart';
import 'produk_pages.dart';

// ---------------------------------------------------------------------------
// Data & helper
// ---------------------------------------------------------------------------

const Color _blue = Color(0xFF2F6FD6);
const Color _line = Color(0xFFF0E6D8);
const Color _grey = Color(0xFF8A8A8A);

class GroomingService {
  final int id;
  final String name;
  final String shortName;
  final int price;
  const GroomingService(this.id, this.name, this.shortName, this.price);
}

/// Daftar layanan. Awalnya berisi data bawaan, lalu diganti dengan data
/// dari services.php saat halaman Grooming dibuka.
List<GroomingService> kServices = [
  const GroomingService(1, 'Grooming Basic', 'Basic', 75000),
  const GroomingService(2, 'Grooming Plus', 'Plus', 100000),
  const GroomingService(3, 'Grooming Spa', 'Spa', 150000),
];

int _userId() => int.tryParse('${Session.user?['id'] ?? 0}') ?? 0;

/// Kirim permintaan ke bookings.php dan selalu mengembalikan Map berisi
/// success dan message, termasuk saat server membalas error.
Future<Map<String, dynamic>> _postBooking(Map<String, dynamic> payload) async {
  try {
    final res = await http.post(
      Uri.parse(apiUrl('bookings.php')),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    try {
      return Map<String, dynamic>.from(jsonDecode(res.body) as Map);
    } catch (_) {
      final isi = res.body.length > 150 ? res.body.substring(0, 150) : res.body;
      return {'success': false, 'message': 'Balasan server tidak dikenali: $isi'};
    }
  } catch (e) {
    return {'success': false, 'message': 'Tidak bisa terhubung ke server'};
  }
}

Future<void> loadServices() async {
  try {
    final res = await http.get(Uri.parse(apiUrl('services.php')));
    final body = jsonDecode(res.body);
    if (body['success'] == true && body['data'] is List) {
      final list = <GroomingService>[];
      for (final r in body['data'] as List) {
        final m = Map<String, dynamic>.from(r as Map);
        final name =
            (m['name'] ?? m['service_name'] ?? m['nama'] ?? '').toString();
        final price = int.tryParse(
                '${m['price'] ?? m['harga'] ?? 0}'.split('.').first) ??
            0;
        final id = int.tryParse('${m['id']}') ?? 0;
        if (name.isEmpty || id == 0) continue;
        list.add(GroomingService(id, name, name.split(' ').last, price));
      }
      if (list.isNotEmpty) kServices = list.take(3).toList();
    }
  } catch (_) {
    // Kalau gagal, tetap pakai data bawaan.
  }
}

class BookingData {
  final GroomingService service;
  final String animal;
  final String petName;
  final DateTime date;
  final String time;
  final String note;
  String payment;
  String bookingId;

  BookingData({
    required this.service,
    required this.animal,
    required this.petName,
    required this.date,
    required this.time,
    required this.note,
    this.payment = 'Transfer Bank',
    this.bookingId = '',
  });

  String get kode {
    String two(int n) => n.toString().padLeft(2, '0');
    final no = bookingId.isEmpty ? '01' : bookingId.padLeft(2, '0');
    return 'PWT-${two(date.day)}${two(date.month)}${two(date.year % 100)}-$no';
  }
}

String ymd(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String rupiah(int v) {
  final s = v.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return 'Rp$buf';
}

const _hariPendek = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
const _hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
const _bulan = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];
const _bulanPendek = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

String tanggalPanjang(DateTime d) =>
    '${_hari[d.weekday - 1]}, ${d.day} ${_bulanPendek[d.month - 1]} ${d.year}';

TextStyle _p(
  double size, {
  FontWeight w = FontWeight.w400,
  Color c = kNavy,
  double h = 1.0,
}) =>
    GoogleFonts.poppins(fontSize: size, fontWeight: w, color: c, height: h);

BoxDecoration _box(
  double s, {
  double r = 22,
  Color fill = Colors.white,
  Color border = _line,
  double bw = 1,
}) =>
    BoxDecoration(
      color: fill,
      borderRadius: BorderRadius.circular(r * s),
      border: Border.all(color: border, width: bw),
    );

void _snack(BuildContext context, String teks) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(teks)));
}

/// Judul + cakar kecil + panah kembali.
/// Judul dibuat tidak menangkap sentuhan dan panah ditaruh paling atas,
/// supaya tombol kembali selalu bisa ditekan.
List<Widget> _topBar(BuildContext context, double s, String title) => [
      bgPaw(s, 347, 66.7, 33, 0.2),
      Positioned(
        top: 68 * s,
        left: 0,
        right: 0,
        child: IgnorePointer(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: _p(18 * s, w: FontWeight.w700),
          ),
        ),
      ),
      Positioned(
        top: 51 * s,
        left: 10 * s,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.pop(context),
          child: Padding(
            padding: EdgeInsets.all(14 * s),
            child: Icon(Icons.arrow_back, size: 20 * s, color: kNavy),
          ),
        ),
      ),
    ];

Widget _label(double s, String text, double centerY, {double size = 14.5}) =>
    Positioned(
      left: 24 * s,
      top: (centerY - size / 2) * s,
      child: Text(text, style: _p(size * s, w: FontWeight.w700)),
    );

class _DashedLine extends StatelessWidget {
  final double s;
  const _DashedLine({required this.s});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final n = (c.maxWidth / (6 * s)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            n,
            (_) => Container(
              width: 3.5 * s,
              height: 1,
              color: const Color(0xFFE6DCCB),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// 1. Halaman Grooming (daftar layanan)
// ---------------------------------------------------------------------------

class GroomingPage extends StatefulWidget {
  const GroomingPage({super.key});

  @override
  State<GroomingPage> createState() => _GroomingPageState();
}

class _GroomingPageState extends State<GroomingPage> {
  int _service = 0;

  @override
  void initState() {
    super.initState();
    loadServices().then((_) {
      if (mounted) setState(() {});
    });
    loadBookings().then((_) {
      if (mounted) setState(() {});
    });
  }

  Widget _tabItem(double s, String label, bool active, VoidCallback onTap,
      {bool badge = false}) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? kNavy : Colors.transparent,
            borderRadius: BorderRadius.circular(18 * s),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: _p(
                  13.5 * s,
                  w: FontWeight.w700,
                  c: active ? Colors.white : kNavy,
                ),
              ),
              if (badge && kMyBookings.any((b) => b.upcoming)) ...[
                SizedBox(width: 7 * s),
                Container(
                  width: 15 * s,
                  height: 15 * s,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE53935),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${kMyBookings.where((b) => b.upcoming).length}',
                    style: _p(9 * s, w: FontWeight.w600, c: Colors.white),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _serviceCard(double s, int i) {
    final sv = kServices[i];
    final selected = _service == i;
    return Positioned(
      left: 24 * s,
      right: 24 * s,
      top: (449 + i * 64.5) * s,
      height: 58 * s,
      child: GestureDetector(
        onTap: () => setState(() => _service = i),
        child: Container(
          decoration: _box(s, r: 16),
          child: Stack(
            children: [
              Positioned(
                left: 19 * s,
                top: 17 * s,
                child: Icon(Icons.adjust, size: 24 * s, color: kNavy),
              ),
              Positioned(
                left: 59 * s,
                top: 14.5 * s,
                child: Text(sv.name, style: _p(13.5 * s, w: FontWeight.w500)),
              ),
              Positioned(
                left: 59 * s,
                top: 35 * s,
                child: Text(rupiah(sv.price), style: _p(12 * s)),
              ),
              Positioned(
                right: 15 * s,
                top: 18 * s,
                child: Container(
                  width: 22 * s,
                  height: 22 * s,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? _blue : Colors.white,
                    border: Border.all(color: _blue, width: 1.8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DesignCanvas(
        builder: (s, h) => Stack(
          children: [
            bgPaw(s, 47.5, 168, 27, -0.3),
            bgPaw(s, 341.5, 435, 33, 0.3),
            bgPaw(s, 37, 724, 22, -0.2),

            // Judul
            Positioned(
              top: 68 * s,
              left: 0,
              right: 0,
              child: Text(
                'Grooming',
                textAlign: TextAlign.center,
                style: _p(18 * s, w: FontWeight.w700),
              ),
            ),

            // Tab Layanan / Jadwal Saya
            Positioned(
              left: 23 * s,
              right: 23 * s,
              top: 99 * s,
              height: 41.5 * s,
              child: Container(
                padding: EdgeInsets.all(3.7 * s),
                decoration: BoxDecoration(
                  color: _line,
                  borderRadius: BorderRadius.circular(21 * s),
                ),
                child: Row(
                  children: [
                    _tabItem(s, 'Layanan', true, () {}),
                    _tabItem(
                      s,
                      'Jadwal Saya',
                      false,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const JadwalBookingPage(),
                        ),
                      ).then((_) => setState(() {})),
                      badge: true,
                    ),
                  ],
                ),
              ),
            ),

            // Subjudul
            Positioned(
              top: 156 * s,
              left: 0,
              right: 0,
              child: Text(
                'Bikin si kecil makin bersih, sehat, dan lucu!',
                textAlign: TextAlign.center,
                style: _p(10 * s),
              ),
            ),

            // Ilustrasi
            Positioned(
              left: 101 * s,
              top: 182 * s,
              width: 197 * s,
              child: Image.asset(
                'assets/images/grooming_illustration.png',
                fit: BoxFit.fitWidth,
                errorBuilder: (_, __, ___) => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'grooming_illustration.png tidak ditemukan',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ),

            // Pilih layanan
            Positioned(
              left: 23 * s,
              top: 420 * s,
              child: Text('Pilih Layanan', style: _p(16 * s, w: FontWeight.w700)),
            ),
            for (int i = 0; i < kServices.length; i++) _serviceCard(s, i),

            // Tombol lanjutkan
            Positioned(
              left: 24 * s,
              right: 24 * s,
              top: 667 * s,
              height: 51 * s,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookingGroomingPage(
                        serviceIndex:
                            _service.clamp(0, kServices.length - 1).toInt(),
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kNavy,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26 * s),
                  ),
                ),
                child: Text(
                  'Lanjutkan',
                  style: _p(15 * s, w: FontWeight.w700, c: Colors.white),
                ),
              ),
            ),

            // Menu bawah
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: PawBottomNav(
                s: s,
                active: 2,
                onTap: (i) {
                  if (i == 0) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const HomePage()),
                    );
                  } else if (i == 1) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const ProdukPage()),
                    );
                  } else if (i == 4) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfilePage()),
                    );
                  } else if (i != 2) {
                    _snack(context, 'Halaman belum tersedia');
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 2. Booking Grooming
// ---------------------------------------------------------------------------

class BookingGroomingPage extends StatefulWidget {
  final int serviceIndex;
  const BookingGroomingPage({super.key, this.serviceIndex = 1});

  @override
  State<BookingGroomingPage> createState() => _BookingGroomingPageState();
}

class _BookingGroomingPageState extends State<BookingGroomingPage> {
  static const _times = [
    '09:00', '10:30', '13:00', '14:30',
    '16:00', '17:30', '19:00', '20:30',
  ];
  static const _disabled = <String>[];

  final _nameCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  late final List<DateTime> _days;
  bool _cat = true;
  late int _service;
  int _date = 1;
  String _time = '13:00';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _days = List.generate(5, (i) => DateTime(now.year, now.month, now.day + i));
    _service = widget.serviceIndex.clamp(0, kServices.length - 1).toInt();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _konfirmasi() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _snack(context, 'Nama hewan wajib diisi');
      return;
    }
    final data = BookingData(
      service: kServices[_service],
      animal: _cat ? 'Kucing' : 'Anjing',
      petName: name,
      date: _days[_date],
      time: _time,
      note: _noteCtrl.text.trim(),
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PaymentPage(data: data)),
    );
  }

  Widget _animalButton(double s, bool cat, double left) {
    final selected = _cat == cat;
    final color = selected ? Colors.white : kNavy;
    return Positioned(
      left: left * s,
      top: 131 * s,
      width: 165 * s,
      height: 49 * s,
      child: GestureDetector(
        onTap: () => setState(() => _cat = cat),
        child: Container(
          decoration: _box(
            s,
            r: 25,
            fill: selected ? kNavy : Colors.white,
            border: selected ? kNavy : _line,
          ),
          child: Row(
            children: [
              SizedBox(width: 20 * s),
              Icon(Icons.adjust, size: 24 * s, color: color),
              SizedBox(width: 13 * s),
              Text(
                cat ? 'Kucing' : 'Anjing',
                style: _p(14.5 * s, w: FontWeight.w700, c: color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _serviceChip(double s, int i) {
    final sv = kServices[i];
    final selected = _service == i;
    final color = selected ? Colors.white : kNavy;
    return Positioned(
      left: (24 + i * 118) * s,
      top: 306 * s,
      width: 106 * s,
      height: 60.7 * s,
      child: GestureDetector(
        onTap: () => setState(() => _service = i),
        child: Container(
          decoration: _box(
            s,
            r: 18,
            fill: selected ? kNavy : Colors.white,
            border: selected ? kNavy : _line,
          ),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 18 * s,
                child: Text(
                  sv.shortName,
                  textAlign: TextAlign.center,
                  style: _p(12 * s, w: FontWeight.w700, c: color),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 37.5 * s,
                child: Text(
                  rupiah(sv.price),
                  textAlign: TextAlign.center,
                  style: _p(11 * s, c: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dateChip(double s, int i) {
    final d = _days[i];
    final selected = _date == i;
    final color = selected ? Colors.white : kNavy;
    return Positioned(
      left: (24 + i * 70) * s,
      top: 408.7 * s,
      width: 62 * s,
      height: 56 * s,
      child: GestureDetector(
        onTap: () => setState(() => _date = i),
        child: Container(
          decoration: _box(
            s,
            r: 15,
            fill: selected ? kNavy : Colors.white,
            border: selected ? kNavy : _line,
          ),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 12.5 * s,
                child: Text(
                  _hariPendek[d.weekday - 1],
                  textAlign: TextAlign.center,
                  style: _p(11 * s, c: color),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 32 * s,
                child: Text(
                  '${d.day}',
                  textAlign: TextAlign.center,
                  style: _p(16 * s, w: FontWeight.w700, c: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _timeChip(double s, int i) {
    final t = _times[i];
    final disabled = _disabled.contains(t);
    final selected = _time == t;
    final row = i ~/ 4;
    final col = i % 4;
    return Positioned(
      left: (24 + col * 87.5) * s,
      top: (503 + row * 42) * s,
      width: 79.5 * s,
      height: 34 * s,
      child: GestureDetector(
        onTap: disabled ? null : () => setState(() => _time = t),
        child: Container(
          alignment: Alignment.center,
          decoration: _box(
            s,
            r: 17,
            fill: selected ? kNavy : Colors.white,
            border: selected ? kNavy : _line,
          ),
          child: Text(
            t,
            style: _p(
              12 * s,
              w: selected ? FontWeight.w700 : FontWeight.w400,
              c: selected
                  ? Colors.white
                  : (disabled ? const Color(0xFFC4C4C4) : kNavy),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sv = kServices[_service];
    final first = _days.first;
    return Scaffold(
      body: DesignCanvas(
        builder: (s, h) => Stack(
          children: [
            ..._topBar(context, s, 'Booking Grooming'),

            // Pilih hewan
            _label(s, 'Pilih Hewan', 118),
            _animalButton(s, true, 24),
            _animalButton(s, false, 201),

            // Nama hewan
            _label(s, 'Nama Hewan', 204.4),
            Positioned(
              left: 24 * s,
              right: 24 * s,
              top: 217.5 * s,
              height: 47.5 * s,
              child: Container(
                decoration: _box(s, r: 24, border: _blue, bw: 1.3),
                child: Row(
                  children: [
                    SizedBox(width: 16 * s),
                    Icon(Icons.adjust, size: 22 * s, color: _blue),
                    SizedBox(width: 14 * s),
                    Expanded(
                      child: TextField(
                        controller: _nameCtrl,
                        style: _p(14 * s),
                        decoration: InputDecoration(
                          isCollapsed: true,
                          border: InputBorder.none,
                          hintText: 'Contoh: Mochi',
                          hintStyle: _p(14 * s, c: _grey),
                        ),
                      ),
                    ),
                    SizedBox(width: 16 * s),
                  ],
                ),
              ),
            ),

            // Pilih layanan
            _label(s, 'Pilih Layanan', 290.7),
            for (int i = 0; i < kServices.length; i++) _serviceChip(s, i),

            // Pilih tanggal
            _label(s, 'Pilih Tanggal', 393),
            Positioned(
              right: 23 * s,
              top: 387.5 * s,
              child: Text(
                '${_bulan[first.month - 1]} ${first.year}',
                style: _p(10.5 * s, c: _grey),
              ),
            ),
            for (int i = 0; i < 5; i++) _dateChip(s, i),

            // Pilih jam
            _label(s, 'Pilih Jam', 487),
            for (int i = 0; i < _times.length; i++) _timeChip(s, i),

            // Catatan
            _label(s, 'Catatan (opsional)', 602),
            Positioned(
              left: 24 * s,
              right: 24 * s,
              top: 616 * s,
              height: 42 * s,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20 * s),
                alignment: Alignment.centerLeft,
                decoration: _box(s, r: 21),
                child: TextField(
                  controller: _noteCtrl,
                  style: _p(12 * s),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: 'Contoh: bulu kusut, takut air...',
                    hintStyle: _p(12 * s, c: _grey),
                  ),
                ),
              ),
            ),

            // Ringkasan
            Positioned(
              left: 24 * s,
              right: 24 * s,
              top: 670 * s,
              height: 60 * s,
              child: Container(
                decoration: _box(s, r: 18),
                child: Stack(
                  children: [
                    Positioned(
                      left: 17 * s,
                      top: 15.5 * s,
                      child: Text(
                        '${sv.name} - ${_cat ? 'Kucing' : 'Anjing'}',
                        style: _p(13 * s, w: FontWeight.w700),
                      ),
                    ),
                    Positioned(
                      left: 17 * s,
                      top: 37.5 * s,
                      child: Text(
                        '${tanggalPanjang(_days[_date])} - $_time',
                        style: _p(10.5 * s, c: _grey),
                      ),
                    ),
                    Positioned(
                      right: 16 * s,
                      top: 28 * s,
                      child: Text(
                        rupiah(sv.price),
                        style: _p(16 * s, w: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Tombol konfirmasi
            Positioned(
              left: 24 * s,
              right: 24 * s,
              top: 744 * s,
              height: 50 * s,
              child: ElevatedButton(
                onPressed: _konfirmasi,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kNavy,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25 * s),
                  ),
                ),
                child: Text(
                  'Konfirmasi Booking',
                  style: _p(15 * s, w: FontWeight.w700, c: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3. Pembayaran
// ---------------------------------------------------------------------------

class PaymentPage extends StatefulWidget {
  final BookingData data;
  const PaymentPage({super.key, required this.data});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  static const _methods = [
    'Transfer Bank',
    'QRIS',
    'E-Wallet (DANA, OVO, GoPay)',
    'Bayar di Salon',
  ];
  static const _subs = ['BCA, BNI, Mandiri, dll', 'Scan & Bayar', '', 'Bayar saat datang'];
  // posisi tengah (relatif ke kartu): judul, subjudul, radio
  static const _titleY = [26.5, 87.0, 147.0, 207.4];
  static const _subY = [47.0, 108.0, 0.0, 228.0];
  static const _radioY = [33.7, 94.0, 154.4, 214.0];

  int _method = 0;
  bool _loading = false;

  Future<void> _bayar() async {
    final d = widget.data;
    final uid = _userId();
    if (uid == 0) {
      _snack(context, 'Silakan login dulu');
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await http.post(
        Uri.parse(apiUrl('bookings.php')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': uid,
          'service_id': d.service.id,
          'booking_date': ymd(d.date),
          'booking_time': d.time,
          'animal_type': d.animal,
          'pet_name': d.petName,
          'notes': d.note,
          'payment_method': _methods[_method],
        }),
      );
      final data = jsonDecode(res.body);
      if (!mounted) return;
      if (data['success'] == true) {
        d.payment = _methods[_method];
        d.bookingId = '${data['data']['booking_id']}';
        kMyBookings.insert(0, MyBooking.fromData(d));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => BookingSuccessPage(data: d)),
        );
      } else {
        _snack(context, data['message'] ?? 'Booking gagal');
      }
    } catch (e) {
      if (!mounted) return;
      _snack(context, 'Tidak bisa terhubung ke server');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _methodRow(double s, int i) {
    final selected = _method == i;
    return Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: (_radioY[i] - 30) * s,
          height: 60 * s,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _method = i),
            child: const SizedBox.expand(),
          ),
        ),
        Positioned(
          left: 0,
          top: (_radioY[i] - 11) * s,
          child: IgnorePointer(
            child: Container(
              width: 22 * s,
              height: 22 * s,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? _blue : Colors.white,
                border: Border.all(color: _blue, width: 1.8),
              ),
            ),
          ),
        ),
        Positioned(
          left: 21.3 * s,
          top: (_radioY[i] - 12) * s,
          child: IgnorePointer(
            child: Icon(Icons.adjust, size: 24 * s, color: kNavy),
          ),
        ),
        Positioned(
          left: 60 * s,
          top: (_titleY[i] - 6.5) * s,
          child: IgnorePointer(
            child: Text(_methods[i], style: _p(13 * s, w: FontWeight.w500)),
          ),
        ),
        if (_subs[i].isNotEmpty)
          Positioned(
            left: 60 * s,
            top: (_subY[i] - 5) * s,
            child: IgnorePointer(
              child: Text(_subs[i], style: _p(9.5 * s, c: _grey)),
            ),
          ),
      ],
    );
  }

  Widget _priceRow(double s, String label, String value, double centerY,
      {Color? valueColor}) {
    return Stack(
      children: [
        Positioned(
          left: 20 * s,
          top: (centerY - 6.5) * s,
          child: Text(label, style: _p(12.5 * s, c: _grey)),
        ),
        Positioned(
          right: 19.5 * s,
          top: (centerY - 6.5) * s,
          child: Text(value, style: _p(12.5 * s, c: valueColor ?? kNavy)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return Scaffold(
      body: DesignCanvas(
        builder: (s, h) => Stack(
          children: [
            ..._topBar(context, s, 'Pembayaran'),
            bgPaw(s, 191, 690, 22, 0.1),

            // Ringkasan booking
            _label(s, 'Ringkasan Booking', 120, size: 15),
            Positioned(
              left: 24 * s,
              right: 24 * s,
              top: 137 * s,
              height: 101 * s,
              child: Container(
                decoration: _box(s, r: 22),
                child: Stack(
                  children: [
                    Positioned(
                      left: 16 * s,
                      top: 16 * s,
                      width: 64.5 * s,
                      height: 65 * s,
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1E3C8),
                          borderRadius: BorderRadius.circular(14 * s),
                        ),
                        child: PawLogo(
                          width: 44 * s,
                          color: const Color(0xFFE3CCA3),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 96.8 * s,
                      top: 24 * s,
                      child: Text(
                        d.service.name,
                        style: _p(14 * s, w: FontWeight.w700),
                      ),
                    ),
                    Positioned(
                      right: 19.5 * s,
                      top: 23.5 * s,
                      child: Text(
                        rupiah(d.service.price),
                        style: _p(13.5 * s, w: FontWeight.w700),
                      ),
                    ),
                    Positioned(
                      left: 96.8 * s,
                      top: 46 * s,
                      child: Text(
                        '${d.animal} - ${d.petName}',
                        style: _p(11.5 * s, c: _grey),
                      ),
                    ),
                    Positioned(
                      left: 96.8 * s,
                      top: 66.5 * s,
                      child: Text(
                        '${tanggalPanjang(d.date)} - ${d.time} WIB',
                        style: _p(10.5 * s),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Metode pembayaran
            _label(s, 'Metode Pembayaran', 269, size: 15),
            Positioned(
              left: 24 * s,
              right: 24 * s,
              top: 286 * s,
              height: 245 * s,
              child: Container(
                decoration: _box(s, r: 22),
                child: Stack(
                  children: [
                    for (int i = 0; i < 4; i++) _methodRow(s, i),
                    Positioned(
                      right: 15 * s,
                      top: 14 * s,
                      width: 81.5 * s,
                      height: 21 * s,
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD6E4FB),
                          borderRadius: BorderRadius.circular(11 * s),
                        ),
                        child: Text(
                          'Rekomendasi',
                          style: _p(9.5 * s, w: FontWeight.w500),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Rincian harga
            Positioned(
              left: 24 * s,
              right: 24 * s,
              top: 550 * s,
              height: 126 * s,
              child: Container(
                decoration: _box(s, r: 22),
                child: Stack(
                  children: [
                    _priceRow(s, 'Harga Layanan', rupiah(d.service.price), 28.7),
                    _priceRow(
                      s,
                      'Biaya Admin',
                      'Gratis',
                      55,
                      valueColor: const Color(0xFF3C9B5C),
                    ),
                    Positioned(
                      left: 20 * s,
                      right: 19.5 * s,
                      top: 75 * s,
                      height: 1,
                      child: Container(color: const Color(0xFFEDE3D3)),
                    ),
                    Positioned(
                      left: 20 * s,
                      top: 95 * s,
                      child: Text('Total', style: _p(14.5 * s, w: FontWeight.w700)),
                    ),
                    Positioned(
                      right: 19.5 * s,
                      top: 94 * s,
                      child: Text(
                        rupiah(d.service.price),
                        style: _p(16 * s, w: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bar bawah
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 143.4 * s,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(28 * s)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0x14000000),
                      blurRadius: 14 * s,
                      offset: Offset(0, -2 * s),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: 24 * s,
                      top: 29 * s,
                      child: Text(
                        'Total Pembayaran',
                        style: _p(10.5 * s, c: _grey),
                      ),
                    ),
                    Positioned(
                      left: 24 * s,
                      top: 50.5 * s,
                      child: Text(
                        rupiah(d.service.price),
                        style: _p(19 * s, w: FontWeight.w700),
                      ),
                    ),
                    Positioned(
                      right: 22 * s,
                      top: 21.4 * s,
                      width: 177.6 * s,
                      height: 53 * s,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _bayar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kNavy,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(27 * s),
                          ),
                        ),
                        child: Text(
                          _loading ? 'Memproses...' : 'Bayar Sekarang',
                          style: _p(14 * s, w: FontWeight.w700, c: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 4. Booking Berhasil
// ---------------------------------------------------------------------------

class _CheckPainter extends CustomPainter {
  final double s;
  _CheckPainter(this.s);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.5 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()
      ..moveTo(c.dx - 28.4 * s, c.dy + 6.6 * s)
      ..lineTo(c.dx - 10.4 * s, c.dy + 20.2 * s)
      ..lineTo(c.dx + 29 * s, c.dy - 20.2 * s);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CheckPainter old) => old.s != s;
}

class BookingSuccessPage extends StatelessWidget {
  final BookingData data;
  const BookingSuccessPage({super.key, required this.data});

  Widget _dot(double s, double cx, double cy, double r) => Positioned(
        left: (cx - r) * s,
        top: (cy - r) * s,
        child: Container(
          width: r * 2 * s,
          height: r * 2 * s,
          decoration: const BoxDecoration(
            color: Color(0xFFA9BDE4),
            shape: BoxShape.circle,
          ),
        ),
      );

  Widget _row(double s, String label, String value, double centerY) {
    return Stack(
      children: [
        Positioned(
          left: 20 * s,
          top: (centerY - 6.5) * s,
          child: Text(label, style: _p(12.5 * s, c: _grey)),
        ),
        Positioned(
          right: 20 * s,
          top: (centerY - 6.5) * s,
          child: Text(value, style: _p(12 * s, w: FontWeight.w700)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DesignCanvas(
        builder: (s, h) => Stack(
          children: [
            bgPaw(s, 47.5, 56.8, 30, -0.3),
            bgPaw(s, 341.5, 56.8, 30, 0.3),
            bgPaw(s, 39, 298, 25, -0.2),
            bgPaw(s, 189, 831, 18, 0.1),

            // Titik dekorasi biru
            _dot(s, 129, 59, 3),
            _dot(s, 98.4, 89, 5),
            _dot(s, 289.6, 79, 4),
            _dot(s, 309.8, 179, 6),
            _dot(s, 83.6, 189.6, 4),
            _dot(s, 261.7, 214.7, 3),

            // Lingkaran centang
            Positioned(
              left: (195 - 70) * s,
              top: (139 - 70) * s,
              width: 140 * s,
              height: 140 * s,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFDFE6F3),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              left: (195 - 52.5) * s,
              top: (139 - 52.5) * s,
              width: 105 * s,
              height: 105 * s,
              child: Container(
                decoration: const BoxDecoration(
                  color: kNavy,
                  shape: BoxShape.circle,
                ),
                child: CustomPaint(painter: _CheckPainter(s)),
              ),
            ),

            // Judul & subjudul
            Positioned(
              top: 232.7 * s,
              left: 0,
              right: 0,
              child: Text(
                'Booking Berhasil!',
                textAlign: TextAlign.center,
                style: _p(22 * s, w: FontWeight.w700),
              ),
            ),
            Positioned(
              top: 263 * s,
              left: 0,
              right: 0,
              child: Text(
                'Jadwal grooming kamu sudah dikonfirmasi.\nKami tunggu kedatanganmu!',
                textAlign: TextAlign.center,
                style: _p(13 * s, h: 1.55),
              ),
            ),

            // Kartu detail booking
            Positioned(
              left: 24 * s,
              right: 24 * s,
              top: 314 * s,
              height: 332 * s,
              child: Container(
                decoration: _box(s, r: 22),
                child: Stack(
                  children: [
                    Positioned(
                      left: 20 * s,
                      top: 22.5 * s,
                      child: Text(
                        'Detail Booking',
                        style: _p(13 * s, w: FontWeight.w700),
                      ),
                    ),
                    Positioned(
                      right: 16 * s,
                      top: 16 * s,
                      width: 86 * s,
                      height: 23.5 * s,
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD8F1E0),
                          borderRadius: BorderRadius.circular(12 * s),
                        ),
                        child: Text(
                          'Terkonfirmasi',
                          style: _p(
                            9.5 * s,
                            w: FontWeight.w600,
                            c: const Color(0xFF2E7D4F),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 20 * s,
                      right: 20 * s,
                      top: 52 * s,
                      child: _DashedLine(s: s),
                    ),
                    _row(s, 'Kode Booking', data.kode, 82),
                    _row(s, 'Layanan', data.service.name, 118.8),
                    _row(s, 'Hewan', '${data.animal} - ${data.petName}', 155),
                    _row(s, 'Tanggal', tanggalPanjang(data.date), 191),
                    _row(s, 'Jam', '${data.time} WIB', 227),
                    _row(s, 'Lokasi', 'Pawtopia Batam Center', 263),
                    Positioned(
                      left: 20 * s,
                      right: 20 * s,
                      top: 284 * s,
                      child: _DashedLine(s: s),
                    ),
                    Positioned(
                      left: 20 * s,
                      top: 303 * s,
                      child: Text(
                        'Total Pembayaran',
                        style: _p(13 * s, w: FontWeight.w700),
                      ),
                    ),
                    Positioned(
                      right: 20 * s,
                      top: 301.5 * s,
                      child: Text(
                        rupiah(data.service.price),
                        style: _p(16 * s, w: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Banner info
            Positioned(
              left: 24 * s,
              right: 24 * s,
              top: 661.7 * s,
              height: 40.5 * s,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFD3E2F9),
                  borderRadius: BorderRadius.circular(14 * s),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: 11 * s,
                      top: 3.5 * s,
                      child: PawLogo(width: 22 * s),
                    ),
                    Positioned(
                      left: 40.4 * s,
                      top: 16.5 * s,
                      child: Text(
                        'Datang 10 menit sebelum jadwal ya!',
                        style: _p(11 * s),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Tombol
            Positioned(
              left: 24 * s,
              right: 24 * s,
              top: 718 * s,
              height: 51 * s,
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const JadwalBookingPage()),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kNavy,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26 * s),
                  ),
                ),
                child: Text(
                  'Lihat Jadwal Booking',
                  style: _p(14.5 * s, w: FontWeight.w700, c: Colors.white),
                ),
              ),
            ),
            Positioned(
              left: 24 * s,
              right: 24 * s,
              top: 778 * s,
              height: 45 * s,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const HomePage()),
                    (route) => false,
                  );
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: kNavy,
                  side: const BorderSide(color: kNavy, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(23 * s),
                  ),
                ),
                child: Text(
                  'Kembali ke Beranda',
                  style: _p(13 * s, w: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 5. Jadwal Booking
// ---------------------------------------------------------------------------

class MyBooking {
  final int? id;
  final String serviceName;
  final String animal;
  final String petName;
  DateTime date;
  String time;
  String status; // Terkonfirmasi, Menunggu, Selesai, Dibatalkan

  MyBooking({
    this.id,
    required this.serviceName,
    required this.animal,
    required this.petName,
    required this.date,
    required this.time,
    this.status = 'Menunggu',
  });

  factory MyBooking.fromData(BookingData d) => MyBooking(
        id: int.tryParse(d.bookingId),
        serviceName: d.service.name,
        animal: d.animal,
        petName: d.petName,
        date: d.date,
        time: d.time,
      );

  factory MyBooking.fromJson(Map<String, dynamic> m) {
    final dt =
        DateTime.tryParse((m['booking_date'] ?? '').toString()) ?? DateTime.now();
    var time = (m['booking_time'] ?? '').toString();
    if (time.length >= 5) time = time.substring(0, 5);
    final raw = (m['status'] ?? '').toString().toLowerCase();
    String status = 'Menunggu';
    if (raw.contains('batal') || raw.contains('cancel')) {
      status = 'Dibatalkan';
    } else if (raw.contains('selesai') ||
        raw.contains('complete') ||
        raw.contains('done')) {
      status = 'Selesai';
    } else if (raw.contains('konfirm') || raw.contains('confirm')) {
      status = 'Terkonfirmasi';
    }
    return MyBooking(
      id: int.tryParse('${m['id']}'),
      serviceName: (m['service_name'] ?? 'Grooming').toString(),
      animal: (m['animal_type'] ?? '').toString(),
      petName: (m['pet_name'] ?? '').toString(),
      date: DateTime(dt.year, dt.month, dt.day),
      time: time,
      status: status,
    );
  }

  bool get upcoming => status == 'Terkonfirmasi' || status == 'Menunggu';
}

/// Daftar booking milik pengguna yang sedang login (diambil dari bookings.php).
List<MyBooking> kMyBookings = [];

Future<bool> loadBookings() async {
  final uid = _userId();
  if (uid == 0) return false;
  try {
    final res = await http.get(
      Uri.parse('${apiUrl('bookings.php')}?user_id=$uid'),
    );
    final body = jsonDecode(res.body);
    if (body['success'] == true && body['data'] is List) {
      kMyBookings = (body['data'] as List)
          .map((r) => MyBooking.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList();
      return true;
    }
  } catch (_) {
    // Kalau gagal, tetap pakai daftar yang ada di aplikasi.
  }
  return false;
}

class JadwalBookingPage extends StatefulWidget {
  const JadwalBookingPage({super.key});

  @override
  State<JadwalBookingPage> createState() => _JadwalBookingPageState();
}

class _JadwalBookingPageState extends State<JadwalBookingPage> {
  static const _tabs = ['Akan Datang', 'Selesai', 'Dibatalkan'];
  static const _tabLeft = [23.0, 151.0, 249.0];
  static const _tabW = [121.0, 90.5, 117.5];

  int _tab = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    loadBookings().then((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  List<MyBooking> get _items {
    if (_tab == 0) return kMyBookings.where((b) => b.upcoming).toList();
    if (_tab == 1) return kMyBookings.where((b) => b.status == 'Selesai').toList();
    return kMyBookings.where((b) => b.status == 'Dibatalkan').toList();
  }

  Future<void> _batalkan(MyBooking b) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan booking?'),
        content: Text('${b.serviceName} - ${b.petName} akan dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Tidak'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, batalkan'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    if (b.id != null) {
      final data = await _postBooking({
        'action': 'cancel',
        'booking_id': b.id,
        'user_id': _userId(),
      });
      if (!mounted) return;
      if (data['success'] != true) {
        _snack(context, '${data['message'] ?? 'Gagal membatalkan booking'}');
        return;
      }
    }
    setState(() => b.status = 'Dibatalkan');
    _snack(context, 'Booking dibatalkan');
  }

  Future<void> _ubahJadwal(MyBooking b) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => UbahJadwalPage(booking: b)),
    );
    if (changed == true && mounted) {
      setState(() {});
      loadBookings().then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  Widget _tabChip(double s, int i) {
    final active = _tab == i;
    return Positioned(
      left: _tabLeft[i] * s,
      top: 98.7 * s,
      width: _tabW[i] * s,
      height: 35 * s,
      child: GestureDetector(
        onTap: () => setState(() => _tab = i),
        child: Container(
          alignment: Alignment.center,
          decoration: _box(
            s,
            r: 18,
            fill: active ? kNavy : Colors.white,
            border: active ? kNavy : _line,
          ),
          child: Text(
            _tabs[i],
            style: _p(
              12.5 * s,
              w: active ? FontWeight.w700 : FontWeight.w400,
              c: active ? Colors.white : kNavy,
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionButton(
    double s,
    String label,
    Color color,
    double left,
    VoidCallback onTap,
  ) {
    return Positioned(
      left: left * s,
      top: 90.6 * s,
      width: 151.7 * s,
      height: 31.6 * s,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: color,
          padding: EdgeInsets.zero,
          side: BorderSide(color: color, width: 1.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16 * s),
          ),
        ),
        child: Text(label, style: _p(12 * s, w: FontWeight.w700, c: color)),
      ),
    );
  }

  Widget _card(double s, MyBooking b) {
    final confirmed = b.status == 'Terkonfirmasi';
    final waiting = b.status == 'Menunggu';
    final Color badgeBg = confirmed
        ? const Color(0xFFD8F1E0)
        : waiting
            ? const Color(0xFFFBEBC1)
            : b.status == 'Selesai'
                ? const Color(0xFFD3E2F9)
                : const Color(0xFFFADADD);
    final Color badgeFg = confirmed
        ? const Color(0xFF2E7D4F)
        : waiting
            ? const Color(0xFF9A6B00)
            : b.status == 'Selesai'
                ? const Color(0xFF2F5FA8)
                : const Color(0xFFC0392B);
    return Container(
      height: (b.upcoming ? 132 : 98) * s,
      decoration: _box(s, r: 22),
      child: Stack(
        children: [
          // Kotak tanggal
          Positioned(
            left: 15.7 * s,
            top: 15.3 * s,
            width: 57.3 * s,
            height: 65 * s,
            child: Container(
              decoration: BoxDecoration(
                color: kNavy,
                borderRadius: BorderRadius.circular(15 * s),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 14 * s,
                    child: Text(
                      '${b.date.day}',
                      textAlign: TextAlign.center,
                      style: _p(20 * s, w: FontWeight.w700, c: Colors.white),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 42 * s,
                    child: Text(
                      _bulanPendek[b.date.month - 1].toUpperCase(),
                      textAlign: TextAlign.center,
                      style: _p(11 * s, c: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 88.8 * s,
            top: 23 * s,
            child: Text(b.serviceName, style: _p(14 * s, w: FontWeight.w700)),
          ),
          Positioned(
            left: 88.8 * s,
            top: 44.5 * s,
            child: Text(
              [b.animal, b.petName].where((e) => e.isNotEmpty).join(' - '),
              style: _p(11.5 * s, c: _grey),
            ),
          ),
          Positioned(
            left: 88.8 * s,
            top: 65 * s,
            child: Text(
              '${_hari[b.date.weekday - 1]}, ${b.time} WIB',
              style: _p(11 * s),
            ),
          ),
          // Status
          Positioned(
            right: 16.4 * s,
            top: 13 * s,
            width: 88 * s,
            height: 23 * s,
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(12 * s),
              ),
              child: Text(
                b.status,
                style: _p(9.5 * s, w: FontWeight.w700, c: badgeFg),
              ),
            ),
          ),
          if (b.upcoming) ...[
            _actionButton(
              s,
              'Ubah Jadwal',
              kNavy,
              15.7,
              () => _ubahJadwal(b),
            ),
            _actionButton(
              s,
              'Batalkan',
              const Color(0xFFE5484D),
              176,
              () => _batalkan(b),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, c) {
          final s = c.maxWidth / 390;
          final items = _items;
          return Stack(
            children: [
              ..._topBar(context, s, 'Jadwal Booking'),
              for (int i = 0; i < 3; i++) _tabChip(s, i),
              Positioned(
                left: 0,
                right: 0,
                top: 150 * s,
                bottom: 0,
                child: ListView(
                  padding: EdgeInsets.fromLTRB(23 * s, 0, 23 * s, 30 * s),
                  children: [
                    if (items.isEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 40 * s),
                        child: Center(
                          child: Text(
                            _loading ? 'Memuat jadwal...' : 'Belum ada booking',
                            style: _p(13 * s, c: _grey),
                          ),
                        ),
                      ),
                    for (final b in items)
                      Padding(
                        padding: EdgeInsets.only(bottom: 16 * s),
                        child: _card(s, b),
                      ),
                    SizedBox(height: 6 * s),
                    SizedBox(
                      height: 50 * s,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const GroomingPage(),
                            ),
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kNavy,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25 * s),
                          ),
                        ),
                        child: Text(
                          '+ Booking Baru',
                          style: _p(15 * s, w: FontWeight.w700, c: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 6. Ubah Jadwal
// ---------------------------------------------------------------------------

class UbahJadwalPage extends StatefulWidget {
  final MyBooking booking;
  const UbahJadwalPage({super.key, required this.booking});

  @override
  State<UbahJadwalPage> createState() => _UbahJadwalPageState();
}

class _UbahJadwalPageState extends State<UbahJadwalPage> {
  static const _times = [
    '09:00', '10:30', '13:00', '14:30',
    '16:00', '17:30', '19:00', '20:30',
  ];
  static const _disabled = <String>[];

  late final List<DateTime> _days;
  int _date = 0;
  late String _time;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _days = List.generate(5, (i) => DateTime(now.year, now.month, now.day + i));
    final b = widget.booking;
    final idx = _days.indexWhere(
      (d) => d.year == b.date.year && d.month == b.date.month && d.day == b.date.day,
    );
    _date = idx >= 0 ? idx : 0;
    _time = _times.contains(b.time) ? b.time : '13:00';
  }

  Future<void> _simpan() async {
    final b = widget.booking;
    final newDate = _days[_date];
    final same = newDate.year == b.date.year &&
        newDate.month == b.date.month &&
        newDate.day == b.date.day &&
        _time == b.time;
    if (same) {
      _snack(context, 'Jadwal belum diubah');
      return;
    }
    setState(() => _saving = true);
    if (b.id != null) {
      final data = await _postBooking({
        'action': 'reschedule',
        'booking_id': b.id,
        'user_id': _userId(),
        'booking_date': ymd(newDate),
        'booking_time': _time,
      });
      if (!mounted) return;
      if (data['success'] != true) {
        setState(() => _saving = false);
        _snack(context, '${data['message'] ?? 'Gagal mengubah jadwal'}');
        return;
      }
    }
    b.date = newDate;
    b.time = _time;
    _snack(context, 'Jadwal berhasil diubah');
    Navigator.pop(context, true);
  }

  Widget _dateChip(double s, int i) {
    final d = _days[i];
    final selected = _date == i;
    final color = selected ? Colors.white : kNavy;
    return Positioned(
      left: (24 + i * 70) * s,
      top: 238 * s,
      width: 62 * s,
      height: 56 * s,
      child: GestureDetector(
        onTap: () => setState(() => _date = i),
        child: Container(
          decoration: _box(
            s,
            r: 15,
            fill: selected ? kNavy : Colors.white,
            border: selected ? kNavy : _line,
          ),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 12.5 * s,
                child: Text(
                  _hariPendek[d.weekday - 1],
                  textAlign: TextAlign.center,
                  style: _p(11 * s, c: color),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 32 * s,
                child: Text(
                  '${d.day}',
                  textAlign: TextAlign.center,
                  style: _p(16 * s, w: FontWeight.w700, c: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _timeChip(double s, int i) {
    final t = _times[i];
    final disabled = _disabled.contains(t);
    final selected = _time == t;
    return Positioned(
      left: (24 + (i % 4) * 87.5) * s,
      top: (337 + (i ~/ 4) * 42) * s,
      width: 79.5 * s,
      height: 34 * s,
      child: GestureDetector(
        onTap: disabled ? null : () => setState(() => _time = t),
        child: Container(
          alignment: Alignment.center,
          decoration: _box(
            s,
            r: 17,
            fill: selected ? kNavy : Colors.white,
            border: selected ? kNavy : _line,
          ),
          child: Text(
            t,
            style: _p(
              12 * s,
              w: selected ? FontWeight.w700 : FontWeight.w400,
              c: selected
                  ? Colors.white
                  : (disabled ? const Color(0xFFC4C4C4) : kNavy),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final first = _days.first;
    return Scaffold(
      body: DesignCanvas(
        builder: (s, h) => Stack(
          children: [
            ..._topBar(context, s, 'Ubah Jadwal'),

            // Ringkasan booking
            Positioned(
              left: 24 * s,
              right: 24 * s,
              top: 118 * s,
              height: 76 * s,
              child: Container(
                decoration: _box(s, r: 18),
                child: Stack(
                  children: [
                    Positioned(
                      left: 17 * s,
                      top: 14 * s,
                      child: Text(
                        b.serviceName,
                        style: _p(14 * s, w: FontWeight.w700),
                      ),
                    ),
                    Positioned(
                      left: 17 * s,
                      top: 36 * s,
                      child: Text(
                        [b.animal, b.petName].where((e) => e.isNotEmpty).join(' - '),
                        style: _p(11.5 * s, c: _grey),
                      ),
                    ),
                    Positioned(
                      left: 17 * s,
                      top: 54 * s,
                      child: Text(
                        'Jadwal saat ini: ${tanggalPanjang(b.date)} - ${b.time}',
                        style: _p(10.5 * s),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Tanggal baru
            _label(s, 'Pilih Tanggal Baru', 222),
            Positioned(
              right: 23 * s,
              top: 216.5 * s,
              child: Text(
                '${_bulan[first.month - 1]} ${first.year}',
                style: _p(10.5 * s, c: _grey),
              ),
            ),
            for (int i = 0; i < 5; i++) _dateChip(s, i),

            // Jam baru
            _label(s, 'Pilih Jam Baru', 322),
            for (int i = 0; i < _times.length; i++) _timeChip(s, i),

            // Tombol simpan
            Positioned(
              left: 24 * s,
              right: 24 * s,
              top: 440 * s,
              height: 50 * s,
              child: ElevatedButton(
                onPressed: _saving ? null : _simpan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kNavy,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25 * s),
                  ),
                ),
                child: Text(
                  _saving ? 'Menyimpan...' : 'Simpan Jadwal',
                  style: _p(15 * s, w: FontWeight.w700, c: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}