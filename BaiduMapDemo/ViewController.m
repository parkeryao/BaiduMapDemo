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
#import <BaiduMapAPI_Cloud/BMKCloudSearchComponent.h>
#import "ZDCPinView.h"

@interface ViewController () <BMKMapViewDelegate, CLLocationManagerDelegate, BMKLocationAuthDelegate, BMKCloudSearchDelegate>

@property (nonatomic, strong) BMKMapView *mapView;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) BMKLocationManager *BDLocationManager;
@property (nonatomic, strong) BMKUserLocation *userLocation;

@property (nonatomic, strong) NSMutableArray<BMKPointAnnotation*> *bikeList;

@property (nonatomic) BOOL enable;
@property (nonatomic) NSInteger status;

@end

@implementation ViewController

BMKCloudSearch *search;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _locationManager =[[CLLocationManager alloc] init];
    
    
    // 监听app进入前台显示的系统事件
    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(openMap)
        name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    NSLog(@"viewDidAppear");
    [self preOpenMap];
}

- (void) loadBikesFromBDCloud {
    
    if (search == nil) {
        search = [[BMKCloudSearch alloc]init];
    }
    search.delegate = self;
    
    BMKCloudLocalSearchInfo *cloudLocalInfo = [[BMKCloudLocalSearchInfo alloc]init];
    cloudLocalInfo.ak = @"9tSpXUogWAaagWVhTeSZffa6qMArKEjy";
    cloudLocalInfo.geoTableId = 200474;
    cloudLocalInfo.region = @"长沙";
    cloudLocalInfo.keyword = @"";
    
    BOOL flag = [search localSearchWithSearchInfo:cloudLocalInfo];
    if (flag) {
        NSLog(@"搜索成功");
    } else {
        NSLog(@"搜索失败");
    }

    
    BMKCloudDetailSearchInfo *cloudLocalInfo1 = [[BMKCloudDetailSearchInfo alloc]init];
    cloudLocalInfo.ak = @"9tSpXUogWAaagWVhTeSZffa6qMArKEjy";
    cloudLocalInfo.geoTableId = 200474;
    cloudLocalInfo.region = @"长沙";
    cloudLocalInfo.keyword = @"";
    
    BOOL flag1 = [search detailSearchWithSearchInfo:cloudLocalInfo1];
    if (flag) {
        NSLog(@"搜索成功");
    } else {
        NSLog(@"搜索失败");
    }
    
    
}

- (void)loadBikeList {
    NSURLSession *session = [NSURLSession sharedSession];
    NSURL *url = [[NSURL alloc] initWithString:@"http://192.168.31.155:3000/bikeowners"]; //此处如果使用localhost会出现1004错误
    NSURLSessionDataTask *dataTask = [session dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@", error);
        } else {
            self.bikeList = [[NSMutableArray alloc] init];
//            NSLog(@"%@", data);
            NSDictionary *coordinates = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
//            NSLog(@"%@", coordinates);
            for (NSDictionary *coordinate in coordinates){
                BMKPointAnnotation *annotation = [[BMKPointAnnotation alloc] init];
                //设置标注的经纬度坐标
                NSNumber *longtitude = coordinate[@"longitude"];
                NSNumber *latitude = coordinate[@"latitude"];
                annotation.coordinate =  CLLocationCoordinate2DMake([longtitude doubleValue], [latitude doubleValue]);
                //设置标注的标题
                annotation.title = @"标注";
                //副标题
                annotation.subtitle = @"可拖拽";
                [self.bikeList addObject:annotation];
            }
            
            //注：不在在background调用AppKit, UIKit的API，不然会报：Main Thread Checker: UI API called on a background thread: -[UIView initWithFrame:]的错误，解决办法是用这部分操作放到主线程中去
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.mapView addAnnotations:self.bikeList];
                //将所有annotation显示在地图视图上
                [self.mapView showAnnotations:self.bikeList animated:YES];
            });
            
        }
    }];
    [dataTask resume];
}

