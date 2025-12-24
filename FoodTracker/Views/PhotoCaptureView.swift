//
//  PhotoCaptureView.swift
//  FoodTracker
//

import SwiftUI
import SwiftData
import PhotosUI

struct PhotoCaptureView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var openCameraDirectly: Bool = false

    @StateObject private var cameraService = CameraService()
    @State private var selectedImageData: Data?
    @State private var captureDate: Date?
    @State private var isAnalyzing = false
    @State private var errorMessage: String?
    @State private var selectedItem: PhotosPickerItem?
    @State private var showingCamera = false
    @State private var hasAutoOpenedCamera = false

    private var isWaitingForCamera: Bool {
        openCameraDirectly && !showingCamera && selectedImageData == nil && !isAnalyzing
    }

    var body: some View {
        NavigationStack {
            Group {
                if isWaitingForCamera {
                    // Minimal view while camera is launching
                    Color(.systemBackground)
                        .overlay {
                            ProgressView()
                        }
                } else {
                    VStack(spacing: 20) {
                        if let imageData = selectedImageData,
                           let image = UIImage(data: imageData) {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 300)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            ContentUnavailableView(
                                "No Photo Selected",
                                systemImage: "photo",
                                description: Text("Take or choose a photo of your meal")
                            )
                            .frame(height: 300)
                        }

                        if isAnalyzing {
                            ProgressView("Analyzing your meal...")
                                .padding()
                        } else {
                            HStack(spacing: 16) {
                                if cameraService.isCameraAvailable {
                                    Button {
                                        Task {
                                            await cameraService.requestAuthorization()
                                            if cameraService.isAuthorized {
                                                showingCamera = true
                                            }
                                        }
                                    } label: {
                                        Label("Camera", systemImage: "camera")
                                    }
                                    .buttonStyle(.bordered)
                                }

                                PhotosPicker(
                                    selection: $selectedItem,
                                    matching: .images
                                ) {
                                    Label("Photos", systemImage: "photo.on.rectangle")
                                }
                                .buttonStyle(.bordered)
                            }
                        }

                        if let error = errorMessage {
                            Text(error)
                                .foregroundStyle(.red)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationTitle(isWaitingForCamera ? "" : "Add Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !isWaitingForCamera {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                        .disabled(isAnalyzing)
                    }
                }
            }
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        selectedImageData = data
                        captureDate = ImageHelpers.extractCaptureDate(from: data)
                        errorMessage = nil
                        await analyzeMeal()
                    }
                }
            }
            .onChange(of: selectedImageData) { oldValue, newValue in
                // Auto-analyze when image comes from camera (selectedItem won't change)
                if oldValue == nil, newValue != nil, selectedItem == nil {
                    Task {
                        await analyzeMeal()
                    }
                }
            }
            .fullScreenCover(isPresented: $showingCamera, onDismiss: {
                // If camera was auto-opened and user cancelled without taking photo, dismiss the view
                if openCameraDirectly && selectedImageData == nil && hasAutoOpenedCamera {
                    dismiss()
                }
            }) {
                CameraView(imageData: $selectedImageData)
                    .ignoresSafeArea()
            }
            .onAppear {
                if openCameraDirectly && !hasAutoOpenedCamera && cameraService.isCameraAvailable {
                    hasAutoOpenedCamera = true
                    Task {
                        await cameraService.requestAuthorization()
                        if cameraService.isAuthorized {
                            showingCamera = true
                        }
                    }
                }
            }
        }
    }

    private func analyzeMeal() async {
        guard let imageData = selectedImageData else { return }

        isAnalyzing = true
        errorMessage = nil

        do {
            let service = APIKeyManager.shared.createSelectedService()
            let result = try await service.analyzeMeal(imageData: imageData)

            let rating = MealRating(rawValue: result.rating) ?? .yellow

            let meal = Meal(
                photoData: imageData,
                calorieEstimate: result.calorieEstimate,
                rating: rating,
                foodName: result.foodName,
                timestamp: captureDate ?? Date()
            )

            modelContext.insert(meal)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }

        isAnalyzing = false
    }
}

struct CameraView: UIViewControllerRepresentable {
    @Binding var imageData: Data?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView

        init(_ parent: CameraView) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                parent.imageData = image.jpegData(compressionQuality: 0.8)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    PhotoCaptureView()
        .modelContainer(for: Meal.self, inMemory: true)
}
