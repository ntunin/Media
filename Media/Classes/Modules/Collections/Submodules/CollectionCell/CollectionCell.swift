//
//  Copyright © 2018 Rosberry. All rights reserved.
//

import UIKit
import Framezilla

class CollectionCell: UICollectionViewCell {

    private var configureCell: ConfigureCell = .init()

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.25) {
                if self.isHighlighted {
                    self.contentView.backgroundColor = self.configureCell.selectedColor
                }
                else {
                    self.contentView.backgroundColor = self.configureCell.highlightedColor
                }
            }
        }
    }

    // MARK: - Subviews

    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = configureCell.infoViewBackgroundColor
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.black
        return label
    }()

    private lazy var itemCountLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.black
        return label
    }()

    // MARK: - Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        UIView.setAnimationsEnabled(false)

        imageView.layer.cornerRadius = 4.0
        imageView.configureFrame { maker in
            maker.left(inset: 15.0)
            maker.centerY()
            maker.size(width: contentView.bounds.height - 16.0, height: contentView.bounds.height - 16.0)
        }

        titleLabel.configureFrame { maker in
            maker.left(to: imageView.nui_right, inset: 15.0)
            maker.right(inset: 20.0)
            maker.bottom(to: imageView.nui_centerY, inset: 1.0)
            maker.heightToFit()
        }

        itemCountLabel.configureFrame { maker in
            maker.left(to: imageView.nui_right, inset: 15.0)
            maker.right(inset: 20.0)
            maker.top(to: imageView.nui_centerY, inset: 1.0)
            maker.heightToFit()
        }

        UIView.setAnimationsEnabled(true)
    }

    func update(with viewModel: CollectionCellModel, configureCell: ConfigureCell) {
        self.configureCell = configureCell
        imageView.image = viewModel.thumbnail
        titleLabel.text = viewModel.title

        var itemCountLabelString: String?
        switch viewModel.estimatedMediaItemsCount {
            case .none:
                itemCountLabelString = L10n.MediaLibrary.unknown
            case .max?:
                if viewModel.isFavorite {
                    itemCountLabelString = L10n.MediaLibrary.favoriteItems
                }
                else {
                    itemCountLabelString = L10n.MediaLibrary.allItems
                }
            case .some(let count):
                itemCountLabelString = "\(count)"
        }
        itemCountLabel.text = itemCountLabelString
        setNeedsLayout()
        layoutIfNeeded()
    }

    // MARK: - Private

    private func setup() {
        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(itemCountLabel)
    }
}
