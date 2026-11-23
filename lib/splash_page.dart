import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart';
import 'login_page.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DesignCanvas(
        builder: (s, h) => Stack(
          children: [
            // Cakar dekorasi background
            bgPaw(s, 200, 67, 26, 0.2),
            bgPaw(s, 59, 117, 34, -0.35),
            bgPaw(s, 331, 146, 34, 0.3),
            bgPaw(s, 40, 327, 28, -0.3),
            bgPaw(s, 346, 396, 32, 0.25),
            bgPaw(s, 71, 466, 34, -0.2),
            bgPaw(s, 284, 525, 30, 0.15),

            // Bar navy bawah
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 73 * s,
              child: Container(
                decoration: BoxDecoration(
                  color: kNavy,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(24 * s)),
                ),
              ),
            ),

            // Gambar kucing & anjing (menimpa bar navy)
            Positioned(
              left: 15 * s,
              right: 15 * s,
              bottom: 46 * s,
              child: Image.asset(
                'assets/images/cat_dog.png',
                fit: BoxFit.fitWidth,
                errorBuilder: (_, __, ___) => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'cat_dog.png tidak ditemukan di assets/images/',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ),

            // Logo
            Positioned(
              top: 100 * s,
              left: 0,
              right: 0,
              child: Center(child: PawLogo(width: 175 * s)),
            ),

            // Judul
            Positioned(
              top: 294 * s,
              left: 0,
              right: 0,
              child: Text(
                'Pawtopia',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 48 * s,
                  fontWeight: FontWeight.w700,
                  color: kNavy,
                  height: 1.0,
                ),
              ),
            ),

            // Tagline
            Positioned(
              top: 359 * s,
              left: 0,
              right: 0,
              child: Text(
                'Pet Care, Happy Life',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16 * s,
                  color: kNavy,
                  height: 1.0,
                ),
              ),
            ),

            // Garis + cakar kecil
            Positioned(
              top: 386 * s,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(width: 100 * s, height: 1, color: kNavy),
                  SizedBox(width: 14 * s),
                  PawLogo(width: 22 * s),
                  SizedBox(width: 14 * s),
                  Container(width: 100 * s, height: 1, color: kNavy),
                ],
              ),
            ),

            // Tombol menuju login
            Positioned(
              top: 470 * s,
              left: 0,
              right: 0,
              child: Center(
                child: SizedBox(
                  width: 200 * s,
                  height: 48 * s,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kNavy,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      'Mulai',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 15 * s,
                      ),
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
}
