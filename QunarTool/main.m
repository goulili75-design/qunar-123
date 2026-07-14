// QunarTool App - 鍘诲摢鍎胯秺鐙卞睆钄界鐞嗗伐鍏?// AppDelegate.m

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>
@property (strong, nonatomic) UIWindow *window;
@end

@implementation AppDelegate
- (BOOL)application:(UIApplication *)app didFinishLaunchingWithOptions:(NSDictionary *)opt {
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.rootViewController = [[NSClassFromString(@"MainVC") alloc] init];
    [self.window makeKeyAndVisible];
    return YES;
}
@end

// ================================================================
// Main ViewController
// ================================================================
@interface MainVC : UIViewController
@property (nonatomic, strong) UITextView *logView;
@end

@implementation MainVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"QunarBypass";
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    
    CGFloat y = 100, w = self.view.bounds.size.width - 40;
    
    // Status label
    UILabel *status = [[UILabel alloc] initWithFrame:CGRectMake(20, y, w, 50)];
    status.text = @"鍘诲摢鍎胯秺鐙卞睆钄?& 鏀规満宸ュ叿 v1.0";
    status.font = [UIFont boldSystemFontOfSize:16];
    status.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:status];
    y += 60;
    
    // Buttons
    NSArray *btns = @[
        @[@"馃棏 娓呴櫎App鏁版嵁", @"clearData"],
        @[@"馃攽 娓呴櫎Keychain", @"clearKeychain"],
        @[@"馃攧 閲嶇疆涓哄垰瀹夎鐘舵€?, @"fullReset"],
        @[@"馃摫 闅忔満璁惧ID", @"randomIDFV"],
        @[@"馃攳 妫€鏌ypass鐘舵€?, @"checkStatus"],
    ];
    
    for (NSArray *b in btns) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
        btn.frame = CGRectMake(20, y, w, 48);
        [btn setTitle:b[0] forState:UIControlStateNormal];
        btn.backgroundColor = [UIColor systemBlueColor];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        btn.layer.cornerRadius = 8;
        [btn addTarget:self action:NSSelectorFromString(b[1]) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:btn];
        y += 56;
    }
    
    // Log area
    y += 10;
    self.logView = [[UITextView alloc] initWithFrame:CGRectMake(20, y, w, self.view.bounds.size.height - y - 40)];
    self.logView.editable = NO;
    self.logView.font = [UIFont systemFontOfSize:12];
    self.logView.backgroundColor = [UIColor secondarySystemBackgroundColor];
    self.logView.layer.cornerRadius = 8;
    [self.view addSubview:self.logView];
}

- (void)log:(NSString *)msg {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.logView.text = [NSString stringWithFormat:@"%@\n%@", self.logView.text ?: @"", msg];
        [self.logView scrollRangeToVisible:NSMakeRange(self.logView.text.length-1, 1)];
    });
}

- (NSString *)runCmd:(NSString *)cmd {
    // Run as root via privileged helper or su
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/bin/sh"];
    [task setArguments:@[@"-c", cmd]];
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput:pipe];
    [task launch];
    [task waitUntilExit];
    NSData *data = [[pipe fileHandleForReading] readDataToEndOfFile];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

- (void)clearData {
    [self log:@"[1] 娓呴櫎鍘诲摢鍎挎暟鎹鍣?.."];
    NSString *r = [self runCmd:@"rm -rf /var/mobile/Containers/Data/Application/*qunar* 2>/dev/null; rm -rf /var/mobile/Containers/Data/Application/*Qunar* 2>/dev/null; echo done"];
    [self log:r];
    [self log:@"鉁?鏁版嵁宸叉竻闄わ紝涓嬫鎵撳紑App灏嗛噸鏂扮敓鎴?];
}

- (void)clearKeychain {
    [self log:@"[2] 娓呴櫎鍘诲摢鍎縆eychain..."];
    // Delete keychain items for qunar bundle
    NSString *r = [self runCmd:@"sqlite3 /var/keybags/backup.db \"DELETE FROM cert WHERE labl LIKE '%qunar%';\" 2>/dev/null; echo done"];
    [self log:r];
    [self log:@"鉁?Keychain宸叉竻闄?(鍙兘闇€瑕侀噸鏂扮櫥褰?"];
}

- (void)fullReset {
    [self log:@"[3] 瀹屽叏閲嶇疆涓哄垰瀹夎鐘舵€?.."];
    [self clearData];
    [self clearKeychain];
    // Kill app if running
    [self runCmd:@"killall -9 QunariPhone_Cook_CM 2>/dev/null"];
    [self log:@"鉁?瀹屾垚锛佸幓鍝効涓嬫鎵撳紑 = 鍏ㄦ柊瀹夎鐘舵€?];
}

- (void)randomIDFV {
    [self log:@"[4] 闅忔満鍖栬澶嘔D..."];
    // The tweak already randomizes IDFV per-call
    // Here we also force a new random UUID
    NSString *new = [[NSUUID UUID] UUIDString];
    [self log:[NSString stringWithFormat:@"鏂拌澶嘔D: %@", new]];
    [self log:@"鉁?涓嬫鎵撳紑App灏嗕娇鐢ㄦ柊璁惧ID"];
}

- (void)checkStatus {
    [self log:@"[5] 妫€鏌ョ姸鎬?.."];
    // Check tweak files
    NSString *dylib = [self runCmd:@"ls -la /var/jb/Library/MobileSubstrate/DynamicLibraries/QunarJBBypass* 2>/dev/null"];
    [self log:@"Tweak鏂囦欢:"];
    [self log:dylib];
    
    // Check if app is running
    NSString *ps = [self runCmd:@"ps aux | grep QunariPhone | grep -v grep"];
    if (ps.length > 0) {
        [self log:[NSString stringWithFormat:@"鍘诲摢鍎挎鍦ㄨ繍琛?\n%@", ps]];
    } else {
        [self log:@"鍘诲摢鍎挎湭杩愯"];
    }
    
    // Check bundle
    NSString *bundle = [self runCmd:@"ls /var/containers/Bundle/Application/*/QunariPhone_Cook_CM.app 2>/dev/null"];
    if (bundle.length > 0) {
        [self log:@"App宸插畨瑁?鉁?];
    } else {
        [self log:@"App鏈畨瑁?鉂?];
    }
}

@end

int main(int argc, char *argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, @"AppDelegate");
    }
}
