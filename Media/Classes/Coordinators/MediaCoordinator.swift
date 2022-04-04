//
//  Copyright © 2020 Rosberry. All rights reserved.
//

import UIKit
import Ion
import Photos
import MediaService

public final class MediaCoordinator {

    typealias Dependencies = HasMediaLibraryService

    private lazy var dependencies: Dependencies = Services

    let navigationViewController: UINavigationController

    private lazy var permissionsCollector: Collector<PHAuthorizationStatus> = {
        return .init(source: dependencies.mediaLibraryService.permissionStatusEventSource)
    }()

    public var maxItemsCount: Int = 2
    public var numberOfItemsInRow: Int = 4

    public var mediaAppearance: MediaAppearance

    // MARK: - Modules
    private var galleryModule: GalleryModule?

    // MARK: - Lifecycle

    public init(navigationViewController: UINavigationController, mediaAppearance: MediaAppearance) {
        self.navigationViewController = navigationViewController
        self.mediaAppearance = mediaAppearance
        setupPermissionsCollector()
    }

    public init(navigationViewController: UINavigationController) {
        self.navigationViewController = navigationViewController
        self.mediaAppearance = .init()
        setupPermissionsCollector()
    }

    public func start(bundleName: String) {
        let module = makeGalleryModule(bundleName: bundleName)
        galleryModule = module
        navigationViewController.pushViewController(module.viewController, animated: true)
        dependencies.mediaLibraryService.requestMediaLibraryPermissions()
    }

    // MARK: - Private

    private func setupPermissionsCollector() {
        permissionsCollector.subscribe { [weak self] status in
            self?.galleryModule?.input.update(isAuthorized: status == .authorized)
        }
    }


    private func makeGalleryModule(bundleName: String) -> GalleryModule {
        let module = GalleryModule(bundleName: bundleName,
                                   maxItemsCount: maxItemsCount,
                                   numberOfItemsInRow: numberOfItemsInRow,
                                   collectionAppearance: mediaAppearance.list)
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

// MARK: - MediaItemsModuleOutput
extension MediaCoordinator: GalleryModuleOutput {

    public func didStartPreview(item: MediaItem, from rect: CGRect) {
        let module = makeMediaItemPreviewModule()
        module.input.mediaItem = item
        navigationViewController.present(module.viewController, animated: true, completion: nil)
    }

    public func didStopPreview(item: MediaItem) {
        navigationViewController.dismiss(animated: true, completion: nil)
    }

    public func didFinishLoading(_ collection: MediaItemsCollection, isMixedContentCollection: Bool) {

    }

    public func closeEventTriggered() {
        navigationViewController.popViewController(animated: true)
    }
}
