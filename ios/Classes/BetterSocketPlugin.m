#import "BetterSocketPlugin.h"
#import <SRWebSocket.h>


@interface BetterSocketPlugin()<SRWebSocketDelegate,FlutterStreamHandler>
@property (nonatomic,strong) SRWebSocket *webSocket;
@property(nonatomic,strong)FlutterEventSink eventSink;

@end

@implementation BetterSocketPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    
    int count = 20;
    for (int i = 0; i<count; i++) {
        FlutterMethodChannel* channel = [FlutterMethodChannel
                                         methodChannelWithName:[NSString stringWithFormat:@"better_socket%d",i]
                                         binaryMessenger:[registrar messenger]];
        BetterSocketPlugin* instance = [[BetterSocketPlugin alloc] init];
        [registrar addMethodCallDelegate:instance channel:channel];
        
        FlutterEventChannel* eventChannel = [FlutterEventChannel eventChannelWithName:[NSString stringWithFormat:@"better_socket/event%d",i] binaryMessenger:[registrar messenger]];
        [eventChannel setStreamHandler:instance];
    }
}


- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"getPlatformVersion" isEqualToString:call.method]) {
        result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
    } else if ([@"connentSocket" isEqualToString:call.method]) {
        NSDictionary *dict = call.arguments;
        self.webSocket.delegate = nil;
        [self.webSocket close];
        //        NSDictionary *hedaer = dict[@"httpHeaders"];
        self.webSocket = [[SRWebSocket alloc] initWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:dict[@"path"]]]];
        self.webSocket.delegate = self;
        [self.webSocket open];
        result(nil);
    } else if ([@"sendMsg" isEqualToString:call.method]){
        NSDictionary *dict = call.arguments;
        [self.webSocket send:dict[@"msg"]];
        result(nil);
    } else if ([@"sendByteMsg" isEqualToString:call.method]){
        NSDictionary *dict = call.arguments;
        NSData *data = [NSData dataWithData:[dict[@"msg"] data]];
        [self.webSocket send:data];
        result(nil);
    }
    else if ([@"close" isEqualToString:call.method]) {
        [self.webSocket close];
        result(nil);
    }
    else {
        result(FlutterMethodNotImplemented);
    }
}


- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
    NSMutableDictionary *eventResult = [[NSMutableDictionary alloc] init];
    eventResult[@"event"] = @"onMessage";
    eventResult[@"message"] = message;
    self.eventSink(eventResult);
    // NSLog(@"message –> %@", message);
}

- (void)webSocketDidOpen:(SRWebSocket *)webSocket {
    // NSLog(@"Websocket Connected");
    NSMutableDictionary *eventResult = [[NSMutableDictionary alloc] init];
    eventResult[@"event"] = @"onOpen";
    eventResult[@"code"] = @(webSocket.readyState);
    eventResult[@"httpStatus"] = @"200";
    eventResult[@"httpStatusMessage"] = @"成功";
    self.eventSink(eventResult);
}

//连接失败
-(void)webSocket:(SRWebSocket* )webSocket didFailWithError:(NSError* )error {
    // NSLog(@"error --> %@", error);
    NSMutableDictionary *eventResult = [[NSMutableDictionary alloc] init];
    eventResult[@"event"] = @"onError";
    eventResult[@"message"] = [NSString stringWithFormat:@"%@",error];
    self.eventSink(eventResult);
    self.webSocket = nil;
}

// 连接关闭
- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    // NSLog(@"Closed Reason:%@",reason);
    NSMutableDictionary *eventResult = [[NSMutableDictionary alloc] init];
    eventResult[@"event"] = @"onClose";
    eventResult[@"code"] = @(code);
    eventResult[@"reason"] = reason;
    eventResult[@"remote"] = @(wasClean);
    self.eventSink(eventResult);
    self.webSocket = nil;
}

- (void)webSocket:(SRWebSocket *)webSocket didReceivePong:(NSData *)pongPayload {
    NSString *reply = [[NSString alloc] initWithData:pongPayload encoding:NSUTF8StringEncoding];
    NSLog(@"%@",reply);
}


#pragma mark ============FlutterStreamHandler 代理=================
- (FlutterError* _Nullable)onListenWithArguments:(id _Nullable)arguments
                                       eventSink:(FlutterEventSink)eventSink{
    self.eventSink = eventSink;
    return nil;
}

- (FlutterError* _Nullable)onCancelWithArguments:(id _Nullable)arguments {
    return nil;
}
@end

