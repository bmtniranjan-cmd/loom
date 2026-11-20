import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/master_item_model.dart';
import '../../../models/farmer_stock_model.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_dropdown.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../services/database_service.dart';

class FarmerStocksScreen extends StatefulWidget {
  const FarmerStocksScreen({super.key});

  @override
  State<FarmerStocksScreen> createState() => _FarmerStocksScreenState();
}

class _FarmerStocksScreenState extends State<FarmerStocksScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  final DatabaseService _dbService = DatabaseService();

  List<FarmerStockModel> _myStocks = [];
  List<MasterItemModel> _masterItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser!.id;

      // 1. Fetch Master Items[cite: 14]
      final masterRes = await _supabase
          .from('master_items')
          .select('*, categories(name)')
          .order('name');
      _masterItems = (masterRes as List)
          .map((e) => MasterItemModel.fromJson(e))
          .toList();

      // 2. Fetch Farmer's Stocks using Model (with item image_url)[cite: 14]
      final stockRes = await _supabase
          .from('farmer_stocks')
          .select('*, master_items(name, unit, image_url, categories(name))')
          .eq('farmer_id', userId);

      _myStocks = (stockRes as List)
          .map((e) => FarmerStockModel.fromJson(e))
          .toList();

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _confirmDeleteStock(FarmerStockModel stock) {
    if (stock.id == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Stock'),
        content: Text(
          'Are you sure you want to delete "${stock.itemName ?? 'this stock'}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              _deleteStock(stock.id!);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteStock(String stockId) async {
    try {
      await _dbService.deleteData('farmer_stocks', stockId);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stock deleted successfully!'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting stock: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Cannot delete stock because it may be in a cart or order.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showStockForm({FarmerStockModel? stockToEdit}) {
    final formKey = GlobalKey<FormState>();
    final priceController = TextEditingController(
      text: stockToEdit != null ? stockToEdit.price.toString() : '',
    );
    final qtyController = TextEditingController(
      text: stockToEdit != null ? stockToEdit.stockQuantity.toString() : '',
    );

    MasterItemModel? selectedItem;
    if (stockToEdit != null) {
      try {
        selectedItem = _masterItems.firstWhere(
          (i) => i.id == stockToEdit.itemId,
        );
      } catch (_) {}
    } else if (_masterItems.isNotEmpty) {
      selectedItem = _masterItems.first;
    }

    bool isSaving = false;

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
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stockToEdit == null
                            ? 'Add Produce Stock'
                            : 'Update Stock',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 15),

                      CustomDropdown<MasterItemModel>(
                        labelText: 'Select Produce *',
                        value: selectedItem,
                        items: _masterItems,
                        itemLabelBuilder: (item) =>
                            '${item.name} (${item.unit})',
                        prefixIcon: Icons.eco_outlined,
                        onChanged: (val) {
                          if (stockToEdit == null) {
                            setModalState(() => selectedItem = val);
                          }
                        },
                      ),
                      const SizedBox(height: 10),

                      CustomTextField(
                        controller: priceController,
                        label: 'Price per Unit (Rs) *',
                        hint: 'e.g. 350',
                        icon: Icons.attach_money,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (val) => val == null || val.trim().isEmpty
                            ? 'Enter price'
                            : null,
                      ),

                      CustomTextField(
                        controller: qtyController,
                        label: 'Available Quantity *',
                        hint: 'e.g. 50',
                        icon: Icons.scale,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (val) => val == null || val.trim().isEmpty
                            ? 'Enter quantity'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      CustomButton(
                        text: stockToEdit == null
                            ? 'Save Stock'
                            : 'Update Stock',
                        color: Colors.green,
                        isLoading: isSaving,
                        onPressed: () async {
                          if (!formKey.currentState!.validate() ||
                              selectedItem == null) {
                            return;
                          }

                          setModalState(() => isSaving = true);
                          try {
                            final userId = _supabase.auth.currentUser!.id;

                            final stockModel = FarmerStockModel(
                              farmerId: userId,
                              itemId: selectedItem!.id!,
                              price: double.parse(priceController.text.trim()),
                              stockQuantity: double.parse(
                                qtyController.text.trim(),
                              ),
                            );

                            if (stockToEdit == null) {
                              await _dbService.insertData(
                                'farmer_stocks',
                                stockModel.toJson(),
                              );
                            } else {
                              await _dbService.updateData(
                                'farmer_stocks',
                                stockToEdit.id!,
                                stockModel.toJson(),
                              );
                            }

                            if (!mounted) return;
                            final messenger = ScaffoldMessenger.of(
                              this.context,
                            );

                            if (ctx.mounted) Navigator.pop(ctx);

                            await _loadData();

                            if (mounted) {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Stock saved successfully!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (ctx.mounted) {
                              setModalState(() => isSaving = false);
                            }
                            debugPrint('Error saving stock: $e');
                          }
                        },
                      ),
                    ],
                  ),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('My Produce Stocks'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _myStocks.isEmpty
          ? const Center(child: Text('No stocks added yet. Tap + to add.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _myStocks.length,
              itemBuilder: (context, index) {
                final stock = _myStocks[index];
                final hasImage =
                    stock.imageUrl != null && stock.imageUrl!.isNotEmpty;

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
                                stock.imageUrl!,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.storefront,
                                  color: Colors.green,
                                ),
                              ),
                            )
                          : const Icon(Icons.storefront, color: Colors.green),
                    ),
                    title: Text(
                      stock.itemName ?? 'Unknown',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Rs. ${stock.price} / ${stock.itemUnit}  •  ${stock.stockQuantity} ${stock.itemUnit}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: Colors.blue,
                          ),
                          onPressed: () => _showStockForm(stockToEdit: stock),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: () => _confirmDeleteStock(stock),
                        ),
                      ],
                    ),
                    onTap: () => _showStockForm(stockToEdit: stock),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        onPressed: () => _showStockForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
