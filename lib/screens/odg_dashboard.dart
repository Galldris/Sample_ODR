import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'odg_login.dart';
import 'view_requisition_screen.dart';
import 'tickets.dart'; // Add this import

class ODGDashboard extends StatefulWidget {
  const ODGDashboard({Key? key}) : super(key: key);

  @override
  _ODGDashboardState createState() => _ODGDashboardState();
}

class _ODGDashboardState extends State<ODGDashboard> {
  List<dynamic> _requisitions = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _filter = 'All';

  Future<void> _fetchRequisitions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:5000/requisitions?status=approved'),
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

  Future<void> _viewRequisition(int requisitionId) async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ViewRequisitionScreen(requisitionId: requisitionId)),
    );
  }

  List<dynamic> _filterRequisitions() {
    if (_filter == 'All') {
      return _requisitions;
    } else {
      return _requisitions.where((requisition) {
        final dateRequired = DateTime.parse(requisition['date_required']);
        final now = DateTime.now();
        if (_filter == 'High') {
          return dateRequired.isBefore(now.add(Duration(days: 3)));
        } else if (_filter == 'Medium') {
          return dateRequired.isBefore(now.add(Duration(days: 7)));
        } else {
          return dateRequired.isAfter(now.add(Duration(days: 7)));
        }
      }).toList();
    }
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
        title: const Text('ODG Dashboard'),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
              tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
            );
          },
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'ODG Dashboard Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.confirmation_number), // Use a valid icon
              title: const Text('Tickets'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TicketsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const ODGLogin()),
                );
              },
            ),
          ],
        ),
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
              : Column(
                  children: [
                    DropdownButton<String>(
                      value: _filter,
                      onChanged: (String? newValue) {
                        setState(() {
                          _filter = newValue!;
                        });
                      },
                      items: <String>['All', 'High', 'Medium', 'Low']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _filterRequisitions().length,
                        itemBuilder: (context, index) {
                          final requisition = _filterRequisitions()[index];
                          return Card(
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
                                  Text('Date Required: ${requisition['date_required']}'),
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
                              trailing: IconButton(
                                icon: const Icon(Icons.visibility),
                                onPressed: () => _viewRequisition(requisition['id']),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}