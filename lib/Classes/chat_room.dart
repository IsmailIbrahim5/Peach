import '../Classes/message.dart';
import '../Classes/user_classes.dart';

class ChatRoom{
  final String id;
  final List<String> userIds;
  DateTime? lastMessageDate;
  User? secondUser;
  bool isTyping;
  List<Message> messages = [];

  ChatRoom(this.id, this.userIds, this.isTyping , {this.lastMessageDate});
}