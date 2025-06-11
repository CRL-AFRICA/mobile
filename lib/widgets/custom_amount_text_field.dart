import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class AmountField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final double maxAmount;

  const AmountField({
    super.key,
    required this.controller,
    this.label = "Amount",
    this.maxAmount = 1000000,
  });

  @override
  // ignore: library_private_types_in_public_api
  _AmountFieldState createState() => _AmountFieldState();
}

class _AmountFieldState extends State<AmountField> {
  late FocusNode _focusNode; // Declare FocusNode
  final NumberFormat currencyFormat = NumberFormat("#,##0.00", "en_US");
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(); // Initialize FocusNode
    _focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_formatInput);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose(); // Dispose FocusNode
    widget.controller.removeListener(_formatInput);
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      // Format input only when focus is lost
      _formatInput();
    }
  }

  void _formatInput() {
    if (_isEditing) return; // Avoid re-entrant calls
    String text = widget.controller.text.replaceAll(',', '');
    if (text.isEmpty) return;

    double? value = double.tryParse(text);
    if (value != null) {
      String formatted = currencyFormat.format(value);
      _isEditing = true;
      widget.controller.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
      _isEditing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      focusNode: _focusNode,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(),
        helperText: "Max per transaction limit: ₦${currencyFormat.format(widget.maxAmount)}",
        prefixText: "₦",
      ),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
    );
  }
}
