class TransaksiItem {
  const TransaksiItem({
    required this.nama,
    required this.qty,
    required this.harga,
  });

  final String nama;
  final int qty;
  final num harga;

  num get subtotal => harga * qty;

  factory TransaksiItem.fromJson(Map<String, dynamic> json) {
    return TransaksiItem(
      nama: json['nama'] as String? ?? '-',
      qty: (json['qty'] as num?)?.toInt() ?? 0,
      harga: (json['harga'] as num?) ?? 0,
    );
  }
}

class Transaksi {
  const Transaksi({
    required this.id,
    required this.barang,
    required this.total,
    required this.tanggal,
  });

  final String id;
  final List<TransaksiItem> barang;
  final num total;
  final DateTime? tanggal;

  factory Transaksi.fromJson(Map<String, dynamic> json) {
    final rawBarang = json['barang'] as List<dynamic>? ?? [];
    return Transaksi(
      id: json['_id'] as String? ?? '',
      barang: rawBarang
          .map((item) => TransaksiItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num?) ?? 0,
      tanggal: DateTime.tryParse(json['tanggal'] as String? ?? ''),
    );
  }
}
