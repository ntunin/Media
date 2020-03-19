//
//  Copyright © 2020 Rosberry. All rights reserved.
//

import UIKit
import Ion
import Photos

public final class MediaCoordinator {

     public enum Context {
        case library
        case albums
        case items
    }

    typealias Dependencies = HasMediaLibraryService

    private lazy var dependencies: Dependencies = Services

    let navigationViewController: UINavigationController

    private lazy var permissionsCollector: Collector<PHAuthorizationStatus> = {
        return .init(source: dependencies.mediaLibraryService.permissionStatusEventSource)
    }()

    public var maxItemsCount: Int = 2
    public var numberOfItemsInRow: Int = 4

    public let context: Context

    // MARK: - Modules

    private var mediaLibraryModule: MediaLibraryModule?
    private var collectionsModule: CollectionsModule?
    private var mediaItemsModule: MediaItemsModule?

    // MARK: - Lifecycle

    public init(navigationViewController: UINavigationController, context: Context) {
        self.navigationViewController = navigationViewController
        self.context = context
        setupPermissionsCollector()
    }

    public func start() {
        switch context {
            case .library:
                let module = makeMediaLibraryModule()
                mediaLibraryModule = module
                navigationViewController.pushViewController(module.viewController, animated: true)
            case .albums:
                let module = makeCollectionsModule()
                collectionsModule = module
                navigationViewController.pushViewController(module.viewController, animated: true)
            case .items:
                let module = makeMediaItemsModule()
                mediaItemsModule = module
                navigationViewController.pushViewController(module.viewController, animated: true)
        }
        dependencies.mediaLibraryService.requestMediaLibraryPermissions()
    }

    // MARK: - Private

    private func setupPermissionsCollector() {
        permissionsCollector.subscribe { [weak self] status in
            self?.mediaLibraryModule?.input.update(isAuthorized: status == .authorized)
            self?.collectionsModule?.input.update(isAuthorized: status == .authorized)
            self?.mediaItemsModule?.input.update(isAuthorized: status == .authorized)
        }
    }

    private func makeMediaLibraryModule() -> MediaLibraryModule {
        let module = MediaLibraryModule(maxItemsCount: maxItemsCount,
                                        collectionsModule: makeCollectionsModule(),
                                        mediaItemsModule: makeMediaItemsModule())
        module.output = self
        return module
    }

    private func makeCollectionsModule() -> CollectionsModule {
        let module = CollectionsModule()
        module.output = self
        return module
    }

    private func makeMediaItemsModule() -> MediaItemsModule {
        let module = MediaItemsModule(maxItemsCount: maxItemsCount, numberOfItemsInRow: numberOfItemsInRow)
        module.output = self
        return module
    }

    private func makeMediaItemPreviewModule() -> MediaItemPreviewModule {
        let module = MediaItemPreviewModule()
        module.viewController.modalPresentationStyle = .overCurrentContext
        module.viewController.modalTransitionStyle = .crossDissolve
        module.viewController.modalPresentationCapturesStatusBarAppearance = false
        return module
    }
}

// MARK: - MediaLibraryModuleOutput
extension MediaCoordinator: MediaLibraryModuleOutput {

    public func mediaLibraryModuleDidFinish(_ moduleInput: MediaLibraryModuleInput, with items: [MediaItem]) {
        navigationViewController.popViewController(animated: true)
    }
}

// MARK: - CollectionsModuleOutput
extension MediaCoordinator: CollectionsModuleOutput {

    public func didSelect(_ collection: MediaItemCollection) {
        switch context {
            case .library:
                mediaLibraryModule?.input.select(collection)
            case .albums:
                let module = makeMediaItemsModule()
                mediaItemsModule = module
                module.input.collection = collection
                navigationViewController.pushViewController(module.viewController, animated: true)
            case .items:
                break
        }
    }
}

// MARK: - MediaItemsModuleOutput
extension MediaCoordinator: MediaItemsModuleOutput {

    public func didStartPreview(item: MediaItem, from rect: CGRect) {
        let module = makeMediaItemPreviewModule()
        navigationViewController.present(module.viewController, animated: true, completion: nil)
    }

    public func didStopPreview(item: MediaItem) {
        navigationViewController.dismiss(animated: true, completion: nil)
    }

    public func didFinishLoading(_ collection: MediaItemCollection, isMixedContentCollection: Bool) {

    }
}
