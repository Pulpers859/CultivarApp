import SwiftUI
import SwiftData
import PhotosUI

// MARK: - Log Care View
struct LogCareView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var plant: Plant
    let editingLog: CareLog?

    @State private var careType: CareType = .watering
    @State private var notes: String = ""
    @State private var soilMoisture: SoilMoisture = .moist
    @State private var fertiliserUsed: String = ""
    @State private var amount: String = ""
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var photoData: Data? = nil

    init(plant: Plant, editingLog: CareLog? = nil) {
        self.plant = plant
        self.editingLog = editingLog
        _careType = State(initialValue: editingLog?.careType ?? .watering)
        _notes = State(initialValue: editingLog?.notes ?? "")
        _soilMoisture = State(initialValue: editingLog?.soilMoisture ?? .moist)
        _fertiliserUsed = State(initialValue: editingLog?.fertiliserUsed ?? "")
        _amount = State(initialValue: editingLog?.amountMl.map { String(format: "%.0f", $0) } ?? "")
        _photoData = State(initialValue: editingLog?.photoData)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ForestGradients.deepCanopy.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        FormSection(title: "What did you do?", icon: "hand.raised.fill") {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                ForEach(CareType.allCases, id: \.self) { type in
                                    Button {
                                        careType = type
                                    } label: {
                                        HStack(spacing: 8) {
                                            Image(systemName: type.icon)
                                                .foregroundColor(careType == type ? .forestFloor : .mossGreen)
                                            Text(type.rawValue)
                                                .font(CultivarFont.undergrowth(13))
                                                .foregroundColor(careType == type ? .forestFloor : .mushroomCream)
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 8)
                                        .frame(maxWidth: .infinity)
                                        .background(careType == type ? Color.mossGreen : Color.midForest.opacity(0.6))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                }
                            }
                        }

                        if careType == .watering {
                            FormSection(title: "Soil Condition", icon: "drop.fill") {
                                Picker("Soil Moisture Before", selection: $soilMoisture) {
                                    ForEach(SoilMoisture.allCases, id: \.self) { m in
                                        Text(m.rawValue).tag(m)
                                    }
                                }
                                .colorScheme(.dark)
                                .pickerStyle(.segmented)

                                CultivarFormField(label: "Amount (ml)", placeholder: "e.g. 250", text: $amount)
                            }
                        }

                        if careType == .fertilizing {
                            FormSection(title: "Fertiliser Used", icon: "sparkle") {
                                CultivarFormField(label: "Product name", placeholder: "e.g. Miracle-Gro All Purpose", text: $fertiliserUsed)
                            }
                        }

                        FormSection(title: "Add a Photo", icon: "camera.fill") {
                            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                                HStack {
                                    Image(systemName: "photo.on.rectangle.angled")
                                        .foregroundColor(.mossGreen)
                                    Text(photoData == nil ? "Choose from Library" : "Photo Selected ✓")
                                        .font(CultivarFont.undergrowth(14))
                                        .foregroundColor(photoData == nil ? .driedGrass : .mossGreen)
                                }
                            }
                            .onChange(of: selectedPhoto) { _, newItem in
                                Task {
                                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                        photoData = data
                                    }
                                }
                            }
                        }

                        FormSection(title: "Notes", icon: "note.text") {
                            TextEditor(text: $notes)
                                .font(CultivarFont.undergrowth(14))
                                .foregroundColor(.mushroomCream)
                                .scrollContentBackground(.hidden)
                                .background(Color.richSoil.opacity(0.5))
                                .frame(minHeight: 70)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }

                        CultivarButton(editingLog == nil ? "Log Care" : "Save Changes", icon: "checkmark.circle.fill") {
                            saveCare()
                        }
                        .padding(.horizontal, 16)
                        Spacer(minLength: 40)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle(editingLog == nil ? "Log Care for \(plant.nickname)" : "Edit Care Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.stoneGrey)
                }
            }
        }
    }

    func saveCare() {
        if let editingLog {
            let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedFertiliser = fertiliserUsed.trimmingCharacters(in: .whitespacesAndNewlines)
            editingLog.careType = careType
            editingLog.notes = trimmedNotes
            editingLog.soilMoisture = careType == .watering ? soilMoisture : nil
            editingLog.fertiliserUsed = careType == .fertilizing && !trimmedFertiliser.isEmpty ? trimmedFertiliser : nil
            editingLog.amountMl = ParsingUtils.parseLocalizedDecimal(amount)
            editingLog.photoData = photoData
            plant.refreshTrackedCareDates()
        } else {
            PlantCareService.recordCare(
                for: plant,
                careType: careType,
                notes: notes,
                soilMoisture: soilMoisture,
                fertiliserUsed: fertiliserUsed,
                amountMl: ParsingUtils.parseLocalizedDecimal(amount),
                photoData: photoData
            )
        }
        dismiss()
    }
}
