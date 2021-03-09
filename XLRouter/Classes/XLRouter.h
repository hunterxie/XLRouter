//
//  XLRouter.h
//  Pods-XLRouter_Example
//
//  Created by xll on 2021/3/9.
//

#import <Foundation/Foundation.h>
#import "XLRouterManager.h"
NS_ASSUME_NONNULL_BEGIN

/**
 * 删除路由规则结果回调
 * @param isSucc 是否删除成功
 * @param routes 当前路由表
 */
typedef void (^XLRouterRemoveCompletion)(BOOL isSucc, NSDictionary *routes);

@interface XLRouter : NSObject

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (instancetype)new UNAVAILABLE_ATTRIBUTE;

/**
 * 当前router对应scheme
 */
@property (nonatomic, copy, readonly) NSString *scheme;

/**
 * 以scheme初始化一个实例，且设置是否锁定匹配
 * @param scheme         路由scheme
 * @param isSchemeLocked 是否锁定当前scheme 无法再注册其他规则
 * @return router
 */
+ (instancetype)routerForScheme:(NSString *)scheme isSchemeLocked:(BOOL)isSchemeLocked;

#pragma mark - 添加路由

/**
 * 注册一个scheme规则。使用该方式注册会使当前路由锁定，符合此scheme的url直接回调handler处理。解析时优先判断该方式注册的规则
 * @param scheme       scheme
 * @param handlerBlock 回调，不能为空，否则会导致注册失败，因为没有实际意义
 * @return 是否注册成功
 */
- (BOOL)addRouterWithScheme:(NSString *)scheme handler:(_Nonnull XLRouterHandler)handlerBlock;

/**
 * 注册一个规则，指定scheme和host，当目标url符合当前scheme和host则执行handlerBlock
 * 示例：scheme=> xll,  host=> module,可解析目标url=> xll://module/xxxxx?xx=xx
 * @param scheme       如xll
 * @param host         module，可以根据业务模块划分
 * @param handlerBlock 回调，不能为空，否则会导致注册失败，因为没有实际意义
 * @return 是否注册成功
 */
- (BOOL)addRouterWithScheme:(NSString *)scheme withHost:(NSString *)host handler:(_Nonnull XLRouterHandler)handlerBlock;

#pragma mark - 移除路由

/**
 * 删除由-addRouterWithScheme:handler:方法注册的规则
 * @param scheme           scheme
 * @param removeCompletion 回调
 */
- (void)removeRouterWithScheme:(NSString *)scheme completion:(_Nonnull XLRouterRemoveCompletion)removeCompletion;

/**
 * 移除由-addRouterWithScheme:withHost:handler:方法注册的规则
 * @param scheme           scheme
 * @param host             host
 * @param removeCompletion 回调
 */
- (void)removeRouterWithScheme:(NSString *)scheme withHost:(NSString *)host completion:(_Nonnull XLRouterRemoveCompletion)removeCompletion;

#pragma mark - 执行路由

/**
 * 判断是否可以打开该URL
 * @param URL 带有scheme的URL
 * @return 是否可以打开该URL
 */
- (BOOL)canOpenURL:(NSURL *)URL;

/**
 * 路由打开某个URL
 * @param URL 带有scheme的URL
 * @return 是否打开成功
 */
- (BOOL)openURL:(NSURL *)URL;

/**
 * 路由打开某个URL
 * @param URL        带有scheme的URL
 * @param completion 路由调用完成回调
 * @return 是否打开成功
 */
- (BOOL)openURL:(NSURL *)URL completion:(nullable XLRouterOpenCompletion)completion;

/**
 * 路由打开某个URL
 * @param URL        带有scheme的URL
 * @param userInfo   除url信息之外，可传入字典，在注册方法中取出该字典
 * @param completion 路由调用完成回调
 * @return 是否打开成功
 */
- (BOOL)openURL:(NSURL *)URL withUserInfo:(nullable NSDictionary *)userInfo completion:(nullable XLRouterOpenCompletion)completion;

@end

NS_ASSUME_NONNULL_END
