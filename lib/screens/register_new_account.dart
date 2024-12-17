import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterNewAccount extends StatefulWidget {
  const RegisterNewAccount({Key? key}) : super(key: key);

  @override
  _RegisterNewAccountState createState() => _RegisterNewAccountState();
}

class _RegisterNewAccountState extends State<RegisterNewAccount> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  String? _selectedRole;
  bool _isLoading = false;

  
  
  
  
  Future<void> _registerAccount() async {
  if (_nameController.text.isEmpty ||
      _emailController.text.isEmpty ||
      _passwordController.text.isEmpty ||
      _confirmPasswordController.text.isEmpty) {
    _showErrorDialog('Please fill all required fields.');
    return;
  }

  if (_selectedRole == null) {
    _showErrorDialog('Please select a job role.');
    return;
  }

  if (_passwordController.text != _confirmPasswordController.text) {
    _showErrorDialog('Passwords do not match.');
    return;
  }

  if (!_emailController.text.contains('@galldris.co.uk')) {
    _showErrorDialog('Please enter a valid Galldris email.');
    return;
  }

  setState(() {
    _isLoading = true;
  });

  final payload = {
    'name': _nameController.text.trim(),
    'role': _selectedRole,
    'email': _emailController.text.trim(),
    'phone': _phoneController.text.trim(),
    'password': _passwordController.text,
  };
  print('Request Payload: $payload');

  try {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:5000/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(payload),
    );

    final data = json.decode(response.body);
    if (response.statusCode == 201) {
      _showSuccessDialog('Account created successfully!');
    } else {
      _showErrorDialog(data['message'] ?? 'Failed to create account.');
    }
  } catch (e) {
    print('Error: $e');
    _showErrorDialog('An error occurred. Please try again later.');
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}

  
  
  
  
  
  
  
  
  
  
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register New Account'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              onChanged: (value) => setState(() => _selectedRole = value),
              items: const [
                DropdownMenuItem(value: 'supervisor', child: Text('Supervisor')),
                DropdownMenuItem(value: 'site_manager', child: Text('Site Manager')),
                DropdownMenuItem(value: 'delivery_driver', child: Text('Delivery Driver')),
                DropdownMenuItem(value: 'odg_staff', child: Text('ODG Staff')),
              ],
              decoration: const InputDecoration(labelText: 'Job Role'),
            ),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Galldris Email'),
            ),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number (Optional)'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            TextField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(labelText: 'Confirm Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _registerAccount,
                    child: const Text('Create Account'),
                  ),
          ],
        ),
      ),
    );
  }
}
