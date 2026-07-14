// QunarBypass v8.0 - Full logging
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#define LOG(fmt,...) NSLog(@"[QNB] " fmt, ##__VA_ARGS__)

static BOOL isJB(NSString *p){
    if(!p)return 0;
    NSString *l=[p lowercaseString];
    return [l hasPrefix:@"/var/jb"]||[l hasPrefix:@"/etc/apt"]||[l containsString:@"cydia.app"]||[l containsString:@"sileo.app"]||[l containsString:@"dopamine.app"]||[l containsString:@"/usr/sbin/sshd"]||[l containsString:@"/bin/bash"];
}

static BOOL(*orig_fep)(id,SEL,NSString*);
static BOOL hook_fep(id s,SEL c,NSString*p){
    BOOL r=orig_fep(s,c,p);
    if([p length]&&([p containsString:@"/var"]||[p containsString:@"Cydia"]||[p containsString:@"apt"]||[p containsString:@"bin/"]))
        LOG(@"fileExists: %@ = %d -> NO",p,r);
    return isJB(p)?NO:r;
}
static BOOL(*orig_fepd)(id,SEL,NSString*,BOOL*);
static BOOL hook_fepd(id s,SEL c,NSString*p,BOOL*d){if(isJB(p)){if(d)*d=NO;return NO;}return orig_fepd(s,c,p,d);}

static NSDictionary*(*orig_env)(id,SEL);
static NSDictionary* hook_env(id s,SEL c){
    NSDictionary*e=orig_env(s,c);
    LOG(@"env accessed: %lu keys",(unsigned long)[e count]);
    NSMutableDictionary*m=[e mutableCopy];
    [m removeObjectForKey:@"DYLD_INSERT_LIBRARIES"];
    [m removeObjectForKey:@"DYLD_LIBRARY_PATH"];
    return m;
}

static void(*orig_svh)(id,SEL,NSString*,NSString*);
static void hook_svh(id s,SEL c,NSString*v,NSString*f){
    if([f length])LOG(@"setHeader: %@ = %@",f,v?:@"(nil)");
    orig_svh(s,c,v,f);
}

static NSString*(*orig_name)(id,SEL);
static NSString* hook_name(id s,SEL c){NSString*r=orig_name(s,c);LOG(@"name = %@ -> iPhone",r);return @"iPhone";}
static NSString*(*orig_model)(id,SEL);
static NSString* hook_model(id s,SEL c){NSString*r=orig_model(s,c);LOG(@"model = %@ -> iPhone",r);return @"iPhone";}
static NSString*(*orig_idfv)(id,SEL);
static NSString* hook_idfv(id s,SEL c){NSString*r=orig_idfv(s,c);LOG(@"IDFV = %@ -> random",r);return[[NSUUID UUID]UUIDString];}

static CGRect(*orig_bounds)(id,SEL);
static CGRect hook_bounds(id s,SEL c){CGRect r=orig_bounds(s,c);LOG(@"screen = %.0fx%.0f -> 390x844",r.size.width,r.size.height);return CGRectMake(0,0,390,844);}
static CGFloat(*orig_scale)(id,SEL);
static CGFloat hook_scale(id s,SEL c){CGFloat r=orig_scale(s,c);LOG(@"scale = %.1f -> 3.0",r);return 3.0;}

static NSDictionary*(*orig_fsa)(id,SEL,NSString*);
static NSDictionary* hook_fsa(id s,SEL c,NSString*p){
    NSDictionary*d=orig_fsa(s,c,p);
    LOG(@"disk: free=%@ total=%@",d[NSFileSystemFreeSize],d[NSFileSystemSize]);
    NSMutableDictionary*m=[d mutableCopy];
    m[NSFileSystemFreeSize]=@(100000000000LL);
    m[NSFileSystemSize]=@(256000000000LL);
    return m;
}

// Kernel info
static int(*orig_uname)(void*);
static int hook_uname(void*b){
    int r=orig_uname(b);
    LOG(@"uname called");
    return r;
}

__attribute__((constructor))
static void init(){@autoreleasepool{
    LOG(@"===== v8.0 LOADED - logging all device access =====");
    Class c=NSClassFromString(@"NSFileManager");
    if(c){Method m=class_getInstanceMethod(c,@selector(fileExistsAtPath:));if(m){orig_fep=(void*)method_getImplementation(m);method_setImplementation(m,(IMP)hook_fep);}
        m=class_getInstanceMethod(c,@selector(fileExistsAtPath:isDirectory:));if(m){orig_fepd=(void*)method_getImplementation(m);method_setImplementation(m,(IMP)hook_fepd);}
        m=class_getInstanceMethod(c,@selector(attributesOfFileSystemForPath:error:));if(m){orig_fsa=(void*)method_getImplementation(m);method_setImplementation(m,(IMP)hook_fsa);}}
    c=NSClassFromString(@"NSProcessInfo");
    if(c){Method m=class_getInstanceMethod(c,@selector(environment));if(m){orig_env=(void*)method_getImplementation(m);method_setImplementation(m,(IMP)hook_env);}}
    c=NSClassFromString(@"NSMutableURLRequest");
    if(c){Method m=class_getInstanceMethod(c,@selector(setValue:forHTTPHeaderField:));if(m){orig_svh=(void*)method_getImplementation(m);method_setImplementation(m,(IMP)hook_svh);}}
    c=NSClassFromString(@"UIDevice");
    if(c){Method m=class_getInstanceMethod(c,@selector(name));if(m){orig_name=(void*)method_getImplementation(m);method_setImplementation(m,(IMP)hook_name);}
        m=class_getInstanceMethod(c,@selector(model));if(m){orig_model=(void*)method_getImplementation(m);method_setImplementation(m,(IMP)hook_model);}
        m=class_getInstanceMethod(c,@selector(identifierForVendor));if(m){orig_idfv=(void*)method_getImplementation(m);method_setImplementation(m,(IMP)hook_idfv);}}
    c=NSClassFromString(@"UIScreen");
    if(c){
        // Use instance method from mainScreen (safer - may be nil at load time)
        id screen = [c mainScreen];
        if(screen){
            Method m=class_getInstanceMethod(c,@selector(bounds));if(m){orig_bounds=(void*)method_getImplementation(m);method_setImplementation(m,(IMP)hook_bounds);}
            m=class_getInstanceMethod(c,@selector(scale));if(m){orig_scale=(void*)method_getImplementation(m);method_setImplementation(m,(IMP)hook_scale);}
        }
    }
    LOG(@"===== READY =====");
}}
