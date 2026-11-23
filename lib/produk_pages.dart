import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'main.dart';
import 'widgets.dart';
import 'home_page.dart';
import 'grooming_pages.dart';
import 'profile_page.dart';

const Color _line = Color(0xFFF0E6D8);
const Color _grey = Color(0xFF8A8A8A);
const Color _blue = Color(0xFF2F6FD6);

TextStyle _p(
  double size, {
  FontWeight w = FontWeight.w400,
  Color c = kNavy,
  double h = 1.0,
}) =>
    GoogleFonts.poppins(fontSize: size, fontWeight: w, color: c, height: h);

BoxDecoration _card(double s, {double r = 22}) => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(r * s),
      border: Border.all(color: _line),
    );

// ---------------------------------------------------------------------------
// Data produk
// ---------------------------------------------------------------------------

class Product {
  final int? id;
  final String name;
  final String weight;
  final int price;
  final String asset; // gambar bawaan di aplikasi (boleh kosong)
  final String imageUrl; // gambar dari server (boleh kosong)
  final String animal; // Anjing / Kucing / Semua
  final String category;
  final int? stock;

  const Product(
    this.name,
    this.weight,
    this.price,
    this.asset,
    this.animal, {
    this.id,
    this.imageUrl = '',
    this.category = 'Makanan',
    this.stock,
  });

  /// Dari balasan products.php (id, category_id, name, description, price,
  /// image, stock, category_name).
  factory Product.fromJson(Map<String, dynamic> m) {
    final name = (m['name'] ?? m['product_name'] ?? '').toString();
    final desc = (m['description'] ?? '').toString();
    final text = '$name $desc'.toLowerCase();

    final isCat = RegExp(r'\b(kucing|cat|kitten|whiskas|me-o|meo|choize)\b')
        .hasMatch(text);
    final isDog = RegExp(r'\b(anjing|dog|puppy|pedigree|bolt|pro ?plan)\b')
        .hasMatch(text);
    final animal = (isCat && !isDog)
        ? 'Kucing'
        : (isDog && !isCat)
            ? 'Anjing'
            : 'Semua';

    final w = RegExp(r'(\d+(?:[.,]\d+)?)\s?(kg|gr|g)\b', caseSensitive: false);
    final wm = w.firstMatch(name) ?? w.firstMatch(desc);
    final weight = wm == null ? '' : wm.group(0)!.replaceAll(' ', '');

    final cat = (m['category_name'] ?? '').toString();
    return Product(
      name,
      weight,
      int.tryParse('${m['price'] ?? 0}'.split('.').first) ?? 0,
      _assetFor(name),
      animal,
      id: int.tryParse('${m['id']}'),
      imageUrl: _imageUrl((m['image'] ?? '').toString()),
      category: cat.isEmpty ? 'Makanan' : cat,
      stock: int.tryParse('${m['stock']}'),
    );
  }
}

/// Mencocokkan nama produk dengan foto yang sudah ada di assets/images.
String _assetFor(String name) {
  final n = name.toLowerCase();
  const map = [
    ['pedigree', 'pedigree_adult'],
    ['puppy', 'royal_canin_puppy'],
    ['kitten', 'royal_canin_kitten'],
    ['pro plan', 'pro_plan_adult'],
    ['proplan', 'pro_plan_adult'],
    ['bolt', 'bolt_dog_food'],
    ['whiskas', 'whiskas_tuna'],
    ['me-o', 'meo_salmon'],
    ['meo', 'meo_salmon'],
    ['choize', 'cat_choize'],
  ];
  for (final e in map) {
    if (n.contains(e[0])) return 'assets/images/${e[1]}.png';
  }
  return '';
}

/// Alamat gambar dari kolom image di database.
String _imageUrl(String img) {
  if (img.isEmpty) return '';
  if (img.startsWith('http')) return img;
  final base = apiUrl('x.php').replaceFirst('/api/x.php', '');
  final path = img.contains('/') ? img : 'uploads/$img';
  return '$base/${path.startsWith('/') ? path.substring(1) : path}';
}

