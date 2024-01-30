import '../Classes/chat_room.dart';

class User{
  String name;
  final String id;
  String pfpLink;
  String status;
  String messagingToken;
  bool isActive;
  final UserSettings settings;

  User(this.name, this.id, this.pfpLink, this.messagingToken, this.isActive, this.status , this.settings);

  static User fromJson(Map<dynamic, dynamic> json , String id){
    return User(json['name'], id, json['pfpLink'],json['messagingToken'], json['active'] , json['status'] , UserSettings.fromJson(json['settings']));
  }
}

class UserSettings{
  bool activeStatus;
  bool readRecipients;
  bool notifications;

  UserSettings(this.activeStatus, this.readRecipients, this.notifications);

  static UserSettings fromJson(Map  json) => UserSettings(json['active_status'], json['read_recipients'], json['notifications_allowed']);

  Map toJson () => {
    'active_status' : activeStatus,
    'read_recipients': readRecipients,
    'notifications_allowed': notifications
  };
}

class Friend extends User{
  final String chatRoomId;

  Friend(super.name , super.id , super.pfpLink , super.messagingToken , super.isActive , super.status,super.settings,this.chatRoomId);
  static Friend fromJson(Map<dynamic, dynamic> json , String id , String chatRoomId){
    return Friend(json['name'], id, json['pfpLink'],json['messagingToken'], json['active'] , json['status'] , UserSettings.fromJson(json['settings']), chatRoomId);
  }
}

class CurrentUser extends User{
  final List? chatRoomsIds;
  List<ChatRoom>? chatRooms;
  final List? friendsIds;
  List<Friend>? friends;

  CurrentUser(super.name, super.id, super.pfpLink,super.messagingToken, super.isActive, super.status, super.settings , this.chatRoomsIds, this.friendsIds);

  static CurrentUser fromJson(Map<dynamic, dynamic> json , String id){
    return CurrentUser(json['name'], id, json['pfpLink'], json['messagingToken'],json['active'] , json['status'] , UserSettings.fromJson(json['settings']), json['chat_rooms'] == null ? [] : json['chat_rooms'].keys.toList() , json['friends'] == null ? [] : json['friends'].keys.toList());
  }


  static CurrentUser fromRawJson(Map<dynamic, dynamic> json){
    return CurrentUser(json['name'], json['id'], json['pfpLink'], json['messagingToken'], json['active'] , json['status'] , UserSettings.fromJson(json['settings']), json['chat_rooms'] , json['friends']);
  }


  Map toJson() => {
    'name': name,
    'pfpLink': pfpLink,
    'messagingToken': messagingToken,
    'active': isActive,
    'status': status,
    'settings': settings.toJson(),
    'chat_rooms': List.generate(chatRoomsIds?.length??0, (index) => {'${chatRoomsIds?[index]}' , '${chatRoomsIds?[index]}'}),
    'friends': List.generate(friendsIds?.length??0, (index) => {'${friendsIds?[index]}' , '${friendsIds?[index]}'}),
  };
}