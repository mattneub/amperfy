//
//  LibraryEntityDetailVC.swift
//  Amperfy
//
//  Created by Maximilian Bauer on 20.01.22.
//  Copyright (c) 2022 Maximilian Bauer. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

import Foundation
import UIKit
import AmperfyKit
import PromiseKit
import MarqueeLabel

typealias GetPlayContextCallback = () -> PlayContext?
typealias GetPlayerIndexCallback = () -> PlayerIndex?

class LibraryEntityDetailVC: UIViewController {
    
    @IBOutlet var superView: UIView!
    @IBOutlet weak var mainStackView: UIStackView!
    
    @IBOutlet weak var elementInfoStackView: UIStackView!
    @IBOutlet weak var elementInfoLabelsView: UIView!
    @IBOutlet weak var titleLabel: MarqueeLabel!
    @IBOutlet weak var artistContainerView: UIView!
    @IBOutlet weak var artistLabel: MarqueeLabel!
    @IBOutlet weak var showArtistButton: UIButton!
    @IBOutlet weak var albumContainerView: UIView!
    @IBOutlet weak var albumLabel: MarqueeLabel!
    @IBOutlet weak var showAlbumButton: UIButton!
    @IBOutlet weak var infoLabel: MarqueeLabel!
    @IBOutlet weak var entityImage: EntityImageView!
    
    @IBOutlet weak var podcastQueueContainerView: UIView!
    @IBOutlet weak var podcastQueueInsertButton: BasicButton!
    @IBOutlet weak var podcastQueueAppendButton: BasicButton!
    
    @IBOutlet weak var queueContainerView: UIView!
    @IBOutlet weak var userQueueInsertButton: BasicButton!
    @IBOutlet weak var userQueueAppendButton: BasicButton!
    @IBOutlet weak var contextQueueInsertButton: BasicButton!
    @IBOutlet weak var contextQueueAppendButton: BasicButton!
    
    @IBOutlet weak var ratingPlaceholderView: UIView!
    @IBOutlet weak var ratingView: RatingView?

    @IBOutlet weak var mainClusterStackView: UIStackView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var playShuffledButton: BasicButton!
    @IBOutlet weak var addToPlaylistButton: UIButton!
    @IBOutlet weak var downloadButton: UIButton!
    @IBOutlet weak var deleteCacheButton: UIButton!
    @IBOutlet weak var deleteOnServerButton: UIButton!
    @IBOutlet weak var showPodcastDetailsButton: UIButton!
    @IBOutlet weak var copyIdToClipboardButton: UIButton!
    private var buttonsOfMainCluster: [UIButton] {
        return [
            playButton,
            playShuffledButton,
            addToPlaylistButton,
            downloadButton,
            deleteCacheButton,
            deleteOnServerButton,
            showPodcastDetailsButton,
            copyIdToClipboardButton,
        ]
    }

    @IBOutlet weak var cancelButton: UIButton!
    
    static let detailLabelsClusterNormalHeight = 90.0
    static let minEntityImageHeight = 30.0
    static let compactMainStackSpacing = 5.0
    static let largeMainStackSpacing = 20.0
    
    @IBOutlet weak var topMarginSpaceConstraint: NSLayoutConstraint!
    @IBOutlet weak var detailLabelsClusterHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var artistNameLabelHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var albumNameLabelHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var ratingHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var podcastQueueContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var queueStackHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var mainStackClusterHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var playerStackClusterHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var playerActionsLabelHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var playButtonHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var cancelButtonHeightConstraint: NSLayoutConstraint!
    
    private var rootView: UIViewController?
    private var playContextCb: GetPlayContextCallback?
    private var playerIndexCb: GetPlayerIndexCallback?
    private var appDelegate: AppDelegate!
    private var entityContainer: PlayableContainable!

