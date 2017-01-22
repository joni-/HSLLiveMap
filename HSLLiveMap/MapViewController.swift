//
//  MapViewController.swift
//  HSLLiveMap
//
//  Created by Joni Nevalainen on 22/01/17.
//  Copyright © 2017 Joni Nevalainen. All rights reserved.
//

import UIKit
import CocoaMQTT
import MapKit
import Foundation

class MapViewController: UIViewController, CocoaMQTTDelegate, MKMapViewDelegate {

    @IBOutlet weak var map: MKMapView!

    var points: [String:MKPointAnnotation] = [:]
    var mqtt: CocoaMQTT!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        mqtt = CocoaMQTT(clientID: "MQTT-LiveIOSApp", host: "mqtt.hsl.fi", port: 1883)
        mqtt.delegate = self
        self.map.delegate = self


        // Zoom around Helsinki area
        let coordinate = CLLocationCoordinate2D(latitude: 60.20, longitude: 24.92)
        let span = MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
        let region = MKCoordinateRegionMake(coordinate, span)
        self.map.setRegion(region, animated: false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        mqtt.connect()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidAppear(animated)
        mqtt.disconnect()
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let pin = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "pin")
        pin.pinTintColor = UIColor.green
        return pin
    }

    func mqtt(_ mqtt: CocoaMQTT, didConnect host: String, port: Int) {
        mqtt.subscribe("/hfp/journey/#")
    }

    func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
    }

    func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
    }

    func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
    }

    func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16 ) {
        if let data = message.string!.data(using: String.Encoding.utf8) {
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                if let dict = json as? [String:Any] {
                    if let vp = dict["VP"] as? [String:Any] {
                        let vehicleId = vp["veh"] as! String
                        let longitude = vp["long"] as! Double
                        let latitude = vp["lat"] as! Double
                        let line = vp["desi"] as! String

                        if self.points[vehicleId] != nil {
                            self.map.removeAnnotation(self.points[vehicleId]!)
                            self.points.removeValue(forKey: vehicleId)
                        }

                        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                        let p = MKPointAnnotation()
                        p.coordinate = coordinate
                        self.points[vehicleId] = p
                        
                        map.addAnnotation(p)
                    }
                }
            } catch {}
        }
    }

    func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopic topic: String) {
        print("subscribed to " + topic)
    }

    func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopic topic: String) {
        print("unsubscribed from " + topic)
    }

    func mqttDidPing(_ mqtt: CocoaMQTT) {
    }

    func mqttDidReceivePong(_ mqtt: CocoaMQTT) {
    }

    func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
    }
}

