//
//  DistanceCalculator.m
//  Tfence
//
//  Created by vision on 10/19/25.
//

#import "DistanceCalculator.h"

@implementation DistanceCalculator

+ (CLLocationDistance)distanceBetween:(CLLocationCoordinate2D)from to:(CLLocationCoordinate2D)to {
    // CoreLocation의 CLLocation 객체를 사용하여 거리를 계산합니다.
    CLLocation *fromLocation = [[CLLocation alloc] initWithLatitude:from.latitude longitude:from.longitude];
    CLLocation *toLocation = [[CLLocation alloc] initWithLatitude:to.latitude longitude:to.longitude];
    
    // distance(from:) 메소드는 거리를 미터 단위로 반환합니다.
    return [toLocation distanceFromLocation:fromLocation];
}

@end

