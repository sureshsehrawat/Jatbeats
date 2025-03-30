import Foundation
import UIKit

extension Notification.Name {
  static let playerPlay = Notification.Name("playerPlay")
  static let playerPause = Notification.Name("playerPause")
  static let playerStop = Notification.Name("playerStop")
  static let playerPlaylistPositionChanged = Notification.Name("playerPlaylistPositionChanged")
  static let playerPlaylistChanged = Notification.Name("playerPlaylistChanged")
  static let playerPlayableChanged = Notification.Name("playerPlayableChanged")
  static let playerDurationChanged = Notification.Name("playerDurationChanged")
  static let playerCurrentPlayProgress = Notification.Name("playerCurrentPlayProgress")
  static let downloadQueueItemsChanged = Notification.Name("downloadQueueItemsChanged")
  static let libraryChanged = Notification.Name("libraryChanged")
  static let themeChanged = Notification.Name("userThemeChanged")
  static let lightDarkModeChanged = Notification.Name("userLightDarkModeChanged")
  static let offlineModeChanged = Notification.Name("offlineModeChanged")
  static let prefetchingChanged = Notification.Name("prefetchingChanged")
  static let biometricPromptEnabled = Notification.Name("biometricPromptEnabled")
  static let spotlightIndexingStarted = Notification.Name("spotlightIndexingStarted")
  static let showStreamingElementsChanged = Notification.Name("showStreamingElementsChanged")
  static let radioArtworkUpdated = Notification.Name("radioArtworkUpdated")
} 