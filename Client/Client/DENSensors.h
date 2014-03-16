//
//  DENSensors.h
//  Client
//
//  Created by Denis Ogun on 27/12/2013.
//  Copyright (c) 2013 Mulan. All rights reserved.
//

#import <Foundation/Foundation.h>

#define ACCELEROMETER_UPDATE_INTERVAL 0.05
#define GYROSCOPE_UPDATE_INTERVAL 0.05

typedef NS_ENUM(NSInteger, SensorType) {
    NULL_DEVICE = 0,
    GYROSCOPE = 1,
    ACCELEROMETER = 2,
    BUTTONS = 3,
    NO_DEVICE = -1
};

@interface DENSensors : NSObject

- (NSDictionary *)getSensorDataForSensor:(SensorType)sensor;
+ (SensorType)getSensorForID:(NSInteger)sensorID;

@end
