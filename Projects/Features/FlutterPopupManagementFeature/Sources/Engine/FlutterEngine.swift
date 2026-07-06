//
//  FlutterEngine.swift
//  FlutterPopupManagementFeature
//
//  Created by 김동현 on 7/6/26.
//

import Flutter
import FlutterPluginRegistrant

final class FlutterRuntime {
    static let shared = FlutterRuntime()
    
    let engine = FlutterEngine(name: "poppang.flutter")
    
    func start() {
        engine.run()
        GeneratedPluginRegistrant.register(with: engine)
    }
    
    func makeViewController() -> FlutterViewController {
        FlutterViewController(engine: engine, nibName: nil, bundle: nil)
    }
}
