//
//  ViewController.swift
//  GoHomeApp
//
//  Created by 鹿山 玲子 on 2020/07/19.
//  Copyright © 2020 reiko.kayama. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import CoreLocation
import RealmSwift

class ViewController: UIViewController, UITextFieldDelegate, CLLocationManagerDelegate, ARSCNViewDelegate {
    
    @IBOutlet weak var arView: ARSCNView!
    @IBOutlet weak var postalCodeField: UITextField!
    @IBOutlet weak var addressField: UITextField!
    @IBOutlet weak var settingButton: UIButton!
    @IBOutlet weak var getLocationButton: UIButton!
    @IBOutlet weak var bottomHeight: NSLayoutConstraint!
    @IBOutlet weak var settingView: UIView!
    
    var locationManager: CLLocationManager!
    let geocoder = CLGeocoder()
    
    // Realmインスタンスを取得する
    let realm = try! Realm()
    let getLocationData = try! Realm().objects(Location.self)
    var location: Location!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getLocationButton.layer.borderWidth = 1.0
        getLocationButton.layer.borderColor = UIColor(named: "Primary")?.cgColor

        postalCodeField.delegate = self
        addressField.delegate = self
        arView.delegate = self
        
        arView.backgroundColor = UIColor.black
        
        //キーボードでフォームが隠れないようにする
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        self.view.addGestureRecognizer(tapGesture)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let configration = ARWorldTrackingConfiguration()
        arView.session.run(configration)
    }

    //フォーム入力完了後
    func textFieldDidEndEditing(_ textField: UITextField) {
        CLGeocoder().convertAddress(from: postalCodeField.text!) {
            (address, error) in
            if let error = error {
                print(error)
                return
            }
            print(address?.administrativeArea as Any)
            print(address?.locality as Any)
            print(address?.subLocality as Any)
            
            let homeAddress:String = (address?.administrativeArea)! + (address?.locality)! + (address?.subLocality)!
            
            if self.addressField.text == "" {
                self.addressField.text = homeAddress
            }
        }
        if addressField.text == "" {
            return addressFieldCheck(false)
        } else {
            return addressFieldCheck(true)
        }
    }
    
    // キーボードを閉じる
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    //フォームが入力済みかどうかでボタンの表示を変更する
    func addressFieldCheck(_ didEdit:Bool) -> () {
        if didEdit {
            settingButton.backgroundColor = UIColor(named: "Primary")
            settingButton.setTitleColor(UIColor.white, for: .normal)
            settingButton.isEnabled = true
        } else {
            settingButton.backgroundColor = UIColor.systemGray
            settingButton.setTitleColor(UIColor.systemGray2, for: .normal)
            settingButton.isEnabled = false
        }
    }
    
    //現在地から自動入力
    @IBAction func getLocation(_ sender: Any) {
        locationManager = CLLocationManager()
        // 位置情報取得許可ダイアログの表示
        guard let locationManager = locationManager else { return }
        locationManager.requestWhenInUseAuthorization()
        
        let status = CLLocationManager.authorizationStatus()
        if status == .authorizedWhenInUse {
            self.locationManager.delegate = self
            // 位置情報取得を開始
            locationManager.startUpdatingLocation()
        }
        addressFieldCheck(true)
    }
    
    //位置情報を住所に変換
    func locationManager( _ manager: CLLocationManager, didUpdateLocations locations: [ CLLocation ] ) {
        if let location = locations.first {
            self.geocoder.reverseGeocodeLocation( location, completionHandler: { ( placemarks, error ) in
                if let placemark = placemarks?.first {
                    //住所
                    let administrativeArea = placemark.administrativeArea == nil ? "" : placemark.administrativeArea!
                    let locality = placemark.locality == nil ? "" : placemark.locality!
                    let subLocality = placemark.subLocality == nil ? "" : placemark.subLocality!
                    let thoroughfare = placemark.thoroughfare == nil ? "" : placemark.thoroughfare!
                    let subThoroughfare = placemark.subThoroughfare == nil ? "" : placemark.subThoroughfare!
                    let placeName = !thoroughfare.contains( subLocality ) ? subLocality : thoroughfare
                    self.addressField.text = administrativeArea + locality + placeName + subThoroughfare
                   }
            } )
        }
    }
    
    //設定する
    @IBAction func setLocation(_ sender: Any) {
        //インスタンス化
        location = Location()
        
        if getLocationData.count != 0 {
            location.id = getLocationData.max(ofProperty: "id")! + 1
        }
        
        //保存
        try! realm.write {
            self.location.postalCode = postalCodeField.text ?? ""
            self.location.homeAddress = self.addressField.text!
            self.realm.add(self.location, update: .modified)
        }
        
        performSegue(withIdentifier: "toMap", sender: nil)
    }
    
    // フォームがキーボードで隠れないようにするメソッド群
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0 {
                self.view.frame.origin.y -= keyboardSize.height
            } else {
                let suggestionHeight = self.view.frame.origin.y + keyboardSize.height
                self.view.frame.origin.y -= suggestionHeight
            }
        }
    }
    @objc func keyboardWillHide() {
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
    }
    @objc func dismissKeyboard() {
        self.view.endEditing(true)
    }
    
}

extension CLGeocoder {

    struct Address {
        var administrativeArea: String? // 都道府県
        var locality: String? // 市区町村
        var subLocality: String? // 地名
    }

    func convertAddress(from postalCode: String, completion: @escaping (Address?, Error?) -> Void) {
        CLGeocoder().geocodeAddressString(postalCode) { (placemarks, error) in
            if let error = error {
                completion(nil, error)
                return
            }
            if let placemark = placemarks?.first {
                let location = CLLocation(
                    latitude: (placemark.location?.coordinate.latitude)!,
                    longitude: (placemark.location?.coordinate.longitude)!
                )
                 CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
                    guard let placemark = placemarks?.first, error == nil else {
                        completion(nil, error)
                        return
                    }
                    var address: Address = Address()
                    address.administrativeArea = placemark.administrativeArea
                    address.locality = placemark.locality
                    address.subLocality = placemark.subLocality
                    completion(address, nil)
                }
            }
        }
    }
}
