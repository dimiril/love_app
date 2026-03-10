import 'package:flutter/material.dart';
import '../models/conversation_model.dart';
import '../models/private_message_model.dart';
import '../services/chat_service.dart';

class ChatProvider with ChangeNotifier {
  final ChatService _service = ChatService();

  List<ConversationModel> _conversations = [];
  List<ConversationModel> get conversations => _conversations;

  List<PrivateMessageModel> _messages = [];
  List<PrivateMessageModel> get messages => _messages;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  int? _activeConversationId;
  // ✅ إضافة getter للمعلق النشط
  int? get activeConversationId => _activeConversationId;
  
  int _currentMsgPage = 1;
  bool _hasMoreMsgs = true;
  bool get hasMoreMsgs => _hasMoreMsgs;

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  void addMessageLocally(PrivateMessageModel msg) {
    if (_activeConversationId != null && msg.conversationId == _activeConversationId) {
      if (!_messages.any((m) => m.id == msg.id)) {
        _messages.insert(0, msg);
        notifyListeners();
      }
    }
  }

  Future<int?> loadMessages(int? conversationId, {int? userId, int? otherId, bool refresh = false}) async {
    if (refresh) {
      _messages = [];
      _currentMsgPage = 1;
      _hasMoreMsgs = true;
    }

    if (!_hasMoreMsgs || _isLoading) return conversationId;

    _setLoading(true);

    int? id = conversationId;
    if (id == null && userId != null && otherId != null) {
      id = await _service.getConversationId(userId, otherId);
    }

    if (id != null) {
      _activeConversationId = id;
      final results = await _service.fetchMessages(id, page: _currentMsgPage);
      
      if (results.isEmpty) {
        _hasMoreMsgs = false;
      } else {
        _messages.addAll(results);
        _currentMsgPage++;
        if (results.length < 20) _hasMoreMsgs = false;
      }

      if (userId != null && refresh) markAsRead(id, userId, shouldNotify: false);
    }
    
    _setLoading(false);
    return id;
  }

  Future<void> loadConversations(int userId, {bool refresh = false}) async {
    if (refresh) {
      _conversations = [];
      notifyListeners();
    }
    final results = await _service.fetchConversations(userId);
    _conversations = results;
    notifyListeners();
  }

  Future<void> markAsRead(int conversationId, int userId, {bool shouldNotify = true}) async {
    await _service.markAsRead(conversationId, userId);
    final index = _conversations.indexWhere((c) => c.id == conversationId);
    if (index != -1) {
      if (_conversations[index].unreadCount == 0) return;
      _conversations[index] = ConversationModel(
        id: _conversations[index].id,
        otherUserId: _conversations[index].otherUserId,
        otherUserName: _conversations[index].otherUserName,
        otherUserAvatar: _conversations[index].otherUserAvatar,
        lastMessage: _conversations[index].lastMessage,
        lastMessageTime: _conversations[index].lastMessageTime,
        unreadCount: 0,
        isOnline: _conversations[index].isOnline,
      );
      if (shouldNotify) notifyListeners();
    }
  }

  Future<bool> deleteConversation(int conversationId, int userId) async {
    final success = await _service.deleteConversation(conversationId, userId);
    if (success) {
      _conversations.removeWhere((c) => c.id == conversationId);
      notifyListeners();
    }
    return success;
  }

  Future<bool> sendMessage({required int senderId, required int receiverId, required String message, int? conversationId}) async {
    final tempMsg = PrivateMessageModel(
      id: DateTime.now().millisecondsSinceEpoch,
      conversationId: conversationId ?? 0,
      senderId: senderId,
      message: message,
      isSeen: false,
      createdAt: DateTime.now(),
    );
    _messages.insert(0, tempMsg);
    notifyListeners();
    final success = await _service.sendMessage(senderId: senderId, receiverId: receiverId, message: message);
    if (!success) {
      _messages.remove(tempMsg);
      notifyListeners();
    }
    return success;
  }

  void clear() {
    _conversations = [];
    _messages = [];
    _activeConversationId = null;
    _currentMsgPage = 1;
    _hasMoreMsgs = true;
    notifyListeners();
  }
}
