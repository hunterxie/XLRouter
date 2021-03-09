//
//  XLViewController.m
//  XLRouter
//
//  Created by hunterxie on 03/09/2021.
//  Copyright (c) 2021 hunterxie. All rights reserved.
//

#import "XLViewController.h"
#import <XLRouter/XLRouterManager.h>
@interface XLViewController ()

@end

@implementation XLViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self addRegist];
    [self callRouter];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)addRegist {
    
    [XLRouterManager addRouteWithScheme:@"xll" handler:^(NSURL * _Nonnull url, NSDictionary * _Nonnull userInfo, XLRouterOpenCompletion  _Nonnull routerOpenCompletion) {
        NSLog(@"didRecieveMsgUrl:%@,userInfo:%@",url,userInfo);
        if (routerOpenCompletion) {
            routerOpenCompletion(YES,@"callback1");
        }
    }];
    
    [XLRouterManager addRouteWithScheme:@"hello" withHost:@"kitty" handler:^(NSURL * _Nonnull url, NSDictionary * _Nonnull userInfo, XLRouterOpenCompletion  _Nonnull routerOpenCompletion) {
        NSLog(@"didRecieveMsgUrl:%@,userInfo:%@",url,userInfo);
    }];
}

- (void)callRouter {
    NSURL *url = [NSURL URLWithString:@"xll://good/happy?name=xiaoming"];
    if ([XLRouterManager canOpenURL:url]) {
        NSDictionary *userInfo = @{@"key1":@"token1"};
        
        [XLRouterManager openURL:url withUserInfo:userInfo completion:^(BOOL isSucc, id  _Nonnull data) {
            if (isSucc) {
                NSLog(@"%@",data);
            }
        }];
    }
    
    NSURL *url1 = [NSURL URLWithString:@"hello://kitty/happy?name=xiaoming"];
    NSDictionary *userInfo1 = @{@"key2":@"token2"};
    [XLRouterManager openURL:url1 withUserInfo:userInfo1];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
