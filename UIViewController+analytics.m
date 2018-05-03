//
//  UIViewController+analytics.m
//  TGTA
//
//  Created by MacBook Pro on 2018/3/9.
//  Copyright © 2018年 trends. All rights reserved.
//

#import "UIViewController+analytics.h"
#import <objc/runtime.h>
#import <sys/utsname.h>
#import <Realm/Realm.h>
#import "CPIphoneModel.h"

#define DBNAME @"analytics"
#define EXTENSION @"realm"

@implementation UIViewController (analytics)

NSDictionary *_pageNameDic;
CFAbsoluteTime _StartTime;
CFAbsoluteTime _EndTime;

+(void)load {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"PageNameList" ofType:@".plist"];
    _pageNameDic = [NSDictionary dictionaryWithContentsOfFile:path];
    Method method1 = class_getInstanceMethod([self class], @selector(viewWillAppear:));
    Method method2 = class_getInstanceMethod([self class], @selector(my_viewWillAppear:));
    method_exchangeImplementations(method1, method2);
    
    Method method3 = class_getInstanceMethod([self class], @selector(viewWillDisappear:));
    Method method4 = class_getInstanceMethod([self class], @selector(my_viewWillDisappear:));
    method_exchangeImplementations(method3, method4);
}

-(void)my_viewWillAppear:(BOOL)animated {
    [self saveDataWithViewIsAppear:YES];
    [self my_viewWillAppear:animated];
}

-(void)my_viewWillDisappear:(BOOL)animated{
    [self saveDataWithViewIsAppear:NO];
    [self my_viewWillDisappear:animated];
}

-(void)saveDataWithViewIsAppear:(BOOL)isAppear {
    NSString *className = NSStringFromClass([self class]);
    if (_pageNameDic[className]) {
        
        // 生成数据库文件路径
        NSString *filePath = [self pathOfDBWithName:DBNAME andExtension:EXTENSION];
        
        // 根据路径创建数据库
        [self createDatabaseWithPath:filePath];
        
        // 获取当前设备基本信息
        struct utsname systemInfo;
        uname(&systemInfo);
        NSString *iphoneMachine = [NSString stringWithCString:systemInfo.machine encoding:NSASCIIStringEncoding];
        NSString *iphoneSys = [[UIDevice currentDevice] systemName];
        NSString *iphoneVersion = [[UIDevice currentDevice] systemVersion];
        
        // 判断当前页面是否将要销毁
        if (!isAppear) {
            
            // 记录当前页面销毁时刻的时间戳
            _EndTime = CFAbsoluteTimeGetCurrent();
            
            // 生成当前页面停留时间
            NSString *stayTime = [self timeOfStart:_StartTime subEndTime:_EndTime];
            
            // 整理当前浏览记录信息
            CPIphoneModel *model = [[CPIphoneModel alloc] init];
            model.pageID = className;
            model.pageName = _pageNameDic[className];
            model.iphoneMachine = iphoneMachine;
            model.iphoneSys = iphoneSys;
            model.iphoneVersion = iphoneVersion;
            model.stayTime = stayTime;
            
            // 根据路径拿取数据库对象
            RLMRealm *realm = [RLMRealm realmWithURL:[NSURL URLWithString:filePath]];
            [realm transactionWithBlock:^{
                // 添加浏览记录
                [realm addObject:model];
                {
//                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//                    [realm transactionWithBlock:^{
//                        [realm addObject:model];
//                    }];
//                });
            }
            }];
            NSLog(@"《%@》 消失。停留了%@", className, stayTime);
        }
        else {
            // 记录当前页面出现时刻的时间戳
            _StartTime = CFAbsoluteTimeGetCurrent();
            NSLog(@"《%@》 出现", className);
        }
    }
}

-(void)createDatabaseWithPath:(NSString *)filePath {
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
        config.fileURL = [NSURL URLWithString:filePath];
        [RLMRealmConfiguration setDefaultConfiguration:config];
        [RLMRealm defaultRealm];
    }
}

- (NSString *)pathOfDBWithName:(NSString *)name andExtension:(NSString *)extension{
    NSArray *docPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [docPath objectAtIndex:0];
    NSString *filePath = [[path stringByAppendingPathComponent:name] stringByAppendingPathExtension:extension];
    return filePath;
}

-(NSString *)timeOfStart:(CFAbsoluteTime)startTime subEndTime:(CFAbsoluteTime)endTime{
    int d_time = endTime - startTime;
    if (!(d_time/3600)) {
        if (!(d_time/60)) {
            return [NSString stringWithFormat:@"%d秒", d_time];
        }
        return [NSString stringWithFormat:@"%d分%d秒", d_time/60, d_time%60];
    }
    return [NSString stringWithFormat:@"%d时%d分%d秒", d_time/3600, d_time%3600/60, d_time%60];
}


@end
