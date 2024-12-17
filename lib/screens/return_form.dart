import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Add this import for date formatting
import 'dart:convert';
import 'package:http/http.dart' as http;

class ReturnForm extends StatefulWidget {
  @override
  _ReturnFormState createState() => _ReturnFormState();
}

class _ReturnFormState extends State<ReturnForm> {
  int _currentStep = 0;

  // Auto-generated fields
  late String _formNo;
  late String _requestNo;

  // Static counters for form and request numbers
  static int _formCounter = 1;
  static int _requestCounter = 1;

  // Controllers for Section 1
  final TextEditingController _siteIdController = TextEditingController();
  final TextEditingController _dateOfRequestController = TextEditingController();

  // Dynamic Lists for Section 2
  List<Map<String, dynamic>> _toolsOffhire = [];

  // GlobalKey for the form
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    // Generate Form No. and Request No. on form initialization
    _formNo = "RF${_formCounter.toString().padLeft(3, '0')}";
    _requestNo = "RR${_requestCounter.toString().padLeft(3, '0')}";

    // Increment counters for next form and request
    _formCounter++;
    _requestCounter++;

    // Set the date of request to today's date in the format of day, month, and year
    _dateOfRequestController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  List<Step> _getSteps() {
    return [
      Step(
        title: const Text('Section 1'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Return Form No: $_formNo',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Return Request No: $_requestNo',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _siteIdController,
              decoration: const InputDecoration(
                labelText: 'Site ID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _dateOfRequestController,
              decoration: const InputDecoration(
                labelText: 'Date of Request',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              readOnly: true,
              onTap: () => _selectDate(context, _dateOfRequestController),
            ),
          ],
        ),
        isActive: _currentStep >= 0,
        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Section 2'),
        content: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Plant/Tools Offhire',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ..._toolsOffhire.map((tool) {
                final TextEditingController dateController = TextEditingController(
                  text: tool['collectionDate'] ?? '',
                );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Plant/Tool ${_toolsOffhire.indexOf(tool) + 1}',
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        tool['name'] = value;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: dateController,
                      decoration: InputDecoration(
                        labelText: 'Required Collection Date',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () {
                            _selectDate(context, dateController).then((_) {
                              setState(() {
                                tool['collectionDate'] = dateController.text;
                              });
                            });
                          },
                        ),
                      ),
                      readOnly: true,
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              }).toList(),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _toolsOffhire.add({});
                  });
                },
                child: const Text('Add Plant/Tool Offhire'),
              ),
            ],
          ),
        ),
        isActive: _currentStep >= 1,
        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Overview'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Return Form No: $_formNo',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Return Request No: $_requestNo',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Site ID: ${_siteIdController.text}',
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Date of Request: ${_dateOfRequestController.text}',
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Plant/Tools Offhire:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ..._toolsOffhire.map((tool) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Plant/Tool ${_toolsOffhire.indexOf(tool) + 1}: ${tool['name'] ?? ''}',
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Required Collection Date: ${tool['collectionDate'] ?? ''}',
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              );
            }).toList(),
          ],
        ),
        isActive: _currentStep >= 2,
        state: _currentStep > 2 ? StepState.complete : StepState.indexed,
      ),
    ];
  }

  void _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      // Collect the data
      final formData = {
        "site_id": _siteIdController.text,
        "type": "Plant/Tools Offhire",
        "status": "Pending",
        "created_by": 1, // Assuming a static user ID for now
        "toolsOffhire": _toolsOffhire,
      };

      if (_siteIdController.text.isEmpty || _toolsOffhire.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please fill in all required fields')),
        );
        return;
      }

      try {
        // Send data to the backend
        final response = await http.post(
          Uri.parse('http://10.0.2.2:5000/offhire_tools/create'), // Corrected endpoint
          headers: {'Content-Type': 'application/json'},
          body: json.encode(formData),
        );

        if (response.statusCode == 201) {
          // Handle success
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Return form submitted successfully!')),
          );

          // Navigate back to the dashboard or reset the form
          _cancelForm();
        } else {
          // Handle error
          final errorData = json.decode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${errorData['message']}')),
          );
        }
      } catch (e) {
        // Handle network errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Network error: $e')),
        );
      }
    }
  }

  void _cancelForm() {
    // Handle form cancellation
    // For example, reset the form or navigate away
    setState(() {
      _currentStep = 0;
      _siteIdController.clear();
      _dateOfRequestController.text = DateFormat('yyyy-MM-dd').format(DateTime.now()); // Reset to today's date
      _toolsOffhire.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Return Form'),
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < _getSteps().length - 1) {
            setState(() {
              _currentStep += 1;
            });
          } else {
            _submitForm();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() {
              _currentStep -= 1;
            });
          }
        },
        steps: _getSteps(),
        controlsBuilder: (BuildContext context, ControlsDetails details) {
          return Row(
            children: <Widget>[
              if (_currentStep < _getSteps().length - 1)
                ElevatedButton(
                  onPressed: details.onStepContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFCF20),
                    textStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text('Next'),
                ),
              if (_currentStep == _getSteps().length - 1)
                ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFCF20),
                    textStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text('Submit'),
                ),
              const SizedBox(width: 8),
              if (_currentStep > 0 && _currentStep < _getSteps().length - 1)
                ElevatedButton(
                  onPressed: details.onStepCancel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    textStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text('Back'),
                ),
              if (_currentStep == _getSteps().length - 1)
                ElevatedButton(
                  onPressed: _cancelForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    textStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              if (_currentStep == _getSteps().length - 1)
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _currentStep = 0;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    textStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text('Edit'),
                ),
            ],
          );
        },
      ),
    );
  }
}