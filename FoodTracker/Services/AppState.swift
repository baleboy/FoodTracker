//
//  AppState.swift
//  FoodTracker
//

import Foundation

@MainActor
final class AppState: ObservableObject {
    static let shared = AppState()

    @Published var shouldOpenCameraDirectly = false

    private init() {}
}
