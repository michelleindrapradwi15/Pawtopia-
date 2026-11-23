import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'main.dart';
import 'widgets.dart';
import 'home_page.dart';
import 'grooming_pages.dart';
import 'produk_pages.dart';

const Color _line = Color(0xFFF0E6D8);
const Color _grey = Color(0xFF8A8A8A);

TextStyle _p(
  double size, {
  FontWeight w = FontWeight.w400,
  Color c = kNavy,
  double h = 1.0,
}) =>
    GoogleFonts.poppins(fontSize: size, fontWeight: w, color: c, height: h);

void _snack(BuildContext context, String teks) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(teks)));
}

int _uid() => int.tryParse('${Session.user?['id'] ?? 0}') ?? 0;

/// Kirim permintaan ke profile.php. Selalu mengembalikan Map berisi
/// success dan message, termasuk saat server membalas error.
Future<Map<String, dynamic>> _postProfile(Map<String, dynamic> payload) async {
  try {
    final res = await http.post(
      Uri.parse(apiUrl('profile.php')),
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

BoxDecoration _card(double s) => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22 * s),
      border: Border.all(color: _line),
    );

Widget _label(double s, String text) => Padding(
      padding: EdgeInsets.only(top: 18 * s, bottom: 8 * s, left: 4 * s),
      child: Text(text, style: _p(14 * s, w: FontWeight.w700)),
    );

Widget _primary(double s, String label, VoidCallback? onTap) => SizedBox(
      height: 50 * s,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: kNavy,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF8FA0BF),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25 * s),
          ),
        ),
        child: Text(label, style: _p(15 * s, w: FontWeight.w700, c: Colors.white)),
      ),
    );

