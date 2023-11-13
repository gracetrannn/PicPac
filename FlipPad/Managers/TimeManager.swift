//
//  TimeManager.swift
//  FlipPad
//
//  Created by Igor on 13.09.2022.
//  Copyright © 2022 Alex. All rights reserved.
//

import Foundation

struct ApiDate: Codable {
    var year   : Int
    var month  : Int
    var day    : Int
    var hour   : Int
    var minute : Int
    var seconds: Int
}

class TimeManager: NSObject {
    
    static let shared = TimeManager()
    
    func getTime(completion: @escaping (_ unixtime: TimeInterval?) -> Void) {
        makeTimeRequest { [weak self] response in
            guard let response = response,
                  let date = try? JSONDecoder().decode(ApiDate.self, from: response) else {
                completion(nil)
                return
            }
            completion(self?.makeUnixTime(date: date))
        }
    }
    
    private func makeUnixTime(date: ApiDate) -> TimeInterval? {
        let calendar = Calendar(identifier: .gregorian)
        let components = DateComponents(year: date.year, month: date.month, day: date.day, hour: date.hour, minute: date.minute, second: date.seconds)
        return calendar.date(from: components)?.timeIntervalSince1970
    }
    
    private func makeTimeRequest(completion: @escaping (_ response: Data?) -> Void) {
        
        let urlString = "https://timeapi.io/api/Time/current/zone?timeZone=America/New_York" //"http://worldtimeapi.org/api/timezone/Europe/Moscow"
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
//        let params: [String:String] = ["timeZone":"Europe/Amsterdam"]
        var request = URLRequest(url: url)// URLRequest(url: url)
        request.httpMethod = "GET"
//        request.httpBody = try? JSONSerialization.data(withJSONObject: params, options: [])
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 30.0
        sessionConfig.timeoutIntervalForResource = 30.0
        let session = URLSession(configuration: sessionConfig)
        let task = session.dataTask(with: request) { data, ressponse, error in
            if let data = data {
                completion(data)
            } else {
                completion(nil)
            }
        }
        task.resume()
    }
}
