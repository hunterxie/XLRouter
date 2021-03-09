//
//  XLRouterManager.h
//  Pods-XLRouter_Example
//
//  Created by xll on 2021/3/9.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * 路由打开完成回调
 * @param isSucc 是否成功
 * @param data   返回数据
 */
typedef void (^XLRouterOpenCompletion)(BOOL isSucc, id data);

/**
 * 路由规则回调
 * @param url                  带有scheme的URL
 * @param userInfo             除url信息之外，可传入字典，在注册方法中取出该字典
 * @param routerOpenCompletion 路由打开完成回调
 */
typedef void (^XLRouterHandler)(NSURL *url, NSDictionary *userInfo, XLRouterOpenCompletion routerOpenCompletion);

@interface XLRouterManager : NSObject

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (instancetype)new UNAVAILABLE_ATTRIBUTE;

#pragma mark - 添加路由

/**
 * 注册一个scheme规则。使用该方式注册会使当前路由锁定，符合此scheme的url直接回调handler处理。解析时优先判断该方式注册的规则。
 * @param scheme       scheme
 * @param handlerBlock 回调，不能为空，否则会导致注册失败，因为没有实际意义
 * @return 是否注册成功
 */
+ (BOOL)addRouteWithScheme:(NSString *)scheme handler:(_Nonnull XLRouterHandler)handlerBlock;

/**
 * 注册一个规则，指定scheme和host，当目标url符合当前scheme和host则执行handlerBlock
 * 示例：scheme=> xll,  host=> module,可解析目标url=> xll://module/xxxxx?xx=xx
 * @param scheme       如xll
 * @param host         module
 * @param handlerBlock 回调，不能为空，否则会导致注册失败，因为没有实际意义
 * @return 是否注册成功
 */
+ (BOOL)addRouteWithScheme:(NSString *)scheme withHost:(NSString *)host handler:(_Nonnull XLRouterHandler)handlerBlock;

#pragma mark - 移除路由

/**
 * 移除由+addRouteWithScheme:handler:方式注册的规则
 * @param scheme scheme
 */
+ (void)removeRouteWithScheme:(NSString *)scheme;

/**
 * 移除由+addRouteWithScheme:withHost:handler:注册的规则
 * @param scheme scheme
 * @param host   host
 */
+ (void)removeRouteWithScheme:(NSString *)scheme withHost:(NSString *)host;

#pragma mark - 执行路由

/**
 * 判断是否可以打开该URL
 * @param URL 带有scheme的URL
 * @return 是否可以打开该URL
 */
+ (BOOL)canOpenURL:(NSURL *)URL;

/**
 * 路由打开某个URL
 * @param URL 带有scheme的URL，如： xll://module/action?name=xiaoming
 * @return 是否执行
 */
+ (BOOL)openURL:(NSURL *)URL;

/**
 * 路由打开某个URL可附带对象
 * @param URL      带有scheme的URL，如： xll://module/action?name=xiaoming
 * @param userInfo 除url信息之外，可传入字典，在注册方法中取出该字典
 * @return 是否执行
 */
+ (BOOL)openURL:(NSURL *)URL withUserInfo:(nullable NSDictionary *)userInfo;

/**
 * 路由打开某个URL
 * @param URL        带有scheme的URL，如： xll://module/action?name=xiaoming
 * @param userInfo   除url信息之外，可传入字典，在注册方法中取出该字典
 * @param completion 路由调用完成回调
 * @return 是否执行
 */
+ (BOOL)openURL:(NSURL *)URL withUserInfo:(nullable NSDictionary *)userInfo completion:(nullable XLRouterOpenCompletion)completion;

#pragma mark - 工具方法

/**
 * 快捷创建url
 * @param scheme 协议
 * @return url对象
*/
+ (NSURL *)urlWithScheme:(NSString *)scheme;

/**
 * 快捷创建url
 * @param scheme 协议
 * @param host   域
 * @return url对象
*/
+ (NSURL *)urlWithScheme:(NSString *)scheme host:(NSString *)host;

@end

NS_ASSUME_NONNULL_END
