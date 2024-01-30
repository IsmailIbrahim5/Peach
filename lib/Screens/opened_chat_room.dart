import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:audio_waveforms/audio_waveforms.dart' as waveform;
import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart' as intl;
import 'package:peach/Widgets/animated_value.dart';
import 'package:provider/provider.dart';
import '../Classes/chat_room.dart';
import '../Classes/main_provider.dart';
import '../Classes/message.dart';
import '../Classes/message_notification.dart';
import '../Pages/chat_rooms_page.dart';
import '../Utils/chat_room_cache_manager.dart';
import '../main.dart';
import '../Utils/server_helper.dart';
import '../Widgets/sequence_animation_builder.dart';
import '../Widgets/icon_switcher.dart';
import '../Widgets/loading_widget.dart';
import '../Widgets/typing_widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../Classes/design_constants.dart';
import 'dart:math' as math;
import 'package:path/path.dart' as path;

AudioPlayer? runningAudioPlayer;

class Media {
  String type;
  File file;

  Media(this.type, this.file);
}

int getId(String name) {
  int id = 0;
  for (int c in name.codeUnits) {
    id += c;
  }
  return id;
}

class OpenedChatRoom extends StatefulWidget {
  final ChatRoom chatRoom;
  const OpenedChatRoom({super.key, required this.chatRoom});

  @override
  State<OpenedChatRoom> createState() => _OpenedChatRoomState();
}

