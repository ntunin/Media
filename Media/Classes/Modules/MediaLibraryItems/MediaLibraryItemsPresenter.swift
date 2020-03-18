//
//  Copyright © 2018 Rosberry. All rights reserved.
//

import Ion
import UIKit
import Photos
import CollectionViewTools

typealias MediaLibraryItemsDependencies = HasMediaLibraryService

public final class MediaLibraryItemsPresenter {

    public enum FocusDirection {
        case up
        case down
    }

    private let dependencies: MediaLibraryItemsDependencies
    weak var view: MediaLibraryItemsViewController?

    weak var output: MediaLibraryItemsModuleOutput?

    public var collection: MediaItemCollection? {
        didSet {
            updateMediaItemList(usingPlaceholderTransition: collection !== oldValue)
        }
    }

    public var useStrictItemFiltering: Bool = false
    public var filter: MediaItemFilter = .video {
        didSet {
            updateMediaItemList(usingPlaceholderTransition: true)
        }
    }

    public var fetchResult: MediaItemFetchResult?
    public var selectedItems: [MediaItem] = [] {
        didSet {
            updateSelection()
        }
    }

    var mediaLibraryCollections: [MediaItemCollection] = []
    var activeCollection: MediaItemCollection? {
        didSet {
            collection = activeCollection
        }
    }

    private var focusDirection: FocusDirection = .down

    private lazy var mediaLibraryItemsCollector: Collector<MediaItemFetchResult> = {
        return .init(source: dependencies.mediaLibraryService.mediaItemsEventSource)
    }()

    private lazy var mediaLibraryUpdateEventCollector: Collector<PHChange> = {
        return .init(source: dependencies.mediaLibraryService.mediaLibraryUpdateEventSource)
    }()

    private lazy var factory: MediaLibraryItemSectionsFactory = {
        let factory = MediaLibraryItemSectionsFactory(numberOfItemsInRow: numberOfItemsInRow)
        factory.output = self
        return factory
    }()

    private let maxItemsCount: Int
    public var numberOfItemsInRow: Int

    // MARK: - Lifecycle

    init(maxItemsCount: Int, numberOfItemsInRow: Int, dependencies: MediaLibraryItemsDependencies) {
        self.maxItemsCount = maxItemsCount
        self.numberOfItemsInRow = numberOfItemsInRow
        self.dependencies = dependencies
    }

    func viewReadyEventTriggered() {
        filter = .all

        setupMediaItemsCollector()
        setupMediaLibraryUpdateEventCollector()
    }

    func scrollEventTriggered(direction: FocusDirection) {
        guard focusDirection != direction else {
            return
        }

        focusDirection = direction
    }

    // MARK: - Helpers

    private func setupMediaItemsCollector() {
        mediaLibraryItemsCollector.subscribe { [weak self] (result: MediaItemFetchResult) in
            guard let self = self else {
                return
            }
            self.fetchResult = result
            self.view?.update(with: self.dataSource(for: result.fetchResult), animated: true)
            self.output?.didFinishLoading(result.collection, isMixedContentCollection: result.filter == .all)
        }
    }

    private func setupMediaLibraryUpdateEventCollector() {
        mediaLibraryUpdateEventCollector.subscribe { [weak self] _ in
            if let filter = self?.filter {
                self?.dependencies.mediaLibraryService.fetchMediaItems(in: self?.collection, filter: filter)
            }
        }
    }

    private func dataSource(for result: PHFetchResult<PHAsset>) -> CollectionViewSectionDataSource {
        guard result.count != 0 else {
            return GeneralCollectionViewSectionDataSource(sources: []) { _ in return nil }
        }
        let minimumLineSpacing: CGFloat = 8.0
        let minimumInteritemSpacing: CGFloat = 8.0
        let insets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        let count = result.count
        let itemSource = GeneralCollectionViewItemDataSource(count: count, cellItemProvider: { (index: Int) -> CollectionViewCellItem? in
            let asset = result.object(at: count - index - 1)
            let mediaItem = MediaItem(asset: asset)
            let selectionIndex = self.selectedItems.firstIndex(of: mediaItem)
            let isSelectionInfoLabelHidden = self.maxItemsCount == 1
            return self.factory.makeCellItem(mediaItem: mediaItem,
                                             selectionIndex: selectionIndex,
                                             isSelectionInfoLabelHidden: isSelectionInfoLabelHidden)
        }, sizeProvider: { (_: Int, collectionView: UICollectionView) -> CGSize in
            let numberOfItemsInRow: CGFloat = 4
            let width = (collectionView.bounds.width - insets.left - insets.right -
                numberOfItemsInRow * minimumInteritemSpacing) / numberOfItemsInRow
            return CGSize(width: width, height: width)
        })

        return GeneralCollectionViewSectionDataSource(sources: [itemSource]) { _ in
            let sectionItem = GeneralCollectionViewSectionItem()
            sectionItem.minimumLineSpacing = minimumLineSpacing
            sectionItem.minimumInteritemSpacing = minimumInteritemSpacing
            sectionItem.insets = insets
            return sectionItem
        }
    }

    private func updateMediaItemList(usingPlaceholderTransition: Bool) {
        guard let collection = collection else {
            return
        }

        if usingPlaceholderTransition {
            view?.showMediaItemsPlaceholder(estimatedItemCount: min(collection.estimatedMediaItemsCount ?? 64, 64))
        }

        dependencies.mediaLibraryService.fetchMediaItems(in: collection, filter: filter)
    }

    func updateSelection() {
        view?.updateSelection { item -> Int? in
            selectedItems.firstIndex(of: item)
        }
    }
}

// MARK: - MediaLibraryItemSectionsFactoryOutput

extension MediaLibraryItemsPresenter: MediaLibraryItemSectionsFactoryOutput {

    func didSelect(_ item: MediaItem) {
        var selectedItems = self.selectedItems
        if let index = selectedItems.firstIndex(of: item) {
            selectedItems.remove(at: index)
        }
        else if selectedItems.count < maxItemsCount {
            selectedItems.append(item)
        }
        self.selectedItems = selectedItems
    }

    func didRequestPreviewStart(item: MediaItem, from rect: CGRect) {
        output?.didStartPreview(item: item, from: rect)
    }

    func didRequestPreviewStop(item: MediaItem) {
        output?.didStopPreview(item: item)
    }
}

// MARK: - MediaLibraryItemsModuleInput

extension MediaLibraryItemsPresenter: MediaLibraryItemsModuleInput {

    public func update(isAuthorized: Bool) {
        if isAuthorized {
            dependencies.mediaLibraryService.fetchMediaItems(in: collection, filter: filter)
        }
        else {
            view?.showMediaLibraryDeniedPermissionsPlaceholder()
        }
    }
}