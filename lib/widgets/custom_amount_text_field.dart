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
  final NumberFormat currencyFormat = NumberFormat("#,##0.00", "en_US");

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_formatInput);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_formatInput);
    super.dispose();
  }

  void _formatInput() {
    String text = widget.controller.text.replaceAll(',', '');
    if (text.isEmpty) return;

    double? value = double.tryParse(text);
    if (value != null) {
      String formatted = currencyFormat.format(value);
      widget.controller.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: widget.label,
        border: OutlineInputBorder(),
        helperText: "Max per transaction limit: ₦${currencyFormat.format(widget.maxAmount)}",
      ),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
    );
  }
}
