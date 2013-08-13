//
//  LocationManager.h
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@class LocationManager;

#define kSharedLocationManager [LocationManager sharedLocationManager]

// -------------------------------------------------------------------------------

typedef void (^LMGeocodeResultHandler)(NSArray *placemarks, NSError *error);
typedef void (^LMOnceUpdateLocationResultHadler)(CLLocation *currentLocation, NSError *error);

// -------------------------------------------------------------------------------

@protocol LocationManagerDelegate <NSObject>
@optional

- (void)locationManagerDidUpdateLocations:(NSArray *)locations; //locations is an array of CLLocation objects in chronological order.
- (void)locationManagerDidFailWithError:(NSError *)error;
- (void)locationManagerDidChangeAuthorizationStatus:(CLAuthorizationStatus)status;

@end

// -------------------------------------------------------------------------------

@interface LocationManager : NSObject

@property (nonatomic) CLLocationAccuracy accuracy; //default kCLLocationAccuracyKilometer

// -------------------------------------------------------------------------------
+ (LocationManager*)sharedLocationManager;
// -------------------------------------------------------------------------------
- (void)addListener:(id)listener;
- (void)removeListener:(id)listener;
// -------------------------------------------------------------------------------
- (CLAuthorizationStatus)authorizationStatus;
- (BOOL)isGeocoding;
- (BOOL)isUpdatingLocation;
// -------------------------------------------------------------------------------
- (void)setCurrentLocation:(CLLocation*)location;
- (void)setCurrentLocationWithCoordinates:(CLLocationCoordinate2D)coord;
- (void)setCurrentLocationWithLatitude:(CLLocationDegrees)latitude longitude:(CLLocationDegrees)longitude;
- (void)setCurrentLocationByAddress:(NSString *)address resultHandler:(void(^)(CLPlacemark *placemark, NSError *error))resultBlock;
// -------------------------------------------------------------------------------
- (void)geocodeAddressString:(NSString *)address resultHandler:(LMGeocodeResultHandler)resultBlock;
- (void)reverseGeocodeCurrentLocation:(LMGeocodeResultHandler)resultBlock;
- (void)reverseGeocodeLocation:(CLLocation *)location resultHandler:(LMGeocodeResultHandler)resultBlock;
- (void)reverseGeocodeCoordinates:(CLLocationCoordinate2D)coord resultHandler:(LMGeocodeResultHandler)resultBlock;
- (void)reverseGeocodeLatitude:(CLLocationDegrees)latitude longitude:(CLLocationDegrees)longitude resultHandler:(LMGeocodeResultHandler)resultBlock;
- (void)cancelGeocode;
// -------------------------------------------------------------------------------
- (CLLocation*)currentLocation;
// -------------------------------------------------------------------------------
- (void)startUpdateLocation;
- (void)updateLocationOnce:(LMOnceUpdateLocationResultHadler)resultBlock;
- (void)stopUpdatingLocation;
// -------------------------------------------------------------------------------
- (CLLocationDistance)distanceFromLocation:(CLLocation*)fromLocation toLocation:(CLLocation*)toLocation;
- (CLLocationDistance)distanceFromCurrentLocationToLocation:(CLLocation*)toLocation;
// -------------------------------------------------------------------------------
@end
