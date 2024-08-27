import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rfid_c72_plugin/rfid_c72_plugin.dart';
import 'package:rfid_c72_plugin/tag_epc.dart';
import 'package:get/get.dart';
import 'package:rfid_c72_plugin_example/models/prodEtiquetasRFID.dart'; // Make sure to update this with the correct absolute path
import 'package:rfid_c72_plugin_example/services/api_service.dart'; // Make sure to update this with the correct absolute path

class RfidScanner extends StatefulWidget {
  const RfidScanner({Key? key}) : super(key: key);

  @override
  State<RfidScanner> createState() => _RfidScannerState();
}

class _RfidScannerState extends State<RfidScanner> {
  String _platformVersion = 'Unknown';
  bool _isConnected = false;
  bool _isContinuousCall = false;
  bool _is2dscanCall = false;
  bool _isLoading = true;
  int _totalEPC = 0;

  final TextEditingController _powerLevelController = TextEditingController();
  final List<TagEpc> _data = [];
  final List<String> _EPC = [];

  @override
  void initState() {
    super.initState();
    _initializeRfidPlugin();
    // Add a listener to capture hardware key presses
    RawKeyboard.instance.addListener(_handleKeyEvent);
  }

  @override
  void dispose() {
    _closeAllConnections();
    RawKeyboard.instance.removeListener(_handleKeyEvent); // Remove the listener
    super.dispose();
  }

