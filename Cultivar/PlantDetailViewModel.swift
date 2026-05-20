import Foundation
import Combine

@MainActor
final class PlantDetailViewModel: ObservableObject {
    func toggleFavorite(for plant: Plant) {
        plant.isFavorite.toggle()
    }

    func quickWater(for plant: Plant) {
        PlantCareService.recordCare(for: plant, careType: .watering)
    }

    func quickFertilize(for plant: Plant) {
        PlantCareService.recordCare(for: plant, careType: .fertilizing)
    }

    func applyPhotoData(_ data: Data?, to plant: Plant) {
        guard let data else {
            return
        }
        plant.photoData = data
    }
}
