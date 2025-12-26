//
//  PhotoCaptureView.swift
//  FoodTracker
//

import SwiftUI
import SwiftData

struct PhotoCaptureView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var initialImageData: Data? = nil

    @State private var selectedImageData: Data?
    @State private var captureDate: Date?
    @State private var isAnalyzing = false
    @State private var errorMessage: String?
    @State private var showingComparison = false
    @State private var hasProcessedInitialImage = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if let imageData = selectedImageData,
                   let image = UIImage(data: imageData) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                if isAnalyzing {
                    ProgressView("Analyzing your meal...")
                        .padding()
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
            .navigationTitle("Add Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isAnalyzing)
                }
            }
            .fullScreenCover(isPresented: $showingComparison, onDismiss: {
                dismiss()
            }) {
                if let imageData = selectedImageData {
                    ComparisonResultView(imageData: imageData, captureDate: captureDate)
                }
            }
            .onAppear {
                if let data = initialImageData, !hasProcessedInitialImage {
                    hasProcessedInitialImage = true
                    selectedImageData = data
                    captureDate = ImageHelpers.extractCaptureDate(from: data)
                    if FastingSettings.shared.comparisonModeEnabled {
                        showingComparison = true
                    } else {
                        Task {
                            await analyzeMeal()
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
