//
//  STSocketTool.m
//  SpeechText_Example
//
//  Created by xiaojiuwo on 2025/3/31.
//  Copyright © 2025 xiaojiuwo. All rights reserved.
//

#import "STSocketTool.h"

#import "AFNetworkReachabilityManager.h"
//#import "AFNetworkReachabilityManager.h"
// 主线程异步队列
#define dispatch_main_async_safe(block)\
if ([NSThread isMainThread]) {\
block();\
} else {\
dispatch_async(dispatch_get_main_queue(), block);\
}

// 定义分块大小
static const NSUInteger kChunkSize = 6400; // 每次发送 6400 字节
static const NSTimeInterval kSendTimeout = 0.5; // 50毫秒发送一次

@interface STSocketTool() <SRWebSocketDelegate>

@property (nonatomic, strong) NSTimer *heartBeatTimer; //心跳定时器
@property (nonatomic, strong) NSTimer *netWorkTestingTimer; //没有网络的时候检测网络定时器
@property (nonatomic, strong) dispatch_queue_t queue; //数据请求队列（串行队列）
@property (nonatomic, strong) NSMutableArray *sendDataArray; //存储要发送给服务端的数据
@property (nonatomic, assign) BOOL isActivelyClose;    //用于判断是否主动关闭长连接，如果是主动断开连接，连接失败的代理中，就不用执行 重新连接方法


@property (nonatomic, assign) NSInteger reconnectAttempts; // 已尝试重连次数

/** 判断是否要重新初始化 */
@property (nonatomic, assign) BOOL isEnd;

/** 判断是否关闭长连接 */
@property (nonatomic, assign) BOOL isClose;

@property (nonatomic, strong) NSData *audioData; // 音频二进制数据
@property (nonatomic, assign) NSUInteger currentOffset; // 当前发送偏移量
@property (nonatomic, strong) NSDate *lastSendDate; // 最后一次发送数据的时间

@property (nonatomic,strong) NSTimer *timer;//录音timer

@end

@implementation STSocketTool


//单例
+ (instancetype)sharedSocketManager
{
    static STSocketTool *_instace = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken,^{
        _instace = [[self alloc] init];
    });
    return _instace;
}

- (instancetype)init
{
    self = [super init];
    if(self)
    {
        self.reconnectAttempts = 0;
        self.isEnd = YES; // 判断是否要重新初始化
        self.isClose = NO; // 判断是否关闭长连接
        self.isActivelyClose = NO;
        self.queue = dispatch_queue_create("BF",NULL);
        self.sendDataArray = [[NSMutableArray alloc] init];
        
        _url = @"";
        _token = @"";
        _session_id = @"";
        _samp_freq = 16000;
        _joinNum = 2;
        _spk_num = 1;
    }
    return self;
}

- (void)setUrl:(NSString *)url {
    _url = url;
}

- (void)setToken:(NSString *)token {
    _token = token;
}

- (void)setSession_id:(NSString *)session_id {
    _session_id = session_id;
}

- (void)setSamp_freq:(NSInteger)samp_freq {
    _samp_freq = samp_freq;
}

- (void)setJoinNum:(NSInteger)joinNum {
    _joinNum = joinNum;
}

- (void)setSpk_num:(NSInteger)spk_num {
    _spk_num = spk_num;
}


#pragma mark - NSTimer

//初始化心跳
- (void)initHeartBeat
{
    //心跳没有被关闭
    if(self.heartBeatTimer)
    {
        return;
    }
    __weak typeof (self) weakSelf = self;
    dispatch_main_async_safe(^{
        weakSelf.heartBeatTimer  = [NSTimer timerWithTimeInterval:10 target:weakSelf selector:@selector(senderheartBeat) userInfo:nil repeats:true];
        [[NSRunLoop currentRunLoop] addTimer:weakSelf.heartBeatTimer forMode:NSRunLoopCommonModes];
    });
}

//取消心跳
- (void)destoryHeartBeat
{
    __weak typeof (self) weakSelf = self;
    dispatch_main_async_safe(^{
        if (weakSelf.heartBeatTimer)
        {
            [weakSelf.heartBeatTimer invalidate];
            weakSelf.heartBeatTimer = nil;
        }
    });
}

