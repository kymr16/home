//
//  Location.swift
//  home
//
//  Created by 鹿山 玲子 on 2020/07/25.
//  Copyright © 2020 reiko.kayama. All rights reserved.
//

import Foundation
import RealmSwift

class Location: Object {
    // 管理用 ID プライマリーキー
    @objc dynamic var id = 0
    
    // 郵便番号(任意)
    @objc dynamic var postalCode = ""

    // 住所
    @objc dynamic var homeAddress = ""

    // id をプライマリーキーとして設定
    override static func primaryKey() -> String? {
        return "id"
    }
}