/// Kerangka halaman: judul, cakar kecil, isi yang bisa di-scroll, dan panah
/// kembali di lapisan paling atas supaya selalu bisa ditekan.
class _Shell extends StatelessWidget {
  final String title;
  final List<Widget> Function(double s) body;
  const _Shell({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, c) {
          final s = c.maxWidth / 390;
          return Stack(
            children: [
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
                left: 0,
                right: 0,
                top: 108 * s,
                bottom: 0,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(24 * s, 8 * s, 24 * s, 40 * s),
                    children: body(s),
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
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Profil Saya
// ---------------------------------------------------------------------------

class ProfilDetailPage extends StatefulWidget {
  const ProfilDetailPage({super.key});

  @override
  State<ProfilDetailPage> createState() => _ProfilDetailPageState();
}

class _ProfilDetailPageState extends State<ProfilDetailPage> {
  final _name =
      TextEditingController(text: (Session.user?['name'] ?? '').toString());
  final _email = TextEditingController(text: Session.email);
  final _phone = TextEditingController(text: Session.phone);
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    final name = _name.text.trim();
    final phone = _phone.text.trim();
    if (_uid() == 0) {
      _snack(context, 'Silakan login dulu');
      return;
    }
    if (name.isEmpty) {
      _snack(context, 'Nama wajib diisi');
      return;
    }
    setState(() => _saving = true);
    final data = await _postProfile({
      'action': 'update_profile',
      'user_id': _uid(),
      'name': name,
      'phone': phone,
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (data['success'] == true) {
      Session.merge({'name': name, 'phone': phone});
      _snack(context, 'Profil berhasil diperbarui');
      Navigator.pop(context, true);
    } else {
      _snack(context, '${data['message'] ?? 'Gagal menyimpan profil'}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Shell(
      title: 'Profil Saya',
      body: (s) => [
        _label(s, 'Nama Lengkap'),
        PawField(s: s, controller: _name, hint: 'Nama Lengkap'),
        _label(s, 'Email'),
        PawField(s: s, controller: _email, hint: 'Email', readOnly: true),
        Padding(
          padding: EdgeInsets.only(top: 6 * s, left: 4 * s),
          child: Text('Email tidak dapat diubah.', style: _p(10.5 * s, c: _grey)),
        ),
        _label(s, 'Nomor HP'),
        PawField(
          s: s,
          controller: _phone,
          hint: 'Nomor HP',
          keyboardType: TextInputType.phone,
        ),
        SizedBox(height: 28 * s),
        _primary(
          s,
          _saving ? 'Menyimpan...' : 'Simpan Perubahan',
          _saving ? null : _simpan,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Alamat Saya (daftar alamat) & Tambah / Ubah Alamat
// ---------------------------------------------------------------------------

const Color _blue = Color(0xFF2F6FD6);
const Color _red = Color(0xFFE5484D);
const Color _chipBlue = Color(0xFFD3E2F9);

class AddressItem {
  final int? id;
  final String label;
  final String name;
  final String phone;
  final String city;
  final String postal;
  final String street;
  final bool primary;

  const AddressItem({
    this.id,
    required this.label,
    required this.name,
    required this.phone,
    required this.city,
    required this.postal,
    required this.street,
    required this.primary,
  });

  factory AddressItem.fromJson(Map<String, dynamic> m) => AddressItem(
        id: int.tryParse('${m['id']}'),
        label: (m['label'] ?? 'Rumah').toString(),
        name: (m['recipient_name'] ?? '').toString(),
        phone: (m['phone'] ?? '').toString(),
        city: (m['city'] ?? '').toString(),
        postal: (m['postal_code'] ?? '').toString(),
        street: (m['street'] ?? '').toString(),
        primary: '${m['is_primary']}' == '1',
      );

  String get full {
    final parts = <String>[];
    if (street.isNotEmpty) parts.add(street);
    final tail = [city, postal].where((e) => e.isNotEmpty).join(' ');
    if (tail.isNotEmpty) parts.add(tail);
    return parts.join(', ');
  }
}

/// GET (tanpa post) atau POST ke file API. Selalu mengembalikan Map berisi
/// success dan message, termasuk saat server membalas error.
Future<Map<String, dynamic>> _api(
  String file, {
  Map<String, dynamic>? post,
  String query = '',
}) async {
  try {
    final uri = Uri.parse('${apiUrl(file)}$query');
    final res = post == null
        ? await http.get(uri)
        : await http.post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(post),
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

class AlamatPage extends StatefulWidget {
  const AlamatPage({super.key});

  @override
  State<AlamatPage> createState() => _AlamatPageState();
}

class _AlamatPageState extends State<AlamatPage> {
  List<AddressItem> _items = [];
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_uid() == 0) {
      setState(() {
        _loading = false;
        _error = 'Silakan login dulu';
      });
      return;
    }
    final data = await _api('addresses.php', query: '?user_id=${_uid()}');
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (data['success'] == true && data['data'] is List) {
        _items = (data['data'] as List)
            .map((r) => AddressItem.fromJson(Map<String, dynamic>.from(r as Map)))
            .toList();
        _error = '';
      } else {
        _error = '${data['message'] ?? 'Gagal memuat alamat'}';
      }
    });
  }

  Future<void> _buka([AddressItem? a]) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => TambahAlamatPage(existing: a)),
    );
    if (changed == true) _load();
  }

  Future<void> _hapus(AddressItem a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus alamat?'),
        content: Text('Alamat ${a.label} atas nama ${a.name} akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final data = await _api('addresses.php', post: {
      'action': 'delete',
      'user_id': _uid(),
      'address_id': a.id,
    });
    if (!mounted) return;
    _snack(context, '${data['message'] ?? ''}');
    _load();
  }

  Future<void> _jadikanUtama(AddressItem a) async {
    final data = await _api('addresses.php', post: {
      'action': 'set_primary',
      'user_id': _uid(),
      'address_id': a.id,
    });
    if (!mounted) return;
    _snack(context, '${data['message'] ?? ''}');
    _load();
  }

  Widget _chip(double s, String text, {bool dark = false}) => Container(
        height: 23 * s,
        padding: EdgeInsets.symmetric(horizontal: 11 * s),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: dark ? kNavy : _chipBlue,
          borderRadius: BorderRadius.circular(12 * s),
        ),
        child: Text(
          text,
          style: _p(10.5 * s, w: FontWeight.w700, c: dark ? Colors.white : kNavy),
        ),
      );

  Widget _link(double s, String text, Color color, VoidCallback onTap) =>
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 6 * s, horizontal: 4 * s),
          child: Text(text, style: _p(12 * s, w: FontWeight.w700, c: color)),
        ),
      );

  Widget _addrCard(double s, AddressItem a) {
    return Container(
      padding: EdgeInsets.fromLTRB(15.2 * s, 14.2 * s, 16.5 * s, 7 * s),
      decoration: _card(s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _chip(s, a.label),
              if (a.primary) ...[
                SizedBox(width: 6.5 * s),
                _chip(s, 'Utama', dark: true),
              ],
            ],
          ),
          SizedBox(height: 13 * s),
          Row(
            children: [
              Expanded(
                child: Text(
                  a.name,
                  overflow: TextOverflow.ellipsis,
                  style: _p(14.5 * s, w: FontWeight.w700),
                ),
              ),
              SizedBox(width: 8 * s),
              Text(a.phone, style: _p(12 * s, c: _grey)),
            ],
          ),
          SizedBox(height: 4 * s),
          Text(
            a.full,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: _p(10 * s, c: _grey, h: 1.7),
          ),
          SizedBox(height: 6 * s),
          Container(height: 1, color: const Color(0xFFEDE3D3)),
          SizedBox(height: 4 * s),
          Row(
            children: [
              _link(s, 'Ubah', _blue, () => _buka(a)),
              SizedBox(width: 10 * s),
              _link(s, 'Hapus', _red, () => _hapus(a)),
              const Spacer(),
              if (!a.primary)
                _link(s, 'Jadikan Utama', kNavy, () => _jadikanUtama(a)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _body(double s) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: kNavy));
    }
    return ListView(
      padding: EdgeInsets.fromLTRB(23 * s, 0, 23 * s, 24 * s),
      children: [
        if (_error.isNotEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 20 * s),
            child: Text(
              _error,
              textAlign: TextAlign.center,
              style: _p(12 * s, c: _red, h: 1.4),
            ),
          ),
        if (_error.isEmpty && _items.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 30 * s),
            child: Text(
              'Belum ada alamat. Tambahkan alamat pertamamu.',
              textAlign: TextAlign.center,
              style: _p(12.5 * s, c: _grey, h: 1.4),
            ),
          ),
        for (final a in _items)
          Padding(
            padding: EdgeInsets.only(bottom: 12 * s),
            child: _addrCard(s, a),
          ),
        SizedBox(height: 12 * s),
        SizedBox(
          height: 50.7 * s,
          child: ElevatedButton(
            onPressed: () => _buka(),
            style: ElevatedButton.styleFrom(
              backgroundColor: kNavy,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26 * s),
              ),
            ),
            child: Text(
              '+ Tambah Alamat Baru',
              style: _p(15 * s, w: FontWeight.w700, c: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, c) {
          final s = c.maxWidth / 390;
          return Stack(
            children: [
              bgPaw(s, 347, 66.7, 33, 0.2),
              bgPaw(s, 189.5, 749, 22, 0.1),
              Positioned(
                top: 68 * s,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Text(
                    'Alamat Saya',
                    textAlign: TextAlign.center,
                    style: _p(18 * s, w: FontWeight.w700),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 102 * s,
                bottom: 84 * s,
                child: _body(s),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: PawBottomNav(
                  s: s,
                  active: 4,
                  onTap: (i) {
                    if (i == 4) {
                      Navigator.pop(context);
                    } else if (i == 0) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const HomePage()),
                        (route) => false,
                      );
                    } else if (i == 1) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const ProdukPage()),
                        (route) => false,
                      );
                    } else if (i == 2) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const GroomingPage()),
                        (route) => false,
                      );
                    } else {
                      _snack(context, 'Halaman belum tersedia');
                    }
                  },
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
            ],
          );
        },
      ),
    );
  }
}

