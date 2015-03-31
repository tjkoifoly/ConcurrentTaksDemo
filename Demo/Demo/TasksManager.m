//
//  ThreeManager.m
//  Demo
//
//  Created by NGUYEN CHI CONG on 3/31/15.
//  Copyright (c) 2015 if. All rights reserved.
//

#import "TasksManager.h"
#import <CoreLocation/CoreLocation.h>

#define kAPI_URL_STRING @"http://sigma-solutions.eu/test"

@interface TasksManager () <CLLocationManagerDelegate, NSURLSessionDelegate>

@property (nonatomic, strong) NSOperationQueue *concurrentQueue;
@property (nonatomic, strong) NSTimer *timerScheduler1;
@property (nonatomic, strong) NSTimer *timerScheduler2;
@property (nonatomic, strong) CLLocationManager *locationManager;

@end

@implementation TasksManager

+ (id)sharedManager {
	static id __sharedInstance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		__sharedInstance = [[self alloc]init];
	});
	return __sharedInstance;
}

- (id)init {
	if (self = [super init]) {
		self.list = @[].mutableCopy;

		[self addObserver:self forKeyPath:@"list" options:NSKeyValueObservingOptionNew context:nil];
		self.concurrentQueue = [[NSOperationQueue alloc] init];
		self.concurrentQueue.maxConcurrentOperationCount = 3;
	}
	return self;
}

- (void)dealloc {
	[self removeObserver:self forKeyPath:@"list"];
	self.list = nil;
	[self.concurrentQueue cancelAllOperations];
	self.concurrentQueue = nil;
}

/**-----------------------------------------------------------------**/
#pragma mark - Main Functions

- (void)startTasks {
	NSLog(@"======= START TASKS =======");

	if (!self.timerScheduler1) {
		self.timerScheduler1 = [NSTimer scheduledTimerWithTimeInterval:6 target:self selector:@selector(getBatteryInfo:) userInfo:nil repeats:YES];
	}
	[self.timerScheduler1 fire];

	if (!self.timerScheduler2) {
		self.timerScheduler2 = [NSTimer scheduledTimerWithTimeInterval:9 target:self selector:@selector(getLocationInfo:) userInfo:nil repeats:YES];
	}
	[self.timerScheduler2 fire];
}

- (void)stopTasks {
	if (self.timerScheduler1.isValid) {
		[self.timerScheduler1 invalidate];
		self.timerScheduler1 = nil;
	}
	if (self.timerScheduler2.isValid) {
		[self.timerScheduler2 invalidate];
		self.timerScheduler2 = nil;
	}

	[self.concurrentQueue cancelAllOperations];

	NSLog(@"======= STOP TASKS =======");
}

- (BOOL)isRunning {
	return self.timerScheduler1.isValid || self.timerScheduler2.isValid;
}

/**-----------------------------------------------------------------**/
#pragma mark -

- (void)getBatteryInfo:(NSTimer *)timer {
	NSLog(@"TASK 1");
	__weak typeof(self) weakSelf = self;

	NSBlockOperation *bOperation1 = [NSBlockOperation blockOperationWithBlock: ^{
	    [weakSelf getBatteryInfoWithComplete: ^(NSString *info) {
	        [weakSelf addInfo:info];
		}];
	}];
	[self.concurrentQueue addOperation:bOperation1];
}

- (void)getLocationInfo:(NSTimer *)timer {
	NSLog(@"TASK 2");
	__weak typeof(self) weakSelf = self;

	NSBlockOperation *bOperation2 = [NSBlockOperation blockOperationWithBlock: ^{
	    [weakSelf getUserLocationInfoWithComplete: ^(NSString *info) {
	        [weakSelf addInfo:info];
		}];
	}];
	[self.concurrentQueue addOperation:bOperation2];
}

- (void)postInfo:(NSString *)apiURLString {
	NSError *error;

	NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
	NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:self.concurrentQueue];
	NSURL *url = [NSURL URLWithString:apiURLString];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
	                                                       cachePolicy:NSURLRequestUseProtocolCachePolicy
	                                                   timeoutInterval:60.0];

	[request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
	[request addValue:@"application/json" forHTTPHeaderField:@"Accept"];

	[request setHTTPMethod:@"POST"];

	NSString *listInfo = [self.list componentsJoinedByString:@"|"];

	NSDictionary *parameters = [[NSDictionary alloc] initWithObjectsAndKeys:@"TEST IOS", listInfo,
	                            nil];
	NSData *postData = [NSJSONSerialization dataWithJSONObject:parameters options:0 error:&error];
	[request setHTTPBody:postData];


	NSURLSessionDataTask *postDataTask = [session dataTaskWithRequest:request completionHandler: ^(NSData *data, NSURLResponse *response, NSError *error) {
	    NSLog(@"POST DATA FINISHED");
	}];

	[postDataTask resume];
}

/**-----------------------------------------------------------------**/
#pragma mark - Observer

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqualToString:@"list"]) {
		NSLog(@"PREPARE POST DATA: %@", self.list);
		[self postInfo:kAPI_URL_STRING];
	}
}

- (void)addInfo:(NSString *)info {
	if (info) {
		[self willChangeValueForKey:@"list"];
		[self.list addObject:info];
		[self didChangeValueForKey:@"list"];
	}
}

/**-----------------------------------------------------------------**/
#pragma mark - Location

- (CLLocationManager *)locationManager {
	if (!_locationManager) {
		_locationManager = [[CLLocationManager alloc] init];
		_locationManager.delegate = self;
		if (IS_OS_8_OR_LATER) {
			[_locationManager requestWhenInUseAuthorization];
			[_locationManager requestAlwaysAuthorization];
		}
	}

	return _locationManager;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
	NSLog(@"%@", [locations lastObject]);
}

/**-----------------------------------------------------------------**/
#pragma mark - GetInfo

- (void)getBatteryInfoWithComplete:(void (^)(NSString *info))completion {
	UIDevice *myDevice = [UIDevice currentDevice];
	[myDevice setBatteryMonitoringEnabled:YES];
	float batLeft = [myDevice batteryLevel];
	int batinfo = (batLeft * 100);

	NSLog(@"Get Battery: %@", [NSString stringWithFormat:@"Battery: %d %@", batinfo, @"%"]);
	if (completion) {
		completion([NSString stringWithFormat:@"Battery: %d %@", batinfo, @"%"]);
	}
}

- (void)getUserLocationInfoWithComplete:(void (^)(NSString *info))completion {
	[[self locationManager] startUpdatingLocation];
	NSString *info;
	if (![CLLocationManager locationServicesEnabled]) {
		info = @"Location Services is disabled";
	}
	else {
		BOOL authenticated = NO;
		if (IS_OS_8_OR_LATER) {
			if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse) {
				authenticated = YES;
			}
		}
		else {
			if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized) {
				authenticated = YES;
			}
		}
		if (!authenticated) {
			info = @"Location Services is not allowed by user";
		}
		else {
			CLLocation *location = self.locationManager.location;
			CLLocationDegrees currentLatitude = location.coordinate.latitude;
			CLLocationDegrees currentLongitude = location.coordinate.longitude;
			info = [NSString stringWithFormat:@"Location: %f,%f", currentLatitude, currentLongitude];
		}
	}
	NSLog(@"Get Location: %@", info);
	if (completion) {
		completion(info);
	}
}

@end
