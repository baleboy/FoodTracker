//
//  CameraService.swift
//  FoodTracker
//

import AVFoundation
import UIKit

@MainActor
class CameraService: ObservableObject {
    @Published var isAuthorized = false
    @Published var error: CameraError?

    enum CameraError: Error, LocalizedError {
        case notAuthorized
        case captureDeviceNotFound

        var errorDescription: String? {
            switch self {
            case .notAuthorized:
                return "Camera access not authorized. Please enable in Settings."
            case .captureDeviceNotFound:
                return "No camera found"
            }
        }
    }

    func requestAuthorization() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)

        switch status {
        case .authorized:
            isAuthorized = true
        case .notDetermined:
            isAuthorized = await AVCaptureDevice.requestAccess(for: .video)
        default:
            isAuthorized = false
        }
    }

    var isCameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }
}
