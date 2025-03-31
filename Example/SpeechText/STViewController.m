//
//  STViewController.m
//  SpeechText
//
//  Created by xiaojiuwo on 03/31/2025.
//  Copyright (c) 2025 xiaojiuwo. All rights reserved.
//

#import "STViewController.h"

#import "STSocketTool.h"
#import "UIColor+Hex.h"

#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>

#import "SD_RecordHelper.h"

#define kFullScreenWidth ([UIScreen mainScreen].bounds.size.width)

@interface STViewController () <AVAudioRecorderDelegate, STSocketToolDelegate, SD_RecordHelperDelegate>

@property (nonatomic, strong) AVAudioRecorder *audioRecorder;
@property (nonatomic, strong) NSURL *recordedFileURL;
@property (nonatomic, strong) NSData *audioData;

/** 是否链接成功 */
@property (nonatomic, assign) BOOL isJoin;

@property (nonatomic, strong) UILabel *hintLabel;
@property (nonatomic, strong) UILabel *stateLabel;

@property (nonatomic, strong) NSString *urlSteing;

@property (nonatomic, strong) UIButton *button;

@property (nonatomic, strong) UITextField *samp_freqTextFiled;
@property (nonatomic, strong) UITextField *joinNumTextFiled;
@property (nonatomic, strong) UITextField *spk_numTextFiled;
@property (nonatomic, strong) UITextField *tokenTextFiled;
@property (nonatomic, strong) UITextField *urlTextFiled;
@property (nonatomic, strong) UITextField *session_idTextFiled;

@property (nonatomic, strong) UILabel *serviceLabel;

@end

@implementation STViewController


- (UITextField *)tokenTextFiled {
    if (_tokenTextFiled) {
        return _tokenTextFiled;
    }
    _tokenTextFiled = [[UITextField alloc] init];
    _tokenTextFiled.placeholder = @"请输入token";
    _tokenTextFiled.backgroundColor = [UIColor colorWithHexString:@"#f2f2f2" alpha:1];
    _tokenTextFiled.textColor = [UIColor colorWithHexString:@"#333333" alpha:1];
    _tokenTextFiled.font = [UIFont systemFontOfSize:14];
    return _tokenTextFiled;
}

- (UITextField *)urlTextFiled {
    if (_urlTextFiled) {
        return _urlTextFiled;
    }
    _urlTextFiled = [[UITextField alloc] init];
    _urlTextFiled.placeholder = @"请输入url";
    _urlTextFiled.backgroundColor = [UIColor colorWithHexString:@"#f2f2f2" alpha:1];
    _urlTextFiled.textColor = [UIColor colorWithHexString:@"#333333" alpha:1];
    _urlTextFiled.font = [UIFont systemFontOfSize:14];
    return _urlTextFiled;
}

- (UITextField *)samp_freqTextFiled {
    if (_samp_freqTextFiled) {
        return _samp_freqTextFiled;
    }
    _samp_freqTextFiled = [[UITextField alloc] init];
    _samp_freqTextFiled.placeholder = @"默认16000，需要与实际采样率一致";
    _samp_freqTextFiled.backgroundColor = [UIColor colorWithHexString:@"#f2f2f2" alpha:1];
    _samp_freqTextFiled.keyboardType = UIKeyboardTypeNumberPad;
    _samp_freqTextFiled.textColor = [UIColor colorWithHexString:@"#333333" alpha:1];
    _samp_freqTextFiled.font = [UIFont systemFontOfSize:14];

    return _samp_freqTextFiled;
}

- (UITextField *)joinNumTextFiled {
    if (_joinNumTextFiled) {
        return _joinNumTextFiled;
    }
    _joinNumTextFiled = [[UITextField alloc] init];
    _joinNumTextFiled.placeholder = @"连接掉线重连次数，默认2次";
    _joinNumTextFiled.backgroundColor = [UIColor colorWithHexString:@"#f2f2f2" alpha:1];
    _joinNumTextFiled.keyboardType = UIKeyboardTypeNumberPad;
    _joinNumTextFiled.textColor = [UIColor colorWithHexString:@"#333333" alpha:1];
    _joinNumTextFiled.font = [UIFont systemFontOfSize:14];
    return _joinNumTextFiled;
}

- (UITextField *)spk_numTextFiled {
    if (_spk_numTextFiled) {
        return _spk_numTextFiled;
    }
    _spk_numTextFiled = [[UITextField alloc] init];
    _spk_numTextFiled.placeholder = @" 场景有⼏个说话⼈。默认1人";
    _spk_numTextFiled.backgroundColor = [UIColor colorWithHexString:@"#f2f2f2" alpha:1];
    _spk_numTextFiled.keyboardType = UIKeyboardTypeNumberPad;
    _spk_numTextFiled.textColor = [UIColor colorWithHexString:@"#333333" alpha:1];
    _spk_numTextFiled.font = [UIFont systemFontOfSize:14];
    return _spk_numTextFiled;
}

