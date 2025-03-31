//
//  STSocketTool.h
//  SpeechText_Example
//
//  Created by xiaojiuwo on 2025/3/31.
//  Copyright © 2025 xiaojiuwo. All rights reserved.
//

#import <Foundation/Foundation.h>


#import <SRWebSocket.h>

@class STSocketTool;
@protocol STSocketToolDelegate <NSObject>

@optional

/**
  * 音频上传结束后返回文本内容  text 内容 end是否转义结束
 */
- (void)socketToolreceiveMessageWithClass:(STSocketTool *)classSuper WithText:(NSString *)text WithEnd:(BOOL)end;

// 长连接是否成功 1成功 0 失败
- (void)socketToolreceiveMessageWithClass:(STSocketTool *)classSuper WithJoin:(BOOL)join;

// 长连接被服务端断开
- (void)socketToolDisconnectWithClass:(STSocketTool *)classSuper didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean;

// 超过重连次数未连接成功
- (void)socketToolConnectionFailureWithClass:(STSocketTool *)classSuper;

@end

@interface STSocketTool : NSObject

@property (nonatomic, strong) SRWebSocket *webSocket;

+ (instancetype)sharedSocketManager;//单例

/**
  请求地址
 */
@property (nonatomic, strong) NSString *url;
/**
  token
 */
@property (nonatomic, strong) NSString *token;
/**
  会话id，可不传，V3.1必传
 */
@property (nonatomic, strong) NSString *session_id;
/**
 音频采样率，需要与实际音频采样率一致,默认16000
 */
@property (nonatomic, assign) NSInteger samp_freq;
/**
 连接掉线重连次数，默认2次
 */
@property (nonatomic, assign) NSInteger joinNum;
/**
 场景有⼏个说话⼈。默认1人
 */
@property (nonatomic, assign) NSInteger spk_num;


/** 直接上传音频路径 */
- (void)sendRecordedFileToServer:(NSString *)filePath;

- (void)connectInitiativeServer;//建立长连接
- (void)SRWebSocketClose;//关闭长连接

/** 发送音频 */
- (void)sendRecordedDataToServer:(NSData *)data;


@property (nonatomic, weak) id<STSocketToolDelegate>delegate;


@end


