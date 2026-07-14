// QunarBypass DEB
#import <Foundation/Foundation.h>
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
    if([p length]&&([p containsString:@"/var"]||[p containsString:@"Cydia"]))LOG(@"fileExists: %@ = %d -> NO",p,r);
    return isJB(p)?NO:r;
}
static BOOL(*orig_fepd)(id,SEL,NSString*,BOOL*);
static BOOL hook_fepd(id s,SEL c,NSString*p,BOOL*d){if(isJB(p)){if(d)*d=NO;return NO;}return orig_fepd(s,c,p,d);}

static NSDictionary*(*orig_env)(id,SEL);
static NSDictionary* hook_env(id s,SEL c){NSDictionary*e=orig_env(s,c);NSMutableDictionary*m=[e mutableCopy];[m removeObjectForKey:@"DYLD_INSERT_LIBRARIES"];return m;}

static void(*orig_svh)(id,SEL,NSString*,NSString*);
static void hook_svh(id s,SEL c,NSString*v,NSString*f){LOG(@"Header: %@ = %@",f,v);orig_svh(s,c,v,f);}

static NSString*(*orig_name)(id,SEL);
static NSString* hook_name(id s,SEL c){LOG(@"name -> iPhone");return @"iPhone";}
static NSString*(*orig_model)(id,SEL);
static NSString* hook_model(id s,SEL c){LOG(@"model -> iPhone");return @"iPhone";}
static NSString*(*orig_idfv)(id,SEL);
static NSString* hook_idfv(id s,SEL c){LOG(@"IDFV -> random");return[[NSUUID UUID]UUIDString];}

__attribute__((constructor))
static void init(){@autoreleasepool{
    LOG(@"===== QunarBypass LOADED =====");
    Class c=NSClassFromString(@"NSFileManager");
    if(c){Method m=class_getInstanceMethod(c,@selector(fileExistsAtPath:));if(m){orig_fep=(void*)method_getImplementation(m);method_setImplementation(m,(IMP)hook_fep);}
        m=class_getInstanceMethod(c,@selector(fileExistsAtPath:isDirectory:));if(m){orig_fepd=(void*)method_getImplementation(m);method_setImplementation(m,(IMP)hook_fepd);}}
    c=NSClassFromString(@"NSProcessInfo");
    if(c){Method m=class_getInstanceMethod(c,@selector(environment));if(m){orig_env=(void*)method_getImplementation(m);method_setImplementation(m,(IMP)hook_env);}}
    c=NSClassFromString(@"NSMutableURLRequest");
    if(c){Method m=class_getInstanceMethod(c,@selector(setValue:forHTTPHeaderField:));if(m){orig_svh=(void*)method_getImplementation(m);method_setImplementation(m,(IMP)hook_svh);}}
    c=NSClassFromString(@"UIDevice");
    if(c){Method m=class_getInstanceMethod(c,@selector(name));if(m){orig_name=(void*)method_getImplementation(m);method_setImplementation(m,(IMP)hook_name);}
        m=class_getInstanceMethod(c,@selector(model));if(m){orig_model=(void*)method_getImplementation(m);method_setImplementation(m,(IMP)hook_model);}
        m=class_getInstanceMethod(c,@selector(identifierForVendor));if(m){orig_idfv=(void*)method_getImplementation(m);method_setImplementation(m,(IMP)hook_idfv);}}
    LOG(@"===== READY =====");
}}
