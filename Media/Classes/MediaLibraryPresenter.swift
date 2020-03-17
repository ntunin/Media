//
//  Copyright © 2018 Rosberry. All rights reserved.
//

import Ion
import Photos

typealias MediaLibraryDependencies = HasMediaLibraryService

final class MediaLibraryPresenter {

    private let dependencies: MediaLibraryDependencies
    weak var view: MediaLibraryViewController?

    weak var output: MediaLibraryModuleOutput?

    var mediaLibraryCollections: [MediaItemCollection] = []
    var activeCollection: MediaItemCollection? {
        didSet {
            updateMediaItemList()
        }
    }

    private lazy var mediaLibraryCollectionListCollector: Collector<[MediaItemCollection]> = {
        return .init(source: dependencies.mediaLibraryService.collectionsEventSource)
    }()
    
    private lazy var mediaLibraryPermissionsCollector: Collector<PHAuthorizationStatus> = {
        return .init(source: dependencies.mediaLibraryService.permissionStatusEventSource)
    }()

    private let maxItemsCount: Int

    // MARK: - Submodules

    lazy var mediaLibraryAlbumListModule: MediaItemCollectionsModule = {
        let module = MediaItemCollectionsModule()
        module.output = self
        return module
    }()

    lazy var mediaLibraryItemListModule: MediaLibraryItemsModule = {
        let module = MediaLibraryItemsModule(maxItemsCount: maxItemsCount)
        module.output = self
        return module
    }()

    // MARK: - Lifecycle

    init(maxItemsCount: Int, dependencies: MediaLibraryDependencies) {
        self.maxItemsCount = maxItemsCount
        self.dependencies = dependencies
    }

    func viewReadyEventTriggered() {
        setupCollectionListCollector()
        setupPermissionsCollector()
    }

    func albumPickerUpdateEventTriggered() {
        mediaLibraryAlbumListModule.input.updateAlbumList()
    }

    func filterVideosEventTriggered() {
        mediaLibraryItemListModule.input.filter = .video
    }

    func filterAllEventTriggered() {
        mediaLibraryItemListModule.input.filter = .all
    }

    func confirmationEventTriggered() {
        var selectedItems = mediaLibraryItemListModule.input.selectedItems
        if let fetchResult = mediaLibraryItemListModule.input.fetchResult?.fetchResult {
            let mediaItems: [MediaItem] = (0..<fetchResult.count).map { index -> MediaItem in
                let asset = fetchResult.object(at: index)
                return MediaItem(asset: asset)
            }
            selectedItems = selectedItems.filter { mediaItem -> Bool in
                mediaItems.contains(mediaItem)
            }
        }
        output?.mediaLibraryModuleDidFinish(self, with: selectedItems)
    }

    // MARK: - Helpers

    private func setupCollectionListCollector() {
        mediaLibraryCollectionListCollector.subscribe { [weak self] (collections: [MediaItemCollection]) in
            self?.mediaLibraryCollections = collections
            guard self?.activeCollection == nil else {
                return
            }
            self?.activeCollection = collections.first
        }
    }
    
    private func setupPermissionsCollector() {
        mediaLibraryPermissionsCollector.subscribe { [weak self] (status: PHAuthorizationStatus) in
            switch status {
            case .denied:
                self?.view?.isAuthorized = false
            case .authorized:
                self?.view?.isAuthorized = true
            default:
                break
            }
        }
    }

    private func updateMediaItemList() {
        guard let collection = activeCollection else {
            return
        }

        view?.setup(with: collection, filter: mediaLibraryItemListModule.input.filter)
        mediaLibraryItemListModule.input.collection = collection
    }
}

// MARK: - MediaLibraryModuleInput

extension MediaLibraryPresenter: MediaLibraryModuleInput {
	//
}

// MARK: - MediaLibraryItemsModuleOutput

extension MediaLibraryPresenter: MediaLibraryItemsModuleOutput {

    func didFinishLoading(collection: MediaItemCollection, isMixedContentCollection: Bool) {
        if isMixedContentCollection {
            view?.showFilterSelector()
        }
        else {
            view?.hideFilterSelector()
        }
    }
}

// MARK: - MediaItemCollectionsModuleOutput

extension MediaLibraryPresenter: MediaItemCollectionsModuleOutput {

    func didSelect(_ collection: MediaItemCollection) {
        view?.hideAlbumPicker()
        activeCollection = collection
    }
}