/// Produk contoh, dipakai kalau data dari server belum bisa dimuat.
const List<Product> kProducts = [
  Product('Pedigree Adult Beef', '1,5kg', 89000,
      'assets/images/pedigree_adult.png', 'Anjing'),
  Product('Royal Canin Puppy', '1kg', 135000,
      'assets/images/royal_canin_puppy.png', 'Anjing'),
  Product('Pro Plan Adult', '2,5kg', 210000,
      'assets/images/pro_plan_adult.png', 'Anjing'),
  Product('Bolt Dog Food', '1kg', 45000,
      'assets/images/bolt_dog_food.png', 'Anjing'),
  Product('Royal Canin Kitten', '400gr', 95000,
      'assets/images/royal_canin_kitten.png', 'Kucing'),
  Product('Whiskas Tuna', '1kg', 68000,
      'assets/images/whiskas_tuna.png', 'Kucing'),
  Product('Me-O Salmon', '1,2kg', 72000,
      'assets/images/meo_salmon.png', 'Kucing'),
  Product('Cat Choize Adult', '800gr', 55000,
      'assets/images/cat_choize.png', 'Kucing'),
];

/// Keranjang sederhana (disimpan di aplikasi selama aplikasi terbuka).
class Cart {
  static final Map<String, int> items = {};
  static void add(Product p) => items[p.name] = (items[p.name] ?? 0) + 1;
  static int get count => items.values.fold(0, (a, b) => a + b);
}

Future<Map<String, dynamic>> _apiGet(String file) async {
  try {
    final res = await http.get(Uri.parse(apiUrl(file)));
    try {
      return Map<String, dynamic>.from(jsonDecode(res.body) as Map);
    } catch (_) {
      final isi = res.body.length > 120 ? res.body.substring(0, 120) : res.body;
      return {'success': false, 'message': 'Balasan server tidak dikenali: $isi'};
    }
  } catch (e) {
    return {'success': false, 'message': 'Tidak bisa terhubung ke server'};
  }
}

// ---------------------------------------------------------------------------
// Halaman produk
// ---------------------------------------------------------------------------

class ProdukPage extends StatefulWidget {
  final String initialAnimal; // Semua / Kucing / Anjing
  const ProdukPage({super.key, this.initialAnimal = 'Semua'});

  @override
  State<ProdukPage> createState() => _ProdukPageState();
}

class _ProdukPageState extends State<ProdukPage> {
  final _search = TextEditingController();
  late String _animal;
  String _cat = 'Makanan';
  List<String> _cats = ['Makanan', 'Pakaian', 'Mainan', 'Tempat Tidur'];
  List<Product> _all = kProducts;
  String _note = '';

  @override
  void initState() {
    super.initState();
    _animal = widget.initialAnimal;
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final cats = await _apiGet('categories.php');
    final prods = await _apiGet('products.php');
    if (!mounted) return;
    setState(() {
      if (cats['success'] == true && cats['data'] is List) {
        final names = (cats['data'] as List)
            .map((r) {
              final m = r as Map;
              return (m['name'] ?? m['category_name'] ?? '').toString();
            })
            .where((e) => e.isNotEmpty)
            .toList();
        if (names.isNotEmpty) {
          _cats = names;
          if (!_cats.contains(_cat)) _cat = _cats.first;
        }
      }
      if (prods['success'] == true && prods['data'] is List) {
        final list = (prods['data'] as List)
            .map((r) => Product.fromJson(Map<String, dynamic>.from(r as Map)))
            .toList();
        if (list.isNotEmpty) {
          _all = list;
          _note = '';
        } else {
          _note = 'Belum ada produk di database, menampilkan produk contoh.';
        }
      } else {
        _note = '${prods['message'] ?? 'Gagal memuat produk'}. Menampilkan produk contoh.';
      }
    });
  }

