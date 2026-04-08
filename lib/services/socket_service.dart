import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../core/constants.dart';
import '../models/order.dart';

/// Socket.io service for real-time supplier order notifications.
/// Connects to the backend and listens for new orders and status updates.
class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  String? _supplierId;

  // Stream controllers for real-time events
  final _newOrderController = StreamController<Order>.broadcast();
  final _orderStatusController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Order> get onNewOrder => _newOrderController.stream;
  Stream<Map<String, dynamic>> get onOrderStatusUpdate => _orderStatusController.stream;

  bool get isConnected => _socket?.connected ?? false;

  /// Connect to backend socket and join supplier room
  void connect(String supplierId) {
    if (_socket != null && _supplierId == supplierId) return;
    _supplierId = supplierId;

    _socket = IO.io(
      ApiConstants.baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableReconnection()
          .build(),
    );

    _socket!.onConnect((_) {
      debugPrint('[SocketService] Connected to server');
      _socket!.emit('supplier_online', {'supplierId': supplierId});
    });

    _socket!.on('new_supplier_order', (data) {
      debugPrint('[SocketService] New order received!');
      try {
        final order = Order.fromJson(data);
        _newOrderController.add(order);
      } catch (e) {
        debugPrint('[SocketService] Error parsing new order: $e');
      }
    });

    _socket!.onDisconnect((_) {
      debugPrint('[SocketService] Disconnected');
    });

    _socket!.onReconnect((_) {
      debugPrint('[SocketService] Reconnected');
      if (_supplierId != null) {
        _socket!.emit('supplier_online', {'supplierId': _supplierId});
      }
    });

    _socket!.connect();
  }

  /// Disconnect and cleanup
  void disconnect() {
    if (_socket != null && _supplierId != null) {
      _socket!.emit('supplier_offline', {'supplierId': _supplierId});
    }
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _supplierId = null;
  }

  void dispose() {
    disconnect();
    _newOrderController.close();
    _orderStatusController.close();
  }
}
