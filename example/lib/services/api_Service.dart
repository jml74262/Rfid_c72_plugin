import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:rfid_c72_plugin_example/models/prodEtiquetasRFID.dart';

class ApiService {
  static const String baseUrl = 'http://172.16.10.31/api';

  Future<ProdEtiquetasRFID> getLabelByRFID(String code) async {
    final response = await http
        .get(Uri.parse('$baseUrl/RfidLabel/GetLabelByTraceabilityCode/$code'));

    if (response.statusCode == 200) {
      return ProdEtiquetasRFID.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load label');
    }
  }
}
