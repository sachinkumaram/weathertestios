//
//  Forecast.swift
//  YahooWeatherSwift2
//
//  Created by Pratik Somaiya on 21/02/17.
//  Copyright © 2017 Pratik Somaiya. All rights reserved.
//

import UIKit
import RealmSwift

class Forecast: Object {
    dynamic var date = ""
    dynamic var highTemperature = ""
    dynamic var lowTemperature = ""
    dynamic var weatherType = ""
    dynamic var cityName = ""
    
    func save() {
        do
        {
            let realm = try! Realm()
            try realm.write {
                realm.add(self)
            }
        }
        catch let error as NSError
        {
            fatalError(error.localizedDescription)
        }
    }
}
