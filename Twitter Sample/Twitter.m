//
//  Twitter.m
//  Twitter Sample
//
//  Created by Mahesh on 3/20/14.
//  Copyright (c) 2014 Mahesh. All rights reserved.
//

#import "Twitter.h"
#import <CoreFoundation/CFUUID.h>
#import <CommonCrypto/CommonHMAC.h>
#import <CommonCrypto/CommonDigest.h>

#warning replace the kTwitterConsumerKey and kTwitterSecretKey with your app specific key
NSString * const kTwitterConsumerKey = @"";
NSString * const kTwitterSecretKey = @"";
NSString * const kTwittercallback = @"stoned://twitter-callback";

@interface Twitter()

@property(nonatomic, strong)NSURLSession *session;
@property(nonatomic, strong)NSString *requestToken;
@property(nonatomic, strong)NSString *authVerifier;

@property(nonatomic, copy)twitterAccessCallback callback;

@end

@implementation Twitter

- (id)init
{
    self = [super init];
    if(self)
    {
        [self initSession];
        _user = [[TwitterUser alloc]init];
    }
    
    return self;
}

+ (instancetype)twitter
{
    Twitter *object = [[Twitter alloc]init];
    return object;
}

#pragma mark - NSURLSession
- (void)initSession
{
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    self.session = [NSURLSession sessionWithConfiguration:config];
}

#pragma mark - Connect
- (void)connect:(twitterAccessCallback)callback
{
    self.callback = callback;
    
    NSDictionary *oauthParameters = [self oauthRequestParameters];
    
    
    typeof(self) __weak weakself = self;
    
    NSString *signature = [self signatureWithUrl:@"https://api.twitter.com/oauth/request_token" method:@"POST" parameters:oauthParameters];
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithDictionary:oauthParameters];
    [dictionary setObject:signature forKey:@"oauth_signature"];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://api.twitter.com/oauth/request_token"]];
    [request setHTTPMethod:@"POST"];
    
    NSString *header = [@"OAuth " stringByAppendingString:[self stringFromParameters:dictionary combinedWithString:@","]];
    [request setValue:header forHTTPHeaderField:@"Authorization"];
    
    NSURLSessionDataTask *dataTask = [self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSLog(@"Value %@",[[NSMutableString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        [weakself authenticateWithParameters:[self dictionaryFromRequestTokenCallBackString:[[NSMutableString alloc] initWithData:data encoding:NSUTF8StringEncoding]]];
    }];
    
    [dataTask resume];
}

#pragma mark - Twitter Parameteres
- (NSDictionary *)oauthRequestParameters
{
    /* oauth_nonce="K7ny27JTpKVsTgdyLdDfmQQWVLERj2zAK5BslRsqyw",
       oauth_callback="http%3A%2F%2Fmyapp.com%3A3005%2Ftwitter%2Fprocess_callback",
       oauth_signature_method="HMAC-SHA1", oauth_timestamp="1300228849",
       oauth_consumer_key="OqEqJeafRSF11jBMStrZz",
       oauth_signature="Pc%2BMLdv028fxCErFyi8KXFM%2BddU%3D",
       oauth_version="1.0" */
    
    NSDictionary *oauthParameters = @{
                                      @"oauth_consumer_key"     : kTwitterConsumerKey,
                                      @"oauth_nonce"            : [self nonce],
                                      @"oauth_signature_method" : @"HMAC-SHA1",
                                      @"oauth_timestamp"        : [self timeStamp],
                                      @"oauth_version"          : @"1.0",
                                      @"oauth_callback"         : kTwittercallback};
    
    return oauthParameters;
}

- (NSString *)nonce
{
    CFUUIDRef uuidRef = CFUUIDCreate(kCFAllocatorDefault);
    NSString *uuid = (__bridge_transfer NSString*)CFUUIDCreateString(kCFAllocatorDefault, uuidRef);
    
    if(uuid.length > 32)
        return [uuid substringWithRange:NSMakeRange(0, 32)];
    
    return uuid;
}

- (NSString *)tokenSecret
{
    if(self.user.accessSecret.length >0)
        return self.user.accessSecret;
    
    return nil;
}

- (NSString *)timeStamp
{
    return [NSString stringWithFormat:@"%d",(int)[[NSDate date] timeIntervalSince1970]];
}

- (NSString *)signHMACSHAIWithKey:(NSString *)key value:(NSString *)value
{
    unsigned char buf[CC_SHA1_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA1, [key UTF8String], [key length], [value UTF8String], [value length], buf);
    NSData *data = [NSData dataWithBytes:buf length:CC_SHA1_DIGEST_LENGTH];
    return [data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
}

- (NSString *)encodeString:(NSString *)string
{
    NSString *s = (__bridge_transfer NSString *)(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                                         (CFStringRef)string,
                                                                                         NULL,
                                                                                         CFSTR("!*'();:@&=+$,/?%#[]"),
                                                                                         kCFStringEncodingUTF8));
    return s;
}

- (NSString *)signatureWithUrl:(NSString *)url method:(NSString *)method parameters:(NSDictionary *)parameters
{
    NSMutableArray *mutableArray = [NSMutableArray arrayWithCapacity:parameters.count];
    NSArray *keys = [[parameters allKeys] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj1 compare:obj2];
    }];
    
    for(NSString *key in keys)
    {
        NSString *s = [NSString stringWithFormat:@"%@=%@",[self encodeString:key],[self encodeString:parameters[key]]];
        [mutableArray addObject:s];
    }
    
    NSString *encodedParameters = [mutableArray componentsJoinedByString:@"&"];
    NSString *baseString = [NSString stringWithFormat:@"%@&%@&%@",[method uppercaseString],[self encodeString:url],[self encodeString:encodedParameters]];
    
    NSString *encodedConsumerSecret = [self encodeString:kTwitterSecretKey];
    NSString *encodedTokenSecret = [self encodeString:[self tokenSecret]];
    NSString *signinKey = nil;
    
    if(encodedTokenSecret)
        signinKey = [encodedConsumerSecret stringByAppendingString:[NSString stringWithFormat:@"&%@",encodedTokenSecret]];
    else
        signinKey = [encodedConsumerSecret stringByAppendingString:@"&"];
    
    NSString *signature = [self signHMACSHAIWithKey:signinKey value:baseString];
    
    return signature;
}