# pragma 打开地图前的检查和判断
- (void)preOpenMap {
    if ([self shouldShowMap]) { // 拥有位置权限，直接打开地图
        [self openMap];

//        [self loadBikeList];
        [self loadBikesFromBDCloud];
        
        
        
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


# pragma 打开并显示地图
- (void) openMap {
    if (_mapView == nil) {
        _mapView = [[BMKMapView alloc]initWithFrame:self.view.bounds];
        _mapView.delegate = self;
        _mapView.zoomLevel = 17;
        _mapView.showsUserLocation = YES;
        _mapView.showMapPoi = NO;
        [_mapView setCompassPosition:CGPointMake(300, 300)];
        CGSize compassSize =  self.mapView.compassSize;
        [_mapView setCompassImage:[UIImage imageNamed:@"poi"]];
        [self.view addSubview:_mapView];
        
        
        
//        //初始化标注类BMKPointAnnotation的实例
//        NSMutableArray<BMKPointAnnotation*> *annotations = [[NSMutableArray alloc] init];
//        BMKPointAnnotation *annotation = [[BMKPointAnnotation alloc] init];
//        //设置标注的经纬度坐标
//        //特别注意：在百度坐标拾取网站取到的坐标的经纬度刚好是反的
//        annotation.coordinate =  CLLocationCoordinate2DMake(28.234476, 112.941464);
//        //设置标注的标题
//        annotation.title = @"标注";
//        //副标题
//        annotation.subtitle = @"可拖拽";
//        [annotations addObject:annotation];
//        [self.mapView addAnnotations:self.bikeList];
        
    }
    
    if (_BDLocationManager == nil) {
        _BDLocationManager = [[BMKLocationManager alloc] init];
    }
    

    
    [_BDLocationManager requestLocationWithReGeocode:YES withNetworkState:YES completionBlock:^(BMKLocation * _Nullable location, BMKLocationNetworkState state, NSError * _Nullable error) {
        if (!error) {
            NSLog(@"定位失败: %@", error);
        }
        if (self.userLocation == nil) {
            self.userLocation = [[BMKUserLocation alloc] init];
            
        }
        
        self.userLocation.location = location.location;
        
        [self.mapView updateLocationData:self.userLocation];
        
        // 设置当前位置为地图的中心和[self.mapView showAnnotations:self.bikeList animated:YES]是有冲突的，如果想设置所有POI（self.bikeList，未必是全部POI）可见，就不要设置当前位置为地图中心
//        [self.mapView setCenterCoordinate:location.location.coordinate animated:YES];
        

        
    }];

}

#pragma mark - BMKMapViewDelegate
- (BMKAnnotationView *)mapView:(BMKMapView *)mapView viewForAnnotation:(id <BMKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[BMKPointAnnotation class]])
    {
        static NSString *reuseIndetifier = @"annotationReuseIndetifier";
        BMKAnnotationView *annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:reuseIndetifier];
        if (annotationView == nil)
        {
            annotationView = [[BMKAnnotationView alloc] initWithAnnotation:annotation
                                                           reuseIdentifier:reuseIndetifier];
        }
        
        annotationView.image = [UIImage imageNamed:@"poi.png"];
        
        annotationView.canShowCallout = YES;
        ZDCPinView *customPopView = [[ZDCPinView alloc] init];
        customPopView.frame = CGRectMake(0, 0, 120.0f, 74.0f);
        customPopView.image = [UIImage imageNamed:@"bike.png"];
        customPopView.title = @"北京";
        customPopView.subtitle = @"天安门";
        
        
        
        BMKActionPaopaoView *pView = [[BMKActionPaopaoView alloc] initWithCustomView:customPopView];
        pView.backgroundColor = [UIColor lightGrayColor];
        pView.frame = customPopView.frame;
        annotationView.paopaoView = pView;
        
        annotationView.hidePaopaoWhenSingleTapOnMap = YES;
        annotationView.hidePaopaoWhenSelectOthers = YES;
        
        return annotationView;
    }
    return nil;
}

//# pragma <BMKMapViewDelegate>
//- (BMKAnnotationView *)mapView:(BMKMapView *)mapView viewForAnnotation:(id<BMKAnnotation>)annotation {
//    if ([annotation isKindOfClass:[BMKPointAnnotation class]]) {
//        BMKPinAnnotationView *annotationView = (BMKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:@"annotationViewIdentifier"];
//        if (!annotationView) {
//            annotationView = [[BMKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"annotationViewIdentifier"];
//            annotationView.centerOffset = CGPointMake(0, 0);
//            annotationView.calloutOffset = CGPointMake(0, 0);
//            annotationView.enabled3D = NO;
//            annotationView.enabled = YES;
//            annotationView.selected = NO;
//            annotationView.canShowCallout = YES;
//            annotationView.leftCalloutAccessoryView = nil;
//            annotationView.rightCalloutAccessoryView = nil;
//            annotationView.pinColor = BMKPinAnnotationColorRed;
//            annotationView.draggable = YES;
//        }
//        return annotationView;
//    }
//    return nil;
//}

# pragma <CLLocationManagerDelegate>
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if ([self shouldShowMap]) {
        [self openMap];
    } else {
        NSLog(@"Not authorized to open map");
    }
}

# pragma 点击POI时调整地图使得当前POI们于地图中心
- (void)mapView:(BMKMapView *)mapView didSelectAnnotationView:(BMKAnnotationView *)view {
    CLLocationCoordinate2D coordinate = view.annotation.coordinate;
    [self.mapView setZoomLevel:18];
    [self.mapView setCenterCoordinate:coordinate animated:YES];
}

#pragma BMKCloudSearchDelegate
- (void)onGetCloudPoiResult:(NSArray *)poiResultList searchType:(int)type errorCode:(int)error {
    if (error == BMK_CLOUD_NO_ERROR) {
        self.bikeList = [[NSMutableArray alloc] init];
//        NSLog(@"%@", poiResultList[0]);
        BMKCloudPOIList *list = poiResultList[0];
        
        for (BMKCloudPOIInfo *poi in list.POIs) {
            BMKPointAnnotation *annotation = [[BMKPointAnnotation alloc] init];
            annotation.coordinate =  CLLocationCoordinate2DMake(poi.longitude,poi.latitude);
            annotation.title = poi.title;
            [self.bikeList addObject:annotation];
        }
        //注：不在在background调用AppKit, UIKit的API，不然会报：Main Thread Checker: UI API called on a background thread: -[UIView initWithFrame:]的错误，解决办法是用这部分操作放到主线程中去
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.mapView addAnnotations:self.bikeList];
            //将所有annotation显示在地图视图上
            [self.mapView showAnnotations:self.bikeList animated:YES];
        });
        
    } else {
        NSLog(@"检索失败");
    }
}

- (void)onGetCloudPoiDetailResult:(BMKCloudPOIInfo *)poiDetailResult searchType:(int)type errorCode:(int)error {
    NSLog(@"%@", poiDetailResult);
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}



@end
