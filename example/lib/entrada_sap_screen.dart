import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rfid_c72_plugin/rfid_c72_plugin.dart';
import 'package:rfid_c72_plugin/tag_epc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:rfid_c72_plugin_example/models/prodEtiquetasRFID.dart';
import 'package:rfid_c72_plugin_example/services/api_Service.dart';

class EntradaSapScreen extends StatefulWidget {
  @override
  _EntradaSapScreenState createState() => _EntradaSapScreenState();
}

class _EntradaSapScreenState extends State<EntradaSapScreen> {
  String _platformVersion = 'Unknown';
  bool _isConnected = false;
  bool _isContinuousCall = false;
  bool _is2dscanCall = false;
  bool _isLoading = true;
  int _totalEPC = 0;

  final scaffolkey = GlobalKey<ScaffoldState>();
  final Set<String> _uniqueEPCs = <String>{};
  final AudioPlayer _audioPlayer = AudioPlayer(); // Instantiate the AudioPlayer
  final TextEditingController _powerLevelController = TextEditingController();
  final List<TagEpc> _data = [];

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entradas SAP'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _closeAllConnections();
            Get.toNamed(
                '/'); // Replace '/yourRoute' with the actual named route you want to navigate to
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // _buildHeaderIcon(),
                  _buildControlButtons(),
                  _buildClearButton(),
                  const SizedBox(height: 10), //Build space