class _OpenedChatRoomState extends State<OpenedChatRoom>
    with SingleTickerProviderStateMixin {
  bool enabled = false;
  ScrollController chatListController = ScrollController();
  late ChatRoom chatRoom;

  late DatabaseReference chatRoomRef;
  List<Message> messages = [];
  late DatabaseReference typingStat;

  late StreamSubscription<DatabaseEvent> chatListener;
  late StreamSubscription<DatabaseEvent> removeListener;
  late StreamSubscription<DatabaseEvent> modifyListener;
  late StreamSubscription<DatabaseEvent> activeListener;
  late StreamSubscription<DatabaseEvent> typingListener;

  late AnimationController controller;
  late Animation<double> fadeAnimation;
  late Animation<double> fadeAnimation2;
  late Animation<Offset> slideAnimation;
  late Animation<double> scaleAnimation;
  late Animation<Color?> colorAnimation1;
  late Animation<Color?> colorAnimation2;

  Offset? popUpLocation;
  bool isRecording = false;

  ValueNotifier<bool> scrolledUp = ValueNotifier(false);

  late MainProvider provider;

  void loadMoreMessages() {
    loadMoreNotifier.value = true;
    FirebaseDatabase.instance
        .ref('messages/${widget.chatRoom.id}')
        .endBefore(messages.isEmpty ? '' : messages.first.date.toString())
        .limitToLast(10 + messages.length)
        .get()
        .then((event) async {
      Map? lastTenMessage = event.value as Map?;
      List<Message> lastTenMessages = [];
      lastTenMessage?.forEach((key, value) {
        Message m = Message.fromJson({key: value});
        if (messages
                .where((element) =>
                    element.date == m.date && element.content == m.content)
                .firstOrNull ==
            null) {
          lastTenMessages.add(m);
        }
      });
      lastTenMessages.sort(
        (a, b) => b.date.difference(a.date).inMilliseconds,
      );
      for (int i = 0; i < lastTenMessages.length; i++) {
        messages.insert(0, lastTenMessages[i]);
      }
      if (mounted) {
        setState(() {});
      }
      loadMoreNotifier.value = false;
    });
  }

  @override
  void initState() {
    super.initState();

    provider = Provider.of<MainProvider>(context, listen: false);
    controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    fadeAnimation = Tween(begin: 1.0, end: 0.25)
        .animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));
    fadeAnimation2 = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));
    slideAnimation = Tween<Offset>(
            begin: Offset.zero,
            end: Offset(0, provider.screenSize.height * 0.55))
        .animate(
            CurvedAnimation(parent: controller, curve: Curves.easeOutBack));
    scaleAnimation = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOutBack));
    colorAnimation1 = ColorTween(begin: Colors.white, end: Design.mainColor)
        .animate(CurvedAnimation(parent: controller, curve: Curves.ease));
    colorAnimation2 = ColorTween(begin: Design.mainColor, end: Colors.white)
        .animate(CurvedAnimation(parent: controller, curve: Curves.ease));

    chatRoom = widget.chatRoom;
    messages = chatRoom.messages;

    activeListener = FirebaseDatabase.instance
        .ref()
        .child('users/${chatRoom.secondUser?.id}/active')
        .onValue
        .listen((event) {
      setState(() {});
    });

    if (provider.currentUser!.settings.readRecipients) {
      FirebaseDatabase.instance
          .ref('messages/${widget.chatRoom.id}')
          .ref
          .limitToLast(10)
          .get()
          .then((event) {
        final map = event.value as Map?;
        if (map != null) {
          for (int i = 0; i < map.values.length; i++) {
            if (map.values.elementAt(i)['user_id'] !=
                    provider.currentUser!.id &&
                !map.values.elementAt(i)['seen']) {
              FirebaseDatabase.instance
                  .ref(
                      'messages/${widget.chatRoom.id}/${map.keys.elementAt(i)}')
                  .update({'seen': true});
            }
          }
        }
      });
    }

    typingStat = FirebaseDatabase.instance.ref(
        'chat_rooms/${widget.chatRoom.id}/typing/${provider.currentUser!.id}');
    typingListener = FirebaseDatabase.instance
        .ref(
            'chat_rooms/${widget.chatRoom.id}/typing/${chatRoom.secondUser?.id}')
        .onValue
        .listen((event) {
      chatRoom.isTyping = event.snapshot.value as bool;
      if (chatRoom.isTyping) {
        addTyping();
      } else {
        removeTyping();
      }
    });

    chatRoomRef =
        FirebaseDatabase.instance.ref('messages/${widget.chatRoom.id}');
    chatListener = chatRoomRef.limitToLast(1).onValue.listen((event) async {
      Map? lastMessageMap = event.snapshot.value as Map?;

      if (lastMessageMap != null) {
        Message m = Message.fromJson(
            {lastMessageMap.keys.first: lastMessageMap.values.first});
        setState(() {
          if (!m.sent(provider.currentUser!.id) &&
              !m.seen &&
              provider.currentUser!.settings.readRecipients) {
            chatRoomRef
                .child('${lastMessageMap.keys.first}')
                .update({'seen': true});
          }
          if (m.seen != messages.lastOrNull?.seen) {
            messages.lastOrNull?.seen = m.seen;
          }

          if (widget.chatRoom.messages
                  .where((element) => element.date == m.date)
                  .firstOrNull ==
              null) {
            widget.chatRoom.messages.add(m);
          }
          if (widget.chatRoom.lastMessageDate != m.date) {
            widget.chatRoom.lastMessageDate = m.date;
          }
        });
      }
    });
    modifyListener = chatRoomRef.onChildChanged.listen((event) {
      Message m = Message.fromJson({event.snapshot.key: event.snapshot.value});
      setState(() {
        messages[widget.chatRoom.messages
            .indexWhere((element) => element.date == m.date)] = m;
      });
    });

    removeListener = chatRoomRef.onChildRemoved.listen((event) {
      Message m = Message.fromJson({event.snapshot.key: event.snapshot.value});

      setState(() {
        widget.chatRoom.messages
            .removeWhere((element) => element.date == m.date);
      });
    });

    chatListController.addListener(() {
      if (chatListController.position.pixels >=
          chatListController.position.maxScrollExtent - 20) {
        loadMoreMessages();
      }
      scrolledUp.value = chatListController.position.pixels >= 100;
    });

    if (messages.isEmpty) {
      loadMoreMessages();
    }

    WidgetsBinding.instance.addObserver(AppLifecycleListener(
      onPause: () {
        if (provider.currentUser!.settings.activeStatus) {
          FirebaseDatabase.instance
              .ref('users/${provider.currentUser!.id}/active')
              .set(false);
          chatListener.pause();
        }
      },
      onResume: () {
        if (provider.currentUser!.settings.activeStatus) {
          FirebaseDatabase.instance
              .ref('users/${provider.currentUser!.id}/active')
              .set(true);
          chatListener.resume();
        }
      },
    ));

    currentDateNotifier = ValueNotifier(DateTime.now());
  }

  Future<void> addMessage(Message message, context, {Media? media}) async {
    if (messages.lastOrNull != null &&
        messages.last.content.isEmpty &&
        messages.last.userId == chatRoom.secondUser?.id) {
      messages.insert(messages.length - 1, message);
    } else {
      messages.add(message);
    }
    message.pending = true;

    if (media != null) {
      await ChatRoomCacheManager(widget.chatRoom.id).putFile(
          path.basename(message.content), media.file.readAsBytesSync(),
          key: path.basenameWithoutExtension(message.content),
          fileExtension: path.extension(message.content).substring(1));
    }

    setState(() {});

    try {
      if (media != null) {
        final ref = FirebaseStorage.instance
            .ref('chatroom_${widget.chatRoom.id}/${message.content}');

        await ref.putFile(
            media.file,
            SettableMetadata(
                contentType:
                    '${media.type}/${path.extension(media.file.path).substring(1)}'));
      }
      DateTime lastMessageDate = DateTime.fromMicrosecondsSinceEpoch(int.parse(
          ((await FirebaseDatabase.instance
                      .ref('messages/${chatRoom.id}')
                      .limitToLast(1)
                      .get())
                  .value as Map?)!
              .keys
              .first));

      await FirebaseDatabase.instance
          .ref(
              'users/${provider.currentUser!.id}/chat_rooms/${lastMessageDate.microsecondsSinceEpoch}')
          .remove();
      await FirebaseDatabase.instance
          .ref(
              'users/${provider.currentUser!.id}/chat_rooms/${message.date.microsecondsSinceEpoch}')
          .set({'chat_room_id': widget.chatRoom.id});

      await FirebaseDatabase.instance
          .ref(
              'users/${widget.chatRoom.secondUser?.id}/chat_rooms/${lastMessageDate.microsecondsSinceEpoch}')
          .remove();
      await FirebaseDatabase.instance
          .ref(
              'users/${widget.chatRoom.secondUser?.id}/chat_rooms/${message.date.microsecondsSinceEpoch}')
          .set({'chat_room_id': widget.chatRoom.id});

      await FirebaseDatabase.instance
          .ref(
              'messages/${widget.chatRoom.id}/${message.date.microsecondsSinceEpoch}')
          .set(message.toJson());
      chatRoom.lastMessageDate = message.date;

      message.pending = false;
      setState(() {});
    } catch (e) {
      setState(() {
        message.pending = false;
        message.failed = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: Colors.white,
        content: Text(
          'Couldn\'t send that message, please try again',
          style: TextStyle(
              color: Design.mainColor,
              fontWeight: FontWeight.w900,
              fontFamily: 'Inter'),
        ),
      ));
    }

    if (widget.chatRoom.secondUser!.messagingToken.isNotEmpty) {
      try {
        MessageNotification n = MessageNotification(
            getId(provider.currentUser!.id),
            provider.currentUser!.id,
            widget.chatRoom.id,
            widget.chatRoom.secondUser!.messagingToken);
        ServerHelper.sendNotification(n);
      } catch (e) {}
    }
  }

  @override
  void dispose() {
    removeTyping();
    typingStat.set(false);
    chatListener.cancel();
    modifyListener.cancel();
    removeListener.cancel();
    typingListener.cancel();
    activeListener.cancel();
    super.dispose();
  }

  void addTyping() {
    if (messages.firstOrNull?.content.isNotEmpty ?? true) {
      setState(() {
        messages.add(Message(
            userId: chatRoom.secondUser!.id,
            seen: false,
            liked: false,
            messageType: 'text',
            content: '',
            date: DateTime.now().add(const Duration(days: 365))));
      });
    }
  }

  void removeTyping() {
    if (messages.lastOrNull != null &&
        messages.last.content.isEmpty &&
        !messages.last.sent(provider.currentUser!.id)) {
      setState(() {
        messages.removeLast();
      });
    }
  }

  TextEditingController messageController = TextEditingController();
  bool down = true;

  late ValueNotifier<DateTime> currentDateNotifier;
  ValueNotifier<bool> loadMoreNotifier = ValueNotifier(false);

  waveform.RecorderController recorderController =
      waveform.RecorderController();

  SequenceAnimationController builderController = SequenceAnimationController();
  SequenceAnimationController popUpBuilderController =
      SequenceAnimationController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const BackgroundGradient(),
          Stack(
            children: [
              SafeArea(
                child: SequenceAnimationBuilder(
                  repeat: false,
                  animations: 6,
                  duration: const Duration(milliseconds: 400),
                  endCallback: () {
                    Navigator.of(context).pop();
                    provider.refreshMain?.call();
                  },
                  controller: builderController,
                  builder: (values, [child]) => PopScope(
                    canPop: false,
                    onPopInvoked: (didPop) {
                      if (controller.isCompleted) {
                        controller.reverse();
                      } else {
                        builderController.reverse!();
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 8.0, right: 8.0, top: 16.0, bottom: 36.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                UpwardCrossFade(
                                  value:
                                      Curves.easeOutBack.transform(values[0]),
                                  child: GestureDetector(
                                    onTap: () {
                                      if (controller.isCompleted) {
                                        controller.reverse();
                                      } else {
                                        builderController.reverse!();
                                      }
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [Design.shadow3]),
                                      height: provider.screenSize.width * .12,
                                      width: provider.screenSize.width * .12,
                                      child: Transform.scale(
                                        scale: .35,
                                        child: Image.asset(
                                          'images/arrow_left.png',
                                          color: Design.mainColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                UpwardCrossFade(
                                  value:
                                      Curves.easeOutBack.transform(values[1]),
                                  child: AnimatedBuilder(
                                    animation: fadeAnimation2,
                                    builder: (context, child) => Opacity(
                                        opacity: 1 - fadeAnimation2.value,
                                        child: child),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        DefaultTextStyle(
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 20.0,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Inter'),
                                          child:
                                              Text(chatRoom.secondUser!.name),
                                        ),
                                        Transform.translate(
                                          offset: const Offset(12.0, 0.0),
                                          child: AnimatedScale(
                                              duration: const Duration(
                                                  milliseconds: 400),
                                              scale: widget.chatRoom.secondUser!
                                                      .isActive
                                                  ? 1.0
                                                  : 0.0,
                                              alignment: Alignment.center,
                                              child: const ActiveDot()),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                                UpwardCrossFade(
                                  value:
                                      Curves.easeOutBack.transform(values[2]),
                                  child: GestureDetector(
                                    onTap: () {
                                      FocusManager.instance.primaryFocus
                                          ?.unfocus();
                                      if (controller.isDismissed) {
                                        controller.forward();
                                      } else {
                                        controller.reverse();
                                      }
                                    },
                                    child: AnimatedBuilder(
                                      animation: controller,
                                      builder: (context, child) => Container(
                                        decoration: BoxDecoration(
                                            color: colorAnimation1.value,
                                            shape: BoxShape.circle),
                                        height: provider.screenSize.width * .12,
                                        width: provider.screenSize.width * .12,
                                        child: Transform.scale(
                                          scale: .4,
                                          child: Image.asset(
                                            'images/info.png',
                                            color: colorAnimation2.value,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                          Expanded(
                            child: Stack(
                              children: [
                                AnimatedBuilder(
                                  animation: controller,
                                  builder: (context, child) => Opacity(
                                    opacity: fadeAnimation2.value,
                                    child: Container(
                                      height: provider.screenSize.height *
                                          .5 *
                                          scaleAnimation.value,
                                      width: provider.screenSize.width,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(48.0),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: Stack(
                                        children: [
                                          BackgroundPainter(
                                            key: const ValueKey(
                                                'infoBackground'),
                                            count: 8,
                                            size: 48 * scaleAnimation.value,
                                            color: Design.mainColor
                                                .withOpacity(.5),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal:
                                                    20.0 * scaleAnimation.value,
                                                vertical: 20.0 *
                                                    scaleAnimation.value),
                                            child: Column(
                                              children: [
                                                const Spacer(flex: 1),
                                                Container(
                                                  alignment: Alignment.center,
                                                  height: provider
                                                          .screenSize.width *
                                                      0.35 *
                                                      scaleAnimation.value,
                                                  width: provider
                                                          .screenSize.width *
                                                      0.35 *
                                                      scaleAnimation.value,
                                                  child: AnimatedContainer(
                                                    duration: const Duration(
                                                        milliseconds: 400),
                                                    clipBehavior:
                                                        Clip.antiAlias,
                                                    decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: widget
                                                                .chatRoom
                                                                .secondUser!
                                                                .isActive
                                                            ? Design.activeColor
                                                            : Design.mainColor,
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Design
                                                                .shadow2.color
                                                                .withOpacity(widget
                                                                        .chatRoom
                                                                        .secondUser!
                                                                        .isActive
                                                                    ? 0.5
                                                                    : 0.0),
                                                            blurRadius: widget
                                                                    .chatRoom
                                                                    .secondUser!
                                                                    .isActive
                                                                ? Design.shadow2
                                                                    .blurRadius
                                                                : 0.0,
                                                            offset: widget
                                                                    .chatRoom
                                                                    .secondUser!
                                                                    .isActive
                                                                ? Design.shadow2
                                                                    .offset
                                                                : Offset.zero,
                                                          )
                                                        ]),
                                                    constraints:
                                                        const BoxConstraints
                                                            .expand(),
                                                    child: Container(
                                                      margin:
                                                          const EdgeInsets.all(
                                                              2.0),
                                                      decoration:
                                                          const BoxDecoration(
                                                        shape: BoxShape.circle,
                                                      ),
                                                      clipBehavior:
                                                          Clip.antiAlias,
                                                      child: CachedNetworkImage(
                                                        imageUrl: widget
                                                                .chatRoom
                                                                .secondUser!
                                                                .pfpLink
                                                                .isEmpty
                                                            ? ''
                                                            : widget
                                                                .chatRoom
                                                                .secondUser!
                                                                .pfpLink,
                                                        placeholder:
                                                            (context, url) =>
                                                                Container(
                                                          color: Colors.white,
                                                          child: FittedBox(
                                                            fit:
                                                                BoxFit.fitWidth,
                                                            child:
                                                                Transform.scale(
                                                              scale: 0.3,
                                                              child:
                                                                  AnimatedDefaultTextStyle(
                                                                duration:
                                                                    const Duration(
                                                                        milliseconds:
                                                                            400),
                                                                style: TextStyle(
                                                                    color: widget
                                                                            .chatRoom
                                                                            .secondUser!
                                                                            .isActive
                                                                        ? Design
                                                                            .activeColor
                                                                        : Design
                                                                            .mainColor,
                                                                    fontSize:
                                                                        100.0,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w900),
                                                                child: Text(
                                                                  widget
                                                                      .chatRoom
                                                                      .secondUser!
                                                                      .name[0],
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        errorWidget: (context,
                                                                url, error) =>
                                                            Container(
                                                          color: Colors.white,
                                                          child: FittedBox(
                                                            fit:
                                                                BoxFit.fitWidth,
                                                            child:
                                                                Transform.scale(
                                                              scale: 0.3,
                                                              child:
                                                                  AnimatedDefaultTextStyle(
                                                                duration:
                                                                    const Duration(
                                                                        milliseconds:
                                                                            400),
                                                                style: TextStyle(
                                                                    color: widget
                                                                            .chatRoom
                                                                            .secondUser!
                                                                            .isActive
                                                                        ? Design
                                                                            .activeColor
                                                                        : Design
                                                                            .mainColor,
                                                                    fontSize:
                                                                        100.0,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w900),
                                                                child: Text(
                                                                  widget
                                                                      .chatRoom
                                                                      .secondUser!
                                                                      .name[0],
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const Spacer(flex: 1),
                                                Text(
                                                  widget.chatRoom.secondUser!
                                                      .name,
                                                  style: TextStyle(
                                                    color: Design.mainColor,
                                                    fontFamily: 'Inter',
                                                    fontSize: 26.0 *
                                                        scaleAnimation.value,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  widget.chatRoom.secondUser!
                                                      .status,
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color: Design.mainColor,
                                                    fontFamily: 'Inter',
                                                    fontSize: 14.0 *
                                                        scaleAnimation.value,
                                                    fontWeight: FontWeight.w300,
                                                  ),
                                                ),
                                                const Spacer(flex: 2),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceEvenly,
                                                  children: [
                                                    Expanded(
                                                      child: Column(
                                                        children: [
                                                          Container(
                                                              decoration: BoxDecoration(
                                                                  color: Colors
                                                                      .white,
                                                                  shape: BoxShape
                                                                      .circle,
                                                                  boxShadow: [
                                                                    Design
                                                                        .shadow3
                                                                  ]),
                                                              height: provider
                                                                      .screenSize
                                                                      .width *
                                                                  .12 *
                                                                  scaleAnimation
                                                                      .value,
                                                              width: provider
                                                                      .screenSize
                                                                      .width *
                                                                  .12 *
                                                                  scaleAnimation
                                                                      .value,
                                                              child: Transform
                                                                  .scale(
                                                                scale: .5,
                                                                child:
                                                                    Image.asset(
                                                                  'images/mute_on.png',
                                                                  color: Design
                                                                      .mainColor,
                                                                ),
                                                              )),
                                                          SizedBox(
                                                            height: 8.0 *
                                                                scaleAnimation
                                                                    .value,
                                                          ),
                                                          Text('Mute',
                                                              style: TextStyle(
                                                                color: Design
                                                                    .mainColor,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w900,
                                                                fontFamily:
                                                                    'Inter',
                                                                fontSize: 12.0 *
                                                                    scaleAnimation
                                                                        .value,
                                                              ))
                                                        ],
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: Column(
                                                        children: [
                                                          Container(
                                                              decoration: BoxDecoration(
                                                                  color: Design
                                                                      .mainColor,
                                                                  shape: BoxShape.circle,
                                                                  boxShadow: [
                                                                    Design
                                                                        .shadow3
                                                                  ]),
                                                              height: provider
                                                                      .screenSize
                                                                      .width *
                                                                  .12 *
                                                                  scaleAnimation
                                                                      .value,
                                                              width: provider
                                                                      .screenSize
                                                                      .width *
                                                                  .12 *
                                                                  scaleAnimation
                                                                      .value,
                                                              child: Transform
                                                                  .scale(
                                                                scale: .5,
                                                                child:
                                                                    Image.asset(
                                                                  'images/remove_person.png',
                                                                  color: Colors
                                                                      .white,
                                                                ),
                                                              )),
                                                          SizedBox(
                                                            height: 8.0 *
                                                                scaleAnimation
                                                                    .value,
                                                          ),
                                                          Text('Unfriend',
                                                              style: TextStyle(
                                                                color: Design
                                                                    .mainColor,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w900,
                                                                fontFamily:
                                                                    'Inter',
                                                                fontSize: 12.0 *
                                                                    scaleAnimation
                                                                        .value,
                                                              ))
                                                        ],
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: Column(
                                                        children: [
                                                          Container(
                                                              decoration: BoxDecoration(
                                                                  color: Colors
                                                                      .white,
                                                                  shape: BoxShape
                                                                      .circle,
                                                                  boxShadow: [
                                                                    Design
                                                                        .shadow3
                                                                  ]),
                                                              height: provider
                                                                      .screenSize
                                                                      .width *
                                                                  .12 *
                                                                  scaleAnimation
                                                                      .value,
                                                              width: provider
                                                                      .screenSize
                                                                      .width *
                                                                  .12 *
                                                                  scaleAnimation
                                                                      .value,
                                                              child: Transform
                                                                  .scale(
                                                                scale: .5,
                                                                child:
                                                                    Image.asset(
                                                                  'images/delete.png',
                                                                  color: Design
                                                                      .mainColor,
                                                                ),
                                                              )),
                                                          SizedBox(
                                                            height: 8.0 *
                                                                scaleAnimation
                                                                    .value,
                                                          ),
                                                          Text('Delete Chat',
                                                              style: TextStyle(
                                                                color: Design
                                                                    .mainColor,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w900,
                                                                fontFamily:
                                                                    'Inter',
                                                                fontSize: 12.0 *
                                                                    scaleAnimation
                                                                        .value,
                                                              ))
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const Spacer(flex: 1),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                AnimatedBuilder(
                                  animation: controller,
                                  builder: (context, child) =>
                                      Transform.translate(
                                          offset: slideAnimation.value,
                                          child: Opacity(
                                            opacity: fadeAnimation.value,
                                            child: child,
                                          )),
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: UpwardCrossFade(
                                          value: Curves.easeOutBack
                                              .transform(values[3]),
                                          limit: .5,
                                          child: Stack(
                                            children: [
                                              Container(
                                                clipBehavior: Clip.antiAlias,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          36.0),
                                                  color: Colors.white,
                                                ),
                                                child: Stack(
                                                  alignment:
                                                      Alignment.topCenter,
                                                  children: [
                                                    BackgroundPainter(
                                                      count: 8,
                                                      size: 48,
                                                      color: Design.mainColor
                                                          .withOpacity(.5),
                                                    ),
                                                    ChatMessageList(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              top: 24.0,
                                                              left: 24.0,
                                                              right: 24.0,
                                                              bottom: 24.0),
                                                      controller:
                                                          chatListController,
                                                      messages: List.generate(
                                                        messages.length,
                                                        (index) {
                                                          index =
                                                              messages.length -
                                                                  1 -
                                                                  index;
                                                          int shapeType = 0;
                                                          double topPadding =
                                                              index == 0
                                                                  ? 0.0
                                                                  : 8.0;
                                                          double bottomPadding =
                                                              index ==
                                                                      messages.length -
                                                                          1
                                                                  ? 0.0
                                                                  : 8.0;

                                                          try {
                                                            if (messages[index -
                                                                        1]
                                                                    .sent(provider
                                                                        .currentUser!
                                                                        .id) ==
                                                                messages[index]
                                                                    .sent(provider
                                                                        .currentUser!
                                                                        .id)) {
                                                              shapeType = 1;
                                                              topPadding = 2.0;
                                                            }
                                                          } catch (e) {
                                                            //
                                                          }
                                                          try {
                                                            if (messages[index +
                                                                        1]
                                                                    .sent(provider
                                                                        .currentUser!
                                                                        .id) ==
                                                                messages[index]
                                                                    .sent(provider
                                                                        .currentUser!
                                                                        .id)) {
                                                              if (shapeType ==
                                                                  1) {
                                                                shapeType = 2;
                                                              }
                                                              bottomPadding =
                                                                  2.0;
                                                            }
                                                          } catch (e) {
                                                            //
                                                          }

                                                          bool withDate = false;
                                                          if (messages[index]
                                                                  .content
                                                                  .isEmpty &&
                                                              !messages[index]
                                                                  .sent(provider
                                                                      .currentUser!
                                                                      .id)) {
                                                          } else {
                                                            if (index ==
                                                                    messages.length -
                                                                        1 ||
                                                                messages[index +
                                                                            1]
                                                                        .userId !=
                                                                    messages[
                                                                            index]
                                                                        .userId) {
                                                              withDate = true;
                                                            }
                                                            // if(index != 0 && messages
                                                            // [index].date.difference(messages
                                                            // [index].date).inHours > 2){
                                                            //   withDateDiff  = true;
                                                            // }
                                                          }

                                                          return ChatMessage(
                                                              widget: messages[
                                                                              index]
                                                                          .content
                                                                          .isEmpty &&
                                                                      !messages[
                                                                              index]
                                                                          .sent(provider
                                                                              .currentUser!
                                                                              .id)
                                                                  ? ChatTyping(
                                                                      key: const ValueKey(
                                                                          'TypingWidget'),
                                                                      shapeType:
                                                                          shapeType,
                                                                    )
                                                                  : ShowingDetector(
                                                                      onShowing:
                                                                          () {
                                                                        if (convertDate(currentDateNotifier.value) !=
                                                                            convertDate(messages[index].date)) {
                                                                          currentDateNotifier.value =
                                                                              messages[index].date;
                                                                        }
                                                                      },
                                                                      key: ValueKey(
                                                                          messages[index]
                                                                              .date),
                                                                      child:
                                                                          MessageWidget(
                                                                        chatRoom:
                                                                            widget.chatRoom,
                                                                        message:
                                                                            messages[index],
                                                                        shapeType:
                                                                            shapeType,
                                                                        key: ValueKey(
                                                                            'message${messages[index].date}'),
                                                                        withDate:
                                                                            withDate,
                                                                        lastMessage:
                                                                            index ==
                                                                                messages.length - 1,
                                                                        padding: EdgeInsets.only(
                                                                            top:
                                                                                topPadding,
                                                                            bottom:
                                                                                bottomPadding),
                                                                      ),
                                                                    ),
                                                              alignment: messages[
                                                                          index]
                                                                      .sent(provider
                                                                          .currentUser!
                                                                          .id)
                                                                  ? Alignment
                                                                      .bottomRight
                                                                  : Alignment
                                                                      .bottomLeft);
                                                        },
                                                      ),
                                                    ),
                                                    ValueListenableBuilder(
                                                        valueListenable:
                                                            loadMoreNotifier,
                                                        builder: (context,
                                                                value, child) =>
                                                            AnimatedPositioned(
                                                              duration:
                                                                  const Duration(
                                                                      milliseconds:
                                                                          400),
                                                              top: value
                                                                  ? 36
                                                                  : -40,
                                                              curve: value
                                                                  ? Curves
                                                                      .easeOutBack
                                                                  : Curves
                                                                      .easeIn,
                                                              child: child!,
                                                            ),
                                                        child: const Typing()),
                                                    ValueListenableBuilder(
                                                      valueListenable:
                                                          scrolledUp,
                                                      builder: (context, value,
                                                              child) =>
                                                          AnimatedPositioned(
                                                        duration:
                                                            const Duration(
                                                                milliseconds:
                                                                    400),
                                                        bottom: value
                                                            ? 36
                                                            : -provider
                                                                    .screenSize
                                                                    .width *
                                                                .1,
                                                        curve: value
                                                            ? Curves.easeOutBack
                                                            : Curves.easeIn,
                                                        child: GestureDetector(
                                                          onTap: () => chatListController
                                                              .animateTo(0,
                                                                  duration: const Duration(
                                                                      milliseconds:
                                                                          400),
                                                                  curve: Curves
                                                                      .easeOut),
                                                          child: Container(
                                                              height: provider
                                                                      .screenSize
                                                                      .width *
                                                                  .1,
                                                              width: provider
                                                                      .screenSize
                                                                      .width *
                                                                  .3,
                                                              decoration: BoxDecoration(
                                                                  color: Design
                                                                      .mainColor,
                                                                  borderRadius: BorderRadius.circular(20),
                                                                  boxShadow: [
                                                                    Design
                                                                        .shadow1
                                                                  ]),
                                                              padding: EdgeInsets
                                                                  .all(provider
                                                                          .screenSize
                                                                          .width *
                                                                      .025),
                                                              child: const Row(
                                                                children: [
                                                                  FittedBox(
                                                                    child: Icon(
                                                                      Icons
                                                                          .arrow_circle_down,
                                                                      color: Colors
                                                                          .white,
                                                                    ),
                                                                  ),
                                                                  SizedBox(
                                                                      width:
                                                                          2.0),
                                                                  Expanded(
                                                                    child:
                                                                        FittedBox(
                                                                      child: Text(
                                                                          'Scroll Down',
                                                                          textAlign: TextAlign
                                                                              .center,
                                                                          style:
                                                                              TextStyle(
                                                                            color:
                                                                                Colors.white,
                                                                            fontFamily:
                                                                                'Inter',
                                                                            fontWeight:
                                                                                FontWeight.w900,
                                                                          )),
                                                                    ),
                                                                  ),
                                                                ],
                                                              )),
                                                        ),
                                                      ),
                                                    )
                                                  ],
                                                ),
                                              ),
                                              Align(
                                                alignment: Alignment.topCenter,
                                                child: FractionalTranslation(
                                                  translation:
                                                      const Offset(0.0, -.5),
                                                  child: ValueListenableBuilder(
                                                    valueListenable:
                                                        currentDateNotifier,
                                                    builder: (context, value,
                                                            child) =>
                                                        Container(
                                                      decoration: BoxDecoration(
                                                          color: Colors.white,
                                                          border: Border.all(
                                                              color:
                                                                  Colors.white,
                                                              width: 1.0),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      100),
                                                          boxShadow: [
                                                            Design.shadow3
                                                          ]),
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          vertical: 4.0,
                                                          horizontal: 16.0),
                                                      child: AnimatedSize(
                                                        clipBehavior: Clip.none,
                                                        duration:
                                                            const Duration(
                                                                milliseconds:
                                                                    400),
                                                        curve:
                                                            Curves.easeOutBack,
                                                        child: AnimatedSwitcher(
                                                          duration:
                                                              const Duration(
                                                                  milliseconds:
                                                                      400),
                                                          switchInCurve:
                                                              Curves.easeInQuad,
                                                          switchOutCurve: Curves
                                                              .easeOutQuad,
                                                          child: Text(
                                                            convertDate(
                                                                currentDateNotifier
                                                                    .value),
                                                            key: ValueKey(
                                                                convertDate(
                                                                    currentDateNotifier
                                                                        .value)),
                                                            style: const TextStyle(
                                                                fontSize: 12.0,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w900,
                                                                color: Design
                                                                    .mainColor),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Expanded(
                                            flex: 4,
                                            child: UpwardCrossFade(
                                              value: Curves.easeOutBack
                                                  .transform(values[4]),
                                              child: AnimatedContainer(
                                                duration: const Duration(
                                                    milliseconds: 400),
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 20.0),
                                                decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            48.0),
                                                    color: isRecording
                                                        ? Design.mainColor
                                                        : Colors.white,
                                                    boxShadow: [
                                                      Design.shadow1
                                                    ]),
                                                clipBehavior: Clip.antiAlias,
                                                child: AnimatedSwitcher(
                                                  duration: const Duration(
                                                      milliseconds: 400),
                                                  child: isRecording
                                                      ? AnimatedBuilder(
                                                          animation:
                                                              recorderController,
                                                          builder: (context,
                                                                  child) =>
                                                              RecordingWidget(
                                                                  data: recorderController
                                                                      .waveData))
                                                      : Row(
                                                          children: [
                                                            GestureDetector(
                                                              onTapUp:
                                                                  (details) {
                                                                setState(() {
                                                                  popUpLocation =
                                                                      details
                                                                          .globalPosition;
                                                                });
                                                              },
                                                              child: Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .all(
                                                                        12.0),
                                                                child:
                                                                    AnimatedRotation(
                                                                  turns: popUpLocation ==
                                                                          null
                                                                      ? 0
                                                                      : math.pi /
                                                                          5,
                                                                  duration: const Duration(
                                                                      milliseconds:
                                                                          400),
                                                                  curve: Curves
                                                                      .easeOutBack,
                                                                  child: Image
                                                                      .asset(
                                                                    'images/add.png',
                                                                    color: Design
                                                                        .mainColor,
                                                                    width: 26.0,
                                                                    height:
                                                                        26.0,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                            Expanded(
                                                              child:
                                                                  RawScrollbar(
                                                                radius:
                                                                    const Radius
                                                                        .circular(
                                                                        2.0),
                                                                thickness: 4.0,
                                                                thumbColor:
                                                                    Colors
                                                                        .white54,
                                                                crossAxisMargin:
                                                                    -8.0,
                                                                child:
                                                                    TextFormField(
                                                                  controller:
                                                                      messageController,
                                                                  keyboardType:
                                                                      TextInputType
                                                                          .multiline,
                                                                  minLines: 1,
                                                                  maxLines: 4,
                                                                  onChanged:
                                                                      (value) {
                                                                    if (value
                                                                            .trim()
                                                                            .isEmpty &&
                                                                        enabled) {
                                                                      typingStat
                                                                          .set(
                                                                              false);
                                                                      setState(
                                                                          () {
                                                                        enabled =
                                                                            false;
                                                                      });
                                                                    }
                                                                    if (value
                                                                            .trim()
                                                                            .isNotEmpty &&
                                                                        !enabled) {
                                                                      typingStat
                                                                          .set(
                                                                              true);
                                                                      setState(
                                                                          () {
                                                                        enabled =
                                                                            true;
                                                                      });
                                                                    }
                                                                  },
                                                                  decoration:
                                                                      InputDecoration(
                                                                    border:
                                                                        InputBorder
                                                                            .none,
                                                                    hintText:
                                                                        'Say Hello...',
                                                                    hintStyle:
                                                                        TextStyle(
                                                                      color: Design
                                                                          .mainColor
                                                                          .withOpacity(
                                                                              .7),
                                                                            
                                                                    ),
                                                                  ),
                                                                  cursorOpacityAnimates:
                                                                      true,
                                                                  style:
                                                                      const TextStyle(
                                                                    color: Design
                                                                        .mainColor,

                                                                        fontFamily: 'Inter',

                                                                          fontWeight: FontWeight.w500,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                            // TODO: Add emoji button
                                                            // Padding(
                                                            //   padding:
                                                            //       const EdgeInsets
                                                            //           .symmetric(
                                                            //           horizontal:
                                                            //               12.0),
                                                            //   child:
                                                            //       Image.asset(
                                                            //     'images/emoji.png',
                                                            //     color: Design
                                                            //         .mainColor
                                                            //         .withOpacity(
                                                            //             .5),
                                                            //     width: 26.0,
                                                            //     height: 26.0,
                                                            //   ),
                                                            // ),
                                                          ],
                                                        ),
                                                ),
                                                /*
                                                  AnimatedBuilder(animation: recorderController, builder: (context, child) => AnimatedOpacity(
                                                      opacity: recorderController.isRecording ? 1.0 : 0.0,
                                                      duration: const Duration(milliseconds: 400),
                                                      child: child,
                                                    ),
                                                    child: LayoutBuilder(
                                                      builder: (context, constraints) => AudioWaveforms(
                                                        size: Size(constraints.maxWidth, 54.0),
                                                        backgroundColor: Design.mainColor,
                                                        recorderController: recorderController,
                                                        shouldCalculateScrolledPosition: true,

                                                        waveStyle: WaveStyle(
                                                            waveColor: Colors.white,
                                                            spacing: 12.0,
                                                              gradient: ui.Gradient.linear(
                                                              const Offset(0, 27.0),
                                                              Offset(constraints.maxWidth, 27.0),
                                                              [Design.mainColor, Colors.white ,Colors.white ,Design.mainColor ],
                                                                  [0.0 , 0.1 , 0.8 , 1.0]

                                                            ),
                                                            extendWaveform: true,
                                                            showMiddleLine: false,
                                                            waveThickness: 8.0
                                                        ),
                                                      ),
                                                    ),
                                                    )
                                                 */
                                              ),
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () async {
                                              final path =
                                                  await recorderController
                                                      .stop();
                                              if (path != null) {
                                                File audioFile = File(path);
                                                audioFile.delete();
                                              }
                                              setState(() {
                                                isRecording = false;
                                              });
                                            },
                                            child: AnimatedContainer(
                                                duration: const Duration(
                                                    milliseconds: 400),
                                                curve: isRecording
                                                    ? Curves.easeOutBack
                                                    : Curves.easeOut,
                                                margin: EdgeInsets.only(
                                                    left: isRecording
                                                        ? 16.0
                                                        : 0.0),
                                                decoration: BoxDecoration(
                                                    color: Design.mainColor,
                                                    shape: BoxShape.circle,
                                                    boxShadow: [
                                                      Design.shadow1
                                                    ]),
                                                padding: EdgeInsets.all(
                                                    isRecording ? 16.0 : 0.0),
                                                child: Image.asset(
                                                  'images/delete.png',
                                                  key: const ValueKey('delete'),
                                                  color: Colors.white,
                                                  height:
                                                      isRecording ? 22.0 : 0.0,
                                                  width:
                                                      isRecording ? 22.0 : 0.0,
                                                )),
                                          ),
                                          UpwardCrossFade(
                                            value: Curves.easeOutBack
                                                .transform(values[5]),
                                            child: GestureDetector(
                                              onTap: () async {
                                                if (enabled) {
                                                  typingStat.set(false);
                                                  addMessage(
                                                      Message(
                                                          userId: provider
                                                              .currentUser!.id,
                                                          content:
                                                              messageController
                                                                  .text.trim(),
                                                          seen: false,
                                                          liked: false,
                                                          date: DateTime.now(),
                                                          messageType: 'text'),
                                                      context);
                                                  setState(() {
                                                    enabled = false;
                                                  });
                                                  messageController.clear();
                                                } else {
                                                  if (recorderController
                                                      .isRecording) {
                                                    setState(
                                                      () => isRecording = false,
                                                    );
                                                    final audioPath =
                                                        await recorderController
                                                            .stop();
                                                    if (audioPath != null) {
                                                      File currentAudioFile =
                                                          File(audioPath);

                                                      await addMessage(
                                                          Message(
                                                              userId: provider
                                                                  .currentUser!
                                                                  .id,
                                                              content:
                                                                  path.basename(
                                                                      audioPath),
                                                              seen: false,
                                                              liked: false,
                                                              date: DateTime
                                                                  .now(),
                                                              messageType:
                                                                  'audio'),
                                                          context,
                                                          media: Media('audio',
                                                              currentAudioFile));

                                                      currentAudioFile.delete();
                                                    }
                                                  } else {
                                                    final hasPermission =
                                                        await recorderController
                                                            .checkPermission();
                                                    if (hasPermission) {
                                                      setState(
                                                        () =>
                                                            isRecording = true,
                                                      );
                                                      final path =
                                                          '${(await getApplicationCacheDirectory()).path}/a${DateTime.now().toString().trim().replaceAll(' ', '')}.m4a';
                                                      await recorderController
                                                          .record(path: path);
                                                    } else {
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                              const SnackBar(
                                                        content: Text(
                                                          'Can\'t record audio without permission',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontFamily: 'Inter',
                                                            fontWeight:
                                                                FontWeight.w900,
                                                            fontSize: 20.0,
                                                          ),
                                                        ),
                                                        backgroundColor:
                                                            Design.mainColor,
                                                      ));
                                                    }
                                                  }
                                                }
                                              },
                                              child: Container(
                                                  margin: const EdgeInsets.only(
                                                      left: 16.0),
                                                  decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      shape: BoxShape.circle,
                                                      boxShadow: [
                                                        Design.shadow1
                                                      ]),
                                                  padding: const EdgeInsets.all(
                                                      14.0),
                                                  child: IconSwitcher(
                                                    icon: enabled
                                                        ? Image.asset(
                                                            'images/send.png',
                                                            key: const ValueKey(
                                                                'Send Button'),
                                                            color: Design
                                                                .mainColor,
                                                            height: 26.0,
                                                            width: 26.0,
                                                          )
                                                        : isRecording
                                                            ? Image.asset(
                                                                'images/send.png',
                                                                key: const ValueKey(
                                                                    'Finish Record Button'),
                                                                color: Design
                                                                    .mainColor,
                                                                height: 26.0,
                                                                width: 26.0,
                                                              )
                                                            : Image.asset(
                                                                'images/mic.png',
                                                                key: const ValueKey(
                                                                    'Record Button'),
                                                                color: Design
                                                                    .mainColor,
                                                                height: 26.0,
                                                                width: 26.0,
                                                              ),
                                                  )),
                                            ),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (popUpLocation != null)
                SequenceAnimationBuilder(
                  animations: 1,
                  repeat: false,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.linear,
                  endCallback: () => setState(() => popUpLocation = null),
                  controller: popUpBuilderController,
                  builder: (values, [child]) => PopScope(
                    onPopInvoked: (didPop) => popUpBuilderController.reverse!(),
                    canPop: false,
                    child: Stack(
                      children: [
                        Positioned.fill(
                            child: BackdropFilter(
                          filter: ImageFilter.blur(
                              sigmaX: (values[0] * 1.0).clamp(0.00001, 1.0),
                              sigmaY: (values[0] * 1.0).clamp(0.00001, 1)),
                          child: GestureDetector(
                              onTap: () => popUpBuilderController.reverse!()),
                        )),
                        Positioned(
                          top: popUpLocation!.dy -
                              MediaQuery.sizeOf(context).width * .4 -
                              16.0,
                          left: 24,
                          child: Opacity(
                            opacity: values[0],
                            child: Transform.scale(
                              scale: Curves.easeOutBack.transform(values[0]),
                              child: Container(
                                  width: MediaQuery.sizeOf(context).width * .4,
                                  height: MediaQuery.sizeOf(context).width * .4,
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(24),
                                      color: Colors.white,
                                      boxShadow: [Design.shadow3]),
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () async {
                                            popUpBuilderController.reverse!();
                                            XFile? image = await ImagePicker()
                                                .pickImage(
                                                    source:
                                                        ImageSource.gallery);
                                            if (image != null) {
                                              DateTime creationDate =
                                                  DateTime.now();

                                              addMessage(
                                                  Message(
                                                      userId: Provider.of<
                                                                  MainProvider>(
                                                              context)
                                                          .currentUser!
                                                          .id,
                                                      content:
                                                          'i${creationDate.toString().trim().replaceAll(' ', '')}${path.extension(image.path)}',
                                                      seen: false,
                                                      liked: false,
                                                      date: creationDate,
                                                      messageType: 'image'),
                                                  context,
                                                  media: Media('image',
                                                      File(image.path)));
                                            }
                                          },
                                          child: Container(
                                            color: Colors.transparent,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 24.0),
                                            child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceAround,
                                                children: [
                                                  Image.asset(
                                                      'images/image.png',
                                                      width: 28,
                                                      height: 28,
                                                      color: Design.mainColor),
                                                  const Text('Image',
                                                      style: TextStyle(
                                                          fontSize: 14.0,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color:
                                                              Design.mainColor,
                                                          fontFamily: 'Inter'))
                                                ]),
                                          ),
                                        ),
                                      ),
                                      // TODO: Add video button
                                      //                   Expanded(child: GestureDetector(
                                      //                     onTap: ()async{
                                      //                       popUpBuilderController.reverse!();
                                      //     XFile? video = await ImagePicker().pickVideo(source: ImageSource.gallery);
                                      //                 if(video != null){
                                      // // send Video
                                      //                 }
                                      //     },
                                      //                     child: Container(
                                      //                       color:Colors.transparent,
                                      //                       padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                      //                       child: Row(
                                      //                           mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      //                           children: [
                                      //                             Image.asset('images/add.png' , width: 20, height: 20 , color: Design.mainColor),
                                      //                             const Text('Video' , style: TextStyle(
                                      //                                 fontSize: 14.0 ,
                                      //                                 fontWeight: FontWeight.bold,
                                      //                                 color: Design.mainColor,
                                      //                                 fontFamily: 'Inter'
                                      //                             ))
                                      //                           ]
                                      //                       ),
                                      //                     ),
                                      //                   )),
                                      Expanded(
                                          child: GestureDetector(
                                        onTap: () async {
                                          popUpBuilderController.reverse!();
                                          XFile? audio =
                                              await ImagePicker().pickMedia();
                                          if (audio != null) {
                                            DateTime creationDate =
                                                DateTime.now();

                                            addMessage(
                                                Message(
                                                    userId: Provider.of<
                                                                MainProvider>(
                                                            context)
                                                        .currentUser!
                                                        .id,
                                                    content:
                                                        'a${creationDate.toString().replaceAll(' ', '')}${path.extension(audio.path)}',
                                                    seen: false,
                                                    liked: false,
                                                    date: creationDate,
                                                    messageType: 'audio'),
                                                context,
                                                media: Media(
                                                    'audio', File(audio.path)));
                                          }
                                        },
                                        child: Container(
                                          color: Colors.transparent,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 24.0),
                                          child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceAround,
                                              children: [
                                                Image.asset('images/audio.png',
                                                    width: 28,
                                                    height: 28,
                                                    color: Design.mainColor),
                                                const Text('Audio',
                                                    style: TextStyle(
                                                        fontSize: 14.0,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Design.mainColor,
                                                        fontFamily: 'Inter'))
                                              ]),
                                        ),
                                      ))
                                    ],
                                  )),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
            ],
          ),
        ],
      ),
    );
  }

  String convertDate(DateTime dateTime) {
    if (DateTime.now().year - dateTime.year > 0) {
      return intl.DateFormat().add_yMMMd().format(dateTime);
    }
    if (DateTime.now().day - dateTime.day > 1) {
      return intl.DateFormat().add_MMMd().format(dateTime);
    }
    if (DateTime.now().day - dateTime.day == 1) {
      return 'Yesterday';
    }
    if (DateTime.now().day - dateTime.day == 0) {
      return 'Today';
    }
    return 'Didn\'t code that one';
  }
}

class ChatMessage {
  final Alignment alignment;
  AnimationController? controller;
  Widget widget;

  ChatMessage({
    this.alignment = Alignment.bottomLeft,
    required this.widget,
    this.controller,
  });
}

class ChatMessageList extends StatefulWidget {
  final List<ChatMessage> messages;
  final EdgeInsets padding;
  final ScrollController? controller;
  const ChatMessageList(
      {super.key,
      required this.messages,
      this.padding = EdgeInsets.zero,
      this.controller});

  @override
  State<ChatMessageList> createState() => _ChatMessageListState();
}

class _ChatMessageListState extends State<ChatMessageList>
    with TickerProviderStateMixin {
  int childAddedIndex = -1;
  int childRemovedIndex = -1;
  late List<ChatMessage> children;

  @override
  void initState() {
    super.initState();
    children = [];
    for (ChatMessage child in widget.messages) {
      child.controller = AnimationController(
          vsync: this, duration: const Duration(milliseconds: 400))
        ..value = 1.0;
      children.add(child);
    }
  }

  @override
  Widget build(BuildContext context) {
    for (int i = 0; i < widget.messages.length; i++) {
      if (children
              .where((element) =>
                  element.widget.key == widget.messages[i].widget.key)
              .firstOrNull ==
          null) {
        childAddedIndex = i;
        AnimationController controller = AnimationController(
            vsync: this, duration: const Duration(milliseconds: 400));
        controller.addListener(() {
          if (controller.isCompleted) childAddedIndex = -1;
        });
        controller.forward();
        if (i == children.length) {
          children.add(widget.messages[i]..controller = controller);
        } else {
          children.insert(i, widget.messages[i]..controller = controller);
        }
      }
    }

    for (int i = 0; i < children.length; i++) {
      ChatMessage? child = widget.messages
          .where((element) => element.widget.key == children[i].widget.key)
          .firstOrNull;
      if (child == null) {
        childRemovedIndex = i;
        children[i].controller!.addListener(() {
          if (children[i].controller!.isDismissed) {
            childRemovedIndex = -1;
            setState(() {
              children.remove(children[i]);
            });
          }
        });
        children[i].controller!.reverse();
      } else {
        if (child.widget != children[i].widget) {
          children[children.indexWhere(
                  (element) => element.widget.key == child.widget.key)]
              .widget = child.widget;
        }
      }
    }

    return ListView(
      reverse: true,
      padding: widget.padding,
      controller: widget.controller,
      children: List.generate(
        children.length,
        (index) {
          return FadeTransition(
            key: ValueKey('child${children[index].widget.key}'),
            opacity: CurvedAnimation(
                parent: children[index].controller!, curve: Curves.easeIn),
            child: SlideTransition(
              position: Tween<Offset>(
                      begin: Offset(children[index].alignment.x,
                          children[index].alignment.y),
                      end: Offset.zero)
                  .animate(CurvedAnimation(
                      parent: children[index].controller!,
                      curve: Curves.easeOutQuad)),
              child: ScaleTransition(
                scale: CurvedAnimation(
                    parent: children[index].controller!,
                    curve: Curves.easeOutBack),
                alignment: children[index].alignment,
                child: AnimatedBuilder(
                    animation: children[index].controller!,
                    builder: (context, child) => Align(
                          alignment: Alignment.center,
                          heightFactor: Curves.easeOutQuad
                              .transform(children[index].controller!.value),
                          widthFactor: 1.0,
                          child: child,
                        ),
                    child: children[index].widget),
              ),
            ),
          );
        },
      ),
    );
  }
}

class ActiveDot extends StatefulWidget {
  const ActiveDot({super.key});

  @override
  State<ActiveDot> createState() => _ActiveDotState();
}

class _ActiveDotState extends State<ActiveDot>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> opacityAnimation;
  late Animation<double> scaleAnimation;

  @override
  void initState() {
    super.initState();
    controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 1));
    opacityAnimation = Tween(begin: 1.0, end: 0.0)
        .animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));
    scaleAnimation = Tween(begin: 1.0, end: 4.0)
        .animate(CurvedAnimation(parent: controller, curve: Curves.easeIn));

    runAnimations();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void runAnimations() async {
    while (mounted) {
      await controller.forward(from: 0.0);
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 8.0,
          height: 8.0,
          decoration: const BoxDecoration(
              shape: BoxShape.circle, color: Design.activeColor),
        ),
        ScaleTransition(
          scale: scaleAnimation,
          child: FadeTransition(
            opacity: opacityAnimation,
            child: Container(
              width: 8.0,
              height: 8.0,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: Design.activeColor),
            ),
          ),
        ),
      ],
    );
  }
}

class ShowingDetector extends StatefulWidget {
  final Function onShowing;
  final Widget child;
  const ShowingDetector(
      {required super.key, required this.onShowing, required this.child});

  @override
  State<ShowingDetector> createState() => _ShowingDetectorState();
}

class _ShowingDetectorState extends State<ShowingDetector> {
  double lastVisibilityFraction = 1.0;
  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: widget.key!,
      child: widget.child,
      onVisibilityChanged: (info) {
        if (info.visibleFraction > lastVisibilityFraction &&
            info.visibleFraction == 1.0) {
          widget.onShowing.call();
        }
        lastVisibilityFraction = info.visibleFraction;
      },
    );
  }
}

class RecordingWidget extends StatefulWidget {
  final List<double> data;
  const RecordingWidget({super.key, required this.data});

  @override
  State<RecordingWidget> createState() => _RecordingWidgetState();
}

class _RecordingWidgetState extends State<RecordingWidget> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          reverse: true,
          scrollDirection: Axis.horizontal,
          children: List.generate(
              widget.data.length,
              (index) => TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 250),
                    key: ValueKey('wave_$index'),
                    builder: (context, value, child) => Align(
                      alignment: Alignment.center,
                      child: Container(
                        width: 10 * value,
                        height: 10 * value + value * widget.data[index] * 44,
                        margin: const EdgeInsets.symmetric(horizontal: 2.0),
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(value),
                            borderRadius: BorderRadius.circular(5)),
                      ),
                    ),
                  )).reversed.toList()),
    );
  }
}

class MessageWidget extends StatefulWidget {
  final Message message;
  final int shapeType;

  final EdgeInsets padding;
  final bool withDate;
  final bool lastMessage;
  final ChatRoom chatRoom;

  const MessageWidget({
    super.key,
    required this.message,
    required this.shapeType,
    required this.padding,
    required this.withDate,
    required this.lastMessage,
    required this.chatRoom,
  });

  @override
  State<MessageWidget> createState() => _MessageWidgetState();
}

class _MessageWidgetState extends State<MessageWidget> {
  static const Radius hardEdge = Radius.circular(4.0);
  static const Radius softEdge = Radius.circular(24.0);

  bool forceDate = false;
  bool showDeleteOption = false;

  late MainProvider provider;
  @override
  Widget build(BuildContext context) {
    provider = Provider.of<MainProvider>(context, listen: false);
    BorderRadius shape0 = BorderRadius.only(
        topLeft: softEdge,
        topRight: softEdge,
        bottomLeft:
            widget.message.sent(provider.currentUser!.id) ? softEdge : hardEdge,
        bottomRight: widget.message.sent(provider.currentUser!.id)
            ? hardEdge
            : softEdge);
    BorderRadius shape1 = BorderRadius.only(
        topLeft:
            widget.message.sent(provider.currentUser!.id) ? softEdge : hardEdge,
        topRight:
            widget.message.sent(provider.currentUser!.id) ? hardEdge : softEdge,
        bottomLeft: softEdge,
        bottomRight: softEdge);
    BorderRadius shape2 = BorderRadius.horizontal(
        left:
            widget.message.sent(provider.currentUser!.id) ? softEdge : hardEdge,
        right: widget.message.sent(provider.currentUser!.id)
            ? hardEdge
            : softEdge);
    late BorderRadius shape;
    switch (widget.shapeType) {
      case 0:
        shape = shape0;
        break;
      case 1:
        shape = shape1;
        break;
      case 2:
        shape = shape2;
        break;
    }

    double width = 0;
    if (widget.message.messageType == 'text') {
      width = (TextPainter(
              text: TextSpan(
                  text: widget.message.content,
                  style: TextStyle(
                    color: widget.message.sent(provider.currentUser!.id)
                        ? Colors.white
                        : Design.mainColor,
                    fontSize: 12.0,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  )),
              textDirection: TextDirection.ltr)
            ..layout(
                maxWidth: (provider.screenSize.width - 96.0) * (4 / 5) - 36,
                minWidth: 0))
          .size
          .width;
    }
    if (widget.message.messageType == 'audio' ||
        widget.message.messageType == 'image') {
      width = (provider.screenSize.width - 96.0) * (4 / 5) - 36;
    }

    return Padding(
      padding: widget.padding,
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            curve: showDeleteOption ? Curves.easeOutBack : Curves.easeOutQuad,
            right: widget.message.sent(provider.currentUser!.id)
                ? showDeleteOption
                    ? width + 36.0 + 12.0
                    : width
                : null,
            left: widget.message.sent(provider.currentUser!.id)
                ? null
                : showDeleteOption
                    ? width + 36.0 + 12.0
                    : width,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: () async {
                DateTime removedDate = widget.message.date;
                DateTime previousDate = widget.chatRoom.messages.elementAtOrNull(widget.chatRoom.messages.length - 2)?.date ?? DateTime.now();
                await FirebaseDatabase.instance
                    .ref(
                        'messages/${widget.chatRoom.id}/${removedDate.microsecondsSinceEpoch}')
                    .remove();
                  await FirebaseDatabase.instance
                      .ref(
                          'users/${provider.currentUser!.id}/chat_rooms/${removedDate.microsecondsSinceEpoch}')
                      .remove();
                  await FirebaseDatabase.instance
                      .ref(
                          'users/${provider.currentUser!.id}/chat_rooms/${previousDate.microsecondsSinceEpoch}')
                      .set({'chat_room_id': widget.chatRoom.id});

                  await FirebaseDatabase.instance
                      .ref(
                          'users/${widget.chatRoom.secondUser?.id}/chat_rooms/${removedDate.microsecondsSinceEpoch}')
                      .remove();
                  await FirebaseDatabase.instance
                      .ref(
                          'users/${widget.chatRoom.secondUser?.id}/chat_rooms/${previousDate.microsecondsSinceEpoch}')
                      .set({'chat_room_id': widget.chatRoom.id});

                if (widget.chatRoom.secondUser!.messagingToken.isNotEmpty) {
                  ServerHelper.sendNotification(MessageNotification(
                      getId(provider.currentUser!.id),
                      provider.currentUser!.id,
                      widget.chatRoom.id,
                      widget.chatRoom.secondUser!.messagingToken));
                }
              },
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 400),
                curve:
                    showDeleteOption ? Curves.easeOutBack : Curves.easeOutQuad,
                opacity: showDeleteOption ? 1.0 : 0.0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: showDeleteOption
                      ? Curves.easeOutBack
                      : Curves.easeOutQuad,
                  width: provider.screenSize.width * .1,
                  height: provider.screenSize.width * .1,
                  margin: EdgeInsets.only(
                      bottom: (widget.message.liked
                              ? provider.screenSize.width * .0125
                              : 0) +
                          (widget.withDate ? 12.0 : 0.0)),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [Design.shadow3]),
                  child: Transform.scale(
                    scale: .7,
                    child: Image.asset(
                      'images/delete.png',
                      color: Design.mainColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              if (widget.message.sent(provider.currentUser!.id))
                const Spacer(
                  flex: 1,
                ),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment:
                      widget.message.userId == provider.currentUser!.id
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onDoubleTap: () {
                        if (!widget.message.sent(provider.currentUser!.id)) {
                          setState(() {
                            widget.message.liked = !widget.message.liked;
                          });
                          FirebaseDatabase.instance
                              .ref(
                                  'messages/${widget.chatRoom.id}/${widget.message.date.microsecondsSinceEpoch}/liked')
                              .set(widget.message.liked);
                        }
                      },
                      onTap: () {
                        setState(() {
                          if (showDeleteOption) {
                            showDeleteOption = false;
                          } else {
                            forceDate = !forceDate;
                          }
                        });
                      },
                      onLongPressStart: (details) {
                        if (widget.message.sent(provider.currentUser!.id)) {
                          setState(() {
                            showDeleteOption = !showDeleteOption;
                          });
                        }
                      },
                      child: AnimatedPadding(
                        padding: EdgeInsets.only(
                            bottom: widget.message.liked
                                ? provider.screenSize.width * .025
                                : 0.0),
                        curve: widget.message.liked
                            ? Curves.easeOutBack
                            : Curves.easeOutQuad,
                        duration: const Duration(milliseconds: 400),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            AnimatedContainer(
                                duration: const Duration(milliseconds: 400),
                                clipBehavior: Clip.antiAlias,
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: shape,
                                    gradient: widget.message
                                            .sent(provider.currentUser!.id)
                                        ? Design.mainGradient
                                        : null,
                                    boxShadow: [Design.shadow3]),
                                padding: const EdgeInsets.all(18.0),
                                child: widget.message.messageType == 'text'
                                    ? RichText(
                                        text: _buildText(
                                          widget.message.content,
                                          TextStyle(
                                              color: widget.message.sent(
                                                      provider.currentUser!.id)
                                                  ? Colors.white
                                                  : Design.mainColor,
                                              // fontSize: 12.0,
                                              // fontFamily: 'Inter',
                                              fontWeight: FontWeight.w600),
                                        ),
                                      )
                                    // Text(
                                    //         widget.message.content,
                                    //         style: TextStyle(
                                    //             color: widget.message.sent(
                                    //                     provider.currentUser!.id)
                                    //                 ? Colors.white
                                    //                 : Design.mainColor,
                                    //             fontSize: 12.0,
                                    //             fontFamily: 'Inter',
                                    //             fontWeight: FontWeight.w600),
                                    //       )
                                    : widget.message.messageType == 'image'
                                        ? imageWidget(context, shape)
                                        : AudioMessageWidget(
                                            message: widget.message,
                                            chatRoomId: widget.chatRoom.id,
                                          )),
                            Positioned(
                              left:
                                  widget.message.sent(provider.currentUser!.id)
                                      ? null
                                      : width,
                              right:
                                  widget.message.sent(provider.currentUser!.id)
                                      ? width
                                      : null,
                              bottom: -provider.screenSize.width * .025,
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 400),
                                curve: widget.message.liked
                                    ? Curves.easeOutBack
                                    : Curves.easeOutQuad,
                                opacity: widget.message.liked ? 1.0 : 0.0,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 400),
                                  width: provider.screenSize.width *
                                      .05 *
                                      (widget.message.liked ? 1.0 : 0.0),
                                  height: provider.screenSize.width *
                                      .05 *
                                      (widget.message.liked ? 1.0 : 0.0),
                                  curve: widget.message.liked
                                      ? Curves.easeOutBack
                                      : Curves.easeOutQuad,
                                  decoration: BoxDecoration(
                                      color: widget.message
                                              .sent(provider.currentUser!.id)
                                          ? Colors.white
                                          : Design.mainColor,
                                      boxShadow: [Design.shadow3],
                                      shape: BoxShape.circle),
                                  child: Transform.scale(
                                    scale: .75,
                                    child: Image.asset(
                                      'images/heart.png',
                                      color: widget.message
                                              .sent(provider.currentUser!.id)
                                          ? Design.mainColor
                                          : Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    AnimatedPadding(
                      duration: const Duration(milliseconds: 400),
                      curve: widget.withDate || forceDate
                          ? Curves.easeOutBack
                          : Curves.easeOutQuad,
                      padding: EdgeInsets.symmetric(
                        vertical: widget.withDate || forceDate ? 4.0 : 0.0,
                      ),
                      child: Row(
                        mainAxisAlignment:
                            widget.message.sent(provider.currentUser!.id)
                                ? MainAxisAlignment.end
                                : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          AnimatedSize(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOutBack,
                            child: IconSwitcher(
                              icon: (widget.lastMessage &&
                                          widget.message.sent(
                                              provider.currentUser!.id)) ||
                                      forceDate
                                  ? (widget.message.pending
                                      ? LoadingWidget(
                                          key: const ValueKey('pending'),
                                          size: 4.0,
                                          color:
                                              Design.mainColor.withOpacity(.5),
                                          number: 2,
                                        )
                                      : Image.asset(
                                          widget.message.seen &&
                                                  widget.lastMessage
                                              ? 'images/eye_shown.png'
                                              : widget.message.failed
                                                  ? 'images/error.png'
                                                  : 'images/sent.png',
                                          key: ValueKey(widget.message.seen &&
                                                  widget.lastMessage
                                              ? 'seen'
                                              : widget.message.failed
                                                  ? 'failed'
                                                  : 'sent'),
                                          color:
                                              Design.mainColor.withOpacity(.5),
                                          height: 20.0,
                                          width: 20.0,
                                        ))
                                  : const SizedBox(),
                            ),
                          ),
                          Container(
                            width: (widget.lastMessage &&
                                        widget.message
                                            .sent(provider.currentUser!.id)) ||
                                    forceDate
                                ? 3.0
                                : 0.0,
                            height: (widget.lastMessage &&
                                        widget.message
                                            .sent(provider.currentUser!.id)) ||
                                    forceDate
                                ? 3.0
                                : 0.0,
                            margin: EdgeInsets.symmetric(
                                horizontal: (widget.lastMessage &&
                                            widget.message.sent(
                                                provider.currentUser!.id)) ||
                                        forceDate
                                    ? 4.0
                                    : 0.0),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Design.mainColor.withOpacity(.5),
                            ),
                          ),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 400),
                            curve: widget.withDate || forceDate
                                ? Curves.easeOutBack
                                : Curves.easeOutQuad,
                            style: TextStyle(
                                color: Design.mainColor.withOpacity(.5),
                                fontSize:
                                    widget.withDate || forceDate ? 10.0 : 0.0,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600),
                            child: Text(
                              convertDate(widget.message.date),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              if (!widget.message.sent(provider.currentUser!.id))
                const Spacer(
                  flex: 1,
                )
            ],
          ),
        ],
      ),
    );
  }

  TextSpan _buildText(String text, TextStyle style) {
    final children = <TextSpan>[];
    final runes = text.runes;

    for (int i = 0; i < runes.length; /* empty */) {
      int current = runes.elementAt(i);

      // we assume that everything that is not
      // in Extended-ASCII set is an emoji...
      final isEmoji = current > 255;
      final shouldBreak = isEmoji ? (x) => x <= 255 : (x) => x > 255;

      final chunk = <int>[];
      while (!shouldBreak(current)) {
        chunk.add(current);
        if (++i >= runes.length) break;
        current = runes.elementAt(i);
      }

      children.add(
        TextSpan(
          text: String.fromCharCodes(chunk),
          style: style.copyWith(
            fontSize: isEmoji ? 16.0 : 12.0,
            fontFamily:
            // isEmoji ?
            // 'NotoColorEmoji' :
            'Inter',
          ),
        ),
      );
    }

    return TextSpan(children: children);
  }

  Widget imageWidget(context, shape) {
    Widget? hero;

    return FutureBuilder(
      future: FirebaseStorage.instance
          .ref('chatroom_${widget.chatRoom.id}/${widget.message.content}')
          .getDownloadURL(),
      builder: (context, snapshot) {
        // if(snapshot.hasData){
        //   if(snapshot.data != null) {
        //     return GestureDetector(
        //       onTap: () =>
        //           Navigator.of(context)
        //               .push(PageRouteBuilder(
        //               pageBuilder: (context,
        //                   animation,
        //                   secondaryAnimation) =>
        //                   FullViewMedia(
        //                     hero: hero!,
        //                     animation: animation,
        //                   ),
        //               opaque: false,
        //               barrierColor:
        //               Colors.transparent)),
        //       child: AnimatedSize(
        //         duration: const Duration(milliseconds: 400),
        //         curve: Curves.easeOutBack,
        //         child: CachedNetworkImage(
        //             cacheManager:
        //             ChatRoomCacheManager(
        //                 widget.chatRoom.id),
        //             cacheKey: basenameWithoutExtension(widget.message.content),
        //             imageUrl: snapshot.data!,
        //
        //             placeholder: (context, url) => loadingImageWidget(),
        //             errorWidget: (context, url, error) {
        //               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        //                 content: Text(
        //                   'Couldn\'t load this image :(',
        //                   style: TextStyle(
        //                     color: Design.mainColor,
        //                     fontFamily: 'Inter',
        //                     fontWeight: FontWeight.w900,
        //                   ),
        //                 ),
        //                 backgroundColor: Colors.white,
        //                 behavior: SnackBarBehavior.floating,
        //               ));
        //               return  loadingImageWidget(fail: true);
        //             },
        //             imageBuilder:
        //                 (context, imageProvider) {
        //               hero = Hero(
        //                   tag:
        //                   'image_${widget.message.date}',
        //                   child: ClipRRect(
        //                       borderRadius:
        //                       BorderRadius.zero,
        //                       child: Image(
        //                         image:
        //                         imageProvider,
        //                       )));
        //               return Hero(
        //                 tag:
        //                 'image_${widget.message.date}',
        //                 child: ClipRRect(
        //                   borderRadius: shape,
        //                   child: Image(
        //                     image: imageProvider,
        //                   ),
        //                 ),
        //               );
        //             }),
        //       ),
        //     );
        //   }
        //   else{
        //     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        //       content: Text(
        //         'Couldn\'t load this image :(',
        //         style: TextStyle(
        //           color: Design.mainColor,
        //           fontFamily: 'Inter',
        //           fontWeight: FontWeight.w900,
        //         ),
        //       ),
        //       backgroundColor: Colors.white,
        //       behavior: SnackBarBehavior.floating,
        //     ));
        //     return  loadingImageWidget(fail: true);
        //   }
        // }
        // return loadingImageWidget();

        print(snapshot.data);
        return GestureDetector(
            key: ValueKey(snapshot.data),
          onTap: () {
            if (hero != null) {
              Navigator.of(context).push(PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      FullViewMedia(
                        hero: hero!,
                        animation: animation,
                      ),
                  opaque: false,
                  barrierColor: Colors.transparent));
            }
          },
          child: AnimatedSize(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutBack,
            child: CachedNetworkImage(
              cacheManager: ChatRoomCacheManager(widget.chatRoom.id),
              cacheKey: path.basenameWithoutExtension(widget.message.content),
              imageUrl: snapshot.data ?? '',
              placeholder: (context, url) => loadingImageWidget(),
              errorWidget: (context, url, error) => loadingImageWidget(),
              imageBuilder: (context, imageProvider) {
                hero = Hero(
                    tag: 'image_${widget.message.date}',
                    child: ClipRRect(
                        borderRadius: BorderRadius.zero,
                        child: Image(
                          image: imageProvider,
                        )));
                return Hero(
                  tag: 'image_${widget.message.date}',
                  child: ClipRRect(
                    borderRadius: shape,
                    child: Image(
                      image: imageProvider,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget loadingImageWidget({bool fail = false}) => Padding(
        padding: const EdgeInsets.all(12.0),
        child: Image.asset(
          fail ? 'images/error.png' : 'images/image.png',
          width: provider.screenSize.width * .3,
          height: provider.screenSize.width * .3,
          color: widget.message.sent(provider.currentUser!.id)
              ? Colors.white
              : Design.mainColor,
        ),
      );

  String convertDate(DateTime dateTime) {
    if (DateTime.now().year - dateTime.year > 0) {
      return intl.DateFormat('yyyy MMM d hh:mm a').format(dateTime);
    }
    if (DateTime.now().day - dateTime.day > 1) {
      return intl.DateFormat('MMM d hh:mm a').format(dateTime);
    }
    if (DateTime.now().day - dateTime.day == 1) {
      return 'Yesterday ${intl.DateFormat('hh:mm a').format(dateTime)}';
    }
    if (DateTime.now().day - dateTime.day == 0) {
      return intl.DateFormat('hh:mm a').format(dateTime);
    }
    return 'Didn\'t code that one';
  }
}

class AudioMessageWidget extends StatefulWidget {
  final Message message;
  final String chatRoomId;
  const AudioMessageWidget(
      {super.key, required this.message, required this.chatRoomId});

  @override
  State<AudioMessageWidget> createState() => _AudioMessageWidgetState();
}

class _AudioMessageWidgetState extends State<AudioMessageWidget> {
  final AudioPlayer controller = AudioPlayer();
  List<double> waveformData = [];

  late MainProvider provider;

  @override
  void initState() {
    super.initState();
    provider = Provider.of<MainProvider>(context, listen: false);
    initAudio();
  }

  ValueNotifier<Duration> currentDuration = ValueNotifier(Duration.zero);
  ValueNotifier<PlayerState?> playerState = ValueNotifier(null);
  Duration maxDuration = Duration.zero;

  @override
  void dispose() {
    currentDuration.dispose();
    playerState.dispose();
    super.dispose();
  }

  void initAudio() async {
    try {
      File audioFile = await ChatRoomCacheManager(widget.chatRoomId)
          .getSingleFile(widget.message.content,
              key: path.basenameWithoutExtension(widget.message.content));

      waveform.PlayerController()
          .extractWaveformData(path: audioFile.path, noOfSamples: 15)
          .then((value) {
        if (mounted) {
          setState(() {
            waveformData = value;
            playerState.value = PlayerState.stopped;
          });
        }
      });

      controller.onDurationChanged.listen((duration) {
        if (mounted) {
          setState(() {
            maxDuration = duration;
          });
        }
      });

      controller.onPositionChanged.listen((duration) {
        currentDuration.value = duration;
      });

      controller.onPlayerStateChanged.listen((PlayerState s) async {
        if (s == PlayerState.completed) {
          await controller.seek(Duration.zero);
          currentDuration.value = Duration.zero;
        }
        playerState.value = s;
      });

      await controller.setSource(DeviceFileSource(audioFile.path));

      await controller.setReleaseMode(ReleaseMode.stop);
    } catch (e) {
      playerState.value = PlayerState.disposed;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: LayoutBuilder(
                builder: (context, constraints) => Stack(
                      children: [
                        ColorFiltered(
                            colorFilter: ColorFilter.mode(
                                widget.message.sent(provider.currentUser!.id)
                                    ? Colors.white54
                                    : Design.mainColor.withOpacity(.5),
                                BlendMode.srcIn),
                            child: SickWaveform(
                              sampleNumber: 15,
                              data: waveformData,
                              size: Size(
                                constraints.maxWidth,
                                54,
                              ),
                              spacing: 2.0,
                            )),
                        ValueListenableBuilder(
                          valueListenable: currentDuration,
                          builder: (context, value, child) => AnimatedValue(
                            val: value.inMicroseconds /
                                maxDuration.inMicroseconds,
                            duration: const Duration(milliseconds: 100),
                            builder: (val) => ClipRect(
                              clipper: RectClipper(val),
                              child: ColorFiltered(
                                  colorFilter: ColorFilter.mode(
                                      widget.message
                                              .sent(provider.currentUser!.id)
                                          ? Colors.white
                                          : Design.mainColor,
                                      BlendMode.srcIn),
                                  child: SickWaveform(
                                    sampleNumber: 15,
                                    data: waveformData,
                                    size: Size(
                                      constraints.maxWidth,
                                      54,
                                    ),
                                    spacing: 2.0,
                                  )),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onPanDown: (details) => controller.pause(),
                          onPanUpdate: (details) {
                            double progress = (details.localPosition.dx /
                                    constraints.maxWidth)
                                .clamp(0, 1);
                            controller.seek(maxDuration * progress);
                          },
                          onPanEnd: (details) {
                            controller.resume();
                          },
                          onTapDown: (details) {
                            controller.pause();
                          },
                          onTapUp: (details) {
                            double progress = (details.localPosition.dx /
                                    constraints.maxWidth)
                                .clamp(0, 1);
                            controller.seek(maxDuration * progress);
                          },
                          child: Container(
                            color: Colors.transparent,
                            width: constraints.maxWidth,
                            height: 54,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ValueListenableBuilder(
                                valueListenable: currentDuration,
                                builder: (context, value, child) => Text(
                                  '${value.inMinutes < 10 ? '0' : ''}${value.inMinutes}:${value.inSeconds % 60 < 10 ? '0' : ''}${value.inSeconds % 60}',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      fontFamily: 'Inter',
                                      fontSize: 6.0,
                                      color: widget.message
                                              .sent(provider.currentUser!.id)
                                          ? Colors.white
                                          : Design.mainColor),
                                ),
                              ),
                              Text(
                                '${maxDuration.inMinutes < 10 ? '0' : ''}${maxDuration.inMinutes}:${maxDuration.inSeconds % 60 < 10 ? '0' : ''}${maxDuration.inSeconds % 60}',
                                style: TextStyle(
                                    fontWeight: FontWeight.w400,
                                    fontSize: 6.0,
                                    fontFamily: 'Inter',
                                    color: widget.message
                                            .sent(provider.currentUser!.id)
                                        ? Colors.white
                                        : Design.mainColor),
                              ),
                            ],
                          ),
                        )
                      ],
                    )),
          ),
        ),
        Expanded(
          flex: 1,
          child: ValueListenableBuilder(
            valueListenable: playerState,
            builder: (context, value, child) => GestureDetector(
              onTap: () {
                if (waveformData.isNotEmpty) {
                  if (value == PlayerState.playing) {
                    controller.pause();
                  } else {
                    if (runningAudioPlayer != null &&
                        runningAudioPlayer!.state == PlayerState.playing) {
                      runningAudioPlayer!.pause();
                    }
                    controller.resume();
                    runningAudioPlayer = controller;
                  }
                }
              },
              child: LayoutBuilder(
                builder: (context, constraints) => Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.message.sent(provider.currentUser!.id)
                        ? Colors.white
                        : Design.mainColor,
                  ),
                  clipBehavior: Clip.antiAlias,
                  alignment: Alignment.center,
                  width: constraints.maxWidth,
                  height: constraints.maxWidth,
                  child: value == null
                      ? LoadingWidget(
                          size: 6,
                          number: 3,
                          color: widget.message.sent(provider.currentUser!.id)
                              ? Design.mainColor
                              : Colors.white,
                        )
                      : Transform.scale(
                          scale: 0.4,
                          child: IconSwitcher(
                            icon: value == PlayerState.disposed
                                ? Image.asset(
                                    'images/error.png',
                                    key: const ValueKey('error'),
                                    color: widget.message
                                            .sent(provider.currentUser!.id)
                                        ? Design.mainColor
                                        : Colors.white,
                                  )
                                : value == PlayerState.playing
                                    ? Image.asset(
                                        'images/pause.png',
                                        key: const ValueKey('pause'),
                                        color: widget.message
                                                .sent(provider.currentUser!.id)
                                            ? Design.mainColor
                                            : Colors.white,
                                      )
                                    : Image.asset(
                                        'images/play.png',
                                        key: const ValueKey('play'),
                                        color: widget.message
                                                .sent(provider.currentUser!.id)
                                            ? Design.mainColor
                                            : Colors.white,
                                      ),
                          )),
                ),
              ),
            ),
          ),
        )
      ],
    );
  }
}

class RectClipper extends CustomClipper<Rect> {
  double percentage;

  RectClipper(this.percentage);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(0, 0, percentage * size.width, size.height);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) => true;
}

class FullViewMedia extends StatelessWidget {
  final Widget hero;
  final Animation<double> animation;
  const FullViewMedia({super.key, required this.hero, required this.animation});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
        child: Stack(
          children: [
            FadeTransition(
              opacity: animation,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  color: Colors.white24,
                ),
              ),
            ),
            Center(child: hero),
          ],
        ),
      ),
    );
  }
}

class SickWaveform extends StatefulWidget {
  final int sampleNumber;
  final List<double> data;
  final Size size;
  final double spacing;
  const SickWaveform(
      {super.key,
      required this.sampleNumber,
      required this.data,
      this.spacing = 2.0,
      required this.size});

  @override
  State<SickWaveform> createState() => _SickWaveformState();
}

class _SickWaveformState extends State<SickWaveform> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size.width,
      height: widget.size.height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(
            widget.sampleNumber,
            (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  margin: EdgeInsets.symmetric(horizontal: widget.spacing),
                  width: (widget.size.width / widget.sampleNumber) -
                      widget.spacing * 2,
                  height: (widget.data.length > index
                          ? widget.data[index] * widget.size.height * 2
                          : 0) +
                      (widget.size.width / widget.sampleNumber) -
                      widget.spacing * 2,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        widget.size.width / widget.sampleNumber / 2,
                      ),
                      color: Colors.white),
                )),
      ),
    );
  }
}
