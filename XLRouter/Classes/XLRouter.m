//
//  XLRouter.m
//  Pods-XLRouter_Example
//
//  Created by xll on 2021/3/9.
//

#import "XLRouter.h"

@interface XLRouter ()

//当前路由匹配是否被锁定。锁定代表不处理传入的url，直接回调给业务方自己解析，且锁定的路由scheme只能注册一次，其他注册将会抛弃。
//目前只有- (void)addRouterWithScheme:(NSString *)scheme handler:(XLRouterHandler)handler方法会使当前路由被锁定
@property (nonatomic, assign, readonly) BOOL isSchemeLocked;

//所有规则回调列表
@property (nonatomic,strong) NSMutableDictionary *routes;

@end

@implementation XLRouter

//以scheme初始化一个实例，且设置是否锁定匹配
- (instancetype)initWithScheme:(NSString *)scheme isSchemeLocked:(BOOL)isSchemeLocked
{
    if (self = [super init])
    {
        _scheme = scheme;
        _isSchemeLocked = isSchemeLocked;
        self.routes = [[NSMutableDictionary alloc] init];
    }
    return self;
}

//以scheme初始化一个实例，且设置是否锁定匹配
+ (instancetype)routerForScheme:(NSString *)scheme isSchemeLocked:(BOOL)isSchemeLocked
{
    XLRouter *router = [[XLRouter alloc] initWithScheme:scheme isSchemeLocked:isSchemeLocked];
    return router;
}

#pragma mark - 添加路由

//注册一个scheme规则。使用该方式注册会使当前路由锁定，符合此scheme的url直接回调handler处理。解析时优先判断该方式注册的规则
- (BOOL)addRouterWithScheme:(NSString *)scheme handler:(XLRouterHandler)handlerBlock
{
    //路由未锁定，不能单独注册scheme
    if (self.isSchemeLocked == NO)
    {
        return NO;
    }
    
    //保存规则回调
    self.routes[scheme] = [handlerBlock copy];
    return YES;
}

//注册一个规则，指定scheme和host，当目标url符合当前scheme和host则执行handlerBlock
- (BOOL)addRouterWithScheme:(NSString *)scheme withHost:(NSString *)host handler:(XLRouterHandler)handlerBlock
{
    //路由已锁定
    if (self.isSchemeLocked)
    {
        NSLog(@"当前scheme已经使用addRouteWithScheme方式注册过了，已经被锁定，所以该scheme下不允许注册其他规则");
        return NO;
    }
    
    //判断是否已注册
    NSString *pattern = [NSString stringWithFormat:@"%@://%@/", scheme, host];
    XLRouterHandler block = self.routes[pattern];
    if (block)
    {
        NSLog(@"该规则=>%@ 已经注册了，请更换其他规则", pattern);
        return NO;
    }
    
    //保存协议和回调
    self.routes[pattern] = [handlerBlock copy];
    return YES;
}

#pragma mark - 移除路由

//删除由-addRouterWithScheme:handler:方法注册的规则
- (void)removeRouterWithScheme:(NSString *)scheme completion:(XLRouterRemoveCompletion)removeCompletion
{
    //路由未锁定，不能单独删除scheme
    if (!self.isSchemeLocked)
    {
        NSLog(@"移除失败，该schme：%@不是锁定的，请使用removeRouteWithScheme: withHost: completion方法移除", scheme);
        removeCompletion(NO,self.routes);
        return;
    }
    
    //删除并回调
    [self.routes removeObjectForKey:scheme];
    removeCompletion(YES, self.routes);
}

//移除由-addRouterWithScheme:withHost:handler:方法注册的规则
- (void)removeRouterWithScheme:(NSString *)scheme withHost:(NSString *)host completion:(nonnull XLRouterRemoveCompletion)removeCompletion
{
    //路由已锁定scheme，不能删除
    if (self.isSchemeLocked)
    {
        NSLog(@"移除失败，该schme：%@为锁定的，请使用removeRouteWithScheme移除", scheme);
        removeCompletion(NO,self.routes);
        return;
    }
    
    //判断路由是否存在
    NSString *pattern = [NSString stringWithFormat:@"%@://%@/", scheme, host];
    XLRouterHandler block = self.routes[pattern];
    if (!block)
    {
        NSLog(@"该规则=>%@ 不存在，无法移除", pattern);
        removeCompletion(NO,self.routes);
        return;
    }
    
    //删除并回调
    [self.routes removeObjectForKey:pattern];
    removeCompletion(YES,self.routes);
}

#pragma mark - 执行路由

//判断是否可以打开该URL
- (BOOL)canOpenURL:(NSURL *)URL
{
    //判断是否是scheme锁定路由
    NSString *scheme = [URL.scheme lowercaseString];
    if (self.isSchemeLocked)
    {
        XLRouterHandler block = self.routes[scheme];
        if (block)
        {
            return YES;
        }
        return NO;
    }
    
    //如果url没有host，中断
    NSString *host = URL.host;
    if (!host)
    {
        return NO;
    }
    
    //判断是否是scheme+host路由
    host = [host lowercaseString];
    NSString *pattern = [NSString stringWithFormat:@"%@://%@/", scheme, host];
    XLRouterHandler block = self.routes[pattern];
    if (block)
    {
        return YES;
    }
    return NO;
}

//路由打开某个URL
- (BOOL)openURL:(NSURL *)URL
{
    return [self openURL:URL completion:nil];
}

//路由打开某个URL
- (BOOL)openURL:(NSURL *)URL completion:(nullable XLRouterOpenCompletion)completion
{
    return [self openURL:URL withUserInfo:nil completion:completion];
}

//路由打开某个URL
- (BOOL)openURL:(NSURL *)URL withUserInfo:(nullable NSDictionary *)userInfo completion:(nullable XLRouterOpenCompletion)completion
{
    //判断是否是scheme锁定路由，如果是则执行
    NSString *scheme = [URL.scheme lowercaseString];
    if (self.isSchemeLocked)
    {
        XLRouterHandler block = self.routes[scheme];
        if (block)
        {
            block(URL, userInfo, completion);
            return YES;
        }
        return NO;
    }
    
    //如果url没有host，中断
    NSString *host = URL.host;
    if (!host)
    {
        return NO;
    }
    
    //判断是否是scheme+host路由，如果是则执行
    host = [host lowercaseString];
    NSString *pattern = [NSString stringWithFormat:@"%@://%@/", scheme, host];
    XLRouterHandler block = self.routes[pattern];
    if (block)
    {
        block(URL, userInfo, completion);
        return YES;
    }
    return NO;
}

@end
