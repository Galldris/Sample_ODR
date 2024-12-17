import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ViewRequisitionScreen extends StatefulWidget {
  final int requisitionId;

  ViewRequisitionScreen({required this.requisitionId});

  @override
  _ViewRequisitionScreenState createState() => _ViewRequisitionScreenState();
}

class _ViewRequisitionScreenState extends State<ViewRequisitionScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _requisition;
  Set<String> _raisedTickets = Set<String>();

  Future<void> _fetchRequisitionDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:5000/requisitions/${widget.requisitionId}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _requisition = data['data'];
          });
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Failed to fetch requisition details.';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Server error. Please try again later.';
        });
      }
    } catch (e) {
      print('Error fetching requisition details: $e');
      setState(() {
        _errorMessage = 'An error occurred. Please check your connection.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showRaiseTicketDialog(String itemId, String itemType) {
    final TextEditingController _serialNoController = TextEditingController();
    final TextEditingController _stockNoController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Raise Ticket for $itemType'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _serialNoController,
                decoration: const InputDecoration(
                  labelText: 'Serial No',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _stockNoController,
                decoration: const InputDecoration(
                  labelText: 'Stock No',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _raisedTickets.add(itemId);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Ticket raised for $itemType with ID $itemId')),
                );
                Navigator.of(context).pop();
              },
              child: const Text('Raise Ticket'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchRequisitionDetails();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Requisition'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(fontSize: 16, color: Colors.red),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView(
                          children: [
                            Text('Requisition ID: ${_requisition?['id'] ?? 'N/A'}'),
                            Text('Form No: ${_requisition?['form_no'] ?? 'N/A'}'),
                            Text('Request No: ${_requisition?['request_no'] ?? 'N/A'}'),
                            Text('Site ID: ${_requisition?['site_id'] ?? 'N/A'}'),
                            Text('Date of Request: ${_requisition?['date_of_request'] ?? 'N/A'}'),
                            const SizedBox(height: 16),
                            const Text('Plant/Tools Required'),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text('Name')),
                                  DataColumn(label: Text('Quantity')),
                                  DataColumn(label: Text('Date Required')),
                                  DataColumn(label: Text('Duration')),
                                  DataColumn(label: Text('Actions')),
                                ],
                                rows: _requisition?['toolsRequired']?.map<DataRow>((tool) {
                                  return DataRow(
                                    color: MaterialStateProperty.resolveWith<Color?>(
                                      (Set<MaterialState> states) {
                                        if (_raisedTickets.contains(tool['id'].toString())) {
                                          return Colors.green.withOpacity(0.3);
                                        }
                                        return null;
                                      },
                                    ),
                                    cells: [
                                      DataCell(Text(tool['name'] ?? 'N/A')),
                                      DataCell(Text(tool['quantity']?.toString() ?? 'N/A')),
                                      DataCell(Text(tool['date_required'] ?? 'N/A')),
                                      DataCell(Text(tool['duration']?.toString() ?? 'N/A')),
                                      DataCell(
                                        ElevatedButton(
                                          onPressed: () => _showRaiseTicketDialog(tool['id'].toString(), 'tool'),
                                          child: const Text('Raise Ticket'),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList() ?? [],
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text('Consumables Required'),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text('Name')),
                                  DataColumn(label: Text('Quantity')),
                                  DataColumn(label: Text('Date Required')),
                                  DataColumn(label: Text('Actions')),
                                ],
                                rows: _requisition?['consumablesRequired']?.map<DataRow>((consumable) {
                                  return DataRow(
                                    color: MaterialStateProperty.resolveWith<Color?>(
                                      (Set<MaterialState> states) {
                                        if (_raisedTickets.contains(consumable['id'].toString())) {
                                          return Colors.green.withOpacity(0.3);
                                        }
                                        return null;
                                      },
                                    ),
                                    cells: [
                                      DataCell(Text(consumable['name'] ?? 'N/A')),
                                      DataCell(Text(consumable['quantity']?.toString() ?? 'N/A')),
                                      DataCell(Text(consumable['date_required'] ?? 'N/A')),
                                      DataCell(
                                        ElevatedButton(
                                          onPressed: () => _showRaiseTicketDialog(consumable['id'].toString(), 'consumable'),
                                          child: const Text('Raise Ticket'),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList() ?? [],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}