class _PawSwitch extends StatelessWidget {
  final double s;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _PawSwitch({
    required this.s,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 45.4 * s,
        height: 26 * s,
        padding: EdgeInsets.all(3 * s),
        decoration: BoxDecoration(
          color: value ? kNavy : const Color(0xFFD9D2C5),
          borderRadius: BorderRadius.circular(13 * s),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 180),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20 * s,
            height: 20 * s,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

class TambahAlamatPage extends StatefulWidget {
  final AddressItem? existing;
  const TambahAlamatPage({super.key, this.existing});

  @override
  State<TambahAlamatPage> createState() => _TambahAlamatPageState();
}

class _TambahAlamatPageState extends State<TambahAlamatPage> {
  static const _labels = ['Rumah', 'Kantor', 'Lainnya'];
  static const _kota = [
    'Batam Kota, Kota Batam',
    'Batu Aji, Kota Batam',
    'Batu Ampar, Kota Batam',
    'Belakang Padang, Kota Batam',
    'Bengkong, Kota Batam',
    'Bulang, Kota Batam',
    'Galang, Kota Batam',
    'Lubuk Baja, Kota Batam',
    'Nongsa, Kota Batam',
    'Sagulung, Kota Batam',
    'Sei Beduk, Kota Batam',
    'Sekupang, Kota Batam',
  ];

  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _postal;
  late final TextEditingController _street;
  late String _label;
  late String _city;
  late bool _primary;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(
      text: e?.name ?? (Session.name == 'Pengguna' ? '' : Session.name),
    );
    _phone = TextEditingController(text: e?.phone ?? Session.phone);
    _postal = TextEditingController(text: e?.postal ?? '');
    _street = TextEditingController(text: e?.street ?? '');
    _label = e?.label ?? 'Rumah';
    _city = e?.city ?? '';
    _primary = e?.primary ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _postal.dispose();
    _street.dispose();
    super.dispose();
  }

  Future<void> _pilihKota() async {
    FocusScope.of(context).unfocus();
    final pilih = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.7,
          ),
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final k in _kota)
                ListTile(
                  title: Text(k, style: _p(14)),
                  onTap: () => Navigator.pop(ctx, k),
                ),
              ListTile(
                title: Text('Kota lain (ketik manual)', style: _p(14, c: _blue)),
                onTap: () => Navigator.pop(ctx, '__manual__'),
              ),
            ],
          ),
        ),
      ),
    );
    if (pilih == null || !mounted) return;
    if (pilih != '__manual__') {
      setState(() => _city = pilih);
      return;
    }
    final ctrl = TextEditingController();
    final teks = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kota / Kecamatan'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Contoh: Tanjungpinang'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (teks != null && teks.isNotEmpty && mounted) {
      setState(() => _city = teks);
    }
  }

  Future<void> _simpan() async {
    if (_uid() == 0) {
      _snack(context, 'Silakan login dulu');
      return;
    }
    if (_name.text.trim().isEmpty) {
      _snack(context, 'Nama wajib diisi');
      return;
    }
    if (_city.isEmpty) {
      _snack(context, 'Pilih kota / kecamatan dulu');
      return;
    }
    if (_street.text.trim().isEmpty) {
      _snack(context, 'Alamat jalan wajib diisi');
      return;
    }
    final e = widget.existing;
    setState(() => _saving = true);
    final data = await _api('addresses.php', post: {
      'action': e == null ? 'create' : 'update',
      'user_id': _uid(),
      if (e != null) 'address_id': e.id,
      'label': _label,
      'recipient_name': _name.text.trim(),
      'phone': _phone.text.trim(),
      'city': _city,
      'postal_code': _postal.text.trim(),
      'street': _street.text.trim(),
      'is_primary': _primary,
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (data['success'] == true) {
      _snack(context, '${data['message'] ?? 'Alamat tersimpan'}');
      Navigator.pop(context, true);
    } else {
      _snack(context, '${data['message'] ?? 'Gagal menyimpan alamat'}');
    }
  }

  Widget _labelChip(double s, int i) {
    final selected = _label == _labels[i];
    return Positioned(
      left: (23 + i * 88) * s,
      top: 132.7 * s,
      width: 80 * s,
      height: 34.4 * s,
      child: GestureDetector(
        onTap: () => setState(() => _label = _labels[i]),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? kNavy : Colors.white,
            borderRadius: BorderRadius.circular(18 * s),
            border: Border.all(color: selected ? kNavy : _line),
          ),
          child: Text(
            _labels[i],
            style: _p(
              12 * s,
              w: selected ? FontWeight.w700 : FontWeight.w400,
              c: selected ? Colors.white : kNavy,
            ),
          ),
        ),
      ),
    );
  }

  Widget _pill(
    double s,
    double top,
    TextEditingController ctrl,
    String hint, {
    TextInputType? keyboard,
  }) {
    return Positioned(
      left: 24 * s,
      right: 24 * s,
      top: top * s,
      height: 46 * s,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20 * s),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(23 * s),
          border: Border.all(color: _line),
        ),
        child: TextField(
          controller: ctrl,
          keyboardType: keyboard,
          style: _p(13.5 * s),
          decoration: InputDecoration(
            isCollapsed: true,
            border: InputBorder.none,
            hintText: hint,
            hintStyle: _p(13.5 * s, c: _grey),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;
    return Scaffold(
      body: DesignCanvas(
        builder: (s, h) => Stack(
          children: [
            bgPaw(s, 347, 66.7, 33, 0.2),
            bgPaw(s, 38.2, 638.5, 25, -0.3),
            bgPaw(s, 340, 669.6, 25, 0.3),
            Positioned(
              top: 68 * s,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Text(
                  editing ? 'Ubah Alamat' : 'Tambah Alamat',
                  textAlign: TextAlign.center,
                  style: _p(18 * s, w: FontWeight.w700),
                ),
              ),
            ),

            // Label alamat
            Positioned(
              left: 23 * s,
              top: 110 * s,
              child: Text('Label Alamat', style: _p(14.5 * s, w: FontWeight.w700)),
            ),
            for (int i = 0; i < 3; i++) _labelChip(s, i),

            // Isian
            _pill(s, 185.2, _name, 'Nama penerima'),
            _pill(s, 239.8, _phone, 'Nomor HP', keyboard: TextInputType.phone),
            Positioned(
              left: 24 * s,
              right: 24 * s,
              top: 294 * s,
              height: 46 * s,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _pilihKota,
                child: Container(
                  padding: EdgeInsets.only(left: 20 * s, right: 18 * s),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(23 * s),
                    border: Border.all(color: _line),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _city.isEmpty ? 'Pilih Kota / Kecamatan' : _city,
                          overflow: TextOverflow.ellipsis,
                          style: _p(13.5 * s, c: _city.isEmpty ? _grey : kNavy),
                        ),
                      ),
                      Icon(Icons.keyboard_arrow_down, size: 22 * s, color: kNavy),
                    ],
                  ),
                ),
              ),
            ),
            _pill(s, 348.5, _postal, 'Kode Pos', keyboard: TextInputType.number),
            Positioned(
              left: 24 * s,
              right: 24 * s,
              top: 402.5 * s,
              height: 80 * s,
              child: Container(
                padding: EdgeInsets.fromLTRB(20 * s, 14 * s, 20 * s, 10 * s),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22 * s),
                  border: Border.all(color: _line),
                ),
                child: TextField(
                  controller: _street,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: _p(13.5 * s, h: 1.4),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: 'Nama jalan, nomor rumah, RT/RW, patokan',
                    hintStyle: _p(13.5 * s, c: _grey, h: 1.4),
                  ),
                ),
              ),
            ),

            // Jadikan alamat utama
            Positioned(
              left: 23 * s,
              top: 509 * s,
              child: Text('Jadikan alamat utama', style: _p(14 * s)),
            ),
            Positioned(
              right: 35.5 * s,
              top: 503 * s,
              child: _PawSwitch(
                s: s,
                value: _primary,
                onChanged: (v) => setState(() => _primary = v),
              ),
            ),

            // Tandai lokasi di peta
            Positioned(
              left: 24 * s,
              right: 24 * s,
              top: 548.4 * s,
              height: 46 * s,
              child: OutlinedButton(
                onPressed: () => _snack(context, 'Fitur peta belum tersedia'),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _blue,
                  side: const BorderSide(color: _blue, width: 1.2),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(23 * s),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(width: 23 * s),
                    Icon(Icons.adjust, size: 24 * s, color: _blue),
                    SizedBox(width: 12 * s),
                    Text(
                      'Tandai Lokasi di Peta',
                      style: _p(12.5 * s, w: FontWeight.w700, c: _blue),
                    ),
                  ],
                ),
              ),
            ),

            // Simpan
            Positioned(
              left: 24 * s,
              right: 24 * s,
              top: 700.8 * s,
              height: 50.8 * s,
              child: ElevatedButton(
                onPressed: _saving ? null : _simpan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kNavy,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFF8FA0BF),
                  disabledForegroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26 * s),
                  ),
                ),
                child: Text(
                  _saving ? 'Menyimpan...' : 'Simpan Alamat',
                  style: _p(15 * s, w: FontWeight.w700, c: Colors.white),
                ),
              ),
            ),

            // Panah kembali (lapisan paling atas)
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
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pengaturan Akun (ubah password)
// ---------------------------------------------------------------------------