//没有网络的时候开始定时 -- 用于网络检测
- (void)noNetWorkStartTestingTimer
{
    __weak typeof (self) weakSelf = self;
    dispatch_main_async_safe(^{
        weakSelf.netWorkTestingTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:weakSelf selector:@selector(noNetWorkStartTesting) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:weakSelf.netWorkTestingTimer forMode:NSDefaultRunLoopMode];
    });
}

//取消网络检测
- (void)destoryNetWorkStartTesting
{
    __weak typeof (self) weakSelf = self;
    dispatch_main_async_safe(^{
        if(weakSelf.netWorkTestingTimer)
        {
            [weakSelf.netWorkTestingTimer invalidate];
            weakSelf.netWorkTestingTimer = nil;
        }
    });
}

#pragma mark - private -- webSocket相关方法

//发送心跳
- (void)senderheartBeat
{
    //和服务端约定好发送什么作为心跳标识，尽可能的减小心跳包大小
    __weak typeof (self) weakSelf = self;
    dispatch_main_async_safe(^{
        if (weakSelf.webSocket.readyState == SR_OPEN)
        {
            [weakSelf.webSocket sendPing:nil error:nil];
        }
    });
}

//定时检测网络
- (void)noNetWorkStartTesting
{
    //有网络
    if(AFNetworkReachabilityManager.sharedManager.networkReachabilityStatus != AFNetworkReachabilityStatusNotReachable)
    {
        //关闭网络检测定时器
        [self destoryNetWorkStartTesting];
   
        if (self.reconnectAttempts >= _joinNum) {
            return;
        }
        //开始重连

        self.isEnd = YES;
        [self reConnectServer];
    }
}


- (void)connectInitiativeServer {
    self.reconnectAttempts = 0;
    self.isClose = NO;
    self.isEnd = YES;
    self.isActivelyClose = NO;
    [self connectServer];
}

//建立长连接
- (void)connectServer
{
    
    NSLog(@"%ld", self.webSocket.readyState);
    if (self.webSocket && self.isEnd == NO) {
        NSLog(@"不需要重新初始化");
        return;
    }
    
    self.currentOffset = 0;
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:_url]];
    
//    [request setValue:@"application/json;charset=utf-8" forHTTPHeaderField:@"Content-type"];
    [request setValue:[NSString stringWithFormat:@"Bearer %@", _token] forHTTPHeaderField:@"Authorization"];
    
//    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        self.webSocket = [[SRWebSocket alloc] initWithURLRequest:request];
        self.webSocket.delegate = self;
        [self.webSocket open];
//    });
    
    self.isEnd = NO;
}

- (void)reConnectServer {
    // 1. 如果已连接或正在连接，则不需要重连
    if (self.reconnectAttempts >= _joinNum) {
        NSLog(@"重连次数已经到了");
        if ([self.delegate respondsToSelector:@selector(socketToolConnectionFailureWithClass:)]) {
            [self.delegate socketToolConnectionFailureWithClass:self];
        }
    }
    if (self.webSocket.readyState == SR_OPEN || self.webSocket.readyState == SR_CONNECTING  ||
        self.reconnectAttempts >= _joinNum) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
       dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
           if (weakSelf.reconnectAttempts >= _joinNum) return;
           
           weakSelf.reconnectAttempts++;
           self.isEnd = YES;
           NSLog(@"尝试重连... (第%ld次)", (long)weakSelf.reconnectAttempts);
           [weakSelf connectServer];
       });
}


