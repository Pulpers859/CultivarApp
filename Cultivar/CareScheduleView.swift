import SwiftUI
import SwiftData
import Combine

// MARK: - Care Schedule View (Tab 2)
struct CareScheduleView: View {
    @Query(sort: \Plant.nickname) private var plants: [Plant]
    @State private var selectedPlant: Plant? = nil
    @State private var now: Date = Date()

    private let clock = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var thirstyPlants: [Plant] { plants.filter { ($0.daysUntilWater(relativeTo: now) ?? 0) <= 0 } }
    var upcomingPlants: [Plant] { plants.filter { ($0.daysUntilWater(relativeTo: now) ?? 0) > 0 } }

    var body: some View {
        NavigationStack {
            ZStack {
                ForestGradients.deepCanopy.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("The Watering Round")
                                .font(CultivarFont.oldGrowth(26))
                                .foregroundColor(.mushroomCream)
                            Text(now.formatted(date: .complete, time: .omitted))
                                .font(CultivarFont.undergrowth(13))
                                .foregroundColor(.stoneGrey)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                        if !thirstyPlants.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                CultivarSectionHeader(title: "Needs Water Now", icon: "drop.fill", color: .rainwaterBlue)
                                ForEach(thirstyPlants) { plant in
                                    CareTaskRow(plant: plant, taskType: .water, now: now)
                                        .onTapGesture { selectedPlant = plant }
                                }
                            }
                            .padding(.horizontal, 16)
                        }

                        if !upcomingPlants.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                CultivarSectionHeader(title: "Coming Up", icon: "calendar", color: .sageGreen)
                                ForEach(upcomingPlants.prefix(10)) { plant in
                                    CareTaskRow(plant: plant, taskType: .upcoming, now: now)
                                        .onTapGesture { selectedPlant = plant }
                                }
                            }
                            .padding(.horizontal, 16)
                        }

                        if plants.isEmpty {
                            EmptyStateCard(title: "No plants yet", subtitle: "Add plants to your grove to see care tasks here")
                                .padding(.horizontal, 16)
                        }

                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $selectedPlant) { plant in
                PlantDetailView(plant: plant)
            }
            .onReceive(clock) { now = $0 }
        }
    }
}

struct CareTaskRow: View {
    let plant: Plant
    let taskType: TaskType
    let now: Date

    enum TaskType { case water, upcoming }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.midForest)
                    .frame(width: 48, height: 48)
                if let img = plant.profileImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                } else {
                    Text(plant.emoji)
                        .font(.system(size: 26))
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(plant.nickname)
                    .font(CultivarFont.canopy(15, weight: .semibold))
                    .foregroundColor(.mushroomCream)
                HStack(spacing: 6) {
                    if !plant.roomLocation.isEmpty {
                        Text(plant.roomLocation)
                            .font(CultivarFont.undergrowth(11))
                            .foregroundColor(.stoneGrey)
                    }
                    if let days = plant.daysUntilWater(relativeTo: now) {
                        Text(days <= 0 ? "Overdue!" : "Due in \(days) day\(days == 1 ? "" : "s")")
                            .font(CultivarFont.rings(11))
                            .foregroundColor(days <= 0 ? .petalCoral : .sageGreen)
                    }
                }
            }
            Spacer()

            if taskType == .water {
                Button {
                    PlantCareService.recordCare(for: plant, careType: .watering)
                } label: {
                    Image(systemName: "drop.fill")
                        .foregroundColor(.rainwaterBlue)
                        .padding(10)
                        .background(Color.rainwaterBlue.opacity(0.15))
                        .clipShape(Circle())
                }
            }
        }
        .padding(12)
        .forestCard(isUrgent: taskType == .water)
    }
}
