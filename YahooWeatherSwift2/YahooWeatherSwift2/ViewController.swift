//
//  ViewController.swift
//  YahooWeatherSwift2
//
//  Created by Pratik Somaiya on 14/02/17.
//  Copyright © 2017 Pratik Somaiya. All rights reserved.
//

import UIKit
import PKHUD
//import Alamofire
import RealmSwift
import FileProvider

//class ForecastModel: Mappable
//{
//    var date: String?
//    var highTemperature: String?
//    var lowTemperature: String?
//    var weatherType: String?
//    
//    required init(map: Map) {
//        
//    }
//    
//    // Mappable
//    func mapping(map: Map) {
//        date                <- map["date"]
//        highTemperature     <- map["high"]
//        lowTemperature      <- map["low"]
//        weatherType         <- map["text"]
//    }
//}
let kLastCitySearchKey: String = "LastCitySearchKey"
let kLastWeatherStringKey: String = "LastWeatherStringKey"

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var cityNameTextField: UITextField!
    @IBOutlet weak var todayWeatherLabel: UILabel!
    @IBOutlet weak var forecastTableView: UITableView!
    var weatherForecastArray: Results<Forecast>!
    
    //MARK: - ViewController Methods -
    override func viewDidLoad() {
        super.viewDidLoad()
//        self.cityNameTextField.text = "Pune, In"
        let documentsProvider = LocalFileProvider(directory: .documentDirectory, domainMask: .userDomainMask)
        NSLog("Documents directory path: \(documentsProvider.baseURL?.absoluteString)")
        self.loadCachedData()
        // Do any additional setup after loading the view, typically from a nib
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    //MARK: - IBAction -
    @IBAction func onSubmit(_ sender: UIButton) {
        getWeatherData(cityName: self.cityNameTextField.text!)
        self.view.endEditing(true)
    }
    
    //MARK: - Webservice Methods -
    /// This method gets weather data from yahoo weather api
    ///
    /// - Parameter cityName: String reference to name of city
    func getWeatherData(cityName: String) {

        if (cityName.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)).characters.count == 0 {
            self.clearScreen()
            return
        }
        
        //NSLog("Get Weather data called")
        self.showProgressView()
        let yqlQuery : String = "select * from weather.forecast where woeid in (select woeid from geo.places(1) where text=\"\(cityName)\")"
//        NSLog("yql query : \(yqlQuery)")

        let yqlQueryWithPercentageEncoding : String = yqlQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        
        let yqlQueryEnvironmentEncoding : String = "store%3A%2F%2Fdatatables.org%2Falltableswithkeys"
        
        let parameters : Dictionary = ["q" : yqlQueryWithPercentageEncoding,
                                       "format" : "json",
                                       "env": yqlQueryEnvironmentEncoding]
        
        var urlString : String = "https://query.yahooapis.com/v1/public/yql"
        
//      Create custom url with given parameters for get method
        
        urlString += "?"
        for (key, value) in parameters {
            urlString += "\(key)=\(value)&"
        }
        
        let url = URL(string: urlString)!
        
        var urlRequest = URLRequest(url: url,
                                    cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
                                    timeoutInterval: 10.0 * 1000)
        urlRequest.httpMethod = "GET"
        urlRequest.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let task = URLSession.shared.dataTask(with: urlRequest){ (data, response, error) -> Void in
            DispatchQueue.main.async {
                PKHUD.sharedHUD.hide()
            }
            guard error == nil else {
                print("Error while fetching remote content: \(error)")
                return
            }
            
            guard let data = data,
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else
            {
                    print("Nil data received from web service")
                    return
            }
            
            //NSLog("Response : \(json)")
            
            if let queryObj = json?["query"] as? [String: Any],
                let resultsObj = queryObj["results"] as? [String: Any]
            {
                let channelObj = resultsObj["channel"] as! [String: Any]
                let itemObj = channelObj["item"] as! [String: Any]
                let foreCastArray = itemObj["forecast"] as! Array <Dictionary<String, Any>>
//                self.weatherForecastArray = foreCastArray as! Array <Dictionary<String, Any>>
                let searchedCityNameString = channelObj["description"] as! String
                let conditionObj = itemObj["condition"] as! [String: Any]
                let todayTempString = conditionObj["temp"] as! String
                let todayWeatherString = conditionObj["text"] as! String
                let weatherText = "Today, temperature is \(todayTempString)° F and weather is \(todayWeatherString) in \(cityName)"
                
                //UI Updates
                DispatchQueue.main.async {
                    self.saveDataToPersistantStorage(foreCastArray: foreCastArray, cityName: searchedCityNameString.replacingOccurrences(of: "Yahoo! Weather for ", with: ""))
                    UserDefaults.standard.set("\(searchedCityNameString.replacingOccurrences(of: "Yahoo! Weather for ", with: ""))", forKey:kLastCitySearchKey)
                    UserDefaults.standard.set("\(weatherText)", forKey:kLastWeatherStringKey)
                    UserDefaults.standard.synchronize()
                    self.forecastTableView.isHidden = false
                    self.todayWeatherLabel.text = weatherText
                }
                //NSLog("Forecast Array : \(foreCastArray)")
            }
            else
            {
                DispatchQueue.main.async {
                    self.forecastTableView.isHidden = true
                    self.showBlankTableView()
                    self.todayWeatherLabel.text = "No data found. Please try with different city name."
                }
            }
        }
        
        task.resume()
    }
    //MARK: - TableView methods -
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        "weathercell"
        let forecastObj = self.weatherForecastArray[indexPath.row] 
        let cell : WeatherTableViewCell = tableView.dequeueReusableCell(withIdentifier: "weathercell", for: indexPath) as! WeatherTableViewCell
        cell.dateLabel.text = forecastObj.date
        cell.dayTypeLabel.text = forecastObj.weatherType
        cell.highTemperatureLabel.text = "\(forecastObj.highTemperature)° F"
        cell.lowTemperatureLabel.text = "\(forecastObj.lowTemperature)° F"
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.weatherForecastArray.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.view.endEditing(true)
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Weather Forecast"
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int)
    {
        let header:UITableViewHeaderFooterView = view as! UITableViewHeaderFooterView
        header.textLabel?.textColor = UIColor.darkGray
        header.textLabel?.font = self.todayWeatherLabel.font.withSize((header.textLabel?.font?.pointSize)!)
    }
    
    //MARK: - Touches method -
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        self.view.endEditing(true)
    }
    //MARK: - Class Methods -
    
    /// Show Blank TableView
    func showBlankTableView() -> Void {
        let realm = try! Realm()
        self.weatherForecastArray = realm.objects(Forecast.self).filter("cityName = ''")
        self.forecastTableView?.reloadData()
    }
    
    /// Show Progress view
    
    func showProgressView() -> Void
    {
        PKHUD.sharedHUD.contentView = PKHUDTextView(text: "Loading...")
        PKHUD.sharedHUD.dimsBackground = false
        PKHUD.sharedHUD.show()
    }
    
    
    /// Show Empty City Name Alert
    
    func showEmptyCityNameAlert() -> Void
    {
        let alert = UIAlertController(title: "Please enter City Name",
                                      message: "",
                                      preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: { (action) in
            alert.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func clearScreen() -> Void
    {
        DispatchQueue.main.async {
            self.forecastTableView.isHidden = true
            self.showBlankTableView()
            self.todayWeatherLabel.text = ""
            self.showEmptyCityNameAlert()
        }
    }
    
    /// Save Forecast Array objects to Persistant Storage
    ///
    /// - Parameter foreCastArray: Forecast array containing Forecast dictionary objects
    
    func saveDataToPersistantStorage(foreCastArray: Array<Dictionary<String, Any>>, cityName: String) -> Void
    {
        self.removeCityNameForecastData(cityName: cityName)
        for forecast: Dictionary in foreCastArray
        {
            let forecastObj = Forecast()
            forecastObj.date = forecast["date"] as! String
            forecastObj.highTemperature = forecast["high"] as! String
            forecastObj.lowTemperature = forecast["low"] as! String
            forecastObj.weatherType = forecast["text"] as! String
            forecastObj.cityName = "\(cityName)"
            forecastObj.save()
        }
        self.populateTableViewWithForecastData(cityName: cityName)
    }
    
    func removeCityNameForecastData(cityName: String) -> Void
    {
        let realm = try! Realm()
        try! realm.write {
            realm.delete(realm.objects(Forecast.self).filter("cityName = %@",cityName))
        }
    }
    
    func populateTableViewWithForecastData(cityName: String?) -> Void {
        
        let realm = try! Realm()
        var lastSearchedCity : String

        if  cityName == nil {
            NSLog("No String saved to user defaults")
            lastSearchedCity = ""
        }else
        {
            lastSearchedCity = cityName!
        }
        
        self.weatherForecastArray = realm.objects(Forecast.self).filter(NSPredicate(format: "cityName = %@", lastSearchedCity))
        NSLog("Weather forecast array : \(self.weatherForecastArray)")
        self.forecastTableView.reloadData()
    }
    
    func loadCachedData() -> Void
    {
        self.cityNameTextField.text = UserDefaults.standard.string(forKey: kLastCitySearchKey)
        self.todayWeatherLabel.text = UserDefaults.standard.string(forKey: kLastWeatherStringKey)
        self.populateTableViewWithForecastData(cityName: UserDefaults.standard.string(forKey: kLastCitySearchKey))
    }
}

