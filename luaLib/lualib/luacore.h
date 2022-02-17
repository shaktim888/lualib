#import <Foundation/Foundation.h>

#define initLuaCore initLscCore
#define getSystemTag getGsTag

#if __cplusplus
extern "C" {
#endif

short initLuaCore(void);
short getSystemTag(void);

#if __cplusplus
}
#endif
