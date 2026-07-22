class Stok {
  const Stok({
    required this.id,
    required this.nama,
    required this.kategori,
    required this.harga,
    required this.stok,
  });

  final String id;
  final String nama;
  final String kategori;
  final num harga;
  final int stok;

  factory Stok.fromJson(Map<String, dynamic> json) {
    return Stok(
      id: json['_id'] as String,
      nama: json['nama'] as String,
      kategori: json['kategori'] as String,
      harga: (json['harga'] as num),
      stok: (json['stok'] as num).toInt(),
    );
  }
}
