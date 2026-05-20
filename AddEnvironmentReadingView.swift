import SwiftUI
import SwiftData

// MARK: - Add Environment Reading
struct AddEnvironmentReadingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var plants: [Plant]

    @AppStorage("use_celsius") private var useCelsius: Bool = true
    @State private var room: String = ""
    @State private var tempStr: String = ""
    @State private var humidStr: String = ""
    @State private var lightStr: String = ""
    @State private var notes: String = ""

    let roomOptions = ["Living Room", "Bedroom", "Kitchen", "Bathroom", "Office", "Balcony", "Sunroom"]

    var body: some View {
        NavigationStack {
            ZStack {
                ForestGradients.deepCanopy.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        FormSection(title: "Location", icon: "mappin.circle.fill") {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(roomOptions, id: \.self) { r in
                                        Button { room = r } label: {
                                            Text(r)
                                                .font(CultivarFont.undergrowth(13))
                                                .foregroundColor(room == r ? .forestFloor : .sageGreen)
                                                .padding(.horizontal, 12).padding(.vertical, 7)
                                                .background(room == r ? Color.mossGreen : Color.midForest.opacity(0.6))
                                                .clipShape(Capsule())
                                        }
                                    }
                                }
                            }
                            TextField("Or type room name", text: $room)
                                .textFieldStyle(GroveTextFieldStyle())
                        }

                        FormSection(title: "Readings", icon: "thermometer.medium") {
                            CultivarFormField(
                                label: useCelsius ? "Temperature (°C)" : "Temperature (°F)",
                                placeholder: useCelsius ? "e.g. 22.5" : "e.g. 72.5",
                                text: $tempStr
                            )
                            CultivarFormField(label: "Humidity (%)", placeholder: "e.g. 60", text: $humidStr)
                            CultivarFormField(label: "Light (lux)", placeholder: "e.g. 500", text: $lightStr)
                        }

                        FormSection(title: "Notes", icon: "note.text") {
                            TextEditor(text: $notes)
                                .font(CultivarFont.undergrowth(14))
                                .foregroundColor(.mushroomCream)
                                .scrollContentBackground(.hidden)
                                .background(Color.richSoil.opacity(0.5))
                                .frame(minHeight: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }

                        CultivarButton("Save Reading", icon: "checkmark.circle.fill") {
                            var tempCelsius = ParsingUtils.parseLocalizedDecimal(tempStr)
                            if !useCelsius, let f = tempCelsius {
                                tempCelsius = (f - 32) * 5 / 9
                            }
                            let reading = EnvironmentReading(
                                roomName: room.trimmingCharacters(in: .whitespacesAndNewlines),
                                temperatureCelsius: tempCelsius,
                                humidityPercent: ParsingUtils.parseLocalizedDecimal(humidStr),
                                lightLux: ParsingUtils.parseLocalizedDecimal(lightStr)
                            )
                            reading.notes = notes
                            let trimmedRoom = room.trimmingCharacters(in: .whitespacesAndNewlines)
                            if let matchingPlant = plants.first(where: { $0.roomLocation.caseInsensitiveCompare(trimmedRoom) == .orderedSame }) {
                                matchingPlant.environmentReadings.append(reading)
                            } else {
                                modelContext.insert(reading)
                            }
                            dismiss()
                        }
                        .disabled(room.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .padding(.horizontal, 16)
                        Spacer(minLength: 40)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Environment Reading")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(.stoneGrey)
                }
            }
        }
    }
}
