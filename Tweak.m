// QunarBypass v9.0 - Deferred init to avoid watchdog
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
    if([p length]&&([p containsString:@"/var"]||[p containsString:@"Cydia"]))
        LOG(@"fileExists: %@ = %d -> NO",p,r);
    return isJB(p)?NO:r;
}
static BOOL(*orig_fepd)(id,SEL,NSString*,BOOL*);
static BOOL hook_fepd(id s,SEL c,NSString*p,BOOL*d){if(isJB(p)){if(d)*d=NO;return NO;}return orig_fepd(s,c,p,d);}

static NSDictionary*(*orig_env)(id,SEL);
static NSDictionary* hook_env(id s,SEL c){NSDictionary*e=orig_env(s,c);NSMutableDictionary*m=[e mutableCopy];[m removeObjectForKey:@"DYLD_INSERT_LIBRARIES"];return m;}

static void(*orig_svh)(id,SEL,NSString*,NSString*);
static void hook_svh(id s,SEL c,NSString*v,NSString*f){LOG(@"Header: %@ = %@",f,v?:@"nil");orig_svh(s,c,v,f);}

static NSString*(*orig_name)(id,SEL);
static NSString* hook_name(id s,SEL c){NSString*r=orig_name(s,c);LOG(@"name = %@ -> iPhone",r);return @"iPhone";}
static NSString*(*orig_model)(id,SEL);
static NSString* hook_model(id s,SEL c){NSString*r=orig_model(s,c);LOG(@"model = %@ -> iPhone",r);return @"iPhone";}
static NSString*(*orig_idfv)(id,SEL);
static NSString* hook_idfv(id s,SEL c){LOG(@"IDFV -> random");return[[NSUUID UUID]UUIDString];}

static CGRect(*orig_bounds)(id,SEL);
static CGRect hook_bounds(id s,SEL c){CGRect r=orig_bounds(s,c);LOG(@"screen = %.0fx%.0f -> 390x844",r.size.width,r.size.height);return CGRectMake(0,0,390,844);}
static CGFloat(*orig_scale)(id,SEL);
static CGFloat hook_scale(id s,SEL c){LOG(@"scale -> 3.0");return 3.0;}

static NSDictionary*(*orig_fsa)(id,SEL,NSString*);
static NSDictionary* hook_fsa(id s,SEL c,NSString*p){NSDictionary*d=orig_fsa(s,c,p);NSMutableDictionary*m=[d mutableCopy];m[NSFileSystemFreeSize]=@(100000000000LL);m[NSFileSystemSize]=@(256000000000LL);return m;}

// Deferred setup - runs on main queue after app is ready
static void doHooks(){
    LOG(@"Setting up hooks...");
    Class c;
    c=NSClassFromString(@"NSFileManager");
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
    if(c){Method m=class_getInstanceMethod(c,@selector(bounds));if(m){orig_bounds=(void*)method_getImplementation(m);method_setImplementation(m,(IMP)hook_bounds);}
        m=class_getInstanceMethod(c,@selector(scale));if(m){orig_scale=(void*)method_getImplementation(m);method_setImplementation(m,(IMP)hook_scale);}}
    LOG(@"Hooks ready");
}

__attribute__((constructor))
static void init(){
    LOG(@"Loaded - will setup after app ready");
    // Listen for app launch notification, then hook
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
        object:nil queue:nil usingBlock:^(NSNotification *n){ doHooks(); }];
}
