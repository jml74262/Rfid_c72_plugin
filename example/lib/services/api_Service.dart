import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:rfid_c72_plugin_example/models/prodEtiquetasRFID.dart';
import 'dart:typed_data';

class ApiService {
  static const String baseUrl = 'http://172.16.10.31/api';
  // local server
  // static const String baseUrl = 'http://172.16.20.52:5001/api';

  // Method to get label by RFID
  Future<ProdEtiquetasRFID> getLabelByRFID(String code) async {
    final response = await http
        .get(Uri.parse('$baseUrl/RfidLabel/GetLabelByTraceabilityCode/$code'));

    if (response.statusCode == 200) {
      return ProdEtiquetasRFID.fromJson(jsonDecode(response.body));
    } else {
      // Return the response
      throw (response.body);
    }
  }

  // Method to send EPCs and generate/download Excel file
  Future<Uint8List> sendEPCsAndGenerateExcel(List<String> epcs) async {
    const apiUrl =
        '$baseUrl/RfidLabel/generate-excel-from-handheld'; // Replace with your API endpoint

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(epcs), // Ensure the list is correctly serialized
    );

    if (response.statusCode == 200) {
      return response.bodyBytes; // Return the file bytes
    } else {
      throw Exception('Failed to generate Excel file: ${response.body}');
    }
  }

  // Mehod to send EPCs and generate/download Excel file for DESTINY INVENTORY
  Future<Uint8List> sendEPCsAndGenerateExcelDestinyInventory(
      List<String> epcs) async {
    const apiUrl =
        '$baseUrl/LabelDestiny/generate-excel-from-handheld'; // Replace with your API endpoint

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(epcs), // Ensure the list is correctly serialized
    );

    if (response.statusCode == 200) {
      return response.bodyBytes; // Return the file bytes
    } else {
      throw Exception('Failed to generate Excel file: ${response.body}');
    }
  }

  Future<Uint8List> sendEPCsAndGenerateExcelQualityInventory(
      List<String> epcs) async {
    print('sendEPCsAndGenerateExcelQualityInventory');
    const apiUrl =
        '$baseUrl/LabelQuality/generate-excel-from-handheld'; // Replace with your API endpoint

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(epcs), // Ensure the list is correctly serialized
    );

    if (response.statusCode == 200) {
      return response.bodyBytes; // Return the file bytes
    } else {
      throw Exception('Failed to generate Excel file: ${response.body}');
    }
  }

  Future<Uint8List> sendEPCsAndGenerateExcelVasoInventory(
      List<String> epcs) async {
    print('sendEPCsAndGenerateExcelVasoInventory');
    const apiUrl =
        '$baseUrl/Vaso/generate-excel-from-handheld'; // Replace with your API endpoint

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(epcs), // Ensure the list is correctly serialized
    );

    if (response.statusCode == 200) {
      return response.bodyBytes; // Return the file bytes
    } else {
      throw Exception('Failed to generate Excel file: ${response.body}');
    }
  }

  // Method to save inventory record
  Future<void> saveInventoryRecord(
      List<String> epcs,
      DateTime fechaInventario,
      String formatoEtiqueta,
      String operador,
      String ubicacion,
      String nombreArchivo) async {
    const apiUrl =
        '$baseUrl/RfidLabel/generate-excel-from-handheld-save-inventory'; // Replace with your API endpoint

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'epcs': epcs,
        'fechaInventario': fechaInventario.toIso8601String(),
        'formatoEtiqueta': formatoEtiqueta,
        'operador': operador,
        'ubicacion': ubicacion,
        'nombreArchivo': nombreArchivo
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to save inventory record: ${response.body}');
    }
  }

  Future<Uint8List> generateSAPFile(List<String> epcs) async {
    const apiUrl = '$baseUrl/SAP'; // Replace with your API endpoint

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(epcs), // Ensure the list is correctly serialized
    );

    if (response.statusCode == 200) {
      return response.bodyBytes; // Return the file bytes
    } else {
      throw Exception('Failed to generate Excel file: ${response.body}');
    }
  }

  // Future<void> sendEPCsAndGenerateExcel2(List<String> epcs) async {
  //   final url = Uri.parse('$baseUrl/RfidLabel/generate-excel');

  //   final response = await http.post(
  //     url,
  //     headers: {
  //       'Content-Type': 'application/json',
  //     },
  //     body: jsonEncode(epcs), // Ensure the list is correctly serialized
  //   );

  //   if (response.statusCode == 200) {
  //     // Handle successful response, such as saving the file or showing a message
  //     // In this case, you may want to download the file or open it
  //   } else {
  //     // Handle error response
  //     throw Exception('Failed to generate Excel file: ${response.body}');
  //   }
  // }
}
