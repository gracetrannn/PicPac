#define fb_dispatch_thread(the_block) dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), the_block)
#define fb_dispatch_main(the_block) dispatch_sync(dispatch_get_main_queue(), the_block)
#define fb_dispatch_main_async(the_block) dispatch_async(dispatch_get_main_queue(), the_block)
#define fb_dispatch_seconds(seconds, the_block) dispatch_after(dispatch_time(DISPATCH_TIME_NOW, seconds * NSEC_PER_SEC), dispatch_get_main_queue(), the_block)

#ifdef DEBUG
	#define FBDebugLog(fmt, ...) NSLog(fmt, ##__VA_ARGS__)
#else
	#define FBDebugLog(fmt, ...)
#endif

#define FBIsPhone() ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)
#define FBIsSystemGreaterThanEqualTo(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
