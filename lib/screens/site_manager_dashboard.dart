import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SiteManagerDashboard extends StatefulWidget {
  final int userId;

  SiteManagerDashboard({required this.userId});

  @override
  _SiteManagerDashboardState createState() => _SiteManagerDashboardState();
}

class _SiteManagerDashboardState extends State<SiteManagerDashboard> {
  List<dynamic> _requisitions = [];
  bool _isLoading = true;
  String? _errorMessage;

  Future<void> _fetchRequisitions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:5000/requisitions?role=site_manager&user_id=${widget.userId}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _requisitions = data['data'];
          });
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Failed to fetch requisitions.';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Server error. Please try again later.';
        });
      }
    } catch (e) {
      print('Error fetching requisitions: $e');
      setState(() {
        _errorMessage = 'An error occurred. Please check your connection.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _approveRequisition(int requisitionId) async {
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/requisitions/approve'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'requisition_id': requisitionId, 'approved_by': widget.userId}),
      );

      if (response.statusCode == 200) {
        _fetchRequisitions();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Requisition approved successfully')),
        );

        // Notify ODG staff
        await http.post(
          Uri.parse('http://10.0.2.2:5000/notify_odg'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'requisition_id': requisitionId}),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to approve requisition')),
        );
      }
    } catch (e) {
      print('Error approving requisition: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred. Please try again.')),
      );
    }
  }

  Future<void> _rejectRequisition(int requisitionId) async {
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/requisitions/reject'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'requisition_id': requisitionId, 'rejected_by': widget.userId}),
      );

      if (response.statusCode == 200) {
        _fetchRequisitions();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Requisition rejected successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to reject requisition')),
        );
      }
    } catch (e) {
      print('Error rejecting requisition: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred. Please try again.')),
      );
    }
  }

  Future<void> _viewRequisition(int requisitionId) async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ViewRequisitionScreen(requisitionId: requisitionId)),
    );
  }

  Future<void> _editRequisition(int requisitionId) async {
    // Navigate to the edit requisition screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditRequisitionScreen(requisitionId: requisitionId)),
    ).then((_) {
      _fetchRequisitions();
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchRequisitions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Site Manager Dashboard'),
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
              : ListView.builder(
                  itemCount: _requisitions.length,
                  itemBuilder: (context, index) {
                    final requisition = _requisitions[index];
                    Color cardColor;
                    if (requisition['status'] == 'Approved') {
                      cardColor = Colors.green[100]!;
                    } else if (requisition['status'] == 'Rejected') {
                      cardColor = Colors.red[100]!;
                    } else {
                      cardColor = Colors.white;
                    }
                    return Card(
                      color: cardColor,
                      margin: const EdgeInsets.all(8.0),
                      child: ListTile(
                        title: Text('Requisition ID: ${requisition['id']}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Form No: ${requisition['form_no']}'),
                            Text('Request No: ${requisition['request_no']}'),
                            Text('Site ID: ${requisition['site_id']}'),
                            Text('Date of Request: ${requisition['date_of_request']}'),
                            const Text('Plant/Tools Required:'),
                            ...?requisition['toolsRequired']?.map<Widget>((tool) {
                              return Text(
                                'Name: ${tool['name']}, Quantity: ${tool['quantity']}, Date Required: ${tool['date_required']}, Duration: ${tool['duration']} days',
                              );
                            }).toList() ?? [],
                            const Text('Consumables Required:'),
                            ...?requisition['consumablesRequired']?.map<Widget>((consumable) {
                              return Text(
                                'Name: ${consumable['name']}, Quantity: ${consumable['quantity']}, Date Required: ${consumable['date_required']}',
                              );
                            }).toList() ?? [],
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility),
                              onPressed: () => _viewRequisition(requisition['id']),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _editRequisition(requisition['id']),
                            ),
                            IconButton(
                              icon: const Icon(Icons.check),
                              onPressed: () => _approveRequisition(requisition['id']),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => _rejectRequisition(requisition['id']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

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
                  child: ListView(
                    children: [
                      Text('Requisition ID: ${_requisition!['id']}'),
                      Text('Form No: ${_requisition!['form_no']}'),
                      Text('Request No: ${_requisition!['request_no']}'),
                      Text('Site ID: ${_requisition!['site_id']}'),
                      Text('Date of Request: ${_requisition!['date_of_request']}'),
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
                          ],
                          rows: _requisition!['toolsRequired']?.map<DataRow>((tool) {
                            return DataRow(cells: [
                              DataCell(Text(tool['name'])),
                              DataCell(Text(tool['quantity'].toString())),
                              DataCell(Text(tool['date_required'])),
                              DataCell(Text(tool['duration'].toString())),
                            ]);
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
                          ],
                          rows: _requisition!['consumablesRequired']?.map<DataRow>((consumable) {
                            return DataRow(cells: [
                              DataCell(Text(consumable['name'])),
                              DataCell(Text(consumable['quantity'].toString())),
                              DataCell(Text(consumable['date_required'])),
                            ]);
                          }).toList() ?? [],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class EditRequisitionScreen extends StatefulWidget {
  final int requisitionId;

  EditRequisitionScreen({required this.requisitionId});

  @override
  _EditRequisitionScreenState createState() => _EditRequisitionScreenState();
}

class _EditRequisitionScreenState extends State<EditRequisitionScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _requisition;

  final TextEditingController _siteIdController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();
  List<Map<String, dynamic>> _toolsRequired = [];
  List<Map<String, dynamic>> _consumablesRequired = [];

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
            _siteIdController.text = _requisition!['site_id'].toString();
            _typeController.text = _requisition!['type'];
            _statusController.text = _requisition!['status'];
            _toolsRequired = List<Map<String, dynamic>>.from(_requisition!['toolsRequired'] ?? []);
            _consumablesRequired = List<Map<String, dynamic>>.from(_requisition!['consumablesRequired'] ?? []);
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

  Future<void> _updateRequisition() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/requisitions/edit'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'requisition_id': widget.requisitionId,
          'site_id': int.parse(_siteIdController.text),
          'type': _typeController.text,
          'status': _statusController.text,
          'toolsRequired': _toolsRequired,
          'consumablesRequired': _consumablesRequired,
        }),
      );

      if (response.statusCode == 200) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Requisition updated successfully')),
        );
      } else {
        setState(() {
          _errorMessage = 'Failed to update requisition.';
        });
      }
    } catch (e) {
      print('Error updating requisition: $e');
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
        title: const Text('Edit Requisition'),
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
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      children: [
                        TextFormField(
                          controller: _siteIdController,
                          decoration: const InputDecoration(labelText: 'Site ID'),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter the site ID';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _typeController,
                          decoration: const InputDecoration(labelText: 'Type'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter the type';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _statusController,
                          decoration: const InputDecoration(labelText: 'Status'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter the status';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        const Text('Tools Required'),
                        ..._toolsRequired.map((tool) {
                          return ListTile(
                            title: Text(tool['name']),
                            subtitle: Text('Quantity: ${tool['quantity']}, Date Required: ${tool['dateRequired']}, Duration: ${tool['duration']} days'),
                          );
                        }).toList(),
                        const SizedBox(height: 16),
                        const Text('Consumables Required'),
                        ..._consumablesRequired.map((consumable) {
                          return ListTile(
                            title: Text(consumable['name']),
                            subtitle: Text('Quantity: ${consumable['quantity']}, Date Required: ${consumable['dateRequired']}'),
                          );
                        }).toList(),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _updateRequisition,
                          child: const Text('Update Requisition'),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}