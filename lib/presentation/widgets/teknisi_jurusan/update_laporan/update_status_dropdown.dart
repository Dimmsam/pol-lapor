import 'package:flutter/material.dart';
import '../../../../../core/constants/app_constants.dart';

class UpdateStatusDropdown extends StatelessWidget {
  final String status;
  final ValueChanged<String?> onChanged;

  const UpdateStatusDropdown({
    super.key,
    required this.status,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: status,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          items: AppConstants.statusProgresOptions.map((option) {
            return DropdownMenuItem(
              value: option['value'],
              child: Text(option['label']!),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
