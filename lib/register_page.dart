import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'main.dart';
import 'widgets.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _hidePass = true;
  bool _hideConfirm = true;
  bool _agree = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _pesan(String teks) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(teks)));
  }

  void _keLogin() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  Future<void> _daftar() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final pass = _passCtrl.text;

    if (name.isEmpty || email.isEmpty || phone.isEmpty || pass.isEmpty) {
      _pesan('Semua kolom wajib diisi');
      return;
    }
    if (pass != _confirmCtrl.text) {
      _pesan('Konfirmasi password tidak sama');
      return;
    }
    if (!_agree) {
      _pesan('Setujui Syarat & Ketentuan dulu');
      return;
    }
    try {
      // Sesuaikan nama field dengan yang dibaca register.php kamu
      final res = await http.post(
        Uri.parse(apiUrl('register.php')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'phone': phone,
          'password': pass,
        }),
      );
      final data = jsonDecode(res.body);
      if (!mounted) return;
      if (data['success'] == true) {
        _pesan(data['message'] ?? 'Pendaftaran berhasil');
        _keLogin();
      } else {
        _pesan(data['message'] ?? 'Pendaftaran gagal');
      }
    } catch (e) {
      if (!mounted) return;
      _pesan('Tidak bisa terhubung ke server');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DesignCanvas(
        builder: (s, h) => Stack(
          children: [
            // Cakar dekorasi background
            bgPaw(s, 200, 17, 20, 0.2),
            bgPaw(s, 339, 66, 34, 0.3),
            bgPaw(s, 45, 156, 28, -0.3),
            bgPaw(s, 334, 200, 24, 0.25),
            bgPaw(s, 48, 687, 27, -0.2),
            bgPaw(s, 339, 692, 31, 0.2),

            // Bar navy (layer bawah)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 86 * s,
              child: Container(
                decoration: BoxDecoration(
                  color: kNavy,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(24 * s)),
                ),
              ),
            ),

            // Cakar hewan (layer atas)
            Positioned(
              left: 13 * s,
              right: 13 * s,
              bottom: 35 * s,
              child: Image.asset(
                'assets/images/paws_footer.png',
                fit: BoxFit.fitWidth,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),

            // Logo
            Positioned(
              top: 82 * s,
              left: 0,
              right: 0,
              child: Center(child: PawLogo(width: 79 * s)),
            ),

            // Judul
            Positioned(
              top: 184 * s,
              left: 0,
              right: 0,
              child: Text(
                'Buat Akun Baru',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 26 * s,
                  fontWeight: FontWeight.w700,
                  color: kNavy,
                  height: 1.0,
                ),
              ),
            ),

            // Subjudul
            Positioned(
              top: 219 * s,
              left: 0,
              right: 0,
              child: Text(
                'Daftar untuk mulai perjalanan bersama Pawtopia',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12 * s,
                  color: kNavy,
                  height: 1.0,
                ),
              ),
            ),

            // Kolom isian
            Positioned(
              top: 252 * s,
              left: 24 * s,
              right: 24 * s,
              child: PawField(s: s, controller: _nameCtrl, hint: 'Nama Lengkap'),
            ),
            Positioned(
              top: 318 * s,
              left: 24 * s,
              right: 24 * s,
              child: PawField(
                s: s,
                controller: _emailCtrl,
                hint: 'Email',
                keyboardType: TextInputType.emailAddress,
              ),
            ),
            Positioned(
              top: 384 * s,
              left: 24 * s,
              right: 24 * s,
              child: PawField(
                s: s,
                controller: _phoneCtrl,
                hint: 'Nomor HP',
                keyboardType: TextInputType.phone,
              ),
            ),
            Positioned(
              top: 450 * s,
              left: 24 * s,
              right: 24 * s,
              child: PawField(
                s: s,
                controller: _passCtrl,
                hint: 'Password',
                obscure: _hidePass,
                onTrailingTap: () => setState(() => _hidePass = !_hidePass),
              ),
            ),
            Positioned(
              top: 516 * s,
              left: 24 * s,
              right: 24 * s,
              child: PawField(
                s: s,
                controller: _confirmCtrl,
                hint: 'Konfirmasi Password',
                obscure: _hideConfirm,
                onTrailingTap: () =>
                    setState(() => _hideConfirm = !_hideConfirm),
              ),
            ),

            // Checkbox syarat & ketentuan
            Positioned(
              top: 587 * s,
              left: 24 * s,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _agree = !_agree),
                child: Row(
                  children: [
                    Container(
                      width: 23 * s,
                      height: 23 * s,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(5 * s),
                        border: Border.all(
                          color: const Color(0xFF2F6FD6),
                          width: 1.5,
                        ),
                      ),
                      child: _agree
                          ? Icon(
                              Icons.check,
                              size: 16 * s,
                              color: const Color(0xFF2F6FD6),
                            )
                          : null,
                    ),
                    SizedBox(width: 9 * s),
                    Text.rich(
                      TextSpan(
                        style: GoogleFonts.poppins(
                          fontSize: 12 * s,
                          color: kNavy,
                          height: 1.0,
                        ),
                        children: const [
                          TextSpan(text: 'Saya setuju dengan '),
                          TextSpan(
                            text: 'Syarat & Ketentuan',
                            style: TextStyle(color: Color(0xFF2F6FD6)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Tombol daftar
            Positioned(
              top: 628 * s,
              left: 24 * s,
              right: 24 * s,
              height: 50 * s,
              child: ElevatedButton(
                onPressed: _daftar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kNavy,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25 * s),
                  ),
                ),
                child: Text(
                  'Daftar',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15 * s,
                  ),
                ),
              ),
            ),

            // Link masuk
            Positioned(
              top: 701 * s,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Sudah punya akun?',
                    style: GoogleFonts.poppins(
                      fontSize: 12 * s,
                      color: kNavy,
                      height: 1.0,
                    ),
                  ),
                  GestureDetector(
                    onTap: _keLogin,
                    child: Text(
                      'Masuk di sini',
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

            // Tombol kembali (lapisan paling atas)
            Positioned(
              top: 51 * s,
              left: 12 * s,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _keLogin,
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