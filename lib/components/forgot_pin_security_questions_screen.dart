import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'change_pin_screen.dart';

class ForgotPinScreen extends StatefulWidget {
  const ForgotPinScreen({super.key});

  @override
  State<ForgotPinScreen> createState() => _ForgotPinScreenState();
}

class _ForgotPinScreenState extends State<ForgotPinScreen> {
  final _formKey = GlobalKey<FormState>();
  List<dynamic> _securityQuestions = [];
  final List<TextEditingController> _answerControllers = List.generate(3, (_) => TextEditingController());
  final List<int?> _selectedQuestionIds = List.generate(3, (_) => null);

  @override
  void initState() {
    super.initState();
    _fetchSecurityQuestions();
  }

  Future<void> _fetchSecurityQuestions() async {
    final response = await http.get(
      Uri.parse("https://demoapi.crlafrica.com/odata/customer/SecurityQuestion"),
      headers: {'accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      setState(() {
        _securityQuestions = json.decode(response.body)['value'];
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load security questions")),
      );
    }
  }

  Future<void> _submitAnswers() async {
    if (_formKey.currentState?.validate() ?? false) {
      final payload = {
        "questionAndAnswers": List.generate(3, (index) {
          return {
            "securityQuestionId": _selectedQuestionIds[index],
            "answer": _answerControllers[index].text.trim(),
          };
        }),
      };

      final response = await http.post(
        Uri.parse("https://demoapi.crlafrica.com/api/customer/User/ResetPin/AnswerSecurityQuestions"),
        headers: {
          'accept': '*/*',
          'Content-Type': 'application/json;odata.metadata=minimal;odata.streaming=true',
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ChangePinScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Incorrect answers or server error")),
        );
      }
    }
  }

  Widget _buildQuestionDropdown(int index) {
    return DropdownButtonFormField<int>(
      value: _selectedQuestionIds[index],
      decoration: const InputDecoration(labelText: "Select Security Question"),
      items: _securityQuestions.map<DropdownMenuItem<int>>((question) {
        return DropdownMenuItem<int>(
          value: question['securityQuestionId'],
          child: Text(question['question']),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedQuestionIds[index] = value;
        });
      },
      validator: (value) => value == null ? "Select a question" : null,
    );
  }

  Widget _buildAnswerField(int index) {
    return TextFormField(
      controller: _answerControllers[index],
      decoration: const InputDecoration(labelText: "Your Answer"),
      validator: (value) => value!.isEmpty ? "Please enter your answer" : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 30),
              Center(child: Image.asset("images/logo.png", height: 100)), // Logo
              const SizedBox(height: 24),
              const Text(
                "Forgot PIN",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: Column(
                  children: List.generate(3, (index) {
                    return Column(
                      children: [
                        _buildQuestionDropdown(index),
                        const SizedBox(height: 8),
                        _buildAnswerField(index),
                        const SizedBox(height: 16),
                      ],
                    );
                  }),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitAnswers,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6197BC),
                  ),
                  child: const Text("Continue", style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
