import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/database_service.dart';
import '../../../widgets/custom_button.dart';

class FarmerBulkOrdersScreen extends StatefulWidget {
  const FarmerBulkOrdersScreen({super.key});

  @override
  State<FarmerBulkOrdersScreen> createState() => _FarmerBulkOrdersScreenState();
}

class _FarmerBulkOrdersScreenState extends State<FarmerBulkOrdersScreen> {
  final DatabaseService _dbService = DatabaseService();
  final String _farmerId = Supabase.instance.client.auth.currentUser!.id;

  List _bulkOrders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBulkOrders();
  }

  Future<void> _loadBulkOrders() async {
    setState(() => _isLoading = true);
    try {
      final response = await _dbService.getDataWithQuery(
        'farmer_bulk_orders',
        column: 'farmer_id',
        value: _farmerId,
      );

      _bulkOrders = List.from(response);
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error loading bulk orders: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsReady(String itemId) async {
    try {
      await _dbService.callRpc('update_farmer_bulk_order_status', {
        'p_farmer_id': _farmerId,
        'p_item_id': itemId,
        'p_new_status': 'Ready',
      });

      await _loadBulkOrders();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order marked as Ready!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Incoming Bulk Orders'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bulkOrders.isEmpty
          ? const Center(
              child: Text(
                'No incoming orders right now.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _bulkOrders.length,
              itemBuilder: (context, index) {
                final order = _bulkOrders[index];
                final itemName = order['item_name'] ?? 'Item';
                final unit = order['item_unit'] ?? 'kg';
                final totalQty = order['total_quantity'];
                final totalRevenue = order['total_revenue'];
                //final orderCount = order['total_orders_count'];
                final itemId = order['item_id'];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              itemName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              // child: Text(
                              //   '$orderCount Orders',
                              //   style: const TextStyle(
                              //     color: Colors.green,
                              //     fontWeight: FontWeight.bold,
                              //     fontSize: 12,
                              //   ),
                              // ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Total Quantity Required: $totalQty $unit',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Total Revenue: Rs. $totalRevenue',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: CustomButton(
                            text: 'Mark as Ready',
                            color: Colors.green,
                            onPressed: () => _markAsReady(itemId),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
