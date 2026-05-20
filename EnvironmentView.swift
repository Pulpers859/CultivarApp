import SwiftUI
import SwiftData

// MARK: - Environment View (Tab 4)
struct EnvironmentView: View {
    @Query(sort: \EnvironmentReading.date, order: .reverse) private var readings: [EnvironmentReading]
    @Query(sort: \Plant.nickname) private var plants: [Plant]

    @State private var showAddReading: Bool = false

    var rooms: [String] {
        let names = Set(plants.map { $0.roomLocation }.filter { !$0.isEmpty })
        return ["All"] + names.sorted()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ForestGradients.deepCanopy.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Habitat Monitor")
                                .font(CultivarFont.oldGrowth(26))
                                .foregroundColor(.mushroomCream)
                            Text("Temperature · Humidity · Light")
                                .font(CultivarFont.undergrowth(13))
                                .foregroundColor(.stoneGrey)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                        let groupedPlants = Dictionary(grouping: plants.filter { !$0.roomLocation.isEmpty }, by: { $0.roomLocation })
                        ForEach(groupedPlants.keys.sorted(), id: \.self) { room in
                            RoomCard(room: room, plants: groupedPlants[room] ?? [])
                        }
                        .padding(.horizontal, 16)

                        CultivarButton("Log Environment Reading", icon: "thermometer.medium") {
                            showAddReading = true
                        }
                        .padding(.horizontal, 16)

                        if !readings.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                            CultivarSectionHeader(title: "Recent Readings", icon: "clock", color: .dewDrop)
                                ForEach(readings.prefix(10)) { reading in
                                    EnvironmentReadingRow(reading: reading)
                                }
                            }
                            .padding(.horizontal, 16)
                        }

                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAddReading) {
                AddEnvironmentReadingView()
            }
        }
    }
}

struct RoomCard: View {
    let room: String
    let plants: [Plant]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(.mossGreen)
                Text(room)
                    .font(CultivarFont.canopy(15, weight: .semibold))
                    .foregroundColor(.mushroomCream)
                Spacer()
                Text("\(plants.count) plant\(plants.count == 1 ? "" : "s")")
                    .font(CultivarFont.undergrowth(12))
                    .foregroundColor(.stoneGrey)
            }

            HStack(spacing: 4) {
                ForEach(plants.prefix(8)) { plant in
                    Text(plant.emoji)
                        .font(.system(size: 18))
                }
                if plants.count > 8 {
                    Text("+\(plants.count - 8)")
                        .font(CultivarFont.rings(11))
                        .foregroundColor(.stoneGrey)
                }
            }

            if let dominantLight = plants.map({ $0.lightLevel }).max(by: { a, b in
                plants.filter { $0.lightLevel == a }.count < plants.filter { $0.lightLevel == b }.count
            }) {
                HStack(spacing: 6) {
                    Image(systemName: dominantLight.icon)
                        .foregroundColor(dominantLight.color)
                        .font(.system(size: 12))
                    Text(dominantLight.rawValue)
                        .font(CultivarFont.undergrowth(12))
                        .foregroundColor(.driedGrass)
                }
            }
        }
        .padding(14)
        .forestCard()
    }
}

struct EnvironmentReadingRow: View {
    let reading: EnvironmentReading
    @AppStorage("use_celsius") private var useCelsius: Bool = true

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "thermometer.medium")
                .foregroundColor(.dewDrop)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(reading.roomName)
                    .font(CultivarFont.undergrowth(13))
                    .foregroundColor(.mushroomCream)
                HStack(spacing: 10) {
                    if let t = reading.temperatureCelsius {
                        if useCelsius {
                            Text("\(t, specifier: "%.1f")°C").font(CultivarFont.rings(11)).foregroundColor(.petalCoral)
                        } else if let f = reading.temperatureFahrenheit {
                            Text("\(f, specifier: "%.1f")°F").font(CultivarFont.rings(11)).foregroundColor(.petalCoral)
                        }
                    }
                    if let h = reading.humidityPercent { Text("\(h, specifier: "%.0f")% RH").font(CultivarFont.rings(11)).foregroundColor(.dewDrop) }
                    if let l = reading.lightLux { Text("\(l, specifier: "%.0f") lux").font(CultivarFont.rings(11)).foregroundColor(.goldenPollen) }
                }
            }
            Spacer()
            Text(reading.date.formatted(date: .abbreviated, time: .shortened))
                .font(CultivarFont.rings(10))
                .foregroundColor(.stoneGrey.opacity(0.6))
        }
        .padding(10)
        .forestCard()
    }
}
