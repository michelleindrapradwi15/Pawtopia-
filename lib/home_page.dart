import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart';
import 'grooming_pages.dart';
import 'profile_page.dart';
import 'produk_pages.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _tab = 0;

  void _soon(String nama) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Halaman $nama belum tersedia')),
    );
  }

  BoxDecoration _card(double s) => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22 * s),
        border: Border.all(color: const Color(0xFFF0E6D8)),
        boxShadow: [
          BoxShadow(
            color: const Color(0x14000000),
            blurRadius: 12 * s,
            offset: Offset(0, 3 * s),
          ),
        ],
      );

  Widget _feature(double s, double center, String label) => Positioned(
        left: (center - 50) * s,
        width: 100 * s,
        top: 17 * s,
        child: Column(
          children: [
            Icon(Icons.adjust, size: 25 * s, color: kNavy),
            SizedBox(height: 9 * s),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12 * s,
                fontWeight: FontWeight.w500,
                color: kNavy,
                height: 1.0,
              ),
            ),
          ],
        ),
      );

  Widget _navItem(double s, int i, IconData icon, String label) {
    final active = _tab == i;
    final color = active ? kNavy : const Color(0xFF8A8A8A);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (i == 0) {
          setState(() => _tab = 0);
        } else if (i == 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ProdukPage()),
          );
        } else if (i == 2) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const GroomingPage()),
          );
        } else if (i == 4) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ProfilePage()),
          );
        } else {
          _soon(label);
        }
      },
      child: Padding(
        padding: EdgeInsets.only(top: 14.5 * s),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 25 * s, color: color),
            SizedBox(height: 12 * s),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11 * s,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                color: color,
                height: 1.0,
              ),
            ),
          ],
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
            // Cakar dekorasi background
            bgPaw(s, 332, 127, 31, 0.25),
            bgPaw(s, 38, 289, 27, -0.3),
            bgPaw(s, 352, 328, 27, 0.3),

            // Header: logo kecil + nama
            Positioned(
              left: 15 * s,
              top: 46.5 * s,
              child: PawLogo(width: 36 * s),
            ),
            Positioned(
              left: 53 * s,
              top: 61 * s,
              child: Text(
                'Pawtopia',
                style: GoogleFonts.poppins(
                  fontSize: 14.5 * s,
                  fontWeight: FontWeight.w700,
                  color: kNavy,
                  height: 1.0,
                ),
              ),
            ),
            Positioned(
              left: 337 * s,
              top: 48.5 * s,
              child: GestureDetector(
                onTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                ),
                child: Container(
                  width: 32 * s,
                  height: 32 * s,
                  decoration: const BoxDecoration(
                    color: kNavy,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),

            // Judul + tagline + deskripsi
            Positioned(
              left: 24 * s,
              top: 116 * s,
              child: Text(
                'Pawtopia',
                style: GoogleFonts.poppins(
                  fontSize: 42 * s,
                  fontWeight: FontWeight.w700,
                  color: kNavy,
                  height: 1.0,
                ),
              ),
            ),
            Positioned(
              left: 24 * s,
              top: 169 * s,
              child: Text(
                'Pet Care, Happy Life',
                style: GoogleFonts.poppins(
                  fontSize: 14.5 * s,
                  fontWeight: FontWeight.w600,
                  color: kNavy,
                  height: 1.0,
                ),
              ),
            ),
            Positioned(
              left: 24 * s,
              top: 195 * s,
              child: Text(
                'Semua kebutuhan hewan kesayanganmu\ndalam satu tempat!',
                style: GoogleFonts.poppins(
                  fontSize: 13 * s,
                  color: kNavy,
                  height: 1.2,
                ),
              ),
            ),

            // Tombol belanja
            Positioned(
              left: 23 * s,
              top: 240 * s,
              width: 172 * s,
              height: 42 * s,
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProdukPage()),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kNavy,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(21 * s),
                  ),
                ),
                child: Text(
                  'Belanja Sekarang',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 15 * s,
                  ),
                ),
              ),
            ),

            // Foto hewan
            Positioned(
              left: 6 * s,
              right: 8 * s,
              top: 323 * s,
              child: Image.asset(
                'assets/images/pets_group.png',
                fit: BoxFit.fitWidth,
                errorBuilder: (_, __, ___) => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'pets_group.png tidak ditemukan di assets/images/',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ),

            // Kartu 3 keunggulan
            Positioned(
              left: 24 * s,
              right: 24 * s,
              top: 492 * s,
              height: 85 * s,
              child: Container(
                decoration: _card(s),
                child: Stack(
                  children: [
                    _feature(s, 45, 'Pesan Mudah'),
                    _feature(s, 171, 'Grooming Pro'),
                    _feature(s, 296, 'Berkualitas'),
                  ],
                ),
              ),
            ),

            // Kartu pesanan & pembayaran
            Positioned(
              left: 24 * s,
              right: 24 * s,
              top: 594 * s,
              height: 150 * s,
              child: Container(
                decoration: _card(s),
                child: Stack(
                  children: [
                    Positioned(
                      left: 20 * s,
                      top: 19 * s,
                      child: Text(
                        'Pesanan & Pembayaran',
                        style: GoogleFonts.poppins(
                          fontSize: 15 * s,
                          fontWeight: FontWeight.w700,
                          color: kNavy,
                          height: 1.0,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 20 * s,
                      top: 42 * s,
                      child: Text(
                        'Lengkapi pesananmu dan lakukan pembayaran.',
                        style: GoogleFonts.poppins(
                          fontSize: 11 * s,
                          color: const Color(0xFF6E7A94),
                          height: 1.0,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 15 * s,
                      right: 15 * s,
                      top: 68 * s,
                      height: 63 * s,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16 * s),
                          border: Border.all(color: const Color(0xFFF0E6D8)),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              left: 14.5 * s,
                              top: 10 * s,
                              width: 29 * s,
                              height: 43 * s,
                              child: Image.asset(
                                'assets/images/royal_canin.png',
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const SizedBox(),
                              ),
                            ),
                            Positioned(
                              left: 60 * s,
                              top: 20 * s,
                              child: Text(
                                'Royal Canin Kitten 400gr',
                                style: GoogleFonts.poppins(
                                  fontSize: 12 * s,
                                  fontWeight: FontWeight.w500,
                                  color: kNavy,
                                  height: 1.0,
                                ),
                              ),
                            ),
                            Positioned(
                              left: 60 * s,
                              top: 39 * s,
                              child: Text(
                                'Rp95.000',
                                style: GoogleFonts.poppins(
                                  fontSize: 13 * s,
                                  fontWeight: FontWeight.w700,
                                  color: kNavy,
                                  height: 1.0,
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
            ),

            // Navigasi bawah
            Positioned(
              left: 12 * s,
              right: 12 * s,
              bottom: 39 * s,
              height: 83 * s,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28 * s),
                  border: Border.all(color: const Color(0xFFF0E6D8)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0x1A000000),
                      blurRadius: 14 * s,
                      offset: Offset(0, 3 * s),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _navItem(s, 0, Icons.home_outlined, 'Beranda'),
                    _navItem(s, 1, Icons.shopping_bag_outlined, 'Produk'),
                    _navItem(s, 2, Icons.content_cut, 'Grooming'),
                    _navItem(s, 3, Icons.shopping_basket_outlined, 'Keranjang'),
                    _navItem(s, 4, Icons.person_outline, 'Profil'),
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