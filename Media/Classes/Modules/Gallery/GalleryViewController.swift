//
//  Copyright © 2018 Rosberry. All rights reserved.
//

import UIKit
import CollectionViewTools
import Framezilla
import MediaService
import AVFoundation
import RCam

public final class GalleryViewController: UIViewController {

    private typealias PhotoCellItem = UniversalCollectionViewCellItem<PhotoItemCellModel, PhotoMediaItemCell>
    private typealias VideoCellItem = UniversalCollectionViewCellItem<VideoItemCellModel, VideoMediaItemCell>

    private let presenter: GalleryPresenter

    private var mediaAppearance: MediaAppearance {
        presenter.mediaAppearance
    }

    private var assetCellAppearance: AssetCellAppearance {
        presenter.mediaAppearance.gallery.assetCellAppearance
    }

    private var navigationAppearance: NavigationAppearance {
        presenter.mediaAppearance.navigation
    }

    private lazy var factory: GallerySectionsFactory = {
        let factory = GallerySectionsFactory(dependencies: Services,
                                             mediaAppearance: mediaAppearance)
        factory.output = presenter
        return factory
    }()

    private lazy var assetsCollectionManager: CollectionViewManager = {
        let manager = CollectionViewManager(collectionView: assetsCollectionView)
        manager.scrollDelegate = self
        return manager
    }()

    private lazy var albumsCollectionManager: CollectionViewManager = .init(collectionView: albumsCollectionView)

    public private(set) var assetsIsHidden: Bool = false
    // MARK: - Subviews

    public private(set) lazy var titleView: AlbumsShevroneView = {
        let view = AlbumsShevroneView(titleImage: mediaAppearance.navigation.titleImage)
        view.tapEventHandler = { [weak self] state in
            self?.stopScrolling(state)
            self?.presenter.albumsEventTriggered()
        }
        view.imageView.isHidden = true
        return view
    }()

    private lazy var placeholderView: PlaceholderView = {
        let view = PlaceholderView(placeholderAppearance: mediaAppearance.placeholder)
        view.isHidden = true
        return view
    }()

    private lazy var permissionsPlaceholderView: PlaceholderView = {
        let view = PlaceholderView(placeholderAppearance: mediaAppearance.permission)
        view.isHidden = true
        return view
    }()

