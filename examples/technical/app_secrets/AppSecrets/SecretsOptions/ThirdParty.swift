//
//  ThirdParty.swift
//  AppSecrets
//
//  Created by Fišer Jakub on 17.05.2023.
//

import Foundation
import ArkanaKeys

class ThirdParty {
    let apiKey = ArkanaKeys.Keys.Global().apiKey

    func useApiKey() {
        print("ThirdParty: \(apiKey)")
    }
}
