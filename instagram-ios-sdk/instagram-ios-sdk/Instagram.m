//
//  Instagram.m
//  instagram-ios-sdk
//
//  Created by Cristiano Severini on 18/04/12.
//  Copyright (c) 2012 IQUII. All rights reserved.
//

#import "Instagram.h"

#import "InstagramNotificationKeys.h"

static NSString* kDialogBaseURL         = @"https://instagram.com/";
static NSString* kRestserverBaseURL     = @"https://api.instagram.com/v1/";

static NSString* kLogin                 = @"oauth/authorize";

static NSString *requestFinishedKeyPath = @"state";
static void *finishedContext            = @"finishedContext";

static NSString *kInstagramAccessTokenKey = @"InstagramAccessToken";

@interface Instagram () <IGSessionDelegate>

@property(nonatomic, strong) NSArray* scopes;
@property(nonatomic, strong) NSString* clientId;

-(void)authorizeWithSafari;

@end


@implementation Instagram

+ (NSString *)cliendIdFromMainBundle
{
    NSArray *urlTypes = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleURLTypes"];
    
    if (![urlTypes count])
        return nil;
    
    // Get instagram url sceme
    __block NSArray *urlScemes = nil;
    [urlTypes enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([[obj objectForKey:@"CFBundleURLName"] isEqualToString:@"instagram_redirect_url"])
        {
            urlScemes = [obj objectForKey:@"CFBundleURLSchemes"];
            *stop = YES;
        }
    }];
    
    if (!urlScemes || 1 < [urlScemes count])
        return nil;
    
    NSString *urlSceme = [urlScemes firstObject];
    
    // crop id
    // format: ig[clientID]
    static NSString * const prefix = @"ig";
    
    NSMutableString *mutableString = [NSMutableString stringWithString:urlSceme];
    [mutableString deleteCharactersInRange:NSMakeRange(0, [prefix length])];
    
    return mutableString;
}

static Instagram *sharedInstance = nil;
+ (void)initSharedInstance
{
    if (sharedInstance)
    {
        [[NSException exceptionWithName:InstagramErrorDomain
                                 reason:@"Trying to re-initialize a shared instance"
                               userInfo:nil] raise];
    }
    
    NSString *clientId = [Instagram cliendIdFromMainBundle];
    
    if (!clientId)
    {
        [[NSException exceptionWithName:InstagramErrorDomain
                                 reason:@"Cannot find registered URL scheme for name: instagram_redirect_url"
                               userInfo:nil] raise];
    }
    
    sharedInstance = [[Instagram alloc] initWithClientId:clientId delegate:nil];
}

+ (instancetype)sharedInstance
{
    return sharedInstance;
}

@synthesize accessToken = _accessToken;
@synthesize sessionDelegate = _sessionDelegate;
@synthesize scopes = _scopes;
@synthesize clientId = _clientId;

-(id)initWithClientId:(NSString*)clientId delegate:(id<IGSessionDelegate>)delegate {
    self = [super init];
    if (self) {
        self.clientId = clientId;
        if (!delegate)
        {
            delegate = self;
        }
        self.sessionDelegate = delegate;
        _requests = [[NSMutableSet alloc] init];
    }
    return self;
}

- (void)dealloc {
    for (IGRequest* request in _requests) {
        @try {
            [_requests removeObserver:self forKeyPath:requestFinishedKeyPath];
        }
        @catch (NSException *exception) {
            NSLog(@"%@", exception);
        }
    }
}

#pragma mark - setters/getters
- (void)setAccessToken:(NSString *)accessToken
{
    [[NSUserDefaults standardUserDefaults] setObject:accessToken forKey:kInstagramAccessTokenKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *)accessToken
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:kInstagramAccessTokenKey];
}

#pragma mark - internal

-(void)invalidateSession {
    self.accessToken = nil;
    
    NSHTTPCookieStorage* cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray* instagramCookies = [cookies cookiesForURL:[NSURL URLWithString:kDialogBaseURL]];
    
    for (NSHTTPCookie* cookie in instagramCookies) {
        [cookies deleteCookie:cookie];
    }

    if ([self.sessionDelegate respondsToSelector:@selector(instagramSessionInvalidated:)]) {
        [self.sessionDelegate instagramSessionInvalidated:self];
    }
}