    public private(set) lazy var assetsCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = mediaAppearance.gallery.collectionViewBackgroundColor
        collectionView.alwaysBounceVertical = true
        collectionView.contentInsetAdjustmentBehavior = .never
        return collectionView
    }()

    public private(set) lazy var albumsCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = mediaAppearance.gallery.collectionViewBackgroundColor
        collectionView.alwaysBounceVertical = true
        return collectionView
    }()

    // MARK: - Lifecycle

    init(presenter: GalleryPresenter) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = mediaAppearance.gallery.backgroundColor
        view.addSubview(albumsCollectionView)
        view.addSubview(assetsCollectionView)
        view.addSubview(placeholderView)
        view.addSubview(permissionsPlaceholderView)

        showMediaItemsPlaceholder()
        setupNavigationBar()
        presenter.viewReadyEventTriggered()
    }

    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        permissionsPlaceholderView.frame = view.bounds
        placeholderView.frame = view.bounds

        assetsCollectionView.configureFrame { maker in
            let inset = self.assetsIsHidden ? self.view.frame.height : 0
            maker.top(to: view.nui_safeArea.top, inset: inset).left().right().bottom()
        }

        albumsCollectionView.configureFrame { maker in
            maker.top(to: view.nui_safeArea.top).left().right().bottom()
        }
    }

    // MARK: -

    func changeCollectionView(assetsIsHidden: Bool) {
        self.assetsIsHidden = assetsIsHidden
        UIView.animate(withDuration: 0.3) {
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
        }
    }

    func showMediaItemsPlaceholder(estimatedItemCount: Int = 128) {
        assetsCollectionView.setContentOffset(.zero, animated: false)
        assetsCollectionView.isUserInteractionEnabled = false
        assetsCollectionManager.sectionItems = factory.placeholderSectionItems(placeholderCount: estimatedItemCount)

        placeholderView.isHidden = true
    }

    private func showCamera() {
        let camera = CameraImpl()
        camera.zoomRangeLimits = 1.0...5.0
        let cameraViewController = CameraViewController(cameraService: camera)

        let placeholderPermissionView = PlaceholderView(placeholderAppearance: mediaAppearance.permission)

        cameraViewController.permissionsPlaceholderView = placeholderPermissionView
        cameraViewController.modalPresentationStyle = .overCurrentContext
        cameraViewController.delegate = self
        present(cameraViewController, animated: true)
    }

    func update(with mediaItemCollections: [MediaItemsCollection]) {
        albumsCollectionManager.sectionItems = factory.makeSectionItems(mediaItemCollections: mediaItemCollections)
        albumsCollectionView.isUserInteractionEnabled = true
    }

    func update(with sectionItemsProvider: LazySectionItemsProvider, animated: Bool) {
        if animated {
            UIView.transition(with: assetsCollectionView, duration: 0.15, options: .transitionCrossDissolve, animations: {
                self.assetsCollectionManager.mode = .lazy(provider: sectionItemsProvider)
                self.assetsCollectionView.isUserInteractionEnabled = true
                self.assetsCollectionView.reloadData()
            }, completion: nil)
        }
        else {
            self.assetsCollectionManager.mode = .lazy(provider: sectionItemsProvider)
            assetsCollectionView.isUserInteractionEnabled = true
            self.assetsCollectionView.reloadData()
        }
        let estimatedCellItemsCount = (0..<sectionItemsProvider.sectionItemsNumberHandler()).reduce(0) { res, index in
            res + sectionItemsProvider.cellItemsNumberHandler(index)
        }
        placeholderView.isHidden = estimatedCellItemsCount > 0
    }

    public func select(items: [MediaItem]) {
        var items = items
        for section in assetsCollectionManager.sectionItems {
            for cellItem in section.cellItems {
                if let photoCellItem = cellItem as? PhotoCellItem,
                   let index = items.firstIndex(of: photoCellItem.object.mediaItem) {
                    photoCellItem.object.selectionIndex = index
                }
                else if let videoCellItem = cellItem as? VideoCellItem,
                        let index = items.firstIndex(of: videoCellItem.object.mediaItem) {
                    videoCellItem.object.selectionIndex = index
                    items.remove(at: index)
                }
            }
        }
    }

    public func updateSelection(handler: (_ mediaItem: MediaItem) -> Int?) {
        for section in assetsCollectionManager.sectionItems {
            for cellItem in section.cellItems {
                if let photoCellItem = cellItem as? PhotoCellItem {
                    photoCellItem.object.selectionIndex = handler(photoCellItem.object.mediaItem)
                    guard let cell = photoCellItem.cell as? MediaItemCell else {
                        return
                    }
                    cell.update(with: photoCellItem.object, cellAppearance: assetCellAppearance)
                }
                else if let videoCellItem = cellItem as? VideoCellItem {
                    videoCellItem.object.selectionIndex = handler(videoCellItem.object.mediaItem)
                    guard let cell = videoCellItem.cell as? MediaItemCell else {
                        return
                    }
                    cell.update(with: videoCellItem.object, cellAppearance: assetCellAppearance)
                }
            }
        }
    }

    func showMediaLibraryDeniedPermissionsPlaceholder() {
        permissionsPlaceholderView.isHidden = false
        titleView.isHidden = true
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }

    func updateTitleView(with title: String? = nil,
                         shevronePosition: AlbumsShevroneView.ShevronePosition) {
        if let title = title {
            titleView.titleLabel.attributedText = navigationAppearance.titleFormatter(title).text(with: navigationAppearance.titleStyle).attributed
            titleView.sizeToFit()
            titleView.setNeedsLayout()
            titleView.layoutIfNeeded()
        }
        titleView.imageView.isHidden = false
        titleView.isHidden = false

        updateTitleView(with: shevronePosition)
    }

    func updateTitleView(with shevronePosition: AlbumsShevroneView.ShevronePosition) {
        titleView.update(shevronePosition: shevronePosition)
        navigationAppearance.titleViewUpdateHandler(titleView)
    }

    func hidePlaceholdersIfNeeded() {
        permissionsPlaceholderView.isHidden = true
        placeholderView.isHidden = true
    }

    private func setupNavigationBar() {
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.view.backgroundColor = .white

        navigationItem.titleView = titleView
        if navigationAppearance.shouldShowCameraButton {
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: navigationAppearance.cameraImage?.withRenderingMode(.alwaysOriginal),
                                                                style: .plain,
                                                                target: self,
                                                                action: #selector(cameraButtonPressed))
        }
        if navigationAppearance.shouldShowBackButton {
            navigationItem.leftBarButtonItem = UIBarButtonItem(image: navigationAppearance.backImage?.withRenderingMode(.alwaysOriginal),
                                                               style: .plain,
                                                               target: self,
                                                               action: #selector(closeButtonPressed))
        }
    }

    private func stopScrolling(_ state: AlbumsShevroneView.ShevronePosition) {
        state == .up ? updateCollectionView(assetsCollectionView) : updateCollectionView(albumsCollectionView)
    }

    private func updateCollectionView(_ collectionView: UICollectionView) {
        if collectionView.numberOfItems(inSection: 0) != 0 {
            collectionView.scrollToItem(at: .init(row: 0, section: 0), at: .top, animated: false)
        }
    }

    @objc private func cameraButtonPressed() {
        showCamera()
    }

    @objc private func closeButtonPressed() {
        presenter.closeEventTriggered()
    }
}

// MARK: - UIScrollViewDelegate

extension GalleryViewController: UIScrollViewDelegate {

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y == -scrollView.contentInset.top {
            return presenter.scrollEventTriggered(direction: .down)
        }

        let delta = scrollView.panGestureRecognizer.translation(in: scrollView).y
        let direction: GalleryPresenter.FocusDirection = (delta > 0.0) ? .down : .up
        presenter.scrollEventTriggered(direction: direction)
    }
}

extension GalleryViewController: CameraViewControllerDelegate {
    public func cameraViewController(_ viewController: CameraViewController, imageCaptured image: UIImage, orientationApplied: Bool) {
        presenter.makePhotoEventTriggered(image)
        viewController.dismiss(animated: true)
    }

    public func cameraViewControllerCloseEventTriggered(_ viewController: CameraViewController) {
        presenter.permissionEventTriggered()
        viewController.dismiss(animated: true)
    }
}
