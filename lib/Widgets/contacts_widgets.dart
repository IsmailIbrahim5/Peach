
import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:peach/Classes/main_provider.dart';
import 'package:provider/provider.dart';

import '../Classes/chat_room.dart';
import '../Classes/design_constants.dart';
import '../Classes/user_classes.dart';
import '../Pages/chat_rooms_page.dart';
import '../main.dart';
import 'animated_list.dart';
import 'cross_fade_switcher.dart';
import 'loading_widget.dart';

class ContactsList extends StatefulWidget {
  final bool expanded;
  final Function(ChatRoom chatRoom) onClick;
  const ContactsList({super.key, required this.expanded, required this.onClick});

  @override
  State<ContactsList> createState() => _ContactsListState();
}

class _ContactsListState extends State<ContactsList> {
  late StreamSubscription<DatabaseEvent> friendsListener;
  List<StreamSubscription<DatabaseEvent>> messageListeners = [];

  List<Friend>? cacheList;

  late MainProvider provider;

  @override
  void initState() {
    super.initState();
    provider = Provider.of<MainProvider>(context , listen: false);
    initiateFriends();
  }

  @override
  void dispose() {
    friendsListener.cancel();
    for (StreamSubscription<DatabaseEvent> listener in messageListeners) {
      listener.cancel();
    }
    super.dispose();
  }


  void initiateFriends() async {
    friendsListener = FirebaseDatabase.instance
        .ref('users/${provider.currentUser!.id}/friends')
        .onValue
        .listen((event) async {
      cacheList = [];
      for(Friend f in provider.currentUser?.friends ?? []){
        cacheList?.add(f);
      }
          if(provider.currentUser!.friends == null) provider.currentUser!.friends = [];
      Map? friendsInfoData = event.snapshot.value as Map?;
      if(friendsInfoData?.isNotEmpty?? false) {
        for (Map? friendInfo in friendsInfoData?.values ?? []) {
          if (provider.currentUser?.friends
              ?.where((element) => element.id == friendInfo!['friend_id'])
              .firstOrNull == null) {
            Map? friendData =
            (await FirebaseDatabase.instance.ref(
                'users/${friendInfo!['friend_id']}').get()).value
            as Map?;
            if (friendData != null) {
              Friend friend = Friend.fromJson(
                  friendData, friendInfo['friend_id'],
                  friendInfo['friend_chat_room_id']);
              provider.currentUser?.friends?.add(friend);
            }
          }
        }
      }else{
        setState(() {});
      }

      sortAndUpdate();
    });
  }


  void sortAndUpdate(){
    if(mounted) {
      provider.currentUser?.friends?.sort(
              (a, b) =>
              a.name.toLowerCase().trim().compareTo(b.name.toLowerCase().trim())
      );
      bool worthUpdating = false;
      for(int i = 0 ; i < (provider.currentUser?.friends?.length  ?? 0); i++){
        if(provider.currentUser!.friends?.elementAtOrNull(i)?.id != cacheList?.elementAtOrNull(i)?.id){
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
    return CrossFadeSwitcher(
      next: true,
      factor: .25,
      direction: Axis.vertical,
      child: provider.currentUser!.friends == null
          ? Center(key: UniqueKey() , child: const LoadingWidget())
          :provider.currentUser!.friends!.isEmpty ? const Center(
        child: Text(
          'You don\'t have any friends\nPress the add button to add friends',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontFamily: 'Inter',
              color: Colors.white,
              fontWeight: FontWeight.bold
          ),
        ),
      ): AnimatedPadding(
        duration: const Duration(milliseconds: 2000),
        curve: Curves.elasticOut,
        padding:  EdgeInsets.only(top: (provider.screenSize.height * 0.07) + ((provider.screenSize.width * (widget.expanded ? 7 : 2.5) / 10) * .75 + 30.0) ),
        child: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.white,
                  Colors.white,
                  Colors.transparent,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.2, 0.9, 1.0]).createShader(bounds),
          blendMode: BlendMode.dstIn,
          child: AnimatedListBgd(
            key: const ValueKey('contacts_list'),
              childrenHeight: provider.screenSize.height * .14+ 24,
            startingDelay: const Duration(milliseconds: 600),
              padding:  EdgeInsets.only(top:  ((provider.screenSize.width * (widget.expanded ? 7 : 2.5) / 10 ) * .25+ 10.0) + 32 , bottom:  provider.screenSize.height * 0.085 + 32.0 + 8.0),
              children: List.generate(
                  provider.currentUser!.friends!.length,
                      (index) => AnimatedListItem(
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: GestureDetector(
                            onTap: () async{
                              ChatRoom? chatRoom = provider.currentUser?.chatRooms?.where((element) => element.id ==provider.currentUser!.friends![index].chatRoomId).firstOrNull;
                              if(chatRoom == null) {
                                Map? chatRoomData = (await FirebaseDatabase.instance.ref(
                                'chat_rooms/${provider.currentUser!.friends![index].chatRoomId}').get()).value as Map?;
                              chatRoom = ChatRoom(provider.currentUser!.friends![index].chatRoomId,
                              chatRoomData!['user_ids'].keys.toList().cast<String>(),
                              chatRoomData['typing'][provider.currentUser!.id]);
                              chatRoom.secondUser = provider.currentUser!.friends![index];
                              }
                              widget.onClick(chatRoom);
                            },
                            child: FriendWidget(friend: provider.currentUser!.friends![index], childHeight: provider.screenSize.height * .14,)),
                      ),
                      ValueKey(provider.currentUser!.friends![index].id))),
            ),
        ),
      ),
    );
  }
}

