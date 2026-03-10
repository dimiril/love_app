import 'package:flutter/material.dart';
import '../models/private_message_model.dart';
import '../services/private_message_service.dart';

class PrivateMessageProvider with ChangeNotifier {
  final PrivateMessageService _service = PrivateMessageService();

  List<PrivateMessageModel> _messages = [];
  List<PrivateMessageModel> get messages => _messages;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  int _currentPage = 1;
  bool _hasMore = true;
  String _currentFolder = 'inbox'; // inbox or sent

  Future<void> loadMessages(int userId, {String folder = 'inbox', bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _messages = [];
      _hasMore = true;
      _currentFolder = folder;
    }

    if (!_hasMore || _isLoading) return;

    _isLoading = true;
    notifyListeners();

    final newMessages = await _service.fetchMessages(
      userId: userId,
      folder: _currentFolder,
      page: _currentPage,
    );

    if (newMessages.isEmpty) {
      _hasMore = false;
    } else {
      _messages.addAll(newMessages);
      _currentPage++;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> sendMessage({
    required int senderId,
    required int receiverId,
    String? subject,
    required String content,
  }) async {
    _isLoading = true;
    notifyListeners();

    final success = await _service.sendMessage(
      senderId: senderId,
      receiverId: receiverId,
      subject: subject,
      content: content,
    );

    _isLoading = false;
    notifyListeners();
    return success;
  }

  void clearMessages() {
    _messages = [];
    _currentPage = 1;
    _hasMore = true;
    notifyListeners();
  }
}
