class ProdEtiquetasRFID {
  int id;
  String area;
  DateTime fecha;
  String claveProducto;
  String nombreProducto;
  String claveOperador;
  String operador;
  String turno;
  double pesoTarima;
  double pesoBruto;
  double pesoNeto;
  double piezas;
  String trazabilidad;
  String orden;
  String rfid;
  int status;
  String? uom;
  DateTime? createdAt;

  ProdEtiquetasRFID({
    required this.id,
    required this.area,
    required this.fecha,
    required this.claveProducto,
    required this.nombreProducto,
    required this.claveOperador,
    required this.operador,
    required this.turno,
    required this.pesoTarima,
    required this.pesoBruto,
    required this.pesoNeto,
    required this.piezas,
    required this.trazabilidad,
    required this.orden,
    required this.rfid,
    required this.status,
    this.uom,
    this.createdAt,
  });

  factory ProdEtiquetasRFID.fromJson(Map<String, dynamic> json) {
    return ProdEtiquetasRFID(
      id: json['id'],
      area: json['area'],
      fecha: DateTime.parse(json['fecha']),
      claveProducto: json['claveProducto'],
      nombreProducto: json['nombreProducto'],
      claveOperador: json['claveOperador'],
      operador: json['operador'],
      turno: json['turno'],
      pesoTarima: (json['pesoTarima'] as num).toDouble(),
      pesoBruto: (json['pesoBruto'] as num).toDouble(),
      pesoNeto: (json['pesoNeto'] as num).toDouble(),
      piezas: (json['piezas'] as num).toDouble(),
      trazabilidad: json['trazabilidad'],
      orden: json['orden'],
      rfid: json['rfid'],
      status: json['status'],
      uom: json['uom'],
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'area': area,
      'fecha': fecha.toIso8601String(),
      'claveProducto': claveProducto,
      'nombreProducto': nombreProducto,
      'claveOperador': claveOperador,
      'operador': operador,
      'turno': turno,
      'pesoTarima': pesoTarima,
      'pesoBruto': pesoBruto,
      'pesoNeto': pesoNeto,
      'piezas': piezas,
      'trazabilidad': trazabilidad,
      'orden': orden,
      'rfid': rfid,
      'status': status,
      'uom': uom,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