- (UITextField *)session_idTextFiled {
    if (_session_idTextFiled) {
        return _session_idTextFiled;
    }
    _session_idTextFiled = [[UITextField alloc] init];
    _session_idTextFiled.placeholder = @"请输入session_id";
    _session_idTextFiled.backgroundColor = [UIColor colorWithHexString:@"#f2f2f2" alpha:1];
    _session_idTextFiled.keyboardType = UIKeyboardTypeNumberPad;
    _session_idTextFiled.textColor = [UIColor colorWithHexString:@"#333333" alpha:1];
    _session_idTextFiled.font = [UIFont systemFontOfSize:14];
    return _session_idTextFiled;
}


- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}


- (void)viewDidLoad {
    [super viewDidLoad];

    self.isJoin = NO;

    [self requestMicrophonePermission];
    self.view.backgroundColor = [UIColor colorWithHexString:@"#ffffff" alpha:1];
    
    SD_RecordHelper *recordHelper = [SD_RecordHelper share];
    [recordHelper initRecord];
    
    
    
    UILabel *label1 = [[UILabel alloc] init];
    label1.text = @"音频采样率：";
    label1.textColor = [UIColor colorWithHexString:@"#000000" alpha:1];
    label1.font = [UIFont systemFontOfSize:14];
    [self.view addSubview:label1];
    
    UILabel *label2 = [[UILabel alloc] init];
    label2.text = @"掉线重连次数：";
    label2.textColor = [UIColor colorWithHexString:@"#000000" alpha:1];
    label2.font = [UIFont systemFontOfSize:14];
    [self.view addSubview:label2];
    
    UILabel *label3 = [[UILabel alloc] init];
    label3.text = @"会话人数：";
    label3.textColor = [UIColor colorWithHexString:@"#000000" alpha:1];
    label3.font = [UIFont systemFontOfSize:14];
    [self.view addSubview:label3];
    
    UILabel *label4 = [[UILabel alloc] init];
    label4.text = @"token：";
    label4.textColor = [UIColor colorWithHexString:@"#000000" alpha:1];
    label4.font = [UIFont systemFontOfSize:14];
    [self.view addSubview:label4];
    
    UILabel *label5 = [[UILabel alloc] init];
    label5.text = @"url：";
    label5.textColor = [UIColor colorWithHexString:@"#000000" alpha:1];
    label5.font = [UIFont systemFontOfSize:14];
    [self.view addSubview:label5];
    
    UILabel *label6 = [[UILabel alloc] init];
    label6.text = @"url：";
    label6.textColor = [UIColor colorWithHexString:@"#000000" alpha:1];
    label6.font = [UIFont systemFontOfSize:14];
    [self.view addSubview:label6];
    
    [self.view addSubview:self.samp_freqTextFiled];
    [self.view addSubview:self.joinNumTextFiled];
    [self.view addSubview:self.spk_numTextFiled];
    [self.view addSubview:self.tokenTextFiled];
    [self.view addSubview:self.urlTextFiled];
    [self.view addSubview:self.session_idTextFiled];
    
    self.button = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.button setTitle:@"开始转换" forState:UIControlStateNormal];
    [self.button setTitleColor:[UIColor colorWithHexString:@"#000000" alpha:1] forState:UIControlStateNormal];
    self.button.titleLabel.font = [UIFont boldSystemFontOfSize:13];
    self.button.backgroundColor = [UIColor colorWithHexString:@"#3898ea" alpha:1];
    self.button.layer.cornerRadius = 14;
    self.button.layer.masksToBounds = YES;
    [self.button addTarget:self action:@selector(startRecordbutton) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.button];
    
    UIButton *button1 = [UIButton buttonWithType:UIButtonTypeCustom];
    [button1 setTitle:@"结束上传" forState:UIControlStateNormal];
    [button1 setTitleColor:[UIColor colorWithHexString:@"#000000" alpha:1] forState:UIControlStateNormal];
    button1.titleLabel.font = [UIFont boldSystemFontOfSize:13];
    button1.backgroundColor = [UIColor colorWithHexString:@"#3898ea" alpha:1];
    button1.layer.cornerRadius = 14;
    button1.layer.masksToBounds = YES;
    [button1 addTarget:self action:@selector(stopRecordbutton) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button1];
    
    UIButton *button2 = [UIButton buttonWithType:UIButtonTypeCustom];
    [button2 setTitle:@"播放" forState:UIControlStateNormal];
    [button2 setTitleColor:[UIColor colorWithHexString:@"#000000" alpha:1] forState:UIControlStateNormal];
    button2.titleLabel.font = [UIFont boldSystemFontOfSize:13];
    button2.backgroundColor = [UIColor colorWithHexString:@"#3898ea" alpha:1];
    button2.layer.cornerRadius = 14;
    button2.layer.masksToBounds = YES;
    [button2 addTarget:self action:@selector(play) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button2];
    
    self.hintLabel = [[UILabel alloc] init];
    self.hintLabel.textColor = [UIColor redColor];
    self.hintLabel.backgroundColor = [UIColor colorWithHexString:@"#999999" alpha:1];
    self.hintLabel.numberOfLines = 0;
    [self.view addSubview:self.hintLabel];
    
    
    self.stateLabel = [[UILabel alloc] init];
    self.stateLabel.textColor = [UIColor redColor];
    self.stateLabel.backgroundColor = [UIColor colorWithHexString:@"#f2f2f2" alpha:1];
    self.stateLabel.font = [UIFont systemFontOfSize:14];
    self.stateLabel.text = @"当前状态：";
    [self.view addSubview:self.stateLabel];
    
    self.serviceLabel = [[UILabel alloc] init];
    self.serviceLabel.textColor = [UIColor redColor];
    self.serviceLabel.backgroundColor = [UIColor colorWithHexString:@"#f2f2f2" alpha:1];
    self.serviceLabel.font = [UIFont systemFontOfSize:14];
    self.serviceLabel.text = @"服务端状态：";
    [self.view addSubview:self.serviceLabel];
    
    label1.frame = CGRectMake(10, 30, 100, 50);
    self.samp_freqTextFiled.frame = CGRectMake(130, 30, kFullScreenWidth - 200, 50);
    
    label2.frame = CGRectMake(10, 90, 100, 50);
    self.joinNumTextFiled.frame = CGRectMake(130, 90, kFullScreenWidth - 200, 50);
    
    label3.frame = CGRectMake(10, 150, 100, 50);
    self.spk_numTextFiled.frame = CGRectMake(130, 150, kFullScreenWidth - 200, 50);
    
    label4.frame = CGRectMake(10, 210, 100, 50);
    self.tokenTextFiled.frame = CGRectMake(130, 210, kFullScreenWidth - 200, 50);
    
    label5.frame = CGRectMake(10, 270, 100, 50);
    self.urlTextFiled.frame = CGRectMake(130, 270, kFullScreenWidth - 200, 50);
    
    
    self.stateLabel.frame = CGRectMake(10, 330, kFullScreenWidth - 20, 30);
    
    self.button.frame = CGRectMake(10, 370, 100, 50);
    button1.frame = CGRectMake(120, 370, 100, 50);
    button2.frame = CGRectMake(230, 370, 100, 50);
    self.serviceLabel.frame = CGRectMake(10, 430, kFullScreenWidth - 20, 50);
    self.hintLabel.frame = CGRectMake(10, 490, kFullScreenWidth - 20, 300);
}



