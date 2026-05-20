import SwiftUI
import SwiftData

// MARK: - Collection Stats View (Tab 5)
struct CollectionStatsView: View {
    @Query private var plants: [Plant]
    @Query private var wishlist: [WishlistItem]

    var body: some View {
        NavigationStack {
            ZStack {
                ForestGradients.deepCanopy.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("The Census")
                                .font(CultivarFont.oldGrowth(26))
                                .foregroundColor(.mushroomCream)
                            Text("Your growing legacy")
                                .font(CultivarFont.undergrowth(13))
                                .foregroundColor(.stoneGrey)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            BigStatCard(value: "\(plants.count)", label: "Total Plants", icon: "leaf.fill", color: .mossGreen)
                            BigStatCard(value: "\(plants.filter { $0.isFavorite }.count)", label: "Favorites", icon: "heart.fill", color: .petalCoral)
                            BigStatCard(value: "\(plants.filter { $0.healthStatus == .thriving }.count)", label: "Thriving", icon: "sparkles", color: .sageGreen)
                            BigStatCard(value: "\(wishlist.filter { !$0.isAcquired }.count)", label: "On Wishlist", icon: "crown.fill", color: .goldenPollen)
                        }
                        .padding(.horizontal, 16)

                        VStack(alignment: .leading, spacing: 12) {
                            CultivarSectionHeader(title: "Health of the Grove", icon: "heart.fill", color: .mossGreen)
                            ForEach(HealthStatus.allCases, id: \.self) { status in
                                let count = plants.filter { $0.healthStatus == status }.count
                                if count > 0 {
                                    HealthBar(status: status, count: count, total: plants.count)
                                }
                            }
                        }
                        .padding(16)
                        .forestCard()
                        .padding(.horizontal, 16)

                        let roomGroups = Dictionary(grouping: plants.filter { !$0.roomLocation.isEmpty }, by: { $0.roomLocation })
                        if !roomGroups.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                CultivarSectionHeader(title: "By Room", icon: "mappin.circle.fill", color: .stoneGrey)
                                ForEach(roomGroups.keys.sorted(), id: \.self) { room in
                                    HStack {
                                        Text(room)
                                            .font(CultivarFont.undergrowth(14))
                                            .foregroundColor(.mushroomCream)
                                        Spacer()
                                        Text("\(roomGroups[room]?.count ?? 0) plants")
                                            .font(CultivarFont.rings(13))
                                            .foregroundColor(.sageGreen)
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                            .padding(16)
                            .forestCard()
                            .padding(.horizontal, 16)
                        }

                        if let oldest = plants.min(by: { $0.acquisitionDate < $1.acquisitionDate }) {
                            VStack(alignment: .leading, spacing: 8) {
                                CultivarSectionHeader(title: "Oldest Grove Member", icon: "tree.fill", color: .cedarWarm)
                                HStack(spacing: 12) {
                                    Text(oldest.emoji).font(.system(size: 32))
                                    VStack(alignment: .leading) {
                                        Text(oldest.nickname)
                                            .font(CultivarFont.canopy(16, weight: .semibold))
                                            .foregroundColor(.mushroomCream)
                                        Text("In your care for \(oldest.ownedDurationString)")
                                            .font(CultivarFont.undergrowth(13))
                                            .foregroundColor(.driedGrass)
                                    }
                                }
                            }
                            .padding(16)
                            .forestCard()
                            .padding(.horizontal, 16)
                        }

                        WishlistSection(items: wishlist)
                            .padding(.horizontal, 16)

                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }

}

struct BigStatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 20))
            Text(value)
                .font(CultivarFont.oldGrowth(32))
                .foregroundColor(.mushroomCream)
            Text(label)
                .font(CultivarFont.undergrowth(12))
                .foregroundColor(.stoneGrey.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .forestCard()
    }
}

struct HealthBar: View {
    let status: HealthStatus
    let count: Int
    let total: Int

    var fraction: Double { total > 0 ? Double(count) / Double(total) : 0 }

    var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: 4) {
                Image(systemName: status.icon)
                    .font(.system(size: 11))
                    .foregroundColor(status.color)
                Text(status.rawValue)
                    .font(CultivarFont.undergrowth(13))
                    .foregroundColor(.driedGrass)
            }
            .frame(width: 130, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(Color.richSoil).frame(height: 8)
                    RoundedRectangle(cornerRadius: 4).fill(status.color.opacity(0.8))
                        .frame(width: geo.size.width * fraction, height: 8)
                }
            }
            .frame(height: 8)

            Text("\(count)")
                .font(CultivarFont.rings(12))
                .foregroundColor(.stoneGrey)
                .frame(width: 24, alignment: .trailing)
        }
    }
}

struct WishlistSection: View {
    let items: [WishlistItem]
    @State private var showAdd: Bool = false

    var active: [WishlistItem] {
        items
            .filter { !$0.isAcquired }
            .sorted {
                if priorityRank($0.priority) == priorityRank($1.priority) {
                    return $0.dateAdded > $1.dateAdded
                }
                return priorityRank($0.priority) > priorityRank($1.priority)
            }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                CultivarSectionHeader(title: "Wishlist", icon: "crown.fill", color: .goldenPollen)
                Spacer()
                Button {
                    showAdd = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(.mossGreen)
                }
            }
            if active.isEmpty {
                Text("Your wishlist is empty")
                    .font(CultivarFont.undergrowth(13))
                    .foregroundColor(.stoneGrey.opacity(0.6))
                    .padding(.vertical, 8)
            } else {
                ForEach(active) { item in
                    HStack(spacing: 10) {
                        Image(systemName: item.priority.icon)
                            .foregroundColor(.goldenPollen)
                        VStack(alignment: .leading) {
                            Text(item.plantName)
                                .font(CultivarFont.undergrowth(14))
                                .foregroundColor(.mushroomCream)
                            if !item.species.isEmpty {
                                Text(item.species)
                                    .font(.system(size: 11, design: .serif))
                                    .italic()
                                    .foregroundColor(.stoneGrey)
                            }
                        }
                        Spacer()
                        CultivarBadge(item.priority.rawValue, color: .goldenPollen)
                    }
                    .padding(10)
                    .forestCard()
                }
            }
        }
        .sheet(isPresented: $showAdd) {
            AddWishlistItemView()
        }
    }

    private func priorityRank(_ priority: WishlistPriority) -> Int {
        switch priority {
        case .grail: return 4
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
    }
}
