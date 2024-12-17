import 'package:flutter/material.dart';
import 'requisition_form.dart';
import 'return_form.dart';

class SupervisorDashboard extends StatelessWidget {
  const SupervisorDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supervisor Dashboard'),
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
              leading: const Icon(Icons.assignment),
              title: const Text('Requisition'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RequisitionForm()),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.assignment_return),
              title: const Text('Return Form'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ReturnForm()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pushReplacementNamed(context, '/supervisorLogin');
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Metrics',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                Flexible(child: MetricCard(title: 'Total Orders', value: '120')),
                Flexible(child: MetricCard(title: 'Pending Deliveries', value: '30')),
                Flexible(child: MetricCard(title: 'Returns', value: '10')),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'Orders Table',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Order ID')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Delivery Address')),
                    DataColumn(label: Text('Assigned To')),
                    DataColumn(label: Text('Date Required')),
                  ],
                  rows: const [
                    DataRow(cells: [
                      DataCell(Text('001')),
                      DataCell(Text('Pending')),
                      DataCell(Text('123 Main St')),
                      DataCell(Text('John Doe')),
                      DataCell(Text('2023-12-10')),
                    ]),
                    DataRow(cells: [
                      DataCell(Text('002')),
                      DataCell(Text('Delivered')),
                      DataCell(Text('456 Elm St')),
                      DataCell(Text('Jane Smith')),
                      DataCell(Text('2023-12-08')),
                    ]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Charts',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Placeholder(), // Replace with a chart widget
                  ),
                  Expanded(
                    child: Placeholder(), // Replace with another chart widget
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

class MetricCard extends StatelessWidget {
  final String title;
  final String value;

  const MetricCard({Key? key, required this.title, required this.value})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
