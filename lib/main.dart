import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:peach/Classes/main_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Classes/chat_room.dart';
import 'Classes/design_constants.dart';
import 'Classes/message_notification.dart';
import 'Other/firebase_options.dart';
import 'Classes/user_classes.dart';
import 'Screens/welcome.dart';
import 'Classes/message.dart' as peach;

void main() async {
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseDatabase.instance.setPersistenceEnabled(true);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);


  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(
        android: AndroidInitializationSettings('ic_message_notification')
    ),
    onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
  );

  runApp(const Main());
}


Function(ChatRoom chatRoom)? openChatAnimation;

class Main extends StatelessWidget {
  const Main({super.key});

  @override
  Widget build(BuildContext context) {
    return Provider(
      create: (context) => MainProvider(),
      builder: (context, child) {
        return MaterialApp(
          theme: ThemeData.light().copyWith(
            primaryColor: Design.mainColor,
            textSelectionTheme: TextSelectionThemeData(
              selectionHandleColor: Design.mainColor,
              cursorColor: Design.mainColor,
              selectionColor: Design.mainColor.withOpacity(.25),
            ),
          ),
          home: const Welcome(),
        );
      }
    );
  }
}


@pragma('vm:entry-point')
void notificationTapBackground (NotificationResponse response)async{
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  String userId = (await SharedPreferences.getInstance()).getString('user_id')!;
  final chatRoomId = response.payload;

  switch(response.actionId){
    case 'read':  FirebaseDatabase.instance.ref('messages/$chatRoomId').limitToLast(10).get().then((value){
      Map? messagesMap = value.value as Map;
      messagesMap.forEach((key, value) {
        if(!value['seen'] && value['user_id'] != userId){
          FirebaseDatabase.instance.ref('messages/$chatRoomId/$key').update(
              {'seen': true});
        }
      });
    }); break;
    case 'reply':

      final replyMessage = response.input;
      final lastMessage = (await FirebaseDatabase.instance.ref('messages/$chatRoomId').limitToLast(1).get()).value as Map?;
      final lastMessageDate = DateTime.fromMicrosecondsSinceEpoch(int.parse(lastMessage!.keys.first));
      final creationDate = DateTime.now();
      final secondUserId = ((await FirebaseDatabase.instance.ref('chat_rooms/$chatRoomId/user_ids').get()).value as Map?)!.values.firstWhere((element) => element != userId);
      final message = peach.Message(messageType: 'text' , content: replyMessage! , date: creationDate , liked: false, seen: false,userId: userId);
      FirebaseDatabase.instance.ref('messages/$chatRoomId').limitToLast(10).get().then((value){
        Map? messagesMap = value.value as Map;
        messagesMap.forEach((key, value) {
          if(!value['seen'] && value['user_id'] != userId){
            FirebaseDatabase.instance.ref('messages/$chatRoomId/$key').update(
                {'seen': true});
          }
        });
      });
      await FirebaseDatabase.instance
          .ref(
          'users/$userId/chat_rooms/${lastMessageDate.microsecondsSinceEpoch}')
          .remove();
      await FirebaseDatabase.instance
          .ref(
          'users/$userId/chat_rooms/${message.date.microsecondsSinceEpoch}')
          .set({'chat_room_id': chatRoomId});

      await FirebaseDatabase.instance
          .ref(
          'users/$secondUserId/chat_rooms/${lastMessageDate.microsecondsSinceEpoch}')
          .remove();
      await FirebaseDatabase.instance
          .ref(
          'users/$secondUserId/chat_rooms/${message.date
              .microsecondsSinceEpoch}')
          .set({'chat_room_id': chatRoomId});



      await FirebaseDatabase.instance
          .ref(
          'messages/$chatRoomId/${message.date
              .microsecondsSinceEpoch}')
          .set(message.toJson());
      break;
  }
}



