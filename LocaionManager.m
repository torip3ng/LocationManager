//
//  LocationManager.m
//

#import "LocationManager.h"

@interface LocationManager () <CLLocationManagerDelegate> {
    CLGeocoder *_geoCoder;
    CLLocationManager *_locationManager;
    
    CLLocation *_currentLocation;
    NSString *_currentAddress;
    
    CFMutableArrayRef _listeners;
    
    BOOL _isUpdatingLocationOnce;
    BOOL _isUpdatingLocation;
    
    LMOnceUpdateLocationResultHadler _onceUpdateResultBlock;
}

@end

@implementation LocationManager

#pragma mark -
#pragma mark Syntesize Singleton methods

+ (LocationManager*) sharedLocationManager {
    static LocationManager *sharedLocationManager = nil;
    static dispatch_once_t onceLocationManagerToken;
    dispatch_once(&onceLocationManagerToken, ^{
        sharedLocationManager = [LocationManager new];
    });
    return sharedLocationManager;
}

// -------------------------------------------------------------------------------

#pragma mark -
#pragma mark Lifecycle methods

- (id)init {
    self = [super init];
    if (self) {
        _geoCoder = [CLGeocoder new];
        
        _locationManager = [CLLocationManager new];
        
        _listeners = CFArrayCreateMutable(kCFAllocatorDefault, 0, NULL);
        
        _isUpdatingLocation = NO;
        _isUpdatingLocationOnce = NO;
        
        [self commonInit];
    }
    return self;
}

// -------------------------------------------------------------------------------

- (void)dealloc {
    CFArrayRemoveAllValues(_listeners);
    CFRelease(_listeners);
}

// -------------------------------------------------------------------------------

- (void)commonInit {
    _accuracy = kCLLocationAccuracyKilometer;
    
    [_locationManager setDesiredAccuracy:_accuracy];
    [_locationManager setDistanceFilter:kCLDistanceFilterNone];
    [_locationManager setDelegate:self];
}

// -------------------------------------------------------------------------------

#pragma mark -
#pragma mark Listeners

- (void)addListener:(id)listener {
    @synchronized (self) {
        
        CFIndex arrLength = CFArrayGetCount(_listeners);
        
        if (!CFArrayContainsValue(_listeners, CFRangeMake(0, arrLength), (__bridge const void *)(listener))) {
            CFArrayAppendValue(_listeners, (__bridge const void *)(listener));
        }
    }
}

// -------------------------------------------------------------------------------

- (void)removeListener:(id)listener {
    @synchronized (self) {
        CFIndex arrLength = CFArrayGetCount(_listeners);
        
        if (CFArrayContainsValue(_listeners, CFRangeMake(0, arrLength), (__bridge const void *)(listener))) {
            CFIndex removeItemIdex = CFArrayGetFirstIndexOfValue(_listeners, CFRangeMake(0, arrLength), (__bridge const void *)(listener));
            CFArrayRemoveValueAtIndex(_listeners, removeItemIdex);
        }
    }
}

// -------------------------------------------------------------------------------

- (void)notifyListenersWithBlock:(void(^)(id listener))block {
    @synchronized (self) {
        CFIndex arrLength = CFArrayGetCount(_listeners);
        for (int index = 0; index < arrLength; index++) {
            id item = CFArrayGetValueAtIndex(_listeners, index);
            block(item);
        }
    }
}

// -------------------------------------------------------------------------------

#pragma mark -
#pragma mark Setters / Getters 

- (void)setAccuracy:(CLLocationAccuracy)accuracy {
    _accuracy = accuracy;
    [_locationManager setDesiredAccuracy:_accuracy];
}

// -------------------------------------------------------------------------------

- (void)setCurrentLocation:(CLLocation *)location {
    [self stopUpdatingLocation];
    _currentLocation = location;
}

// -------------------------------------------------------------------------------

- (void)setCurrentLocationWithCoordinates:(CLLocationCoordinate2D)coord {
    [self stopUpdatingLocation];
    _currentLocation = [[CLLocation alloc] initWithLatitude:coord.latitude longitude:coord.longitude];
}

// -------------------------------------------------------------------------------

- (void)setCurrentLocationWithLatitude:(CLLocationDegrees)latitude longitude:(CLLocationDegrees)longitude {
    CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(latitude, longitude);
    [self setCurrentLocationWithCoordinates:coord];
}

// -------------------------------------------------------------------------------

- (void)setCurrentLocationByAddress:(NSString *)address resultHandler:(void(^)(CLPlacemark *placemark, NSError *error))resultBlock {
    @synchronized (self) {
        [_geoCoder geocodeAddressString:address completionHandler:^(NSArray *placemarks, NSError *error) {
            CLPlacemark *placemark = nil;
            
            if (!error) {
                _currentAddress = address;
                placemark =  placemarks[0];
                
                _currentLocation = placemark.location;
            } 
            
            resultBlock(placemark, error);
        }];
    }
}

// -------------------------------------------------------------------------------

- (CLLocation*)currentLocation {
    return _currentLocation;
}

// -------------------------------------------------------------------------------

- (BOOL) isUpdatingLocation {
    return _isUpdatingLocation;
}

// -------------------------------------------------------------------------------