  Future<void> _initializeRfidPlugin() async {
    try {
      _platformVersion = await RfidC72Plugin.platformVersion ?? 'Unknown';
      _setupListeners();
      await RfidC72Plugin.connect;
      await RfidC72Plugin.connectBarcode;
    } on PlatformException {
      _platformVersion = 'Failed to get platform version.';
    }

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });
  }

  void _setupListeners() {
    RfidC72Plugin.connectedStatusStream
        .receiveBroadcastStream()
        .listen(_updateIsConnected);
    RfidC72Plugin.tagsStatusStream.receiveBroadcastStream().listen(_updateTags);
  }

  void _handleKeyEvent(RawKeyEvent event) {
    print('Pressed key code: ${event.logicalKey.keyId}');
    if (event is RawKeyDownEvent) {
      // Print the key code for debugging purposes

      // Replace 'yourKeyCodeHere' with the actual key code of the dedicated button
      // You can find out the key code by checking the print statement when you press the button
      // const int dedicatedButtonKeyCode = /* yourKeyCodeHere */;

      // if (event.logicalKey.keyId == dedicatedButtonKeyCode) {
      //   // Trigger the single reading method
      //   _startSingleReading();
      // }
    }
  }

  void _updateTags(dynamic result) {
    setState(() {
      _data.addAll(TagEpc.parseTags(result));
      _totalEPC = _data.toSet().length;

      // Fetch the label info for each tag and show it in a modal
      for (var tag in _data) {
        _fetchLabelAndShowModal(tag.epc);
      }
    });
  }

  Future<void> _fetchLabelAndShowModal(String epc) async {
    try {
      ProdEtiquetasRFID label = await ApiService().getLabelByRFID(epc);
      _showLabelModal(label);
    } catch (e) {
      _showError("Error fetching label: $e");
    }
  }

  void _showLabelModal(ProdEtiquetasRFID label) {
    Get.defaultDialog(
      title: "Información de la etiqueta",
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("ID: ${label.id}"),
          Text("Area: ${label.area}"),
          Text("Producto: ${label.claveProducto}"),
          Text("Peso Bruto: ${label.pesoBruto}"),
          Text("Peso Neto: ${label.pesoNeto}"),
          Text("Piezas: ${label.piezas}"),
          Text("Fecha: ${label.fecha}"),
          Text("Operador: ${label.operador}"),
          Text("Turno: ${label.turno}"),
          Text("Trazabilidad: ${label.trazabilidad}"),
          Text("RFID: ${label.rfid}")
        ],
      ),
      textConfirm: "Cerrar",
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back();
      },
    );
  }

  void _updateIsConnected(dynamic isConnected) {
    setState(() {
      _isConnected = isConnected;
    });
  }

  void _closeAllConnections() {
    RfidC72Plugin.stopScan;
    RfidC72Plugin.close;
  }

  Future<void> _toggleContinuousScan() async {
    bool? isStarted = _isContinuousCall
        ? await RfidC72Plugin.stop
        : await RfidC72Plugin.startContinuous;

    setState(() {
      _isContinuousCall = !_isContinuousCall;
    });

    if (isStarted == null || !isStarted) {
      _showError('Failed to start/stop continuous scan');
    }
  }

  Future<void> _clearData() async {
    await RfidC72Plugin.clearData;
    setState(() {
      _data.clear();
      _totalEPC = 0;
    });
  }

  Future<void> _toggle2DBarcodeScan() async {
    setState(() {
      _is2dscanCall = !_is2dscanCall;
    });

    if (_is2dscanCall) {
      await RfidC72Plugin.scanBarcode;
      String? scannedCode = await RfidC72Plugin.readBarcode;
      if (scannedCode != null && scannedCode.isNotEmpty) {
        setState(() {
          _data.add(TagEpc(
            epc: scannedCode,
            id: '',
            count: '',
            rssi: '',
          ));
          _totalEPC = _data.toSet().length;

          // Fetch the label info for the scanned barcode and show it in a modal
          _fetchLabelAndShowModal(scannedCode);
        });
      }
    } else {
      await RfidC72Plugin.stopScan;
    }
  }

  void _showError(String message) {
    Get.snackbar(
      "Error",
      message,
      backgroundColor: Colors.redAccent,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rfid Reader C72'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _buildHeaderIcon(),
                  _buildPowerLevel(),
                  _buildControlButtons(),
                  _buildClearButton(),
                  _build2DBarcodeButton(),
                  _buildTotalEPCDisplay(),
                  _buildTagList(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderIcon() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(3.0),
        child: Icon(
          Icons.barcode_reader,
          size: 100,
        ),
      ),
    );
  }

  Widget _buildPowerLevel() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Container(
          width: 100,
          child: TextFormField(
            controller: _powerLevelController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              labelText: 'Power Level',
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(29.0),
            ),
          ),
          child: const Text(
            'Set Power Level',
            style: TextStyle(color: Colors.white),
          ),
          onPressed: () async {
            final value = _powerLevelController.text;
            if (_validatePowerLevel(value)) {
              bool? result = await RfidC72Plugin.setPowerLevel(value);
              if (result != null && result) {
                Get.snackbar(
                    "Potencia cambiada", "Potencia cambiada a $value dBm",
                    backgroundColor: Color.fromARGB(255, 150, 206, 153));
              } else {
                Get.snackbar(
                  "Error",
                  "Ocurrió un error inesperado al cambiar la potencia",
                  backgroundColor: Color.fromARGB(255, 206, 150, 150),
                );
              }
            } else {
              Get.snackbar(
                "Error",
                "Por favor ingresa un valor entre 5 y 30",
                backgroundColor: Color.fromARGB(255, 221, 211, 118),
              );
            }
          },
        ),
      ],
    );
  }

  bool _validatePowerLevel(String value) {
    final int? powerLevel = int.tryParse(value);
    return powerLevel != null && powerLevel >= 1 && powerLevel <= 30;
  }

  Widget _buildControlButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(29.0),
              ),
            ),
            child: const Text(
              'Start Single Reading',
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () async {
              await RfidC72Plugin.startSingle;
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _isContinuousCall ? Colors.red : Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(29.0),
              ),
            ),
            child: Text(
              _isContinuousCall
                  ? 'Stop Continuous Reading'
                  : 'Start Continuous Reading',
              style: const TextStyle(color: Colors.white),
            ),
            onPressed: _toggleContinuousScan,
          ),
        ],
      ),
    );
  }

  Widget _buildClearButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(29.0),
        ),
      ),
      child: const Text(
        'Clear Data',
        style: TextStyle(color: Colors.white),
      ),
      onPressed: _clearData,
    );
  }

  Widget _build2DBarcodeButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _is2dscanCall ? Colors.red : Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(29.0),
            ),
          ),
          child: Text(
            _is2dscanCall ? 'Stop 2D Barcode scan' : 'Start 2D Barcode scan',
            style: const TextStyle(color: Colors.white),
          ),
          onPressed: _toggle2DBarcodeScan,
        ),
      ],
    );
  }

  Widget _buildTotalEPCDisplay() {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 50,
      color: Colors.blue[400],
      child: Center(
        child: Text(
          'Total EPC: $_totalEPC',
          style: GoogleFonts.lato(
            color: Colors.black,
            fontSize: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildTagList() {
    return Column(
      children: _data.map((TagEpc tag) {
        _EPC.add(tag.epc.replaceAll(RegExp('EPC:'), ''));
        return Card(
          color: Colors.blue.shade50,
          child: Container(
            width: 330,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Tag: ${tag.epc.replaceAll(RegExp('EPC:'), '')}',
              style: TextStyle(color: Colors.blue.shade800),
            ),
          ),
        );
      }).toList(),
    );
  }
}
