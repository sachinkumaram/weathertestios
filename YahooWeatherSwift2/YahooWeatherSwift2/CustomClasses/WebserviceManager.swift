//
//  WebserviceManager.swift
//  YahooWeatherSwift2
//
//  Created by Pratik Somaiya on 14/02/17.
//  Copyright © 2017 Pratik Somaiya. All rights reserved.
//

import Foundation
import Alamofire

class WebserviceManager
{
    //MARK: Shared Instance
    static let sharedInstance : WebserviceManager = {
        let instance = WebserviceManager()
        return instance
    }()
    
    
    func getWeatherData(cityName: String) {
        debugPrint("Get Weather data called")
        
        let yqlQuery : String = "select * from weather.forecast where woeid in (select woeid from geo.places(1) where text=\(cityName))".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        
        let parameters : Parameters = ["q" : yqlQuery]
        
        //let headers : Dictionary = ["ContentType" : "application/json"]
        
        Alamofire.request("https://query.yahooapis.com/v1/public/yql",
                          method: .get,
                          parameters: parameters)
            .responseString { (responseString) in
                debugPrint("Response: \(responseString)")
        }
    }
}
