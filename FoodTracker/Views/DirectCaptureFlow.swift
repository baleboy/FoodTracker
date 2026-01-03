//
//  DirectCaptureFlow.swift
//  FoodTracker
//

import SwiftUI
import SwiftData
import AppIntents

/// A streamlined capture flow for Action Button / Shortcut launches.
/// Goes directly to camera with no intermediate UI.
struct DirectCaptureFlow: View {
    @Environment(\.modelContext) private var modelContext

    let onComplete: () -> Void

    @State private var phase: CapturePhase = .camera
    @State private var capturedImageData: Data?
    @State private var isAnalyzing = false
    @State private var errorMessage: String?

    private enum CapturePhase {
        case camera
        case analyzing
        case done
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch phase {
            case .camera:
                CameraView(imageData: $capturedImageData)
                    .ignoresSafeArea()

            case .analyzing:
                analysisView

            case .done:
                Color.clear
            }
        }
        .onChange(of: capturedImageData) { _, newData in
            if let data = newData {
                phase = .analyzing
                Task {
                    await analyzeMeal(imageData: data)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .cameraCancelled)) { _ in
            onComplete()
        }
    }

    private var analysisView: some View {
        VStack(spacing: 20) {
            if let imageData = capturedImageData,
               let image = UIImage(data: imageData) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            if isAnalyzing {
                ProgressView("Analyzing your meal...")
                    .tint(.white)
                    .foregroundStyle(.white)
            }

            if let error = errorMessage {
                VStack(spacing: 16) {
                    Text(error)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)

                    Button("Done") {
                        onComplete()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding()
    }

    private func analyzeMeal(imageData: Data) async {
        isAnalyzing = true
        errorMessage = nil

        let captureDate = ImageHelpers.extractCaptureDate(from: imageData)

        do {
            let service = APIKeyManager.shared.createSelectedService()
            let result = try await service.analyzeMeal(imageData: imageData)

            let meal = Meal(
                photoData: imageData,
                response: result,
                timestamp: captureDate ?? Date()
            )

            modelContext.insert(meal)

            // Donate intent so the system can suggest meal capture
            try? await CaptureMealIntent().donate()

            phase = .done
            onComplete()
        } catch {
            errorMessage = error.localizedDescription
            isAnalyzing = false
        }
    }
}

extension Notification.Name {
    static let cameraCancelled = Notification.Name("cameraCancelled")
}