- (IGRequest*)openUrl:(NSString *)url
               params:(NSMutableDictionary *)params
           httpMethod:(NSString *)httpMethod
             delegate:(id<IGRequestDelegate>)delegate {
    if ([self isSessionValid]) {
        [params setValue:self.accessToken forKey:@"access_token"];
    }
    
    IGRequest* _request = [IGRequest getRequestWithParams:params
                                               httpMethod:httpMethod
                                                 delegate:delegate
                                               requestURL:url];
    [_requests addObject:_request];
    [_request addObserver:self forKeyPath:requestFinishedKeyPath options:0 context:finishedContext];
    [_request connect];
    return _request;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == finishedContext) {
        IGRequest* _request = (IGRequest*)object;
        IGRequestState requestState = [_request state];
        if (requestState == kIGRequestStateError) {
            NSString *errType = (NSString *)[[_request.error userInfo] objectForKey:@"error_type"];
            if (errType && [errType isEqualToString:@"OAuthAccessTokenException"]) {
                [self logout];
            }
//            [self invalidateSession];
//            if ([self.sessionDelegate respondsToSelector:@selector(igSessionInvalidated)]) {
//                [self.sessionDelegate igSessionInvalidated];
//            }
        }
        if (requestState == kIGRequestStateComplete || requestState == kIGRequestStateError) {
            [_request removeObserver:self forKeyPath:requestFinishedKeyPath];
            [_requests removeObject:_request];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (NSString *)getOwnBaseUrl {
    return [NSString stringWithFormat:@"ig%@://authorize", self.clientId];
}

/**
 * A private function for opening the authorization dialog.
 */
- (void)authorizeWithSafari {
    NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   self.clientId, @"client_id",
                                   @"token", @"response_type",
                                   [self getOwnBaseUrl], @"redirect_uri",
                                   nil];
    
    NSString *loginDialogURL    = [kDialogBaseURL stringByAppendingString:kLogin];
    
    if (self.scopes != nil) {
        NSString* scope = [self.scopes componentsJoinedByString:@"+"];
        [params setValue:scope forKey:@"scope"];
    }
    
    BOOL didOpenOtherApp        = NO;
    NSString *igAppUrl          = [IGRequest serializeURL:loginDialogURL params:params];
    didOpenOtherApp             = [[UIApplication sharedApplication] openURL:[NSURL URLWithString:igAppUrl]];
}

- (NSDictionary*)parseURLParams:(NSString *)query {
	NSArray *pairs = [query componentsSeparatedByString:@"&"];
	NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
	for (NSString *pair in pairs) {
		NSArray *kv = [pair componentsSeparatedByString:@"="];
		NSString *val = [[kv objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
		[params setObject:val forKey:[kv objectAtIndex:0]];
	}
    return params;
}

#pragma mark - public

-(void)authorize:(NSArray *)scopes {
    self.scopes = scopes;
    
    [self authorizeWithSafari];
}

- (BOOL)handleOpenURL:(NSURL *)url {
    // If the URL's structure doesn't match the structure used for Instagram authorization, abort.
    if (![[url absoluteString] hasPrefix:[self getOwnBaseUrl]]) {
        return NO;
    }
    
    NSString *query = [url fragment];
    if (!query) {
        query = [url query];
    }
    
    NSDictionary *params = [self parseURLParams:query];
    NSString *accessToken = [params valueForKey:@"access_token"];
    
    // If the URL doesn't contain the access token, an error has occurred.
    if (!accessToken) {        
        NSString *errorReason = [params valueForKey:@"error_reason"];
        
        BOOL userDidCancel = [errorReason isEqualToString:@"user_denied"];
        [self igDidNotLogin:userDidCancel];
        return YES;
    }
    
    [self igDidLogin:accessToken];
    return YES;
}

- (void)logout {
    [self invalidateSession];
    
    if ([self.sessionDelegate respondsToSelector:@selector(instagramDidLogout:)]) {
        [self.sessionDelegate instagramDidLogout:self];
    }
}

-(IGRequest*)requestWithParams:(NSMutableDictionary*)params
                      delegate:(id<IGRequestDelegate>)delegate {
    if ([params objectForKey:@"method"] == nil) {
        NSLog(@"API Method must be specified");
        return nil;
    }
    
    NSString * methodName = [params objectForKey:@"method"];
    [params removeObjectForKey:@"method"];
    
    return [self requestWithMethodName:methodName
                                params:params
                            httpMethod:@"GET"
                              delegate:delegate];
}

-(IGRequest*)requestWithMethodName:(NSString*)methodName
                            params:(NSMutableDictionary*)params
                        httpMethod:(NSString*)httpMethod
                          delegate:(id<IGRequestDelegate>)delegate {
    NSString * fullURL = [kRestserverBaseURL stringByAppendingString:methodName];
    return [self openUrl:fullURL
                  params:params
              httpMethod:httpMethod
                delegate:delegate];
}

- (BOOL)isSessionValid {
    return (self.accessToken != nil);
    
}

#pragma mark 

/**
 * Set the authToken after login succeed
 */
- (void)igDidLogin:(NSString *)token /*expirationDate:(NSDate *)expirationDate*/ {
    self.accessToken = token;
    if ([self.sessionDelegate respondsToSelector:@selector(instagramDidLogin:)]) {
        [self.sessionDelegate instagramDidLogin:self];
    }
    
}

/**
 * Did not login call the not login delegate
 */
- (void)igDidNotLogin:(BOOL)cancelled {
    if ([self.sessionDelegate respondsToSelector:@selector(instagram:didNotLogin:)]) {
        [self.sessionDelegate instagram:self didNotLogin:cancelled];
    }
}


#pragma mark - IGSessionDelegate

-(void)instagramDidLogin:(Instagram *)instagram
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kInstagramDidLogin object:nil];
}

-(void)instagram:(Instagram *)instagram didNotLogin:(BOOL)cancelled
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kInstagramDidNotLogin object:nil];
}

-(void)instagramDidLogout:(Instagram *)instagram
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kInstagramDidLogout object:nil];
}

-(void)instagramSessionInvalidated:(Instagram *)instagram
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kInstagramSessionInvalidated object:nil];
}

@end
