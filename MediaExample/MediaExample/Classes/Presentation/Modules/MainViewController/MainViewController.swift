//
//  Copyright © 2019 Rosberry. All rights reserved.
//

import UIKit
import Media

final class MainViewController: UIViewController {

    private var coordinator: MediaCoordinator?

    // MARK: - Subviews

    private lazy var libraryButton: UIButton = {
        let button = UIButton()
        button.setTitle("Library", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .white
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(libraryButtonPressed), for: .touchUpInside)
        return button
    }()

    private lazy var albumsButton: UIButton = {
        let button = UIButton()
        button.setTitle("Albums", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .white
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(albumsButtonPressed), for: .touchUpInside)
        return button
    }()

    private lazy var listButton: UIButton = {
        let button = UIButton()
        button.setTitle("List", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .white
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(listButtonPressed), for: .touchUpInside)
        return button
    }()

    private lazy var stackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [libraryButton, albumsButton, listButton])
        view.axis = .vertical
        view.distribution = .fillEqually
        view.spacing = 8
        view.backgroundColor = .clear
        return view
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Menu"
        view.backgroundColor = .gray
        view.addSubview(stackView)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        stackView.configureFrame { maker in
            maker.size(width: 200, height: 166).center()
        }
    }

    // MARK: - Private

    @objc func libraryButtonPressed() {
        start(with: .library)
    }

    @objc func albumsButtonPressed() {
        start(with: .albums)
    }

    @objc func listButtonPressed() {
        start(with: .items)
    }

    private func start(with context: MediaCoordinator.Context) {
        guard let navigationController = navigationController else {
            return
        }
        coordinator = .init(navigationViewController: navigationController, context: context)
        coordinator?.start()
    }
}
