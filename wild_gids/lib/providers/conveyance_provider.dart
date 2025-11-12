import 'package:flutter/material.dart';
import 'package:wildrapport/data_managers/conveyance_api.dart';

class ConveyanceProvider extends ChangeNotifier {
  final ConveyanceApi api;
  List<Map<String, dynamic>> _conveyances = [];
  bool _loading = false;
  String? _error;

  ConveyanceProvider(this.api);

  List<Map<String, dynamic>> get conveyances => _conveyances;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetchConveyances() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _conveyances = await api.getMyConveyances();
    } catch (e) {
      _error = e.toString();
      _conveyances = [];
    }
    _loading = false;
    notifyListeners();
  }
}
