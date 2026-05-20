import SwiftUI
import SwiftData

struct PropagationRecordEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var plant: Plant
    let editingRecord: PropagationRecord?

    @State private var method: PropagationMethod
    @State private var numberOfCuttings: String
    @State private var rootingMedium: String
    @State private var notes: String
    @State private var dateStarted: Date
    @State private var isRooted: Bool
    @State private var rootedDate: Date
    @State private var isPotted: Bool
    @State private var pottedDate: Date
    @State private var successCount: String

    init(plant: Plant, editingRecord: PropagationRecord? = nil) {
        self.plant = plant
        self.editingRecord = editingRecord

        let record = editingRecord
        _method = State(initialValue: record?.method ?? .stemCutting)
        _numberOfCuttings = State(initialValue: String(record?.numberOfCuttings ?? 1))
        _rootingMedium = State(initialValue: record?.rootingMedium ?? "")
        _notes = State(initialValue: record?.notes ?? "")
        _dateStarted = State(initialValue: record?.dateStarted ?? Date())
        _isRooted = State(initialValue: record?.rootedDate != nil)
        _rootedDate = State(initialValue: record?.rootedDate ?? Date())
        _isPotted = State(initialValue: record?.pottedDate != nil)
        _pottedDate = State(initialValue: record?.pottedDate ?? Date())
        _successCount = State(initialValue: String(record?.successCount ?? 0))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ForestGradients.deepCanopy.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        FormSection(title: "Method", icon: "leaf.arrow.circlepath") {
                            Picker("Propagation Method", selection: $method) {
                                ForEach(PropagationMethod.allCases, id: \.self) { option in
                                    Text(option.rawValue).tag(option)
                                }
                            }
                            .pickerStyle(.menu)
                        }

                        FormSection(title: "Details", icon: "list.bullet.rectangle") {
                            CultivarFormField(label: "Cuttings", placeholder: "e.g. 2", text: $numberOfCuttings)
                            CultivarFormField(label: "Rooting Medium", placeholder: "e.g. Water, sphagnum moss", text: $rootingMedium)
                            DatePicker("Started", selection: $dateStarted, displayedComponents: .date)
                                .tint(.mossGreen)
                                .colorScheme(.dark)
                        }

                        FormSection(title: "Status", icon: "checkmark.seal.fill") {
                            Toggle("Rooted", isOn: $isRooted)
                                .tint(.mossGreen)
                            if isRooted {
                                DatePicker("Rooted Date", selection: $rootedDate, displayedComponents: .date)
                                    .tint(.mossGreen)
                                    .colorScheme(.dark)
                            }

                            Toggle("Potted", isOn: $isPotted)
                                .tint(.mossGreen)
                            if isPotted {
                                DatePicker("Potted Date", selection: $pottedDate, displayedComponents: .date)
                                    .tint(.mossGreen)
                                    .colorScheme(.dark)
                            }

                            CultivarFormField(label: "Successful Cuttings", placeholder: "e.g. 1", text: $successCount)
                        }

                        FormSection(title: "Notes", icon: "note.text") {
                            TextEditor(text: $notes)
                                .font(CultivarFont.undergrowth(14))
                                .foregroundColor(.mushroomCream)
                                .scrollContentBackground(.hidden)
                                .background(Color.richSoil.opacity(0.5))
                                .frame(minHeight: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }

                        CultivarButton(editingRecord == nil ? "Save Propagation" : "Save Changes", icon: "checkmark.circle.fill") {
                            saveRecord()
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle(editingRecord == nil ? "Add Propagation" : "Edit Propagation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.stoneGrey)
                }
            }
        }
    }

    private func saveRecord() {
        let parsedCuttings = Int(numberOfCuttings.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 1
        let parsedSuccessCount = Int(successCount.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
        let trimmedMedium = rootingMedium.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

        if let editingRecord {
            editingRecord.method = method
            editingRecord.numberOfCuttings = max(1, parsedCuttings)
            editingRecord.rootingMedium = trimmedMedium
            editingRecord.dateStarted = dateStarted
            editingRecord.rootedDate = isRooted ? rootedDate : nil
            editingRecord.pottedDate = isPotted ? pottedDate : nil
            editingRecord.successCount = max(0, parsedSuccessCount)
            editingRecord.notes = trimmedNotes
        } else {
            let record = PropagationRecord(
                method: method,
                numberOfCuttings: max(1, parsedCuttings),
                rootingMedium: trimmedMedium
            )
            record.dateStarted = dateStarted
            record.rootedDate = isRooted ? rootedDate : nil
            record.pottedDate = isPotted ? pottedDate : nil
            record.successCount = max(0, parsedSuccessCount)
            record.notes = trimmedNotes
            plant.propagations.append(record)
        }

        dismiss()
    }
}
