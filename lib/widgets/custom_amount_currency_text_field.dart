import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class AmountInputField extends StatefulWidget {
  final Function(String value) onChanged;

  const AmountInputField({super.key, required this.onChanged});

  @override
  _AmountInputFieldState createState() => _AmountInputFieldState();
}

class _AmountInputFieldState extends State<AmountInputField> {
  final TextEditingController _controller = TextEditingController();
  final NumberFormat _integerFormatter = NumberFormat("#,##0", "en_NG");
  final NumberFormat _finalFormatter = NumberFormat("#,##0.00", "en_NG");
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _formatFinalAmount();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged(String value) {
    String cleanValue = value.replaceAll(RegExp(r'[^\d.]'), '');

    if (cleanValue.isEmpty) {
      widget.onChanged('');
      _controller.value = const TextEditingValue(text: '', selection: TextSelection.collapsed(offset: 0));
      return;
    }

    // Only allow one decimal point
    int dotCount = '.'.allMatches(cleanValue).length;
    if (dotCount > 1) {
      // Remove last input if multiple dots
      cleanValue = cleanValue.substring(0, cleanValue.length - 1);
    }

    // If last char is dot, allow it and don’t format yet
    if (cleanValue.endsWith('.')) {
      widget.onChanged(cleanValue);
      _controller.value = TextEditingValue(
        text: cleanValue,
        selection: TextSelection.collapsed(offset: cleanValue.length),
      );
      return;
    }

    double? parsedValue = double.tryParse(cleanValue);
    if (parsedValue == null) {
      return; // invalid number, ignore
    }

    String formattedValue;
    if (cleanValue.contains('.')) {
      // If decimal entered, keep raw input (no commas) for typing ease
      formattedValue = cleanValue;
    } else {
      // Format integer part with commas
      formattedValue = _integerFormatter.format(parsedValue);
    }

    if (_controller.text != formattedValue) {
      _controller.value = TextEditingValue(
        text: formattedValue,
        selection: TextSelection.collapsed(offset: formattedValue.length),
      );
    }

    widget.onChanged(formattedValue);
  }

  void _formatFinalAmount() {
    String text = _controller.text.replaceAll(',', '');
    double? value = double.tryParse(text);
    if (value != null) {
      String finalFormatted = _finalFormatter.format(value);
      _controller.text = finalFormatted;
      widget.onChanged(finalFormatted);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Text("₦", style: TextStyle(fontSize: 18, color: Colors.grey)),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: "Amount",
                    hintStyle: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  onChanged: _onTextChanged,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        RichText(
          text: const TextSpan(
            text: "Max per transaction limits: ",
            style: TextStyle(fontSize: 12, color: Colors.grey),
            children: [
              TextSpan(
                text: "₦1,000,000.00",
                style: TextStyle(fontSize: 12, color: Colors.blue),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
