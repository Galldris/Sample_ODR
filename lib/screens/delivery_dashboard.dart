import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'delivery_form.dart';
import 'collection_form.dart';

class DeliveryDashboard extends StatefulWidget {
  final int userId;

  DeliveryDashboard({required this.userId});

  @override
  _DeliveryDashboardState createState() => _DeliveryDashboardState();
}

class _DeliveryDashboardState extends State<DeliveryDashboard> {
  List<dynamic> _deliveries = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _filter = 'All';

  Future<void> _fetchDeliveries() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:5000/deliveries?role=delivery&user_id=${widget.userId}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _deliveries = data['data'];
          });
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Failed to fetch deliveries.';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Server error. Please try again later.';
        });
      }
    } catch (e) {
      print('Error fetching deliveries: $e');
      setState(() {
        _errorMessage = 'An error occurred. Please check your connection.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String formatDate(String? date) {
    if (date == null) return "N/A";
    try {
      final parsedDate = DateTime.parse(date);
      return "${parsedDate.day}/${parsedDate.month}/${parsedDate.year} ${parsedDate.hour}:${parsedDate.minute}";
    } catch (e) {
      return "Invalid date";
    }
  }

  List<dynamic> _filterDeliveries() {
    DateTime now = DateTime.now();
    DateTime tomorrow = now.add(Duration(days: 1));
    DateTime nextWeek = now.add(Duration(days: 7));

    if (_filter == 'Today') {
      return _deliveries.where((delivery) {
        DateTime createdAt = DateTime.parse(delivery['created_at']);
        return createdAt.day == now.day &&
               createdAt.month == now.month &&
               createdAt.year == now.year;
      }).toList();
    } else if (_filter == 'Tomorrow') {
      return _deliveries.where((delivery) {
        DateTime createdAt = DateTime.parse(delivery['created_at']);
        return createdAt.day == tomorrow.day &&
               createdAt.month == tomorrow.month &&
               createdAt.year == tomorrow.year;
      }).toList();
    } else if (_filter == 'Next 7 Days') {
      return _deliveries.where((delivery) {
        DateTime createdAt = DateTime.parse(delivery['created_at']);
        return createdAt.isAfter(now) && createdAt.isBefore(nextWeek);
      }).toList();
    } else {
      return _deliveries;
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchDeliveries();
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> filteredDeliveries = _filterDeliveries();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchDeliveries,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.local_shipping),
              title: const Text('Delivery Form'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DeliveryForm()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment_return),
              title: const Text('Collection Form'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CollectionForm()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pushReplacementNamed(context, '/deliveryLogin');
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              value: _filter,
              onChanged: (String? newValue) {
                setState(() {
                  _filter = newValue!;
                });
              },
              items: <String>['All', 'Today', 'Tomorrow', 'Next 7 Days']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(fontSize: 16, color: Colors.red),
                        ),
                      )
                    : filteredDeliveries.isEmpty
                        ? const Center(
                            child: Text(
                              'No deliveries assigned yet.',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredDeliveries.length,
                            itemBuilder: (context, index) {
                              final delivery = filteredDeliveries[index];
                              return Card(
                                margin: const EdgeInsets.all(8.0),
                                child: ListTile(
                                  title: Text(
                                    'Delivery Address: ${delivery['delivery_address']}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Status: ${delivery['delivery_status']}'),
                                      Text('Created At: ${formatDate(delivery['created_at'])}'),
                                      if (delivery['delivery_status'] == 'completed')
                                        Text('Completed At: ${formatDate(delivery['completed_at'])}'),
                                      if (delivery['delivery_images'] != null)
                                        Text('Images: ${delivery['delivery_images']}'),
                                    ],
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