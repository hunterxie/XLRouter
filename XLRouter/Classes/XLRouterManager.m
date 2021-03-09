//
//  XLRouterManager.m
//  Pods-XLRouter_Example
//
//  Created by xll on 2021/3/9.
//

#import "XLRouterManager.h"
#import "XLRouter.h"

@interface XLRouterManager()

//不允许注册或者解析的scheme，比如一些通用的协议：http、https、ftp....
@property(nonatomic,strong) NSArray <NSString *> *ignoreSchemeArray;

//路由字典
@property(nonatomic,strong) NSMutableDictionary <NSString *, XLRouter *> *routeMap;

//路由字典同步锁
@property(nonatomic,strong) NSLock *routeMapLock;

@end

@implementation XLRouterManager

#pragma mark - 初始化

//单例工厂方法
+ (XLRouterManager *)sharedRouteManager
{
    static XLRouterManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        instance = [[XLRouterManager alloc]init];
    });
    return instance;
}

//初始化
- (instancetype)init
{
    if ((self = [super init]))
    {
        //初始化缓存和同步锁
        self.routeMap = [NSMutableDictionary dictionaryWithCapacity:0];
        self.routeMapLock = [[NSLock alloc]init];
        self.routeMapLock.name = @"xlrouter.routemanager.routemap.lock";
        
        //初始化通用协议列表，不允许注册
        self.ignoreSchemeArray = @[@"http",@"https",@"ftp",@"ssh",@"smtp",@"xmpp",@"sip",@"dns",
                                   @"dhcp",@"dns",@"gopher",@"imap4",@"irc",@"nntp",@"pop3",@"snmp",
                                   @"ssh",@"telnet",@"rpc",@"rtcp",@"rtp",@"rtsp",@"sdp",@"soap",@"gtp",
                                   @"stun",@"ntp",@"ssdp",@"bgp",@"rip"];
    }
    return self;
}

#pragma mark - 添加路由

