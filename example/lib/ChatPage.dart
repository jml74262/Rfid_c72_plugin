import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class ChatPage extends StatefulWidget {
  final BluetoothDevice server;
  const ChatPage({required this.server});

  @override
  _ChatPage createState() => _ChatPage();
}

class _ChatPage extends State<ChatPage> {
  BluetoothConnection? connection;
  bool isConnecting = true;
  bool get isConnected => connection != null && connection!.isConnected;
  bool isDisconnecting = false;

  List<String> messages = [];
  final TextEditingController textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    BluetoothConnection.toAddress(widget.server.address).then((_connection) {
      connection = _connection;
      setState(() {
        isConnecting = false;
      });

      connection!.input!.listen(_onDataReceived).onDone(() {
        if (isDisconnecting) {
          print('Disconnected locally');
        } else {
          print('Disconnected remotely');
        }
        if (this.mounted) {
          setState(() {});
        }
      });
    });
  }

  void _onDataReceived(Uint8List data) {
    String received = String.fromCharCodes(data);
    setState(() {
      messages.add(received);
    });
  }

  void _sendMessage(String message) {
    if (message.isNotEmpty && isConnected) {
      connection!.output.add(Uint8List.fromList(utf8.encode(message + "\r\n")));
      setState(() {
        messages.add(message);
      });
      textController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isConnecting
            ? 'Connecting...'
            : isConnected
                ? 'Connected to ${widget.server.name}'
                : 'Disconnected'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              children: messages
                  .map((message) => ListTile(title: Text(message)))
                  .toList(),
            ),
          ),
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: textController,
                  decoration: InputDecoration(
                    labelText: isConnected ? 'Enter message' : 'Disconnected',
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send),
                onPressed: () => _sendMessage(textController.text),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    if (isConnected) {
      isDisconnecting = true;
      connection?.dispose();
      connection = null;
    }
    super.dispose();
  }
}
