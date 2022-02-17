#import <Foundation/Foundation.h>

//! Project version number for lualib.
FOUNDATION_EXPORT double lualibVersionNumber;

//! Project version string for lualib.
FOUNDATION_EXPORT const unsigned char lualibVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <lualib/PublicHeader.h>


#if __cplusplus
extern "C" {
#endif

short initLuaCore(void);
short getSystemTag(void);

#if __cplusplus
}
#endif
