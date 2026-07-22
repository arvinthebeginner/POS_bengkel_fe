import '../../../core/models/stok.dart';

class CartItem {
  const CartItem({required this.stok, required this.qty});

  final Stok stok;
  final int qty;

  num get subtotal => stok.harga * qty;

  CartItem copyWith({int? qty}) {
    return CartItem(stok: stok, qty: qty ?? this.qty);
  }
}
