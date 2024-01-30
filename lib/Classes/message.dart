class Message{
  final String userId;
  final String content;
  DateTime date;
  final String messageType;
  bool seen;
  bool liked;
  bool failed = false;
  bool pending = false;

  Message({required this.userId, required this.content, required this.seen, required this.date, required this.messageType, required this.liked});

  static Message fromJson(Map<dynamic, dynamic> messageMap) {
    final date = messageMap.keys.last;
    return Message(userId: messageMap[date]['user_id'], content: messageMap[date]['content'], seen: messageMap[date]['seen'],date:  DateTime.fromMicrosecondsSinceEpoch(int.parse(date)) , messageType: messageMap[date]['message_type'], liked: messageMap[date]['liked']);
  }

  Map<dynamic, dynamic> toJson() => {
    'user_id': userId,
    'content': content,
    'message_type': messageType,
    'seen': seen,
    'liked': liked
  };

  bool sent(String id) => userId == id;


}