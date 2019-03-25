//
//  ViewController.m
//  BaiduMapDemo
//
//  Created by Gary Yao on 2019/3/21.
//  Copyright © 2019 mobilenow. All rights reserved.
//

#import "ViewController.h"
#import <BaiduMapAPI_Base/BMKBaseComponent.h>
#import <BaiduMapAPI_Map/BMKMapComponent.h>
#import <CoreLocation/CoreLocation.h>
#import <BMKLocationkit/BMKLocationComponent.h>


@interface ViewController () <BMKMapViewDelegate, CLLocationManagerDelegate>

@property (nonatomic, strong) BMKMapView *mapView;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) BMKLocationManager *BDLocationManager;
@property (nonatomic, strong) BMKUserLocation *userLocation;

@property (nonatomic) BOOL enable;
@property (nonatomic) NSInteger status;

@end

@implementation ViewController



- (void)viewDidLoad {
    [super viewDidLoad];
    
    _locationManager =[[CLLocationManager alloc] init];
    
    // 监听app进入前台显示的系统事件
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(openMap) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    NSLog(@"viewDidAppear");
    [self openMap];
}

# pragma 尝试打开地图
- (void)openMap {
    if ([self shouldShowMap]) { // 拥有位置权限，直接打开地图
        [self showMap];
    } else { // 无位置权限
        _enable = [CLLocationManager locationServicesEnabled];
        _status = [CLLocationManager authorizationStatus];
        if(  !_enable || _status< 2){ // 用户之前没有拒绝位置权限，尝试再次请求用户授权
            // 尚未授权位置权限
            if ([[UIDevice currentDevice].systemVersion floatValue] >= 8) {
                //系统位置授权弹窗
                
                [_locationManager requestAlwaysAuthorization];
                [_locationManager requestWhenInUseAuthorization];
                
                
            }
        }else{ // 用户之前拒绝了使用位置，尝试引导用户重新设置
            if (_status == kCLAuthorizationStatusDenied) {
                
                // 引导用户进行位置使用设置
                UIAlertController *alertCtr = [UIAlertController alertControllerWithTitle:@"定位未打开" message:@"打开系统定位服务才能使用地图" preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction *notNow = [UIAlertAction actionWithTitle:@"暂不设置" style:(UIAlertActionStyleCancel) handler:^(UIAlertAction * _Nonnull action) {
                    NSLog(@"cancel");
                }];
                UIAlertAction *setNow = [UIAlertAction actionWithTitle:@"现在设置" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:nil completionHandler:^(BOOL success) {
                        NSLog(@"Opened settings");
                    }];
                }];
                
                [alertCtr addAction:notNow];
                [alertCtr addAction:setNow];
                
                [self presentViewController:alertCtr animated:YES completion:nil];
                
                
            }
        }
    }
}

# pragma 判断是否拥有位置权限
- (BOOL)shouldShowMap {
    BOOL shouldOpenMap = NO;
    
    _enable = [CLLocationManager locationServicesEnabled];
    _status = [CLLocationManager authorizationStatus];
    
    if (_enable && (_status == kCLAuthorizationStatusAuthorizedAlways || _status == kCLAuthorizationStatusAuthorizedWhenInUse)) {
        shouldOpenMap = YES;
    }
    
    return shouldOpenMap;
}

