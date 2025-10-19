//
//  DistanceCalculator.h
//  Tfence
//
//  Created by vision on 10/19/25.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DistanceCalculator : NSObject

// 두 CLLocationCoordinate2D 사이의 거리를 미터(meter) 단위로 계산합니다.
+ (CLLocationDistance)distanceBetween:(CLLocationCoordinate2D)from to:(CLLocationCoordinate2D)to;

@end

NS_ASSUME_NONNULL_END
