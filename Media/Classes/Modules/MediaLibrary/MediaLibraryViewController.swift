//
//  Copyright © 2018 Rosberry. All rights reserved.
//

import UIKit
import Framezilla

public final class MediaLibraryViewController: UIViewController {

    private let presenter: MediaLibraryPresenter

    private lazy var mediaLibraryItemListViewController = presenter.mediaLibraryItemsModule.viewController
    private lazy var mediaLibraryAlbumListViewController = presenter.mediaItemCollectionsModule.viewController

    public var isAuthorized: Bool = false {
        didSet {
            view.setNeedsLayout()
            view.layoutIfNeeded()
        }
    }

    private var isAlbumPickerVisible: Bool = false {
        didSet {
            mediaLibraryAlbumListViewController.view.isUserInteractionEnabled = isAlbumPickerVisible
            view.setNeedsLayout()
            view.layoutIfNeeded()
        }
    }

    // MARK: - Subviews

    public var collectionView: UICollectionView {
        if isAlbumPickerVisible {
            return mediaLibraryAlbumListViewController.collectionView
        }
        return mediaLibraryItemListViewController.collectionView
    }

    private lazy var toolView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.main4
        return view
    }()

    private lazy var albumSelectionButton: DropdownButton = {
        let button = DropdownButton(type: .custom)
        button.addTarget(self, action: #selector(albumSelectionButtonPressed), for: .touchUpInside)
        return button
    }()

    private lazy var filterView: SwitchView = {
        let view = SwitchView()
        view.items = [
            SwitchItem(title: L10n.MediaLibrary.Filter.videos.uppercased()) { [weak self] in
                self?.presenter.filterVideosEventTriggered()
            },
            SwitchItem(title: L10n.MediaLibrary.Filter.all.uppercased()) { [weak self] in
                self?.presenter.filterAllEventTriggered()
            }
        ]
        return view
    }()

    // MARK: - Lifecycle

    init(presenter: MediaLibraryPresenter) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        title = L10n.MediaLibrary.title.uppercased()
        view.backgroundColor = UIColor.main4

        toolView.addSubview(albumSelectionButton)
        toolView.addSubview(filterView)
        view.addSubview(toolView)

        add(child: mediaLibraryItemListViewController)
        add(child: mediaLibraryAlbumListViewController)

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: L10n.MediaLibrary.done,
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(doneButtonPressed))

        presenter.viewReadyEventTriggered()
    }

    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        toolView.configureFrame { (maker: Maker) in
            maker.top(inset: view.safeAreaInsets.top)
            maker.left().right()
            maker.height(38)
        }

        filterView.configureFrame { (maker: Maker) in
            maker.right(inset: 15.0)
            maker.centerY()
            maker.width(min(160.0, view.bounds.width * 0.45))
            maker.height(32.0)
        }

        albumSelectionButton.configureFrame { (maker: Maker) in
            maker.top().bottom()
            maker.left(inset: 16).right(inset: 16)
        }

        mediaLibraryItemListViewController.view.configureFrame { (maker) in
            if isAuthorized {
                maker.top(to: toolView.nui_bottom)
            }
            else {
                maker.top(inset: view.safeAreaInsets.top)
            }
            maker.left().right()
            maker.bottom()
        }

        mediaLibraryAlbumListViewController.view.configureFrame { (maker: Maker) in
            if isAuthorized {
                maker.top(to: toolView.nui_bottom)
            }
            else {
                maker.top(inset: view.safeAreaInsets.top)
            }
            maker.left().right()
            if isAlbumPickerVisible {
                maker.bottom()
            }
            else {
                maker.height(0.0)
            }
        }
    }

    // MARK: - Private

    @objc private func albumSelectionButtonPressed() {
        albumSelectionButton.isSelected.toggle()
        if albumSelectionButton.isSelected {
            showAlbumPicker()
        }
        else {
            hideAlbumPicker()
        }
    }

    @objc public func doneButtonPressed() {
        presenter.confirmationEventTriggered()
    }

    // MARK: -

    func setup(with collection: MediaItemCollection, filter: MediaItemFilter) {
        albumSelectionButton.title = collection.title?.uppercased()

        CATransaction.execute {
            CATransaction.setDisableActions(true)
            switch filter {
                case .video:
                    filterView.selectedIndex = 0
                case .all:
                    filterView.selectedIndex = 1
            }
        }
    }

    func showAlbumPicker() {
        albumSelectionButton.isSelected = true
        mediaLibraryAlbumListViewController.beginAppearanceTransition(true, animated: true)
        UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.95, initialSpringVelocity: 0.5, options: [], animations: {
            self.isAlbumPickerVisible = true
        }, completion: { _ in
            self.mediaLibraryAlbumListViewController.endAppearanceTransition()
        })

        UIView.animate(withDuration: 0.15) {
            self.filterView.alpha = 0.0
        }
    }

    func hideAlbumPicker() {
        albumSelectionButton.isSelected = false
        mediaLibraryAlbumListViewController.beginAppearanceTransition(false, animated: true)
        UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.95, initialSpringVelocity: 0.5, options: [], animations: {
            self.isAlbumPickerVisible = false
        }, completion: { _ in
            self.mediaLibraryAlbumListViewController.endAppearanceTransition()
        })

        UIView.animate(withDuration: 0.15, delay: 0.25, options: [], animations: {
            self.filterView.alpha = 1.0
        }, completion: nil)
    }

    func showFilterSelector() {
        filterView.isHidden = false
    }

    func hideFilterSelector() {
        filterView.isHidden = true
    }
}