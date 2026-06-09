import SwiftUI
import SwiftData
import PhotosUI

// MARK: - Add Growth Entry View
struct AddGrowthEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var plant: Plant
    let editingEntry: GrowthEntry?

    @State private var entryDate: Date = Date()
    @State private var heightStr: String = ""
    @State private var leafCountStr: String = ""
    @State private var stemCountStr: String = ""
    @State private var milestone: String = ""
    @State private var notes: String = ""
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var photoData: Data? = nil

    init(plant: Plant, editingEntry: GrowthEntry? = nil) {
        self.plant = plant
        self.editingEntry = editingEntry
        _entryDate = State(initialValue: editingEntry?.date ?? Date())
        _heightStr = State(initialValue: editingEntry?.heightCm.map { String(format: "%.1f", $0) } ?? "")
        _leafCountStr = State(initialValue: editingEntry?.leafCount.map(String.init) ?? "")
        _stemCountStr = State(initialValue: editingEntry?.stemCount.map(String.init) ?? "")
        _milestone = State(initialValue: editingEntry?.milestone ?? "")
        _notes = State(initialValue: editingEntry?.notes ?? "")
        _photoData = State(initialValue: editingEntry?.photoData)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ForestGradients.deepCanopy.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        FormSection(title: "Date", icon: "calendar") {
                            DatePicker(
                                "Entry Date",
                                selection: $entryDate,
                                in: ...Date(),
                                displayedComponents: .date
                            )
                            .datePickerStyle(.compact)
                            .font(CultivarFont.undergrowth(14))
                            .tint(.mossGreen)
                        }

                        FormSection(title: "Measurements", icon: "ruler") {
                            CultivarFormField(label: "Height (cm)", placeholder: "e.g. 32.5", text: $heightStr)
                            CultivarFormField(label: "Leaf Count", placeholder: "e.g. 12", text: $leafCountStr)
                            CultivarFormField(label: "Stem Count", placeholder: "e.g. 3", text: $stemCountStr)
                        }

                        FormSection(title: "Milestone", icon: "sparkles") {
                            CultivarFormField(
                                label: "Celebrate something? (optional)",
                                placeholder: "e.g. First new leaf unfurl!",
                                text: $milestone
                            )
                        }

                        FormSection(title: "Photo", icon: "camera.fill") {
                            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                                HStack {
                                    Image(systemName: "photo.on.rectangle.angled").foregroundColor(.mossGreen)
                                    Text(photoData == nil ? "Add Growth Photo" : "Replace Growth Photo")
                                        .font(CultivarFont.undergrowth(14))
                                        .foregroundColor(photoData == nil ? .driedGrass : .mossGreen)
                                }
                            }
                            .onChange(of: selectedPhoto) { _, item in
                                Task { if let d = try? await item?.loadTransferable(type: Data.self) { photoData = d } }
                            }

                            if let data = photoData, let image = UIImage(data: data) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 160)
                                    .frame(maxWidth: .infinity)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.mossGreen.opacity(0.25), lineWidth: 1)
                                    )

                                Button {
                                    photoData = nil
                                    selectedPhoto = nil
                                } label: {
                                    Label("Remove Photo", systemImage: "trash")
                                        .font(CultivarFont.undergrowth(12))
                                        .foregroundColor(.petalCoral)
                                }
                            }

                            Text("Growth photos appear in each plant's Growth timeline.")
                                .font(CultivarFont.undergrowth(11))
                                .foregroundColor(.stoneGrey.opacity(0.75))
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

                        CultivarButton(editingEntry == nil ? "Save Entry" : "Save Changes", icon: "checkmark.circle.fill") {
                            saveGrowthEntry()
                        }
                        .padding(.horizontal, 16)
                        Spacer(minLength: 40)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle(editingEntry == nil ? "Log Growth" : "Edit Growth Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(.stoneGrey)
                }
            }
        }
    }

    func saveGrowthEntry() {
        let parsedHeight = ParsingUtils.parseLocalizedDecimal(heightStr)
        let parsedLeafCount = Int(leafCountStr.trimmingCharacters(in: .whitespacesAndNewlines))
        let parsedStemCount = Int(stemCountStr.trimmingCharacters(in: .whitespacesAndNewlines))
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedMilestone = milestone.trimmingCharacters(in: .whitespacesAndNewlines)

        if let editingEntry {
            editingEntry.date = entryDate
            editingEntry.heightCm = parsedHeight
            editingEntry.leafCount = parsedLeafCount
            editingEntry.stemCount = parsedStemCount
            editingEntry.notes = trimmedNotes
            editingEntry.milestone = trimmedMilestone.isEmpty ? nil : trimmedMilestone
            editingEntry.photoData = photoData
        } else {
            let entry = GrowthEntry(
                heightCm: parsedHeight,
                leafCount: parsedLeafCount,
                notes: trimmedNotes,
                milestone: trimmedMilestone.isEmpty ? nil : trimmedMilestone
            )
            entry.date = entryDate
            entry.stemCount = parsedStemCount
            entry.photoData = photoData
            plant.growthEntries.append(entry)
        }

        if let h = parsedHeight { plant.currentHeightCm = h }
        if let l = parsedLeafCount { plant.currentLeafCount = l }
        dismiss()
    }
}
