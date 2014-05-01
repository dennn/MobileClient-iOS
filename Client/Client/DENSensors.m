//
//  DENSensors.m
//  Client
//
//  Created by Denis Ogun on 27/12/2013.
//  Copyright (c) 2013 Mulan. All rights reserved.
//

#import "DENSensors.h"
@import CoreMotion;

@interface DENSensors ()

// Core Motion
@property (nonatomic, strong) CMMotionManager *sensorManager;
@property (nonatomic, strong) NSMutableSet *sensors;

@end

@implementation DENSensors

- (instancetype)init
{
    if (self = [super init]) {
        _sensorManager = [[CMMotionManager alloc] init];
        _sensors = [[NSMutableSet alloc] init];
    }
    
    return self;
}

#pragma mark - Sensors

- (void)startMonitoringSensor:(SensorType)sensor
{
    switch (sensor) {
        case NULL_DEVICE:
            break;
            
        case ACCELEROMETER:
        {
            if (self.sensorManager.accelerometerActive == NO) {
                if (self.sensorManager.accelerometerAvailable) {
                    self.sensorManager.accelerometerUpdateInterval = ACCELEROMETER_UPDATE_INTERVAL;
                    [self.sensorManager startAccelerometerUpdates];
                }
            }
            break;
        }
            
        case GYROSCOPE:
        {
            if (self.sensorManager.gyroActive == NO) {
                if (self.sensorManager.gyroAvailable) {
                    self.sensorManager.gyroUpdateInterval = GYROSCOPE_UPDATE_INTERVAL;
                    [self.sensorManager startGyroUpdates];
                }
            }
            break;
        }
            
        default:
            NSLog(@"Request for unknown sensor type");
            
    }
}

- (NSDictionary *)getSensorDataForSensor:(SensorType)sensor
{
    //TODO: this will check with the sensor manager each time to see if it's active. Ideally we should track it ourselves.
    [self startMonitoringSensor:sensor];
    
    switch (sensor) {
        case ACCELEROMETER:
        {
            NSMutableDictionary *sensorDictionary = [NSMutableDictionary new];
            CMAccelerometerData *accelerometerData = self.sensorManager.accelerometerData;
            UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;

            if (orientation == UIInterfaceOrientationLandscapeLeft) {
                [sensorDictionary setObject:[NSNumber numberWithDouble:(accelerometerData.acceleration.x*9.81)] forKey:@"X"];
                [sensorDictionary setObject:[NSNumber numberWithDouble:(accelerometerData.acceleration.y*9.81)] forKey:@"Y"];
                [sensorDictionary setObject:[NSNumber numberWithDouble:(accelerometerData.acceleration.z*9.81)] forKey:@"Z"];
            } else if (orientation == UIInterfaceOrientationLandscapeRight) {
                [sensorDictionary setObject:[NSNumber numberWithDouble:(accelerometerData.acceleration.x*9.81*-1)] forKey:@"X"];
                [sensorDictionary setObject:[NSNumber numberWithDouble:(accelerometerData.acceleration.y*9.81*-1)] forKey:@"Y"];
                [sensorDictionary setObject:[NSNumber numberWithDouble:(accelerometerData.acceleration.z*9.81*-1)] forKey:@"Z"];
            }
            
            return sensorDictionary;
        }
            
        case GYROSCOPE:
        {
            NSMutableDictionary *sensorDictionary = [NSMutableDictionary new];
            CMGyroData *gyroData = self.sensorManager.gyroData;
            [sensorDictionary setObject:[NSNumber numberWithDouble:gyroData.rotationRate.x] forKey:@"X"];
            [sensorDictionary setObject:[NSNumber numberWithDouble:gyroData.rotationRate.y] forKey:@"Y"];
            [sensorDictionary setObject:[NSNumber numberWithDouble:gyroData.rotationRate.z] forKey:@"Z"];
            return sensorDictionary;
        }
            
        default:
            return NULL;
    }
}

+ (SensorType)getSensorForID:(NSInteger)sensorID
{
    if (sensorID >= 3) {
        return BUTTONS;
    }
    
    switch (sensorID) {
        case 0:
            return NULL_DEVICE;
            
        case 1:
            return GYROSCOPE;
            
        case 2:
            return ACCELEROMETER;
            
        default:
            return NO_DEVICE;
    }
}


@end
