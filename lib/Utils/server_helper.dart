import 'dart:convert';

import 'package:http/http.dart' as http;

import '../Classes/message_notification.dart';

class ServerHelper{

  static const _domain = 'peach-server.onrender.com';

  static const _sendNotificationEndPoint = 'sendNotification';

  static const _openChatEndPoint = 'openChat';

  static void sendNotification (MessageNotification notification) async{
    var url = Uri.https(_domain, _sendNotificationEndPoint ,  );

    var response = await http.post(url, body: json.encode(notification.toJson()) , headers: {
      'Content-type': 'application/json',
      'Accept': 'application/json',
    },);
  }

  static void openChat (OpenChatMessage message) async{
    var url = Uri.https(_domain, _openChatEndPoint ,);

    var response = await http.post(url, body: json.encode(message.toJson()) , headers: {
      'Content-type': 'application/json',
      'Accept': 'application/json',
    },);
  }
}