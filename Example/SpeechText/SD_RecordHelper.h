//
//  SD_RecordHelper.h
//  SDRecord
//
//  Created by Stephen on 2017/12/22.
//  Copyright © 2017年 Stephen. All rights reserved.
//


#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    /// 正在录音
    SD_RHRecording,
    /// 录音完成
    SD_RHDone,
    /// 录音暂停
    SD_RHPause,
} SD_RHRecordStatus;

typedef void(^SD_RecordTimeBlock)(NSInteger );
typedef void(^SD_RecordDoneBlock)(void);

@class SD_RecordHelper;
@protocol SD_RecordHelperDelegate <NSObject>

@optional

- (void)SD_RecordHelperWithClass:(SD_RecordHelper *)classSuper WithUrl:(NSString *)url;

- (void)SD_RecordHelperWithClass:(SD_RecordHelper *)classSuper WithStop:(BOOL)stop;

@end

@interface SD_RecordHelper : NSObject
///录音时间技术block
@property (copy, nonatomic) SD_RecordTimeBlock SDRecordTimeBlock;
///录音保存成功block
@property (copy, nonatomic) SD_RecordDoneBlock SDRecordDoneBlock;

///录音时长
@property (assign , nonatomic) NSInteger recordTimeIndex;

///当前录音状态
@property (assign , nonatomic) SD_RHRecordStatus recordStatus;

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



///获取录音helper单例
+ (instancetype)share;


///开始录音
- (void)initRecord;

///开始录音
- (void)startRecord;

///暂停录音
- (void)pauseRecord;
///继续录音
- (void)resumeRecord;
//停止录音
- (void)finishRecord;


///播放录音
- (void)playRecord:(NSString *)path;

@property (nonatomic, weak) id<SD_RecordHelperDelegate>delegate;

@end
