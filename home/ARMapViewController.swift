//
//  ARMapViewController.swift
//  home
//
//  Created by 鹿山 玲子 on 2020/08/02.
//  Copyright © 2020 reiko.kayama. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import CoreLocation
import RealmSwift

class ARMapViewController: UIViewController, CLLocationManagerDelegate, ARSCNViewDelegate {

    @IBOutlet weak var arView: ARSCNView!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var subTextLabel: UILabel!
    @IBOutlet weak var settingButton: UIButton!
    
    let getLocation = try! Realm().objects(Location.self)
    var locationManager: CLLocationManager!
    var homeAddress = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        arView.delegate = self

        let scene = SCNScene(named: "art.scnassets/arrow.scn")!
        arView.scene = scene
        arView.backgroundColor = UIColor.black
        
        settingButton.layer.borderWidth = 1.0
        settingButton.layer.borderColor = UIColor(named: "Gray")?.cgColor
        
        if let getLocation = getLocation.last {
          homeAddress = getLocation.homeAddress
        }
        
        //位置情報取得開始
        setupLocationManager()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let configration = ARWorldTrackingConfiguration()
        arView.session.run(configration)
    }
    
    func setupLocationManager() {
        locationManager = CLLocationManager()
        guard let locationManager = locationManager else { return }

        locationManager.requestWhenInUseAuthorization()

        let status = CLLocationManager.authorizationStatus()
        if status == .authorizedWhenInUse {
            self.locationManager.delegate = self
            locationManager.distanceFilter = 10
            locationManager.startUpdatingLocation()
        }
    }
    
    //位置情報の取得
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        CLGeocoder().geocodeAddressString(homeAddress) { (placemarks, error) in
            if let placemarks = placemarks {
                let targetLat = Double((placemarks.first?.location?.coordinate.latitude)!)
                let targetLng = Double((placemarks.first?.location?.coordinate.longitude)!)
                // ターゲット(家)の緯度経度
                let targetPosition = (la: targetLat, lo: targetLng)
                
                let location = locations.first
                //現在地の緯度経度を取得
                let currentLat = Double((location?.coordinate.latitude)!)
                let currentLng = Double((location?.coordinate.longitude)!)
                // 現在地の緯度経度
                let currentPosition = (la: currentLat, lo: currentLng)
                
                // 現在地とターゲットの距離(小数点3桁)
                let distance = round(1000 * self.getDistance(current: currentPosition, target: targetPosition)) / 1000
                
                self.setLabel(distance)
                print(distance,"\(String(format: "%01d", distance * 1000))m")
              }
        }
    }
    
    //球面三角法で計算
    func getDistance(current: (la: Double, lo: Double), target: (la: Double, lo: Double)) -> Double {
        
        // 緯度経度をラジアンに変換
        let currentLa   = current.la * Double.pi / 180
        let currentLo   = current.lo * Double.pi / 180
        let targetLa    = target.la * Double.pi / 180
        let targetLo    = target.lo * Double.pi / 180
 
        // 赤道半径
        let equatorRadius = 6378137.0;
        
        // 算出
        let averageLat = (currentLa - targetLa) / 2
        let averageLon = (currentLo - targetLo) / 2
        let distance = equatorRadius * 2 * asin(sqrt(pow(sin(averageLat), 2) + cos(currentLa) * cos(targetLa) * pow(sin(averageLon), 2)))
        return distance / 1000
    }
    
    //10メートル以内かどうかで表示切り替え
    func setLabel(_ distance: Double) -> () {
        var distanceText = ""
        
        if distance < 0.01 {
            distanceText = "家にいます"
            self.subTextLabel.isHidden = true
        } else {
            //1km未満の場合はメートル表示
            distanceText = distance < 1 ? "\(String(format: "%01d", distance * 1000))m" : "\(distance)km"
            self.subTextLabel.isHidden = false
        }
        
        self.distanceLabel.text = distanceText
    }

}
