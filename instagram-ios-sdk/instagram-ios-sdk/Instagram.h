//
//  Instagram.h
//  instagram-ios-sdk
//
//  Created by Cristiano Severini on 18/04/12.
//  Copyright (c) 2012 IQUII. All rights reserved.
//

#import "IGRequest.h"
@protocol IGSessionDelegate;


@interface Instagram : NSObject {
    NSMutableSet* _requests;
}

@property(nonatomic, strong) NSString* accessToken;
@property(nonatomic, weak) id<IGSessionDelegate> sessionDelegate;

+ (void)initSharedInstance;
+ (instancetype)sharedInstance;

-(id)initWithClientId:(NSString*)clientId delegate:(id<IGSessionDelegate>)delegate;

-(void)authorize:(NSArray*)scopes;

-(BOOL)handleOpenURL:(NSURL *)url;

-(void)logout;

-(BOOL)isSessionValid;

-(IGRequest*)requestWithParams:(NSMutableDictionary*)params
                      delegate:(id<IGRequestDelegate>)delegate;

-(IGRequest*)requestWithMethodName:(NSString*)methodName
                            params:(NSMutableDictionary*)params
                        httpMethod:(NSString*)httpMethod
                          delegate:(id<IGRequestDelegate>)delegate;

@end


#pragma mark

@protocol IGSessionDelegate <NSObject>

-(void)instagramDidLogin:(Instagram *)instagram;

-(void)instagram:(Instagram *)instagram didNotLogin:(BOOL)cancelled;

-(void)instagramDidLogout:(Instagram *)instagram;

-(void)instagramSessionInvalidated:(Instagram *)instagram;

@end