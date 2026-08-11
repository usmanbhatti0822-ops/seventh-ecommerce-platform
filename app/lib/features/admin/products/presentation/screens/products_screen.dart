import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "../../../../catalog/domain/entities/product.dart";
import "../../../../catalog/presentation/providers/catalog_provider.dart";
import "../../../../../core/theme/app_theme.dart";
import "../../../../../core/widgets/error_view.dart";
import "../../../../admin_shell.dart";
import "../../data/repositories/admin_products_repository.dart";
import "../../../../../core/network/api_result.dart";

/// Known catalog categories (mirrors the mock backend's seed categories —
/// there's no dedicated categories endpoint yet, so this list is kept in
/// sync with core/network/mock_backend.dart's `_categories`).
const _categories = [
  ("cat-hoodies", "Hoodies"),
  ("cat-outerwear", "Outerwear"),
  ("cat-tees", "Tees"),
  ("cat-bottoms", "Bottoms"),
  ("cat-accessories", "Accessories"),
];

const _badges = [null, "New", "Bestseller"];

class AdminProductsScreen extends ConsumerStatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  ConsumerState<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends ConsumerState<AdminProductsScreen> {
  String _search = "";

  void _openBulkImportDialog(BuildContext context) {
    final controller = TextEditingController(text: "name,basePrice,description,categoryId\n");
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Bulk Import Products (CSV)"),
        content: SizedBox(
          width: 480,
          child: TextField(
            controller: controller,
            maxLines: 8,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: "name,basePrice,description,categoryId",
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final rows = parseProductCsv(controller.text);
              final result = await AdminProductsRepository().bulkImport(rows);
              if (context.mounted) {
                Navigator.pop(context);
                final message = switch (result) {
                  ApiSuccess() => "Imported ${rows.length} products",
                  ApiFailure(message: final msg) => msg,
                };
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
                ref.invalidate(productsProvider);
              }
            },
            child: const Text("Import"),
          ),
        ],
      ),
    );
  }

  Future<void> _openProductForm({Product? existing}) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => _ProductFormDialog(existing: existing),
    );
    if (saved == true) {
      ref.invalidate(productsProvider);
    }
  }

  Future<void> _confirmDelete(Product p) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Product"),
        content: Text('Delete "${p.name}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final result = await AdminProductsRepository().delete(p.id);
    if (!mounted) return;
    final message = switch (result) {
      ApiSuccess() => "Deleted ${p.name}",
      ApiFailure(message: final msg) => msg,
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    ref.invalidate(productsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider(_search.isEmpty ? null : _search));
    return AdminShell(
      currentPath: "/admin/products",
      title: "Products",
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(builder: (context, constraints) {
              final narrow = constraints.maxWidth < 700;
              final searchField = TextField(
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: "Search products...",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.button), borderSide: BorderSide.none),
                ),
              );
              final addBtn = ElevatedButton.icon(onPressed: () => _openProductForm(), icon: const Icon(Icons.add), label: const Text("Add Product"));
              final importBtn = OutlinedButton.icon(
                onPressed: () => _openBulkImportDialog(context),
                icon: const Icon(Icons.upload_file),
                label: const Text("Bulk Import"),
              );
              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    searchField,
                    const SizedBox(height: 12),
                    Row(children: [Expanded(child: addBtn), const SizedBox(width: 12), Expanded(child: importBtn)]),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: searchField),
                  const SizedBox(width: 12),
                  addBtn,
                  const SizedBox(width: 12),
                  importBtn,
                ],
              );
            }),
            const SizedBox(height: 16),
            Expanded(
              child: productsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => ErrorView(message: "Could not load products", onRetry: () => ref.invalidate(productsProvider)),
                data: (products) {
                  if (products.isEmpty) {
                    return Center(child: Text("No products found", style: bodyFont(fontSize: 13, color: AppColors.inkSoft)));
                  }
                  return Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadii.card), border: Border.all(color: AppColors.line)),
                    child: LayoutBuilder(builder: (context, constraints) {
                      final wide = constraints.maxWidth > 760;
                      return ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: products.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.line),
                        itemBuilder: (context, i) => _ProductRow(
                          product: products[i],
                          wide: wide,
                          onEdit: () => _openProductForm(existing: products[i]),
                          onDelete: () => _confirmDelete(products[i]),
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  final Product product;
  final bool wide;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _ProductRow({required this.product, required this.wide, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final p = product;
    return ListTile(
      leading: ClipRRect(borderRadius: BorderRadius.circular(2), child: Image.network(p.imageUrl, width: 44, height: 44, fit: BoxFit.cover)),
      title: Text(p.name, style: bodyFont(fontSize: 13.5, fontWeight: FontWeight.w700)),
      subtitle: Text(p.category, style: bodyFont(fontSize: 12, color: AppColors.inkSoft)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (wide) ...[
            Text("Rs ${p.price.toStringAsFixed(0)}", style: bodyFont(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(width: 16),
            _StatusChip(label: p.inStock ? "In Stock" : "Out of Stock", color: p.inStock ? AppColors.success : Colors.redAccent),
            const SizedBox(width: 8),
          ],
          IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: onEdit, tooltip: "Edit"),
          IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent), onPressed: onDelete, tooltip: "Delete"),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(AppRadii.chip)),
      child: Text(label, style: bodyFont(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class _ProductFormDialog extends StatefulWidget {
  final Product? existing;
  const _ProductFormDialog({this.existing});

  @override
  State<_ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<_ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _name;
  late TextEditingController _price;
  late TextEditingController _oldPrice;
  late TextEditingController _description;
  String _categoryId = _categories.first.$1;
  String? _badge;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? "");
    _price = TextEditingController(text: e != null ? e.price.toStringAsFixed(0) : "");
    _oldPrice = TextEditingController(text: e?.oldPrice != null ? e!.oldPrice!.toStringAsFixed(0) : "");
    _description = TextEditingController(text: e?.description ?? "");
    _badge = e?.badge;
    if (e != null) {
      final match = _categories.where((c) => c.$2 == e.category);
      if (match.isNotEmpty) _categoryId = match.first.$1;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _oldPrice.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final payload = {
      "name": _name.text.trim(),
      "basePrice": double.tryParse(_price.text.trim()) ?? 0,
      "oldPrice": _oldPrice.text.trim().isEmpty ? null : double.tryParse(_oldPrice.text.trim()),
      "description": _description.text.trim(),
      "categoryId": _categoryId,
      "badge": _badge,
    };
    final repo = AdminProductsRepository();
    final result = widget.existing == null ? await repo.create(payload) : await repo.update(widget.existing!.id, payload);
    if (!mounted) return;
    setState(() => _saving = false);
    final message = switch (result) {
      ApiSuccess() => widget.existing == null ? "Product created" : "Product updated",
      ApiFailure(message: final msg) => msg,
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    if (result is ApiSuccess) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      title: Text(isEdit ? "Edit Product" : "Add Product", style: displayFont(fontSize: 18)),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: "Name", border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _price,
                        decoration: const InputDecoration(labelText: "Price (Rs)", border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                        validator: (v) => (double.tryParse(v?.trim() ?? "") == null) ? "Invalid" : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _oldPrice,
                        decoration: const InputDecoration(labelText: "Old Price (optional)", border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _categoryId,
                  decoration: const InputDecoration(labelText: "Category", border: OutlineInputBorder()),
                  items: _categories.map((c) => DropdownMenuItem(value: c.$1, child: Text(c.$2))).toList(),
                  onChanged: (v) => setState(() => _categoryId = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: _badge,
                  decoration: const InputDecoration(labelText: "Badge (optional)", border: OutlineInputBorder()),
                  items: _badges.map((b) => DropdownMenuItem(value: b, child: Text(b ?? "None"))).toList(),
                  onChanged: (v) => setState(() => _badge = v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _description,
                  decoration: const InputDecoration(labelText: "Description", border: OutlineInputBorder()),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(isEdit ? "Save" : "Create"),
        ),
      ],
    );
  }
}
