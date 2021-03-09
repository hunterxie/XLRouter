# XLRouter

[![CI Status](https://img.shields.io/travis/hunterxie/XLRouter.svg?style=flat)](https://travis-ci.org/hunterxie/XLRouter)
[![Version](https://img.shields.io/cocoapods/v/XLRouter.svg?style=flat)](https://cocoapods.org/pods/XLRouter)
[![License](https://img.shields.io/cocoapods/l/XLRouter.svg?style=flat)](https://cocoapods.org/pods/XLRouter)
[![Platform](https://img.shields.io/cocoapods/p/XLRouter.svg?style=flat)](https://cocoapods.org/pods/XLRouter)

## Example

## Requirements

## Installation

XLRouter is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
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


```

## Author

hunterxie, 843144392@qq.com

## License

XLRouter is available under the MIT license. See the LICENSE file for more info.
