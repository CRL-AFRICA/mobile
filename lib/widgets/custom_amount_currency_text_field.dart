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
  final NumberFormat _formatter = NumberFormat("#,##0.00", "en_NG");

  void _onTextChanged(String value) {
    // Remove non-numeric characters except for '.'
    String cleanValue = value.replaceAll(RegExp(r'[^\d.]'), '');

    if (cleanValue.isNotEmpty) {
      double parsedValue = double.tryParse(cleanValue) ?? 0.0;
      String formattedValue = _formatter.format(parsedValue);

      // Prevent infinite loop by checking if already formatted
      if (_controller.text != formattedValue) {
        _controller.value = TextEditingValue(
          text: formattedValue,
          selection: TextSelection.collapsed(offset: formattedValue.length),
        );
      }

      // Pass formatted string value to parent widget
      widget.onChanged(formattedValue);
    } else {
      widget.onChanged('');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue), // Border color
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Text("₦", style: TextStyle(fontSize: 18, color: Colors.grey)),
              SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _controller,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                  decoration: InputDecoration(
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
        SizedBox(height: 4),
        RichText(
          text: TextSpan(
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
