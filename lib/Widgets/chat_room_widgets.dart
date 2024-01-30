import 'dart:async';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:peach/Classes/main_provider.dart';
import 'package:peach/Pages/chat_rooms_page.dart';
import 'package:peach/Widgets/animated_value.dart';
import 'package:provider/provider.dart';

import '../Classes/chat_room.dart';
import '../Classes/design_constants.dart';
import '../Classes/message.dart';
import '../Classes/user_classes.dart';
import 'animated_list.dart';
import 'cross_fade_switcher.dart';
import 'loading_widget.dart';
import 'typing_widgets.dart';

class ChatRoomsList extends StatefulWidget {
  final Function(ChatRoom chatRoom) onClick;
  const ChatRoomsList({super.key, required this.onClick});

  @override
  State<ChatRoomsList> createState() => _ChatRoomsListState();
}

class _ChatRoomsListState extends State<ChatRoomsList> {
  StreamSubscription<DatabaseEvent>? chatRoomListener;
  List<StreamSubscription<DatabaseEvent>> messageListeners = [];

  ScrollController chatRoomsScrollController = ScrollController();

  List<ChatRoom>? cacheList;

  late MainProvider provider;

  @override
  void initState() {
    super.initState();

    provider = Provider.of<MainProvider>(context , listen: false);
    initiateChatRooms();

    chatRoomsScrollController.addListener(() {
      if (chatRoomsScrollController.position.pixels >=
          chatRoomsScrollController.position.maxScrollExtent - 10) {
        initiateChatRooms(limit: provider.currentUser!.chatRooms!.length + 10);
      }
    });
  }

  @override
  void dispose() {
    chatRoomListener?.cancel();
    for (StreamSubscription<DatabaseEvent> listener in messageListeners) {
      listener.cancel();
    }
    super.dispose();
  }

  Future<void> addChatRoom(Map? chatRoomInfoData, String date) async {
    final chatRoomId = chatRoomInfoData!['chat_room_id'];

    ChatRoom? chatRoom = provider.currentUser!.chatRooms
        ?.where((element) => element.id == chatRoomId)
        .firstOrNull;
    DateTime lastMessageDate =
        DateTime.fromMicrosecondsSinceEpoch(int.parse(date));
    if (chatRoom != null) {
      if (chatRoom.lastMessageDate != lastMessageDate) {
        FirebaseDatabase.instance.ref('users/${provider.currentUser!.id}/chat_rooms/${chatRoom.lastMessageDate?.microsecondsSinceEpoch}').remove();
        chatRoom.lastMessageDate = lastMessageDate;
      }
      return;
    }
    Map<Object?, Object?>? chatRoomData =
        (await FirebaseDatabase.instance.ref('chat_rooms/$chatRoomId').get())
            .value as Map<Object?, Object?>?;

    if (chatRoomData != null) {
      List<String> userIds =
          (chatRoomData['user_ids'] as Map?)?.keys.cast<String>().toList() ??
              [];

      String secondUserId = userIds.firstWhere((element) => element != provider.currentUser!.id);

      Map<dynamic, dynamic>? typing = chatRoomData['typing'] as Map?;
      chatRoom = ChatRoom(chatRoomInfoData['chat_room_id'], userIds,
          typing?[secondUserId] as bool,
          lastMessageDate:
              DateTime.fromMicrosecondsSinceEpoch(int.parse(date)));

      Map<dynamic, dynamic> userMap = (await FirebaseDatabase.instance
              .ref()
              .child('users/$secondUserId')
              .get())
          .value as Map<dynamic, dynamic>;

      User secondUser = User.fromJson(userMap, secondUserId);

      chatRoom.secondUser = secondUser;

      if (provider.currentUser!.chatRooms
              ?.where((element) => chatRoom?.id == element.id)
              .firstOrNull ==
          null) {
        provider.currentUser!.chatRooms?.add(chatRoom);
      }
    }
  }

  void initiateChatRooms({int limit = 10}) async {
    if (chatRoomListener != null) chatRoomListener?.cancel();
    chatRoomListener = FirebaseDatabase.instance
        .ref('users/${provider.currentUser!.id}/chat_rooms')
        .limitToLast(limit)
        .onValue
        .listen((event) async {
      cacheList = [];
      for(ChatRoom c in provider.currentUser?.chatRooms ?? []){
        cacheList?.add(c);
      }

      if (provider.currentUser!.chatRooms == null) provider.currentUser!.chatRooms = [];
      if (event.snapshot.children.isNotEmpty) {
        for (var element in event.snapshot.children) {
          await addChatRoom(element.value as Map?, element.key!);
        }
        sortAndUpdate();
      } else {
        setState(() {});
      }
    });
  }

