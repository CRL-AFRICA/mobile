import 'package:flutter/material.dart';

class OTPInputWidget extends StatefulWidget {
  final Function(String) onCompleted;

  const OTPInputWidget({super.key, required this.onCompleted});

  @override
  // ignore: library_private_types_in_public_api
  _OTPInputWidgetState createState() => _OTPInputWidgetState();
}

class _OTPInputWidgetState extends State<OTPInputWidget> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      maxLength: 6,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        counterText: "",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        hintText: "------",
      ),
      onChanged: (value) {
        if (value.length == 6) {
          widget.onCompleted(value);
        }
      },
    );
  }
}