// 播放
- (void)play {
    SD_RecordHelper *recordHelper = [SD_RecordHelper share];
    [recordHelper playRecord:self.urlSteing];
}

/*
 1.开始录音
 */
- (void)startRecordbutton {
    NSLog(@"开始录音");
//    if ([self.tokenTextFiled.text isEqualToString:@""]) {
//        [self.view makeToast:@"请输入token"];
//        return;
//    }
//    if ([self.urlTextFiled.text isEqualToString:@""]) {
//        [self.view makeToast:@"请输入url"];
//        return;
//    }
    
    [STSocketTool sharedSocketManager].url = @"wss://maas-gz-api.ai-yuanjing.com/openapi/v2/unicom/ws/asr";
//    [STSocketTool sharedSocketManager].url = @"wss://maas-gz-api.ai-yuanjing.com/openapi/unicom/ws/asr";
//    [STSocketTool sharedSocketManager].joinNum = self.joinNumTextFiled.text.integerValue;
//    [STSocketTool sharedSocketManager].spk_num = self.spk_numTextFiled.text.integerValue;
//    [STSocketTool sharedSocketManager].samp_freq = self.samp_freqTextFiled.text.integerValue;;
//    [STSocketTool sharedSocketManager].session_id = self..text.integerValue;;
    [STSocketTool sharedSocketManager].token = @"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjE4NGIxYTEzLTU1NjYtNDNhYS04OTFhLWQ5ZTQ2ODZjN2NhYSIsInVzZXJuYW1lIjoiY2hpcmoiLCJuaWNrbmFtZSI6Iui_n-S6uuS_iiIsInVzZXJUeXBlIjowLCJidWZmZXJUaW1lIjoxNzQyOTg5MzA4LCJleHAiOjE3NDU1NzQxMDgsImp0aSI6ImJmYTNjNGZkNWE3YjQ0ZjJiNDBiNDg0YzViNDAyMmZmIiwiaWF0IjoxNzQyOTgxOTg4LCJpc3MiOiIxODRiMWExMy01NTY2LTQzYWEtODkxYS1kOWU0Njg2YzdjYWEiLCJuYmYiOjE3NDI5ODE5ODgsInN1YiI6ImtvbmcifQ.buD0y7W9hXEo2E0cSMYvXXfzbmFkkGIRzEcNY29ZIsg";
    
    
    self.stateLabel.text = [NSString stringWithFormat:@"当前状态：%@", @"启动服务中"];
    self.isJoin = NO;  // 长连接未连接成功
    self.hintLabel.text = @"";
    
    // 建立长连接
    [[STSocketTool sharedSocketManager] connectInitiativeServer];
    [STSocketTool sharedSocketManager].delegate = self;
    
}

