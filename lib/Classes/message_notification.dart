class MessageNotification{

  final String user;
  final String chatRoomId;
  final int id;
  final String toToken;

  MessageNotification(this.id,this.user, this.chatRoomId, this.toToken);

  static MessageNotification fromJson(Map json) => MessageNotification(int.parse(json['id']) , json['user'], json['chatRoomId'] , json['toToken']);

  Map<String, String> toJson() => {
    'id' : '$id',
    'user': user,
    'chatRoomId': chatRoomId,
    'toToken': toToken,
    'type': 'sendNotification'
  };
}

class OpenChatMessage{

  final String chatRoomId;
  final int id;
  final String toToken;
  final int creationDate;

  OpenChatMessage(this.id, this.chatRoomId, this.toToken, this.creationDate);

  static OpenChatMessage fromJson(Map json) => OpenChatMessage(int.parse(json['id']) , json['chatRoomId'] , json['toToken'] ,int.parse( json['creationDate']));

  Map<String, String> toJson() => {
    'id' : '$id',
    'chatRoomId': chatRoomId,
    'toToken': toToken,
    'type': 'openChat',
    'creationDate': creationDate.toString()
  };
}