# pragma 检查位置授权信息
//- (void) locationPermissionCheck {
//    _enable = [CLLocationManager locationServicesEnabled];
//    _status = [CLLocationManager authorizationStatus];
//    if(  !_enable || _status< 2){
//        // 尚未授权位置权限
//        if ([[UIDevice currentDevice].systemVersion floatValue] >= 8)
//        {
//            //系统位置授权弹窗
//            _locationManager =[[CLLocationManager alloc] init];
//            [_locationManager requestAlwaysAuthorization];
//            [_locationManager requestWhenInUseAuthorization];
//        }
//    }else{
//        // 拒绝之前拒绝了使用位置
//        if (_status == kCLAuthorizationStatusDenied) {
//
//            // 引导用户进行位置使用设置
//            UIAlertController *alertCtr = [UIAlertController alertControllerWithTitle:@"定位未打开" message:@"打开系统定位服务才能使用地图" preferredStyle:UIAlertControllerStyleAlert];
//
//            UIAlertAction *notNow = [UIAlertAction actionWithTitle:@"暂不设置" style:(UIAlertActionStyleCancel) handler:^(UIAlertAction * _Nonnull action) {
//                NSLog(@"cancel");
//            }];
//            UIAlertAction *setNow = [UIAlertAction actionWithTitle:@"现在设置" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
//                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:nil completionHandler:^(BOOL success) {
//                    NSLog(@"Opened settings");
//                }];
//            }];
//
//            [alertCtr addAction:notNow];
//            [alertCtr addAction:setNow];
//
//            [self presentViewController:alertCtr animated:YES completion:nil];
//
//
//        }else{
//            //允许使用位置
//            [self showMap];
//
//        }
//    }
//}



- (void) showMap {
    if (_mapView == nil) {
        _mapView = [[BMKMapView alloc]initWithFrame:self.view.bounds];
        _mapView.delegate = self;
        _mapView.zoomLevel = 17;
//        _mapView.showsUserLocation = YES;
        [self.view addSubview:_mapView];
        
        
        //初始化标注类BMKPointAnnotation的实例
        NSMutableArray<BMKPointAnnotation*> *annotations = [[NSMutableArray alloc] init];
        BMKPointAnnotation *annotation = [[BMKPointAnnotation alloc] init];
        //设置标注的经纬度坐标
        annotation.coordinate =  CLLocationCoordinate2DMake(112.937816,28.229034);
        //设置标注的标题
        annotation.title = @"标注";
        //副标题
        annotation.subtitle = @"可拖拽";
        [annotations addObject:annotation];
        [self.mapView addAnnotation:annotation];
        
    }
    
    if (_BDLocationManager == nil) {
        _BDLocationManager = [[BMKLocationManager alloc] init];
    }
    
    [_BDLocationManager requestLocationWithReGeocode:YES withNetworkState:YES completionBlock:^(BMKLocation * _Nullable location, BMKLocationNetworkState state, NSError * _Nullable error) {
        if (_userLocation == nil) {
            _userLocation = [[BMKUserLocation alloc] init];
            
        }
        
        _userLocation.location = location.location;
        [_mapView updateLocationData:_userLocation];
        
        [_mapView setCenterCoordinate:location.location.coordinate animated:YES];
        
        
        
        
        
        
        
        
        
    }];

}

- (BMKAnnotationView *)mapView:(BMKMapView *)mapView viewForAnnotation:(id<BMKAnnotation>)annotation {
    if ([annotation isKindOfClass:[BMKPointAnnotation class]]) {
        BMKPinAnnotationView *annotationView = (BMKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:@"annotationViewIdentifier"];
        if (!annotationView) {
            annotationView = [[BMKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"annotationViewIdentifier"];
            annotationView.centerOffset = CGPointMake(0, 0);
            annotationView.calloutOffset = CGPointMake(0, 0);
            annotationView.enabled3D = NO;
            annotationView.enabled = YES;
            annotationView.selected = NO;
            annotationView.canShowCallout = YES;
            annotationView.leftCalloutAccessoryView = nil;
            annotationView.rightCalloutAccessoryView = nil;
            annotationView.pinColor = BMKPinAnnotationColorRed;
            annotationView.draggable = YES;
        }
        return annotationView;
    }
    return nil;
}


- (void) showMapWithAnnotations: (NSArray<BMKPointAnnotation*>*)annotations {
    [self showMap];
    
    [self.mapView addAnnotation:annotations];
}


- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if ([self shouldShowMap]) {
        [self showMap];
    } else {
        NSLog(@"Not authorized to open map");
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