  void sortAndUpdate() {
    if (mounted) {
      provider.currentUser?.chatRooms?.sort(
              (a, b) =>
              b.lastMessageDate!.difference(a.lastMessageDate!).inMilliseconds,
      );
      bool worthUpdating = false;
      for(int i = 0 ; i < (provider.currentUser?.chatRooms?.length  ?? 0); i++){
        if(provider.currentUser!.chatRooms?.elementAtOrNull(i)?.id != cacheList?.elementAtOrNull(i)?.id){
          worthUpdating =true;
          break;
        }
      }
      if(worthUpdating) {
        setState(() {});
      }

    }
  }

  @override
  Widget build(BuildContext context) {
    // currentUser?.chatRooms = List.generate(20, (index) => ChatRoom('chatRoom_$index', [userId , 'lksamca123amxc'], false)..secondUser = User('Ellen Martin$index', 'lksamca123amxc', '', '', false, '', UserSettings(true, true , true)));
    return CrossFadeSwitcher(
      next: true,
      direction: Axis.vertical,
      factor: .25,
      child: provider.currentUser?.chatRooms == null
          ? Center(
              key: UniqueKey(),
              child: const LoadingWidget(),
            )
          : provider.currentUser!.chatRooms!.isEmpty
              ? const Center(
                  child: Text(
                    'You don\'t have any active conversations\nPress the add button to start new conversation',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: 'Inter',
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                )
              : ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.white,
                        Colors.white,
                        Colors.transparent,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.0, 0.1, 0.9, 1.0]).createShader(bounds),
                  blendMode: BlendMode.dstIn,
                  child: AnimatedListBgd(
                    key: const ValueKey('chat_rooms_list'),
                    childrenHeight:  (provider.screenSize.height * .15) + 24.0,
                    scrollController: chatRoomsScrollController,
                    startingDelay: const Duration(milliseconds: 450),
                    padding: EdgeInsets.only(
                        bottom: provider.screenSize.height * 0.085 + 32.0 + 8.0,
                        top: provider.screenSize.height * .07 + 24.0),
                    children: List.generate(
                      provider.currentUser!.chatRooms!.length,
                      (index) => AnimatedListItem(
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          child: ChatRoomWidget(
                            chatRoom: provider.currentUser!.chatRooms![index],
                            onClick: widget.onClick,
                          ),
                        ),
                        ValueKey(provider.currentUser!.chatRooms![index].id),
                      ),
                    ),
                  ),
                ),
    );
  }
}

class ChatRoomWidget extends StatefulWidget {
  final ChatRoom chatRoom;
  final Function(ChatRoom chatRoom) onClick;
  const ChatRoomWidget(
      {required this.chatRoom, super.key, required this.onClick});

  @override
  State<ChatRoomWidget> createState() => _ChatRoomWidgetState();
}

class _ChatRoomWidgetState extends State<ChatRoomWidget> {
  List<StreamSubscription<DatabaseEvent>> messageListener = [];
  StreamSubscription<DatabaseEvent>? userListener;
  StreamSubscription<DatabaseEvent>? typingListener;
  Random random = Random();

  int unreadMessages = 0;

  @override
  void initState() {
    super.initState();
    initializeData();
  }

  @override
  void dispose() {
    for (var element in messageListener) {
      element.cancel();
    }
    userListener?.cancel();
    typingListener?.cancel();
    super.dispose();
  }


  void initializeData() async {
    userListener?.cancel();

    for (var element in messageListener) {
      element.cancel();
    }
    messageListener.clear();

    userListener = FirebaseDatabase.instance
        .ref()
        .child('users/${widget.chatRoom.secondUser!.id}/active')
        .onValue
        .listen((event) {
      setState(() {
        widget.chatRoom.secondUser!.isActive = event.snapshot.value as bool;
      });
    });

    typingListener = FirebaseDatabase.instance
        .ref(
            'chat_rooms/${widget.chatRoom.id}/typing/${widget.chatRoom.secondUser!.id}')
        .onValue
        .listen((event) {
      setState(() {
        widget.chatRoom.isTyping = event.snapshot.value as bool;
      });
    });

    messageListener.add(FirebaseDatabase.instance
        .ref('messages/${widget.chatRoom.id}')
        .limitToLast(10)
        .onValue
        .listen((event) async {
      Map? lastTenMessages = event.snapshot.value as Map?;
      if (lastTenMessages != null) {
        lastTenMessages.forEach((key, value) {
          Message m = Message.fromJson({key: value});
          if (widget.chatRoom.messages
                  .where((element) => element.date == m.date)
                  .firstOrNull ==
              null) {
            widget.chatRoom.messages.add(m);
          } else {
            widget.chatRoom.messages
                .firstWhere((element) => element.date == m.date)
                .seen = m.seen;
          }
        });
      }
      setState(() {
        unreadMessages = countUnreadMessages();
      });
    }));
    messageListener.add(FirebaseDatabase.instance
        .ref('messages/${widget.chatRoom.id}')
        .onChildRemoved
        .listen((event) async {
      Map? lastTenMessage = event.snapshot.value as Map?;
      if (lastTenMessage != null) {
        Message m = Message.fromJson({event.snapshot.key: lastTenMessage});
        widget.chatRoom.messages.removeWhere(
          (element) => element.date == m.date,
        );
      }
      setState(() {
        unreadMessages = countUnreadMessages();
      });
    }));
  }

