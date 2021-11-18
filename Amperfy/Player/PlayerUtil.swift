import Foundation

protocol MusicPlayable {
    func didStartPlaying()
    func didPause()
    func didStopPlaying()
    func didElapsedTimeChange()
    func didPlaylistChange()
    func didArtworkChange()
}

enum RepeatMode: Int16 {
    case off
    case all
    case single

    mutating func switchToNextMode() {
        switch self {
        case .off:
            self = .all
        case .all:
            self = .single
        case .single:
            self = .off
        }
    }
    
    var description : String {
        switch self {
        case .off: return "Off"
        case .all: return "All"
        case .single: return "Single"
        }
    }
}

enum PlayerQueueType: Int {
    case prev = 0
    case waitingQueue
    case next
}

struct PlayerIndex: Equatable {
    let queueType: PlayerQueueType
    let index: Int
    
    static func create(from indexPath: IndexPath) -> PlayerIndex? {
        guard let queueType = PlayerQueueType(rawValue: indexPath.section) else { return nil }
        return PlayerIndex(queueType: queueType, index: indexPath.row)
    }
}
