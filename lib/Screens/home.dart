import 'dart:math';
import 'dart:ui';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:camera/camera.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:image_picker/image_picker.dart';
import 'package:peach/Classes/main_provider.dart';
import 'package:provider/provider.dart';
import '../Classes/design_constants.dart';
import '../Classes/message_notification.dart';
import '../Pages/contacts_page.dart';
import '../Pages/chat_rooms_page.dart';
import '../Pages/settings_page.dart';
import '../Screens/scan_qr_code.dart';
import '../Utils/server_helper.dart';
import '../Widgets/cross_fade_switcher.dart';
import '../Widgets/sequence_animation_builder.dart';
import '../Widgets/loading_widget.dart';

import '../Classes/chat_room.dart';
import '../Classes/user_classes.dart';
import '../main.dart';
import 'opened_chat_room.dart';
import 'dart:math' as math;

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  ValueNotifier<int> currentTab = ValueNotifier(0);

  PageController pageController = PageController();
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  List<Tab> tabs = [
    Tab('Messages', 'images/chat.png'),
    Tab('Contacts', 'images/user.png'),
    Tab('Settings', 'images/settings.png'),
  ];

  bool isMiniContactsOn = false;
  SequenceAnimationController builderController = SequenceAnimationController();

  late MainProvider provider;
  @override
  void initState() {
    super.initState();
    provider = Provider.of<MainProvider>(context, listen: false);
    if (provider.currentUser!.settings.activeStatus) {
      FirebaseDatabase.instance
          .ref('users/${provider.currentUser!.id}/active')
          .set(true);
    }

    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    WidgetsBinding.instance.addObserver(AppLifecycleListener(
      onPause: () {
        if (provider.currentUser!.settings.activeStatus) {
          FirebaseDatabase.instance
              .ref('users/${provider.currentUser!.id}/active')
              .set(false);
        }
      },
      onResume: () {
        if (provider.currentUser!.settings.activeStatus) {
          FirebaseDatabase.instance
              .ref('users/${provider.currentUser!.id}/active')
              .set(true);
        }
        check();
      },
      onDetach: () {
        if (provider.currentUser!.settings.activeStatus) {
          FirebaseDatabase.instance
              .ref('users/${provider.currentUser!.id}/active')
              .set(false);
        }
      },
    ));
    check();

    FirebaseMessaging.onMessage.listen((event) async {
      if (event.data['type'] == 'openChat') {
        OpenChatMessage message = OpenChatMessage.fromJson(event.data);

        ChatRoom? chatRoom = provider.currentUser!.chatRooms
            ?.where((element) => element.id == message.chatRoomId)
            .firstOrNull;
        if (chatRoom == null) {
          Map<Object?, Object?> chatRoomData = (await FirebaseDatabase.instance
                  .ref('chat_rooms/${message.chatRoomId}')
                  .get())
              .value as Map<Object?, Object?>;

          List<String> userIds = (chatRoomData['user_ids'] as Map?)
                  ?.keys
                  .cast<String>()
                  .toList() ??
              [];

          String secondUserId = userIds
              .firstWhere((element) => element != provider.currentUser!.id);

          Map<dynamic, dynamic>? typing = chatRoomData['typing'] as Map?;

          chatRoom = ChatRoom(
              message.chatRoomId, userIds, typing?[secondUserId] as bool,
              lastMessageDate:
                  DateTime.fromMicrosecondsSinceEpoch(message.creationDate));

          Map<dynamic, dynamic> userMap = (await FirebaseDatabase.instance
                  .ref()
                  .child('users/$secondUserId')
                  .get())
              .value as Map<dynamic, dynamic>;

          User secondUser = User.fromJson(userMap, secondUserId);

          chatRoom.secondUser = secondUser;
          setState(() {
            if (provider.currentUser!.chatRooms
                    ?.where((element) => chatRoom?.id == element.id)
                    .firstOrNull ==
                null) {
              provider.currentUser!.chatRooms?.add(chatRoom!);
            }
            if (provider.currentUser!.friends
                    ?.where((element) => secondUser.id == element.id)
                    .firstOrNull ==
                null) {
              provider.currentUser!.friends?.add(Friend(
                  secondUser.name,
                  secondUser.id,
                  secondUser.pfpLink,
                  secondUser.messagingToken,
                  secondUser.isActive,
                  secondUser.status,
                  secondUser.settings,
                  chatRoom!.id));
            }
          });
        }
        Navigator.of(context).push(
          PageRouteBuilder(
            transitionDuration: Duration.zero,
            pageBuilder: (context, animation, secondaryAnimation) =>
                OpenedChatRoom(
              chatRoom: chatRoom!,
                  key: const ValueKey('openedChatRoom'),
            ),
          ),
        );
      }
    });
    provider.currentUser?.chatRooms?.clear();
  }

  NotificationResponse? response;

  void check() async {
    final NotificationAppLaunchDetails? notificationAppLaunchDetails =
        await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();

    if (notificationAppLaunchDetails != null) {
      if (notificationAppLaunchDetails.didNotificationLaunchApp) {
        if (notificationAppLaunchDetails.notificationResponse?.id !=
            response?.id) {
          response = notificationAppLaunchDetails.notificationResponse;
          final chatRoomId = response?.payload;
          if (chatRoomId != null) {
            ChatRoom? chatRoom = provider.currentUser?.chatRooms
                ?.where((element) => element.id == chatRoomId)
                .firstOrNull;
            if (chatRoom == null) {
              Map<Object?, Object?> chatRoomData = (await FirebaseDatabase
                      .instance
                      .ref('chat_rooms/$chatRoomId')
                      .get())
                  .value as Map<Object?, Object?>;

              List<String> userIds = (chatRoomData['user_ids'] as Map?)
                      ?.keys
                      .cast<String>()
                      .toList() ??
                  [];

              String secondUserId = userIds
                  .firstWhere((element) => element != provider.currentUser!.id);

              Map<dynamic, dynamic>? typing = chatRoomData['typing'] as Map?;

              Map? lastMessage = (await FirebaseDatabase.instance
                      .ref('messages/$chatRoomId')
                      .limitToLast(1)
                      .get())
                  .value as Map?;
              chatRoom = ChatRoom(
                  chatRoomId, userIds, typing?[secondUserId] as bool,
                  lastMessageDate: DateTime.fromMicrosecondsSinceEpoch(
                      int.parse(lastMessage!.keys.first)));

              Map<dynamic, dynamic> userMap = (await FirebaseDatabase.instance
                      .ref()
                      .child('users/$secondUserId')
                      .get())
                  .value as Map<dynamic, dynamic>;

              User secondUser = User.fromJson(userMap, secondUserId);

              chatRoom.secondUser = secondUser;
              setState(() {
                if (provider.currentUser?.chatRooms
                        ?.where((element) => chatRoom?.id == element.id)
                        .firstOrNull ==
                    null) {
                  provider.currentUser?.chatRooms?.add(chatRoom!);
                }
                if (provider.currentUser?.friends
                        ?.where((element) => secondUser.id == element.id)
                        .firstOrNull ==
                    null) {
                  provider.currentUser!.friends?.add(Friend(
                      secondUser.name,
                      secondUser.id,
                      secondUser.pfpLink,
                      secondUser.messagingToken,
                      secondUser.isActive,
                      secondUser.status,
                      secondUser.settings,
                      chatRoom!.id));
                }
              });
            }
            if(Navigator.of(context).widget.key == const ValueKey('openedChatRoom')) {
              Navigator.of(context).pushReplacement(
                PageRouteBuilder(
                  transitionDuration: Duration.zero,
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      OpenedChatRoom(
                        chatRoom: chatRoom!,
                        key: const ValueKey('openedChatRoom'),
                      ),
                ),
              );
            }else{
              Navigator.of(context).push(
                PageRouteBuilder(
                  transitionDuration: Duration.zero,
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      OpenedChatRoom(
                        chatRoom: chatRoom!,
                        key: const ValueKey('openedChatRoom'),
                      ),
                ),
              );
            }
          }
        }
      }
    }
    flutterLocalNotificationsPlugin.cancelAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: SequenceAnimationBuilder(
        repeat: false,
        animations: 7,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutBack,
        controller: builderController,
        builder: (values, [child]) => Stack(
          children: [
            const BackgroundGradient(),
            child!,
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32.0),
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    ValueListenableBuilder(
                      valueListenable: currentTab,
                      builder: (context, value, child) => AnimatedPositioned(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutBack,
                        height: provider.screenSize.height * 0.085,
                        width: provider.screenSize.width * .45,
                        left: value == 1
                            ? provider.screenSize.width * 0.025
                            : provider.screenSize.width / 2 -
                                (provider.screenSize.width * 0.45 / 2),
                        child: UpwardCrossFade(
                          value: values[value == 0 ? 3 : 6],
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(35.0),
                              boxShadow: [Design.shadow1],
                            ),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                AnimatedOpacity(
                                    duration: const Duration(milliseconds: 250),
                                    opacity: value == 0 ? 1 : .5,
                                    child: IconButton(
                                      onPressed: () => pageController
                                          .animateToPage(0,
                                              duration: const Duration(
                                                  milliseconds: 400),
                                              curve: Curves.easeOut),
                                      icon: Image.asset(
                                        'images/chat.png',
                                        color: Design.mainColor,
                                        width: 28.0,
                                        height: 28.0,
                                      ),
                                    )),
                                Container(
                                  width: 2.0,
                                  height: 10.0,
                                  decoration: BoxDecoration(
                                      color: Design.mainColor.withOpacity(.25),
                                      borderRadius:
                                          BorderRadius.circular(12.0)),
                                ),
                                AnimatedOpacity(
                                    duration: const Duration(milliseconds: 250),
                                    opacity: value == 1 ? 1 : .5,
                                    child: IconButton(
                                      onPressed: () => pageController
                                          .animateToPage(1,
                                              duration: const Duration(
                                                  milliseconds: 400),
                                              curve: Curves.easeOut),
                                      icon: Image.asset(
                                        'images/person_outlined.png',
                                        color: Design.mainColor,
                                        width: 28.0,
                                        height: 28.0,
                                      ),
                                    )),
                                Container(
                                  width: 2.0,
                                  height: 10.0,
                                  decoration: BoxDecoration(
                                      color: Design.mainColor.withOpacity(.25),
                                      borderRadius:
                                          BorderRadius.circular(12.0)),
                                ),
                                AnimatedOpacity(
                                    duration: const Duration(milliseconds: 250),
                                    opacity: value == 2 ? 1 : .50,
                                    child: IconButton(
                                      onPressed: () => pageController
                                          .animateToPage(2,
                                              duration: const Duration(
                                                  milliseconds: 400),
                                              curve: Curves.easeOut),
                                      icon: Image.asset(
                                        'images/settings.png',
                                        color: Design.mainColor,
                                        width: 28.0,
                                        height: 28.0,
                                      ),
                                    )),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: provider.screenSize.width * 0.025,
                      child: UpwardCrossFade(
                        value: values[4],
                        child: ValueListenableBuilder(
                          valueListenable: currentTab,
                          builder: (context, value, child) => AnimatedScale(
                            scale: value == 2 ? 0.0 : 1.0,
                            duration: const Duration(milliseconds: 400),
                            curve: value == 2
                                ? Curves.easeOut
                                : Curves.easeOutBack,
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () {
                                if (value == 1) {
                                  Navigator.of(context).push(PageRouteBuilder(
                                      pageBuilder: (context, animation,
                                              secondaryAnimation) =>
                                          PickSource(
                                            callback: (choice) async {
                                              if (choice == 1) {
                                                Navigator.of(context)
                                                    .push(PageRouteBuilder(
                                                  pageBuilder: (context,
                                                          animation,
                                                          secondaryAnimation) =>
                                                      ScanQRCode(
                                                    callback: qrCallback,
                                                  ),
                                                  transitionsBuilder: (context,
                                                          animation,
                                                          secondaryAnimation,
                                                          child) =>
                                                      ClipPath(
                                                    clipper: CircleClipper(
                                                        animation,
                                                        provider.screenSize),
                                                    child: child,
                                                  ),
                                                ));
                                              } else if (choice == 0) {
                                                XFile? image =
                                                    await ImagePicker()
                                                        .pickImage(
                                                            source: ImageSource
                                                                .gallery);
                                                if (image != null) {
                                                  final barcodes =
                                                      await BarcodeScanner()
                                                          .processImage(InputImage
                                                              .fromFilePath(
                                                                  image.path));
                                                  if (barcodes.isNotEmpty) {
                                                    qrCallback(barcodes
                                                        .first.rawValue!);
                                                  } else {
                                                    showMessage(
                                                        'Couldn\'t detect QR Code in this image, please pick another image');
                                                  }
                                                }
                                              }
                                            },
                                          ),
                                      transitionDuration: Duration.zero,
                                      barrierColor: Colors.transparent,
                                      opaque: false));
                                }
                                if (value == 0) {
                                  setState(() {
                                    isMiniContactsOn = !isMiniContactsOn;
                                  });
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeOutBack,
                                clipBehavior: Clip.antiAlias,
                                height: provider.screenSize.height * 0.085,
                                width: value == 1
                                    ? provider.screenSize.width * .45
                                    : provider.screenSize.height * 0.085,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                        provider.screenSize.height *
                                            0.085 *
                                            .5),
                                    boxShadow: [Design.shadow1],
                                    color: Colors.white),
                                child: CrossFadeSwitcher(
                                  next: value == 1,
                                  child: value == 1
                                      ? Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8.0),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Expanded(
                                                flex: 3,
                                                child: Transform.scale(
                                                  scale: .8,
                                                  child: Image.asset(
                                                    'images/add_person.png',
                                                    color: Design.mainColor,
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                flex: 7,
                                                child: FittedBox(
                                                  fit: BoxFit.contain,
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            right: 6.0),
                                                    child: Text(
                                                      'Add A Friend'
                                                          .toUpperCase(),
                                                      style: const TextStyle(
                                                          color:
                                                              Design.mainColor,
                                                          fontFamily: 'Inter',
                                                          fontWeight:
                                                              FontWeight.w900),
                                                    ),
                                                  ),
                                                ),
                                              )
                                            ],
                                          ),
                                        )
                                      : value == 0
                                          ? AnimatedRotation(
                                              turns: isMiniContactsOn
                                                  ? math.pi / 5
                                                  : 0,
                                              duration: const Duration(
                                                  milliseconds: 400),
                                              curve: Curves.easeOutBack,
                                              child: Image.asset(
                                                'images/add.png',
                                                width: 36,
                                                height: 36,
                                                color: Design.mainColor,
                                              ),
                                            )
                                          : const SizedBox(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                        right: provider.screenSize.width * 0.025,
                        bottom: provider.screenSize.height * 0.085 + 24.0,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOut,
                          opacity: isMiniContactsOn ? 1.0 : 0.0,
                          child: AnimatedContainer(
                            height: isMiniContactsOn
                                ? provider.screenSize.height * 0.25
                                : 0,
                            width: isMiniContactsOn
                                ? provider.screenSize.width * .6
                                : 0,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                  provider.screenSize.width * .25 * .25),
                              color: Colors.white,
                              boxShadow: [Design.shadow1],
                            ),
                            duration: const Duration(milliseconds: 400),
                            alignment: Alignment.topCenter,
                            curve: isMiniContactsOn
                                ? Curves.easeOutBack
                                : Curves.easeOut,
                            child: isMiniContactsOn
                                ? MiniContactsWidget(onClick: () {
                                    setState(() {
                                      isMiniContactsOn = false;
                                    });
                                  })
                                : const SizedBox(),
                          ),
                        ))
                  ],
                ),
              ),
            ),
          ],
        ),
        child: PageView(
          controller: pageController,
          onPageChanged: (value) {
            currentTab.value = value;
          },
          children: [
            MessagesPage(
              controller: builderController,
            ),
            ContactsPage(
              controller: builderController,
            ),
            SettingsPage(
              controller: builderController,
            ),
          ],
        ),
      ),
    );
  }

  void openChat(ChatRoom chatRoom) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: Duration.zero,
        pageBuilder: (context, animation, secondaryAnimation) => OpenedChatRoom(
          chatRoom: chatRoom,
          key: const ValueKey('openedChatRoom'),
        ),
      ),
    );
  }

  void qrCallback(String id) async {
    if (id == provider.currentUser!.id) {
      showMessage(
          'Bruh. I understand how lonely you are, but you can\'t add yourself I\'m sorry');
      return;
    }
    try {
      Map? userMap = (await FirebaseDatabase.instance.ref('users/$id').get())
          .value as Map?;
      if (userMap != null) {
        if (provider.currentUser?.friends
                ?.where((element) => element.id == id)
                .firstOrNull ==
            null) {
          DateTime creationDate = DateTime.now();
          DatabaseReference chatRoomRef =
              FirebaseDatabase.instance.ref('chat_rooms/').push();
          await FirebaseDatabase.instance
              .ref('users/${provider.currentUser!.id}/friends/$id')
              .set({'friend_id': id, 'friend_chat_room_id': chatRoomRef.key});
          await FirebaseDatabase.instance
              .ref('users/$id/friends/${provider.currentUser!.id}')
              .set({
            'friend_id': provider.currentUser!.id,
            'friend_chat_room_id': chatRoomRef.key
          });
          await chatRoomRef.set({
            'typing': {provider.currentUser!.id: false, id: false},
            'user_ids': {
              provider.currentUser!.id: provider.currentUser!.id,
              id: id
            }
          });

          await FirebaseDatabase.instance
              .ref(
                  'users/${provider.currentUser!.id}/chat_rooms/${creationDate.microsecondsSinceEpoch}')
              .set({
            'chat_room_id': chatRoomRef.key,
          });

          await FirebaseDatabase.instance
              .ref(
                  'users/$id/chat_rooms/${creationDate.microsecondsSinceEpoch}')
              .set({
            'chat_room_id': chatRoomRef.key,
          });

          ChatRoom chatRoom = ChatRoom(
              chatRoomRef.key!, [provider.currentUser!.id, id], false,
              lastMessageDate: creationDate);

          chatRoom.secondUser = User.fromJson(userMap, id);

          if (provider.currentUser?.chatRooms
                  ?.where((element) => element.id == chatRoom.id)
                  .firstOrNull ==
              null) {
            provider.currentUser?.chatRooms?.add(chatRoom);
          }

          if (provider.currentUser?.friends
                  ?.where((element) => element.id == chatRoom.secondUser?.id)
                  .firstOrNull ==
              null) {
            provider.currentUser?.friends?.add(Friend(
                chatRoom.secondUser!.name,
                chatRoom.secondUser!.id,
                chatRoom.secondUser!.pfpLink,
                chatRoom.secondUser!.messagingToken,
                chatRoom.secondUser!.isActive,
                chatRoom.secondUser!.status,
                chatRoom.secondUser!.settings,
                chatRoom.id));
          }
          setState(() {});
          ServerHelper.openChat(OpenChatMessage(
              Random().nextInt(1000),
              chatRoom.id,
              chatRoom.secondUser!.messagingToken,
              creationDate.microsecondsSinceEpoch));

          openChat(chatRoom);
        } else {
          showMessage(
              'You already have this person as your friend, you dumbie dumb');
        }
      } else {
        showMessage(
            'Couldn\'t find this user, please make sure you are scanning the right QR code');
      }
    } catch (e) {
      showMessage(
          'An error occurred, please make sure you are scanning the right QR code');
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        message,
        style: const TextStyle(
          color: Color(0xFFEF9899),
          fontWeight: FontWeight.w900,
          fontFamily: 'Inter',
        ),
      ),
      backgroundColor: Colors.white,
    ));
  }
}

