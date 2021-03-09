import Foundation

class PopupPlaylistGrouper {
    
    let sectionNames = ["Previous", "Next"]
    var sections: [[Song]]
    private var playIndex: Int
    
    init(player: MusicPlayer) {
        playIndex = player.currentlyPlaying?.index ?? 0
        
        let playlist = player.playlist
        var played = [Song]()
        if playIndex > 0 {
            played = Array(playlist.songs[0...playIndex-1])
        }
        var next = [Song]()
        if playlist.songs.count > 0, playIndex < playlist.songs.count-1 {
            next = Array(playlist.songs[(playIndex+1)...])
        }
        sections = [played, next]
    }
    
    func convertIndexPathToPlaylistIndex(indexPath: IndexPath) -> Int {
        var playlistIndex = indexPath.row
        if indexPath.section == 1 {
            playlistIndex += (1 + sections[0].count)
        }
        return playlistIndex
    }
    
    func convertPlaylistIndexToIndexPath(playlistIndex: Int) -> IndexPath? {
        if playlistIndex == playIndex {
            return nil
        }
        if playlistIndex < playIndex {
            return IndexPath(row: playlistIndex, section: 0)
        } else {
            return IndexPath(row: playlistIndex-playIndex-1, section: 1)
        }
    }
    
}
