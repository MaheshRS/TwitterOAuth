//
//  TwitterUser.h
//  Twitter Sample
//
//  Created by Mahesh on 3/21/14.
//  Copyright (c) 2014 Mahesh. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TwitterUser : NSObject

@property(nonatomic, copy, readonly)NSString *accessToken;
@property(nonatomic, copy, readonly)NSString *accessSecret;
@property(nonatomic, copy, readonly)NSString *screenName;

- (void)updateUserWithResponse:(NSString *)string;

@end