class PengaturanPage extends StatefulWidget {
  const PengaturanPage({super.key});

  @override
  State<PengaturanPage> createState() => _PengaturanPageState();
}

class _PengaturanPageState extends State<PengaturanPage> {
  final _old = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _hideOld = true;
  bool _hideNew = true;
  bool _hideConfirm = true;
  bool _saving = false;

  @override
  void dispose() {
    _old.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _ubah() async {
    if (_uid() == 0) {
      _snack(context, 'Silakan login dulu');
      return;
    }
    if (_old.text.isEmpty || _new.text.isEmpty || _confirm.text.isEmpty) {
      _snack(context, 'Semua kolom wajib diisi');
      return;
    }
    if (_new.text.length < 8) {
      _snack(context, 'Password baru minimal 8 karakter');
      return;
    }
    if (_new.text != _confirm.text) {
      _snack(context, 'Konfirmasi password tidak sama');
      return;
    }
    setState(() => _saving = true);
    final data = await _postProfile({
      'action': 'change_password',
      'user_id': _uid(),
      'old_password': _old.text,
      'new_password': _new.text,
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (data['success'] == true) {
      _old.clear();
      _new.clear();
      _confirm.clear();
      _snack(context, 'Password berhasil diubah');
    } else {
      _snack(context, '${data['message'] ?? 'Gagal mengubah password'}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Shell(
      title: 'Pengaturan Akun',
      body: (s) => [
        Padding(
          padding: EdgeInsets.only(top: 10 * s, left: 4 * s),
          child: Text('Ubah Password', style: _p(16 * s, w: FontWeight.w700)),
        ),
        Padding(
          padding: EdgeInsets.only(top: 6 * s, left: 4 * s),
          child: Text(
            'Gunakan password baru minimal 8 karakter.',
            style: _p(11.5 * s, c: _grey),
          ),
        ),
        _label(s, 'Password Lama'),
        PawField(
          s: s,
          controller: _old,
          hint: 'Password Lama',
          obscure: _hideOld,
          onTrailingTap: () => setState(() => _hideOld = !_hideOld),
        ),
        _label(s, 'Password Baru'),
        PawField(
          s: s,
          controller: _new,
          hint: 'Password Baru',
          obscure: _hideNew,
          onTrailingTap: () => setState(() => _hideNew = !_hideNew),
        ),
        _label(s, 'Konfirmasi Password Baru'),
        PawField(
          s: s,
          controller: _confirm,
          hint: 'Konfirmasi Password Baru',
          obscure: _hideConfirm,
          onTrailingTap: () => setState(() => _hideConfirm = !_hideConfirm),
        ),
        SizedBox(height: 28 * s),
        _primary(
          s,
          _saving ? 'Menyimpan...' : 'Ubah Password',
          _saving ? null : _ubah,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Bantuan & FAQ
// ---------------------------------------------------------------------------

class BantuanPage extends StatelessWidget {
  const BantuanPage({super.key});

  static const _faqs = [
    [
      'Bagaimana cara booking grooming?',
      'Buka menu Grooming, pilih layanan lalu tekan Lanjutkan. Isi data hewan, pilih tanggal dan jam, kemudian konfirmasi dan lakukan pembayaran.',
    ],
    [
      'Bagaimana cara mengubah jadwal booking?',
      'Buka Grooming, pilih tab Jadwal Saya, lalu tekan Ubah Jadwal pada booking yang ingin diubah. Pilih tanggal dan jam baru, lalu simpan.',
    ],
    [
      'Bagaimana cara membatalkan booking?',
      'Di Jadwal Saya, tekan Batalkan pada booking yang diinginkan dan konfirmasi pembatalan. Booking yang dibatalkan akan pindah ke tab Dibatalkan.',
    ],
    [
      'Metode pembayaran apa saja yang tersedia?',
      'Transfer Bank, QRIS, E-Wallet (DANA, OVO, GoPay), dan Bayar di Salon.',
    ],
    [
      'Apa arti status Menunggu dan Terkonfirmasi?',
      'Menunggu berarti booking sudah diterima dan menunggu konfirmasi dari salon. Terkonfirmasi berarti jadwal sudah dipastikan.',
    ],
    [
      'Bagaimana kalau saya lupa password?',
      'Saat ini belum ada reset password otomatis. Hubungi admin Pawtopia agar akunmu dibantu.',
    ],
  ];

  @override
  Widget build(BuildContext context) {
    return _Shell(
      title: 'Bantuan & FAQ',
      body: (s) => [
        Padding(
          padding: EdgeInsets.only(top: 10 * s, bottom: 12 * s, left: 4 * s),
          child: Text(
            'Pertanyaan yang sering diajukan',
            style: _p(14 * s, w: FontWeight.w700),
          ),
        ),
        for (final f in _faqs)
          Padding(
            padding: EdgeInsets.only(bottom: 10 * s),
            child: Container(
              decoration: _card(s),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  shape: const Border(),
                  collapsedShape: const Border(),
                  iconColor: kNavy,
                  collapsedIconColor: kNavy,
                  tilePadding: EdgeInsets.symmetric(horizontal: 18 * s),
                  childrenPadding: EdgeInsets.fromLTRB(18 * s, 0, 18 * s, 16 * s),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  title: Text(
                    f[0],
                    style: _p(13 * s, w: FontWeight.w600, h: 1.3),
                  ),
                  children: [
                    Text(
                      f[1],
                      style: _p(12 * s, c: const Color(0xFF55627F), h: 1.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        SizedBox(height: 8 * s),
        Container(
          padding: EdgeInsets.all(18 * s),
          decoration: BoxDecoration(
            color: const Color(0xFFD3E2F9),
            borderRadius: BorderRadius.circular(18 * s),
          ),
          child: Text(
            'Butuh bantuan lain? Datang langsung ke Pawtopia Batam Center atau hubungi admin Pawtopia.',
            style: _p(12 * s, h: 1.5),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Tentang Pawtopia
// ---------------------------------------------------------------------------

class TentangPage extends StatelessWidget {
  const TentangPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _Shell(
      title: 'Tentang Pawtopia',
      body: (s) => [
        SizedBox(height: 10 * s),
        Center(child: PawLogo(width: 96 * s)),
        SizedBox(height: 18 * s),
        Center(
          child: Text('Pawtopia', style: _p(30 * s, w: FontWeight.w700)),
        ),
        SizedBox(height: 8 * s),
        Center(child: Text('Pet Care, Happy Life', style: _p(14 * s))),
        SizedBox(height: 6 * s),
        Center(child: Text('Versi 1.0.0', style: _p(11.5 * s, c: _grey))),
        SizedBox(height: 24 * s),
        Container(
          padding: EdgeInsets.all(18 * s),
          decoration: _card(s),
          child: Text(
            'Pawtopia adalah aplikasi untuk memenuhi semua kebutuhan hewan kesayanganmu dalam satu tempat: pesan grooming, atur jadwal, dan belanja kebutuhan hewan dengan mudah.',
            style: _p(13 * s, h: 1.6),
          ),
        ),
        SizedBox(height: 14 * s),
        Container(
          padding: EdgeInsets.all(18 * s),
          decoration: _card(s),
          child: Row(
            children: [
              Icon(Icons.adjust, size: 24 * s, color: kNavy),
              SizedBox(width: 14 * s),
              Expanded(
                child: Text(
                  'Pawtopia Batam Center',
                  style: _p(13 * s, w: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 24 * s),
        Center(
          child: Text(
            '© 2026 Pawtopia. Semua hak dilindungi.',
            style: _p(10.5 * s, c: _grey),
          ),
        ),
      ],
    );
  }
}