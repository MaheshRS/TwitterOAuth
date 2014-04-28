//
//  Twitter.h
//  Twitter Sample
//
//  Created by Mahesh on 3/20/14.
//  Copyright (c) 2014 Mahesh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TwitterUser.h"

typedef void (^twitterAccessCallback)(BOOL success, NSDictionary *result);
typedef void (^twitterQueryCallback)(BOOL success, NSDictionary *result);

extern NSString * const kTwitterConsumerKey;
extern NSString * const kTwitterSecretKey;
extern NSString * const kTwittercallback;

@interface Twitter : NSObject

@property(nonatomic, strong)TwitterUser *user;

// return Twitter object instance
+ (instancetype)twitter;
// connect to twitter
- (void)connect:(twitterAccessCallback)callback;
// update the token from the URL query
- (void)parseAuthenticationCredentialsWithURLQuery:(NSString *)query;

// get friends list
- (void)getFriendsList:(twitterQueryCallback)callBack withParameters:(NSDictionary *)dict;

@end
