//
//  CPIphoneModel.h
//  TGTA
//
//  Created by MacBook Pro on 2018/3/28.
//  Copyright © 2018年 trends. All rights reserved.
//

#import <Realm/Realm.h>

@interface CPIphoneModel : RLMObject

@property  NSString *pageID;
@property  NSString *pageName;
@property  NSString *iphoneMachine;
@property  NSString *iphoneSys;
@property  NSString *iphoneVersion;
@property  NSString *stayTime;

@end
