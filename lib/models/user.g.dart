// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User()
  ..username = json['username'] as String
  ..nickname = json['nickname'] as String?
  ..email = json['email'] as String?
  ..token = json['token'] as String?;

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'username': instance.username,
      'nickname': instance.nickname,
      'email': instance.email,
      'token': instance.token,
    };
