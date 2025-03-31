//
//  SD_RecordHelper.m
//  SDRecord
//
//  Created by Stephen on 2017/12/22.
//  Copyright © 2017年 Stephen. All rights reserved.
//

#import "SD_RecordHelper.h"
#import <AVFoundation/AVFoundation.h>
//#import "Record.h"

//#import "RecordDataAccessor.h"

#define kRecordAudioFile @"myRecord.caf"
#define kRecordDuration 15

@interface SD_RecordHelper ()<AVAudioRecorderDelegate>
{
    ///录音时长
//    NSInteger _recordTimeIndex;
    ///录音地址
    NSString *_recordPath;
    NSString *_recordName;
}

@property (nonatomic,strong) AVAudioRecorder *audioRecorder;//音频录音机
@property (nonatomic,strong) AVAudioPlayer *audioPlayer;//音频播放器，用于播放录音文件

@property (nonatomic,strong) NSTimer *timer;//录音timer
///date格式器
@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@property (nonatomic, assign) BOOL isInit; // 是否已经初始化

@end

static SD_RecordHelper *_SD_RecordHelper = nil;

@implementation SD_RecordHelper

- (instancetype)init
{
    self = [super init];
    if (self) {
        _recordStatus = SD_RHDone;
        _recordName = [self.dateFormatter stringFromDate:[NSDate date]];
        [self setAudioSession];
//        [self recordClick];
        self.isInit = NO;
    }
    return self;
}

+ (instancetype)share{
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _SD_RecordHelper = [[super allocWithZone:NULL] init];
    });
    
    return _SD_RecordHelper;
    
}

+ (id)allocWithZone:(struct _NSZone *)zone {
    return [SD_RecordHelper share];
}

- (id)copyWithZone:(struct _NSZone *)zone {
    return [SD_RecordHelper share];
}

// 初始化录音机
- (void)initRecord {
    // 新增：生成新的时间戳文件名
    _recordName = [self.dateFormatter stringFromDate:[NSDate date]];
    [self configAudioRecorder];
}

///开始录音
- (void)startRecord {
    _recordStatus = SD_RHRecording;
    
    
//    if (self.isInit == YES) {
    // 准备录音
        [self.audioRecorder prepareToRecord];
        [self.audioRecorder record];//首次使用应用时如果调用record方法会询问用户是否允许使用麦克风
        [self recordClick];
//    }
//    self.isInit = YES;
}

///暂停录音
- (void)pauseRecord{

    _recordStatus = SD_RHPause;
    
    [self pauseClick];
    
}

///继续录音
- (void)resumeRecord {
    _recordStatus = SD_RHRecording;
    
    [self resumeClick];
}

///停止录音
- (void)finishRecord {
    //设置当前录音状态
    _recordStatus = SD_RHDone;
    
    [self stopClick];
    
    //初始化录音数据
    _recordTimeIndex = 0;
    [_timer invalidate];
    _timer = nil;
    
    // 显式释放录音器实例
    _audioRecorder.delegate = nil;
    _audioRecorder = nil;
    
    [self initRecord];
    
    [self.delegate SD_RecordHelperWithClass:self WithStop:YES];
    
    
}


///开始按钮点击
- (void)recordClick {
    
//    [self configAudioRecorder];
   
    [self configTimer];
    NSLog(@"录音 == 开始");
}


///暂停按钮点击
- (void)pauseClick {
    if ([self.audioRecorder isRecording]) {
        self.recordStatus = SD_RHPause;
        [self.audioRecorder pause];
        [self.timer setFireDate:[NSDate distantFuture]];
        NSLog(@"录音 == 暂停");
    }
}

///继续按钮点击
- (void)resumeClick{
    [self.audioRecorder record];
    [self.timer setFireDate:[NSDate distantPast]];
    NSLog(@"录音 == 继续");
}

///停止按钮点击
- (void)stopClick{
    [self.audioRecorder stop];
    
    
    NSLog(@"录音 == 停止");
}

///保存录音
- (void)saveRecord {
    
    NSData *data = [NSData dataWithContentsOfFile:_recordPath];
    NSLog(@"当前录音长度 %lu", (unsigned long)data.length);
    
    [self.delegate SD_RecordHelperWithClass:self WithUrl:_recordPath];

}


//dateformatter
- (NSDateFormatter *)dateFormatter{
    if (!_dateFormatter) {
        _dateFormatter = [[NSDateFormatter alloc] init] ;
        [_dateFormatter setDateFormat:@"yyyy-MM-dd_HH-mm-ss"]; //大写的 H为24小时制，小写h为12小时制
    }
    return _dateFormatter;
}

/**
 *  timer
 */
