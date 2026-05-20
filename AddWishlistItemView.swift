import SwiftUI
import SwiftData

// MARK: - Add Wishlist Item
struct AddWishlistItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var species: String = ""
    @State private var priority: WishlistPriority = .medium
    @State private var notes: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                ForestGradients.deepCanopy.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        FormSection(title: "Plant Details", icon: "crown.fill") {
                            CultivarFormField(label: "Common Name", placeholder: "e.g. Pink Princess Philodendron", text: $name)
                            CultivarFormField(label: "Species (optional)", placeholder: "e.g. Philodendron erubescens", text: $species)
                        }

                        FormSection(title: "How Much Do You Want It?", icon: "heart.fill") {
                            ForEach(WishlistPriority.allCases, id: \.self) { p in
                                Button { priority = p } label: {
                                    HStack {
                                        Image(systemName: p.icon).foregroundColor(.goldenPollen)
                                        Text(p.rawValue).font(CultivarFont.undergrowth(14)).foregroundColor(.mushroomCream)
                                        Spacer()
                                        if priority == p {
                                            Image(systemName: "checkmark").foregroundColor(.mossGreen)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
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

                        CultivarButton("Add to Wishlist", icon: "plus.circle.fill") {
                            let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                            let item = WishlistItem(
                                plantName: trimmedName,
                                species: species.trimmingCharacters(in: .whitespacesAndNewlines),
                                priority: priority
                            )
                            item.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
                            modelContext.insert(item)
                            dismiss()
                        }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .padding(.horizontal, 16)
                        Spacer(minLength: 40)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Add to Wishlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(.stoneGrey)
                }
            }
        }
    }
}
