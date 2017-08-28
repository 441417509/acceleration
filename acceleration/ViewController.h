//
//  ViewController.h
//  acceleration
//
//  Created by chen on 2017/7/19.
//  Copyright © 2017年 chen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController
@property (weak, nonatomic) IBOutlet UILabel *accelerateX;
@property (weak, nonatomic) IBOutlet UILabel *accelerateY;
@property (weak, nonatomic) IBOutlet UILabel *accelerateZ;

@property (weak, nonatomic) IBOutlet UILabel *gyroX;
@property (weak, nonatomic) IBOutlet UILabel *gyroY;
@property (weak, nonatomic) IBOutlet UILabel *gyroZ;

@property (weak, nonatomic) IBOutlet UITextView *logTextView;
@end

