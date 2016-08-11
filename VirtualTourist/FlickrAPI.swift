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
    
    func searchForPhotosByCoordinate(coordinate: CLLocationCoordinate2D, completionHandlerForSearch: (data: [String:AnyObject]?, errorString: String?) -> Void) {
        let parameters = parametersForURLBySearch(coordinate)
        let url = flickrURLFromParameters(parameters)
        getImagesFromFlickrBySearch(url) { (data, errorString) in
            guard let data = data else {
                completionHandlerForSearch(data: nil, errorString: errorString)
                return
            }
            completionHandlerForSearch(data: data, errorString: nil)
        }
    }
    
    func downloadImageFromFlickr(imageURL: NSURL, completionHandlerForImageDownload: (imageData: NSData?, errorString: String?) -> Void) {
        let session = NSURLSession.sharedSession()
        let request = NSURLRequest(URL: imageURL)
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            func returnError(errorString: String) {
                completionHandlerForImageDownload(imageData: nil, errorString: errorString)
            }
            
            guard (error == nil) else {
                returnError("There was an error with your request: \(error?.localizedDescription)")
                return
            }
            
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                returnError("Your request returned a status code other than 2xx! \((response as? NSHTTPURLResponse)?.statusCode)")
                return
            }
            
            guard let data = data else {
                returnError("No data was returned by the request!")
                return
            }
            
            completionHandlerForImageDownload(imageData: data,errorString: nil)
        }
        task.resume()
        
//        guard let data = NSData(contentsOfURL: imageURL) else {
//            completionHandlerForImageDownload(imageData: nil, errorString: "Could not download image")
//            return
//        }
//
//        completionHandlerForImageDownload(imageData: data, errorString: nil)
    }
    
    
    private func parametersForURLBySearch(coordinate: CLLocationCoordinate2D) -> [String:AnyObject] {
        let methodParameters = [
                FlickrAPI.FlickrParameterKeys.SafeSearch: FlickrAPI.FlickrParameterValues.UseSafeSearch,
                FlickrAPI.FlickrParameterKeys.BoundingBox: bboxString(coordinate),
                FlickrAPI.FlickrParameterKeys.Extras: FlickrAPI.FlickrParameterValues.MediumURL,
                FlickrAPI.FlickrParameterKeys.APIKey: FlickrAPI.FlickrParameterValues.APIKey,
                FlickrAPI.FlickrParameterKeys.Method: FlickrAPI.FlickrParameterValues.SearchMethod,
                FlickrAPI.FlickrParameterKeys.PerPage: FlickrAPI.FlickrParameterValues.ResultsPerPage,
                FlickrAPI.FlickrParameterKeys.Format: FlickrAPI.FlickrParameterValues.ResponseFormat,
                FlickrAPI.FlickrParameterKeys.NoJSONCallback: FlickrAPI.FlickrParameterValues.DisableJSONCallback
            ]
        return methodParameters
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
    
    
    private func getImagesFromFlickrBySearch(url: NSURL, completionHandlerForGET: (data: [String:AnyObject]?, errorString: String?) -> Void) {
        let session = NSURLSession.sharedSession()
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            
            func returnError(errorString: String) {
                completionHandlerForGET(data: nil, errorString: errorString)
            }
            
            guard (error == nil) else {
                returnError("There was an error with your request: \(error?.localizedDescription)")
                return
            }
            
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                returnError("Your request returned a status code other than 2xx! \((response as? NSHTTPURLResponse)?.statusCode)")
                return
            }
            
            guard let data = data else {
                returnError("No data was returned by the request!")
                return
            }
            
            var parsedResult: [String:AnyObject]!
            
            do {
                parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments) as! [String:AnyObject]
            } catch {
                returnError("Could not parse JSON data: \(data)")
            }
            
            guard let photosDictionary = parsedResult["photos"] as? [String:AnyObject] else {
                returnError("Could not get photos from downloaded data")
                return
            }
            
            completionHandlerForGET(data: photosDictionary, errorString: nil)
        }
        task.resume()
    }
}