//关闭连接
- (void)SRWebSocketClose;
{
        NSLog(@"关闭连接");
    self.isClose = YES;
    NSDateFormatter *_dateFormatter = [[NSDateFormatter alloc] init] ;
    [_dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
    NSString *strng  = [_dateFormatter stringFromDate:[NSDate date]];
        if (self.isClose == YES) {
            NSLog(@"self.isClose == YES %@", strng);
        } else {
            NSLog(@"self.isClose == NO%@", strng);
        }
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 50 * NSEC_PER_MSEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^{
        NSDateFormatter *_dateFormatter = [[NSDateFormatter alloc] init] ;
        [_dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
        NSString *strng  = [_dateFormatter stringFromDate:[NSDate date]];
        NSLog(@"MatchingCallTool发送时间%@", strng);
        NSLog(@"已经上传的长度 == %ld",self.currentOffset);
        NSLog(@"录音总长 == %ld",self.audioData.length);
        [[STSocketTool sharedSocketManager] sendDataToServer:@{
            @"eof":@1}];
    });
}

//关闭连接
- (void)webSocketClose
{
    if(self.webSocket)
    {
        NSLog(@"关闭连接");
        [_webSocket close];
        _webSocket = nil;
    }
    [_timer invalidate];
    _timer = nil;
}

//发送数据给服务器
- (void)sendDataToServer:(id)data
{
    [self.sendDataArray addObject:data];
    [self sendeDataToServer];
}


- (void)sendeDataToServer
{
    __weak typeof (self) weakSelf = self;
    
    //把数据放到一个请求队列中
//    dispatch_async(self.queue, ^{
        
        //没有网络
        if (AFNetworkReachabilityManager.sharedManager.networkReachabilityStatus == AFNetworkReachabilityStatusNotReachable)
        {
            //开启网络检测定时器
            [weakSelf noNetWorkStartTestingTimer];
        }
        else //有网络
        {
            if (weakSelf.webSocket != nil)
            {
                // 只有长连接OPEN开启状态才能调 send 方法，不然会Crash
                if(weakSelf.webSocket.readyState == SR_OPEN)
                {
                    if (weakSelf.sendDataArray.count > 0)
                    {
                        NSDictionary *dic = weakSelf.sendDataArray[0];
                        NSLog(@"dic==========%@", dic);
                        NSError *error;
                        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:0 error:&error];
                        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                        
                        [weakSelf.webSocket send:jsonString]; //发送数据
                        [weakSelf.sendDataArray removeObjectAtIndex:0];
                        NSLog(@"weakSelf.sendDataArray == %ld", weakSelf.sendDataArray.count);
                        if([weakSelf.sendDataArray count] > 0)
                        {
                            [weakSelf sendeDataToServer];
                        }
                    }
                }
                else if (weakSelf.webSocket.readyState == SR_CONNECTING) //正在连接
                {
                    NSLog(@"正在连接中，重连后会去自动同步数据");
                }
                else if (weakSelf.webSocket.readyState == SR_CLOSING || weakSelf.webSocket.readyState == SR_CLOSED) //断开连接
                {
                    //调用 reConnectServer 方法重连,连接成功后 继续发送数据
                    [weakSelf reConnectServer];
                }
            }
            else
            {
                self.isEnd = YES;
                [weakSelf connectServer]; //连接服务器
            }
        }
//    });
}

#pragma mark - SRWebSocketDelegate -- webSockect代理

//连接成功回调
- (void)webSocketDidOpen:(SRWebSocket *)webSocket
{
        NSLog(@"webSocket ===  连接成功");
    [self initHeartBeat]; //开启心跳
            // 发送消息给服务器
            if ([_url containsString:@"v2"]) {
                [[STSocketTool sharedSocketManager] sendDataToServer:@{
                    @"config":@{
                        @"samp_freq": @(_samp_freq),
                        @"spk_num": @(_spk_num),
                    @"if_temp": @0,
                        @"endpoint_mode":@1,
                    @"language": @"zh"
                    }
                    }];
            } else {
                    [[STSocketTool sharedSocketManager] sendDataToServer:@{
                        @"config":@{
                            @"samp_freq": @(_samp_freq),
                            @"session_id": @"82df7adf-a8ce-4e88-bc42-d9aafcc4367211111111"
                            }
                        }];
            }
        
        //如果有尚未发送的数据，继续向服务端发送数据
        if ([self.sendDataArray count] > 0) {
            [self sendeDataToServer];
        }
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 50 * NSEC_PER_MSEC);
    // 使用dispatch_after延时执行
    dispatch_after(popTime, dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(socketToolreceiveMessageWithClass:WithJoin:)]) {
            [self.delegate socketToolreceiveMessageWithClass:self WithJoin:YES];
        }
    });
    NSLog(@"如果有链接，并且还未发送,那么将开启定时器");
}

