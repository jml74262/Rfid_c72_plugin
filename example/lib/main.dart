import 'package:flutter/material.dart';
import 'package:rfid_c72_plugin_example/entrada_sap_screen.dart';
import 'package:rfid_c72_plugin_example/rfid_scanner.dart';
import 'package:get/get.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      home: RfidScanner(),
      getPages: [
        GetPage(name: '/', page: () => RfidScanner()),
        GetPage(name: '/entrada_sap', page: () => EntradaSapScreen()),
      ],
    );
  }
}
