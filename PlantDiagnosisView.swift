import SwiftUI
import PhotosUI

// MARK: - Plant Diagnosis View (AI powered)
struct PlantDiagnosisView: View {
    @Environment(\.dismiss) private var dismiss
    let plant: Plant

    @State private var symptoms: String = ""
    @State private var diagnosisResult: String = ""
    @State private var isLoading: Bool = false
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var photoData: Data? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                ForestGradients.deepCanopy.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        VStack(spacing: 6) {
                            Image(systemName: "waveform.path.ecg")
                                .font(.system(size: 36))
                                .foregroundColor(.wildBerry)
                            Text("Plant Diagnosis")
                                .font(CultivarFont.oldGrowth(22))
                                .foregroundColor(.mushroomCream)
                            Text("Describe what you're seeing and I'll help identify what's wrong")
                                .font(CultivarFont.undergrowth(13))
                                .foregroundColor(.stoneGrey)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 12)
                        .padding(.horizontal, 20)

                        FormSection(title: "Describe the Symptoms", icon: "text.magnifyingglass") {
                            TextEditor(text: $symptoms)
                                .font(CultivarFont.undergrowth(14))
                                .foregroundColor(.mushroomCream)
                                .scrollContentBackground(.hidden)
                                .background(Color.richSoil.opacity(0.5))
                                .frame(minHeight: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 10))

                            Text("e.g. yellowing lower leaves, brown crispy tips, wilting despite watering, white powder on leaves...")
                                .font(CultivarFont.undergrowth(11))
                                .foregroundColor(.stoneGrey.opacity(0.6))
                        }

                        FormSection(title: "Add a Photo (optional)", icon: "camera.fill") {
                            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                                HStack {
                                    Image(systemName: "photo.badge.plus").foregroundColor(.mossGreen)
                                    Text(photoData == nil ? "Attach a Photo" : "Photo Attached ✓")
                                        .font(CultivarFont.undergrowth(14))
                                        .foregroundColor(photoData == nil ? .driedGrass : .mossGreen)
                                }
                            }
                            .onChange(of: selectedPhoto) { _, item in
                                Task { if let d = try? await item?.loadTransferable(type: Data.self) { photoData = d } }
                            }
                        }

                        CultivarButton(isLoading ? "Consulting the forest..." : "Ask the Grove Keeper", icon: "leaf.fill") {
                            Task { await diagnose() }
                        }
                        .disabled(symptoms.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                        .opacity(symptoms.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading ? 0.5 : 1)
                        .padding(.horizontal, 16)

                        if !diagnosisResult.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 6) {
                                    Image(systemName: "leaf.fill")
                                        .foregroundColor(.mossGreen)
                                    Text("Grove Keeper's Assessment")
                                        .font(CultivarFont.canopy(14, weight: .semibold))
                                        .foregroundColor(.sageGreen)
                                }
                                Text(diagnosisResult)
                                    .font(CultivarFont.undergrowth(14))
                                    .foregroundColor(.mushroomCream)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(16)
                            .forestCard()
                            .padding(.horizontal, 16)
                        }

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("Diagnose \(plant.nickname)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }.foregroundColor(.stoneGrey)
                }
            }
        }
    }

    func diagnose() async {
        let trimmedSymptoms = symptoms.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSymptoms.isEmpty else { return }

        await MainActor.run { isLoading = true }

        let systemPrompt = """
        You are the Grove Keeper — a wise, deeply experienced botanist and plant pathologist with a warm, nature-connected voice. \
        You are helping a plant parent diagnose issues with their beloved plant. \
        Be specific, practical, and empathetic. Lead with the most likely cause, explain why, then give actionable treatment steps. \
        Use a calm, reassuring tone. Keep your answer thorough but focused — aim for 150-250 words. \
        Format: 1) Most likely cause  2) Why this happens  3) How to treat it  4) One prevention tip.
        """

        let userMessage = """
        Plant: \(plant.nickname) (\(plant.commonName.isEmpty ? plant.species : plant.commonName))
        Location: \(plant.roomLocation.isEmpty ? "Unknown" : plant.roomLocation)
        Light: \(plant.lightLevel.rawValue)
        Watered every: \(plant.wateringIntervalDays) days
        Last watered: \(plant.lastWatered.map { $0.formatted(date: .abbreviated, time: .omitted) } ?? "Unknown")
        Current health: \(plant.healthStatus.rawValue)
        Symptoms described: \(trimmedSymptoms)
        \(photoData == nil ? "No photo attached." : "A plant photo is attached for visual diagnosis.")
        """

        do {
            let response = try await callClaudeAPI(
                systemPrompt: systemPrompt,
                userMessage: userMessage,
                imageData: photoData
            )
            await MainActor.run { diagnosisResult = response }
        } catch {
            await MainActor.run { diagnosisResult = "Unable to reach the Grove Keeper right now. Please check your connection and try again." }
        }

        await MainActor.run { isLoading = false }
    }
}
