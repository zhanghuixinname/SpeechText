//
//  STViewController.m
//  SpeechText
//
//  Created by xiaojiuwo on 03/31/2025.
//  Copyright (c) 2025 xiaojiuwo. All rights reserved.
//

#import "STViewController.h"

@interface STViewController ()

@end

@implementation STViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    UILabel *label1 = [[UILabel alloc] init];
    label1.text = @"音频采样率：";
    label1.textColor = [UIColor blackColor];
    label1.font = [UIFont systemFontOfSize:14];
    [self.view addSubview:label1];
    label1.frame = CGRectMake(120, 370, 100, 50);
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
