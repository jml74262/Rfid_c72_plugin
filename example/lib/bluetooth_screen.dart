import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import './BluetoothDeviceListEntry.dart';
import './ChatPage.dart'; // Import the ChatPage

class DiscoveryPage extends StatefulWidget {
  const DiscoveryPage({this.start = true});
  final bool start;

  @override
  _DiscoveryPage createState() => _DiscoveryPage();
}

class _DiscoveryPage extends State<DiscoveryPage> {
  StreamSubscription<BluetoothDiscoveryResult>? _streamSubscription;
  List<BluetoothDiscoveryResult> results =
      List<BluetoothDiscoveryResult>.empty(growable: true);
  bool isDiscovering = false;

  @override
  void initState() {
    super.initState();
    isDiscovering = widget.start;
    if (isDiscovering) {
      _startDiscovery();
    }
  }

  void _restartDiscovery() {
    setState(() {
      results.clear();
      isDiscovering = true;
    });
    _startDiscovery();
  }

  void _startDiscovery() {
    _streamSubscription =
        FlutterBluetoothSerial.instance.startDiscovery().listen((r) {
      setState(() {
        final existingIndex = results.indexWhere(
            (element) => element.device.address == r.device.address);
        if (existingIndex >= 0)
          results[existingIndex] = r;
        else
          results.add(r);
      });
    });

    _streamSubscription!.onDone(() {
      setState(() {
        isDiscovering = false;
      });
    });
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: isDiscovering
            ? Text('Discovering devices')
            : Text('Discovered devices'),
        actions: <Widget>[
          isDiscovering
              ? FittedBox(
                  child: Container(
                    margin: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white)),
                  ),
                )
              : IconButton(
                  icon: Icon(Icons.replay), onPressed: _restartDiscovery),
        ],
      ),
      body: ListView.builder(
        itemCount: results.length,
        itemBuilder: (BuildContext context, index) {
          BluetoothDiscoveryResult result = results[index];
          final device = result.device;
          return BluetoothDeviceListEntry(
            device: device,
            rssi: result.rssi,
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) =>
                    ChatPage(server: device), // Navigate to the ChatPage on tap
              ));
            },
            onLongPress: () async {
              // Bonding logic here if needed
            },
          );
        },
      ),
    );
  }
}