  void _snack(String teks) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(teks)));
  }

  List<Product> get _list {
    final q = _search.text.trim().toLowerCase();
    return _all
        .where((p) =>
            p.category.toLowerCase() == _cat.toLowerCase() &&
            (_animal == 'Semua' || p.animal == 'Semua' || p.animal == _animal) &&
            (q.isEmpty || p.name.toLowerCase().contains(q)))
        .toList();
  }

  bool get _isFood => _cat.toLowerCase().startsWith('makanan');

  String get _title => _animal == 'Semua' ? '$_cat Hewan' : '$_cat $_animal';

  void _keBeranda() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
      (route) => false,
    );
  }

  Widget _chip(
    double s,
    String text,
    double width,
    bool selected,
    VoidCallback onTap,
  ) =>
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: width * s,
          height: 33 * s,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? kNavy : Colors.white,
            borderRadius: BorderRadius.circular(17 * s),
            border: Border.all(color: selected ? kNavy : _line),
          ),
          child: Text(
            text,
            style: _p(
              12.5 * s,
              w: selected ? FontWeight.w700 : FontWeight.w400,
              c: selected ? Colors.white : kNavy,
            ),
          ),
        ),
      );

  Widget _catChip(double s, String name) {
    final selected = _cat == name;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _cat = name),
      child: Container(
        height: 33 * s,
        padding: EdgeInsets.symmetric(horizontal: 16.5 * s),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? kNavy : Colors.white,
          borderRadius: BorderRadius.circular(17 * s),
          border: Border.all(color: selected ? kNavy : _line),
        ),
        child: Text(
          name,
          style: _p(
            12.5 * s,
            w: selected ? FontWeight.w700 : FontWeight.w400,
            c: selected ? Colors.white : kNavy,
          ),
        ),
      ),
    );
  }

  Widget _searchBar(double s) => Container(
        height: 47.7 * s,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24 * s),
          border: Border.all(color: _line),
        ),
        child: Row(
          children: [
            SizedBox(width: 15 * s),
            Icon(Icons.adjust, size: 25 * s, color: _grey),
            SizedBox(width: 13 * s),
            Expanded(
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                style: _p(14 * s),
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText:
                      'Cari ${_cat.toLowerCase()} ${_animal == 'Semua' ? 'hewan' : _animal.toLowerCase()}...',
                  hintStyle: _p(14 * s, c: _grey),
                ),
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _snack('Filter belum tersedia'),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 13.5 * s),
                child: Icon(Icons.adjust, size: 25 * s, color: kNavy),
              ),
            ),
          ],
        ),
      );

  Widget _banner(double s) {
    final cat = _animal == 'Kucing';
    final sub = _isFood
        ? (cat
            ? 'Nutrisi lengkap untuk\nsi manis berbulu'
            : 'Nutrisi lengkap untuk\nsi kecil berbulu')
        : (cat
            ? 'Pilihan terbaik untuk\nsi manis berbulu'
            : 'Pilihan terbaik untuk\nsi kecil berbulu');
    return Container(
      height: 111.6 * s,
      decoration: _card(s),
      child: Stack(
        children: [
          if (_isFood)
            Positioned(
              right: (cat ? 7 : 8) * s,
              top: (cat ? 5.6 : 3.2) * s,
              child: Image.asset(
                cat ? 'assets/images/food_cat.png' : 'assets/images/food_dog.png',
                height: (cat ? 98 : 100.3) * s,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),
          Positioned(
            left: 16.2 * s,
            top: 13.6 * s,
            child: Container(
              height: 22.6 * s,
              padding: EdgeInsets.symmetric(horizontal: 10 * s),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFD3E2F9),
                borderRadius: BorderRadius.circular(12 * s),
              ),
              child: Text(
                'Promo Spesial',
                style: _p(9.5 * s, w: FontWeight.w700),
              ),
            ),
          ),
          Positioned(
            left: 16.2 * s,
            top: 48.6 * s,
            child: Text(_title, style: _p(17.5 * s, w: FontWeight.w700)),
          ),
          Positioned(
            left: 16.2 * s,
            top: 70.4 * s,
            child: Text(sub, style: _p(10.5 * s, h: 1.55)),
          ),
        ],
      ),
    );
  }

  Widget _productImage(double s, Product p) {
    final fallback = Icon(Icons.pets, size: 34 * s, color: kPawLight);
    if (p.asset.isNotEmpty) {
      return Image.asset(
        p.asset,
        height: 68 * s,
        width: 100 * s,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => fallback,
      );
    }
    if (p.imageUrl.isNotEmpty) {
      return Image.network(
        p.imageUrl,
        height: 68 * s,
        width: 100 * s,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => fallback,
      );
    }
    return fallback;
  }

  Widget _productCard(double s, double w, Product p) {
    final habis = p.stock != null && p.stock! <= 0;
    final sub = p.weight.isNotEmpty
        ? p.weight
        : (p.stock == null ? '' : (habis ? 'Stok habis' : 'Stok ${p.stock}'));
    return Container(
      width: w,
      height: 169 * s,
      decoration: _card(s, r: 20),
      child: Stack(
        children: [
          Positioned(
            top: 13 * s,
            left: 0,
            right: 0,
            height: 68 * s,
            child: Center(child: _productImage(s, p)),
          ),
          Positioned(
            left: 11.4 * s,
            right: 8 * s,
            top: 91 * s,
            child: Text(
              p.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _p(11.5 * s),
            ),
          ),
          Positioned(
            left: 11.4 * s,
            top: 108.8 * s,
            child: Text(sub, style: _p(10 * s, c: _grey)),
          ),
          Positioned(
            left: 11.4 * s,
            top: 139.8 * s,
            child: Text(
              rupiah(p.price),
              style: _p(14 * s, w: FontWeight.w700),
            ),
          ),
          Positioned(
            right: 7.6 * s,
            bottom: 10.8 * s,
            child: GestureDetector(
              onTap: () {
                if (habis) {
                  _snack('Stok ${p.name} habis');
                  return;
                }
                Cart.add(p);
                _snack('${p.name} ditambahkan ke keranjang');
              },
              child: Container(
                width: 32.5 * s,
                height: 32.5 * s,
                decoration: BoxDecoration(
                  color: habis ? const Color(0xFFB5BDCC) : kNavy,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.add, size: 19 * s, color: Colors.white),
              ),
            ),
          ),
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
          final cardW = (c.maxWidth - (48.8 + 16.8) * s) / 2;
          final items = _list;
          return Stack(
            children: [
              bgPaw(s, 345.6, 66, 32, 0.2),
              Positioned(
                left: 0,
                right: 0,
                top: 96 * s,
                bottom: 0,
                child: ListView(
                  padding: EdgeInsets.fromLTRB(24.4 * s, 3 * s, 24.4 * s, 110 * s),
                  children: [
                    _searchBar(s),
                    SizedBox(height: 14 * s),

                    // Kategori (dari categories.php)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (int i = 0; i < _cats.length; i++) ...[
                            if (i > 0) SizedBox(width: 6.3 * s),
                            _catChip(s, _cats[i]),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(height: 9.6 * s),

                    // Jenis hewan
                    Row(
                      children: [
                        _chip(s, 'Semua', 79, _animal == 'Semua',
                            () => setState(() => _animal = 'Semua')),
                        SizedBox(width: 8.5 * s),
                        _chip(s, 'Kucing', 79, _animal == 'Kucing',
                            () => setState(() => _animal = 'Kucing')),
                        SizedBox(width: 8.5 * s),
                        _chip(s, 'Anjing', 80.6, _animal == 'Anjing',
                            () => setState(() => _animal = 'Anjing')),
                      ],
                    ),
                    SizedBox(height: 14.7 * s),

                    _banner(s),
                    SizedBox(height: 22.3 * s),

                    // Pilihan terbaik
                    Row(
                      children: [
                        Text(
                          'Pilihan Terbaik',
                          style: _p(16 * s, w: FontWeight.w700),
                        ),
                        SizedBox(width: 33 * s),
                        PawLogo(width: 22 * s, color: kPawLight, angle: 0.1),
                        const Spacer(),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => setState(() {
                            _animal = 'Semua';
                            _search.clear();
                          }),
                          child: Text(
                            'Lihat Semua',
                            style: _p(12 * s, c: _blue),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.5 * s),

                    if (_note.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(bottom: 8 * s),
                        child: Text(
                          _note,
                          style: _p(10 * s, c: _grey, h: 1.4),
                        ),
                      ),

                    if (items.isEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 40 * s),
                        child: Center(
                          child: Text(
                            'Produk tidak ditemukan',
                            style: _p(13 * s, c: _grey),
                          ),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 16.8 * s,
                        runSpacing: 11.3 * s,
                        children: [
                          for (final p in items) _productCard(s, cardW, p),
                        ],
                      ),
                  ],
                ),
              ),
              Positioned(
                top: 68 * s,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Text(
                    _title,
                    textAlign: TextAlign.center,
                    style: _p(18 * s, w: FontWeight.w700),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: PawBottomNav(
                  s: s,
                  active: 1,
                  onTap: (i) {
                    if (i == 0) {
                      _keBeranda();
                    } else if (i == 2) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const GroomingPage()),
                        (route) => false,
                      );
                    } else if (i == 4) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfilePage()),
                        (route) => false,
                      );
                    } else if (i == 3) {
                      _snack(
                        Cart.count == 0
                            ? 'Keranjang masih kosong'
                            : 'Halaman Keranjang belum tersedia (${Cart.count} produk)',
                      );
                    }
                  },
                ),
              ),
              Positioned(
                top: 51 * s,
                left: 10 * s,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _keBeranda,
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