const notificationChannelId = 'peach_channel_id';
const notificationChannelName = 'peach_channel';
const notificationChannelDescription = 'peach_channel_description';
const groupKey = 'com.glitch.peach.CHAT_MESSAGES';
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  String userId = (await SharedPreferences.getInstance()).getString('user_id')!;
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);


  if ((await FirebaseDatabase.instance
      .ref('users/$userId/settings/notifications_allowed')
      .get())
      .value ==
      false) return;

  if (message.data['type'] != 'sendNotification') return;

  MessageNotification messageNotification =
  MessageNotification.fromJson(message.data);

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  AndroidNotificationChannelGroup channelGroup = const AndroidNotificationChannelGroup( notificationChannelId,notificationChannelName , description: notificationChannelDescription);
  await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannelGroup(channelGroup);


  Map userMap = (await FirebaseDatabase.instance
      .ref('users/${messageNotification.user}')
      .get())
      .value as Map;

  User user = User.fromJson(userMap, messageNotification.user);

  File? pfpFile;
  ByteArrayAndroidIcon? pfp;
  if (user.pfpLink.isNotEmpty) {
    pfpFile = await DefaultCacheManager().getSingleFile(
        user.pfpLink, key: 'user_${user.id}_pfp');

    ui.PictureRecorder recorder = ui.PictureRecorder();
    ui.Image image = await decodeImageFromList(pfpFile.readAsBytesSync());

    Canvas canvas = Canvas(recorder,
        Rect.fromLTRB(0, 0, image.width.toDouble(), image.height.toDouble()));
    canvas.clipPath(Path()
      ..addOval(Rect.fromCircle(
          center: Offset(image.width / 2, image.height / 2),
          radius: image.width / 2)));

    canvas.drawImage(image, Offset.zero, Paint());

    final picture = recorder.endRecording();
    final img = await picture.toImage(image.width.toInt(), image.width.toInt());
    final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);
    final list = pngBytes?.buffer.asUint8List(
        pngBytes.offsetInBytes, pngBytes.lengthInBytes);

    pfp = ByteArrayAndroidIcon(list!);
  }else{
    ui.PictureRecorder recorder = ui.PictureRecorder();

    Canvas canvas = Canvas(recorder,
        const Rect.fromLTRB(0, 0, 100, 100));
    canvas.clipPath(Path()
      ..addOval(Rect.fromCircle(
          center: const Offset(50,  50),
          radius: 50)));

    var brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    bool isDarkMode = brightness == Brightness.dark;
    canvas.drawRect( const Rect.fromLTRB(0, 0, 100, 100) , Paint()..color= Design.peachColor);
    canvas.drawOval(  Rect.fromCircle(center: const Offset(50 , 50) , radius: 45) , Paint()..color= isDarkMode ? Colors.black87:Colors.white);

    TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: user.name[0].toUpperCase(),
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          color: Design.peachColor,
          fontFamily: 'Inter',
          fontSize: 60
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center
    );
    textPainter.layout(maxWidth: 100);
    final xCenter = (100 - textPainter.width) / 2;
    final yCenter = (100 - textPainter.height) / 2;
    final offset = Offset(xCenter, yCenter);
    textPainter.paint(canvas, offset);
    final picture = recorder.endRecording();
    final img = await picture.toImage(100, 100);
    final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);
    final list = pngBytes?.buffer.asUint8List(
        pngBytes.offsetInBytes, pngBytes.lengthInBytes);

    pfp = ByteArrayAndroidIcon(list!);
  }
  Person person = Person(
    name: user.name,
    key: user.id,
    icon: pfp,
  );

  List<Message> messages = [];

  Map? messagesMap = (await FirebaseDatabase.instance
      .ref('messages/${messageNotification.chatRoomId}')
      .limitToLast(10)
      .get())
      .value as Map?;

  messagesMap?.forEach((key, value) {
    if (!value['seen'] && value['user_id'] != userId) {
      if (value['message_type'] == 'text') {
        messages.add(Message(value['content'],
            DateTime.fromMicrosecondsSinceEpoch(int.parse(key)), person));
      } else {
        messages.add(Message('Sent an ${value['message_type']}',
            DateTime.fromMicrosecondsSinceEpoch(int.parse(key)), person));
      }
    }
  });

  messages.sort(
        (a, b) =>
    a.timestamp
        .difference(b.timestamp)
        .inMilliseconds,
  );

  MessagingStyleInformation inboxStyleInformation = MessagingStyleInformation(
    person,
    groupConversation: true,
    messages: messages,
  );

  AndroidNotificationDetails secondNotificationAndroidSpecifics =
  AndroidNotificationDetails(notificationChannelId, notificationChannelName,
      channelDescription: notificationChannelDescription,
      category: AndroidNotificationCategory.message,
      styleInformation: inboxStyleInformation,
      color: Design.peachColor,
      priority: Priority.max,
      colorized: true,
      actions: [
        const AndroidNotificationAction(
            'read', 'Mark as read', cancelNotification: true,
            titleColor: Design.peachColor),
        const AndroidNotificationAction(
            'reply', 'Reply', cancelNotification: true,
            titleColor: Design.peachColor,
            inputs: [
              AndroidNotificationActionInput(label: 'Send a reply',),
            ]),
      ],
      number: messages.length,
      enableLights: true,
      importance: Importance.max,
      sound: const RawResourceAndroidNotificationSound('notification_sound'),
      icon: 'ic_message_notification',
      groupKey: groupKey);

  NotificationDetails secondNotificationPlatformSpecifics = NotificationDetails(
    android: secondNotificationAndroidSpecifics,
  );

  flutterLocalNotificationsPlugin.show(
      messageNotification.id,
      user.name,
      messages.last.text,
      secondNotificationPlatformSpecifics,
      payload: messageNotification.chatRoomId);

}