class FriendWidget extends StatelessWidget {
  final Friend friend;
  final double childHeight;
  const FriendWidget({super.key, required this.friend, required this.childHeight});

  @override
  Widget build(BuildContext context) {
    return  Container(
        alignment: Alignment.center,
        height: childHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:  BorderRadius.circular(32.0),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            BackgroundPainter(count: 6, size: 24 , color: Design.mainColor.withOpacity(.5),),

            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: CachedNetworkImage(
                      imageUrl: friend.pfpLink.isEmpty ? '' : friend.pfpLink,
                      placeholder: (context, url) => leadingWidget(),
                      errorWidget: (context, url, error) =>leadingWidget(),
                      imageBuilder: (context, imageProvider) => Container(
                        clipBehavior: Clip.antiAlias,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        child: Image(
                          image: imageProvider,
                          fit: BoxFit.cover,
                        )
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 24 , bottom: 24 , right: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(friend.name,   style: const TextStyle(
                                color: Design.mainColor,
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Inter'),),
                          ),
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              friend.status,
                              style: TextStyle(
                                color: Design.mainColor.withOpacity(.75),
                                fontSize: 12.0,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // TODO: Add remove friend button
                    // GestureDetector(
                    //   onTap: () {
                    //     FirebaseDatabase.instance.ref('users/$userId/friends/${widget.friend.id}').remove();
                    //     FirebaseDatabase.instance.ref('users/${widget.friend.id}/friends/$userId').remove();
                    //   },
                    //   child: Container(
                    //     height: screenSize.height * (12/15) / 5 * .45,
                    //     width: screenSize.height * (12/15) / 5 * .45,
                    //
                    //     decoration: const BoxDecoration(
                    //         shape: BoxShape.circle,
                    //         color: Design.mainColor
                    //     ),
                    //     child:  Transform.scale(
                    //       scale: .7,
                    //       child: Image.asset(
                    //         'images/remove_person.png',
                    //         color: Colors.white,
                    //       ),
                    //     )
                    //   ),
                    // ),

                  ),
                ),
              ],
            ),
          ],
        ));

  }

  Widget leadingWidget() =>Container(
    decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(width: 1.0 , color: Design.mainColor),
      shape: BoxShape.circle,
    ),
    child: FittedBox(
      fit: BoxFit.fitWidth,
      child: Transform.scale(
        scale: 0.3,
        child: Text(
          friend.name[0],
          style:const TextStyle(
              color: Design.mainColor,
              fontSize: 100.0,

              fontWeight: FontWeight.w900
          ),
        ),
      ),
    ),
  );
}


