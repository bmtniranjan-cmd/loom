import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/farmer_stock_model.dart';
import '../../../services/database_service.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';
import 'customer_cart_screen.dart';

class CustomerStocksScreen extends StatefulWidget {
  const CustomerStocksScreen({super.key});

  @override
  State<CustomerStocksScreen> createState() => _CustomerStocksScreenState();
}

class _CustomerStocksScreenState extends State<CustomerStocksScreen> {
  final DatabaseService _dbService = DatabaseService();
  final String _userId = Supabase.instance.client.auth.currentUser!.id;

  List<FarmerStockModel> _allStocks = [];
  int _cartCount = 0;
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Farmer price + 15% -> Round up to nearest 10 (ends with 0)
  double _getCustomerPrice(double farmerPrice) {
    final withMarkup = farmerPrice * 1.15;
    return (withMarkup / 10).ceil() * 10.0;
  }

  String _formatPrice(double price) {
    if (price == price.roundToDouble()) {
      return price.toInt().toString();
    }
    return price.toStringAsFixed(2);
  }

  bool _isKgUnit(FarmerStockModel stock) {
    return (stock.itemUnit ?? '').trim().toLowerCase() == 'kg';
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // 1. සියලුම ස්ටොක්ස් ලබා ගැනීම (with item image_url)[cite: 11]
      final response = await _dbService.getDataWithJoin(
        'farmer_stocks',
        selectQuery: '*, master_items(name, unit, image_url, categories(name))',
        filterColumn: 'is_available',
        filterValue: true,
      );

      _allStocks = response.map((e) => FarmerStockModel.fromJson(e)).toList();
      _allStocks.sort((a, b) => (a.itemName ?? '').compareTo(b.itemName ?? ''));

      // 2. Cart එකේ ඇති අයිතම ගණන ලබා ගැනීම[cite: 11]
      final cartRes = await _dbService.getDataWithQuery(
        'cart_items',
        column: 'customer_id',
        value: _userId,
      );
      _cartCount = cartRes.length;

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error loading data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Cart එකට එකතු කිරීමේ Bottom Sheet එක (kg items සඳහා gram input සහාය සමඟ)[cite: 11]
  void _showAddToCartSheet(FarmerStockModel stock) {
    final isKg = _isKgUnit(stock);
    final qtyController = TextEditingController(text: isKg ? '500' : '1');
    final formKey = GlobalKey<FormState>();
    final customerPrice = _getCustomerPrice(stock.price);
    final maxGrams = (stock.stockQuantity * 1000).round();
    bool isAdding = false;
    final defaultQtyText = isKg ? '500' : '1';

    qtyController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: defaultQtyText.length,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final enteredQty = double.tryParse(qtyController.text.trim()) ?? 0;
            final qtyInStockUnit = isKg && enteredQty > 0
                ? enteredQty / 1000.0
                : enteredQty;
            final estimatedCost = qtyInStockUnit * customerPrice;

            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add ${stock.itemName ?? 'Item'} to Cart',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Price: Rs. ${_formatPrice(customerPrice)} / ${stock.itemUnit}  •  Available: ${stock.stockQuantity} ${stock.itemUnit}${isKg ? ' (${maxGrams}g)' : ''}',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 15),

                    CustomTextField(
                      controller: qtyController,
                      label: isKg
                          ? 'Quantity (g) *'
                          : 'Quantity (${stock.itemUnit}) *',
                      hint: isKg ? 'e.g. 500' : 'e.g. 2',
                      icon: Icons.scale,
                      autofocus: true,
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: !isKg,
                      ),
                      onChanged: (_) => setModalState(() {}),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Enter quantity';
                        }
                        final qty = double.tryParse(val);
                        if (qty == null || qty <= 0) {
                          return 'Enter valid quantity';
                        }
                        final neededInStockUnit = isKg ? qty / 1000.0 : qty;
                        if (neededInStockUnit > stock.stockQuantity) {
                          return isKg
                              ? 'Only ${stock.stockQuantity} ${stock.itemUnit} (${maxGrams}g) available'
                              : 'Only ${stock.stockQuantity} ${stock.itemUnit} available';
                        }
                        return null;
                      },
                    ),

                    if (enteredQty > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Estimated Price: Rs. ${_formatPrice(estimatedCost)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    CustomButton(
                      text: 'Add to Cart',
                      color: Colors.green,
                      isLoading: isAdding,
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;

                        setModalState(() => isAdding = true);
                        try {
                          final rawQty = double.parse(
                            qtyController.text.trim(),
                          );
                          final qtyToReserve = isKg ? rawQty / 1000.0 : rawQty;

                          // RPC හරහා Cart එකට දමා Stock එක Reserve කිරීම[cite: 11]
                          await _dbService.callRpc('add_to_cart_with_reserve', {
                            'p_customer_id': _userId,
                            'p_stock_id': stock.id!,
                            'p_quantity': qtyToReserve,
                          });

                          if (ctx.mounted) Navigator.pop(ctx);
                          await _loadData();

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Added to cart & stock reserved!',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (ctx.mounted) {
                            setModalState(() => isAdding = false);
                          }
                          debugPrint('Error adding to cart: $e');
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredStocks = _allStocks.where((stock) {
      final name = stock.itemName?.toLowerCase() ?? '';
      final category = stock.categoryName?.toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || category.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Fresh Produce Market'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          // Cart Icon with Badge Counter[cite: 11]
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CustomerCartScreen(),
                    ),
                  );
                  _loadData(); // Cart එකෙන් ආපසු එන විට දත්ත යාවත්කාලීන කරගැනීමට[cite: 11]
                },
              ),
              if (_cartCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$_cartCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search vegetables...',
                prefixIcon: const Icon(Icons.search, color: Colors.green),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
              ),
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredStocks.isEmpty
                ? const Center(
                    child: Text(
                      'No produce available right now.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.2,
                        ),
                    itemCount: filteredStocks.length,
                    itemBuilder: (context, index) {
                      final stock = filteredStocks[index];
                      final isOutOfStock = stock.stockQuantity <= 0;
                      final displayPrice = _getCustomerPrice(stock.price);
                      final hasImage =
                          stock.imageUrl != null && stock.imageUrl!.isNotEmpty;

                      return Card(
                        elevation: 1.5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        color: isOutOfStock
                            ? Colors.grey.shade100
                            : Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // උඩින්: Square Image (වම් පැත්තේ) + Price & Stock (දකුණු පැත්තේ)[cite: 11]
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 55,
                                    height: 55,
                                    decoration: BoxDecoration(
                                      color: isOutOfStock
                                          ? Colors.grey.shade200
                                          : Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: hasImage
                                        ? Image.network(
                                            stock.imageUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Icon(
                                              Icons.eco,
                                              color: isOutOfStock
                                                  ? Colors.grey
                                                  : Colors.green,
                                              size: 28,
                                            ),
                                          )
                                        : Icon(
                                            Icons.eco,
                                            color: isOutOfStock
                                                ? Colors.grey
                                                : Colors.green,
                                            size: 28,
                                          ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Rs. ${_formatPrice(displayPrice)}/${stock.itemUnit}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: isOutOfStock
                                                ? Colors.grey
                                                : Colors.green,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          isOutOfStock
                                              ? 'Sold Out'
                                              : 'Stock: ${stock.stockQuantity} ${stock.itemUnit}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isOutOfStock
                                                ? Colors.red
                                                : Colors.grey.shade600,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              // මුළු Card එකේම width එක දිගේ Item Name එක[cite: 11]
                              Text(
                                stock.itemName ?? 'Produce',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isOutOfStock
                                      ? Colors.grey
                                      : const Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),

                              // යටින්: Add to Cart Button[cite: 11]
                              SizedBox(
                                width: double.infinity,
                                height: 32,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isOutOfStock
                                        ? Colors.grey.shade300
                                        : Colors.green,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                  onPressed: isOutOfStock
                                      ? null
                                      : () => _showAddToCartSheet(stock),
                                  child: Text(
                                    isOutOfStock
                                        ? 'Out of Stock'
                                        : 'Add to Cart',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
