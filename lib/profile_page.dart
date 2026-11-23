import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart';
import 'widgets.dart';
import 'home_page.dart';
import 'grooming_pages.dart';
import 'login_page.dart';
import 'account_pages.dart';
import 'produk_pages.dart';

const Color _line = Color(0xFFF0E6D8);
const Color _grey = Color(0xFF8A8A8A);

TextStyle _p(
  double size, {
  FontWeight w = FontWeight.w400,
  Color c = kNavy,
}) =>
    GoogleFonts.poppins(fontSize: size, fontWeight: w, color: c, height: 1.0);

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {

  static const _menu = [
    'Profil Saya',
    'Pesanan Saya',
    'Alamat Saya',
    'Pengaturan Akun',
    'Bantuan & FAQ',
    'Tentang Pawtopia',
  ];

  void _snack(BuildContext context, String teks) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(teks)));
  }

  void _onMenu(BuildContext context, int i) {
    final Widget page;
    switch (i) {
      case 0:
        page = const ProfilDetailPage();
        break;
      case 1:
        page = const JadwalBookingPage();
        break;
      case 2:
        page = const AlamatPage();
        break;
      case 3:
        page = const PengaturanPage();
        break;
      case 4:
        page = const BantuanPage();
        break;
      default:
        page = const TentangPage();
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => page)).then((_) {
      if (mounted) setState(() {});
    });
  }

  void _logout(BuildContext context) {
    Session.clear();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DesignCanvas(
        builder: (s, h) => Stack(
          children: [
            // Cakar dekorasi background
            bgPaw(s, 342, 127, 36, 0.25),
            bgPaw(s, 48, 176, 32, -0.3),
            bgPaw(s, 341, 257.5, 26, 0.3),
            bgPaw(s, 49.6, 597, 27, -0.2),
            bgPaw(s, 347, 688.5, 32, 0.2),

            // Header kecil
            Positioned(
              left: 16.4 * s,
              top: 46.4 * s,
              child: PawLogo(width: 36 * s),
            ),
            Positioned(
              left: 52.4 * s,
              top: 59 * s,
              child: Text('Profil', style: _p(16 * s, w: FontWeight.w700)),
            ),

            // Avatar
            Positioned(
              left: 143.5 * s,
              top: 98.2 * s,
              width: 104.7 * s,
              height: 104.7 * s,
              child: Container(
                padding: EdgeInsets.all(3.5 * s),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1E3C8),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Transform.translate(
                    offset: Offset(0, -4 * s),
                    child: PawLogo(
                      width: 62 * s,
                      color: const Color(0xFFE3CCA3),
                    ),
                  ),
                ),
              ),
            ),

            // Nama & email pengguna yang login
            Positioned(
              top: 224.5 * s,
              left: 24 * s,
              right: 24 * s,
              child: Text(
                Session.name,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: _p(18 * s, w: FontWeight.w700),
              ),
            ),
            Positioned(
              top: 248.6 * s,
              left: 24 * s,
              right: 24 * s,
              child: Text(
                Session.email,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: _p(14.5 * s),
              ),
            ),

            // Kartu menu
            Positioned(
              left: 24 * s,
              right: 24 * s,
              top: 282 * s,
              height: 300 * s,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24 * s),
                  border: Border.all(color: _line),
                ),
                child: Stack(
                  children: [
                    for (int i = 0; i < _menu.length; i++)
                      Positioned(
                        left: 0,
                        right: 0,
                        top: (9.3 + i * 48) * s,
                        height: 48 * s,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _onMenu(context, i),
                          child: Row(
                            children: [
                              SizedBox(width: 18 * s),
                              Icon(Icons.adjust, size: 24 * s, color: kNavy),
                              SizedBox(width: 16 * s),
                              Expanded(
                                child: Text(_menu[i], style: _p(14 * s)),
                              ),
                              Icon(
                                Icons.chevron_right,
                                size: 20 * s,
                                color: kNavy,
                              ),
                              SizedBox(width: 18 * s),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Tombol logout
            Positioned(
              left: 24 * s,
              right: 24 * s,
              top: 610.5 * s,
              height: 46.3 * s,
              child: OutlinedButton(
                onPressed: () => _logout(context),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: kNavy,
                  side: const BorderSide(color: kNavy, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24 * s),
                  ),
                ),
                child: Text(
                  'Logout',
                  style: _p(14.5 * s, w: FontWeight.w700),
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
                active: 4,
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
                  } else if (i == 2) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const GroomingPage()),
                    );
                  } else if (i != 4) {
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