- (NSString *)signatureMethodWithUrl:(NSString *)baseUrl method:(NSString *)method parameters:(NSDictionary *)parameters
{
    NSMutableArray *mutableArray = [NSMutableArray arrayWithCapacity:parameters.count];
    NSArray *keys = [[parameters allKeys] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj1 compare:obj2];
    }];
    
    for(NSString *key in keys)
    {
        NSString *s = [NSString stringWithFormat:@"%@=%@",[self encodeString:key],[self encodeString:parameters[key]]];
        [mutableArray addObject:s];
    }
    
    NSString *encodedParameters = [mutableArray componentsJoinedByString:@"&"];
    NSString *baseString = [NSString stringWithFormat:@"%@&%@&%@",[method uppercaseString],[self encodeString:baseUrl],[self encodeString:encodedParameters]];
    
    NSString *encodedConsumerSecret = [self encodeString:kTwitterSecretKey];
    NSString *encodedTokenSecret = [self encodeString:[self tokenSecret]];
    NSString *signinKey = nil;
    
    if(encodedTokenSecret)
        signinKey = [encodedConsumerSecret stringByAppendingString:[NSString stringWithFormat:@"&%@",encodedTokenSecret]];
    else
        signinKey = [encodedConsumerSecret stringByAppendingString:@"&"];
    
    NSString *signature = [self signHMACSHAIWithKey:signinKey value:baseString];
    
    return signature;
}

- (NSString *)stringFromParameters:(NSMutableDictionary *)param combinedWithString:(NSString *)combiningString
{
    NSMutableArray *keyList = [NSMutableArray arrayWithArray:[param allKeys]];
    [keyList sortUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
        return [obj1 compare:obj2];
    }];
    
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:keyList.count];
    
    for(NSString *key in keyList)
    {
        NSString *paramPair = [NSString stringWithFormat:@"%@=\"%@\"",[self encodeString:key],[self encodeString:param[key]]];
        [array addObject:paramPair];
    }
    
    return [array componentsJoinedByString:combiningString];
}

#pragma mark - Authetication
- (NSDictionary *)dictionaryFromRequestTokenCallBackString:(NSString *)string
{
    NSArray *array = [string componentsSeparatedByString:@"&"];
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:array.count];
    
    for(NSString *str in array)
    {
        NSArray *values = [str componentsSeparatedByString:@"="];
        [dictionary setObject:values[1] forKey:values[0]];
    }
    
    return dictionary;
}

