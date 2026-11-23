import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'main.dart';
import 'register_page.dart';
import 'home_page.dart';
import 'widgets.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _userCtrl.text.trim();
    final pass = _passCtrl.text;
    if (email.isEmpty || pass.isEmpty) {
      _pesan('Email dan password wajib diisi');
      return;
    }
    // Chrome: localhost | Emulator Android: 10.0.2.2 | HP asli: IP laptop
    final url = kIsWeb
        ? 'http://localhost/pawtopia_api/api/login.php'
        : 'http://10.0.2.2/pawtopia_api/api/login.php';
    try {
      final res = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': pass}),
      );
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        final user = data['data']; // id, name, email, phone, address
        Session.user = Map<String, dynamic>.from(user as Map);
        if (!mounted) return;
        _pesan('Selamat datang, ${user['name']}!');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      } else {
        _pesan(data['message'] ?? 'Login gagal');
      }
    } catch (e) {
      _pesan('Tidak bisa terhubung ke server');
    }
  }

  void _pesan(String teks) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(teks)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DesignCanvas(
        builder: (s, h) => Stack(
          children: [
            // Cakar dekorasi background
            bgPaw(s, 341, 67, 32, 0.3),
            bgPaw(s, 48, 196, 30, -0.3),
            bgPaw(s, 330, 258, 24, 0.3),
            bgPaw(s, 341, 637, 34, -0.2),
            bgPaw(s, 199, 698, 24, 0.1),

            // Bar navy (layer bawah)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 84 * s,
              child: Container(
                decoration: BoxDecoration(
                  color: kNavy,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(24 * s)),
                ),
              ),
            ),

            // Cakar hewan (layer atas, tidak tertutup bar navy)
            Positioned(
              left: 7 * s,
              right: 7 * s,
              bottom: 38 * s,
              child: Image.asset(
                'assets/images/paws_footer.png',
                fit: BoxFit.fitWidth,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),

            // Logo
            Positioned(
              top: 79 * s,
              left: 0,
              right: 0,
              child: Center(child: PawLogo(width: 136 * s)),
            ),

            // Judul
            Positioned(
              top: 238 * s,
              left: 0,
              right: 0,
              child: Text(
                'Welcome Back!',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 28 * s,
                  fontWeight: FontWeight.w700,
                  color: kNavy,
                  height: 1.0,
                ),
              ),
            ),

            // Subjudul
            Positioned(
              top: 282 * s,
              left: 0,
              right: 0,
              child: Text(
                'Login untuk melanjutkan\nperjalanan bersama Pawtopia',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 15 * s,
                  color: kNavy,
                  height: 1.33,
                ),
              ),
            ),

            // Input email
            Positioned(
              top: 350 * s,
              left: 24 * s,
              right: 24 * s,
              child: _Field(
                s: s,
                controller: _userCtrl,
                hint: 'Email atau Username',
              ),
            ),

            // Input password
            Positioned(
              top: 420 * s,
              left: 24 * s,
              right: 24 * s,
              child: _Field(
                s: s,
                controller: _passCtrl,
                hint: 'Password',
                obscure: true,
              ),
            ),

            // Tombol login
            Positioned(
              top: 499 * s,
              left: 24 * s,
              right: 24 * s,
              height: 50 * s,
              child: ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kNavy,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25 * s),
                  ),
                ),
                child: Text(
                  'Login',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15 * s,
                  ),
                ),
              ),
            ),

            // Link daftar
            Positioned(
              top: 573 * s,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Belum punya akun?',
                    style: GoogleFonts.poppins(
                      fontSize: 12 * s,
                      color: kNavy,
                      height: 1.0,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterPage()),
                      );
                    },
                    child: Text(
                      'Daftar di sini',
                      style: GoogleFonts.poppins(
                        fontSize: 12 * s,
                        color: const Color(0xFF2F6FD6),
                        height: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final double s;
  final TextEditingController controller;
  final String hint;
  final bool obscure;

  const _Field({
    required this.s,
    required this.controller,
    required this.hint,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56 * s,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28 * s),
        border: Border.all(color: const Color(0xFFF0E6D8)),
      ),
      child: Row(
        children: [
          SizedBox(width: 20 * s),
          Icon(Icons.adjust, size: 22 * s, color: const Color(0xFF8A8A8A)),
          SizedBox(width: 16 * s),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscure,
              style: GoogleFonts.poppins(fontSize: 14 * s, color: kNavy),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: GoogleFonts.poppins(
                  fontSize: 14 * s,
                  color: const Color(0xFF8A8A8A),
                ),
              ),
            ),
          ),
          SizedBox(width: 16 * s),
        ],
      ),
    );
  }
}