- (void)socketToolreceiveMessageWithClass:(STSocketTool *)classSuper WithJoin:(BOOL)join {
    if (![self.stateLabel.text isEqualToString:@"当前状态：无操作"]) {
        self.stateLabel.text = [NSString stringWithFormat:@"当前状态：%@", @"连接成功"];
        self.serviceLabel.text = [NSString stringWithFormat:@"服务端状态：%@", @"连接成功"];
        // 就开始录音
        SD_RecordHelper *recordHelper = [SD_RecordHelper share];
        recordHelper.delegate = self;
        [recordHelper startRecord];
    }
    self.isJoin = YES;
}

/*
 3.停止录音
 */
- (void)stopRecordbutton {
    NSLog(@"停止录音");
    self.stateLabel.text = [NSString stringWithFormat:@"当前状态：%@", @"无操作"];
    self.serviceLabel.text = [NSString stringWithFormat:@"服务端状态：%@", @""];
    SD_RecordHelper *recordHelper = [SD_RecordHelper share];
    recordHelper.delegate = self;
    [recordHelper finishRecord];
}


// 转出文字
- (void)socketToolreceiveMessageWithClass:(STSocketTool *)classSuper WithText:(NSString *)text WithEnd:(BOOL)end{
    NSLog(@"%@", text);
    NSString *textStrring = @"";
    if (end == YES) {
        textStrring = [NSString stringWithFormat:@"最终结果为：%@", text];
    } else {
        textStrring = [NSString stringWithFormat:@"临时结果为：%@", text];
    }
    self.hintLabel.text = textStrring;
}

// 结束录音
- (void)SD_RecordHelperWithClass:(SD_RecordHelper *)classSuper WithStop:(BOOL)stop {
    if (stop == YES) { // 录音结束
        NSDateFormatter *_dateFormatter = [[NSDateFormatter alloc] init] ;
        [_dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
        NSString *strng  = [_dateFormatter stringFromDate:[NSDate date]];
        NSLog(@"结束录音时间 %@", strng);
        [[STSocketTool sharedSocketManager] SRWebSocketClose];
    }
}

// 超过重连次数未连接成功
- (void)socketToolConnectionFailureWithClass:(STSocketTool *)classSuper {
    self.serviceLabel.text = [NSString stringWithFormat:@"服务端状态：%@", @"超过重连次数未连接成功"];
}

- (void)socketToolDisconnectWithClass:(STSocketTool *)classSuper didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    self.serviceLabel.text = [NSString stringWithFormat:@"服务端状态：被关闭连接，code:%ld,reason:%@,wasClean:%d", code,reason,wasClean];
}

// 录音文件
- (void)SD_RecordHelperWithClass:(SD_RecordHelper *)classSuper WithUrl:(NSString *)url {
    
    self.urlSteing = url;
    if (self.isJoin == YES) {
        NSData *audioData = [NSData dataWithContentsOfFile:url];
        if (audioData) {
//            NSLog(@"录音文件传过来的录音长度%ld", audioData.length);
            self.audioData = audioData;
            [[STSocketTool sharedSocketManager] sendRecordedDataToServer:audioData];
        } else {
            NSLog(@"录音文件读取失败");
        }
    }
}

- (void)requestMicrophonePermission {
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession requestRecordPermission:^(BOOL granted) {
        if (granted) {
            // 用户已授权
            NSLog(@"麦克风权限已授权");
        } else {
            // 用户未授权
            NSLog(@"麦克风权限未授权");
            // 可以提示用户去设置中开启权限
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"麦克风权限" message:@"请在设置中允许访问麦克风" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *settingsAction = [UIAlertAction actionWithTitle:@"设置" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                NSURL *appSettings = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                [[UIApplication sharedApplication] openURL:appSettings options:@{} completionHandler:nil];
            }];
            [alert addAction:settingsAction];
            [self presentViewController:alert animated:YES completion:nil];
        }
    }];
}





@end