class MiniContactsWidget extends StatefulWidget {
  final Function onClick;
  const MiniContactsWidget({super.key, required this.onClick});

  @override
  State<MiniContactsWidget> createState() => _MiniContactsWidgetState();
}

class _MiniContactsWidgetState extends State<MiniContactsWidget> {
  late MainProvider provider;

  @override
  void initState() {
    super.initState();
    provider = Provider.of<MainProvider>(context, listen: false);
    if (provider.currentUser?.friends == null) {
      FirebaseDatabase.instance
          .ref('users/${provider.currentUser!.id}/friends')
          .get()
          .then((event) async {
        setState(() {
          if (provider.currentUser!.friends == null)
            provider.currentUser!.friends = [];
        });
        Map? friendsInfoData = event.value as Map?;
        for (Map? friendInfo in friendsInfoData?.values ?? []) {
          if (provider.currentUser?.friends
                  ?.where((element) => element.id == friendInfo!['friend_id'])
                  .firstOrNull ==
              null) {
            Map? friendData = (await FirebaseDatabase.instance
                    .ref('users/${friendInfo!['friend_id']}')
                    .get())
                .value as Map?;
            if (friendData != null) {
              Friend friend = Friend.fromJson(friendData,
                  friendInfo['friend_id'], friendInfo['friend_chat_room_id']);
              provider.currentUser?.friends?.add(friend);
            }
          }
        }

        setState(() {
          provider.currentUser?.friends
              ?.sort((a, b) => a.name[0].compareTo(b.name[0]));
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CrossFadeSwitcher(
      next: true,
      child: provider.currentUser!.friends == null
          ? const Center(
              child: LoadingWidget(
                size: 16.0,
                color: Design.mainColor,
              ),
            )
          : provider.currentUser!.friends!.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: FittedBox(
                      child: Text(
                        'You don\'t currently have any friends (just like me then huh)\n Go to contacts tab to add friends',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Inter',
                            color: Design.mainColor),
                      ),
                    ),
                  ),
                )
              : RawScrollbar(
                  radius: const Radius.circular(2.0),
                  thickness: 4.0,
                  thumbColor: Design.mainColor.withOpacity(.5),
                  crossAxisMargin: 8.0,
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: List.generate(
                        provider.currentUser!.friends!.length,
                        (index) => Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 12.0),
                              child: GestureDetector(
                                onTap: () async {
                                  ChatRoom? chatRoom = provider
                                      .currentUser!.chatRooms
                                      ?.where((element) =>
                                          element.id ==
                                          provider.currentUser!.friends![index]
                                              .chatRoomId)
                                      .firstOrNull;
                                  if (chatRoom == null) {
                                    Map<Object?, Object?> chatRoomData =
                                        (await FirebaseDatabase.instance
                                                .ref('chat_rooms')
                                                .orderByChild('chat_room_id')
                                                .equalTo(provider.currentUser!
                                                    .friends![index].chatRoomId)
                                                .get())
                                            .value as Map<Object?, Object?>;

                                    List<String> userIds =
                                        (chatRoomData['user_ids'] as Map?)
                                                ?.keys
                                                .cast<String>()
                                                .toList() ??
                                            [];

                                    String secondUserId = userIds.firstWhere(
                                        (element) =>
                                            element !=
                                            provider.currentUser!.id);

                                    Map<dynamic, dynamic>? typing =
                                        chatRoomData['typing'] as Map?;

                                    chatRoom = ChatRoom(
                                        provider.currentUser!.friends![index]
                                            .chatRoomId,
                                        userIds,
                                        typing?[secondUserId] as bool);

                                    Map<dynamic, dynamic> userMap =
                                        (await FirebaseDatabase.instance
                                                .ref()
                                                .child('users/$secondUserId')
                                                .get())
                                            .value as Map<dynamic, dynamic>;

                                    User secondUser =
                                        User.fromJson(userMap, secondUserId);

                                    chatRoom.secondUser = secondUser;

                                    if (provider.currentUser!.chatRooms
                                            ?.where((element) =>
                                                chatRoom?.id == element.id)
                                            .firstOrNull ==
                                        null) {
                                      provider.currentUser!.chatRooms
                                          ?.add(chatRoom);
                                    }
                                  }
                                  widget.onClick();
                                  openChatAnimation!(chatRoom);
                                },
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 1,
                                      child: CachedNetworkImage(
                                        imageUrl: provider.currentUser!
                                            .friends![index].pfpLink,
                                        imageBuilder:
                                            (context, imageProvider) =>
                                                Container(
                                          decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Design.mainColor),
                                          padding: const EdgeInsets.all(1.0),
                                          child: Container(
                                            decoration: const BoxDecoration(
                                                shape: BoxShape.circle),
                                            clipBehavior: Clip.antiAlias,
                                            child: Image(
                                              image: imageProvider,
                                            ),
                                          ),
                                        ),
                                        placeholder: (context, url) =>
                                            LayoutBuilder(
                                          builder: (context, constraints) =>
                                              Container(
                                            decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                    color: Design.mainColor,
                                                    width: 1.0)),
                                            height: constraints.maxWidth,
                                            width: constraints.maxWidth,
                                            child: FittedBox(
                                              child: Text(
                                                provider.currentUser!
                                                    .friends![index].name[0]
                                                    .toUpperCase(),
                                                style: const TextStyle(
                                                    color: Design.mainColor,
                                                    fontWeight: FontWeight.w900,
                                                    fontFamily: 'Inter'),
                                              ),
                                            ),
                                          ),
                                        ),
                                        errorWidget: (context, url, error) =>
                                            LayoutBuilder(
                                          builder: (context, constraints) =>
                                              Container(
                                            decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                    color: Design.mainColor,
                                                    width: 1.0)),
                                            height: constraints.maxWidth,
                                            width: constraints.maxWidth,
                                            child: FittedBox(
                                              child: Text(
                                                provider.currentUser!
                                                    .friends![index].name[0]
                                                    .toUpperCase(),
                                                style: const TextStyle(
                                                    color: Design.mainColor,
                                                    fontWeight: FontWeight.w900,
                                                    fontFamily: 'Inter'),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Align(
                                        alignment: Alignment.center,
                                        child: Text(
                                          provider.currentUser!.friends![index]
                                              .name,
                                          style: const TextStyle(
                                            color: Design.mainColor,
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            )),
                  ),
                ),
    );
  }
}

class PickSource extends StatefulWidget {
  final Function(int choice) callback;
  const PickSource({super.key, required this.callback});

  @override
  State<PickSource> createState() => _PickSourceState();
}

class _PickSourceState extends State<PickSource> {
  final controller = SequenceAnimationController();
  int choice = -1;

  late MainProvider provider;

  @override
  void initState() {
    super.initState();
    provider = Provider.of<MainProvider>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: PopScope(
        canPop: false,
        onPopInvoked: (didPop) => controller.reverse!(),
        child: SequenceAnimationBuilder(
          animations: 3,
          repeat: false,
          controller: controller,
          curve: Curves.easeOutBack,
          endCallback: () {
            Navigator.of(context).pop();
            widget.callback(choice);
          },
          duration: const Duration(milliseconds: 600),
          builder: (values, [child]) => Stack(
            children: [
              GestureDetector(
                onTap: () => controller.reverse!(),
                child: Container(
                  color: Colors.white.withOpacity(values[0] * .25),
                ),
              ),
              BackdropFilter(
                filter: ImageFilter.blur(
                    sigmaX: (values[0] * 2.0).clamp(0.0001, 2.0),
                    sigmaY: (values[0] * 2.0).clamp(0.0001, 2.0)),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    margin:
                        EdgeInsets.only(bottom: provider.screenSize.width * .1),
                    height: provider.screenSize.height * .2 * values[0],
                    width: provider.screenSize.width * .8 * values[0],
                    decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [Design.shadow1],
                        borderRadius: BorderRadius.circular(
                            provider.screenSize.width * .1)),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: provider.screenSize.width * .05),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  choice = 0;
                                });
                                controller.reverse!();
                              },
                              child: Transform.scale(
                                scale: values[1],
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal:
                                              provider.screenSize.width * .075),
                                      child: Container(
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(24.0),
                                            color: Colors.white,
                                            boxShadow: [Design.shadow3]),
                                        child: Transform.scale(
                                          scale: .75,
                                          child: Image.asset(
                                            'images/image.png',
                                            color: Design.mainColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      height: provider.screenSize.height * .015,
                                    ),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal:
                                              provider.screenSize.width * .025),
                                      child: const FittedBox(
                                        child: Text(
                                          'Pick From Gallery',
                                          style: TextStyle(
                                              color: Design.mainColor,
                                              fontFamily: 'Inter',
                                              fontWeight: FontWeight.w900,
                                              fontSize: 20.0),
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  choice = 1;
                                });
                                controller.reverse!();
                              },
                              child: Transform.scale(
                                scale: values[2],
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal:
                                              provider.screenSize.width * .075),
                                      child: Container(
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(24.0),
                                            color: Colors.white,
                                            boxShadow: [Design.shadow3]),
                                        child: Transform.scale(
                                          scale: .75,
                                          child: Image.asset(
                                            'images/camera.png',
                                            color: Design.mainColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      height: provider.screenSize.height * .015,
                                    ),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal:
                                              provider.screenSize.width * .025),
                                      child: const FittedBox(
                                        child: Text(
                                          'Scan With Camera',
                                          style: TextStyle(
                                              color: Design.mainColor,
                                              fontFamily: 'Inter',
                                              fontWeight: FontWeight.w900,
                                              fontSize: 20.0),
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class Tab {
  final String title;
  final String imagePath;

  Tab(this.title, this.imagePath);
}

class CircleClipper extends CustomClipper<Path> {
  final Animation<double> animation;
  final Size screenSize;

  CircleClipper(this.animation, this.screenSize) : super(reclip: animation);

  @override
  bool shouldReclip(covariant CustomClipper<dynamic> oldClipper) => true;

  @override
  Path getClip(Size size) {
    return Path()
      ..addOval(Rect.fromCircle(
          center: Offset(
              size.width / 2,
              size.height *
                  (1 - Curves.easeOut.transform(animation.value) * .7)),
          radius: math.sqrt(screenSize.width * screenSize.width +
                  screenSize.height * screenSize.height) *
              Curves.easeIn.transform(animation.value)));
  }
}
