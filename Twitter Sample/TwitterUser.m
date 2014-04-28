//
//  TwitterUser.m
//  Twitter Sample
//
//  Created by Mahesh on 3/21/14.
//  Copyright (c) 2014 Mahesh. All rights reserved.
//

#import "TwitterUser.h"

@implementation TwitterUser

- (void)updateUserWithResponse:(NSString *)string
{
    NSArray *array = [string componentsSeparatedByString:@"&"];
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:array.count];
    
    for (NSString *valueString in array)
    {
        NSArray *valueArray = [valueString componentsSeparatedByString:@"="];
        [dictionary setObject:valueArray[1] forKey:valueArray[0]];
    }
    
    _accessToken = dictionary[@"oauth_token"];
    _accessSecret = dictionary[@"oauth_token_secret"];
    _screenName = dictionary[@"screen_name"];
}

@end
