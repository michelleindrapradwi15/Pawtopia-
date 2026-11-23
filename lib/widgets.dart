import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart';

/// Alamat API: Chrome = localhost, emulator Android = 10.0.2.2.
/// Untuk HP asli, ganti dengan IP laptop kamu.
String apiUrl(String file) {
  final host = kIsWeb ? 'http://localhost' : 'http://10.0.2.2';
  return '$host/pawtopia_api/api/$file';
}

/// Kolom isian bulat dengan ikon lingkaran-titik, sama seperti desain.
/// Kalau [onTrailingTap] diisi, ikon di kanan ikut tampil dan bisa ditekan.
class PawField extends StatelessWidget {
  final double s;
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final VoidCallback? onTrailingTap;
  final TextInputType? keyboardType;
  final bool readOnly;

  const PawField({
    super.key,
    required this.s,
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.onTrailingTap,
    this.keyboardType,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    const grey = Color(0xFF8A8A8A);
    return Container(
      height: 54 * s,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(27 * s),
        border: Border.all(color: const Color(0xFFF0E6D8)),
      ),
      child: Row(
        children: [
          SizedBox(width: 20 * s),
          Icon(Icons.adjust, size: 22 * s, color: grey),
          SizedBox(width: 16 * s),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscure,
              keyboardType: keyboardType,
              readOnly: readOnly,
              style: GoogleFonts.poppins(
                fontSize: 14 * s,
                color: readOnly ? const Color(0xFF8A8A8A) : kNavy,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: GoogleFonts.poppins(fontSize: 14 * s, color: grey),
              ),
            ),
          ),
          if (onTrailingTap != null)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTrailingTap,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 17 * s),
                child: Icon(Icons.adjust, size: 22 * s, color: grey),
              ),
            )
          else
            SizedBox(width: 16 * s),
        ],
      ),
    );
  }
}

/// Menu navigasi bawah yang menempel di dasar layar (dipakai halaman Grooming).
class PawBottomNav extends StatelessWidget {
  final double s;
  final int active;
  final ValueChanged<int> onTap;

  const PawBottomNav({
    super.key,
    required this.s,
    required this.active,
    required this.onTap,
  });

  static const _icons = [
    Icons.home_outlined,
    Icons.shopping_bag_outlined,
    Icons.content_cut,
    Icons.shopping_basket_outlined,
    Icons.person_outline,
  ];
  static const _labels = ['Beranda', 'Produk', 'Grooming', 'Keranjang', 'Profil'];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 84 * s,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30 * s)),
        boxShadow: [
          BoxShadow(
            color: const Color(0x14000000),
            blurRadius: 14 * s,
            offset: Offset(0, -2 * s),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(5, (i) {
          final isActive = active == i;
          final color = isActive ? kNavy : const Color(0xFF8A8A8A);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onTap(i),
            child: Padding(
              padding: EdgeInsets.only(top: 16 * s),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_icons[i], size: 25 * s, color: color),
                  SizedBox(height: 11.5 * s),
                  Text(
                    _labels[i],
                    style: GoogleFonts.poppins(
                      fontSize: 11 * s,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                      color: color,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Menyimpan data pengguna yang sedang login (diisi saat login berhasil).
class Session {
  static Map<String, dynamic>? user;

  static String _get(String key) => (user?[key] ?? '').toString();

  static String get name => _get('name').isEmpty ? 'Pengguna' : _get('name');
  static String get email => _get('email');
  static String get phone => _get('phone');
  static String get address => _get('addres s');

  /// Gabungkan data baru ke data pengguna yang sedang login.
  static void merge(Map<String, dynamic> fields) {
    user = {...?user, ...fields};
  }

  static void clear() => user = null;
}