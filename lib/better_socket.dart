import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';

class BetterSocket {
  final String channelID;
  final MethodChannel channel;
  BetterSocket(this.channelID, this.channel);
  BetterSocket initSocket(String id){
    MethodChannel _channel =  MethodChannel('better_socket' + id);
    BetterSocket socket = BetterSocket(id, _channel);
 
    return socket;
  }
  

  Future<String> get platformVersion async {
    final String version = await channel.invokeMethod('getPlatformVersion');
    return version;
  }

  connentSocket(String path, {Map<String, String> httpHeaders}) {
    channel.invokeMethod(
        'connentSocket', {'path': path, "httpHeaders": httpHeaders});
  }

  sendMsg(String msg) {
    channel.invokeMethod('sendMsg', <String, String>{'msg': msg});
  }

  sendByteMsg(Uint8List msg) {
    channel.invokeMethod('sendByteMsg', <String, Uint8List>{'msg': msg});
  }

  close() {
    channel.invokeMethod('close');
  }

  void addListener(
      {Function onOpen,
      Function onMessage,
      Function onError,
      Function onClose}) {
    EventChannel eventChannel = EventChannel("better_socket0/event");
    eventChannel.receiveBroadcastStream().listen((data) {
      print(data);
      var event = data["event"];
      if ("onOpen" == event) {
        if (onOpen != null) {
          var httpStatus = data["httpStatus"];
          var httpStatusMessage = data["httpStatusMessage"];
          onOpen(httpStatus, httpStatusMessage);
        }
      } else if ("onClose" == event) {
        if (onClose != null) {
          var code = data["code"];
          var reason = data["reason"];
          var remote = data["remote"];
          onClose(code, reason, remote);
        }
      } else if ("onMessage" == event) {
        if (onMessage != null) {
          var message = data["message"];
          onMessage(message);
        }
      } else if ("onError" == event) {
        if (onError != null) {
          var message = data["message"];
          onError(message);
        }
      }
    });
  }
}
