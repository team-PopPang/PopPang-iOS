//
//  FlutterEngine.swift
//  FlutterPopupManagementFeature
//
//  Created by 김동현 on 7/6/26.
//

import Flutter
import FlutterPluginRegistrant

public final class FlutterEngine {
    public static let shared = FlutterEngine()

    private var isStarted = false
    public let engine = Flutter.FlutterEngine(name: "poppang.flutter")

    private init() {}

    public func start() {
        guard !isStarted else { return }
        engine.run()
        GeneratedPluginRegistrant.register(with: engine)
        isStarted = true
    }

    public func makeViewController() -> FlutterViewController {
        start()
        return FlutterViewController(engine: engine, nibName: nil, bundle: nil)
    }
}
