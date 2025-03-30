//
//  RadiosVC.swift
//  Amperfy
//
//  Created by Maximilian Bauer on 27.12.24.
//  Copyright (c) 2024 Maximilian Bauer. All rights reserved.
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

import AmperfyKit
import CoreData
import UIKit
import PhotosUI

class RadiosVC: SingleFetchedResultsTableViewController<RadioMO> {
  override var sceneTitle: String? {
    "Radios"
  }

  private var fetchedResultsController: RadiosFetchedResultsController!
  private var detailHeaderView: LibraryElementDetailTableHeaderView?
  private var profileImageButton: UIButton!
  private var profileImageView: UIImageView!
  private let profileImageSize: CGFloat = 36

  override func viewDidLoad() {
    super.viewDidLoad()

    #if !targetEnvironment(macCatalyst)
      refreshControl = UIRefreshControl()
    #endif

    appDelegate.userStatistics.visited(.radios)

    fetchedResultsController = RadiosFetchedResultsController(
      coreDataCompanion: appDelegate.storage.main,
      isGroupedInAlphabeticSections: true
    )
    singleFetchedResultsController = fetchedResultsController
    tableView.reloadData()

    configureSearchController(
      placeholder: "Search in \"\(sceneTitle ?? "")\"",
      showSearchBarAtEnter: true
    )
    tableView.register(nibName: PlayableTableCell.typeName)
    tableView.rowHeight = PlayableTableCell.rowHeight
    tableView.estimatedRowHeight = PlayableTableCell.rowHeight

    let playShuffleConfig = PlayShuffleInfoConfiguration(
      infoCB: {
        "\(self.fetchedResultsController.fetchedObjects?.count ?? 0) Radio\((self.fetchedResultsController.fetchedObjects?.count ?? 0) == 1 ? "" : "s")"
      },
      playContextCb: handleHeaderPlay,
      player: appDelegate.player,
      isInfoAlwaysHidden: false,
      isShuffleOnContextNeccessary: false,
      shuffleContextCb: handleHeaderShuffle
    )
    detailHeaderView = LibraryElementDetailTableHeaderView.createTableHeader(
      rootView: self,
      configuration: playShuffleConfig
    )
    refreshControl?.addTarget(
      self,
      action: #selector(Self.handleRefresh),
      for: UIControl.Event.valueChanged
    )

    containableAtIndexPathCallback = { indexPath in
      self.fetchedResultsController.getWrappedEntity(at: indexPath)
    }
    playContextAtIndexPathCallback = convertIndexPathToPlayContext
    swipeCallback = { indexPath, completionHandler in
      let radio = self.fetchedResultsController.getWrappedEntity(at: indexPath)
      let playContext = self.convertIndexPathToPlayContext(radioIndexPath: indexPath)
      completionHandler(SwipeActionContext(containable: radio, playContext: playContext))
    }
    setNavBarTitle(title: sceneTitle ?? "")
    setupProfilePicture()
    
    // Update custom radio artwork (like Neha Kakkar's artwork) from specific albums
    // Use the helper class instead of direct implementation
    Task {
      let _ = await updateNehaKakkarRadioArtwork()
      let _ = await updateBadshahRadioArtwork()
      let _ = await updateSonuNigamRadioArtwork()
      let _ = await updateUditNarayanRadioArtwork()
      let _ = await updateShaanRadioArtwork()
      let _ = await updateKumarSanuRadioArtwork()
      let _ = await updateMohammedRafiRadioArtwork()
      let _ = await updateLataMangeshkarRadioArtwork()
      let _ = await updateKishoreKumarRadioArtwork()
      let _ = await updateKKRadioArtwork()
      let _ = await updateAshaBhosleRadioArtwork()
      let _ = await updateDonnaSummerRadioArtwork()
      await MainActor.run {
        tableView.reloadData()
      }
    }
    
    // Listen for artwork update notifications
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleArtworkUpdated),
      name: Notification.Name("radioArtworkUpdated"),
      object: nil
    )
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    updateProfilePicture()
    updateFromRemote()
  }

  func updateFromRemote() {
    guard appDelegate.storage.settings.isOnlineMode else { return }
    Task { @MainActor in
      do {
        try await self.appDelegate.librarySyncer.syncRadios()
      } catch {
        self.appDelegate.eventLogger.report(topic: "Radios Sync", error: error)
      }
      self.detailHeaderView?.refresh()
      self.updateSearchResults(for: self.searchController)
    }
  }

  public func handleHeaderPlay() -> PlayContext {
    guard let displayedRadiosMO = fetchedResultsController.fetchedObjects else { return PlayContext(
      name: sceneTitle ?? "",
      playables: []
    ) }
    let radios = displayedRadiosMO.prefix(appDelegate.player.maxSongsToAddOnce)
      .compactMap { Radio(managedObject: $0) }
    return PlayContext(name: sceneTitle ?? "", playables: radios)
  }

  public func handleHeaderShuffle() -> PlayContext {
    guard let displayedRadiosMO = fetchedResultsController.fetchedObjects else { return PlayContext(
      name: sceneTitle ?? "",
      playables: []
    ) }
    let radios = displayedRadiosMO.prefix(appDelegate.player.maxSongsToAddOnce)
      .compactMap { Radio(managedObject: $0) }
    return PlayContext(
      name: sceneTitle ?? "",
      index: Int.random(in: 0 ..< radios.count),
      playables: radios
    )
  }

  override func tableView(
    _ tableView: UITableView,
    cellForRowAt indexPath: IndexPath
  )
    -> UITableViewCell {
    let cell: PlayableTableCell = dequeueCell(for: tableView, at: indexPath)
    let radio = fetchedResultsController.getWrappedEntity(at: indexPath)
    cell.display(playable: radio, playContextCb: convertCellViewToPlayContext, rootView: self)
    return cell
  }

  override func tableView(
    _ tableView: UITableView,
    heightForHeaderInSection section: Int
  )
    -> CGFloat {
    0.0
  }

  override func tableView(
    _ tableView: UITableView,
    titleForHeaderInSection section: Int
  )
    -> String? {
    nil
  }

  func convertIndexPathToPlayContext(radioIndexPath: IndexPath) -> PlayContext? {
    guard let radios = fetchedResultsController.getContextRadios()
    else { return nil }
    let selectedRadio = fetchedResultsController.getWrappedEntity(at: radioIndexPath)
    guard let playContextIndex = radios.firstIndex(of: selectedRadio) else { return nil }
    return PlayContext(name: sceneTitle ?? "", index: playContextIndex, playables: radios)
  }

  func convertCellViewToPlayContext(cell: UITableViewCell) -> PlayContext? {
    guard let indexPath = tableView.indexPath(for: cell) else { return nil }
    return convertIndexPathToPlayContext(radioIndexPath: indexPath)
  }

  override func updateSearchResults(for searchController: UISearchController) {
    guard let searchText = searchController.searchBar.text else { return }
    if !searchText.isEmpty {
      fetchedResultsController.search(searchText: searchText)
    } else {
      fetchedResultsController.showAllResults()
    }
    tableView.reloadData()
  }

  @objc
  func handleRefresh(refreshControl: UIRefreshControl) {
    guard appDelegate.storage.settings.isOnlineMode else {
      #if !targetEnvironment(macCatalyst)
        self.refreshControl?.endRefreshing()
      #endif
      return
    }
    Task { @MainActor in
      do {
        try await self.appDelegate.librarySyncer.syncRadios()
      } catch {
        self.appDelegate.eventLogger.report(topic: "Radios Sync", error: error)
      }
      self.detailHeaderView?.refresh()
      self.updateSearchResults(for: self.searchController)
      #if !targetEnvironment(macCatalyst)
        self.refreshControl?.endRefreshing()
      #endif
    }
  }

  @objc private func handleArtworkUpdated() {
    tableView.reloadData()
  }
  
  // Update artwork for Neha Kakkar's radio card
  // Only changes artwork if it's not already set to the correct one
  private func updateNehaKakkarRadioArtwork() async -> Bool {
    // 1. Find the "This is Neha Kakkar" album
    let albumFetchRequest: NSFetchRequest<AlbumMO> = AlbumMO.fetchRequest()
    albumFetchRequest.predicate = NSPredicate(
      format: "%K CONTAINS[cd] %@", 
      #keyPath(AlbumMO.name), 
      "This is Neha Kakkar"
    )
    albumFetchRequest.fetchLimit = 1
    
    guard let foundAlbums = try? appDelegate.storage.main.context.fetch(albumFetchRequest),
          let albumMO = foundAlbums.first else {
      print("Failed to find 'This is Neha Kakkar' album")
      return false
    }
    
    let album = Album(managedObject: albumMO)
    guard let albumArtwork = album.artwork else {
      print("Failed to find artwork for 'This is Neha Kakkar' album")
      return false
    }
    
    // 2. Find the Neha Kakkar radio
    let radioFetchRequest: NSFetchRequest<RadioMO> = RadioMO.fetchRequest()
    radioFetchRequest.predicate = NSPredicate(
      format: "%K CONTAINS[cd] %@", 
      #keyPath(RadioMO.title), 
      "Neha Kakkar"
    )
    
    guard let foundRadios = try? appDelegate.storage.main.context.fetch(radioFetchRequest),
          let radioMO = foundRadios.first else {
      print("Failed to find Neha Kakkar radio")
      return false
    }
    
    let radio = Radio(managedObject: radioMO)
    
    // Check if the artwork is already set correctly
    if let currentArtwork = radio.artwork, currentArtwork.id == albumArtwork.id {
      print("Neha Kakkar radio already has the correct artwork")
      return true
    }
    
    // 3. Update the radio's artwork to use the album artwork
    radio.artwork = albumArtwork
    
    // 4. Save changes in a transaction to ensure it's durable
    appDelegate.storage.main.saveContext()
    print("Successfully updated Neha Kakkar radio artwork using 'This is Neha Kakkar' album artwork")
    
    return true
  }
  
  // Update artwork for Donna Summer's radio card
  // Only changes artwork if it's not already set to the correct one
  private func updateDonnaSummerRadioArtwork() async -> Bool {
    // 1. Find the "I Remember Yesterday" album
    let albumFetchRequest: NSFetchRequest<AlbumMO> = AlbumMO.fetchRequest()
    albumFetchRequest.predicate = NSPredicate(
      format: "%K CONTAINS[cd] %@", 
      #keyPath(AlbumMO.name), 
      "I Remember Yesterday"
    )
    albumFetchRequest.fetchLimit = 1
    
    guard let foundAlbums = try? appDelegate.storage.main.context.fetch(albumFetchRequest),
          let albumMO = foundAlbums.first else {
      print("Failed to find 'I Remember Yesterday' album")
      return false
    }
    
    let album = Album(managedObject: albumMO)
    guard let albumArtwork = album.artwork else {
      print("Failed to find artwork for 'I Remember Yesterday' album")
      return false
    }
    
    // 2. Find the Donna Summer radio
    let radioFetchRequest: NSFetchRequest<RadioMO> = RadioMO.fetchRequest()
    radioFetchRequest.predicate = NSPredicate(
      format: "%K CONTAINS[cd] %@", 
      #keyPath(RadioMO.title), 
      "Donna Summer"
    )
    
    guard let foundRadios = try? appDelegate.storage.main.context.fetch(radioFetchRequest),
          let radioMO = foundRadios.first else {
      print("Failed to find Donna Summer radio")
      return false
    }
    
    let radio = Radio(managedObject: radioMO)
    
    // Check if the artwork is already set correctly
    if let currentArtwork = radio.artwork, currentArtwork.id == albumArtwork.id {
      print("Donna Summer radio already has the correct artwork")
      return true
    }
    
    // 3. Update the radio's artwork to use the album artwork
    radio.artwork = albumArtwork
    
    // 4. Save changes in a transaction to ensure it's durable
    appDelegate.storage.main.saveContext()
    print("Successfully updated Donna Summer radio artwork using 'I Remember Yesterday' album artwork")
    
    return true
  }
  
  // Update artwork for Badshah's radio card
  // Only changes artwork if it's not already set to the correct one
  private func updateBadshahRadioArtwork() async -> Bool {
    // 1. Find the "This is Badshah" album
    let albumFetchRequest: NSFetchRequest<AlbumMO> = AlbumMO.fetchRequest()
    albumFetchRequest.predicate = NSPredicate(
      format: "%K CONTAINS[cd] %@", 
      #keyPath(AlbumMO.name), 
      "This is Badshah"
    )
    albumFetchRequest.fetchLimit = 1
    
    guard let foundAlbums = try? appDelegate.storage.main.context.fetch(albumFetchRequest),
          let albumMO = foundAlbums.first else {
      print("Failed to find 'This is Badshah' album")
      return false
    }
    
    let album = Album(managedObject: albumMO)
    guard let albumArtwork = album.artwork else {
      print("Failed to find artwork for 'This is Badshah' album")
      return false
    }
    
    // 2. Find the Badshah radio
    let radioFetchRequest: NSFetchRequest<RadioMO> = RadioMO.fetchRequest()
    radioFetchRequest.predicate = NSPredicate(
      format: "%K CONTAINS[cd] %@", 
      #keyPath(RadioMO.title), 
      "Badshah"
    )
    
    guard let foundRadios = try? appDelegate.storage.main.context.fetch(radioFetchRequest),
          let radioMO = foundRadios.first else {
      print("Failed to find Badshah radio")
      return false
    }
    
    let radio = Radio(managedObject: radioMO)
    
    // Check if the artwork is already set correctly
    if let currentArtwork = radio.artwork, currentArtwork.id == albumArtwork.id {
      print("Badshah radio already has the correct artwork")
      return true
    }
    
    // 3. Update the radio's artwork to use the album artwork
    radio.artwork = albumArtwork
    
    // 4. Save changes in a transaction to ensure it's durable
    appDelegate.storage.main.saveContext()
    
    // 5. Post notification to update the UI
    await MainActor.run {
      NotificationCenter.default.post(name: Notification.Name("radioArtworkUpdated"), object: nil)
    }
    
    print("Successfully updated Badshah radio artwork using 'This is Badshah' album artwork")
    
    return true
  }
  
  // Update artwork for Sonu Nigam's radio card
  // Only changes artwork if it's not already set to the correct one
  private func updateSonuNigamRadioArtwork() async -> Bool {
    // 1. Find the "This is Sonu Nigam" album
    let albumFetchRequest: NSFetchRequest<AlbumMO> = AlbumMO.fetchRequest()
    albumFetchRequest.predicate = NSPredicate(
      format: "%K CONTAINS[cd] %@", 
      #keyPath(AlbumMO.name), 
      "This is Sonu Nigam"
    )
    albumFetchRequest.fetchLimit = 1
    
    guard let foundAlbums = try? appDelegate.storage.main.context.fetch(albumFetchRequest),
          let albumMO = foundAlbums.first else {
      print("Failed to find 'This is Sonu Nigam' album")
      return false
    }
    
    let album = Album(managedObject: albumMO)
    guard let albumArtwork = album.artwork else {
      print("Failed to find artwork for 'This is Sonu Nigam' album")
      return false
    }
    
    // 2. Find the Sonu Nigam radio
    let radioFetchRequest: NSFetchRequest<RadioMO> = RadioMO.fetchRequest()
    radioFetchRequest.predicate = NSPredicate(
      format: "%K CONTAINS[cd] %@", 
      #keyPath(RadioMO.title), 
      "Sonu Nigam"
    )
    
    guard let foundRadios = try? appDelegate.storage.main.context.fetch(radioFetchRequest),
          let radioMO = foundRadios.first else {
      print("Failed to find Sonu Nigam radio")
      return false
    }
    
    let radio = Radio(managedObject: radioMO)
    
    // Check if the artwork is already set correctly
    if let currentArtwork = radio.artwork, currentArtwork.id == albumArtwork.id {
      print("Sonu Nigam radio already has the correct artwork")
      return true
    }
    
    // 3. Update the radio's artwork to use the album artwork
    radio.artwork = albumArtwork
    
    // 4. Save changes in a transaction to ensure it's durable
    appDelegate.storage.main.saveContext()
    
    // 5. Post notification to update the UI
    await MainActor.run {
      NotificationCenter.default.post(name: Notification.Name("radioArtworkUpdated"), object: nil)
    }
    
    print("Successfully updated Sonu Nigam radio artwork using 'This is Sonu Nigam' album artwork")
    return true
  }
  
  // Update artwork for Udit Narayan's radio card
  // Only changes artwork if it's not already set to the correct one
  private func updateUditNarayanRadioArtwork() async -> Bool {
    // 1. Find the "Udit Narayan Radio" album
    let albumFetchRequest: NSFetchRequest<AlbumMO> = AlbumMO.fetchRequest()
    albumFetchRequest.predicate = NSPredicate(
      format: "%K CONTAINS[cd] %@", 
      #keyPath(AlbumMO.name), 
      "Udit Narayan Radio"
    )
    albumFetchRequest.fetchLimit = 1
    
    guard let foundAlbums = try? appDelegate.storage.main.context.fetch(albumFetchRequest),
          let albumMO = foundAlbums.first else {
      print("Failed to find 'Udit Narayan Radio' album")
      return false
    }
    
    let album = Album(managedObject: albumMO)
    guard let albumArtwork = album.artwork else {
      print("Failed to find artwork for 'Udit Narayan Radio' album")
      return false
    }
    
    // 2. Find the Udit Narayan radio
    let radioFetchRequest: NSFetchRequest<RadioMO> = RadioMO.fetchRequest()
    radioFetchRequest.predicate = NSPredicate(
      format: "%K CONTAINS[cd] %@", 
      #keyPath(RadioMO.title), 
      "Udit Narayan"
    )
    
    guard let foundRadios = try? appDelegate.storage.main.context.fetch(radioFetchRequest),
          let radioMO = foundRadios.first else {
      print("Failed to find Udit Narayan radio")
      return false
    }
    
    let radio = Radio(managedObject: radioMO)
    
    // Check if the artwork is already set correctly
    if let currentArtwork = radio.artwork, currentArtwork.id == albumArtwork.id {
      print("Udit Narayan radio already has the correct artwork")
      return true
    }
    
    // 3. Update the radio's artwork to use the album artwork
    radio.artwork = albumArtwork
    
    // 4. Save changes in a transaction to ensure it's durable
    appDelegate.storage.main.saveContext()
    
    // 5. Post notification to update the UI
    await MainActor.run {
      NotificationCenter.default.post(name: Notification.Name("radioArtworkUpdated"), object: nil)
    }
    
    print("Successfully updated Udit Narayan radio artwork using 'Udit Narayan Radio' album artwork")
    return true
  }
  
  // Update artwork for Shaan's radio card
  // Only changes artwork if it's not already set to the correct one
  private func updateShaanRadioArtwork() async -> Bool {
    // 1. Find the "This Is Shaan" album
    let albumFetchRequest: NSFetchRequest<AlbumMO> = AlbumMO.fetchRequest()
    albumFetchRequest.predicate = NSPredicate(
      format: "%K CONTAINS[cd] %@", 
      #keyPath(AlbumMO.name), 
      "This Is Shaan"
    )
    albumFetchRequest.fetchLimit = 1
    
    guard let foundAlbums = try? appDelegate.storage.main.context.fetch(albumFetchRequest),
          let albumMO = foundAlbums.first else {
      print("Failed to find 'This Is Shaan' album")
      return false
    }
    
    let album = Album(managedObject: albumMO)
    guard let albumArtwork = album.artwork else {
      print("Failed to find artwork for 'This Is Shaan' album")
      return false
    }
    
    // 2. Find the Shaan radio
    let radioFetchRequest: NSFetchRequest<RadioMO> = RadioMO.fetchRequest()
    radioFetchRequest.predicate = NSPredicate(
      format: "%K CONTAINS[cd] %@", 
      #keyPath(RadioMO.title), 
      "Shaan"
    )
    
    guard let foundRadios = try? appDelegate.storage.main.context.fetch(radioFetchRequest),
          let radioMO = foundRadios.first else {
      print("Failed to find Shaan radio")
      return false
    }
    
    let radio = Radio(managedObject: radioMO)
    
    // Check if the artwork is already set correctly
    if let currentArtwork = radio.artwork, currentArtwork.id == albumArtwork.id {
      print("Shaan radio already has the correct artwork")
      return true
    }
    
    // 3. Update the radio's artwork to use the album artwork
    radio.artwork = albumArtwork
    
    // 4. Save changes in a transaction to ensure it's durable
    appDelegate.storage.main.saveContext()
    
    // 5. Post notification to update the UI
    await MainActor.run {
      NotificationCenter.default.post(name: Notification.Name("radioArtworkUpdated"), object: nil)
    }
    
    print("Successfully updated Shaan radio artwork using 'This Is Shaan' album artwork")
    return true
  }
  
  // Update artwork for Kumar Sanu's radio card
  // Only changes artwork if it's not already set to the correct one
  private func updateKumarSanuRadioArtwork() async -> Bool {
    // 1. Find the "Kumar Sanu All Time Hits" album
    let albumFetchRequest: NSFetchRequest<AlbumMO> = AlbumMO.fetchRequest()
    albumFetchRequest.predicate = NSPredicate(
      format: "%K CONTAINS[cd] %@", 
      #keyPath(AlbumMO.name), 
      "Kumar Sanu All Time Hits"
    )
    albumFetchRequest.fetchLimit = 1
    
    guard let foundAlbums = try? appDelegate.storage.main.context.fetch(albumFetchRequest),
          let albumMO = foundAlbums.first else {
      print("Failed to find 'Kumar Sanu All Time Hits' album")
      return false
    }
    
    let album = Album(managedObject: albumMO)
    guard let albumArtwork = album.artwork else {
      print("Failed to find artwork for 'Kumar Sanu All Time Hits' album")
      return false
    }
    
    // 2. Find the Kumar Sanu radio
    let radioFetchRequest: NSFetchRequest<RadioMO> = RadioMO.fetchRequest()
    radioFetchRequest.predicate = NSPredicate(
      format: "%K CONTAINS[cd] %@", 
      #keyPath(RadioMO.title), 
      "Kumar Sanu"
    )
    
    guard let foundRadios = try? appDelegate.storage.main.context.fetch(radioFetchRequest),
          let radioMO = foundRadios.first else {
      print("Failed to find Kumar Sanu radio")
      return false
    }
    
    let radio = Radio(managedObject: radioMO)
    
    // Check if the artwork is already set correctly
    if let currentArtwork = radio.artwork, currentArtwork.id == albumArtwork.id {
      print("Kumar Sanu radio already has the correct artwork")
      return true
    }
    
    // 3. Update the radio's artwork to use the album artwork
    radio.artwork = albumArtwork
    
    // 4. Save changes in a transaction to ensure it's durable
    appDelegate.storage.main.saveContext()
    
    // 5. Post notification to update the UI
    await MainActor.run {
      NotificationCenter.default.post(name: Notification.Name("radioArtworkUpdated"), object: nil)
    }
    
    print("Successfully updated Kumar Sanu radio artwork using 'Kumar Sanu All Time Hits' album artwork")
    return true
  }
  
  // Update artwork for Mohammed Rafi's radio card
  // Only changes artwork if it's not already set to the correct one
  private func updateMohammedRafiRadioArtwork() async -> Bool {
    // 1. Find the "Mohammed Rafi Songs Collection" album
    let albumFetchRequest: NSFetchRequest<AlbumMO> = AlbumMO.fetchRequest()
    albumFetchRequest.predicate = NSPredicate(
      format: "%K CONTAINS[cd] %@", 
      #keyPath(AlbumMO.name), 
      "Mohammed Rafi Songs Collection"
    )
    albumFetchRequest.fetchLimit = 1
    
    guard let foundAlbums = try? appDelegate.storage.main.context.fetch(albumFetchRequest),
          let albumMO = foundAlbums.first else {
      print("Failed to find 'Mohammed Rafi Songs Collection' album")
      return false
    }
    
    let album = Album(managedObject: albumMO)
    guard let albumArtwork = album.artwork else {
      print("Failed to find artwork for 'Mohammed Rafi Songs Collection' album")
      return false
    }
    
    // 2. Find the Mohammed Rafi radio
    let radioFetchRequest: NSFetchRequest<RadioMO> = RadioMO.fetchRequest()
    radioFetchRequest.predicate = NSPredicate(
      format: "%K CONTAINS[cd] %@", 
      #keyPath(RadioMO.title), 
      "Mohammed Rafi"
    )
    
    guard let foundRadios = try? appDelegate.storage.main.context.fetch(radioFetchRequest),
          let radioMO = foundRadios.first else {
      print("Failed to find Mohammed Rafi radio")
      return false
    }
    
    let radio = Radio(managedObject: radioMO)
    
    // Check if the artwork is already set correctly
    if let currentArtwork = radio.artwork, currentArtwork.id == albumArtwork.id {
      print("Mohammed Rafi radio already has the correct artwork")
      return true
    }
    
    // 3. Update the radio's artwork to use the album artwork
    radio.artwork = albumArtwork
    
    // 4. Save changes in a transaction to ensure it's durable
    appDelegate.storage.main.saveContext()
    
    // 5. Post notification to update the UI
    await MainActor.run {
      NotificationCenter.default.post(name: Notification.Name("radioArtworkUpdated"), object: nil)
    }
    
    print("Successfully updated Mohammed Rafi radio artwork using 'Mohammed Rafi Songs Collection' album artwork")
    return true
  }
  
  // Update artwork for Lata Mangeshkar's radio card
  // Only changes artwork if it's not already set to the correct one
  private func updateLataMangeshkarRadioArtwork() async -> Bool {
    // 1. Find the "Best Of Lata Mangeshkar & Kishore Kumar Duets" album
    let albumFetchRequest: NSFetchRequest<AlbumMO> = AlbumMO.fetchRequest()
    albumFetchRequest.predicate = NSPredicate(
      format: "%K CONTAINS[cd] %@", 
      #keyPath(AlbumMO.name), 
      "Best Of Lata Mangeshkar & Kishore Kumar Duets"
    )
    albumFetchRequest.fetchLimit = 1
    
    guard let foundAlbums = try? appDelegate.storage.main.context.fetch(albumFetchRequest),
          let albumMO = foundAlbums.first else {
      print("Failed to find 'Best Of Lata Mangeshkar & Kishore Kumar Duets' album")
      return false
    }
    
    let album = Album(managedObject: albumMO)
    guard let albumArtwork = album.artwork else {
      print("Failed to find artwork for 'Best Of Lata Mangeshkar & Kishore Kumar Duets' album")
      return false
    }
    
    // 2. Find the Lata Mangeshkar radio
    let radioFetchRequest: NSFetchRequest<RadioMO> = RadioMO.fetchRequest()
    radioFetchRequest.predicate = NSPredicate(
      format: "%K CONTAINS[cd] %@", 
      #keyPath(RadioMO.title), 
      "Lata Mangeshkar"
    )
    
    guard let foundRadios = try? appDelegate.storage.main.context.fetch(radioFetchRequest),
          let radioMO = foundRadios.first else {
      print("Failed to find Lata Mangeshkar radio")
      return false
    }
    
    let radio = Radio(managedObject: radioMO)
    
    // Check if the artwork is already set correctly
    if let currentArtwork = radio.artwork, currentArtwork.id == albumArtwork.id {
      print("Lata Mangeshkar radio already has the correct artwork")
      return true
    }
    
    // 3. Update the radio's artwork to use the album artwork
    radio.artwork = albumArtwork
    
    // 4. Save changes in a transaction to ensure it's durable
    appDelegate.storage.main.saveContext()
    
    // 5. Post notification to update the UI
    await MainActor.run {
      NotificationCenter.default.post(name: Notification.Name("radioArtworkUpdated"), object: nil)
    }
    
    print("Successfully updated Lata Mangeshkar radio artwork using 'Best Of Lata Mangeshkar & Kishore Kumar Duets' album artwork")
    return true
  }
  
  // Update artwork for Kishore Kumar's radio card
  // Only changes artwork if it's not already set to the correct one
  private func updateKishoreKumarRadioArtwork() async -> Bool {
    // Define array of potential album names to try
    let albumNames = [
      "Golden & Timeless Old Bollywood",
      "Kishore Kumar Hits", 
      "The Best of Kishore Kumar",
      "Kishore Kumar Greatest Hits",
      "Classic Kishore Kumar",
      "Best Of Lata Mangeshkar & Kishore Kumar Duets" // Fallback to this album which we know exists
    ]
    
    var album: Album?
    var albumArtwork: Artwork?
    
    // Try each album name until we find one
    for albumName in albumNames {
      let albumFetchRequest: NSFetchRequest<AlbumMO> = AlbumMO.fetchRequest()
      albumFetchRequest.predicate = NSPredicate(
        format: "%K CONTAINS[cd] %@", 
        #keyPath(AlbumMO.name), 
        albumName
      )
      albumFetchRequest.fetchLimit = 1
      
      guard let foundAlbums = try? appDelegate.storage.main.context.fetch(albumFetchRequest),
            let albumMO = foundAlbums.first else {
        continue
      }
      
      album = Album(managedObject: albumMO)
      if let artwork = album?.artwork {
        albumArtwork = artwork
        print("Found album: \(albumName) with artwork")
        break
      }
    }
    
    // If no album with artwork found, return failure
    guard let albumArtwork = albumArtwork else {
      print("Failed to find any album with artwork for Kishore Kumar")
      return false
    }
    
    // 2. Find the Kishore Kumar radio
    let radioFetchRequest: NSFetchRequest<RadioMO> = RadioMO.fetchRequest()
    radioFetchRequest.predicate = NSPredicate(
      format: "%K CONTAINS[cd] %@", 
      #keyPath(RadioMO.title), 
      "Kishore Kumar"
    )
    
    guard let foundRadios = try? appDelegate.storage.main.context.fetch(radioFetchRequest),
          let radioMO = foundRadios.first else {
      print("Failed to find Kishore Kumar radio")
      return false
    }
    
    let radio = Radio(managedObject: radioMO)
    
    // Check if the artwork is already set correctly
    if let currentArtwork = radio.artwork, currentArtwork.id == albumArtwork.id {
      print("Kishore Kumar radio already has the correct artwork")
      return true
    }
    
    // 3. Update the radio's artwork to use the album artwork
    radio.artwork = albumArtwork
    
    // 4. Save changes in a transaction to ensure it's durable
    appDelegate.storage.main.saveContext()
    print("Successfully updated Kishore Kumar radio artwork")
    
    return true
  }
  
  // Update artwork for K K's radio card
  // Only changes artwork if it's not already set to the correct one
  private func updateKKRadioArtwork() async -> Bool {
    // 1. Find the "Evergreen Hits of K.K" album
    let albumFetchRequest: NSFetchRequest<AlbumMO> = AlbumMO.fetchRequest()
    albumFetchRequest.predicate = NSPredicate(
      format: "%K CONTAINS[cd] %@", 
      #keyPath(AlbumMO.name), 
      "Evergreen Hits of K.K"
    )
    albumFetchRequest.fetchLimit = 1
    
    guard let foundAlbums = try? appDelegate.storage.main.context.fetch(albumFetchRequest),
          let albumMO = foundAlbums.first else {
      print("Failed to find 'Evergreen Hits of K.K' album")
      return false
    }
    
    let album = Album(managedObject: albumMO)
    guard let albumArtwork = album.artwork else {
      print("Failed to find artwork for 'Evergreen Hits of K.K' album")
      return false
    }
    
    // 2. Find the K K radio
    let radioFetchRequest: NSFetchRequest<RadioMO> = RadioMO.fetchRequest()
    radioFetchRequest.predicate = NSPredicate(
      format: "%K CONTAINS[cd] %@", 
      #keyPath(RadioMO.title), 
      "K K"
    )
    
    guard let foundRadios = try? appDelegate.storage.main.context.fetch(radioFetchRequest),
          let radioMO = foundRadios.first else {
      print("Failed to find K K radio")
      return false
    }
    
    let radio = Radio(managedObject: radioMO)
    
    // Check if the artwork is already set correctly
    if let currentArtwork = radio.artwork, currentArtwork.id == albumArtwork.id {
      print("K K radio already has the correct artwork")
      return true
    }
    
    // 3. Update the radio's artwork to use the album artwork
    radio.artwork = albumArtwork
    
    // 4. Save changes in a transaction to ensure it's durable
    appDelegate.storage.main.saveContext()
    print("Successfully updated K K radio artwork using 'Evergreen Hits of K.K' album artwork")
    
    return true
  }
  
  // Update artwork for Asha Bhosle's radio card
  // Only changes artwork if it's not already set to the correct one
  private func updateAshaBhosleRadioArtwork() async -> Bool {
    // 1. Find the "Asha Bhosle Dance Songs" album
    let albumFetchRequest: NSFetchRequest<AlbumMO> = AlbumMO.fetchRequest()
    albumFetchRequest.predicate = NSPredicate(
      format: "%K CONTAINS[cd] %@", 
      #keyPath(AlbumMO.name), 
      "Asha Bhosle Dance Songs"
    )
    albumFetchRequest.fetchLimit = 1
    
    guard let foundAlbums = try? appDelegate.storage.main.context.fetch(albumFetchRequest),
          let albumMO = foundAlbums.first else {
      print("Failed to find 'Asha Bhosle Dance Songs' album")
      return false
    }
    
    let album = Album(managedObject: albumMO)
    guard let albumArtwork = album.artwork else {
      print("Failed to find artwork for 'Asha Bhosle Dance Songs' album")
      return false
    }
    
    // 2. Find the Asha Bhosle radio
    let radioFetchRequest: NSFetchRequest<RadioMO> = RadioMO.fetchRequest()
    radioFetchRequest.predicate = NSPredicate(
      format: "%K CONTAINS[cd] %@", 
      #keyPath(RadioMO.title), 
      "Asha Bhosle"
    )
    
    guard let foundRadios = try? appDelegate.storage.main.context.fetch(radioFetchRequest),
          let radioMO = foundRadios.first else {
      print("Failed to find Asha Bhosle radio")
      return false
    }
    
    let radio = Radio(managedObject: radioMO)
    
    // Check if the artwork is already set correctly
    if let currentArtwork = radio.artwork, currentArtwork.id == albumArtwork.id {
      print("Asha Bhosle radio already has the correct artwork")
      return true
    }
    
    // 3. Update the radio's artwork to use the album artwork
    radio.artwork = albumArtwork
    
    // 4. Save changes in a transaction to ensure it's durable
    appDelegate.storage.main.saveContext()
    print("Successfully updated Asha Bhosle radio artwork using 'Asha Bhosle Dance Songs' album artwork")
    
    return true
  }

  private func setupProfilePicture() {
    // Create a profile image view inside a button
    profileImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: profileImageSize, height: profileImageSize))
    profileImageView.contentMode = .scaleAspectFill
    profileImageView.clipsToBounds = true
    profileImageView.layer.cornerRadius = profileImageSize / 2
    profileImageView.backgroundColor = .systemGray5
    
    // If no profile image, show placeholder
    if profileImageView.image == nil {
      profileImageView.image = UIImage(systemName: "person.crop.circle.fill")
      profileImageView.tintColor = .systemGray2
    }
    
    // Create the profile button that contains the image view
    profileImageButton = UIButton(type: .system)
    profileImageButton.frame = CGRect(x: 0, y: 0, width: profileImageSize, height: profileImageSize)
    profileImageButton.addSubview(profileImageView)
    
    // Make sure the image view is centered and fills the button
    profileImageView.frame = profileImageButton.bounds
    
    profileImageButton.addTarget(self, action: #selector(profilePictureTapped), for: .touchUpInside)
    
    // Create a UIBarButtonItem with the profile button
    let profileButtonItem = UIBarButtonItem(customView: profileImageButton)
    
    // Add profile button to the right of navigation bar
    navigationItem.rightBarButtonItem = profileButtonItem
    
    // Update profile picture if exists
    updateProfilePicture()
  }
  
  private func updateProfilePicture() {
    if let profilePicturePath = appDelegate.storage.settings.profilePicturePath,
       let profileImage = UIImage(contentsOfFile: profilePicturePath) {
      profileImageView.image = profileImage
      profileImageView.tintColor = .clear
    }
  }
  
  @objc private func profilePictureTapped() {
    // Create action sheet for profile picture options
    let actionSheet = UIAlertController(title: "Profile Picture", message: nil, preferredStyle: .actionSheet)
    
    // Option to take a photo
    actionSheet.addAction(UIAlertAction(title: "Take Photo", style: .default) { [weak self] _ in
      self?.presentCamera()
    })
    
    // Option to choose from photo library
    actionSheet.addAction(UIAlertAction(title: "Choose from Library", style: .default) { [weak self] _ in
      self?.presentPhotoPicker()
    })
    
    // Option to remove profile picture (only if one exists)
    if appDelegate.storage.settings.profilePicturePath != nil {
      actionSheet.addAction(UIAlertAction(title: "Remove Picture", style: .destructive) { [weak self] _ in
        self?.removeProfilePicture()
      })
    }
    
    // Cancel option
    actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
    
    // For iPad, set the source view for the popover
    if let popoverController = actionSheet.popoverPresentationController {
      popoverController.sourceView = profileImageButton
      popoverController.sourceRect = profileImageButton.bounds
    }
    
    present(actionSheet, animated: true)
  }
  
  private func presentCamera() {
    guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
      let alert = UIAlertController(title: "Camera Not Available", message: "This device does not have a camera.", preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "OK", style: .default))
      present(alert, animated: true)
      return
    }
    
    let imagePickerController = UIImagePickerController()
    imagePickerController.sourceType = .camera
    imagePickerController.allowsEditing = true
    imagePickerController.delegate = self
    present(imagePickerController, animated: true)
  }
  
  private func presentPhotoPicker() {
    if #available(iOS 14, *) {
      var configuration = PHPickerConfiguration()
      configuration.selectionLimit = 1
      configuration.filter = .images
      
      let picker = PHPickerViewController(configuration: configuration)
      picker.delegate = self
      present(picker, animated: true)
    } else {
      let imagePickerController = UIImagePickerController()
      imagePickerController.sourceType = .photoLibrary
      imagePickerController.allowsEditing = true
      imagePickerController.delegate = self
      present(imagePickerController, animated: true)
    }
  }
  
  private func saveProfilePicture(_ image: UIImage) {
    // Create a unique file name for the profile picture
    let fileName = "profile_picture_\(Date().timeIntervalSince1970).jpg"
    
    // Get the documents directory
    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let fileURL = documentsDirectory.appendingPathComponent(fileName)
    
    // Convert image to JPEG data and save
    if let imageData = image.jpegData(compressionQuality: 0.8) {
      do {
        try imageData.write(to: fileURL)
        
        // Remove the old profile picture if it exists
        if let oldPath = appDelegate.storage.settings.profilePicturePath {
          try? FileManager.default.removeItem(atPath: oldPath)
        }
        
        // Save the new path
        appDelegate.storage.settings.profilePicturePath = fileURL.path
        
        // Update the UI
        updateProfilePicture()
      } catch {
        print("Error saving profile picture: \(error)")
      }
    }
  }
  
  private func removeProfilePicture() {
    if let profilePicturePath = appDelegate.storage.settings.profilePicturePath {
      // Remove the file
      try? FileManager.default.removeItem(atPath: profilePicturePath)
      
      // Clear the path
      appDelegate.storage.settings.profilePicturePath = nil
      
      // Update UI with placeholder
      profileImageView.image = UIImage(systemName: "person.crop.circle.fill")
      profileImageView.tintColor = .systemGray2
    }
  }

  override func configureSearchController(
    placeholder: String?,
    scopeButtonTitles: [String]? = nil,
    showSearchBarAtEnter: Bool = false
  ) {
    // Call the superclass implementation first
    super.configureSearchController(
      placeholder: placeholder,
      scopeButtonTitles: scopeButtonTitles,
      showSearchBarAtEnter: showSearchBarAtEnter
    )
    
    // Re-add the profile button after search controller is configured
    if profileImageButton != nil {
      // Create a UIBarButtonItem with the profile button
      let profileButtonItem = UIBarButtonItem(customView: profileImageButton)
      
      #if !targetEnvironment(macCatalyst)
        // Set the profile button as the right bar button item
        navigationItem.rightBarButtonItem = profileButtonItem
      #endif
    }
  }
}

// MARK: - UIImagePickerControllerDelegate
extension RadiosVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
    picker.dismiss(animated: true) {
      if let editedImage = info[.editedImage] as? UIImage {
        self.saveProfilePicture(editedImage)
      } else if let originalImage = info[.originalImage] as? UIImage {
        self.saveProfilePicture(originalImage)
      }
    }
  }
  
  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    picker.dismiss(animated: true)
  }
}

// MARK: - PHPickerViewControllerDelegate
@available(iOS 14, *)
extension RadiosVC: PHPickerViewControllerDelegate {
  func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
    picker.dismiss(animated: true)
    
    guard let result = results.first else { return }
    
    result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] reading, error in
      if let error = error {
        print("Error loading image: \(error)")
        return
      }
      
      if let image = reading as? UIImage {
        DispatchQueue.main.async {
          self?.saveProfilePicture(image)
        }
      }
    }
  }
}