- (void)configTimer{
    if (!_timer) {
        __weak typeof(self) weakSelf = self;
        _recordTimeIndex = 0;
        _timer = [NSTimer timerWithTimeInterval:0.05
                                         target:weakSelf
                                       selector:@selector(startRecordAction)
                                       userInfo:nil
                                        repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
    }
}

///开始录音的各种操作
- (void)startRecordAction {
    
//    NSLog(@"%@", [NSString stringWithFormat:@"录音%ld秒",(long)_recordTimeIndex]);
    
    //传出时间技术
//    if (self.SDRecordTimeBlock) {
//        self.SDRecordTimeBlock(_recordTimeIndex);
//    }
    
//    if (_recordTimeIndex < kRecordDuration) {
        self.recordStatus = SD_RHRecording;
//        _recordTimeIndex += 1;
//    } else {
//        [self stopClick];
//        _recordTimeIndex = 0;
//        _recordName = [self.dateFormatter stringFromDate:[NSDate date]];
//        [self recordClick];
//    }
        NSData *data = [NSData dataWithContentsOfFile:_recordPath];
//        NSLog(@"data audio chunk of size: %lu bytes", (unsigned long)data.length);
        
        [self.delegate SD_RecordHelperWithClass:self WithUrl:_recordPath];
}


/**
 *  设置音频会话
 */
-(void)setAudioSession {
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    // 设置为播放和录音状态，以便可以在录制完之后播放录音
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [audioSession setActive:YES error:nil];
}

///获取录音地址
-(NSURL *)getSavePath {
    _recordPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    _recordPath = [_recordPath stringByAppendingPathComponent:_recordName];
//    _recordPath = [_recordPath stringByAppendingPathComponent:@"12344"];
    NSLog(@"录音路径:file path:%@",_recordPath);
    NSURL *url = [NSURL fileURLWithPath:_recordPath];
    return url;
}


///取得录音文件设置
-(NSDictionary *)getAudioSetting{
    NSMutableDictionary *dicM=[NSMutableDictionary dictionary];
    //设置录音格式, iOS录音的格式为PCM格式,可以转换其他的录音格式，具体的Google一下吧
    [dicM setObject:@(kAudioFormatLinearPCM) forKey:AVFormatIDKey];
    //设置录音采样率，8000是电话采样率，对于一般录音已经够了
    [dicM setObject:@(16000) forKey:AVSampleRateKey];
    //设置通道,这里采用单声道
    [dicM setObject:@(1) forKey:AVNumberOfChannelsKey];
//    //每个采样点位数,分为8、16、24、32
    [dicM setObject:@(16) forKey:AVLinearPCMBitDepthKey];
//    //是否使用浮点数采样
//    [dicM setObject:@(YES) forKey:AVLinearPCMIsFloatKey];
    
    //....其他设置等
    return dicM;
}


///配置录音机
-(void)configAudioRecorder {
    
    //录音文件保存路径，我设置的路径是当前时间的字符串，注意路径不要有空格
    
    _recordPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    _recordPath = [_recordPath stringByAppendingPathComponent:_recordName];
//    _recordPath = [_recordPath stringByAppendingPathComponent:@"12344"];
    NSLog(@"录音路径:file path:%@",_recordPath);
    NSURL *url = [NSURL fileURLWithPath:_recordPath];
    //录音格式设置
    NSDictionary *setting=[self getAudioSetting];
    //录音机
    NSError *error=nil;
    _audioRecorder=[[AVAudioRecorder alloc]initWithURL:url settings:setting error:&error];
    self.audioRecorder.delegate = self;
    //这个设置为YES可以做音波的效果，我没有实现音波功能
    _audioRecorder.meteringEnabled=YES;
    if (error) {
        NSLog(@"创建录音机audioRecorder发生错误:%@",error.localizedDescription);
    } else {
//        if (_recordPath && _recordPath != nil && _recordPath != NULL && _recordPath.length != 0) {
//            NSLog(@"制定执行");
            
//        }
    }
    
}

#pragma mark - 录音机代理方法
/**
 *  录音完成
 */
-(void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag{

    ///录音完成
    if (self.SDRecordDoneBlock) {
        self.SDRecordDoneBlock();
    }
    NSLog(@"录音完成!");
    [self saveRecord];
}

///获取播放器
-(AVAudioPlayer *)audioPlayer{
    if (!_audioPlayer) {
        NSURL *url=[self getSavePath];
        NSError *error=nil;
        _audioPlayer=[[AVAudioPlayer alloc]initWithContentsOfURL:url error:&error];
        _audioPlayer.numberOfLoops=0;
        [_audioPlayer prepareToPlay];
        if (error) {
            NSLog(@"创建播放器过程中发生错误,错误信息：%@",error.localizedDescription);
            return nil;
        }
    }
    return _audioPlayer;
}

///播放录音
- (void)playRecord:(NSString *)path{
    NSURL *url=[NSURL fileURLWithPath:path];
    NSError *error=nil;
    
    self.audioPlayer = [[AVAudioPlayer alloc]initWithContentsOfURL:url error:&error];
    self.audioPlayer.numberOfLoops=0;
    [self.audioPlayer prepareToPlay];
    if (error) {
        NSLog(@"创建播放器过程中发生错误,错误信息：%@",error.localizedDescription);
    }
    [self.audioPlayer play];
}


@end