                  // // _build2DBarcodeButton(),
                  // _buildExcelButtons(),
                  // const SizedBox(height: 10),
                  _buildPowerLevel(),
                  const SizedBox(height: 10), //Build space
                  _buildSapButton(),
                  const SizedBox(height: 10), //Build space
                  _buildTotalEPCDisplay(),
                  _buildTagList(),
                ],
              ),
            ),
    );
  }

  Future<void> _initializeRfidPlugin() async {
    try {
      _platformVersion = await RfidC72Plugin.platformVersion ?? 'Unknown';
      _setupListeners();
      await RfidC72Plugin.connect;
      await RfidC72Plugin.connectBarcode;
      await RfidC72Plugin.setPowerLevel("1");
    } on PlatformException {
      _platformVersion = 'Failed to get platform version.';
    }

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });
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

  Future<void> _startSingleReading() async {
    try {
      await RfidC72Plugin.startSingle;
      // _playBeepSoundAtMaxVolume(); // Play the beep sound after a successful read
    } catch (e) {
      _showError('Error during single read: $e');
    }
  }

  Future<void> _clearData() async {
    await RfidC72Plugin.clearData;
    setState(() {
      _data.clear();
      _totalEPC = 0;
      _uniqueEPCs.clear();
    });
  }

  Future<void> _fetchLabelAndShowModal(String epc) async {
    try {
      ProdEtiquetasRFID label = await ApiService().getLabelByRFID(epc);
      _showLabelModal(label);
    } catch (e) {
      _showError("Error al verificar: $e");
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

  Widget _buildControlButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5.0),
              ),
            ),
            onPressed: _startSingleReading,
            child: const Text(
              'Lectura Individual',
              style: TextStyle(color: Colors.white),
            ), // Trigger single reading and play beep
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _isContinuousCall ? Colors.red : Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5.0),
              ),
            ),
            onPressed: _toggleContinuousScan,
            child: Text(
              _isContinuousCall ? 'Parar Lectura Continua' : 'Lectura Continua',
              style: const TextStyle(color: Colors.white),
            ),
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
          borderRadius: BorderRadius.circular(5.0),
        ),
      ),
      child: const Text(
        'Limpiar Información',
        style: TextStyle(color: Colors.white),
      ),
      onPressed: () {
        // Show a confirmation dialog before clearing the data
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Confirmación'),
              content: const Text(
                  '¿Estás seguro de que quieres limpiar toda la información?'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Dismiss the dialog
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white),
                  onPressed: () {
                    _clearData(); // Call the clear data function
                    Navigator.of(context).pop(); // Dismiss the dialog
                  },
                  child: const Text('Limpiar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPowerLevel() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Container(
          width: 150, // Increase width for better usability
          padding: const EdgeInsets.symmetric(
              horizontal: 8.0), // Add horizontal padding
          decoration: BoxDecoration(
            color: Colors.white, // Background color
            borderRadius: BorderRadius.circular(5.0), // Rounded corners
            border: Border.all(
                color: Colors.grey.shade300,
                width: 1.0), // Border color and width
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2), // Shadow color
                spreadRadius: 2, // How wide the shadow spreads
                blurRadius: 5, // How much the shadow blurs
                offset: Offset(0, 2), // Offset for shadow position
              ),
            ],
          ),
          child: TextFormField(
            controller: _powerLevelController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16, // Increase font size
              color: Colors.black87, // Text color
            ),
            decoration: InputDecoration(
              labelStyle: TextStyle(
                color: Colors.grey.shade700, // Label text color
                fontWeight: FontWeight.w500, // Label text weight
              ),
              prefixIcon:
                  Icon(Icons.power, color: Colors.grey.shade600), // Add icon
              border: InputBorder.none, // Remove default border
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5.0),
            ),
          ),
          child: const Text(
            'Ajustar Potencia',
            style: TextStyle(color: Colors.white),
          ),
          onPressed: () async {
            final value = _powerLevelController.text;
            if (_validatePowerLevel(value)) {
              bool? result = await RfidC72Plugin.setPowerLevel(value);
              if (result != null && result) {
                Get.snackbar(
                    "Potencia cambiada", "Potencia cambiada a $value dBm",
                    backgroundColor: const Color.fromARGB(255, 150, 206, 153));
              } else {
                Get.snackbar(
                  "Error",
                  "Ocurrió un error inesperado al cambiar la potencia",
                  backgroundColor: const Color.fromARGB(255, 206, 150, 150),
                );
              }
            } else {
              Get.snackbar(
                "Error",
                "Por favor ingresa un valor entre 5 y 30",
                backgroundColor: const Color.fromARGB(255, 221, 211, 118),
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
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.5, // 50% of screen height
      child: ListView.builder(
        itemCount: _data.length,
        itemBuilder: (context, index) {
          final tag = _data[index];
          return ListTile(
            title: Text(tag.epc),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red), // Delete icon
              onPressed: () {
                _deleteTag(index); // Call the delete function
              },
            ),
            onTap: () {
              _fetchLabelAndShowModal(tag.epc); // Show modal on tap
            },
          );
        },
      ),
    );
  }

  Future<void> _sendUniqueEPCToSAP() async {
    final apiService = ApiService();
    final epcLISt = _uniqueEPCs.toList();

    try {
      final fileBytes = await apiService.generateSAPFile(epcLISt);
      final String timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('.', '-');
      final fileName = 'sap_file_$timestamp.txt';
      await downloadExcelFile(fileBytes);
      Get.snackbar('Success', 'Archivo descargado correctamente',
          backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar("Error", "Ocurrió un error al enviar los datos a SAP",
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  Future<void> downloadExcelFile(Uint8List bytes) async {
    // bool permissionGranted = await requestStoragePermission();
    // if (!permissionGranted) {
    //   // Handle the case when permission is not granted
    //   print('Storage permission denied');
    //   Get.snackbar("Permission Denied",
    //       "Storage permission is required to save the file.");
    //   return;
    // }
    final String timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');

    final directory = await getExternalStorageDirectory();
    final filePath = '${directory!.path}/rfid_data_$timestamp.xlsx';

    final file = File(filePath);
    await file.writeAsBytes(bytes);

    // print(' $filePath');

    // Show snackbar with a button to open the file
    Get.snackbar(
      "Archivo descargado",
      "Ruta: $filePath",
      backgroundColor: const Color.fromARGB(255, 150, 206, 153),
      mainButton: TextButton(
        onPressed: () {
          _openFile(filePath); // Call the function to open the file
        },
        child: const Text(
          "Abrir",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Future<void> _openFile(String filePath) async {
    final result = await OpenFile.open(filePath);
    if (result.type != ResultType.done) {
      Get.snackbar(
        "Error",
        "Error al abrir el archivo: ${result.message}",
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 3),
        colorText: Colors.white,
      );
    }
  }

  // _buildSapButton, widget to build the SAP button
  Widget _buildSapButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5.0),
        ),
      ),
      onPressed: _sendUniqueEPCToSAP,
      child: const Text(
        'Enviar a SAP',
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  void _deleteTag(int index) {
    setState(() {
      // Save the epc to be deleted
      final epc = _data[index].epc;
      _data.removeAt(index); // Remove the element at the given index
      _totalEPC = _data.toSet().length; // Update the total EPC count
      _uniqueEPCs.remove(epc); // Remove the epc from the set
    });

    Get.snackbar('Eliminada', 'La etiqueta ha sido eliminada de la lista',
        backgroundColor: Colors.redAccent, colorText: Colors.white);
  }

  void _showError(String message) {
    Get.snackbar(
      "Error",
      message,
      backgroundColor: Colors.redAccent,
      duration: const Duration(milliseconds: 900),
      colorText: Colors.white,
    );
  }

  void _setupListeners() {
    RfidC72Plugin.connectedStatusStream
        .receiveBroadcastStream()
        .listen(_updateIsConnected);
    RfidC72Plugin.tagsStatusStream.receiveBroadcastStream().listen(_updateTags);
  }

  void _updateIsConnected(dynamic isConnected) {
    setState(() {
      _isConnected = isConnected;
    });
  }

  void _updateTags(dynamic result) {
    // Start or reset debounce timer
    // _debounceTimer?.cancel();
    // _debounceTimer = Timer(_debounceDuration, () {
    List<TagEpc> newTags = TagEpc.parseTags(result);

    for (var tag in newTags) {
      if (_uniqueEPCs.add(tag.epc)) {
        // Only adds if not already present
        _data.add(tag);
        _playBeepSoundAtMaxVolume();
      }
    }

    setState(() {
      _totalEPC = _uniqueEPCs.length;
    });
    // });
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      const int dedicatedButtonKeyCode = 73014444325;

      if (event.logicalKey.keyId == dedicatedButtonKeyCode) {
        _startSingleReading(); // Trigger single reading
      }
    }
  }

  void _closeAllConnections() {
    RfidC72Plugin.stopScan;
    RfidC72Plugin.close;
  }

  Future<void> _playBeepSoundAtMaxVolume() async {
    // print('Attempting to play beep sound at max volume');

    try {
      // Play the beep sound
      await _audioPlayer.play(AssetSource('beep.mp3'));
    } catch (e) {
      // print('Error playing beep sound: $e');
    }
  }
}
