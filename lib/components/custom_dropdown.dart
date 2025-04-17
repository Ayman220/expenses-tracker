import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';

class CustomDropdown extends StatelessWidget {
  final List<Map<String, String>> items;
  final Map<String, String>? selectedItem;
  final Function(Map<String, String>?) onChanged;
  final String hintText;
  final String? errorText;

  const CustomDropdown({
    super.key,
    required this.items,
    this.selectedItem,
    required this.onChanged,
    required this.hintText,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownSearch<Map<String, String>>(
      items: items,
      selectedItem: selectedItem,
      onChanged: onChanged,
      popupProps: PopupProps.menu(
        showSearchBox: true,
        searchFieldProps: TextFieldProps(
          decoration: InputDecoration(
            hintText: 'Search...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        menuProps: MenuProps(
          borderRadius: BorderRadius.circular(12),
          backgroundColor: Theme.of(context).colorScheme.surface,
        ),
      ),
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          hintText: hintText,
          errorText: errorText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(26),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(26),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
        ),
      ),
      itemAsString: (item) => item['name'] ?? 'Unknown',
      compareFn: (item1, item2) => item1['uid'] == item2['uid'],
    );
  }
} 