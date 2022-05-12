//
//  Copyright © 2018 Rosberry. All rights reserved.
//

import CollectionViewTools
import MediaService

public class EmptyItemCellModel: DiffCompatible {
    public var diffIdentifier: String {
        UUID().uuidString
    }

    let mediaItem: MediaItem
    var selectionIndex: Int?
    let isSelectionInfoLabelHidden: Bool

    init(mediaItem: MediaItem, selectionIndex: Int?) {
        self.mediaItem = mediaItem
        self.selectionIndex = selectionIndex
        isSelectionInfoLabelHidden = false
    }

    init(mediaItem: MediaItem, selectionIndex: Int?, isSelectionInfoLabelHidden: Bool) {
        self.mediaItem = mediaItem
        self.selectionIndex = selectionIndex
        self.isSelectionInfoLabelHidden = isSelectionInfoLabelHidden
    }

    public func makeDiffComparator() -> Bool {
        true
    }
}
