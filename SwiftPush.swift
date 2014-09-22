//
//  SwiftPush.swift
//
//  Created by Furkan Üzümcü on 22/09/14.
//  Copyright (c) 2014 Furkan Üzümcü. All rights reserved.

import Foundation
import Alamofire

class SwiftPush {
    
    private let mAPIKey: String
    private let mURLContacts: String = "https://api.pushbullet.com/v2/contacts"
    private let mURLDevices: String = "https://api.pushbullet.com/v2/devices"
    private let mURLMe: String = "https://api.pushbullet.com/v2/users/me"
    private let mURLPushes: String = "https://api.pushbullet.com/v2/pushes"
    private let mURLUploadRequest: String = "https://api.pushbullet.com/v2/upload-request"
    
    struct Contact {
        var name: String, email: String, ID: String
    }
    
    struct Device {
        var ID: String?, pushToken: String?, nickname: String, manufacturer: String?, model: String?, type: String?
        var appVersion: Int?
        var active: Bool
        var pushable: Bool
    }
    
    struct Me {
        var ID: String, name: String, email: String, imageURL: String
    }
    
    struct Push {
        var ID: String, title: String?, body: String?, url: String?, targetDeviceID: String?, senderEmail: String?, receiverEmail: String?, addressName: String?, address: String?, fileName: String?, fileType: String?, fileURL: String?, type: String?
        var modified: Double, created: Double
        var list: Array<JSON>?
        var isActive: Bool
    }
    
    /// Initialize the class with the API key
    init(apiKey: String) {
        mAPIKey = apiKey
    }
    
    /// Gets the list of the contacts and calls the given function with every contact received.
    /// Received contacts are not stored, so do it yourself.
    func getContactList(responseHandler: (Contact?, NSError?) -> ()) {
        Alamofire.request(.GET, mURLContacts)
            .authenticate(user: mAPIKey, password: mAPIKey)
            .response {(request, response, receivedData, error) in
                if error != nil {
                    responseHandler(nil, error)
                    return
                }
                let json = JSON(data: receivedData as NSData)
                for value in json["contacts"].arrayValue! {
                    var c: String? = value["name"].stringValue
                    if c != nil {
                        responseHandler(Contact(name: value["name"].stringValue!, email: value["email"].stringValue!, ID: value["iden"].stringValue!), nil)
                    }
                }
        }
    }
    
    /// Gets the list of the devices and calls the given function with every contact received.
    /// Received contacts are not stored, so do it yourself.
    func getDeviceList(responseHandler: (Device?, NSError?) -> ()) {
        Alamofire.request(.GET, mURLDevices)
            .authenticate(user: mAPIKey, password: mAPIKey)
            .response {(request, response, receivedData, error) in
                if error != nil {
                    responseHandler(nil, error)
                    return
                }
                let json = JSON(data: receivedData as NSData)
                for value in json["devices"].arrayValue! {
                    var c: String? = value["nickname"].stringValue
                    if c != nil {
                        responseHandler(Device(ID: value["iden"].stringValue!, pushToken: value["push_token"].stringValue, nickname: value["nickname"].stringValue!, manufacturer: value["manufacturer"].stringValue, model: value["mdeol"].stringValue, type: value["type"].stringValue, appVersion: value["app_version"].integerValue, active: value["active"].boolValue, pushable: value["pushable"].boolValue), nil)
                    }
                }
        }
    }
    
    /// Gets the user info and calls the given handler function
    func getUserInfo(responseHandler: (Me?, NSError?) -> ()) {
        Alamofire.request(.GET, mURLMe)
            .authenticate(user: mAPIKey, password: mAPIKey)
            .response {(request, response, receivedData, error) in
                if error != nil {
                    responseHandler(nil, error)
                    return
                }
                let json = JSON(data: receivedData as NSData)
                var c: String? = json["email"].stringValue
                if c != nil {
                    responseHandler(Me(ID: json["iden"].stringValue!, name: json["name"].stringValue!, email: json["email"].stringValue!, imageURL: json["image_url"].stringValue!), nil)
                }
        }
    }
    