- (void)authenticateWithParameters:(NSDictionary *)parameters
{
    NSString *baseUrlString = @"https://api.twitter.com/oauth/authenticate?";
    baseUrlString = [baseUrlString stringByAppendingString:[NSString stringWithFormat:@"oauth_token=%@",parameters[@"oauth_token"]]];
    baseUrlString = [baseUrlString stringByAppendingString:[NSString stringWithFormat:@"&force_login=false"]];
    baseUrlString = [baseUrlString stringByAppendingString:[NSString stringWithFormat:@"&oauth_callback_confirmed=true"]];
    
    // get the url
    NSURL *url = [NSURL URLWithString:baseUrlString];
    [[UIApplication sharedApplication]openURL:url];
}

#pragma mark - Access Token
- (void)parseAuthenticationCredentialsWithURLQuery:(NSString *)query
{
    NSArray *array = [query componentsSeparatedByString:@"&"];
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:array.count];
    
    for(NSString *string in array)
    {
        NSArray *values = [string componentsSeparatedByString:@"="];
        [dictionary setValue:[values[1] stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]] forKey:values[0]];
    }
    
    self.requestToken = dictionary[@"oauth_token"];
    self.authVerifier = dictionary[@"oauth_verifier"];
    
    // exchange requestToken with the access token
    [self retriveAccessToken];
}

- (void)retriveAccessToken
{
    NSString *urlString = [NSString stringWithFormat:@"%@?oauth_verifier=%@",@"https://api.twitter.com/oauth/access_token",self.authVerifier];
    
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithDictionary:[self oauthRequestParameters]];
    [dictionary setObject:self.requestToken forKey:@"oauth_token"];
    [dictionary setObject:[self signatureWithUrl:urlString method:@"POST" parameters:dictionary] forKey:@"oauth_signature"];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    [request setHTTPMethod:@"POST"];
    
    NSString *header = [@"OAuth " stringByAppendingString:[self stringFromParameters:dictionary combinedWithString:@","]];
    [request setValue:header forHTTPHeaderField:@"Authorization"];
    
    typeof(self) __weak weakself = self;
    
    NSURLSessionDataTask *dataTask = [self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSLog(@"Value %@",[[NSMutableString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        [weakself.user updateUserWithResponse:[[NSMutableString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
        
        weakself.callback(YES, @{});
    }];
    
    [dataTask resume];
}


#pragma mark - Twitter Data API's
- (void)getFriendsList:(twitterQueryCallback)callBack withParameters:(NSDictionary *)dict
{
    
    NSString *baseUrl = [NSString stringWithFormat:@"https://api.twitter.com/1.1/friends/list.json"];
    NSString *urlString = @"";
    
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithDictionary:[self oauthRequestParameters]];
    [dictionary setObject:self.user.accessToken forKey:@"oauth_token"];
    [dictionary setObject:self.user.screenName forKey:@"screen_name"];
    [dictionary setObject:@"-1" forKey:@"cursor"];
    [dictionary removeObjectForKey:@"oauth_callback"];
    
    [dictionary setObject:[self signatureMethodWithUrl:baseUrl method:@"GET" parameters:dictionary] forKey:@"oauth_signature"];
    
    [dictionary removeObjectForKey:@"cursor"];
    [dictionary removeObjectForKey:@"screen_name"];
    
    __block NSString *userParameters = @"";
    [dict enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL *stop) {
        
        if(userParameters.length > 0)
            userParameters = [userParameters stringByAppendingString:[NSString stringWithFormat:@"&%@=%@",key,obj]];
        else
            userParameters = [userParameters stringByAppendingString:[NSString stringWithFormat:@"%@=%@",key,obj]];
    }];
    
    urlString = [baseUrl stringByAppendingString:[NSString stringWithFormat:@"?%@",userParameters]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    [request setHTTPMethod:@"GET"];
    
    NSString *header = [@"OAuth " stringByAppendingString:[self stringFromParameters:dictionary combinedWithString:@","]];
    [request setValue:header forHTTPHeaderField:@"Authorization"];
    
    NSURLSessionDataTask *dataTask = [self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        callBack(YES, [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil]);
    }];
    
    [dataTask resume];
}

@end
