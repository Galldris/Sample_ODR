import 'package:flutter/material.dart';
import 'screens/supervisor_login.dart';
import 'screens/delivery_login.dart';
import 'screens/supervisor_dashboard.dart';
import 'screens/delivery_dashboard.dart';
import 'screens/odg_login.dart';
import 'screens/odg_dashboard.dart';
import 'screens/site_manager_login.dart';
import 'screens/site_manager_dashboard.dart';
import 'screens/register_new_account.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor: Colors.yellow,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/supervisorLogin': (context) => const SupervisorLogin(),
        '/deliveryLogin': (context) => const DeliveryLogin(),
        '/supervisorDashboard': (context) => const SupervisorDashboard(),
        '/deliveryDashboard': (context) => DeliveryDashboard(userId: 2), // Static userId for testing
        '/odgLogin': (context) => const ODGLogin(),
        '/odgDashboard': (context) => const ODGDashboard(),
        '/siteManagerLogin': (context) => const SiteManagerLogin(),
        '/siteManagerDashboard': (context) => SiteManagerDashboard(userId: 1), // Static userId for testing
        '/registerNewAccount': (context) => const RegisterNewAccount(),
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Align(
                alignment: Alignment.topRight,
                child: Text(
                  "Order, Delivery, Return",
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 25,
                    color: Color(0xFF007349),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Streamlining requisitions, deliveries & returns to construction projects",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: Color.fromARGB(255, 0, 12, 8),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.only(top: 50.0), // Adjust the top padding as needed
                child: Text(
                  "Select your role to get started.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lato',
                  ),
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/supervisorLogin');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFCF20),
                  textStyle: const TextStyle(
                    fontSize: 20,
                    color: Color.fromARGB(255, 7, 0, 0),
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lato',
                  ),
                ),
                child: const Text("Supervisor"),
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/deliveryLogin');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFCF20),
                  textStyle: const TextStyle(
                    fontSize: 20,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lato',
                  ),
                ),
                child: const Text("Delivery Personnel"),
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/odgLogin');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFCF20),
                  textStyle: const TextStyle(
                    fontSize: 20,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lato',
                  ),
                ),
                child: const Text("ODG Staff"),
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/siteManagerLogin');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFCF20),
                  textStyle: const TextStyle(
                    fontSize: 20,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lato',
                  ),
                ),
                child: const Text("Site Manager"),
              ),
              
              
              
              
              
              const SizedBox(height: 35),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/registerNewAccount');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: BorderSide(color: const Color(0xFFFFCF20), width: 2),
                  textStyle: const TextStyle(
                    fontSize: 20,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lato',
                  ),
                ),
                child: const Text(
                  "Register New Account",
                  style: TextStyle(color: Colors.black),
                ),
           
              ),
           
           
            ],
          ),
        ),
      ),
    );
  }
}