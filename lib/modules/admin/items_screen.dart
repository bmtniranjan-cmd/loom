import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:loom/models/category_model.dart';
import 'package:loom/models/master_item_model.dart';
import 'package:loom/widgets/custom_button.dart';
import 'package:loom/widgets/custom_dropdown.dart';
import 'package:loom/widgets/custom_text_field.dart';

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  List<CategoryModel> _categories = [];
  List<MasterItemModel> _itemsList = [];
  bool _isLoadingData = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  // 1. ඩේටා ලෝඩ් කරගැනීම[cite: 11]
  Future<void> _loadInitialData() async {
    setState(() => _isLoadingData = true);
    try {
      final catResponse = await _supabase
          .from('categories')
          .select()
          .order('name', ascending: true);

      _categories = (catResponse as List)
          .map((e) => CategoryModel.fromJson(e))
          .toList();

      final itemsResponse = await _supabase
          .from('master_items')
          .select('*, categories(name)')
          .order('created_at', ascending: false);

      _itemsList = (itemsResponse as List)
          .map((e) => MasterItemModel.fromJson(e))
          .toList();

      if (mounted) {
        setState(() => _isLoadingData = false);
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  // Image එක Supabase Storage එකට upload කර public URL ලබා ගැනීම
  Future<String?> _uploadItemImage(File imageFile) async {
    final ext = imageFile.path.split('.').last.toLowerCase();
    final fileExt = ext.isEmpty ? 'jpg' : ext;
    final fileName = 'item_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    final filePath = 'items/$fileName';

    await _supabase.storage
        .from('item-images')
        .upload(
          filePath,
          imageFile,
          fileOptions: const FileOptions(upsert: true),
        );

    return _supabase.storage.from('item-images').getPublicUrl(filePath);
  }

  // 2. අලුතින් අයිතමයක් එකතු කිරීමට හෝ එඩිට් කිරීමට Bottom Sheet එක පෙන්වීම[cite: 11]
  void _showItemForm({MasterItemModel? itemToEdit}) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: itemToEdit?.name ?? '');

    CategoryModel? selectedCategory;
    if (itemToEdit != null) {
      try {
        selectedCategory = _categories.firstWhere(
          (cat) => cat.id == itemToEdit.categoryId,
        );
      } catch (e) {
        selectedCategory = _categories.isNotEmpty ? _categories.first : null;
      }
    } else if (_categories.isNotEmpty) {
      selectedCategory = _categories.first;
    }

    String selectedUnit = itemToEdit?.unit ?? 'kg';
    final List<String> units = ['kg', 'g', 'pcs', 'packet'];
    File? pickedImageFile;
    String? existingImageUrl = itemToEdit?.imageUrl;
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
            Future<void> pickImage() async {
              final XFile? picked = await _picker.pickImage(
                source: ImageSource.gallery,
                maxWidth: 256,
                maxHeight: 256,
                imageQuality: 75,
              );
              if (picked != null) {
                setModalState(() {
                  pickedImageFile = File(picked.path);
                });
              }
            }

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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            itemToEdit == null
                                ? 'Register New Item'
                                : 'Edit Item',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),

                      // Category Dropdown + Add Category Button[cite: 11]
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: CustomDropdown<CategoryModel>(
                              labelText: 'Category *',
                              value: selectedCategory,
                              items: _categories,
                              itemLabelBuilder: (cat) => cat.name,
                              prefixIcon: Icons.category_outlined,
                              onChanged: (val) {
                                setModalState(() => selectedCategory = val);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: IconButton.filled(
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              tooltip: 'Add Category',
                              onPressed: () {
                                Navigator.pop(ctx);
                                _showAddCategoryDialog();
                              },
                              icon: const Icon(Icons.add, color: Colors.white),
                            ),
                          ),
                        ],
                      ),

                      // Item Name Field[cite: 11]
                      CustomTextField(
                        controller: nameController,
                        label: 'Item Name *',
                        hint: 'e.g. Carrot, Tomato',
                        icon: Icons.eco_outlined,
                        validator: (val) => (val == null || val.trim().isEmpty)
                            ? 'Please enter item name'
                            : null,
                      ),

                      // Unit Dropdown[cite: 11]
                      CustomDropdown<String>(
                        labelText: 'Default Unit *',
                        value: selectedUnit,
                        items: units,
                        itemLabelBuilder: (u) => u,
                        prefixIcon: Icons.scale_outlined,
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() => selectedUnit = val);
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      // Item Image Picker Row
                      Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: pickedImageFile != null
                                ? Image.file(
                                    pickedImageFile!,
                                    fit: BoxFit.cover,
                                  )
                                : (existingImageUrl != null &&
                                      existingImageUrl.isNotEmpty)
                                ? Image.network(
                                    existingImageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.spa,
                                      color: Colors.green,
                                    ),
                                  )
                                : const Icon(Icons.spa, color: Colors.green),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: pickImage,
                              icon: const Icon(
                                Icons.image_outlined,
                                color: Colors.green,
                              ),
                              label: Text(
                                pickedImageFile != null
                                    ? 'Change Selected Image'
                                    : (existingImageUrl != null &&
                                          existingImageUrl.isNotEmpty)
                                    ? 'Replace Image'
                                    : 'Pick Item Image',
                                style: const TextStyle(color: Colors.green),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Save / Update Button[cite: 11]
                      CustomButton(
                        text: itemToEdit == null ? 'Save Item' : 'Update Item',
                        color: Colors.green,
                        isLoading: isSaving,
                        onPressed: () async {
                          if (!formKey.currentState!.validate() ||
                              selectedCategory == null) {
                            return;
                          }

                          setModalState(() => isSaving = true);
                          try {
                            String? imageUrl = existingImageUrl;
                            if (pickedImageFile != null) {
                              imageUrl = await _uploadItemImage(
                                pickedImageFile!,
                              );
                            }

                            final itemData = {
                              'name': nameController.text.trim(),
                              'category_id': selectedCategory!.id,
                              'unit': selectedUnit,
                              'image_url': imageUrl,
                            };

                            if (itemToEdit == null) {
                              await _supabase
                                  .from('master_items')
                                  .insert(itemData);
                            } else {
                              await _supabase
                                  .from('master_items')
                                  .update(itemData)
                                  .eq('id', itemToEdit.id!);
                            }

                            if (!mounted) return;
                            final messenger = ScaffoldMessenger.of(
                              this.context,
                            );

                            if (ctx.mounted) Navigator.pop(ctx);

                            await _loadInitialData();

                            if (mounted) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    itemToEdit == null
                                        ? 'Item registered successfully!'
                                        : 'Item updated successfully!',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (ctx.mounted) {
                              setModalState(() => isSaving = false);
                            }
                            debugPrint('Error saving item: $e');
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

  // 3. අලුත් Category එකක් එකතු කිරීමේ Dialog එක[cite: 11]
  void _showAddCategoryDialog() {
    final catController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Category'),
        content: TextField(
          controller: catController,
          decoration: const InputDecoration(
            hintText: 'e.g. Spices, Leafy Greens',
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final name = catController.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(context);
              try {
                await _supabase.from('categories').insert({'name': name});
                await _loadInitialData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Category added successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // 4. Delete Confirmation Dialog[cite: 11]
  void _confirmDelete(String itemId, String itemName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "$itemName"?'),
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
              _deleteItem(itemId);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteItem(String itemId) async {
    try {
      await _supabase.from('master_items').delete().eq('id', itemId);
      await _loadInitialData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item deleted successfully!'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cannot delete: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Search Filtering[cite: 11]
    final filteredItems = _itemsList.where((item) {
      final nameMatches = item.name.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      final categoryMatches =
          item.categoryName != null &&
          item.categoryName!.toLowerCase().contains(_searchQuery.toLowerCase());
      return nameMatches || categoryMatches;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Manage Items (Admin)'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // --- Search Bar ---[cite: 11]
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search by Item Name or Category...',
                prefixIcon: const Icon(Icons.search),
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

          // --- List View ---[cite: 11]
          Expanded(
            child: _isLoadingData
                ? const Center(child: CircularProgressIndicator())
                : filteredItems.isEmpty
                ? Center(
                    child: Text(
                      _searchQuery.isEmpty
                          ? 'No items registered yet. Tap + to add.'
                          : 'No matching items found.',
                      style: const TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems.length > index
                          ? filteredItems[index]
                          : null;
                      if (item == null) return const SizedBox.shrink();

                      final hasImage =
                          item.imageUrl != null && item.imageUrl!.isNotEmpty;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        color: Colors.white,
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          onTap: () => _showItemForm(itemToEdit: item),
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
                                        Icons.spa,
                                        color: Colors.green,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.spa, color: Colors.green),
                          ),
                          title: Text(
                            item.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            'Category: ${item.categoryName ?? 'N/A'}  •  Unit: ${item.unit}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () =>
                                _confirmDelete(item.id!, item.name),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      // --- Floating Action Button (+ Add Button) ---[cite: 11]
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        onPressed: () => _showItemForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
