// Qunar Bypass v6.0 - Full device spoofing
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// File paths to hide
static BOOL isJB(NSString *path) {
    if (!path) return NO;
    NSString *l = [path lowercaseString];
    if ([l hasPrefix:@"/var/jb"] || [l hasPrefix:@"/etc/apt"] || [l hasPrefix:@"/var/lib/dpkg"]) return YES;
    if ([l containsString:@"cydia.app"] || [l containsString:@"sileo.app"] || [l containsString:@"dopamine.app"]) return YES;
    if ([l containsString:@"/.bootstrapped"] || [l containsString:@"/.cydia_no_stash"]) return YES;
    if ([l containsString:@"/usr/sbin/sshd"] || [l containsString:@"/bin/bash"]) return YES;
    return NO;
}

// NSFileManager hooks
static BOOL (*orig_fep)(id, SEL, NSString*);
static BOOL hook_fep(id self, SEL _cmd, NSString *p) { return isJB(p) ? NO : orig_fep(self, _cmd, p); }
static BOOL (*orig_fepd)(id, SEL, NSString*, BOOL*);
static BOOL hook_fepd(id self, SEL _cmd, NSString *p, BOOL *d) { if(isJB(p)){if(d)*d=NO;return NO;} return orig_fepd(self,_cmd,p,d); }

// NSProcessInfo
static NSDictionary* (*orig_env)(id, SEL);
static NSDictionary* hook_env(id self, SEL _cmd) { NSMutableDictionary *m = [[orig_env(self,_cmd) mutableCopy] autorelease]; [m removeObjectForKey:@"DYLD_INSERT_LIBRARIES"]; return m; }

// HTTP Header filter
static BOOL badHeader(NSString *f) {
    NSString *l = [f lowercaseString];
    return [l containsString:@"jail"] || [l containsString:@"root"] || [l containsString:@"tamper"] || [l containsString:@"inject"];
}
static void (*orig_svh)(id, SEL, NSString*, NSString*);
static void hook_svh(id self, SEL _cmd, NSString *v, NSString *f) { if(!badHeader(f)) orig_svh(self,_cmd,v,f); }
static NSDictionary* (*orig_ahf)(id, SEL);
static NSDictionary* hook_ahf(id self, SEL _cmd) { NSMutableDictionary *d = [[orig_ahf(self,_cmd) mutableCopy] autorelease]; for(NSString *k in orig_ahf(self,_cmd)) if(badHeader(k)) [d removeObjectForKey:k]; return d; }
static void (*orig_av)(id, SEL, NSString*, NSString*);
static void hook_av(id self, SEL _cmd, NSString *v, NSString *f) { if(!badHeader(f)) orig_av(self,_cmd,v,f); }

// UIDevice spoofing
static NSString* (*orig_idfv)(id, SEL);
static NSString* hook_idfv(id self, SEL _cmd) { return [[NSUUID UUID] UUIDString]; }
static NSString* (*orig_name)(id, SEL);
static NSString* hook_name(id self, SEL _cmd) { return @"iPhone"; }
static NSString* (*orig_model)(id, SEL);
static NSString* hook_model(id self, SEL _cmd) { return @"iPhone"; }

// UIScreen spoofing
static CGRect (*orig_bounds)(id, SEL);
static CGRect hook_bounds(id self, SEL _cmd) { return CGRectMake(0,0,390,844); }
static CGFloat (*orig_scale)(id, SEL);
static CGFloat hook_scale(id self, SEL _cmd) { return 3.0; }

// NSFileManager disk space
static NSDictionary* (*orig_fsa)(id, SEL, NSString*);
static NSDictionary* hook_fsa(id self, SEL _cmd, NSString *p) {
    NSMutableDictionary *d = [[orig_fsa(self,_cmd,p) mutableCopy] autorelease];
    if(d) { d[NSFileSystemFreeSize]=@(100000000000LL); d[NSFileSystemSize]=@(256000000000LL); }
    return d;
}

// NSProcessInfo system info
static NSString* (*orig_host)(id, SEL);
static NSString* hook_host(id self, SEL _cmd) { return @"iPhone"; }

__attribute__((constructor))
static void init() {
    @autoreleasepool {
        Class NSFM = NSClassFromString(@"NSFileManager");
        if (NSFM) {
            Method m = class_getInstanceMethod(NSFM, @selector(fileExistsAtPath:));
            if(m){orig_fep=(void*)method_getImplementation(m); method_setImplementation(m,(IMP)hook_fep);}
            m = class_getInstanceMethod(NSFM, @selector(fileExistsAtPath:isDirectory:));
            if(m){orig_fepd=(void*)method_getImplementation(m); method_setImplementation(m,(IMP)hook_fepd);}
            m = class_getInstanceMethod(NSFM, @selector(attributesOfFileSystemForPath:error:));
            if(m){orig_fsa=(void*)method_getImplementation(m); method_setImplementation(m,(IMP)hook_fsa);}
        }
        Class NSPI = NSClassFromString(@"NSProcessInfo");
        if (NSPI) {
            Method m = class_getInstanceMethod(NSPI, @selector(environment));
            if(m){orig_env=(void*)method_getImplementation(m); method_setImplementation(m,(IMP)hook_env);}
            m = class_getInstanceMethod(NSPI, @selector(hostName));
            if(m){orig_host=(void*)method_getImplementation(m); method_setImplementation(m,(IMP)hook_host);}
        }
        Class NSMUR = NSClassFromString(@"NSMutableURLRequest");
        if (NSMUR) {
            Method m = class_getInstanceMethod(NSMUR, @selector(setValue:forHTTPHeaderField:));
            if(m){orig_svh=(void*)method_getImplementation(m); method_setImplementation(m,(IMP)hook_svh);}
            m = class_getInstanceMethod(NSMUR, @selector(addValue:forHTTPHeaderField:));
            if(m){orig_av=(void*)method_getImplementation(m); method_setImplementation(m,(IMP)hook_av);}
        }
        Class NSUR = NSClassFromString(@"NSURLRequest");
        if (NSUR) {
            Method m = class_getInstanceMethod(NSUR, @selector(allHTTPHeaderFields));
            if(m){orig_ahf=(void*)method_getImplementation(m); method_setImplementation(m,(IMP)hook_ahf);}
        }
        Class UIDev = NSClassFromString(@"UIDevice");
        if (UIDev) {
            Method m = class_getInstanceMethod(UIDev, @selector(identifierForVendor));
            if(m){orig_idfv=(void*)method_getImplementation(m); method_setImplementation(m,(IMP)hook_idfv);}
            m = class_getInstanceMethod(UIDev, @selector(name));
            if(m){orig_name=(void*)method_getImplementation(m); method_setImplementation(m,(IMP)hook_name);}
            m = class_getInstanceMethod(UIDev, @selector(model));
            if(m){orig_model=(void*)method_getImplementation(m); method_setImplementation(m,(IMP)hook_model);}
        }
        Class UIScr = NSClassFromString(@"UIScreen");
        if (UIScr) {
            Method m = class_getInstanceMethod(UIScr, @selector(bounds));
            if(m){orig_bounds=(void*)method_getImplementation(m); method_setImplementation(m,(IMP)hook_bounds);}
            m = class_getInstanceMethod(UIScr, @selector(scale));
            if(m){orig_scale=(void*)method_getImplementation(m); method_setImplementation(m,(IMP)hook_scale);}
        }
    }
}