    private var entityPlayables: [AbstractPlayable] {
        let playables = entityContainer?.playables.filterCached(dependigOn: appDelegate.storage.settings.isOfflineMode) ?? [AbstractPlayable]()
        switch(entityContainer.playContextType) {
        case .music:
            return playables.compactMap{ $0.asSong }.filterServerDeleteUncachedSongs()
        case .podcast:
            return playables
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        appDelegate = (UIApplication.shared.delegate as! AppDelegate)
        
        self.view.setBackgroundBlur(style: .prominent)
        elementInfoLabelsView.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        titleLabel.applyAmperfyStyle()
        artistLabel.applyAmperfyStyle()
        albumLabel.applyAmperfyStyle()
        infoLabel.applyAmperfyStyle()
        if let ratingView = ViewBuilder<RatingView>.createFromNib(withinFixedFrame: CGRect(x: 0, y: 0, width: ratingPlaceholderView.bounds.size.width, height: RatingView.frameHeight+10)) {
            self.ratingView = ratingView
            ratingPlaceholderView.addSubview(ratingView)
        }
        ratingPlaceholderView.layer.cornerRadius = BasicButton.cornerRadius
        ratingPlaceholderView.backgroundColor = .clear
        ratingPlaceholderView.layer.borderColor = UIColor.fillColor.cgColor
        ratingPlaceholderView.layer.borderWidth = 2.5
        refresh()

        Self.configureRoundQueueButton(button: podcastQueueInsertButton, corner: [.layerMinXMinYCorner, .layerMaxXMinYCorner])
        Self.configureRoundQueueButton(button: podcastQueueAppendButton, corner: [.layerMinXMaxYCorner, .layerMaxXMaxYCorner])

        Self.configureRoundQueueButton(button: contextQueueInsertButton, corner: .layerMinXMinYCorner)
        Self.configureRoundQueueButton(button: userQueueInsertButton, corner: .layerMaxXMinYCorner)
        Self.configureRoundQueueButton(button: contextQueueAppendButton, corner: .layerMinXMaxYCorner)
        Self.configureRoundQueueButton(button: userQueueAppendButton, corner: .layerMaxXMaxYCorner)

        if !playButton.isHidden {
            playButton.imageView?.contentMode = .scaleAspectFit
        }
        if !playShuffledButton.isHidden {
            playShuffledButton.imageView?.contentMode = .scaleAspectFit
        }
    }
    
    override func viewWillLayoutSubviews() {
        var remainingSpace = superView.frame.size.height
        remainingSpace -= topMarginSpaceConstraint.constant
        remainingSpace -= Self.minEntityImageHeight
        remainingSpace -= detailLabelsClusterHeightConstraint.constant
        if !ratingPlaceholderView.isHidden {
            remainingSpace -= ratingHeightConstraint.constant
            remainingSpace -= Self.compactMainStackSpacing
        }
        if !podcastQueueContainerView.isHidden {
            remainingSpace -= podcastQueueContainerHeightConstraint.constant
            remainingSpace -= Self.compactMainStackSpacing
        }
        if !queueContainerView.isHidden {
            remainingSpace -= queueStackHeightConstraint.constant
            remainingSpace -= Self.compactMainStackSpacing
        }
        remainingSpace -= mainStackClusterHeightConstraint.constant
        remainingSpace -= cancelButtonHeightConstraint.constant
        remainingSpace -= Self.compactMainStackSpacing
        // Big Artwork
        if remainingSpace > detailLabelsClusterHeightConstraint.constant {
            mainStackView.spacing = Self.largeMainStackSpacing
            elementInfoStackView.axis = .vertical
            elementInfoStackView.alignment = .fill
            elementInfoStackView.distribution = .fill
            titleLabel.textAlignment = .center
            artistLabel.textAlignment = .center
            albumLabel.textAlignment = .center
            infoLabel.textAlignment = .center
            var detailClusterHeight = Self.detailLabelsClusterNormalHeight
            if artistContainerView.isHidden {
                detailClusterHeight -= artistNameLabelHeightConstraint.constant
            }
            if albumContainerView.isHidden {
                detailClusterHeight -= albumNameLabelHeightConstraint.constant
            }
            detailLabelsClusterHeightConstraint.constant = detailClusterHeight
        } else {
            mainStackView.spacing = Self.compactMainStackSpacing
            elementInfoStackView.axis = .horizontal
            elementInfoStackView.alignment = .fill
            elementInfoStackView.distribution = .fill
            titleLabel.textAlignment = .left
            artistLabel.textAlignment = .left
            albumLabel.textAlignment = .left
            infoLabel.textAlignment = .left
            detailLabelsClusterHeightConstraint.constant = Self.detailLabelsClusterNormalHeight
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        guard self.appDelegate.storage.settings.isOnlineMode else { return }
        guard let container = entityContainer else { return }
        firstly {
            container.fetch(storage: self.appDelegate.storage, librarySyncer: self.appDelegate.librarySyncer, playableDownloadManager: self.appDelegate.playableDownloadManager)
        }.catch { error in
            self.appDelegate.eventLogger.report(topic: "Detail Sync", error: error)
        }.finally {
            self.refresh()
        }
    }
    
    static func configureRoundQueueButton(button: UIButton, corner: CACornerMask) {
        button.contentMode = .center
        button.imageView?.contentMode = .scaleAspectFill
        button.titleLabel!.lineBreakMode = .byWordWrapping
        button.layer.maskedCorners = [corner]
    }
    
    static func configureRoundButtonCluster(buttons: [UIButton], containerView: UIView, hightConstraint: NSLayoutConstraint, buttonHeight: CGFloat, offsetHeight: CGFloat = 0.0) {
        guard !containerView.isHidden else { return }
        let visibleButtons = buttons.filter{!$0.isHidden}
        var height = 0.0
        if visibleButtons.count == 1 {
            height = buttonHeight + offsetHeight
        } else if visibleButtons.count > 1 {
            height = ((buttonHeight + 1.0) * CGFloat(visibleButtons.count)) - 1 + offsetHeight
        }
        hightConstraint.constant = height
        containerView.isHidden = visibleButtons.isEmpty
        
        if visibleButtons.count == 1 {
            visibleButtons[0].layer.cornerRadius = BasicButton.cornerRadius
            visibleButtons[0].layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        } else {
            visibleButtons.forEach{ $0.layer.maskedCorners = [] }
            let firstButton = visibleButtons.first
            firstButton?.layer.cornerRadius = BasicButton.cornerRadius
            firstButton?.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            let lastButton = visibleButtons.last
            lastButton?.layer.cornerRadius = BasicButton.cornerRadius
            lastButton?.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        }
    }
    
    func display(container: PlayableContainable, on rootView: UIViewController, playContextCb: GetPlayContextCallback? = nil, playerIndexCb: GetPlayerIndexCallback? = nil) {
        self.entityContainer = container
        self.rootView = rootView
        self.playContextCb = playContextCb
        self.playerIndexCb = playerIndexCb
    }

    func refresh() {
        entityImage.display(container: entityContainer)
        titleLabel.text = entityContainer.name
        artistLabel.text = entityContainer.subtitle
        artistContainerView.isHidden = entityContainer.subtitle == nil

        albumLabel.text = entityContainer.subsubtitle
        albumContainerView.isHidden = entityContainer.subsubtitle == nil

        infoLabel.text = entityContainer.info(for: appDelegate.backendApi.selectedApi, details: DetailInfoType(type: .long, settings: appDelegate.storage.settings))

        playButton.isHidden = !entityContainer.playables.hasCachedItems && appDelegate.storage.settings.isOfflineMode
        playShuffledButton.isHidden = !entityContainer.playables.hasCachedItems && appDelegate.storage.settings.isOfflineMode
        podcastQueueContainerView.isHidden = !entityContainer.playables.hasCachedItems && appDelegate.storage.settings.isOfflineMode
        queueContainerView.isHidden = !entityContainer.playables.hasCachedItems && appDelegate.storage.settings.isOfflineMode
        addToPlaylistButton.isHidden = appDelegate.storage.settings.isOfflineMode
        
        switch entityContainer.playContextType {
        case .music:
            podcastQueueContainerView.isHidden = true
        case .podcast:
            queueContainerView.isHidden = true
        }

        downloadButton.isHidden = entityContainer.playables.isCachedCompletely ||
            appDelegate.storage.settings.isOfflineMode ||
            !entityContainer.isDownloadAvailable
        deleteCacheButton.isHidden = !entityContainer.playables.hasCachedItems
        
        deleteOnServerButton.isHidden = true
        showPodcastDetailsButton.isHidden = true
        copyIdToClipboardButton.isHidden = !appDelegate.storage.settings.isShowDetailedInfo

        if let playable = entityContainer as? AbstractPlayable {
            if let song = playable.asSong {
                configureFor(song: song)
            } else if let podcastEpisode = playable.asPodcastEpisode {
                configureFor(podcastEpisode: podcastEpisode)
            }
        } else if let album = entityContainer as? Album {
            configureFor(album: album)
        } else if let artist = entityContainer as? Artist {
            configureFor(artist: artist)
        } else if let genre = entityContainer as? Genre {
            configureFor(genre: genre)
        } else if let playlist = entityContainer as? Playlist {
            configureFor(playlist: playlist)
        } else if let podcast = entityContainer as? Podcast {
            configureFor(podcast: podcast)
        }
        Self.configureRoundButtonCluster(buttons: buttonsOfMainCluster, containerView: mainClusterStackView, hightConstraint: mainStackClusterHeightConstraint, buttonHeight: playButtonHeightConstraint.constant)
        
        if let libraryEntity = entityContainer as? AbstractLibraryEntity, entityContainer.isRateable {
            ratingView?.display(entity: libraryEntity)
            ratingPlaceholderView.isHidden = false
        } else {
            ratingPlaceholderView.isHidden = true
        }
    }

    private func configureFor(playlist: Playlist) {
    }
    
    private func configureFor(genre: Genre) {
    }
    
    private func configureFor(podcast: Podcast) {
        showPodcastDetailsButton.isHidden = false
        showPodcastDetailsButton.setTitle("Show Podcast Description", for: .normal)
        addToPlaylistButton.isHidden = true
        playShuffledButton.isHidden = true
    }
    
    private func configureFor(artist: Artist) {
    }
    
    private func configureFor(album: Album) {
    }
    
    private func configureFor(song: Song) {
        playButton.isHidden =
            (playContextCb == nil) ||
            (!song.isCached && appDelegate.storage.settings.isOfflineMode)
        playShuffledButton.isHidden = true
        queueContainerView.isHidden =
            (playContextCb == nil) ||
            playerIndexCb != nil ||
            (!song.isCached && appDelegate.storage.settings.isOfflineMode)
    }
    
    private func configureFor(podcastEpisode: PodcastEpisode) {
        playButton.isHidden = (playContextCb == nil) ||
           (!podcastEpisode.isAvailableToUser && appDelegate.storage.settings.isOnlineMode) ||
           (!podcastEpisode.isCached && appDelegate.storage.settings.isOfflineMode)
        playShuffledButton.isHidden = true
        podcastQueueContainerView.isHidden = (playContextCb == nil) ||
           (playerIndexCb != nil) ||
           (!podcastEpisode.isAvailableToUser && appDelegate.storage.settings.isOnlineMode) ||
           (!podcastEpisode.isCached && appDelegate.storage.settings.isOfflineMode)
        addToPlaylistButton.isHidden = true
        deleteOnServerButton.isHidden = podcastEpisode.podcastStatus == .deleted || appDelegate.storage.settings.isOfflineMode
        showPodcastDetailsButton.isHidden = false
        showPodcastDetailsButton.setTitle("Show Episode Description", for: .normal)
    }
    
    @IBAction func pressedPlay(_ sender: Any) {
        dismiss(animated: true)
        guard !entityPlayables.isEmpty else { return }
        if let playerIndex = playerIndexCb?() {
            self.appDelegate.player.play(playerIndex: playerIndex)
        } else if let context = playContextCb?() {
            self.appDelegate.player.play(context: context)
        } else {
            self.appDelegate.player.play(context: PlayContext(containable: entityContainer, playables: entityPlayables))
        }
    }
    
    @IBAction func pressPlayShuffled(_ sender: Any) {
        dismiss(animated: true)
        guard !entityPlayables.isEmpty else { return }
        if let context = playContextCb?() {
            self.appDelegate.player.playShuffled(context: context)
        } else {
            self.appDelegate.player.playShuffled(context: PlayContext(containable: entityContainer, playables: entityPlayables))
        }
    }
    
    @IBAction func pressedAddToPlaylist(_ sender: Any) {
        dismiss(animated: true) {
            guard !self.entityPlayables.isEmpty else { return }
            let selectPlaylistVC = PlaylistSelectorVC.instantiateFromAppStoryboard()
            selectPlaylistVC.itemsToAdd = self.entityPlayables
            let selectPlaylistNav = UINavigationController(rootViewController: selectPlaylistVC)
            self.rootView?.present(selectPlaylistNav, animated: true)
        }
    }

    @IBAction func pressedDownload(_ sender: Any) {
        dismiss(animated: true)
        if !entityPlayables.isEmpty {
            appDelegate.playableDownloadManager.download(objects: entityPlayables)
        }
    }
    
    @IBAction func pressedDeleteCache(_ sender: Any) {
        dismiss(animated: true)
        guard entityPlayables.hasCachedItems else { return }
        appDelegate.playableDownloadManager.removeFinishedDownload(for: entityPlayables)
        appDelegate.storage.main.library.deleteCache(of: entityPlayables)
        appDelegate.storage.main.saveContext()
        if let rootTableView = self.rootView as? UITableViewController{
            rootTableView.tableView.reloadData()
        }
        refresh()
    }
    
    @IBAction func pressedDeleteOnServer(_ sender: Any) {
        dismiss(animated: true)
        guard let playable = entityContainer as? AbstractPlayable, let podcastEpisode = playable.asPodcastEpisode else { return }
        firstly {
            self.appDelegate.librarySyncer.requestPodcastEpisodeDelete(podcastEpisode: podcastEpisode)
        }.then { () -> Promise<Void> in
            guard let podcast = podcastEpisode.podcast else { return Promise.value }
            return self.appDelegate.librarySyncer.sync(podcast: podcast)
        }.catch { error in
            self.appDelegate.eventLogger.report(topic: "Podcast Episode Sync Delete", error: error)
        }
    }
    
    @IBAction func pressedShowPodcastDetails(_ sender: Any) {
        guard let rootView = rootView else { return }
        var descriptionVC: PodcastDescriptionVC?
        if let playable = entityContainer as? AbstractPlayable, let podcastEpisode = playable.asPodcastEpisode {
            descriptionVC = PodcastDescriptionVC()
            descriptionVC?.display(podcastEpisode: podcastEpisode, on: rootView)
        } else if let podcast = entityContainer as? Podcast {
            descriptionVC = PodcastDescriptionVC()
            descriptionVC?.display(podcast: podcast, on: rootView)
        }
        
        if let descriptionVC = descriptionVC {
            dismiss(animated: true) {
                rootView.present(descriptionVC, animated: true)
            }
        }
    }
    
    @IBAction func pressedCopyIdToClipboard(_ sender: Any) {
        if !self.entityContainer.id.isEmpty {
            UIPasteboard.general.string = self.entityContainer.id
        }
    }
    
    @IBAction func pressedShowArtist(_ sender: Any) {
        dismiss(animated: true) {
            let playable = self.entityContainer as? AbstractPlayable
            let album = self.entityContainer as? Album
            if let artist = playable?.asSong?.artist ?? album?.artist {
                self.appDelegate.userStatistics.usedAction(.alertGoToArtist)
                let artistDetailVC = ArtistDetailVC.instantiateFromAppStoryboard()
                artistDetailVC.artist = artist
                artistDetailVC.albumToScrollTo = album
                if let popupPlayer = self.rootView as? PopupPlayerVC {
                    popupPlayer.closePopupPlayerAndDisplayInLibraryTab(vc: artistDetailVC)
                } else if let navController = self.rootView?.navigationController {
                    navController.pushViewController(artistDetailVC, animated: true)
                }
            } else if let podcast = playable?.asPodcastEpisode?.podcast {
                self.appDelegate.userStatistics.usedAction(.alertGoToPodcast)
                let podcastDetailVC = PodcastDetailVC.instantiateFromAppStoryboard()
                podcastDetailVC.podcast = podcast
                podcastDetailVC.episodeToScrollTo = playable?.asPodcastEpisode
                if let popupPlayer = self.rootView as? PopupPlayerVC {
                    popupPlayer.closePopupPlayerAndDisplayInLibraryTab(vc: podcastDetailVC)
                } else if let navController = self.rootView?.navigationController {
                    navController.pushViewController(podcastDetailVC, animated: true)
                }
            }
        }
    }
    
    @IBAction func pressedShowAlbum(_ sender: Any) {
        let playable = self.entityContainer as? AbstractPlayable
        let album = playable?.asSong?.album
        dismiss(animated: true) {
            guard let album = album  else { return }
            self.appDelegate.userStatistics.usedAction(.alertGoToAlbum)
            let albumDetailVC = AlbumDetailVC.instantiateFromAppStoryboard()
            albumDetailVC.album = album
            albumDetailVC.songToScrollTo = playable?.asSong
            if let popupPlayer = self.rootView as? PopupPlayerVC {
                popupPlayer.closePopupPlayerAndDisplayInLibraryTab(vc: albumDetailVC)
            } else if let navController = self.rootView?.navigationController {
                navController.pushViewController(albumDetailVC, animated: true)
            }
        }
    }
    
    @IBAction func pressedInsertUserQueue(_ sender: Any) {
        dismiss(animated: true)
        guard !entityPlayables.isEmpty else { return }
        self.appDelegate.player.insertUserQueue(playables: entityPlayables)
    }
    
    @IBAction func pressedAppendUserQueue(_ sender: Any) {
        dismiss(animated: true)
        guard !entityPlayables.isEmpty else { return }
        self.appDelegate.player.appendUserQueue(playables: entityPlayables)
    }
    
    @IBAction func pressedInsertContextQueue(_ sender: Any) {
        dismiss(animated: true)
        guard !entityPlayables.isEmpty else { return }
        self.appDelegate.player.insertContextQueue(playables: entityPlayables)
    }
    
    @IBAction func pressedAppendContextQueue(_ sender: Any) {
        dismiss(animated: true)
        guard !entityPlayables.isEmpty else { return }
        self.appDelegate.player.appendContextQueue(playables: entityPlayables)
    }
    
    @IBAction func pressedInsertPodcastQueue(_ sender: Any) {
        dismiss(animated: true)
        guard !entityPlayables.isEmpty else { return }
        self.appDelegate.player.insertPodcastQueue(playables: entityPlayables)
    }
    
    @IBAction func pressedAppendPodcastQueue(_ sender: Any) {
        dismiss(animated: true)
        guard !entityPlayables.isEmpty else { return }
        self.appDelegate.player.appendPodcastQueue(playables: entityPlayables)
    }
    
    @IBAction func pressedCancel(_ sender: Any) {
        self.dismiss(animated: true)
    }

}