  @override
  Widget build(BuildContext context) {
    Message? lastMessage = widget.chatRoom.messages.lastOrNull;
    return GestureDetector(
      onTap: ()=> widget.onClick.call(widget.chatRoom),
      child: AnimatedContainer(
          height: MediaQuery.sizeOf(context).height * .15,
          duration: const Duration(milliseconds: 400),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: unreadMessages == 0 ? Colors.white : Design.mainColor,
            borderRadius: BorderRadius.circular(36.0),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children:[
              AnimatedValue(
                  val: unreadMessages == 0 ?Design.mainColor:Colors.white,
                  builder: (val) => BackgroundPainter(count: 6, size: 24 , color: val.withOpacity(.5),),
                duration: const Duration(milliseconds: 400),

              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 4,
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(20.0),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.chatRoom.secondUser!.isActive
                                ? Design.activeColor
                                : unreadMessages == 0
                                ? Design.mainColor
                                : Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Design.shadow2.color.withOpacity(
                                    widget.chatRoom.secondUser!.isActive && unreadMessages == 0
                                        ? 0.5
                                        : 0.0),
                                blurRadius: widget.chatRoom.secondUser!.isActive && unreadMessages == 0
                                    ? Design.shadow2.blurRadius
                                    : 0.0,
                                offset: widget.chatRoom.secondUser!.isActive&& unreadMessages == 0
                                    ? Design.shadow2.offset
                                    : Offset.zero,
                              )
                            ]),
                        constraints: const BoxConstraints.expand(),
                        child: Container(
                          margin: const EdgeInsets.all(2.0),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: CachedNetworkImage(
                            imageUrl: widget.chatRoom.secondUser!.pfpLink.isEmpty
                                ? ''
                                : widget.chatRoom.secondUser!.pfpLink,
                            placeholder: (context, url) => Container(
                              color: Colors.white,
                              child: FittedBox(
                                fit: BoxFit.fitWidth,
                                child: Transform.scale(
                                  scale: 0.3,
                                  child: AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 400),
                                    style: TextStyle(
                                        color:
                                        widget.chatRoom.secondUser!.isActive
                                            ? Design.activeColor
                                            : Design.mainColor,
                                        fontSize: 100.0,
                                        fontWeight: FontWeight.w900),
                                    child: Text(
                                      widget.chatRoom.secondUser!.name[0],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.white,
                              child: FittedBox(
                                fit: BoxFit.fitWidth,
                                child: Transform.scale(
                                  scale: 0.3,
                                  child: AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 400),
                                    style: TextStyle(
                                        color:
                                        widget.chatRoom.secondUser!.isActive
                                            ? Design.activeColor
                                            : Design.mainColor,
                                        fontSize: 100.0,
                                        fontWeight: FontWeight.w900),
                                    child: Text(
                                      widget.chatRoom.secondUser!.name[0],
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
                  ),
                  Expanded(
                      flex: 5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 400),
                                child: FittedBox(
                                  child: AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 400),
                                    style: TextStyle(
                                        color: unreadMessages == 0
                                            ? Design.mainColor
                                            : Colors.white,
                                        fontSize: 18.0,
                                        fontWeight: unreadMessages == 0
                                            ? FontWeight.bold
                                            : FontWeight.w900,
                                        fontFamily: 'Inter'),
                                    child: Text(widget.chatRoom.secondUser!.name),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 400),
                                transitionBuilder: (child, animation) {
                                  return SlideTransition(
                                    position: animation.drive(
                                      Tween<Offset>(
                                          begin: const Offset(0.0, 1.0),
                                          end: Offset.zero)
                                          .chain(
                                        CurveTween(curve: Curves.easeOutBack),
                                      ),
                                    ),
                                    child: FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    ),
                                  );
                                },
                                child: Container(
                                  key: widget.chatRoom.isTyping
                                      ? const ValueKey('typing')
                                      : ValueKey(lastMessage?.content ?? ''),
                                  alignment: Alignment.centerLeft,
                                  child: widget.chatRoom.isTyping
                                      ? const Typing()
                                      : RichText(
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,

                                        text: _buildText(lastMessage == null
                                            ? ''
                                            : '${(lastMessage.sent(Provider.of<MainProvider>(context).currentUser!.id) ? 'Me: ' : '')}${(lastMessage.messageType == 'text' ? lastMessage.content : 'Sent an ${lastMessage.messageType}')}' , TextStyle(
                                          color: unreadMessages == 0
                                              ? Design.mainColor
                                              .withOpacity(.75)
                                              : Colors.white,
                                          // fontSize: 12.0,
                                          // fontFamily: 'Inter',
                                          fontWeight: unreadMessages == 0
                                              ? FontWeight.w400
                                              : FontWeight.bold,
                                        ),),
                                      ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                  Expanded(
                      flex: 3,
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(
                          vertical: 20.0,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            if (widget.chatRoom.messages.lastOrNull != null)
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 400),
                                transitionBuilder: (child, animation) {
                                  return SlideTransition(
                                    position: animation.drive(Tween<Offset>(
                                        begin: const Offset(0.0, 1.0),
                                        end: Offset.zero)
                                        .chain(CurveTween(
                                        curve: Curves.easeOutBack))),
                                    child: FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    ),
                                  );
                                },
                                child: AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 400),
                                  style: TextStyle(
                                      color: unreadMessages == 0
                                          ? Design.mainColor.withOpacity(.75)
                                          : Colors.white,
                                      fontSize: 12.0,
                                      fontWeight: unreadMessages == 0
                                          ? FontWeight.bold
                                          : FontWeight.w900,
                                      fontFamily: 'Inter'),
                                  child: Text(
                                    dateTimeDiff(
                                        widget.chatRoom.messages.last.date),
                                    key: ValueKey(
                                        widget.chatRoom.messages.last.date),
                                  ),
                                ),
                              ),
                            AnimatedScale(
                              duration: const Duration(milliseconds: 400),
                              curve: unreadMessages == 0
                                  ? Curves.easeOut
                                  : Curves.easeOutBack,
                              scale: unreadMessages == 0 ? 0 : 1.0,
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                alignment: Alignment.center,
                                child: AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 400),
                                  style: const TextStyle(
                                      color: Design.mainColor,
                                      fontSize: 14.0,
                                      fontWeight: FontWeight.w900,
                                      fontFamily: 'Inter'),
                                  child: Text(
                                    '${unreadMessages == 0 ? '' : unreadMessages}'
                                        .replaceAll('10', '+9'),
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      )),
                ],
              ),
            ]
          )),
    );
  }

  TextSpan _buildText(String text , TextStyle style ) {
    final children = <TextSpan>[];
    final runes = text.runes;

    for (int i = 0; i < runes.length; /* empty */ ) {
      int current = runes.elementAt(i);

      // we assume that everything that is not
      // in Extended-ASCII set is an emoji...
      final isEmoji = current > 255;
      final shouldBreak = isEmoji
          ? (x) => x <= 255
          : (x) => x > 255;

      final chunk = <int>[];
      while (! shouldBreak(current)) {
        chunk.add(current);
        if (++i >= runes.length) break;
        current = runes.elementAt(i);
      }

      children.add(
        TextSpan(
          text: String.fromCharCodes(chunk),
          style: style.copyWith(
            fontSize: isEmoji ?16.0  : 12.0,
            fontFamily:
            // isEmoji ? 'NotoColorEmoji' :
            'Inter',
          ),
        ),
      );
    }

    return TextSpan(children: children);
  }

  int countUnreadMessages() {
    if(mounted) {
      widget.chatRoom.messages
          .sort((a, b) =>
      a.date
          .difference(b.date)
          .inMilliseconds);

      return widget.chatRoom.messages.reversed
          .take(10)
          .where((element) =>
      !element.seen && element.userId != Provider
          .of<MainProvider>(context, listen: false)
          .currentUser!
          .id)
          .length;
    }
    return 0;
  }

  String dateTimeDiff(DateTime then) {
    Duration diff = DateTime.now().difference(then);
    Duration oneSecond = const Duration(seconds: 1);
    Duration oneMinute = const Duration(minutes: 1);
    Duration oneHour = const Duration(hours: 1);
    Duration oneDay = const Duration(days: 1);
    Duration oneYear = const Duration(days: 365);
    if (diff > oneYear) {
      return DateFormat.yMMMd().format(then);
    }
    if (diff > oneDay) {
      return DateFormat.MMMd().format(then);
    }
    if (diff > oneHour) {
      return '${diff.inHours} Hour${isPlural(diff, oneHour)}';
    }
    if (diff > oneMinute) {
      return '${diff.inMinutes} Min${isPlural(diff, oneMinute)}';
    }
    if (diff > oneSecond) {
      return '${diff.inSeconds} Second${isPlural(diff, oneSecond)}';
    }
    return 'Now';
  }

  String isPlural(Duration quantity, Duration m) =>
      quantity >= m * 2 ? 's' : '';
}