- (BOOL)isGeocoding {
    return [_geoCoder isGeocoding];
}

// -------------------------------------------------------------------------------

#pragma mark -
#pragma mark Geocode methods

- (void)geocodeAddressString:(NSString *)address resultHandler:(LMGeocodeResultHandler)resultBlock {
    [_geoCoder geocodeAddressString:address completionHandler:^(NSArray *placemarks, NSError *error) {
        resultBlock(placemarks, error);
    }];
}

// -------------------------------------------------------------------------------

- (void)reverseGeocodeLocation:(CLLocation *)location resultHandler:(LMGeocodeResultHandler)resultBlock {
    [_geoCoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
        resultBlock(placemarks, error);
    }];
}

// -------------------------------------------------------------------------------

- (void)reverseGeocodeCurrentLocation:(LMGeocodeResultHandler)resultBlock {
    [self reverseGeocodeLocation:_currentLocation resultHandler:resultBlock];
}

// -------------------------------------------------------------------------------

- (void)reverseGeocodeCoordinates:(CLLocationCoordinate2D)coord resultHandler:(LMGeocodeResultHandler)resultBlock {
    CLLocation *locatoin = [[CLLocation alloc] initWithLatitude:coord.latitude longitude:coord.longitude];
    
    [self reverseGeocodeLocation:locatoin resultHandler:resultBlock];
}

// -------------------------------------------------------------------------------

- (void)reverseGeocodeLatitude:(CLLocationDegrees)latitude longitude:(CLLocationDegrees)longitude resultHandler:(LMGeocodeResultHandler)resultBlock {
    CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(latitude, longitude);
    
    [self reverseGeocodeCoordinates:coord resultHandler:resultBlock];
}

// -------------------------------------------------------------------------------

- (void)cancelGeocode {
    @synchronized (self) {
        [_geoCoder cancelGeocode];
    }
}

// -------------------------------------------------------------------------------

#pragma mark -
#pragma mark CLLocationManager methods

- (void)startUpdateLocation {
    if (_isUpdatingLocation)
        return;
    
    _isUpdatingLocation = YES;
    [_locationManager startUpdatingLocation];
}

// -------------------------------------------------------------------------------

- (void)updateLocationOnce:(LMOnceUpdateLocationResultHadler)resultBlock {
    _isUpdatingLocationOnce = YES;
    
    _onceUpdateResultBlock = resultBlock;
    
    if (!_isUpdatingLocation) {
        _isUpdatingLocation = YES;
        [_locationManager startUpdatingLocation];
    }
}

// -------------------------------------------------------------------------------

- (void)stopUpdatingLocation {
    _isUpdatingLocation = NO;
    _isUpdatingLocationOnce = NO;
    [_locationManager stopUpdatingLocation];
}

// -------------------------------------------------------------------------------

- (CLAuthorizationStatus)authorizationStatus {
    return [CLLocationManager authorizationStatus];
}

// -------------------------------------------------------------------------------

#pragma mark -
#pragma mark CLLocationManager Delegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    [self updateCurrentLocationAndNotifyListeners:locations];
}

// -------------------------------------------------------------------------------

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    NSArray *locations = nil;
    
    if (oldLocation)
        locations = @[oldLocation, newLocation];
    else
        locations = @[newLocation];
    
    [self updateCurrentLocationAndNotifyListeners:locations];
}

// -------------------------------------------------------------------------------

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    if (_isUpdatingLocationOnce) {
        [self stopUpdatingLocation];
        _onceUpdateResultBlock(nil, error);
        return;
    }
    
    [self notifyListenersWithBlock:^(id listener) {
        if ([listener respondsToSelector:@selector(locationManagerDidFailWithError:)])
            [listener locationManagerDidFailWithError:error];
    }];
}

// -------------------------------------------------------------------------------

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    [self notifyListenersWithBlock:^(id listener) {
        if ([listener respondsToSelector:@selector(locationManagerDidChangeAuthorizationStatus:)])
            [listener locationManagerDidChangeAuthorizationStatus:status];
    }];
}

// -------------------------------------------------------------------------------

- (void) updateCurrentLocationAndNotifyListeners:(NSArray*)locations {
    if (!_isUpdatingLocation)
        return;
    
    _currentLocation = [locations lastObject];
    
    if (_isUpdatingLocationOnce) {
        [self stopUpdatingLocation];
        _onceUpdateResultBlock(_currentLocation, nil);
        return;
    }
    
    [self notifyListenersWithBlock:^(id listener) {
        if ([listener respondsToSelector:@selector(locationManagerDidUpdateLocations:)])
            [listener locationManagerDidUpdateLocations:locations];
    }];
}

// -------------------------------------------------------------------------------

#pragma mark -
#pragma mark Distance methods

- (CLLocationDistance)distanceFromLocation:(CLLocation *)fromLocation toLocation:(CLLocation*)toLocation {
    return [toLocation distanceFromLocation:fromLocation];
}

// -------------------------------------------------------------------------------

- (CLLocationDistance)distanceFromCurrentLocationToLocation:(CLLocation *)toLocation {
    return [self distanceFromLocation:_currentLocation toLocation:toLocation];
}

// -------------------------------------------------------------------------------

@end
