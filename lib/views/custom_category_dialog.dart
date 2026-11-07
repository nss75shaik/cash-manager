import 'package:flutter/material.dart';
import '../controllers/expense_controller.dart';

class CustomCategoryDialog extends StatefulWidget {
  final ExpenseController controller;

  const CustomCategoryDialog({
    super.key,
    required this.controller,
  });

  @override
  State<CustomCategoryDialog> createState() => _CustomCategoryDialogState();
}

class _CustomCategoryDialogState extends State<CustomCategoryDialog> {
  final _nameController = TextEditingController();
  final _budgetController = TextEditingController();
  String _selectedNeedWant = 'need';
  bool _isExpense = true;
  IconData _selectedIcon = Icons.category_rounded;
  Color _selectedColor = const Color(0xFF0284C7);

  final List<IconData> _iconOptions = const [
    Icons.category_rounded,
    Icons.savings_rounded,
    Icons.pets,
    Icons.fitness_center,
    Icons.flight_takeoff,
    Icons.menu_book,
    Icons.local_gas_station,
    Icons.construction,
    Icons.local_cafe,
    Icons.card_giftcard,
    Icons.healing,
    Icons.celebration,
    Icons.local_shipping,
    Icons.water_drop,
    Icons.sports_esports,
  ];

  final List<Color> _colorOptions = const [
    Color(0xFF0284C7),
    Color(0xFF16A34A),
    Color(0xFFDC2626),
    Color(0xFF9333EA),
    Color(0xFFEA580C),
    Color(0xFF0D9488),
    Color(0xFFD97706),
    Color(0xFFE11D48),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  void _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter category name')),
      );
      return;
    }

    final budget = double.tryParse(_budgetController.text.trim()) ?? 0.0;

    await widget.controller.createCustomCategory(
      name: name,
      icon: _selectedIcon,
      color: _selectedColor,
      needWant: _selectedNeedWant,
      budget: budget,
      isExpense: _isExpense,
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Category "$name" created successfully!'),
          backgroundColor: const Color(0xFF16A34A),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _selectedColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_selectedIcon, color: _selectedColor),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Custom Category',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        Text(
                          'Create personalized budget & category',
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Expense vs Income toggle
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Expense')),
                      selected: _isExpense,
                      onSelected: (val) => setState(() => _isExpense = true),
                      selectedColor: const Color(0xFFDC2626),
                      labelStyle: TextStyle(
                        color: _isExpense ? Colors.white : const Color(0xFF334155),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Income')),
                      selected: !_isExpense,
                      onSelected: (val) => setState(() => _isExpense = false),
                      selectedColor: const Color(0xFF16A34A),
                      labelStyle: TextStyle(
                        color: !_isExpense ? Colors.white : const Color(0xFF334155),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Name input
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Category Name',
                  hintText: 'e.g. Gym, Pet Care, Subscription',
                  prefixIcon: const Icon(Icons.label_outline),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 14),

              // Monthly Decided Budget (Optional)
              TextField(
                controller: _budgetController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Monthly Target Budget (₹)',
                  hintText: 'e.g. 3000',
                  prefixIcon: const Icon(Icons.currency_rupee),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 14),

              // Need vs Want (If Expense)
              if (_isExpense) ...[
                const Text('Expense Purpose', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        avatar: Icon(Icons.check_circle_outline, size: 16, color: _selectedNeedWant == 'need' ? Colors.white : const Color(0xFF059669)),
                        label: const Text('NEED (Essential)'),
                        selected: _selectedNeedWant == 'need',
                        onSelected: (val) => setState(() => _selectedNeedWant = 'need'),
                        selectedColor: const Color(0xFF059669),
                        labelStyle: TextStyle(
                          color: _selectedNeedWant == 'need' ? Colors.white : const Color(0xFF059669),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        avatar: Icon(Icons.star_outline, size: 16, color: _selectedNeedWant == 'want' ? Colors.white : const Color(0xFFD97706)),
                        label: const Text('WANT (Optional)'),
                        selected: _selectedNeedWant == 'want',
                        onSelected: (val) => setState(() => _selectedNeedWant = 'want'),
                        selectedColor: const Color(0xFFD97706),
                        labelStyle: TextStyle(
                          color: _selectedNeedWant == 'want' ? Colors.white : const Color(0xFFD97706),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
              ],

              // Choose Icon
              const Text('Select Icon', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _iconOptions.map((icon) {
                  final isSelected = _selectedIcon == icon;
                  return InkWell(
                    onTap: () => setState(() => _selectedIcon = icon),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected ? _selectedColor : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: isSelected ? Colors.white : const Color(0xFF475569), size: 20),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // Choose Color
              const Text('Select Color Tag', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _colorOptions.map((c) {
                  final isSelected = _selectedColor == c;
                  return InkWell(
                    onTap: () => setState(() => _selectedColor = c),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: isSelected ? Border.all(color: Colors.black, width: 2) : null,
                      ),
                      child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Create button
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _save,
                  child: const Text('CREATE CATEGORY', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
