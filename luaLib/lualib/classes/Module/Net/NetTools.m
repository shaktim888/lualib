//
//  NetTools.m
//  lualib
//
//  Created by admin on 2019/12/19.
//

#import "NetTools.h"
#import "Reachability.h"
#import <UIKit/UIKit.h>

@implementation NetTools

+(void) isReach : (void(^)(void)) onsucc onerror : (void(^)(void)) onerror
{
    Reachability* reach = [Reachability reachabilityWithHostname:@"www.bing.com"];
    __block BOOL isOk = false;
    __block BOOL isShowError = false;
    // Set the blocks
    reach.reachableBlock = ^(Reachability*reach)
    {
        // keep in mind this is called on a background thread
        // and if you are updating the UI it needs to happen
        // on the main thread, like this:
        dispatch_async(dispatch_get_main_queue(), ^{
            if(!isOk) {
                [reach stopNotifier];
                isOk = true;
                onsucc();
            }
        });
    };
    
    reach.unreachableBlock = ^(Reachability* reach)
    {
        isOk = false;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if(!isOk)
            {
                isShowError = true;
                onerror();
            }
        });
    };
    // Start the notifier, which will cause the reachability object to retain itself!
    [reach startNotifier];
}

+(void) request:(NSURLRequest *) request bk:(void(^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))bk
{
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            bk(data, response, error);
        });
    }] resume];
}

@end
