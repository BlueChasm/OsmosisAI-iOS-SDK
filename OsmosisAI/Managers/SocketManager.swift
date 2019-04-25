//  Copyright © 2018 OsmosisAI, Inc. All rights reserved.

/*
 CONFIDENTIALITY NOTICE:
 This Software and all associated source files are confidential
 and intended only for use by individual or entity to which addressed
 and may contain information that is privileged, confidential and exempt from disclosure under applicable law.
 If you are not the intended recipient, be aware that any use, dissemination or disclosure,
 distribution or copying of communication or attachments is strictly prohibited.
 */

import Foundation
import Starscream
import SwiftyJSON

enum PacketKey : String {
  case deviceModel
  case deviceName
  case systemName
  case systemVersion
  case localizedModel
  case identifier
  case batteryLevel
  case location
  case text
  case image
  case classifier
  case labels
}

enum AISocketAction: String {
  case queryBaseData = "query_base_data"
}

enum RTSocketAction: String {
  case queryConfig      = "query_config"
  case eventSubmission  = "event_submission"
  case unknown          = "unknown"
}

let RTwebserviceURL = "ws://kobayashi.local.chasmforge.com:32082"
let AIwebserviceURL = "ws://kobayashi.local.chasmforge.com:32090"

public class SocketManager {
  
  // MARK: - Properties
  
  static let shared = SocketManager()
  
  var RTsocket: WebSocket!
  
  let deviceModel = UIDevice.current.model
  let deviceName = UIDevice.current.name
  let systemName = UIDevice.current.systemName
  let systemVersion = UIDevice.current.systemVersion
  let localizedModel = UIDevice.current.localizedModel
  let identifier = UIDevice.current.identifierForVendor
  let batteryLevel = UIDevice.current.batteryLevel
  
  var blockUpload = false

  
  // MARK: - Private Methods
  
  func connect() {
    guard let clientID = Authentication.shared.clientID,
      let secret = Authentication.shared.clientSecret else {
        print("Please enter you clientID & secret")
        return
    }
    
    let urlString = "\(RTwebserviceURL)/ingress/\(clientID)/\(secret)/"
    guard let url = URL(string: urlString) else {
      print("Invalid URL - Please contact support")
      return
    }
    
    RTsocket = WebSocket(url: url)
    
    RTsocket?.onConnect = { [weak self] in
      self?.writeRTSocket(action: .queryConfig)
    }
    
    RTsocket?.onDisconnect = { (error: Error?) in
      let errorString = error?.localizedDescription ?? ""
      // RTV: TODO - Handle socket disconnect
      print("websocket is disconnected: \(errorString)")
    }
    
    RTsocket?.onText = { [weak self] (text: String) in
      let json = JSON(parseJSON: text)
      self?.handleRTSocketResponse(json: json)
    }
    
    RTsocket?.onData = { (data: Data) in
      // RTV: This should never happen
      print("got some data: \(data.count)")
    }
    
    RTsocket.connect()
  }
  
  func writeRTSocket(action: RTSocketAction, args: [String]? = []) {
    let queryConfig: [String : Any] = ["action": action.rawValue,
                                       "args": args]
    let json = JSON(queryConfig)
    
    if let rawString = json.rawString(String.Encoding.utf8, options: []) {
      self.RTsocket?.write(string: rawString)
    }
  }
  
  func compileRTPacket(text: [String]?, image: UIImage?, classifier: String?, detections: [[String : Any]]?) -> [String : Any] {
    var packet: [String : Any] = [:]
    
    packet[PacketKey.deviceModel.rawValue] = deviceModel
    packet[PacketKey.deviceName.rawValue] = deviceName
    packet[PacketKey.systemName.rawValue] = systemName
    packet[PacketKey.systemVersion.rawValue] = systemVersion
    packet[PacketKey.localizedModel.rawValue] = localizedModel
    
    if let i = identifier {
      packet[PacketKey.identifier.rawValue] = "\(i)"
    }
    
    if let c = classifier {
      packet[PacketKey.classifier.rawValue] = c
    }
    
    packet[PacketKey.labels.rawValue] = detections ?? [:]
    
    if let i = image,
      let jpeg = i.jpegData(compressionQuality: 0.3) {
      let strBase64 = jpeg.base64EncodedString(options: .lineLength64Characters)
      packet[PacketKey.image.rawValue] = strBase64
    } else {
      packet[PacketKey.image.rawValue] = ""
    }
    
    if let t = text {
      packet[PacketKey.text.rawValue] = t
    }
    
    packet[PacketKey.batteryLevel.rawValue] = batteryLevel
    
    if let l = LocationManager.shared.currentLocation {
      let locationPacket = ["lat" : l.coordinate.latitude, "lng" : l.coordinate.longitude]
      packet[PacketKey.location.rawValue] = locationPacket
    }
    
    return packet
  }
  
  func sendRTEventPacket(text: [String]?, image: UIImage?, classifier: String?, detections: [[String : Any]]?) {
    if blockUpload == true { return }
    
    let packet = compileRTPacket(text: text, image: image, classifier: classifier, detections: detections)
    let queryConfig: [String : Any] = ["action": "event_submission",
                                       "args": packet]
    
    let json = JSON(queryConfig)
    if let rawString = json.rawString(String.Encoding.utf8, options: []) {
      blockUpload = true
      RTsocket?.write(string: rawString)
    }
  }
  
  func handleRTSocketResponse(json: JSON) {
    let event = json["event"].stringValue
    guard let socketEvent = RTSocketAction(rawValue: event) else {
        // RTV: TODO - Handle unknown socket event
        return
    }
    
    print(json)
    switch socketEvent {
    case .queryConfig:
      break
    case .eventSubmission:
      if json["args"]["ack"] == 1 {
        blockUpload = false
      }
    case .unknown: return
    }
  }
}