//注册一个scheme规则。使用该方式注册会使当前路由锁定，符合此scheme的url直接回调handler处理。解析时优先判断该方式注册的规则。
+ (BOOL)addRouteWithScheme:(NSString *)scheme handler:(XLRouterHandler)handlerBlock
{
    //非法判断
    scheme = [scheme lowercaseString];
    if (scheme == nil || [scheme isKindOfClass:[NSString class]] == NO || scheme.length == 0)
    {
        NSLog(@"scheme为空，无法注册");
        return NO;
    }
    if ([[scheme stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] == 0)
    {
        NSLog(@"scheme为空，无法注册");
        return NO;
    }
    if ([self checkIfContainsSpecialCharacter:scheme])
    {
        NSLog(@"scheme中含有非法字符,以下字符”%@“中的一种，不允许注册", specialCharacters);
        return NO;
    }
    if ([[XLRouterManager sharedRouteManager].ignoreSchemeArray indexOfObject:scheme] != NSNotFound)
    {
        NSLog(@"%@为互联网通用的协议scheme，不允许注册", scheme);
        return NO;
    }
    
    //判断是否已经被注册
    [[XLRouterManager sharedRouteManager].routeMapLock lock];
    XLRouter *router = [XLRouterManager sharedRouteManager].routeMap[scheme];
    [[XLRouterManager sharedRouteManager].routeMapLock unlock];
    if (router)
    {
        NSLog(@"%@已经被其他规则注册，无法再注册", scheme);
        return NO;
    }
    
    //初始化新路由
    router = [XLRouter routerForScheme:scheme isSchemeLocked:YES];
    
    //保存路由对象
    [[XLRouterManager sharedRouteManager].routeMapLock lock];
    [[XLRouterManager sharedRouteManager].routeMap setObject:router forKey:scheme];
    [[XLRouterManager sharedRouteManager].routeMapLock unlock];
    
    //创建路由规则
    return [router addRouterWithScheme:scheme handler:handlerBlock];
}

//注册一个规则，指定scheme和host，当目标url符合当前scheme和host则执行handlerBlock
+ (BOOL)addRouteWithScheme:(NSString *)scheme withHost:(NSString *)host handler:(XLRouterHandler)handlerBlock
{
    //非法判断
    scheme = [scheme lowercaseString];
    host = [host lowercaseString];
    if (scheme == nil || [scheme isKindOfClass:[NSString class]] == NO || scheme.length == 0)
    {
        NSLog(@"scheme为空，无法注册");
        return NO;
    }
    if ([[scheme stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] == 0)
    {
        NSLog(@"scheme为空，无法注册");
        return NO;
    }
    if ([self checkIfContainsSpecialCharacter:scheme])
    {
        NSLog(@"scheme中含有非法字符,以下字符”%@“中的一种，不允许注册", specialCharacters);
        return NO;
    }
    if ([[XLRouterManager sharedRouteManager].ignoreSchemeArray indexOfObject:scheme] != NSNotFound)
    {
        NSLog(@"%@为互联网通用的协议scheme，不允许注册", scheme);
        return NO;
    }
    if (host == nil || [host isKindOfClass:[NSString class]] == NO || host.length == 0)
    {
        NSLog(@"host为空，无法注册");
        return NO;
    }
    if ([[host stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] == 0)
    {
        NSLog(@"host为空，无法注册");
        return NO;
    }
    if ([self checkIfContainsSpecialCharacter:host])
    {
        NSLog(@"host中含有非法字符,以下字符”%@“中的一种，不允许注册", specialCharacters);
        return NO;
    }
    
    //获取缓存路由对象，如果不存在缓存路由对象，则创建一个
    [[XLRouterManager sharedRouteManager].routeMapLock lock];
    XLRouter *router = [XLRouterManager sharedRouteManager].routeMap[scheme];
    [[XLRouterManager sharedRouteManager].routeMapLock unlock];
    if (!router)
    {
        router = [XLRouter routerForScheme:scheme isSchemeLocked:NO];
        [[XLRouterManager sharedRouteManager].routeMapLock lock];
        [[XLRouterManager sharedRouteManager].routeMap setObject:router forKey:scheme];
        [[XLRouterManager sharedRouteManager].routeMapLock unlock];
    }
    
    //创建路由规则
    return [router addRouterWithScheme:scheme withHost:host handler:handlerBlock];
}

#pragma mark - 移除路由

//移除由+addRouteWithScheme:handler:方式注册的规则
+ (void)removeRouteWithScheme:(NSString *)scheme
{
    //非法判断
    scheme = [scheme lowercaseString];
    if (scheme == nil || [scheme isKindOfClass:[NSString class]] == NO || scheme.length == 0)
    {
        NSLog(@"schme为空，移除失败");
        return;
    }
    
    //判断路由是否存在
    [[XLRouterManager sharedRouteManager].routeMapLock lock];
    XLRouter *router = [XLRouterManager sharedRouteManager].routeMap[scheme];
    [[XLRouterManager sharedRouteManager].routeMapLock unlock];
    if (!router)
    {
        NSLog(@"移除失败，未找到注册的schme：%@", scheme);
        return;
    }
    
    //删除路由
    [router removeRouterWithScheme:scheme completion:^(BOOL isSucc, NSDictionary * _Nonnull routes)
    {
        if (isSucc && routes && routes.allKeys.count == 0)
        {
            [[XLRouterManager sharedRouteManager].routeMapLock lock];
            [[XLRouterManager sharedRouteManager].routeMap removeObjectForKey:scheme];
            [[XLRouterManager sharedRouteManager].routeMapLock unlock];
        }
    }];
}

//移除由+addRouteWithScheme:withHost:handler:注册的规则
+ (void)removeRouteWithScheme:(NSString *)scheme withHost:(NSString *)host
{
    //非法判断
    scheme = [scheme lowercaseString];
    host = [host lowercaseString];
    if (scheme == nil || [scheme isKindOfClass:[NSString class]] == NO || scheme.length == 0)
    {
        NSLog(@"schme为空，移除失败");
        return;
    }
    if (host == nil || [host isKindOfClass:[NSString class]] == NO || host.length == 0)
    {
        NSLog(@"host为空，移除失败");
        return;
    }
    
    //判断路由是否存在
    [[XLRouterManager sharedRouteManager].routeMapLock lock];
    XLRouter *router = [XLRouterManager sharedRouteManager].routeMap[scheme];
    [[XLRouterManager sharedRouteManager].routeMapLock unlock];
    if (!router)
    {
        NSLog(@"移除失败，未找到注册的schme：%@", scheme);
        return;
    }
    
    //删除路由
    [router removeRouterWithScheme:scheme withHost:host completion:^(BOOL isSucc, NSDictionary * _Nonnull routes)
    {
        if (isSucc && routes && routes.allKeys.count == 0)
        {
            [[XLRouterManager sharedRouteManager].routeMapLock lock];
            [[XLRouterManager sharedRouteManager].routeMap removeObjectForKey:scheme];
            [[XLRouterManager sharedRouteManager].routeMapLock unlock];
        }
    }];
}

#pragma mark - 执行路由

//判断是否可以打开该URL
+ (BOOL)canOpenURL:(NSURL *)URL
{
    //非法判断
    if (!URL)
    {
        NSLog(@"URL为空");
        return NO;
    }
    if (![URL isKindOfClass:[NSURL class]])
    {
        NSLog(@"当前路由url格式错误，不是NSURL");
        return NO;
    }
    NSString *scheme = [URL.scheme lowercaseString];
    if (!scheme)
    {
        NSLog(@"scheme未找到，无法打开%@", URL);
    }
    if ([[XLRouterManager sharedRouteManager].ignoreSchemeArray indexOfObject:scheme] != NSNotFound)
    {
        NSLog(@"%@为互联网通用的协议scheme，不支持路由", scheme);
        return NO;
    }
    
    //判断路由是否存在
    [[XLRouterManager sharedRouteManager].routeMapLock lock];
    XLRouter *router = [[XLRouterManager sharedRouteManager].routeMap objectForKey:scheme];
    [[XLRouterManager sharedRouteManager].routeMapLock unlock];
    if (!router)
    {
        return NO;
    }
    
    //判断规则是否支持
    return [router canOpenURL:URL];
}

//路由打开某个URL
+ (BOOL)openURL:(NSURL *)URL
{
    return [XLRouterManager openURL:URL withUserInfo:nil];
}

//路由打开某个URL
+ (BOOL)openURL:(NSURL *)URL withUserInfo:(NSDictionary *)userInfo
{
    return [XLRouterManager openURL:URL withUserInfo:userInfo completion:nil];
}

//路由打开某个URL
+ (BOOL)openURL:(NSURL *)URL withUserInfo:(NSDictionary *)userInfo completion:(nullable XLRouterOpenCompletion)completion
{
    //非法判断
    if (!URL)
    {
        NSLog(@"URL为空");
        return NO;
    }
    if (![URL isKindOfClass:[NSURL class]])
    {
        NSLog(@"当前路由url格式错误，不是NSURL");
        return NO;
    }
    NSString *scheme = URL.scheme.lowercaseString;
    if (!scheme)
    {
        NSLog(@"scheme未找到，无法打开%@",URL);
    }
    if ([[XLRouterManager sharedRouteManager].ignoreSchemeArray indexOfObject:scheme] != NSNotFound)
    {
        NSLog(@"%@为互联网通用的协议scheme，不支持路由",scheme);
        return NO;
    }
    
    //判断路由是否存在
    [[XLRouterManager sharedRouteManager].routeMapLock lock];
    XLRouter *router = [[XLRouterManager sharedRouteManager].routeMap objectForKey:scheme];
    [[XLRouterManager sharedRouteManager].routeMapLock unlock];
    if (!router)
    {
        NSLog(@"没有找到对应的Router");
        return NO;
    }
    
    //执行路由规则
    return [router openURL:URL withUserInfo:userInfo completion:completion];
}

#pragma mark - 工具方法

//快捷创建url
+ (NSURL *)urlWithScheme:(NSString *)scheme
{
    return [NSURL URLWithString:[NSString stringWithFormat:@"%@://", scheme]];
}

//快捷创建url
+ (NSURL *)urlWithScheme:(NSString *)scheme host:(NSString *)host
{
    return [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@/", scheme, host]];
}

//特殊字符列表
static NSString *specialCharacters = @"/?&#!~@$￥%^&*()_-+=`:<>|,.？，。；‘【】、「」{}《》";

//判断字符串中是否含有特殊字符
+ (BOOL)checkIfContainsSpecialCharacter:(NSString *)checkedString
{
    NSCharacterSet *specialCharactersSet = [NSCharacterSet characterSetWithCharactersInString:specialCharacters];
    return [checkedString rangeOfCharacterFromSet:specialCharactersSet].location != NSNotFound;
}

@end
