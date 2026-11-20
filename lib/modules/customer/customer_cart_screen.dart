import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/cart_item_model.dart';
import '../../../services/database_service.dart';
import '../../../widgets/custom_button.dart';

class CustomerCartScreen extends StatefulWidget {
  const CustomerCartScreen({super.key});

  @override
  State<CustomerCartScreen> createState() => _CustomerCartScreenState();
}

class _CustomerCartScreenState extends State<CustomerCartScreen> {
  final DatabaseService _dbService = DatabaseService();
  final String _userId = Supabase.instance.client.auth.currentUser!.id;

  List<CartItemModel> _cartItems = [];
  bool _isLoading = true;
  bool _isCheckingOut = false;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    setState(() => _isLoading = true);
    try {
      final response = await _dbService.getDataWithJoin(
        'cart_items',
        selectQuery: '*, master_items(name, unit, image_url)',
        filterColumn: 'customer_id',
        filterValue: _userId,
      );

      _cartItems = response.map((e) => CartItemModel.fromJson(e)).toList();

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error loading cart: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _removeItem(String cartId) async {
    try {
      await _dbService.callRpc('remove_from_cart_and_release', {
        'p_cart_id': cartId,
      });
      await _loadCart();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item removed & stock released.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error removing item: $e');
    }
  }

  Future<void> _checkout() async {
    setState(() => _isCheckingOut = true);
    try {
      await _dbService.callRpc('checkout_cart', {'p_customer_id': _userId});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order placed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isCheckingOut = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Checkout failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  double get _grandTotal =>
      _cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('My Shopping Cart'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cartItems.isEmpty
          ? const Center(
              child: Text(
                'Your cart is empty.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _cartItems.length,
                    itemBuilder: (context, index) {
                      final item = _cartItems[index];
                      final hasImage =
                          item.imageUrl != null && item.imageUrl!.isNotEmpty;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green.shade50,
                            child: hasImage
                                ? ClipOval(
                                    child: Image.network(
                                      item.imageUrl!,
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.shopping_bag_outlined,
                                        color: Colors.green,
                                      ),
                                    ),
                                  )
                                : const Icon(
                                    Icons.shopping_bag_outlined,
                                    color: Colors.green,
                                  ),
                          ),
                          title: Text(
                            item.itemName ?? 'Produce',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${item.quantity} ${item.itemUnit}  ×  Rs. ${item.unitPrice}  =  Rs. ${item.totalPrice.toStringAsFixed(2)}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () => _removeItem(item.id),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Grand Total:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Rs. ${_grandTotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      CustomButton(
                        text: 'Confirm & Place Order',
                        color: Colors.green,
                        isLoading: _isCheckingOut,
                        onPressed: _checkout,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
