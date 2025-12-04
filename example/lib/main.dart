import 'package:flutter/material.dart';
import 'package:gms_services/gms_services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GmsServices.instance.init();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Plugin example app')),
        body: Center(child: Text('Running on: \n')),
      ),
    );
  }
}
