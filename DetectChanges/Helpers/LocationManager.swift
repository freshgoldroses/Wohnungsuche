//
//  LocationManager.swift
//  DetectChanges
//
//  Created by Yuriy Gudimov on 29.03.2023.
//

import Foundation
import CoreLocation

struct LocationManager {
    var locationManager: CLLocationManager
    
    init() {
        self.locationManager = CLLocationManager()
        locationManager.requestAlwaysAuthorization()
        locationManager.allowsBackgroundLocationUpdates = true
        setup()
    }
    
    private func setup() {
        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        locationManager.distanceFilter = 500
    }
}