// 上传音频文件
- (void)sendRecordedDataToServer:(NSData *)data {
    self.audioData = data;
    [self sendNextChunkWithInitiativeSend];
}

// 直接选择音频路径上传的
- (void)sendRecordedFileToServer:(NSString *)filePath {
    NSData *audioData = [NSData dataWithContentsOfFile:filePath];
    if (audioData) {
        self.audioData = audioData;
        [_timer invalidate];
        _timer = nil;
        __weak typeof (self) weakSelf = self;
        weakSelf.isClose = YES;
        _timer = [NSTimer timerWithTimeInterval:0.05
                                         target:weakSelf
                                       selector:@selector(sendNextChunkWithInitiativeSend)
                                       userInfo:nil
                                        repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
        
    } else {
        NSLog(@"录音文件读取失败");
    }
}


//连接失败回调
- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error
{
    //用户主动断开连接，就不去进行重连
    if(self.isActivelyClose)
    {
        return;
    }
    
    [self destoryHeartBeat]; //断开连接时销毁心跳
    
    NSLog(@"连接失败，这里可以实现掉线自动重连，要注意以下几点");
    NSLog(@"1.判断当前网络环境，如果断网了就不要连了，等待网络到来，在发起重连");
    NSLog(@"3.连接次数限制，如果连接失败了，重试10次左右就可以了");
    
    //判断网络环境
    if (AFNetworkReachabilityManager.sharedManager.networkReachabilityStatus == AFNetworkReachabilityStatusNotReachable) //没有网络
    {
        NSLog(@"开启网络检测定时器");
        [self noNetWorkStartTestingTimer];//开启网络检测定时器
    }
    else //有网络
    {
        NSLog(@"连接失败就重连");
        NSLog(@"error== %@", error);
        [self reConnectServer];
    }
}

//连接关闭,注意连接关闭不是连接断开，关闭是 [socket close] 客户端主动关闭，断开可能是断网了，被动断开的。
- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean
{
    // 在这里判断 webSocket 的状态 是否为 open , 大家估计会有些奇怪 ，因为我们的服务器都在海外，会有些时间差，经过测试，我们在进行某次连接的时候，上次重连的回调刚好回来，而本次重连又成功了，就会误以为，本次没有重连成功，而再次进行重连，就会出现问题，所以在这里做了一下判断
    if (self.webSocket.readyState == SR_OPEN || self.isActivelyClose)
    {
        return;
    }
    
    NSLog(@"被关闭连接，code:%ld,reason:%@,wasClean:%d",code,reason,wasClean);
    if ([self.delegate respondsToSelector:@selector(socketToolDisconnectWithClass:didCloseWithCode:reason:wasClean:)]) {
        [self.delegate socketToolDisconnectWithClass:self didCloseWithCode:code reason:reason wasClean:wasClean];
    }
    //判断网络环境
    if (AFNetworkReachabilityManager.sharedManager.networkReachabilityStatus == AFNetworkReachabilityStatusNotReachable) //没有网络
    {
        [self noNetWorkStartTestingTimer];//开启网络检测
    }
    else //有网络
    {
        [self reConnectServer];//连接失败就重连
    }
}

//该函数是接收服务器发送的pong消息，其中最后一个参数是接受pong消息的
-(void)webSocket:(SRWebSocket *)webSocket didReceivePong:(NSData*)pongPayload
{
    NSLog(@"%@", pongPayload);
    NSString* reply = [[NSString alloc] initWithData:pongPayload encoding:NSUTF8StringEncoding];
    NSLog(@"reply === 收到后台心跳回复 Data:%@",reply);
}

// 开始发送音频数据
//- (void)startSendingAudioData {
//    // 启动定时器，每隔 15 秒发送一次数据
    
//}


// 发送下一个数据块 是否是主动发送
- (void)sendNextChunkWithInitiativeSend {
    
    if (!self.audioData || self.audioData.length ==0) {
        NSLog(@"没往下执行！！！！");
        return;
    }
    
    NSDateFormatter *_dateFormatter = [[NSDateFormatter alloc] init] ;
    [_dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
    NSString *strng  = [_dateFormatter stringFromDate:[NSDate date]];
    NSLog(@"self.webSocket.readyState ==%ld", self.webSocket.readyState);
    if (self.webSocket.readyState == SR_OPEN) {
        NSLog(@"已经上传的长度 == %ld",self.currentOffset);
        NSLog(@"录音总长 == %ld",self.audioData.length);
        if (self.isClose == YES) {
            NSLog(@"self.isClose == YES %@", strng);
        } else {
            NSLog(@"self.isClose == NO%@", strng);
        }
    }
        
    if (self.isClose == YES && self.currentOffset >= self.audioData.length) {
        NSLog(@"用户关闭，录音上传完成");
        self.isEnd = NO;
        
        if (self.webSocket.readyState == SR_OPEN) {
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 50 * NSEC_PER_MSEC);
            dispatch_after(popTime, dispatch_get_main_queue(), ^{
                NSDateFormatter *_dateFormatter = [[NSDateFormatter alloc] init] ;
                [_dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
                NSString *strng  = [_dateFormatter stringFromDate:[NSDate date]];
                NSLog(@"MatchingCallTool发送时间%@", strng);
                [[STSocketTool sharedSocketManager] sendDataToServer:@{
                    @"eof": @1}];
            });
        }
        return;
    }
    
    if (self.webSocket.readyState == SR_OPEN) {
        NSLog(@"正常上传");
        // 计算当前分块
        NSUInteger remainingBytes = self.audioData.length - self.currentOffset;
        NSUInteger currentChunkSize = MIN(kChunkSize, remainingBytes);
        NSData *chunk = [self.audioData subdataWithRange:NSMakeRange(self.currentOffset, currentChunkSize)];
        
        // 发送分块
        [self sendChunk:chunk];
        // 更新偏移量
        self.currentOffset += currentChunkSize;
    }
}



// 发送单个数据块
- (void)sendChunk:(NSData *)chunk {
    if (self.webSocket.readyState == SR_OPEN) {
        NSError *err;
        if (chunk.length == 0) {
            return;
        }
        NSDateFormatter *_dateFormatter = [[NSDateFormatter alloc] init] ;
        [_dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
        NSString *strng  = [_dateFormatter stringFromDate:[NSDate date]];
        NSLog(@"发送时间%@", strng);
        NSLog(@"发chunk%@", chunk);
        [self.webSocket send:chunk]; // 发送二进制数据
        if (err) {
                        NSLog(@"发送失败: %@", err.localizedDescription);
                        // 处理错误（如重试或通知上层）
                    }
        self.lastSendDate = [NSDate date]; // 更新最后发送时间
        NSLog(@"Sent audio chunk of size: %lu bytes", (unsigned long)chunk.length);
    } else {
        NSLog(@"WebSocket is not open. Current state: %ld", (long)self.webSocket.readyState);
    }
}

//收到服务器发来的数据
- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message
{
    NSLog(@"422");

    NSData *jsonData = [message dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    
    NSMutableDictionary *dataDic = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                   options:NSJSONReadingMutableContainers
                                                                     error:&err];
    NSLog(@"dataDic==%@", dataDic);
    if (dataDic && [dataDic objectForKey:@"is_end"] != nil) {
        NSLog(@"%@", [dataDic[@"is_end"] class]);
        NSNumber *is_endString = dataDic[@"is_end"];
        NSLog(@"%@", is_endString);
        if ([is_endString isEqualToNumber:@1]) {
            NSLog(@"is_endString == 1");
            self.isActivelyClose = YES;
            [self webSocketClose];
            //关闭心跳定时器
            [self destoryHeartBeat];
            //关闭网络检测定时器
            [self destoryNetWorkStartTesting];
            
            if ([self.delegate respondsToSelector:@selector(socketToolreceiveMessageWithClass:WithText:WithEnd:)]) {
                [self.delegate socketToolreceiveMessageWithClass:self WithText:dataDic[@"result"][@"text"] WithEnd:YES];
            }
        } else {
            if ([self.delegate respondsToSelector:@selector(socketToolreceiveMessageWithClass:WithText:WithEnd:)]) {
                [self.delegate socketToolreceiveMessageWithClass:self WithText:dataDic[@"result"][@"text"] WithEnd:NO];
            }
            NSLog(@"is_endString == 0");
        }
    }
    /*根据具体的业务做具体的处理*/
}

@end
