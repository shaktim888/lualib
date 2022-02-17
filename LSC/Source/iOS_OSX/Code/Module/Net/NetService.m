//
//  NetService.m
//  LuaScriptCore
//
//  Created by admin on 2019/12/10.
//  Copyright © 2019 vimfung. All rights reserved.
//

#import "NetService.h"

@implementation NetService

+(void) GET : (NSString *) urlString backBlock : (void(^)(BOOL success, NSString* obj)) block
{
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:60];
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if(error) {
                block(false, nil);
                return;
            }
            if(data) {
                NSString * ret = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                block(true, ret);
            } else {
                block(false, nil);
            }
        });
    }] resume];
}

+(void) POST : (NSString *) urlString param : (NSDictionary*) param backBlock : (void(^)(BOOL success, NSString* obj)) block
{
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:60];
    [request setHTTPMethod:@"POST"];
    NSString *reqStr = @"";
    if(param)
    {
        NSMutableString * strM = [[NSMutableString alloc] init];
        [param enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            NSString *paramaterKey = key;
            NSString *paramaterValue = obj;
            [strM appendFormat:@"%@=%@&",paramaterKey,paramaterValue];
        }];
        reqStr = [strM substringToIndex:strM.length - 1];
    }
    [request setHTTPBody:[reqStr dataUsingEncoding:NSUTF8StringEncoding]];
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if(error) {
                block(false, nil);
                return;
            }
            if(data) {
                NSString * ret = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                block(true, ret);
            } else {
                block(false, nil);
            }
        });
    }] resume];
}

@end
