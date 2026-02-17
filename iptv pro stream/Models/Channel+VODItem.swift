import Foundation

extension Channel {
    func toVODItem() -> VODItem {
        VODItem(
            id: id,
            name: name,
            streamURL: streamURL,
            logoURL: logoURL,
            plot: plot,
            cast: cast,
            director: director,
            genre: genre,
            releaseDate: releaseDate,
            duration: duration,
            rating: rating,
            categoryID: groupTitle,
            containerExtension: containerExtension,
            providerID: providerID,
            streamType: streamType,
            seriesID: streamID
        )
    }
}