    /// Gets the push history and calls the given handler function with each push. If onlyActivePushes is true only the active pushes are returned.
    /// Pushes are not stored, so do it yourself.
    func getPushHistory(responseHandler: (Push?, NSError?) -> (), onlyActivePushes: Bool) {
        Alamofire.request(.GET, mURLPushes)
            .authenticate(user: mAPIKey, password: mAPIKey)
            .response {(request, response, receivedData, error) in
                if error != nil {
                    responseHandler(nil, error)
                    return
                }
                let json = JSON(data: receivedData as NSData)
                for value in json["pushes"].arrayValue! {
                    var c: Bool = value["active"].boolValue
                    //If the it's desired to see only the active pushes, skip the inactive ones
                    if onlyActivePushes && c == false {
                        continue
                    }
                    else {
                        responseHandler(self.parsePushData(value), nil)
                    }
                }
        }
    }
    
    /// Parses a JSON push object and returns a Push containing the push data
    private func parsePushData(value: JSON) -> Push {
        var ID = value["iden"].stringValue!
        var title: String? = value["title"].stringValue
        var body: String? = value["body"].stringValue
        var url: String? = value["url"].stringValue
        var targetDeviceID: String? = value["target_device_iden"].stringValue
        var senderEmail: String? = value["sender_email"].stringValue
        var receiverEmail: String? = value["receiver_email"].stringValue
        var addressName: String? = value["name"].stringValue
        var address: String? = value["address"].stringValue
        var fileName: String? = value["file_name"].stringValue
        var fileType: String? = value["file_type"].stringValue
        var fileURL: String? = value["file_url"].stringValue
        var type = value["type"].stringValue
        var modified = value["modified"].doubleValue!
        var created = value["created"].doubleValue!
        var list: Array<JSON>? = value["items"].arrayValue
        var isActive = value["active"].boolValue
        return Push(ID: ID, title: title, body: body, url: url, targetDeviceID: targetDeviceID, senderEmail: senderEmail, receiverEmail: receiverEmail, addressName: addressName, address: address, fileName: fileName, fileType: fileType, fileURL: fileURL, type: type, modified: modified, created: created, list: list, isActive: isActive)
    }
    
    private func push(responseHandler: ((NSError?) -> ())?, parameters: [String : AnyObject]) {
        Alamofire.request(.POST, mURLPushes, parameters: parameters, encoding: .JSON)
            .authenticate(user: mAPIKey, password: mAPIKey)
            .responseJSON {(request, response, output, error) in
                if responseHandler != nil {
                    responseHandler!(error)
                }
        }
    }
    
    /// Pushes the given list. To push to all devices provide nil for both deviceID and email. Provide a responseHandler to be notified if the push succeeds.
    func pushList(title: String, items: Array<String>, deviceID: String?, email: String?, responseHandler: ((NSError?) -> ())?) {
        var parameters = [
            "type": "note",
            "title": title,
            "dummy": ["dumy", 1],
            "items": items,
        ]
        if deviceID != nil {
            parameters["device_iden"] = deviceID!
        }
        if email != nil {
            parameters["email"] = email!
        }
        push(responseHandler, parameters: parameters)
    }
    
    /// Pushes the given note. To push to all devices provide nil for both deviceID and email. Provide a responseHandler to be notified if the push succeeds.
    func pushNote(title: String, body: String, deviceID: String?, email: String?, responseHandler: ((NSError?) -> ())?) {
        var parameters = [
            "type": "note",
            "title": title,
            "dummy": ["dumy", 1],
            "body": body
        ]
        if deviceID != nil {
            parameters["device_iden"] = deviceID!
        }
        if email != nil {
            parameters["email"] = email!
        }
        push(responseHandler, parameters: parameters)
    }
    
    /// Pushes the given address. To push to all devices provide nil for both deviceID and email. Provide a responseHandler to be notified if the push succeeds.
    func pushAddress(name: String, body: String?, address: String, deviceID: String?, email: String?, responseHandler: ((NSError?) -> ())?) {
        var parameters = [
            "type": "address",
            "name": name,
            "dummy": ["dumy", 1],
            "body": body!,
            "address": address
        ]
        if deviceID != nil {
            parameters["device_iden"] = deviceID!
        }
        if email != nil {
            parameters["email"] = email!
        }
        push(responseHandler, parameters: parameters)
    }
    
    /// Pushes the given lin. To push to all devices provide nil for both deviceID and email. Provide a responseHandler to be notified if the push succeeds.
    func pushLink(title: String, body: String?, url: String, deviceID: String?, email: String?, responseHandler: ((NSError?) -> ())?) {
        var parameters = [
            "type": "link",
            "title": title,
            "dummy": ["dumy", 1],
            "body": body!,
            "url": url
        ]
        if deviceID != nil {
            parameters["device_iden"] = deviceID!
        }
        if email != nil {
            parameters["email"] = email!
        }
        push(responseHandler, parameters: parameters)
    }
}