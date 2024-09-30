import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart'; // Import GetX

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({Key? key}) : super(key: key);

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  BluetoothDevice? device;
  List<BluetoothService> _services = [];
  BluetoothCharacteristic? _writeCharacteristic;
  BluetoothCharacteristic? _readCharacteristic;
  String _receivedData = '';

  @override
  void initState() {
    super.initState();
    device = Get.arguments
        as BluetoothDevice; // Retrieve the device from GetX arguments
    _discoverServices();
  }

  Future<void> _discoverServices() async {
    if (device != null) {
      List<BluetoothService> services = await device!.discoverServices();
      setState(() {
        _services = services;
      });

      // Find the characteristics for writing and reading
      for (BluetoothService service in services) {
        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
          if (characteristic.properties.write) {
            _writeCharacteristic = characteristic;
          }
          if (characteristic.properties.read ||
              characteristic.properties.notify) {
            _readCharacteristic = characteristic;

            // Set up listening for notifications if the characteristic supports it
            if (characteristic.properties.notify) {
              await characteristic.setNotifyValue(true);
              characteristic.value.listen((value) {
                setState(() {
                  _receivedData = utf8.decode(value);
                });
              });
            }
          }
        }
      }
    }
  }

  Future<void> _sendCommand(String hexCommand) async {
    if (_writeCharacteristic != null) {
      try {
        Uint8List command = _convertHexToBytes(hexCommand);

        // Write with response (default behavior)
        await _writeCharacteristic!.write(command);
      } catch (e) {
        _showErrorSnackbar("Write Error: $e");
        print("Error sending command: $e");
      }
    } else {
      _showErrorSnackbar("Write characteristic not found.");
    }
  }

  Uint8List _convertHexToBytes(String hex) {
    hex = hex.replaceAll(' ', '');
    return Uint8List.fromList(List.generate(hex.length ~/ 2,
        (i) => int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16)));
  }

  void _showErrorSnackbar(String message) {
    final snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Device: ${device?.name ?? "Unknown"}'),
      ),
      body: Column(
        children: [
          if (_writeCharacteristic != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  const Text('Enter HEX command:'),
                  TextField(
                    onSubmitted: (command) {
                      _sendCommand(command); // Send HEX command from input
                    },
                    decoration: const InputDecoration(
                      hintText: 'e.g. 48656c6c6f', // Example for "Hello" in HEX
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      _sendCommand("BB00220000227E"); // Send predefined command
                    },
                    child: const Text("Send Command BB00220000227E"),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          if (_readCharacteristic != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  const Text('Received Data:'),
                  Text(_receivedData.isNotEmpty
                      ? _receivedData
                      : 'No data received yet.'),
                ],
              ),
            ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              device?.disconnect(); // Disconnect from the device
              Get.toNamed(
                  '/bluetooth'); // Navigate back to the Bluetooth screen
            },
            child: const Text("Disconnect"),
          ),
        ],
      ),
    );
  }
}
