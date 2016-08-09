//
//  FlickrAPI.swift
//  VirtualTourist
//
//  Created by Demetrius Henry on 8/8/16.
//  Copyright © 2016 Demetrius Henry. All rights reserved.
//

import UIKit
import MapKit

class FlickrAPI: NSObject {
    static var sharedInstance = FlickrAPI()
    
    func searchForPhotosByCoordinate(coordinate: CLLocationCoordinate2D) {
        let url = flickrURLBySearch(coordinate)
        getImagesFromFlickrBySearch(url)
    }
    
    
    private func flickrURLBySearch(coordinate: CLLocationCoordinate2D) -> NSURL{
        let methodParameters = [
                FlickrAPI.FlickrParameterKeys.SafeSearch: FlickrAPI.FlickrParameterValues.UseSafeSearch,
                FlickrAPI.FlickrParameterKeys.BoundingBox: bboxString(coordinate),
                FlickrAPI.FlickrParameterKeys.Extras: FlickrAPI.FlickrParameterValues.MediumURL,
                FlickrAPI.FlickrParameterKeys.APIKey: FlickrAPI.FlickrParameterValues.APIKey,
                FlickrAPI.FlickrParameterKeys.Method: FlickrAPI.FlickrParameterValues.SearchMethod,
                FlickrAPI.FlickrParameterKeys.Format: FlickrAPI.FlickrParameterValues.ResponseFormat,
                FlickrAPI.FlickrParameterKeys.NoJSONCallback: FlickrAPI.FlickrParameterValues.DisableJSONCallback
            ]
        return flickrURLFromParameters(methodParameters)
    }
    
    
    
    private func flickrURLFromParameters(parameters: [String:AnyObject]) -> NSURL {
        let components = NSURLComponents()
        components.scheme = FlickrAPI.URL.APIScheme
        components.host = FlickrAPI.URL.APIHost
        components.path = FlickrAPI.URL.APIPath
        components.queryItems = [NSURLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = NSURLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        return components.URL!
    }
    
    
    private func bboxString(coordinate: CLLocationCoordinate2D) -> String {
        let long = coordinate.longitude
        var longMinus = long-FlickrAPI.Search.BBoxHalfHeight
        var longPlus = long+FlickrAPI.Search.BBoxHalfHeight
        
        let lat = coordinate.latitude
        var latPlus = lat+FlickrAPI.Search.BBoxHalfWidth
        var latMinus = lat-FlickrAPI.Search.BBoxHalfWidth
        
        if longPlus > 180 {
            longPlus = 180
        }
        
        if longMinus < -180 {
            longMinus = -180
        }
        
        if latPlus > 90 {
            latPlus = 90
        }
        
        if latMinus < -90 {
            latMinus = -90
        }
        return "\(longMinus),\(latMinus),\(longPlus),\(latPlus)"
    }
    
    
    private func getImagesFromFlickrBySearch(url: NSURL) {
        let session = NSURLSession.sharedSession()
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            
            func disPlayError(error: String) {
                print(error)
            }
            
            guard (error == nil) else {
                disPlayError("There was an error with your request: \(error?.localizedDescription)")
                return
            }
            
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                disPlayError("Your request returned a status code other than 2xx!")
                print((response as? NSHTTPURLResponse)?.statusCode)
                return
            }
            
            guard let data = data else {
                disPlayError("No data was returned by the request!")
                return
            }
            
            var parsedResult: AnyObject!
            
            do {
                parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            } catch {
                disPlayError("Could not parse JSON data: \(data)")
            }
            print(parsedResult)
        }
        task.resume()
    }
}
