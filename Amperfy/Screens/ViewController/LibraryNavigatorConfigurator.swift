//
//  LibraryItemConfigurator.swift
//  Amperfy
//
//  Created by Maximilian Bauer on 28.02.24.
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
import UIKit
import CoreData
import SwiftUI
import PhotosUI

// Make appDelegate property MainActor-isolated
@MainActor
private var appDelegate: AppDelegate {
  return UIApplication.shared.delegate as! AppDelegate
}

// MARK: - LibraryNavigatorItem

final class LibraryNavigatorItem: Hashable, Sendable {
  let id = UUID()
  let title: String
  let library: LibraryDisplayType?
  @MainActor
  var isSelected = false
  let isInteractable: Bool
  let tab: TabNavigatorItem?

  init(
    title: String,
    library: LibraryDisplayType? = nil,
    isSelected: Bool = false,
    isInteractable: Bool = true,
    tab: TabNavigatorItem? = nil
  ) {
    self.title = title
    self.library = library
    self.isSelected = isSelected
    self.isInteractable = isInteractable
    self.tab = tab
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }

  static func == (
    lhs: LibraryNavigatorItem,
    rhs: LibraryNavigatorItem
  )
    -> Bool {
    lhs.id == rhs.id
  }
}

// MARK: - TabNavigatorItem

enum TabNavigatorItem: Int, Hashable, CaseIterable {
  case search
  case settings
  case radio
  case new

  var title: String {
    switch self {
    case .search: return "Search"
    case .settings: return "Settings"
    case .radio: return "Radio"
    case .new: return "New"
    }
  }

  @MainActor
  var icon: UIImage {
    switch self {
    case .search: return .search
    case .settings: return .settings
    case .new: return UIImage(systemName: "square.grid.2x2.fill") ?? UIImage()
    case .radio: return UIImage(systemName: "dot.radiowaves.left.and.right") ?? UIImage()
    }
  }

  @MainActor
  var controller: UIViewController {
    switch self {
    case .search: return SearchVC.instantiateFromAppStoryboard()
    case .settings: return SettingsHostVC.instantiateFromAppStoryboard()
    case .radio: 
      // Create RadioVC using custom subclass
      let radioVC = RadioViewController()
      radioVC.title = "Radio"
      radioVC.view.backgroundColor = .systemBackground
      
      // Set the tabBarItem directly to ensure consistent icons
      let radioIcon = UIImage(systemName: "dot.radiowaves.left.and.right") ?? UIImage()
      let radioSelectedIcon = UIImage(systemName: "dot.radiowaves.left.and.right.fill") ?? UIImage()
      
      radioVC.tabBarItem = UITabBarItem(
        title: self.title,
        image: radioIcon,
        tag: self.rawValue
      )
      radioVC.tabBarItem.selectedImage = radioSelectedIcon
      
      // Create a scroll view to hold all content
      let scrollView = UIScrollView()
      scrollView.translatesAutoresizingMaskIntoConstraints = false
      scrollView.showsVerticalScrollIndicator = true
      scrollView.alwaysBounceVertical = true
      scrollView.contentInsetAdjustmentBehavior = .always
      radioVC.view.addSubview(scrollView)
      
      // Create a stack view for the content
      let stackView = UIStackView()
      stackView.axis = .vertical
      stackView.spacing = 20
      stackView.translatesAutoresizingMaskIntoConstraints = false
      scrollView.addSubview(stackView)
      
      // Setup scroll view and stack view constraints
      NSLayoutConstraint.activate([
        scrollView.topAnchor.constraint(equalTo: radioVC.view.safeAreaLayoutGuide.topAnchor),
        scrollView.leadingAnchor.constraint(equalTo: radioVC.view.leadingAnchor),
        scrollView.trailingAnchor.constraint(equalTo: radioVC.view.trailingAnchor),
        scrollView.bottomAnchor.constraint(equalTo: radioVC.view.bottomAnchor),
        
        stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
        stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
        stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
        stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
        stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
      ])
      
      // Page Title
      let titleLabel = UILabel()
      titleLabel.text = "Radio"
      titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
      titleLabel.textAlignment = .left
      stackView.addArrangedSubview(titleLabel)
      
      // Kishore Kumar & Similar Artists Section
      let carouselHeaderView = UIView()
      carouselHeaderView.translatesAutoresizingMaskIntoConstraints = false
      stackView.addArrangedSubview(carouselHeaderView)
      
      let carouselLabel = UILabel()
      carouselLabel.text = "Play Your Favourite Artists"
      carouselLabel.font = .systemFont(ofSize: 20, weight: .bold)
      carouselLabel.translatesAutoresizingMaskIntoConstraints = false
      carouselHeaderView.addSubview(carouselLabel)
      
      NSLayoutConstraint.activate([
        carouselHeaderView.heightAnchor.constraint(equalToConstant: 30),
        carouselLabel.leadingAnchor.constraint(equalTo: carouselHeaderView.leadingAnchor),
        carouselLabel.centerYAnchor.constraint(equalTo: carouselHeaderView.centerYAnchor)
      ])
      
      // Create a horizontal scroll view for the carousel with physics-based momentum
      let carouselScrollView = UIScrollView()
      carouselScrollView.showsHorizontalScrollIndicator = true
      carouselScrollView.translatesAutoresizingMaskIntoConstraints = false
      carouselScrollView.alwaysBounceHorizontal = true
      carouselScrollView.clipsToBounds = true
      carouselScrollView.decelerationRate = .fast // Physics-based deceleration
      stackView.addArrangedSubview(carouselScrollView)
      
      // Set fixed height for carousel
      carouselScrollView.heightAnchor.constraint(equalToConstant: 320).isActive = true
      
      // Create content view for the scroll view
      let contentView = UIView()
      contentView.translatesAutoresizingMaskIntoConstraints = false
      carouselScrollView.addSubview(contentView)
      
      // Setup content view constraints
      NSLayoutConstraint.activate([
        contentView.topAnchor.constraint(equalTo: carouselScrollView.topAnchor),
        contentView.leadingAnchor.constraint(equalTo: carouselScrollView.leadingAnchor),
        contentView.trailingAnchor.constraint(equalTo: carouselScrollView.trailingAnchor),
        contentView.bottomAnchor.constraint(equalTo: carouselScrollView.bottomAnchor),
        contentView.heightAnchor.constraint(equalTo: carouselScrollView.heightAnchor)
      ])
      
      // Create a horizontal stack view to hold carousel items
      let carouselStackView = UIStackView()
      carouselStackView.axis = .horizontal
      carouselStackView.spacing = 15
      carouselStackView.alignment = .center
      carouselStackView.translatesAutoresizingMaskIntoConstraints = false
      contentView.addSubview(carouselStackView)
      
      // Setup stack view constraints
      NSLayoutConstraint.activate([
        carouselStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
        carouselStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
        carouselStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
        carouselStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
      ])
      
      // Create cards for Kishore Kumar & Similar Artists
      let artistNames = ["Suresh Sehrawat", "Kishore Kumar", "Mohammed Rafi", "Lata Mangeshkar", "Asha Bhosle", "Kumar Sanu", "Sonu Nigam", "K K", "Badshah", "Neha Kakkar", "Udit Narayan", "Shaan"]
      
      // Function to get random artwork for an artist or specific artwork for special cases
      func getArtworkForArtist(artistName: String) -> UIImage {
        let storage = appDelegate.storage
        
        // Special handling for Suresh Sehrawat - use "MegaMix Purple Disco Machine 2023-1" album artwork
        if artistName == "Suresh Sehrawat" {
          // Find the "MegaMix Purple Disco Machine 2023-1" album
          let albumFetchRequest: NSFetchRequest<AlbumMO> = AlbumMO.fetchRequest()
          albumFetchRequest.predicate = NSPredicate(
            format: "%K CONTAINS[cd] %@", 
            #keyPath(AlbumMO.name), 
            "MegaMix Purple Disco Machine 2023-1"
          )
          albumFetchRequest.fetchLimit = 1
          
          if let foundAlbums = try? storage.main.context.fetch(albumFetchRequest),
             let albumMO = foundAlbums.first {
            let album = Album(managedObject: albumMO)
            if let artwork = album.artwork?.image {
              return artwork
            }
          }
        }
        
        // Special handling for Neha Kakkar - use "This is Neha Kakkar" album artwork
        if artistName == "Neha Kakkar" {
          // Find the "This is Neha Kakkar" album
          let albumFetchRequest: NSFetchRequest<AlbumMO> = AlbumMO.fetchRequest()
          albumFetchRequest.predicate = NSPredicate(
            format: "%K CONTAINS[cd] %@", 
            #keyPath(AlbumMO.name), 
            "This is Neha Kakkar"
          )
          albumFetchRequest.fetchLimit = 1
          
          if let foundAlbums = try? storage.main.context.fetch(albumFetchRequest),
             let albumMO = foundAlbums.first {
            let album = Album(managedObject: albumMO)
            if let artwork = album.artwork?.image {
              return artwork
            }
          }
        }
        
        // Special handling for Donna Summer - use "I Remember Yesterday" album artwork
        if artistName == "Donna Summer" {
          // Find the "I Remember Yesterday" album
          let albumFetchRequest: NSFetchRequest<AlbumMO> = AlbumMO.fetchRequest()
          albumFetchRequest.predicate = NSPredicate(
            format: "%K CONTAINS[cd] %@", 
            #keyPath(AlbumMO.name), 
            "I Remember Yesterday"
          )
          albumFetchRequest.fetchLimit = 1
          
          if let foundAlbums = try? storage.main.context.fetch(albumFetchRequest),
             let albumMO = foundAlbums.first {
            let album = Album(managedObject: albumMO)
            if let artwork = album.artwork?.image {
              return artwork
            }
          }
        }
        
        // Special handling for Badshah - use "This is Badshah" album artwork
        if artistName == "Badshah" {
          // Find the "This is Badshah" album
          let albumFetchRequest: NSFetchRequest<AlbumMO> = AlbumMO.fetchRequest()
          albumFetchRequest.predicate = NSPredicate(
            format: "%K CONTAINS[cd] %@", 
            #keyPath(AlbumMO.name), 
            "This is Badshah"
          )
          albumFetchRequest.fetchLimit = 1
          
          if let foundAlbums = try? storage.main.context.fetch(albumFetchRequest),
             let albumMO = foundAlbums.first {
            let album = Album(managedObject: albumMO)
            if let artwork = album.artwork?.image {
              return artwork
            }
          }
        }
        
        // Special handling for Sonu Nigam - use "This is Sonu Nigam" album artwork
        if artistName == "Sonu Nigam" {
          // Find the "This is Sonu Nigam" album
          let albumFetchRequest: NSFetchRequest<AlbumMO> = AlbumMO.fetchRequest()
          albumFetchRequest.predicate = NSPredicate(
            format: "%K CONTAINS[cd] %@", 
            #keyPath(AlbumMO.name), 
            "This is Sonu Nigam"
          )
          albumFetchRequest.fetchLimit = 1
          
          if let foundAlbums = try? storage.main.context.fetch(albumFetchRequest),
             let albumMO = foundAlbums.first {
            let album = Album(managedObject: albumMO)
            if let artwork = album.artwork?.image {
              return artwork
            }
          }
        }
        
        // Special handling for Kumar Sanu - use "Kumar Sanu All Time Hits" album artwork
        if artistName == "Kumar Sanu" {
          // Find the "Kumar Sanu All Time Hits" album
          let albumFetchRequest: NSFetchRequest<AlbumMO> = AlbumMO.fetchRequest()
          albumFetchRequest.predicate = NSPredicate(
            format: "%K CONTAINS[cd] %@", 
            #keyPath(AlbumMO.name), 
            "Kumar Sanu All Time Hits"
          )
          albumFetchRequest.fetchLimit = 1
          
          if let foundAlbums = try? storage.main.context.fetch(albumFetchRequest),
             let albumMO = foundAlbums.first {
            let album = Album(managedObject: albumMO)
            if let artwork = album.artwork?.image {
              return artwork
            }
          }
        }
        
        // For Udit Narayan, use artwork from "Udit Narayan Radio" album
        if artistName == "Udit Narayan" {
          // Find the "Udit Narayan Radio" album
          let albumFetchRequest: NSFetchRequest<AlbumMO> = AlbumMO.fetchRequest()
          albumFetchRequest.predicate = NSPredicate(
            format: "%K CONTAINS[cd] %@", 
            #keyPath(AlbumMO.name), 
            "Udit Narayan Radio"
          )
          albumFetchRequest.fetchLimit = 1
          
          if let foundAlbums = try? storage.main.context.fetch(albumFetchRequest),
             let albumMO = foundAlbums.first {
            let album = Album(managedObject: albumMO)
            if let artwork = album.artwork?.image {
              return artwork
            }
          }
        }
        
        // For Shaan, use artwork from "This Is Shaan" album
        if artistName == "Shaan" {
          // Find the "This Is Shaan" album
          let albumFetchRequest: NSFetchRequest<AlbumMO> = AlbumMO.fetchRequest()
          albumFetchRequest.predicate = NSPredicate(
            format: "%K CONTAINS[cd] %@", 
            #keyPath(AlbumMO.name), 
            "This Is Shaan"
          )
          albumFetchRequest.fetchLimit = 1
          
          if let foundAlbums = try? storage.main.context.fetch(albumFetchRequest),
             let albumMO = foundAlbums.first {
            let album = Album(managedObject: albumMO)
            if let artwork = album.artwork?.image {
              return artwork
            }
          }
        }
        
        // For Mohammed Rafi, use artwork from "Mohammed Rafi Songs Collection" album
        if artistName == "Mohammed Rafi" {
          // Find the "Mohammed Rafi Songs Collection" album
          let albumFetchRequest: NSFetchRequest<AlbumMO> = AlbumMO.fetchRequest()
          albumFetchRequest.predicate = NSPredicate(
            format: "%K CONTAINS[cd] %@", 
            #keyPath(AlbumMO.name), 
            "Mohammed Rafi Songs Collection"
          )
          albumFetchRequest.fetchLimit = 1
          
          if let foundAlbums = try? storage.main.context.fetch(albumFetchRequest),
             let albumMO = foundAlbums.first {
            let album = Album(managedObject: albumMO)
            if let artwork = album.artwork?.image {
              return artwork
            }
          }
        }
        
        // For Lata Mangeshkar, use artwork from "Best Of Lata Mangeshkar & Kishore Kumar Duets" album
        if artistName == "Lata Mangeshkar" {
          // Find the album
          let albumFetchRequest: NSFetchRequest<AlbumMO> = AlbumMO.fetchRequest()
          albumFetchRequest.predicate = NSPredicate(
            format: "%K CONTAINS[cd] %@", 
            #keyPath(AlbumMO.name), 
            "Best Of Lata Mangeshkar & Kishore Kumar Duets"
          )
          albumFetchRequest.fetchLimit = 1
          
          if let foundAlbums = try? storage.main.context.fetch(albumFetchRequest),
             let albumMO = foundAlbums.first {
            let album = Album(managedObject: albumMO)
            if let artwork = album.artwork?.image {
              return artwork
            }
          }
        }
        
        // For Kishore Kumar, use artwork from "Golden & Timeless Old Bollywood" album
        if artistName == "Kishore Kumar" {
          // Find the album
          let albumFetchRequest: NSFetchRequest<AlbumMO> = AlbumMO.fetchRequest()
          albumFetchRequest.predicate = NSPredicate(
            format: "%K CONTAINS[cd] %@", 
            #keyPath(AlbumMO.name), 
            "Golden & Timeless Old Bollywood"
          )
          albumFetchRequest.fetchLimit = 1
          
          if let foundAlbums = try? storage.main.context.fetch(albumFetchRequest),
             let albumMO = foundAlbums.first {
            let album = Album(managedObject: albumMO)
            if let artwork = album.artwork?.image {
              return artwork
            }
          }
        }
        
        // For K K, use artwork from "Evergreen Hits of K.K" album
        if artistName == "K K" {
          // Find the album
          let albumFetchRequest: NSFetchRequest<AlbumMO> = AlbumMO.fetchRequest()
          albumFetchRequest.predicate = NSPredicate(
            format: "%K CONTAINS[cd] %@", 
            #keyPath(AlbumMO.name), 
            "Evergreen Hits of K.K"
          )
          albumFetchRequest.fetchLimit = 1
          
          if let foundAlbums = try? storage.main.context.fetch(albumFetchRequest),
             let albumMO = foundAlbums.first {
            let album = Album(managedObject: albumMO)
            if let artwork = album.artwork?.image {
              return artwork
            }
          }
        }
        
        // For Asha Bhosle, use artwork from "Asha Bhosle Dance Songs" album
        if artistName == "Asha Bhosle" {
          // Find the album
          let albumFetchRequest: NSFetchRequest<AlbumMO> = AlbumMO.fetchRequest()
          albumFetchRequest.predicate = NSPredicate(
            format: "%K CONTAINS[cd] %@", 
            #keyPath(AlbumMO.name), 
            "Asha Bhosle Dance Songs"
          )
          albumFetchRequest.fetchLimit = 1
          
          if let foundAlbums = try? storage.main.context.fetch(albumFetchRequest),
             let albumMO = foundAlbums.first {
            let album = Album(managedObject: albumMO)
            if let artwork = album.artwork?.image {
              return artwork
            }
          }
        }
        
        // Normal flow for other artists
        // Default image if no matching artist or album found
        return UIImage.getGeneratedArtwork(
          theme: appDelegate.storage.settings.themePreference,
          artworkType: .artist
        )
      }
      
      // Array to store artist images for use in cards
      var artistImages = [UIImage]()
      
      // Prepare all artist images first
      for artistName in artistNames {
        artistImages.append(getArtworkForArtist(artistName: artistName))
      }
      
      for (index, artistName) in artistNames.enumerated() {
        // Create a card container
        let cardView = UIView()
        cardView.translatesAutoresizingMaskIntoConstraints = false
        
        // Create background gradient view
        let backgroundColorView = GradientBackgroundView()
        backgroundColorView.translatesAutoresizingMaskIntoConstraints = false
        backgroundColorView.layer.cornerRadius = 12
        backgroundColorView.clipsToBounds = true
        cardView.addSubview(backgroundColorView)
        
        // Create gradient layer for background
        let gradientLayer = CAGradientLayer()
        gradientLayer.cornerRadius = 12
        
        // Define bright gradient colors based on index
        var gradientColors: [CGColor] = []
        switch index % 11 {
        case 0:
            // Purple to Pink
            gradientColors = [UIColor.systemPurple.cgColor, UIColor.systemPink.cgColor]
        case 1:
            // Blue to Cyan
            gradientColors = [UIColor.systemBlue.cgColor, UIColor.systemTeal.cgColor]
        case 2:
            // Orange to Yellow
            gradientColors = [UIColor.systemOrange.cgColor, UIColor.systemYellow.cgColor]
        case 3:
            // Red to Orange
            gradientColors = [UIColor.systemRed.cgColor, UIColor.systemOrange.cgColor]
        case 4:
            // Green to Yellow
            gradientColors = [UIColor.systemGreen.cgColor, UIColor.systemYellow.cgColor]
        case 5:
            // Indigo to Purple
            gradientColors = [UIColor.systemIndigo.cgColor, UIColor.systemPurple.cgColor]
        case 6:
            // Teal to Blue
            gradientColors = [UIColor.systemTeal.cgColor, UIColor.systemBlue.cgColor]
        case 7:
            // Pink to Red
            gradientColors = [UIColor.systemPink.cgColor, UIColor.systemRed.cgColor]
        case 8:
            // Purple to Blue
            gradientColors = [UIColor.systemPurple.cgColor, UIColor.systemBlue.cgColor]
        case 9:
            // Yellow to Green
            gradientColors = [UIColor.systemYellow.cgColor, UIColor.systemGreen.cgColor]
        case 10:
            // Red to Purple
            gradientColors = [UIColor.systemRed.cgColor, UIColor.systemPurple.cgColor]
        default:
            gradientColors = [UIColor.systemBlue.cgColor, UIColor.systemPurple.cgColor]
        }
        
        gradientLayer.colors = gradientColors
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        
        // Assign gradient to the background view and add it
        backgroundColorView.gradientLayer = gradientLayer
        backgroundColorView.layer.insertSublayer(gradientLayer, at: 0)
        
        // Add an image view
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = artistImages[index]
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white
        imageView.layer.cornerRadius = CornerRadius.appleMusic.asCGFloat
        imageView.clipsToBounds = true
        cardView.addSubview(imageView)
        
        // Add a title label
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = artistName
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        cardView.addSubview(titleLabel)
        
        // Add a subtitle label
        let subtitleLabel = UILabel()
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = "Tap to shuffle songs"
        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textColor = .white
        subtitleLabel.textAlignment = .center
        cardView.addSubview(subtitleLabel)
        
        // Setup constraints
        NSLayoutConstraint.activate([
          cardView.widthAnchor.constraint(equalToConstant: 200),
          cardView.heightAnchor.constraint(equalToConstant: 280),
          
          backgroundColorView.topAnchor.constraint(equalTo: cardView.topAnchor),
          backgroundColorView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
          backgroundColorView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
          backgroundColorView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor),
          
          imageView.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
          imageView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 30),
          imageView.widthAnchor.constraint(equalToConstant: 120),
          imageView.heightAnchor.constraint(equalToConstant: 120),
          
          titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20),
          titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 10),
          titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -10),
          
          subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
          subtitleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 10),
          subtitleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -10)
        ])
        
        // Store artist name as the view's tag - using hash value for unique identification
        cardView.tag = artistName.hashValue
        
        // Add tap gesture
        let tapGesture = UITapGestureRecognizer(target: radioVC, action: #selector(UIViewController.radioArtistCardTapped(_:)))
        cardView.addGestureRecognizer(tapGesture)
        cardView.isUserInteractionEnabled = true
        
        // Add the card to the carousel
        carouselStackView.addArrangedSubview(cardView)
      }
      
      // Calculate and set the content size for proper scrolling
      let totalWidth = CGFloat(artistNames.count * 215) // 200 width + 15 spacing
      
      // Define a custom UIView subclass for gradient backgrounds
      class GradientBackgroundView: UIView {
        var gradientLayer: CAGradientLayer!
        
        override func layoutSubviews() {
          super.layoutSubviews()
          gradientLayer.frame = bounds
        }
      }
      
      // Critical: Set the content view's width - this is key to making horizontal scrolling work
      let contentWidthConstraint = contentView.widthAnchor.constraint(equalToConstant: totalWidth)
      contentWidthConstraint.priority = .required
      contentWidthConstraint.isActive = true
      
      // Make sure content view's width can be greater than the scroll view's width
      let contentMinWidthConstraint = contentView.widthAnchor.constraint(greaterThanOrEqualTo: carouselScrollView.widthAnchor)
      contentMinWidthConstraint.priority = .defaultHigh
      contentMinWidthConstraint.isActive = true
      
      // Force layout to ensure proper sizing
      carouselScrollView.layoutIfNeeded()
      
      // Add new carousel titled "Listen To More Artists"
      // Create header view for the carousel
      let moreArtistsHeaderView = UIView()
      moreArtistsHeaderView.translatesAutoresizingMaskIntoConstraints = false
      stackView.addArrangedSubview(moreArtistsHeaderView)
      
      let moreArtistsLabel = UILabel()
      moreArtistsLabel.text = "Listen To More Artists"
      moreArtistsLabel.font = .systemFont(ofSize: 20, weight: .bold)
      moreArtistsLabel.translatesAutoresizingMaskIntoConstraints = false
      moreArtistsHeaderView.addSubview(moreArtistsLabel)
      
      NSLayoutConstraint.activate([
        moreArtistsHeaderView.heightAnchor.constraint(equalToConstant: 30),
        moreArtistsLabel.leadingAnchor.constraint(equalTo: moreArtistsHeaderView.leadingAnchor),
        moreArtistsLabel.centerYAnchor.constraint(equalTo: moreArtistsHeaderView.centerYAnchor)
      ])
      
      // Create horizontal scroll view for the carousel
      let moreArtistsScrollView = UIScrollView()
      moreArtistsScrollView.showsHorizontalScrollIndicator = true
      moreArtistsScrollView.translatesAutoresizingMaskIntoConstraints = false
      moreArtistsScrollView.alwaysBounceHorizontal = true
      moreArtistsScrollView.clipsToBounds = true
      moreArtistsScrollView.decelerationRate = .fast
      stackView.addArrangedSubview(moreArtistsScrollView)
      
      // Set fixed height for carousel
      moreArtistsScrollView.heightAnchor.constraint(equalToConstant: 320).isActive = true
      
      // Create content view for the scroll view
      let moreArtistsContentView = UIView()
      moreArtistsContentView.translatesAutoresizingMaskIntoConstraints = false
      moreArtistsScrollView.addSubview(moreArtistsContentView)
      
      // Setup content view constraints
      NSLayoutConstraint.activate([
        moreArtistsContentView.topAnchor.constraint(equalTo: moreArtistsScrollView.topAnchor),
        moreArtistsContentView.leadingAnchor.constraint(equalTo: moreArtistsScrollView.leadingAnchor),
        moreArtistsContentView.trailingAnchor.constraint(equalTo: moreArtistsScrollView.trailingAnchor),
        moreArtistsContentView.bottomAnchor.constraint(equalTo: moreArtistsScrollView.bottomAnchor),
        moreArtistsContentView.heightAnchor.constraint(equalTo: moreArtistsScrollView.heightAnchor)
      ])
      
      // Create horizontal stack view for carousel items
      let moreArtistsStackView = UIStackView()
      moreArtistsStackView.axis = .horizontal
      moreArtistsStackView.spacing = 15
      moreArtistsStackView.alignment = .center
      moreArtistsStackView.translatesAutoresizingMaskIntoConstraints = false
      moreArtistsContentView.addSubview(moreArtistsStackView)
      
      // Setup stack view constraints
      NSLayoutConstraint.activate([
        moreArtistsStackView.topAnchor.constraint(equalTo: moreArtistsContentView.topAnchor, constant: 10),
        moreArtistsStackView.leadingAnchor.constraint(equalTo: moreArtistsContentView.leadingAnchor, constant: 10),
        moreArtistsStackView.trailingAnchor.constraint(equalTo: moreArtistsContentView.trailingAnchor, constant: -10),
        moreArtistsStackView.bottomAnchor.constraint(equalTo: moreArtistsContentView.bottomAnchor, constant: -10)
      ])
      
      // Create cards for Cerrone and Purple Disco Machine
      let moreArtistNames = ["Donna Summer", "Sade", "Phil Collins", "Pet Shop Boys", "Artbat", "Andy Bros", "Blondie", "Boney M", "Cerrone", "Purple Disco"]
      var moreArtistImages = [UIImage]()
      
      // Define a collection of bright gradient pairs
      let gradientPairs: [[CGColor]] = [
        [UIColor(red: 1.0, green: 0.4, blue: 0.8, alpha: 1.0).cgColor, UIColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 1.0).cgColor], // Pink to Blue
        [UIColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0).cgColor, UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0).cgColor], // Red to Yellow
        [UIColor(red: 0.0, green: 0.8, blue: 0.8, alpha: 1.0).cgColor, UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0).cgColor], // Cyan to Blue
        [UIColor(red: 0.5, green: 0.8, blue: 0.0, alpha: 1.0).cgColor, UIColor(red: 0.2, green: 0.4, blue: 1.0, alpha: 1.0).cgColor], // Green to Blue
        [UIColor(red: 1.0, green: 0.4, blue: 0.0, alpha: 1.0).cgColor, UIColor(red: 1.0, green: 0.8, blue: 0.4, alpha: 1.0).cgColor], // Orange to Yellow
        [UIColor(red: 0.8, green: 0.0, blue: 1.0, alpha: 1.0).cgColor, UIColor(red: 0.4, green: 0.2, blue: 1.0, alpha: 1.0).cgColor], // Purple to Indigo
        [UIColor(red: 0.0, green: 0.7, blue: 0.4, alpha: 1.0).cgColor, UIColor(red: 0.4, green: 0.8, blue: 0.8, alpha: 1.0).cgColor]  // Green to Teal
      ]
      
      // Prepare artist images
      for artistName in moreArtistNames {
        // Use the same function we use for the other carousel to get consistent artwork
        let image = getArtworkForArtist(artistName: artistName)
        moreArtistImages.append(image)
      }
      
      // Create the artist cards
      for (index, artistName) in moreArtistNames.enumerated() {
        // Create card container
        let cardView = UIView()
        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.layer.cornerRadius = CornerRadius.appleMusic.asCGFloat
        cardView.clipsToBounds = true
        
        // Create background view with gradient
        let backgroundColorView = GradientBackgroundView()
        backgroundColorView.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(backgroundColorView)
        
        // Setup gradient layer with a unique color pair for each card
        let gradientLayer = CAGradientLayer()
        // Use modulo to ensure we don't go out of bounds if we have more artists than gradient pairs
        let colorPairIndex = index % gradientPairs.count
        let gradientColors = gradientPairs[colorPairIndex]
        gradientLayer.colors = gradientColors
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        
        // Assign gradient to the background view and add it
        backgroundColorView.gradientLayer = gradientLayer
        backgroundColorView.layer.insertSublayer(gradientLayer, at: 0)
        
        // Add an image view
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill // Use fill instead of fit for album artwork
        imageView.tintColor = .white
        imageView.layer.cornerRadius = 10 // More pronounced rounded corners for album artwork
        imageView.clipsToBounds = true
        cardView.addSubview(imageView)
        
        let storage = appDelegate.storage
        var foundArtwork = false
        
        // Special handling for Donna Summer - always use "I Remember Yesterday" album artwork
        if artistName == "Donna Summer" {
          let albumFetchRequest: NSFetchRequest<AlbumMO> = AlbumMO.fetchRequest()
          albumFetchRequest.predicate = NSPredicate(
            format: "%K CONTAINS[cd] %@", 
            #keyPath(AlbumMO.name), 
            "I Remember Yesterday"
          )
          albumFetchRequest.fetchLimit = 1
          
          if let foundAlbums = try? storage.main.context.fetch(albumFetchRequest),
             let albumMO = foundAlbums.first {
            let album = Album(managedObject: albumMO)
            if let artwork = album.artwork?.image {
              imageView.image = artwork
              foundArtwork = true
            }
          }
        }
        
        // Special handling for Sade - always use "The Best Of Sade" album artwork
        else if artistName == "Sade" {
          let albumFetchRequest: NSFetchRequest<AlbumMO> = AlbumMO.fetchRequest()
          albumFetchRequest.predicate = NSPredicate(
            format: "%K CONTAINS[cd] %@", 
            #keyPath(AlbumMO.name), 
            "The Best Of Sade"
          )
          albumFetchRequest.fetchLimit = 1
          
          if let foundAlbums = try? storage.main.context.fetch(albumFetchRequest),
             let albumMO = foundAlbums.first {
            let album = Album(managedObject: albumMO)
            if let artwork = album.artwork?.image {
              imageView.image = artwork
              foundArtwork = true
            }
          }
        }
        
        // Special handling for Pet Shop Boys - always use "Nonetheless" album artwork
        else if artistName == "Pet Shop Boys" {
          let albumFetchRequest: NSFetchRequest<AlbumMO> = AlbumMO.fetchRequest()
          albumFetchRequest.predicate = NSPredicate(
            format: "%K CONTAINS[cd] %@", 
            #keyPath(AlbumMO.name), 
            "Nonetheless"
          )
          albumFetchRequest.fetchLimit = 1
          
          if let foundAlbums = try? storage.main.context.fetch(albumFetchRequest),
             let albumMO = foundAlbums.first {
            let album = Album(managedObject: albumMO)
            if let artwork = album.artwork?.image {
              imageView.image = artwork
              foundArtwork = true
            }
          }
        }
        
        // Special handling for Artbat - always use "This Is ARTBAT" album artwork
        else if artistName == "Artbat" {
          let albumFetchRequest: NSFetchRequest<AlbumMO> = AlbumMO.fetchRequest()
          albumFetchRequest.predicate = NSPredicate(
            format: "%K CONTAINS[cd] %@", 
            #keyPath(AlbumMO.name), 
            "This Is ARTBAT"
          )
          albumFetchRequest.fetchLimit = 1
          
          if let foundAlbums = try? storage.main.context.fetch(albumFetchRequest),
             let albumMO = foundAlbums.first {
            let album = Album(managedObject: albumMO)
            if let artwork = album.artwork?.image {
              imageView.image = artwork
              foundArtwork = true
            }
          }
        }
        
        // Special handling for Blondie - always use "Eat to the Beat" album artwork
        else if artistName == "Blondie" {
          let albumFetchRequest: NSFetchRequest<AlbumMO> = AlbumMO.fetchRequest()
          albumFetchRequest.predicate = NSPredicate(
            format: "%K CONTAINS[cd] %@", 
            #keyPath(AlbumMO.name), 
            "Eat to the Beat"
          )
          albumFetchRequest.fetchLimit = 1
          
          if let foundAlbums = try? storage.main.context.fetch(albumFetchRequest),
             let albumMO = foundAlbums.first {
            let album = Album(managedObject: albumMO)
            if let artwork = album.artwork?.image {
              imageView.image = artwork
              foundArtwork = true
            }
          }
        }
        
        // Try to find album artwork for this artist
        if !foundArtwork {
          let artists = storage.main.library.getArtists().filter { 
            $0.name.lowercased().contains(artistName.lowercased())
          }
          
          // Look for albums by this artist and use the first one with artwork
          if !artists.isEmpty {
            for artist in artists {
              let albums = storage.main.library.getAlbums(whichContainsSongsWithArtist: artist)
              for album in albums {
                if let artwork = album.artwork?.image {
                  imageView.image = artwork
                  foundArtwork = true
                  break
                }
              }
              if foundArtwork { break }
            }
          }
        }
        
        // Special handling for other artists to ensure we have good artwork
        if !foundArtwork {
          // Try searching for specific album names for certain artists
          let albumFetchRequest: NSFetchRequest<AlbumMO> = AlbumMO.fetchRequest()
          
          if artistName == "Phil Collins" {
            albumFetchRequest.predicate = NSPredicate(
              format: "%K CONTAINS[cd] %@ OR %K CONTAINS[cd] %@ OR %K CONTAINS[cd] %@", 
              #keyPath(AlbumMO.name), "Hits",
              #keyPath(AlbumMO.name), "Essential",
              #keyPath(AlbumMO.name), "Greatest"
            )
          } else if artistName == "Andy Bros" {
            albumFetchRequest.predicate = NSPredicate(
              format: "%K CONTAINS[cd] %@", 
              #keyPath(AlbumMO.name), "Andy Bros"
            )
          } else if artistName == "Blondie" {
            albumFetchRequest.predicate = NSPredicate(
              format: "%K CONTAINS[cd] %@", 
              #keyPath(AlbumMO.name), 
              "Eat to the Beat"
            )
          } else if artistName == "Donna Summer" {
            albumFetchRequest.predicate = NSPredicate(
              format: "%K CONTAINS[cd] %@", 
              #keyPath(AlbumMO.name), 
              "I Remember Yesterday"
            )
          } else if artistName == "Sade" {
            albumFetchRequest.predicate = NSPredicate(
              format: "%K CONTAINS[cd] %@", 
              #keyPath(AlbumMO.name), 
              "The Best Of Sade"
            )
          } else {
            // For other artists, try a general search using their name
            albumFetchRequest.predicate = NSPredicate(
              format: "%K CONTAINS[cd] %@", 
              #keyPath(AlbumMO.name), artistName
            )
          }
          
          albumFetchRequest.fetchLimit = 1
          
          if let foundAlbums = try? storage.main.context.fetch(albumFetchRequest),
             let albumMO = foundAlbums.first {
            let album = Album(managedObject: albumMO)
            if let artwork = album.artwork?.image {
              imageView.image = artwork
              foundArtwork = true
            }
          }
        }
        
        // If no artwork found, use a placeholder
        if !foundArtwork {
          imageView.image = UIImage(systemName: "music.note")
          imageView.backgroundColor = UIColor.systemGray3
        }
        
        // Add a title label
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = artistName
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        cardView.addSubview(titleLabel)
        
        // Add a subtitle label
        let subtitleLabel = UILabel()
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = "Tap to shuffle songs"
        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textColor = .white
        subtitleLabel.textAlignment = .center
        cardView.addSubview(subtitleLabel)
        
        // Setup constraints
        NSLayoutConstraint.activate([
          cardView.widthAnchor.constraint(equalToConstant: 200),
          cardView.heightAnchor.constraint(equalToConstant: 280),
          
          backgroundColorView.topAnchor.constraint(equalTo: cardView.topAnchor),
          backgroundColorView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
          backgroundColorView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
          backgroundColorView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor),
          
          imageView.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
          imageView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 30),
          imageView.widthAnchor.constraint(equalToConstant: 120),
          imageView.heightAnchor.constraint(equalToConstant: 120),
          
          titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20),
          titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 10),
          titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -10),
          
          subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
          subtitleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 10),
          subtitleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -10)
        ])
        
        // Store artist name as the view's tag - using hash value for unique identification
        cardView.tag = artistName.hashValue
        
        // Add tap gesture
        let tapGesture = UITapGestureRecognizer(target: radioVC, action: #selector(UIViewController.moreArtistsCardTapped(_:)))
        cardView.addGestureRecognizer(tapGesture)
        cardView.isUserInteractionEnabled = true
        
        // Add the card to the carousel
        moreArtistsStackView.addArrangedSubview(cardView)
      }
      
      // Calculate and set the content size for proper scrolling
      let moreArtistsTotalWidth = CGFloat(moreArtistNames.count * 215) // 200 width + 15 spacing
      
      // Set the content view's width constraint
      let moreArtistsWidthConstraint = moreArtistsContentView.widthAnchor.constraint(equalToConstant: moreArtistsTotalWidth)
      moreArtistsWidthConstraint.priority = .required
      moreArtistsWidthConstraint.isActive = true
      
      // Make sure content view's width can be greater than the scroll view's width
      let moreArtistsMinWidthConstraint = moreArtistsContentView.widthAnchor.constraint(greaterThanOrEqualTo: moreArtistsScrollView.widthAnchor)
      moreArtistsMinWidthConstraint.priority = .defaultHigh
      moreArtistsMinWidthConstraint.isActive = true
      
      // Force layout to ensure proper sizing
      moreArtistsScrollView.layoutIfNeeded()
      
      // Add new carousel titled "Browse by Decade"
      // Create header view for the carousel
      let decadesHeaderView = UIView()
      decadesHeaderView.translatesAutoresizingMaskIntoConstraints = false
      stackView.addArrangedSubview(decadesHeaderView)
      
      let decadesLabel = UILabel()
      decadesLabel.text = "Browse by Decade"
      decadesLabel.font = .systemFont(ofSize: 20, weight: .bold)
      decadesLabel.translatesAutoresizingMaskIntoConstraints = false
      decadesHeaderView.addSubview(decadesLabel)
      
      NSLayoutConstraint.activate([
        decadesHeaderView.heightAnchor.constraint(equalToConstant: 30),
        decadesLabel.leadingAnchor.constraint(equalTo: decadesHeaderView.leadingAnchor),
        decadesLabel.centerYAnchor.constraint(equalTo: decadesHeaderView.centerYAnchor)
      ])
      
      // Create horizontal scroll view for the carousel
      let decadesScrollView = UIScrollView()
      decadesScrollView.showsHorizontalScrollIndicator = true
      decadesScrollView.translatesAutoresizingMaskIntoConstraints = false
      decadesScrollView.alwaysBounceHorizontal = true
      decadesScrollView.clipsToBounds = true
      decadesScrollView.decelerationRate = .fast // Physics-based momentum scrolling
      stackView.addArrangedSubview(decadesScrollView)
      
      // Set fixed height for carousel
      decadesScrollView.heightAnchor.constraint(equalToConstant: 320).isActive = true
      
      // Create content view for the scroll view
      let decadesContentView = UIView()
      decadesContentView.translatesAutoresizingMaskIntoConstraints = false
      decadesScrollView.addSubview(decadesContentView)
      
      // Setup content view constraints
      NSLayoutConstraint.activate([
        decadesContentView.topAnchor.constraint(equalTo: decadesScrollView.topAnchor),
        decadesContentView.leadingAnchor.constraint(equalTo: decadesScrollView.leadingAnchor),
        decadesContentView.trailingAnchor.constraint(equalTo: decadesScrollView.trailingAnchor),
        decadesContentView.bottomAnchor.constraint(equalTo: decadesScrollView.bottomAnchor),
        decadesContentView.heightAnchor.constraint(equalTo: decadesScrollView.heightAnchor)
      ])
      
      // Create horizontal stack view for carousel items
      let decadesStackView = UIStackView()
      decadesStackView.axis = .horizontal
      decadesStackView.spacing = 15
      decadesStackView.alignment = .center
      decadesStackView.translatesAutoresizingMaskIntoConstraints = false
      decadesContentView.addSubview(decadesStackView)
      
      // Setup stack view constraints
      NSLayoutConstraint.activate([
        decadesStackView.topAnchor.constraint(equalTo: decadesContentView.topAnchor, constant: 10),
        decadesStackView.leadingAnchor.constraint(equalTo: decadesContentView.leadingAnchor, constant: 10),
        decadesStackView.trailingAnchor.constraint(equalTo: decadesContentView.trailingAnchor, constant: -10),
        decadesStackView.bottomAnchor.constraint(equalTo: decadesContentView.bottomAnchor, constant: -10)
      ])
      
      // Create cards for 1960s and 1970s decades
      let decadeNames = ["1960", "1970", "1980", "1990", "2000", "2010", "2020", "2025"]
      
      // Define gradient colors for decade cards
      let decadeGradients: [[CGColor]] = [
        [UIColor(red: 0.8, green: 0.4, blue: 0.2, alpha: 1.0).cgColor, UIColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 1.0).cgColor], // 60s - Orange/Red gradient
        [UIColor(red: 0.6, green: 0.0, blue: 0.8, alpha: 1.0).cgColor, UIColor(red: 0.4, green: 0.2, blue: 0.8, alpha: 1.0).cgColor], // 70s - Purple gradient
        [UIColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0).cgColor, UIColor(red: 0.0, green: 0.6, blue: 1.0, alpha: 1.0).cgColor], // 80s - Blue gradient
        [UIColor(red: 0.0, green: 0.8, blue: 0.4, alpha: 1.0).cgColor, UIColor(red: 0.2, green: 1.0, blue: 0.6, alpha: 1.0).cgColor], // 90s - Green gradient
        [UIColor(red: 0.8, green: 0.0, blue: 0.4, alpha: 1.0).cgColor, UIColor(red: 1.0, green: 0.2, blue: 0.6, alpha: 1.0).cgColor], // 2000s - Pink gradient
        [UIColor(red: 0.8, green: 0.8, blue: 0.0, alpha: 1.0).cgColor, UIColor(red: 1.0, green: 1.0, blue: 0.2, alpha: 1.0).cgColor], // 2010s - Yellow gradient
        [UIColor(red: 0.0, green: 0.6, blue: 0.6, alpha: 1.0).cgColor, UIColor(red: 0.2, green: 0.8, blue: 0.8, alpha: 1.0).cgColor], // 2020s - Teal gradient
        [UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0).cgColor, UIColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 1.0).cgColor]  // 2025 - Gray gradient
      ]
      
      // Create the decade cards
      for (index, decadeName) in decadeNames.enumerated() {
        // Create card container
        let cardView = UIView()
        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.layer.cornerRadius = CornerRadius.appleMusic.asCGFloat
        cardView.clipsToBounds = true
        
        // Create background view with gradient
        let backgroundColorView = GradientBackgroundView()
        backgroundColorView.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(backgroundColorView)
        
        // Setup gradient layer with a unique color pair for each card
        let gradientLayer = CAGradientLayer()
        let gradientColors = decadeGradients[index]
        gradientLayer.colors = gradientColors
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        
        // Assign gradient to the background view and add it
        backgroundColorView.gradientLayer = gradientLayer
        backgroundColorView.layer.insertSublayer(gradientLayer, at: 0)
        
        // Add album artwork view with default icon first
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.image = UIImage(systemName: "music.note.list")
        imageView.tintColor = .white
        cardView.addSubview(imageView)
        
        // Add decade label (large and prominent)
        let decadeNumberLabel = UILabel()
        decadeNumberLabel.translatesAutoresizingMaskIntoConstraints = false
        decadeNumberLabel.text = decadeName + "s"
        decadeNumberLabel.font = .systemFont(ofSize: 48, weight: .bold)
        decadeNumberLabel.textColor = .white
        decadeNumberLabel.textAlignment = .center
        cardView.addSubview(decadeNumberLabel)
        
        // Add a subtitle label
        let subtitleLabel = UILabel()
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = "Tap to shuffle songs"
        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textColor = .white
        subtitleLabel.textAlignment = .center
        cardView.addSubview(subtitleLabel)
        
        // Setup constraints
        NSLayoutConstraint.activate([
          cardView.widthAnchor.constraint(equalToConstant: 200),
          cardView.heightAnchor.constraint(equalToConstant: 280),
          
          backgroundColorView.topAnchor.constraint(equalTo: cardView.topAnchor),
          backgroundColorView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
          backgroundColorView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
          backgroundColorView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor),
          
          imageView.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
          imageView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 40),
          imageView.widthAnchor.constraint(equalToConstant: 120),
          imageView.heightAnchor.constraint(equalToConstant: 120),
          
          decadeNumberLabel.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
          decadeNumberLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20),
          decadeNumberLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 10),
          decadeNumberLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -10),
          
          subtitleLabel.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
          subtitleLabel.topAnchor.constraint(equalTo: decadeNumberLabel.bottomAnchor, constant: 20),
          subtitleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 10),
          subtitleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -10)
        ])
        
        // Store decade name as the view's tag using hash value
        cardView.tag = decadeName.hashValue
        
        // Add tap gesture
        let tapGesture = UITapGestureRecognizer(target: radioVC, action: #selector(UIViewController.decadeCardTapped(_:)))
        cardView.addGestureRecognizer(tapGesture)
        cardView.isUserInteractionEnabled = true
        
        // Add the card to the carousel
        decadesStackView.addArrangedSubview(cardView)
        
        // Try to load a random album artwork from the decade
        Task {
          // Find albums from this decade
          let allAlbums = appDelegate.storage.main.library.getAlbums()
          var decadeAlbums = [Album]()
          
          let decadeStartYear = Int(decadeName) ?? 0
          let decadeEndYear = decadeStartYear + 9
          
          for album in allAlbums {
            if album.year >= decadeStartYear && album.year <= decadeEndYear {
              decadeAlbums.append(album)
            }
          }
          
          // If we found albums from this decade, pick a random one and get its artwork
          if !decadeAlbums.isEmpty {
            let randomIndex = Int.random(in: 0..<decadeAlbums.count)
            let randomAlbum = decadeAlbums[randomIndex]
            
            // Get and set artwork for the album
            if let artwork = randomAlbum.artwork?.image {
              // Update UI on main thread
              await MainActor.run {
                imageView.image = artwork
                imageView.contentMode = .scaleAspectFill
              }
            }
          }
        }
      }
      
      // Calculate and set the content size for proper scrolling
      let decadesTotalWidth = CGFloat(decadeNames.count * 215) // 200 width + 15 spacing
      
      // Set the content view's width constraint
      let decadesWidthConstraint = decadesContentView.widthAnchor.constraint(equalToConstant: decadesTotalWidth)
      decadesWidthConstraint.priority = .required
      decadesWidthConstraint.isActive = true
      
      // Make sure content view's width can be greater than the scroll view's width
      let decadesMinWidthConstraint = decadesContentView.widthAnchor.constraint(greaterThanOrEqualTo: decadesScrollView.widthAnchor)
      decadesMinWidthConstraint.priority = .defaultHigh
      decadesMinWidthConstraint.isActive = true
      
      // Force layout to ensure proper sizing
      decadesScrollView.layoutIfNeeded()
      
      // Add new carousel titled "Play By Genre"
      // Create header view for the carousel
      let genresHeaderView = UIView()
      genresHeaderView.translatesAutoresizingMaskIntoConstraints = false
      stackView.addArrangedSubview(genresHeaderView)
      
      let genresLabel = UILabel()
      genresLabel.text = "Play By Genre"
      genresLabel.font = .systemFont(ofSize: 20, weight: .bold)
      genresLabel.translatesAutoresizingMaskIntoConstraints = false
      genresHeaderView.addSubview(genresLabel)
      
      NSLayoutConstraint.activate([
        genresHeaderView.heightAnchor.constraint(equalToConstant: 30),
        genresLabel.leadingAnchor.constraint(equalTo: genresHeaderView.leadingAnchor),
        genresLabel.centerYAnchor.constraint(equalTo: genresHeaderView.centerYAnchor)
      ])
      
      // Create horizontal scroll view for the carousel
      let genresScrollView = UIScrollView()
      genresScrollView.showsHorizontalScrollIndicator = true
      genresScrollView.translatesAutoresizingMaskIntoConstraints = false
      genresScrollView.alwaysBounceHorizontal = true
      genresScrollView.clipsToBounds = true
      genresScrollView.decelerationRate = .fast // Physics-based momentum scrolling
      stackView.addArrangedSubview(genresScrollView)
      
      // Set fixed height for carousel
      genresScrollView.heightAnchor.constraint(equalToConstant: 320).isActive = true
      
      // Create content view for the scroll view
      let genresContentView = UIView()
      genresContentView.translatesAutoresizingMaskIntoConstraints = false
      genresScrollView.addSubview(genresContentView)
      
      // Setup content view constraints
      NSLayoutConstraint.activate([
        genresContentView.topAnchor.constraint(equalTo: genresScrollView.topAnchor),
        genresContentView.leadingAnchor.constraint(equalTo: genresScrollView.leadingAnchor),
        genresContentView.trailingAnchor.constraint(equalTo: genresScrollView.trailingAnchor),
        genresContentView.bottomAnchor.constraint(equalTo: genresScrollView.bottomAnchor),
        genresContentView.heightAnchor.constraint(equalTo: genresScrollView.heightAnchor)
      ])
      
      // Create horizontal stack view for carousel items
      let genresStackView = UIStackView()
      genresStackView.axis = .horizontal
      genresStackView.spacing = 15
      genresStackView.alignment = .center
      genresStackView.translatesAutoresizingMaskIntoConstraints = false
      genresContentView.addSubview(genresStackView)
      
      // Setup stack view constraints
      NSLayoutConstraint.activate([
        genresStackView.topAnchor.constraint(equalTo: genresContentView.topAnchor, constant: 10),
        genresStackView.leadingAnchor.constraint(equalTo: genresContentView.leadingAnchor, constant: 10),
        genresStackView.trailingAnchor.constraint(equalTo: genresContentView.trailingAnchor, constant: -10),
        genresStackView.bottomAnchor.constraint(equalTo: genresContentView.bottomAnchor, constant: -10)
      ])
      
      // Create Disco genre card
      let discoCardView = UIView()
      discoCardView.translatesAutoresizingMaskIntoConstraints = false
      discoCardView.layer.cornerRadius = CornerRadius.appleMusic.asCGFloat
      discoCardView.clipsToBounds = true
      
      // Create background view with gradient
      let discoBackgroundView = GradientBackgroundView()
      discoBackgroundView.translatesAutoresizingMaskIntoConstraints = false
      discoCardView.addSubview(discoBackgroundView)
      
      // Setup gradient layer with disco-themed colors
      let discoGradientLayer = CAGradientLayer()
      discoGradientLayer.colors = [
        UIColor(red: 0.8, green: 0.2, blue: 0.6, alpha: 1.0).cgColor, // Pink
        UIColor(red: 0.4, green: 0.0, blue: 0.8, alpha: 1.0).cgColor  // Purple
      ]
      discoGradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
      discoGradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
      
      // Assign gradient to the background view and add it
      discoBackgroundView.gradientLayer = discoGradientLayer
      discoBackgroundView.layer.insertSublayer(discoGradientLayer, at: 0)
      
      // Add album artwork view with default icon first
      let discoImageView = UIImageView()
      discoImageView.translatesAutoresizingMaskIntoConstraints = false
      discoImageView.contentMode = .scaleAspectFit
      discoImageView.clipsToBounds = true
      discoImageView.layer.cornerRadius = 8
      discoImageView.image = UIImage(systemName: "music.note.list")
      discoImageView.tintColor = .white
      discoCardView.addSubview(discoImageView)
      
      // Add title label
      let discoTitleLabel = UILabel()
      discoTitleLabel.translatesAutoresizingMaskIntoConstraints = false
      discoTitleLabel.text = "Disco"
      discoTitleLabel.font = .systemFont(ofSize: 32, weight: .bold)
      discoTitleLabel.textColor = .white
      discoTitleLabel.textAlignment = .center
      discoCardView.addSubview(discoTitleLabel)
      
      // Add subtitle label
      let discoSubtitleLabel = UILabel()
      discoSubtitleLabel.translatesAutoresizingMaskIntoConstraints = false
      discoSubtitleLabel.text = "Tap to shuffle songs"
      discoSubtitleLabel.font = .systemFont(ofSize: 14)
      discoSubtitleLabel.textColor = .white
      discoSubtitleLabel.textAlignment = .center
      discoCardView.addSubview(discoSubtitleLabel)
      
      // Setup constraints for disco card
      NSLayoutConstraint.activate([
        discoCardView.widthAnchor.constraint(equalToConstant: 200),
        discoCardView.heightAnchor.constraint(equalToConstant: 280),
        
        discoBackgroundView.topAnchor.constraint(equalTo: discoCardView.topAnchor),
        discoBackgroundView.leadingAnchor.constraint(equalTo: discoCardView.leadingAnchor),
        discoBackgroundView.trailingAnchor.constraint(equalTo: discoCardView.trailingAnchor),
        discoBackgroundView.bottomAnchor.constraint(equalTo: discoCardView.bottomAnchor),
        
        discoImageView.centerXAnchor.constraint(equalTo: discoCardView.centerXAnchor),
        discoImageView.topAnchor.constraint(equalTo: discoCardView.topAnchor, constant: 40),
        discoImageView.widthAnchor.constraint(equalToConstant: 120),
        discoImageView.heightAnchor.constraint(equalToConstant: 120),
        
        discoTitleLabel.centerXAnchor.constraint(equalTo: discoCardView.centerXAnchor),
        discoTitleLabel.topAnchor.constraint(equalTo: discoImageView.bottomAnchor, constant: 20),
        discoTitleLabel.leadingAnchor.constraint(equalTo: discoCardView.leadingAnchor, constant: 10),
        discoTitleLabel.trailingAnchor.constraint(equalTo: discoCardView.trailingAnchor, constant: -10),
        
        discoSubtitleLabel.centerXAnchor.constraint(equalTo: discoCardView.centerXAnchor),
        discoSubtitleLabel.topAnchor.constraint(equalTo: discoTitleLabel.bottomAnchor, constant: 20),
        discoSubtitleLabel.leadingAnchor.constraint(equalTo: discoCardView.leadingAnchor, constant: 10),
        discoSubtitleLabel.trailingAnchor.constraint(equalTo: discoCardView.trailingAnchor, constant: -10)
      ])
      
      // Store genre name as the view's tag using hash value
      discoCardView.tag = "Disco".hashValue
      
      // Add tap gesture
      let discoTapGesture = UITapGestureRecognizer(target: radioVC, action: #selector(UIViewController.genreTapped(_:)))
      discoCardView.addGestureRecognizer(discoTapGesture)
      discoCardView.isUserInteractionEnabled = true
      
      // Add the card to the carousel
      genresStackView.addArrangedSubview(discoCardView)
      
      // Try to load a random album artwork
        Task {
        // Find albums with Disco genre
          let allAlbums = appDelegate.storage.main.library.getAlbums()
        var discoAlbums = [Album]()
        
        for album in allAlbums {
          if let genre = album.genre?.name,
             genre.lowercased() == "disco" {
            discoAlbums.append(album)
          }
        }
        
        // If we found Disco albums, pick a random one and get its artwork
        if !discoAlbums.isEmpty {
          let randomIndex = Int.random(in: 0..<discoAlbums.count)
          let randomAlbum = discoAlbums[randomIndex]
          
          // Get and set artwork for the album
          if let artwork = randomAlbum.artwork?.image {
            // Update UI on main thread
            await MainActor.run {
              discoImageView.image = artwork
              discoImageView.contentMode = .scaleAspectFill
            }
          }
        }
      }
      
      // Create House Beats Card
      let houseCardView = UIView()
      houseCardView.translatesAutoresizingMaskIntoConstraints = false
      houseCardView.layer.cornerRadius = CornerRadius.appleMusic.asCGFloat
      houseCardView.clipsToBounds = true
      
      // Create background view with gradient
      let houseBackgroundView = GradientBackgroundView()
      houseBackgroundView.translatesAutoresizingMaskIntoConstraints = false
      houseCardView.addSubview(houseBackgroundView)
      
      // Setup gradient layer with house-themed colors
      let houseGradientLayer = CAGradientLayer()
      houseGradientLayer.colors = [
        UIColor(red: 0.2, green: 0.6, blue: 0.9, alpha: 1.0).cgColor, // Light blue
        UIColor(red: 0.0, green: 0.4, blue: 0.7, alpha: 1.0).cgColor  // Deep blue
      ]
      houseGradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
      houseGradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
      
      // Assign gradient to the background view and add it
      houseBackgroundView.gradientLayer = houseGradientLayer
      houseBackgroundView.layer.insertSublayer(houseGradientLayer, at: 0)
      
      let houseImageView = UIImageView()
      houseImageView.translatesAutoresizingMaskIntoConstraints = false
      houseImageView.contentMode = .scaleAspectFit
      houseImageView.clipsToBounds = true
      houseImageView.layer.cornerRadius = 8
      houseImageView.image = UIImage(systemName: "music.note.list")
      houseImageView.tintColor = .white
      houseCardView.addSubview(houseImageView)
      
      // Add title label
      let houseTitleLabel = UILabel()
      houseTitleLabel.translatesAutoresizingMaskIntoConstraints = false
      houseTitleLabel.text = "House"
      houseTitleLabel.font = .systemFont(ofSize: 32, weight: .bold)
      houseTitleLabel.textColor = .white
      houseTitleLabel.textAlignment = .center
      houseCardView.addSubview(houseTitleLabel)
      
      // Add subtitle label
      let houseSubtitleLabel = UILabel()
      houseSubtitleLabel.translatesAutoresizingMaskIntoConstraints = false
      houseSubtitleLabel.text = "Tap to shuffle songs"
      houseSubtitleLabel.font = .systemFont(ofSize: 14)
      houseSubtitleLabel.textColor = .white
      houseSubtitleLabel.textAlignment = .center
      houseCardView.addSubview(houseSubtitleLabel)
      
      // Setup constraints for house card
      NSLayoutConstraint.activate([
        houseCardView.widthAnchor.constraint(equalToConstant: 200),
        houseCardView.heightAnchor.constraint(equalToConstant: 280),
        
        houseBackgroundView.topAnchor.constraint(equalTo: houseCardView.topAnchor),
        houseBackgroundView.leadingAnchor.constraint(equalTo: houseCardView.leadingAnchor),
        houseBackgroundView.trailingAnchor.constraint(equalTo: houseCardView.trailingAnchor),
        houseBackgroundView.bottomAnchor.constraint(equalTo: houseCardView.bottomAnchor),
        
        houseImageView.centerXAnchor.constraint(equalTo: houseCardView.centerXAnchor),
        houseImageView.topAnchor.constraint(equalTo: houseCardView.topAnchor, constant: 40),
        houseImageView.widthAnchor.constraint(equalToConstant: 120),
        houseImageView.heightAnchor.constraint(equalToConstant: 120),
        
        houseTitleLabel.centerXAnchor.constraint(equalTo: houseCardView.centerXAnchor),
        houseTitleLabel.topAnchor.constraint(equalTo: houseImageView.bottomAnchor, constant: 20),
        houseTitleLabel.leadingAnchor.constraint(equalTo: houseCardView.leadingAnchor, constant: 10),
        houseTitleLabel.trailingAnchor.constraint(equalTo: houseCardView.trailingAnchor, constant: -10),
        
        houseSubtitleLabel.centerXAnchor.constraint(equalTo: houseCardView.centerXAnchor),
        houseSubtitleLabel.topAnchor.constraint(equalTo: houseTitleLabel.bottomAnchor, constant: 20),
        houseSubtitleLabel.leadingAnchor.constraint(equalTo: houseCardView.leadingAnchor, constant: 10),
        houseSubtitleLabel.trailingAnchor.constraint(equalTo: houseCardView.trailingAnchor, constant: -10)
      ])
      
      // Store genre name as the view's tag using hash value
      houseCardView.tag = "House".hashValue
      
      // Add tap gesture
      let houseTapGesture = UITapGestureRecognizer(target: radioVC, action: #selector(UIViewController.genreTapped(_:)))
      houseCardView.addGestureRecognizer(houseTapGesture)
      houseCardView.isUserInteractionEnabled = true
      
      // Add the card to the carousel
      genresStackView.addArrangedSubview(houseCardView)
      
      // Try to load a random album artwork
      Task {
        // Find albums with House genre
        let allAlbums = appDelegate.storage.main.library.getAlbums()
        var houseAlbums = [Album]()
          
          for album in allAlbums {
          if let genre = album.genre?.name,
             genre.lowercased() == "house" {
            houseAlbums.append(album)
          }
        }
        
        // If we found House albums, pick a random one and get its artwork
        if !houseAlbums.isEmpty {
          let randomIndex = Int.random(in: 0..<houseAlbums.count)
          let randomAlbum = houseAlbums[randomIndex]
            
            // Get and set artwork for the album
            if let artwork = randomAlbum.artwork?.image {
              // Update UI on main thread
              await MainActor.run {
              houseImageView.image = artwork
              houseImageView.contentMode = .scaleAspectFill
            }
          }
        }
      }
      
      // Create Bollywood Card
      let bollywoodCardView = UIView()
      bollywoodCardView.translatesAutoresizingMaskIntoConstraints = false
      bollywoodCardView.layer.cornerRadius = CornerRadius.appleMusic.asCGFloat
      bollywoodCardView.clipsToBounds = true
      genresContentView.addSubview(bollywoodCardView)
      
      // Create background view with gradient
      let bollywoodBackgroundView = GradientBackgroundView()
      bollywoodBackgroundView.translatesAutoresizingMaskIntoConstraints = false
      bollywoodCardView.addSubview(bollywoodBackgroundView)
      
      // Setup gradient layer with Bollywood-themed colors
      let bollywoodGradientLayer = CAGradientLayer()
      bollywoodGradientLayer.colors = [
        UIColor(red: 0.9, green: 0.3, blue: 0.1, alpha: 1.0).cgColor, // Orange-Red
        UIColor(red: 0.8, green: 0.1, blue: 0.3, alpha: 1.0).cgColor  // Deep Red
      ]
      bollywoodGradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
      bollywoodGradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
      
      // Assign gradient to the background view and add it
      bollywoodBackgroundView.gradientLayer = bollywoodGradientLayer
      bollywoodBackgroundView.layer.insertSublayer(bollywoodGradientLayer, at: 0)
      
      let bollywoodImageView = UIImageView()
      bollywoodImageView.translatesAutoresizingMaskIntoConstraints = false
      bollywoodImageView.contentMode = .scaleAspectFit
      bollywoodImageView.clipsToBounds = true
      bollywoodImageView.layer.cornerRadius = 8
      bollywoodImageView.image = UIImage(systemName: "music.note.list")
      bollywoodImageView.tintColor = .white
      bollywoodCardView.addSubview(bollywoodImageView)
      
      let bollywoodTitleLabel = UILabel()
      bollywoodTitleLabel.translatesAutoresizingMaskIntoConstraints = false
      bollywoodTitleLabel.text = "Bollywood"
      bollywoodTitleLabel.font = .systemFont(ofSize: 32, weight: .bold)
      bollywoodTitleLabel.textColor = .white
      bollywoodTitleLabel.textAlignment = .center
      bollywoodCardView.addSubview(bollywoodTitleLabel)
      
      let bollywoodSubtitleLabel = UILabel()
      bollywoodSubtitleLabel.translatesAutoresizingMaskIntoConstraints = false
      bollywoodSubtitleLabel.text = "Tap to shuffle songs"
      bollywoodSubtitleLabel.font = .systemFont(ofSize: 14)
      bollywoodSubtitleLabel.textColor = .white
      bollywoodSubtitleLabel.textAlignment = .center
      bollywoodCardView.addSubview(bollywoodSubtitleLabel)
      
      NSLayoutConstraint.activate([
        bollywoodCardView.widthAnchor.constraint(equalToConstant: 200),
        bollywoodCardView.heightAnchor.constraint(equalToConstant: 280),
        
        bollywoodBackgroundView.topAnchor.constraint(equalTo: bollywoodCardView.topAnchor),
        bollywoodBackgroundView.leadingAnchor.constraint(equalTo: bollywoodCardView.leadingAnchor),
        bollywoodBackgroundView.trailingAnchor.constraint(equalTo: bollywoodCardView.trailingAnchor),
        bollywoodBackgroundView.bottomAnchor.constraint(equalTo: bollywoodCardView.bottomAnchor),
        
        bollywoodImageView.centerXAnchor.constraint(equalTo: bollywoodCardView.centerXAnchor),
        bollywoodImageView.topAnchor.constraint(equalTo: bollywoodCardView.topAnchor, constant: 40),
        bollywoodImageView.widthAnchor.constraint(equalToConstant: 120),
        bollywoodImageView.heightAnchor.constraint(equalToConstant: 120),
        
        bollywoodTitleLabel.centerXAnchor.constraint(equalTo: bollywoodCardView.centerXAnchor),
        bollywoodTitleLabel.topAnchor.constraint(equalTo: bollywoodImageView.bottomAnchor, constant: 20),
        bollywoodTitleLabel.leadingAnchor.constraint(equalTo: bollywoodCardView.leadingAnchor, constant: 10),
        bollywoodTitleLabel.trailingAnchor.constraint(equalTo: bollywoodCardView.trailingAnchor, constant: -10),
        
        bollywoodSubtitleLabel.centerXAnchor.constraint(equalTo: bollywoodCardView.centerXAnchor),
        bollywoodSubtitleLabel.topAnchor.constraint(equalTo: bollywoodTitleLabel.bottomAnchor, constant: 20),
        bollywoodSubtitleLabel.leadingAnchor.constraint(equalTo: bollywoodCardView.leadingAnchor, constant: 10),
        bollywoodSubtitleLabel.trailingAnchor.constraint(equalTo: bollywoodCardView.trailingAnchor, constant: -10)
      ])
      
      // Store genre name as the view's tag using hash value
      bollywoodCardView.tag = "Bollywood".hashValue
      
      // Add tap gesture
      let bollywoodTapGesture = UITapGestureRecognizer(target: radioVC, action: #selector(UIViewController.genreTapped(_:)))
      bollywoodCardView.addGestureRecognizer(bollywoodTapGesture)
      bollywoodCardView.isUserInteractionEnabled = true
      
      // Add the card to the carousel
      genresStackView.addArrangedSubview(bollywoodCardView)
      
      // Try to load a random album artwork for Bollywood
      Task {
        // Find albums with Bollywood genre
        let allAlbums = appDelegate.storage.main.library.getAlbums()
        var bollywoodAlbums = [Album]()
        
        for album in allAlbums {
          if let genre = album.genre?.name,
             genre.lowercased() == "bollywood" {
            bollywoodAlbums.append(album)
          }
        }
        
        // If we found Bollywood albums, pick a random one and get its artwork
        if !bollywoodAlbums.isEmpty {
          let randomIndex = Int.random(in: 0..<bollywoodAlbums.count)
          let randomAlbum = bollywoodAlbums[randomIndex]
          
          // Get and set artwork for the album
          if let artwork = randomAlbum.artwork?.image {
            // Update UI on main thread
            await MainActor.run {
              bollywoodImageView.image = artwork
              bollywoodImageView.contentMode = .scaleAspectFill
            }
          }
        }
      }
      
      // Create Filmi genre card
      let filmiCardView = UIView()
      filmiCardView.translatesAutoresizingMaskIntoConstraints = false
      filmiCardView.layer.cornerRadius = CornerRadius.appleMusic.asCGFloat
      filmiCardView.clipsToBounds = true
      
      // Create background view with gradient
      let filmiBackgroundView = GradientBackgroundView()
      filmiBackgroundView.translatesAutoresizingMaskIntoConstraints = false
      filmiCardView.addSubview(filmiBackgroundView)
      
      // Setup gradient layer with filmi-themed colors
      let filmiGradientLayer = CAGradientLayer()
      filmiGradientLayer.colors = [
        UIColor(red: 0.9, green: 0.5, blue: 0.1, alpha: 1.0).cgColor, // Orange
        UIColor(red: 0.8, green: 0.0, blue: 0.3, alpha: 1.0).cgColor  // Red
      ]
      filmiGradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
      filmiGradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
      
      // Assign gradient to the background view and add it
      filmiBackgroundView.gradientLayer = filmiGradientLayer
      filmiBackgroundView.layer.insertSublayer(filmiGradientLayer, at: 0)
      
      // Add album artwork view with default icon first
      let filmiImageView = UIImageView()
      filmiImageView.translatesAutoresizingMaskIntoConstraints = false
      filmiImageView.contentMode = .scaleAspectFit
      filmiImageView.clipsToBounds = true
      filmiImageView.layer.cornerRadius = 8
      filmiImageView.image = UIImage(systemName: "music.note.list")
      filmiImageView.tintColor = .white
      filmiCardView.addSubview(filmiImageView)
      
      // Add title label
      let filmiTitleLabel = UILabel()
      filmiTitleLabel.translatesAutoresizingMaskIntoConstraints = false
      filmiTitleLabel.text = "Filmi"
      filmiTitleLabel.font = .systemFont(ofSize: 32, weight: .bold)
      filmiTitleLabel.textColor = .white
      filmiTitleLabel.textAlignment = .center
      filmiCardView.addSubview(filmiTitleLabel)
      
      // Add subtitle label
      let filmiSubtitleLabel = UILabel()
      filmiSubtitleLabel.translatesAutoresizingMaskIntoConstraints = false
      filmiSubtitleLabel.text = "Tap to shuffle songs"
      filmiSubtitleLabel.font = .systemFont(ofSize: 14)
      filmiSubtitleLabel.textColor = .white
      filmiSubtitleLabel.textAlignment = .center
      filmiCardView.addSubview(filmiSubtitleLabel)
      
      // Setup constraints for filmi card
      NSLayoutConstraint.activate([
        filmiCardView.widthAnchor.constraint(equalToConstant: 200),
        filmiCardView.heightAnchor.constraint(equalToConstant: 280),
        
        filmiBackgroundView.topAnchor.constraint(equalTo: filmiCardView.topAnchor),
        filmiBackgroundView.leadingAnchor.constraint(equalTo: filmiCardView.leadingAnchor),
        filmiBackgroundView.trailingAnchor.constraint(equalTo: filmiCardView.trailingAnchor),
        filmiBackgroundView.bottomAnchor.constraint(equalTo: filmiCardView.bottomAnchor),
        
        filmiImageView.centerXAnchor.constraint(equalTo: filmiCardView.centerXAnchor),
        filmiImageView.topAnchor.constraint(equalTo: filmiCardView.topAnchor, constant: 40),
        filmiImageView.widthAnchor.constraint(equalToConstant: 120),
        filmiImageView.heightAnchor.constraint(equalToConstant: 120),
        
        filmiTitleLabel.centerXAnchor.constraint(equalTo: filmiCardView.centerXAnchor),
        filmiTitleLabel.topAnchor.constraint(equalTo: filmiImageView.bottomAnchor, constant: 20),
        filmiTitleLabel.leadingAnchor.constraint(equalTo: filmiCardView.leadingAnchor, constant: 10),
        filmiTitleLabel.trailingAnchor.constraint(equalTo: filmiCardView.trailingAnchor, constant: -10),
        
        filmiSubtitleLabel.centerXAnchor.constraint(equalTo: filmiCardView.centerXAnchor),
        filmiSubtitleLabel.topAnchor.constraint(equalTo: filmiTitleLabel.bottomAnchor, constant: 20),
        filmiSubtitleLabel.leadingAnchor.constraint(equalTo: filmiCardView.leadingAnchor, constant: 10),
        filmiSubtitleLabel.trailingAnchor.constraint(equalTo: filmiCardView.trailingAnchor, constant: -10)
      ])
      
      // Store genre name as the view's tag using hash value
      filmiCardView.tag = "Filmi".hashValue
      
      // Add tap gesture
      let filmiTapGesture = UITapGestureRecognizer(target: radioVC, action: #selector(UIViewController.genreTapped(_:)))
      filmiCardView.addGestureRecognizer(filmiTapGesture)
      filmiCardView.isUserInteractionEnabled = true
      
      // Add the card to the carousel
      genresStackView.addArrangedSubview(filmiCardView)
      
      // Try to load a random album artwork for Filmi
      Task {
        // Find albums with Filmi genre
        let allAlbums = appDelegate.storage.main.library.getAlbums()
        var filmiAlbums = [Album]()
        
        for album in allAlbums {
          if let genre = album.genre?.name,
             genre.lowercased() == "filmi" {
            filmiAlbums.append(album)
          }
        }
        
        // If we found Filmi albums, pick a random one and get its artwork
        if !filmiAlbums.isEmpty {
          let randomIndex = Int.random(in: 0..<filmiAlbums.count)
          let randomAlbum = filmiAlbums[randomIndex]
          
          // Get and set artwork for the album
          if let artwork = randomAlbum.artwork?.image {
            // Update UI on main thread
            await MainActor.run {
              filmiImageView.image = artwork
              filmiImageView.contentMode = .scaleAspectFill
            }
          }
        }
      }
      
      // Calculate and set the content size for proper scrolling
      // Sized for our 6 genre cards: Disco, House, Bollywood, Filmi, Punjabi, Haryanvi
      let genresTotalWidth = CGFloat(6 * 215) // 200 width + 15 spacing for 6 cards
      
      // Set the content view's width constraint
      let genresWidthConstraint = genresContentView.widthAnchor.constraint(equalToConstant: genresTotalWidth)
      genresWidthConstraint.priority = .required
      genresWidthConstraint.isActive = true
      
      // Make sure content view's width can be greater than the scroll view's width
      let genresMinWidthConstraint = genresContentView.widthAnchor.constraint(greaterThanOrEqualTo: genresScrollView.widthAnchor)
      genresMinWidthConstraint.priority = .defaultHigh
      genresMinWidthConstraint.isActive = true
      
      // Force layout to ensure proper sizing
      genresScrollView.layoutIfNeeded()
      
      // Ensure proper vertical scrolling
      scrollView.layoutIfNeeded()
      
      // Add padding at the bottom for better scrolling experience
      let bottomPaddingView = UIView()
      bottomPaddingView.translatesAutoresizingMaskIntoConstraints = false
      bottomPaddingView.heightAnchor.constraint(equalToConstant: 40).isActive = true
      stackView.addArrangedSubview(bottomPaddingView)
      
      // Set references for custom view controller
      radioVC.mainScrollView = scrollView
      radioVC.contentStackView = stackView
      
      // Add the card to the carousel
      genresStackView.addArrangedSubview(houseCardView)
      
      // Try to load a random album artwork
      Task {
        // Find albums with House genre
        let allAlbums = appDelegate.storage.main.library.getAlbums()
        var houseAlbums = [Album]()
        
        for album in allAlbums {
          if let genre = album.genre?.name,
             genre.lowercased() == "house" {
            houseAlbums.append(album)
          }
        }
        
        // If we found House albums, pick a random one and get its artwork
        if !houseAlbums.isEmpty {
          let randomIndex = Int.random(in: 0..<houseAlbums.count)
          let randomAlbum = houseAlbums[randomIndex]
          
          // Get and set artwork for the album
          if let artwork = randomAlbum.artwork?.image {
            // Update UI on main thread
            await MainActor.run {
              houseImageView.image = artwork
              houseImageView.contentMode = .scaleAspectFill
            }
          }
        }
      }
      
      // Create Punjabi Card
      let punjabiCardView = UIView()
      punjabiCardView.translatesAutoresizingMaskIntoConstraints = false
      punjabiCardView.layer.cornerRadius = CornerRadius.appleMusic.asCGFloat
      punjabiCardView.clipsToBounds = true
      
      // Create background view with gradient
      let punjabiBackgroundView = GradientBackgroundView()
      punjabiBackgroundView.translatesAutoresizingMaskIntoConstraints = false
      punjabiCardView.addSubview(punjabiBackgroundView)
      
      // Setup gradient layer with Punjabi-themed colors
      let punjabiGradientLayer = CAGradientLayer()
      punjabiGradientLayer.colors = [
        UIColor(red: 0.95, green: 0.4, blue: 0.1, alpha: 1.0).cgColor, // Orange
        UIColor(red: 0.8, green: 0.1, blue: 0.2, alpha: 1.0).cgColor  // Deep red
      ]
      punjabiGradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
      punjabiGradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
      
      // Assign gradient to the background view and add it
      punjabiBackgroundView.gradientLayer = punjabiGradientLayer
      punjabiBackgroundView.layer.insertSublayer(punjabiGradientLayer, at: 0)
      
      let punjabiImageView = UIImageView()
      punjabiImageView.translatesAutoresizingMaskIntoConstraints = false
      punjabiImageView.contentMode = .scaleAspectFit
      punjabiImageView.clipsToBounds = true
      punjabiImageView.layer.cornerRadius = 8
      punjabiImageView.image = UIImage(systemName: "music.note.list")
      punjabiImageView.tintColor = .white
      punjabiCardView.addSubview(punjabiImageView)
      
      // Add title label
      let punjabiTitleLabel = UILabel()
      punjabiTitleLabel.translatesAutoresizingMaskIntoConstraints = false
      punjabiTitleLabel.text = "Punjabi"
      punjabiTitleLabel.font = .systemFont(ofSize: 32, weight: .bold)
      punjabiTitleLabel.textColor = .white
      punjabiTitleLabel.textAlignment = .center
      punjabiCardView.addSubview(punjabiTitleLabel)
      
      // Add subtitle label
      let punjabiSubtitleLabel = UILabel()
      punjabiSubtitleLabel.translatesAutoresizingMaskIntoConstraints = false
      punjabiSubtitleLabel.text = "Tap to shuffle songs"
      punjabiSubtitleLabel.font = .systemFont(ofSize: 14)
      punjabiSubtitleLabel.textColor = .white
      punjabiSubtitleLabel.textAlignment = .center
      punjabiCardView.addSubview(punjabiSubtitleLabel)
      
      // Setup constraints for Punjabi card
      NSLayoutConstraint.activate([
        punjabiCardView.widthAnchor.constraint(equalToConstant: 200),
        punjabiCardView.heightAnchor.constraint(equalToConstant: 280),
        
        punjabiBackgroundView.topAnchor.constraint(equalTo: punjabiCardView.topAnchor),
        punjabiBackgroundView.leadingAnchor.constraint(equalTo: punjabiCardView.leadingAnchor),
        punjabiBackgroundView.trailingAnchor.constraint(equalTo: punjabiCardView.trailingAnchor),
        punjabiBackgroundView.bottomAnchor.constraint(equalTo: punjabiCardView.bottomAnchor),
        
        punjabiImageView.centerXAnchor.constraint(equalTo: punjabiCardView.centerXAnchor),
        punjabiImageView.topAnchor.constraint(equalTo: punjabiCardView.topAnchor, constant: 40),
        punjabiImageView.widthAnchor.constraint(equalToConstant: 120),
        punjabiImageView.heightAnchor.constraint(equalToConstant: 120),
        
        punjabiTitleLabel.centerXAnchor.constraint(equalTo: punjabiCardView.centerXAnchor),
        punjabiTitleLabel.topAnchor.constraint(equalTo: punjabiImageView.bottomAnchor, constant: 20),
        punjabiTitleLabel.leadingAnchor.constraint(equalTo: punjabiCardView.leadingAnchor, constant: 10),
        punjabiTitleLabel.trailingAnchor.constraint(equalTo: punjabiCardView.trailingAnchor, constant: -10),
        
        punjabiSubtitleLabel.centerXAnchor.constraint(equalTo: punjabiCardView.centerXAnchor),
        punjabiSubtitleLabel.topAnchor.constraint(equalTo: punjabiTitleLabel.bottomAnchor, constant: 20),
        punjabiSubtitleLabel.leadingAnchor.constraint(equalTo: punjabiCardView.leadingAnchor, constant: 10),
        punjabiSubtitleLabel.trailingAnchor.constraint(equalTo: punjabiCardView.trailingAnchor, constant: -10)
      ])
      
      // Store genre name as the view's tag using hash value
      punjabiCardView.tag = "Punjabi".hashValue
      
      // Add tap gesture
      let punjabiTapGesture = UITapGestureRecognizer(target: radioVC, action: #selector(UIViewController.genreTapped(_:)))
      punjabiCardView.addGestureRecognizer(punjabiTapGesture)
      punjabiCardView.isUserInteractionEnabled = true
      
      // Add the card to the carousel
      genresStackView.addArrangedSubview(punjabiCardView)
      
      // Try to load a random album artwork
      Task {
        // Find albums with Punjabi genre
        let allAlbums = appDelegate.storage.main.library.getAlbums()
        var punjabiAlbums = [Album]()
        
        for album in allAlbums {
          if let genre = album.genre?.name,
             genre.lowercased() == "punjabi" {
            punjabiAlbums.append(album)
          }
        }
        
        // If we found Punjabi albums, pick a random one and get its artwork
        if !punjabiAlbums.isEmpty {
          let randomIndex = Int.random(in: 0..<punjabiAlbums.count)
          let randomAlbum = punjabiAlbums[randomIndex]
          
          // Get and set artwork for the album
          if let artwork = randomAlbum.artwork?.image {
            // Update UI on main thread
            await MainActor.run {
              punjabiImageView.image = artwork
              punjabiImageView.contentMode = .scaleAspectFill
            }
          }
        }
      }
      
      // Create Haryanvi genre card
      let haryanviCardView = UIView()
      haryanviCardView.translatesAutoresizingMaskIntoConstraints = false
      haryanviCardView.layer.cornerRadius = CornerRadius.appleMusic.asCGFloat
      haryanviCardView.clipsToBounds = true
      
      // Create background view with gradient
      let haryanviBackgroundView = GradientBackgroundView()
      haryanviBackgroundView.translatesAutoresizingMaskIntoConstraints = false
      haryanviCardView.addSubview(haryanviBackgroundView)
      
      // Setup gradient layer with haryanvi-themed colors
      let haryanviGradientLayer = CAGradientLayer()
      haryanviGradientLayer.colors = [
        UIColor(red: 0.1, green: 0.6, blue: 0.9, alpha: 1.0).cgColor, // Light blue
        UIColor(red: 0.0, green: 0.4, blue: 0.8, alpha: 1.0).cgColor  // Deep blue
      ]
      haryanviGradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
      haryanviGradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
      
      // Assign gradient to the background view and add it
      haryanviBackgroundView.gradientLayer = haryanviGradientLayer
      haryanviBackgroundView.layer.insertSublayer(haryanviGradientLayer, at: 0)
      
      // Add album artwork view with default icon first
      let haryanviImageView = UIImageView()
      haryanviImageView.translatesAutoresizingMaskIntoConstraints = false
      haryanviImageView.contentMode = .scaleAspectFit
      haryanviImageView.clipsToBounds = true
      haryanviImageView.layer.cornerRadius = 8
      haryanviImageView.image = UIImage(systemName: "music.note.list")
      haryanviImageView.tintColor = .white
      haryanviCardView.addSubview(haryanviImageView)
      
      // Add title label
      let haryanviTitleLabel = UILabel()
      haryanviTitleLabel.translatesAutoresizingMaskIntoConstraints = false
      haryanviTitleLabel.text = "Haryanvi"
      haryanviTitleLabel.font = .systemFont(ofSize: 32, weight: .bold)
      haryanviTitleLabel.textColor = .white
      haryanviTitleLabel.textAlignment = .center
      haryanviCardView.addSubview(haryanviTitleLabel)
      
      // Add subtitle label
      let haryanviSubtitleLabel = UILabel()
      haryanviSubtitleLabel.translatesAutoresizingMaskIntoConstraints = false
      haryanviSubtitleLabel.text = "Tap to shuffle songs"
      haryanviSubtitleLabel.font = .systemFont(ofSize: 14)
      haryanviSubtitleLabel.textColor = .white
      haryanviSubtitleLabel.textAlignment = .center
      haryanviCardView.addSubview(haryanviSubtitleLabel)
      
      // Setup constraints for haryanvi card
      NSLayoutConstraint.activate([
        haryanviCardView.widthAnchor.constraint(equalToConstant: 200),
        haryanviCardView.heightAnchor.constraint(equalToConstant: 280),
        
        haryanviBackgroundView.topAnchor.constraint(equalTo: haryanviCardView.topAnchor),
        haryanviBackgroundView.leadingAnchor.constraint(equalTo: haryanviCardView.leadingAnchor),
        haryanviBackgroundView.trailingAnchor.constraint(equalTo: haryanviCardView.trailingAnchor),
        haryanviBackgroundView.bottomAnchor.constraint(equalTo: haryanviCardView.bottomAnchor),
        
        haryanviImageView.centerXAnchor.constraint(equalTo: haryanviCardView.centerXAnchor),
        haryanviImageView.topAnchor.constraint(equalTo: haryanviCardView.topAnchor, constant: 40),
        haryanviImageView.widthAnchor.constraint(equalToConstant: 120),
        haryanviImageView.heightAnchor.constraint(equalToConstant: 120),
        
        haryanviTitleLabel.centerXAnchor.constraint(equalTo: haryanviCardView.centerXAnchor),
        haryanviTitleLabel.topAnchor.constraint(equalTo: haryanviImageView.bottomAnchor, constant: 20),
        haryanviTitleLabel.leadingAnchor.constraint(equalTo: haryanviCardView.leadingAnchor, constant: 10),
        haryanviTitleLabel.trailingAnchor.constraint(equalTo: haryanviCardView.trailingAnchor, constant: -10),
        
        haryanviSubtitleLabel.centerXAnchor.constraint(equalTo: haryanviCardView.centerXAnchor),
        haryanviSubtitleLabel.topAnchor.constraint(equalTo: haryanviTitleLabel.bottomAnchor, constant: 20),
        haryanviSubtitleLabel.leadingAnchor.constraint(equalTo: haryanviCardView.leadingAnchor, constant: 10),
        haryanviSubtitleLabel.trailingAnchor.constraint(equalTo: haryanviCardView.trailingAnchor, constant: -10)
      ])
      
      // Store genre name as the view's tag using hash value
      haryanviCardView.tag = "Haryanvi".hashValue
      
      // Add tap gesture
      let haryanviTapGesture = UITapGestureRecognizer(target: radioVC, action: #selector(UIViewController.genreTapped(_:)))
      haryanviCardView.addGestureRecognizer(haryanviTapGesture)
      haryanviCardView.isUserInteractionEnabled = true
      
      // Add the card to the carousel
      genresStackView.addArrangedSubview(haryanviCardView)
      
      // Try to load a random album artwork
      Task {
        // Find albums with Haryanvi genre
        let allAlbums = appDelegate.storage.main.library.getAlbums()
        var haryanviAlbums = [Album]()
        
        for album in allAlbums {
          if let genre = album.genre?.name,
             genre.lowercased() == "haryanvi" {
            haryanviAlbums.append(album)
          }
        }
        
        // If we found Haryanvi albums, pick a random one and get its artwork
        if !haryanviAlbums.isEmpty {
          let randomIndex = Int.random(in: 0..<haryanviAlbums.count)
          let randomAlbum = haryanviAlbums[randomIndex]
          
          // Get and set artwork for the album
          if let artwork = randomAlbum.artwork?.image {
            // Update UI on main thread
            await MainActor.run {
              haryanviImageView.image = artwork
              haryanviImageView.contentMode = .scaleAspectFill
            }
          }
        }
      }
      // ... existing code ...
      
      // Add Morning Mood section
      // Create header view for the Morning Mood section
      let morningHeaderView = UIView()
      morningHeaderView.translatesAutoresizingMaskIntoConstraints = false
      stackView.addArrangedSubview(morningHeaderView)
      
      let morningLabel = UILabel()
      morningLabel.text = "Rhythms of Time"
      morningLabel.font = .systemFont(ofSize: 20, weight: .bold)
      morningLabel.translatesAutoresizingMaskIntoConstraints = false
      morningHeaderView.addSubview(morningLabel)
      
      NSLayoutConstraint.activate([
        morningHeaderView.heightAnchor.constraint(equalToConstant: 30),
        morningLabel.leadingAnchor.constraint(equalTo: morningHeaderView.leadingAnchor),
        morningLabel.centerYAnchor.constraint(equalTo: morningHeaderView.centerYAnchor)
      ])
      
      // Create horizontal scroll view for the carousel
      let morningScrollView = UIScrollView()
      morningScrollView.showsHorizontalScrollIndicator = true
      morningScrollView.translatesAutoresizingMaskIntoConstraints = false
      morningScrollView.alwaysBounceHorizontal = true
      morningScrollView.clipsToBounds = true
      morningScrollView.decelerationRate = .fast // Physics-based momentum scrolling
      stackView.addArrangedSubview(morningScrollView)
      
      // Set fixed height for carousel
      morningScrollView.heightAnchor.constraint(equalToConstant: 320).isActive = true
      
      // Create content view for the scroll view
      let morningContentView = UIView()
      morningContentView.translatesAutoresizingMaskIntoConstraints = false
      morningScrollView.addSubview(morningContentView)
      
      // Setup content view constraints
      NSLayoutConstraint.activate([
        morningContentView.topAnchor.constraint(equalTo: morningScrollView.topAnchor),
        morningContentView.leadingAnchor.constraint(equalTo: morningScrollView.leadingAnchor),
        morningContentView.trailingAnchor.constraint(equalTo: morningScrollView.trailingAnchor),
        morningContentView.bottomAnchor.constraint(equalTo: morningScrollView.bottomAnchor),
        morningContentView.heightAnchor.constraint(equalTo: morningScrollView.heightAnchor)
      ])
      
      // Create horizontal stack view for carousel items
      let morningStackView = UIStackView()
      morningStackView.axis = .horizontal
      morningStackView.spacing = 15
      morningStackView.alignment = .center
      morningStackView.translatesAutoresizingMaskIntoConstraints = false
      morningContentView.addSubview(morningStackView)
      
      // Setup stack view constraints
      NSLayoutConstraint.activate([
        morningStackView.topAnchor.constraint(equalTo: morningContentView.topAnchor, constant: 10),
        morningStackView.leadingAnchor.constraint(equalTo: morningContentView.leadingAnchor, constant: 10),
        morningStackView.trailingAnchor.constraint(equalTo: morningContentView.trailingAnchor, constant: -10),
        morningStackView.bottomAnchor.constraint(equalTo: morningContentView.bottomAnchor, constant: -10)
      ])
      
      // Create Morning Mood card
      let morningCardView = UIView()
      morningCardView.translatesAutoresizingMaskIntoConstraints = false
      morningCardView.layer.cornerRadius = CornerRadius.appleMusic.asCGFloat
      morningCardView.clipsToBounds = true
      
      // Create background view with gradient
      let morningBackgroundView = GradientBackgroundView()
      morningBackgroundView.translatesAutoresizingMaskIntoConstraints = false
      morningCardView.addSubview(morningBackgroundView)
      
      // Setup gradient layer with morning-themed colors
      let morningGradientLayer = CAGradientLayer()
      morningGradientLayer.colors = [
        UIColor(red: 0.98, green: 0.82, blue: 0.34, alpha: 1.0).cgColor, // Warm yellow
        UIColor(red: 0.95, green: 0.55, blue: 0.25, alpha: 1.0).cgColor  // Soft orange
      ]
      morningGradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
      morningGradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
      
      // Assign gradient to the background view and add it
      morningBackgroundView.gradientLayer = morningGradientLayer
      morningBackgroundView.layer.insertSublayer(morningGradientLayer, at: 0)
      
      let morningImageView = UIImageView()
      morningImageView.translatesAutoresizingMaskIntoConstraints = false
      morningImageView.contentMode = .scaleAspectFit
      morningImageView.clipsToBounds = true
      morningImageView.layer.cornerRadius = 8
      morningImageView.image = UIImage(systemName: "sunrise.fill")
      morningImageView.tintColor = .white
      morningCardView.addSubview(morningImageView)
      
      // Add title label
      let morningTitleLabel = UILabel()
      morningTitleLabel.translatesAutoresizingMaskIntoConstraints = false
      morningTitleLabel.text = "Morning Vibes"
      morningTitleLabel.font = .systemFont(ofSize: 20, weight: .bold)
      morningTitleLabel.textColor = .white
      morningTitleLabel.textAlignment = .center
      morningCardView.addSubview(morningTitleLabel)
      
      // Add subtitle label
      let morningSubtitleLabel = UILabel()
      morningSubtitleLabel.translatesAutoresizingMaskIntoConstraints = false
      morningSubtitleLabel.text = "Start your day right"
      morningSubtitleLabel.font = .systemFont(ofSize: 12)
      morningSubtitleLabel.textColor = .white
      morningSubtitleLabel.textAlignment = .center
      morningCardView.addSubview(morningSubtitleLabel)
      
      // Setup constraints for morning card
      NSLayoutConstraint.activate([
        morningCardView.widthAnchor.constraint(equalToConstant: 200),
        morningCardView.heightAnchor.constraint(equalToConstant: 280),
        
        morningBackgroundView.topAnchor.constraint(equalTo: morningCardView.topAnchor),
        morningBackgroundView.leadingAnchor.constraint(equalTo: morningCardView.leadingAnchor),
        morningBackgroundView.trailingAnchor.constraint(equalTo: morningCardView.trailingAnchor),
        morningBackgroundView.bottomAnchor.constraint(equalTo: morningCardView.bottomAnchor),
        
        morningImageView.centerXAnchor.constraint(equalTo: morningCardView.centerXAnchor),
        morningImageView.topAnchor.constraint(equalTo: morningCardView.topAnchor, constant: 40),
        morningImageView.widthAnchor.constraint(equalToConstant: 120),
        morningImageView.heightAnchor.constraint(equalToConstant: 120),
        
        morningTitleLabel.centerXAnchor.constraint(equalTo: morningCardView.centerXAnchor),
        morningTitleLabel.topAnchor.constraint(equalTo: morningImageView.bottomAnchor, constant: 20),
        morningTitleLabel.leadingAnchor.constraint(equalTo: morningCardView.leadingAnchor, constant: 10),
        morningTitleLabel.trailingAnchor.constraint(equalTo: morningCardView.trailingAnchor, constant: -10),
        
        morningSubtitleLabel.centerXAnchor.constraint(equalTo: morningCardView.centerXAnchor),
        morningSubtitleLabel.topAnchor.constraint(equalTo: morningTitleLabel.bottomAnchor, constant: 20),
        morningSubtitleLabel.leadingAnchor.constraint(equalTo: morningCardView.leadingAnchor, constant: 10),
        morningSubtitleLabel.trailingAnchor.constraint(equalTo: morningCardView.trailingAnchor, constant: -10)
      ])
      
      // Store mood name as the view's tag using hash value
      morningCardView.tag = "MorningVibes".hashValue
      
      // Add tap gesture
      let morningTapGesture = UITapGestureRecognizer(target: radioVC, action: #selector(UIViewController.moodTapped(_:)))
      morningCardView.addGestureRecognizer(morningTapGesture)
      morningCardView.isUserInteractionEnabled = true
      
      // Add the card to the carousel
      morningStackView.addArrangedSubview(morningCardView)
      
      // Create Afternoon Chill card
      let afternoonCardView = UIView()
      afternoonCardView.translatesAutoresizingMaskIntoConstraints = false
      afternoonCardView.layer.cornerRadius = CornerRadius.appleMusic.asCGFloat
      afternoonCardView.clipsToBounds = true
      
      // Create background view with gradient
      let afternoonBackgroundView = GradientBackgroundView()
      afternoonBackgroundView.translatesAutoresizingMaskIntoConstraints = false
      afternoonCardView.addSubview(afternoonBackgroundView)
      
      // Setup gradient layer with afternoon-themed colors
      let afternoonGradientLayer = CAGradientLayer()
      afternoonGradientLayer.colors = [
        UIColor(red: 0.0, green: 0.6, blue: 0.9, alpha: 1.0).cgColor, // Sky blue
        UIColor(red: 0.0, green: 0.4, blue: 0.8, alpha: 1.0).cgColor  // Deeper blue
      ]
      afternoonGradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
      afternoonGradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
      
      // Assign gradient to the background view and add it
      afternoonBackgroundView.gradientLayer = afternoonGradientLayer
      afternoonBackgroundView.layer.insertSublayer(afternoonGradientLayer, at: 0)
      
      let afternoonImageView = UIImageView()
      afternoonImageView.translatesAutoresizingMaskIntoConstraints = false
      afternoonImageView.contentMode = .scaleAspectFit
      afternoonImageView.clipsToBounds = true
      afternoonImageView.layer.cornerRadius = 8
      afternoonImageView.image = UIImage(systemName: "sun.max.fill")
      afternoonImageView.tintColor = .white
      afternoonCardView.addSubview(afternoonImageView)
      
      // Add title label
      let afternoonTitleLabel = UILabel()
      afternoonTitleLabel.translatesAutoresizingMaskIntoConstraints = false
      afternoonTitleLabel.text = "Afternoon Chill"
      afternoonTitleLabel.font = .systemFont(ofSize: 20, weight: .bold)
      afternoonTitleLabel.textColor = .white
      afternoonTitleLabel.textAlignment = .center
      afternoonCardView.addSubview(afternoonTitleLabel)
      
      // Add subtitle label
      let afternoonSubtitleLabel = UILabel()
      afternoonSubtitleLabel.translatesAutoresizingMaskIntoConstraints = false
      afternoonSubtitleLabel.text = "Midday relaxation"
      afternoonSubtitleLabel.font = .systemFont(ofSize: 12)
      afternoonSubtitleLabel.textColor = .white
      afternoonSubtitleLabel.textAlignment = .center
      afternoonCardView.addSubview(afternoonSubtitleLabel)
      
      // Setup constraints for afternoon card
      NSLayoutConstraint.activate([
        afternoonCardView.widthAnchor.constraint(equalToConstant: 200),
        afternoonCardView.heightAnchor.constraint(equalToConstant: 280),
        
        afternoonBackgroundView.topAnchor.constraint(equalTo: afternoonCardView.topAnchor),
        afternoonBackgroundView.leadingAnchor.constraint(equalTo: afternoonCardView.leadingAnchor),
        afternoonBackgroundView.trailingAnchor.constraint(equalTo: afternoonCardView.trailingAnchor),
        afternoonBackgroundView.bottomAnchor.constraint(equalTo: afternoonCardView.bottomAnchor),
        
        afternoonImageView.centerXAnchor.constraint(equalTo: afternoonCardView.centerXAnchor),
        afternoonImageView.topAnchor.constraint(equalTo: afternoonCardView.topAnchor, constant: 40),
        afternoonImageView.widthAnchor.constraint(equalToConstant: 120),
        afternoonImageView.heightAnchor.constraint(equalToConstant: 120),
        
        afternoonTitleLabel.centerXAnchor.constraint(equalTo: afternoonCardView.centerXAnchor),
        afternoonTitleLabel.topAnchor.constraint(equalTo: afternoonImageView.bottomAnchor, constant: 20),
        afternoonTitleLabel.leadingAnchor.constraint(equalTo: afternoonCardView.leadingAnchor, constant: 10),
        afternoonTitleLabel.trailingAnchor.constraint(equalTo: afternoonCardView.trailingAnchor, constant: -10),
        
        afternoonSubtitleLabel.centerXAnchor.constraint(equalTo: afternoonCardView.centerXAnchor),
        afternoonSubtitleLabel.topAnchor.constraint(equalTo: afternoonTitleLabel.bottomAnchor, constant: 20),
        afternoonSubtitleLabel.leadingAnchor.constraint(equalTo: afternoonCardView.leadingAnchor, constant: 10),
        afternoonSubtitleLabel.trailingAnchor.constraint(equalTo: afternoonCardView.trailingAnchor, constant: -10)
      ])
      
      // Store mood name as the view's tag using hash value
      afternoonCardView.tag = "AfternoonChill".hashValue
      
      // Add tap gesture
      let afternoonTapGesture = UITapGestureRecognizer(target: radioVC, action: #selector(UIViewController.moodTapped(_:)))
      afternoonCardView.addGestureRecognizer(afternoonTapGesture)
      afternoonCardView.isUserInteractionEnabled = true
      
      // Add the card to the carousel
      morningStackView.addArrangedSubview(afternoonCardView)
      
      // Calculate and set the content size for proper scrolling
      let morningTotalWidth = CGFloat(2 * 215) // 200 width + 15 spacing
      
      // Set the content view's width constraint
      let morningWidthConstraint = morningContentView.widthAnchor.constraint(equalToConstant: morningTotalWidth)
      morningWidthConstraint.priority = .required
      morningWidthConstraint.isActive = true
      
      // Make sure content view's width can be greater than the scroll view's width
      let morningMinWidthConstraint = morningContentView.widthAnchor.constraint(greaterThanOrEqualTo: morningScrollView.widthAnchor)
      morningMinWidthConstraint.priority = .defaultHigh
      morningMinWidthConstraint.isActive = true
      
      // Force layout to ensure proper sizing
      morningScrollView.layoutIfNeeded()
      
      return radioVC
    case .new:
      let newVC = DiscoverMoreViewController()
      newVC.title = "Discover More"
      newVC.view.backgroundColor = .systemBackground
      
      // Set the tabBarItem directly to ensure consistent icons
      let newIcon = UIImage(systemName: "square.grid.2x2.fill") ?? UIImage()
      let newSelectedIcon = UIImage(systemName: "square.grid.2x2.fill") ?? UIImage()
      
      newVC.tabBarItem = UITabBarItem(
        title: self.title,
        image: newIcon,
        tag: self.rawValue
      )
      newVC.tabBarItem.selectedImage = newSelectedIcon
      
      // Create a scroll view to hold all content
      let scrollView = UIScrollView()
      scrollView.translatesAutoresizingMaskIntoConstraints = false
      newVC.view.addSubview(scrollView)
      
      // Create a stack view for the content
      let stackView = UIStackView()
      stackView.axis = .vertical
      stackView.spacing = 20
      stackView.translatesAutoresizingMaskIntoConstraints = false
      scrollView.addSubview(stackView)
      
      // Set references to the scroll view and stack view in the view controller
      newVC.mainScrollView = scrollView
      newVC.contentStackView = stackView
      
      // Carousel Section for Bollywood Albums
      let carouselLabel = UILabel()
      carouselLabel.text = "Latest in Bollywood"
      carouselLabel.font = .systemFont(ofSize: 20, weight: .bold)
      stackView.addArrangedSubview(carouselLabel)
      
      // Create a horizontal scroll view for the carousel
      let carouselScrollView = UIScrollView()
      carouselScrollView.showsHorizontalScrollIndicator = true
      carouselScrollView.translatesAutoresizingMaskIntoConstraints = false
      carouselScrollView.alwaysBounceHorizontal = true
      carouselScrollView.clipsToBounds = true
      stackView.addArrangedSubview(carouselScrollView)
      
      // Set fixed height for carousel based on 2 rows of albums
      carouselScrollView.heightAnchor.constraint(equalToConstant: 460).isActive = true // Increased from 360 to 460 to match Punjabi Grooves carousel
      
      // Create content view for the scroll view
      let contentView = UIView()
      contentView.translatesAutoresizingMaskIntoConstraints = false
      carouselScrollView.addSubview(contentView)
      
      // Setup content view constraints
      NSLayoutConstraint.activate([
        contentView.topAnchor.constraint(equalTo: carouselScrollView.topAnchor),
        contentView.leadingAnchor.constraint(equalTo: carouselScrollView.leadingAnchor),
        contentView.trailingAnchor.constraint(equalTo: carouselScrollView.trailingAnchor),
        contentView.bottomAnchor.constraint(equalTo: carouselScrollView.bottomAnchor),
        contentView.heightAnchor.constraint(equalTo: carouselScrollView.heightAnchor)
      ])
      
      // Create a horizontal stack view to hold carousel items
      let carouselStackView = UIStackView()
      carouselStackView.axis = .horizontal
      carouselStackView.spacing = 15
      carouselStackView.alignment = .center
      carouselStackView.translatesAutoresizingMaskIntoConstraints = false
      contentView.addSubview(carouselStackView)
      
      // Setup stack view constraints
      NSLayoutConstraint.activate([
        carouselStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
        carouselStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
        carouselStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
        carouselStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
      ])
      
      // Add a loading label
      let loadingLabel = UILabel()
      loadingLabel.text = "Loading Bollywood albums..."
      loadingLabel.textAlignment = .center
      loadingLabel.textColor = .systemGray
      carouselStackView.addArrangedSubview(loadingLabel)
      
      // Fetch albums from Bollywood genre
      Task { @MainActor in
        do {
          // Display loading indicator
          for view in carouselStackView.arrangedSubviews {
            if !(view is UILabel && (view as! UILabel).text == "Loading Bollywood albums...") {
              carouselStackView.removeArrangedSubview(view)
              view.removeFromSuperview()
            }
          }
          
          // Get the storage instance
        let storage = appDelegate.storage
          
          // Instead of trying to call a non-existent method
          // Check if we need to sync the library first
          if !storage.isLibrarySynced {
            try await appDelegate.librarySyncer.syncInitial(statusNotifyier: nil)
          }
          
          // Find and add Bollywood albums to the playlist
        let allAlbums = storage.main.library.getAlbums()
          let bollywoodAlbums = allAlbums.filter { 
            ($0.genre?.name.lowercased() == "bollywood") || 
            ($0.name.lowercased().contains("bollywood"))
          }
          
          // Sort albums to show recently added first, then follow chronological order
          let sortedBollywoodAlbums = bollywoodAlbums.sorted { album1, album2 in
            // First sort by newest (recently added)
            let newestIndex1 = album1.managedObject.newestIndex
            let newestIndex2 = album2.managedObject.newestIndex
            
            // If either has a newestIndex, prioritize non-zero values
            if newestIndex1 > 0 && newestIndex2 == 0 {
              return true // album1 comes first
            } else if newestIndex1 == 0 && newestIndex2 > 0 {
              return false // album2 comes first
            } else if newestIndex1 > 0 && newestIndex2 > 0 {
              return newestIndex1 < newestIndex2 // Standard newest sort
            }
            
            // Then fallback to chronological order by year
            let year1 = album1.managedObject.year
            let year2 = album2.managedObject.year
            if year1 != 0 || year2 != 0 {
              return year1 > year2
            }
            return album1.name < album2.name // Alphabetical as final fallback
          }
          
          // Clear loading indicator
          for view in carouselStackView.arrangedSubviews {
            carouselStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
          }
          
          if sortedBollywoodAlbums.isEmpty {
            // If no Bollywood albums found, show message
            let emptyLabel = UILabel()
            emptyLabel.text = "No Bollywood albums found in your library. Please sync your library or add Bollywood albums."
            emptyLabel.textAlignment = .center
            emptyLabel.textColor = .systemGray
            emptyLabel.numberOfLines = 0
            carouselStackView.addArrangedSubview(emptyLabel)
            
            // Add note on how to get Bollywood albums
            let noteLabel = UILabel()
            noteLabel.text = "To display Bollywood albums, tag your albums with the 'Bollywood' genre on your server."
            noteLabel.textAlignment = .center
            noteLabel.textColor = .systemBlue
            noteLabel.font = .systemFont(ofSize: 12)
            noteLabel.numberOfLines = 0
            stackView.addArrangedSubview(noteLabel)
          } else {
            // Create a container stack view that will hold two horizontal rows
            let containerStackView = UIStackView()
            containerStackView.axis = .vertical
            containerStackView.spacing = 15
            containerStackView.distribution = .fillEqually
            containerStackView.translatesAutoresizingMaskIntoConstraints = false
            carouselStackView.addArrangedSubview(containerStackView)
            
            // Create two horizontal stack views for the two rows
            let topRowStackView = UIStackView()
            topRowStackView.axis = .horizontal
            topRowStackView.spacing = 15
            topRowStackView.alignment = .center
            topRowStackView.translatesAutoresizingMaskIntoConstraints = false
            
            let bottomRowStackView = UIStackView()
            bottomRowStackView.axis = .horizontal
            bottomRowStackView.spacing = 15
            bottomRowStackView.alignment = .center
            bottomRowStackView.translatesAutoresizingMaskIntoConstraints = false
            
            // Add the rows to the container
            containerStackView.addArrangedSubview(topRowStackView)
            containerStackView.addArrangedSubview(bottomRowStackView)
            
            // Sort albums into two rows
            var currentRow = topRowStackView
            
            // Add the albums to the carousel - divide them between two rows
            for (index, album) in sortedBollywoodAlbums.enumerated() {
              // Alternate between top and bottom rows
              currentRow = index % 2 == 0 ? topRowStackView : bottomRowStackView
              
              let itemView = UIView()
              itemView.translatesAutoresizingMaskIntoConstraints = false
              // Set fixed size for the item - increased size to match Punjabi Grooves carousel
              itemView.widthAnchor.constraint(equalToConstant: 170).isActive = true
              // Ensure sufficient height for album cover, title and artist name
              itemView.heightAnchor.constraint(equalToConstant: 220).isActive = true
              
              // Album artwork
              let imageView = UIImageView()
              imageView.translatesAutoresizingMaskIntoConstraints = false
              imageView.backgroundColor = .systemGray5
              imageView.layer.cornerRadius = 6
              imageView.clipsToBounds = true
                imageView.contentMode = .scaleAspectFill
              
              // If artwork exists, use it, otherwise use placeholder
              if let artwork = album.artwork, let image = artwork.image {
                imageView.image = image
              } else {
                imageView.image = UIImage(systemName: "music.note")
                imageView.tintColor = .systemGray
              }
              
              // Title label
              let titleLabel = UILabel()
              titleLabel.translatesAutoresizingMaskIntoConstraints = false
              titleLabel.text = album.name
              titleLabel.font = .systemFont(ofSize: 14, weight: .medium) // Changed to match Punjabi Grooves
              titleLabel.textAlignment = .left 
              titleLabel.textColor = .label
              titleLabel.numberOfLines = 2 // Changed to match Punjabi Grooves
              titleLabel.lineBreakMode = .byTruncatingTail
              
              // Artist label - new addition
              let artistLabel = UILabel()
              artistLabel.translatesAutoresizingMaskIntoConstraints = false
              
              // Use the album's subtitle property which is defined to return artist name
              // This ensures consistency with how other views display artist information
              artistLabel.text = album.subtitle ?? album.artist?.name ?? "Unknown Artist"
              
              // Improve visibility of artist name
              artistLabel.font = .systemFont(ofSize: 12) // Updated to match Punjabi Grooves
              artistLabel.textColor = .secondaryLabel
              artistLabel.textAlignment = .left
              artistLabel.numberOfLines = 1
              artistLabel.lineBreakMode = .byTruncatingTail
              artistLabel.isHidden = false  // Ensure visibility
              
              // Add subviews to the item view
              itemView.addSubview(imageView)
              itemView.addSubview(titleLabel)
              itemView.addSubview(artistLabel)
              
              // Set up constraints for the image view and labels - increased image size to match Punjabi Grooves
              NSLayoutConstraint.activate([
                imageView.topAnchor.constraint(equalTo: itemView.topAnchor),
                imageView.leadingAnchor.constraint(equalTo: itemView.leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: itemView.trailingAnchor),
                imageView.heightAnchor.constraint(equalToConstant: 170),
                imageView.widthAnchor.constraint(equalToConstant: 170),
                
                titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 6), // Increased from 4 to 6
                titleLabel.leadingAnchor.constraint(equalTo: itemView.leadingAnchor, constant: 8), // Increased left padding
                titleLabel.trailingAnchor.constraint(equalTo: itemView.trailingAnchor, constant: -8), // Increased right padding
                
                artistLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4), // Increased from 2 to 4
                artistLabel.leadingAnchor.constraint(equalTo: itemView.leadingAnchor, constant: 8), // Increased left padding
                artistLabel.trailingAnchor.constraint(equalTo: itemView.trailingAnchor, constant: -8), // Increased right padding
                artistLabel.bottomAnchor.constraint(equalTo: itemView.bottomAnchor, constant: -6) // Increased padding from 4 to 6
              ])
              
              // Store album hashValue as tag - don't use byHashValue as it doesn't exist
              itemView.tag = album.managedObject.hashValue
              
              // Add tap gesture
              let tapGesture = UITapGestureRecognizer(target: newVC, action: #selector(UIViewController.albumTapped(_:)))
              itemView.addGestureRecognizer(tapGesture)
              itemView.isUserInteractionEnabled = true
              
              // Add the item to the current row stack
              currentRow.addArrangedSubview(itemView)
            }
            
            // Calculate and set the content size for proper scrolling - based on half the albums per row
            let albumsPerRow = Int(ceil(Double(sortedBollywoodAlbums.count) / 2.0))
            let totalWidth = CGFloat(albumsPerRow * 185) // 170 width + 15 spacing - matched with Punjabi Grooves
            
            // Critical: Set the content view's width - this is key to making horizontal scrolling work
            let contentWidthConstraint = contentView.widthAnchor.constraint(equalToConstant: totalWidth)
            contentWidthConstraint.priority = .required
            contentWidthConstraint.isActive = true
            
            // Make sure content view's width can be greater than the scroll view's width
            // This is what enables scrolling
            let contentMinWidthConstraint = contentView.widthAnchor.constraint(greaterThanOrEqualTo: carouselScrollView.widthAnchor)
            contentMinWidthConstraint.priority = .defaultHigh
            contentMinWidthConstraint.isActive = true
            
            // Force layout to ensure proper sizing
            carouselScrollView.layoutIfNeeded()
          }
        } catch {
          // Clear any existing views
          for view in carouselStackView.arrangedSubviews {
            carouselStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
          }
          
          // Show error message
          let errorLabel = UILabel()
          errorLabel.text = "Error fetching Bollywood albums: \(error.localizedDescription)"
          errorLabel.textAlignment = .center
          errorLabel.numberOfLines = 0
          errorLabel.textColor = .systemRed
          carouselStackView.addArrangedSubview(errorLabel)
          
          print("Error fetching Bollywood albums: \(error)")
        }
      }
      
      // Apple-style Mood Cards Section
      let moodSectionLabel = UILabel()
      moodSectionLabel.text = "Browse by Mood"
      moodSectionLabel.font = .systemFont(ofSize: 20, weight: .bold)
      stackView.addArrangedSubview(moodSectionLabel)
      
      // Create a scroll view for the mood cards
      let moodScrollView = UIScrollView()
      moodScrollView.showsHorizontalScrollIndicator = true
      moodScrollView.translatesAutoresizingMaskIntoConstraints = false
      moodScrollView.alwaysBounceHorizontal = true
      moodScrollView.clipsToBounds = true
      stackView.addArrangedSubview(moodScrollView)
      
      // Set fixed height for the mood scroll view
      moodScrollView.heightAnchor.constraint(equalToConstant: 180).isActive = true
      
      // Create content view for the mood scroll view
      let moodContentView = UIView()
      moodContentView.translatesAutoresizingMaskIntoConstraints = false
      moodScrollView.addSubview(moodContentView)
      
      // Setup content view constraints
      NSLayoutConstraint.activate([
        moodContentView.topAnchor.constraint(equalTo: moodScrollView.topAnchor),
        moodContentView.leadingAnchor.constraint(equalTo: moodScrollView.leadingAnchor),
        moodContentView.trailingAnchor.constraint(equalTo: moodScrollView.trailingAnchor),
        moodContentView.bottomAnchor.constraint(equalTo: moodScrollView.bottomAnchor),
        moodContentView.heightAnchor.constraint(equalTo: moodScrollView.heightAnchor)
      ])
      
      // Create a horizontal stack view to hold mood cards
      let moodStackView = UIStackView()
      moodStackView.axis = .horizontal
      moodStackView.spacing = 15
      moodStackView.alignment = .center
      moodStackView.translatesAutoresizingMaskIntoConstraints = false
      moodContentView.addSubview(moodStackView)
      
      // Setup stack view constraints
      NSLayoutConstraint.activate([
        moodStackView.topAnchor.constraint(equalTo: moodContentView.topAnchor, constant: 10),
        moodStackView.leadingAnchor.constraint(equalTo: moodContentView.leadingAnchor, constant: 15),
        moodStackView.trailingAnchor.constraint(equalTo: moodContentView.trailingAnchor, constant: -15),
        moodStackView.bottomAnchor.constraint(equalTo: moodContentView.bottomAnchor, constant: -10)
      ])
      
      // Define the moods with their colors and icons
      let moods: [(name: String, gradient: [UIColor], icon: String)] = [
        ("Chill", [UIColor.systemTeal, UIColor.systemBlue], "cloud.sun.fill"),
        ("Workout", [UIColor.systemRed, UIColor.systemOrange], "bolt.fill"),
        ("Focus", [UIColor.systemPurple, UIColor.systemIndigo], "brain.head.profile"),
        ("Party", [UIColor.systemPink, UIColor.systemRed], "music.note.list"),
        ("Relaxing", [UIColor.systemGreen, UIColor.systemTeal], "leaf.fill"),
        ("Romantic", [UIColor.systemPink, UIColor.systemPurple], "heart.fill")
      ]
      
      // Create mood cards
      for mood in moods {
        // Create a container view for the mood card
        let cardView = UIView()
        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.layer.cornerRadius = 16
        cardView.clipsToBounds = true
        
        // Set width and height constraints
        cardView.widthAnchor.constraint(equalToConstant: 150).isActive = true
        cardView.heightAnchor.constraint(equalToConstant: 150).isActive = true
        
        // Create gradient layer
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = mood.gradient.map { $0.cgColor }
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        gradientLayer.frame = CGRect(x: 0, y: 0, width: 150, height: 150)
        cardView.layer.insertSublayer(gradientLayer, at: 0)
        
        // Add a subtle pattern overlay for texture
        let patternView = UIView()
        patternView.translatesAutoresizingMaskIntoConstraints = false
        patternView.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        cardView.addSubview(patternView)
        
              NSLayoutConstraint.activate([
          patternView.topAnchor.constraint(equalTo: cardView.topAnchor),
          patternView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
          patternView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
          patternView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor)
        ])
        
        // Create the icon view
        let iconView = UIImageView()
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.image = UIImage(systemName: mood.icon)
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = .white
        cardView.addSubview(iconView)
              
              // Create the title label
              let titleLabel = UILabel()
              titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = mood.name
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        titleLabel.textAlignment = .center
        cardView.addSubview(titleLabel)
        
        // Layout constraints
              NSLayoutConstraint.activate([
          iconView.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
          iconView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor, constant: -15),
          iconView.widthAnchor.constraint(equalToConstant: 50),
          iconView.heightAnchor.constraint(equalToConstant: 50),
          
          titleLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 8),
          titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 8),
          titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -8),
        ])
        
        // Store mood name as tag (using hashValue to avoid direct string storage)
        cardView.tag = mood.name.hashValue
              
              // Add tap gesture
        let tapGesture = UITapGestureRecognizer(target: newVC, action: #selector(UIViewController.moodTapped(_:)))
        cardView.addGestureRecognizer(tapGesture)
        cardView.isUserInteractionEnabled = true
        
        // Add the card to the stack view
        moodStackView.addArrangedSubview(cardView)
      }
      
      // Calculate and set the content size for proper scrolling
      let totalMoodWidth = CGFloat(moods.count * 165) // 150 width + 15 spacing
      
      // Set the content view's width to enable horizontal scrolling
      let moodContentWidthConstraint = moodContentView.widthAnchor.constraint(equalToConstant: totalMoodWidth)
      moodContentWidthConstraint.priority = .required
      moodContentWidthConstraint.isActive = true
            
            // Make sure content view's width can be greater than the scroll view's width
      let moodContentMinWidthConstraint = moodContentView.widthAnchor.constraint(greaterThanOrEqualTo: moodScrollView.widthAnchor)
      moodContentMinWidthConstraint.priority = .defaultHigh
      moodContentMinWidthConstraint.isActive = true
            
            // Force layout to ensure proper sizing
      moodScrollView.layoutIfNeeded()
      
      // Classic Bollywood Carousel Section
      let classicCarouselLabel = UILabel()
      classicCarouselLabel.text = "Classic Bollywood"
      classicCarouselLabel.font = .systemFont(ofSize: 20, weight: .bold)
      stackView.addArrangedSubview(classicCarouselLabel)
      
      // Create a horizontal scroll view for the classic carousel
      let classicCarouselScrollView = UIScrollView()
      classicCarouselScrollView.showsHorizontalScrollIndicator = true
      classicCarouselScrollView.translatesAutoresizingMaskIntoConstraints = false
      classicCarouselScrollView.alwaysBounceHorizontal = true
      classicCarouselScrollView.clipsToBounds = true
      stackView.addArrangedSubview(classicCarouselScrollView)
      
      // Set fixed height for the carousel - increased to accommodate two rows
      classicCarouselScrollView.heightAnchor.constraint(equalToConstant: 460).isActive = true
      
      // Create content view for the scroll view
      let classicContentView = UIView()
      classicContentView.translatesAutoresizingMaskIntoConstraints = false
      classicCarouselScrollView.addSubview(classicContentView)
      
      // Setup content view constraints
      NSLayoutConstraint.activate([
        classicContentView.topAnchor.constraint(equalTo: classicCarouselScrollView.topAnchor),
        classicContentView.leadingAnchor.constraint(equalTo: classicCarouselScrollView.leadingAnchor),
        classicContentView.trailingAnchor.constraint(equalTo: classicCarouselScrollView.trailingAnchor),
        classicContentView.bottomAnchor.constraint(equalTo: classicCarouselScrollView.bottomAnchor),
        classicContentView.heightAnchor.constraint(equalTo: classicCarouselScrollView.heightAnchor)
      ])
      
      // Create a horizontal stack view to hold carousel items
      let classicCarouselStackView = UIStackView()
      classicCarouselStackView.axis = .horizontal
      classicCarouselStackView.spacing = 15
      classicCarouselStackView.alignment = .center
      classicCarouselStackView.translatesAutoresizingMaskIntoConstraints = false
      classicContentView.addSubview(classicCarouselStackView)
      
      // Setup stack view constraints
      NSLayoutConstraint.activate([
        classicCarouselStackView.topAnchor.constraint(equalTo: classicContentView.topAnchor, constant: 10),
        classicCarouselStackView.leadingAnchor.constraint(equalTo: classicContentView.leadingAnchor, constant: 10),
        classicCarouselStackView.trailingAnchor.constraint(equalTo: classicContentView.trailingAnchor, constant: -10),
        classicCarouselStackView.bottomAnchor.constraint(equalTo: classicContentView.bottomAnchor, constant: -10)
      ])
      
      // Add a loading label
      let classicLoadingLabel = UILabel()
      classicLoadingLabel.text = "Loading Classic Bollywood albums..."
      classicLoadingLabel.textAlignment = .center
      classicLoadingLabel.textColor = .systemGray
      classicCarouselStackView.addArrangedSubview(classicLoadingLabel)
      
      // Fetch albums with genre "Filmi"
      Task { @MainActor in
        do {
          // Display loading indicator
          for view in classicCarouselStackView.arrangedSubviews {
            if !(view is UILabel && (view as! UILabel).text == "Loading Classic Bollywood albums...") {
              classicCarouselStackView.removeArrangedSubview(view)
              view.removeFromSuperview()
            }
          }
          
          // Get the storage instance
          let storage = appDelegate.storage
          
          // Check if we need to sync the library first
          if !storage.isLibrarySynced {
            try await appDelegate.librarySyncer.syncInitial(statusNotifyier: nil)
          }
          
          // Find and add Filmi albums to the carousel
          let allAlbums = storage.main.library.getAlbums()
          let filmyAlbums = allAlbums.filter { 
            ($0.genre?.name.lowercased() == "filmi") || 
            ($0.name.lowercased().contains("filmi"))
          }
          
          // Sort albums to show recently added first, then follow chronological order
          let sortedFilmyAlbums = filmyAlbums.sorted { album1, album2 in
            // First sort by newest (recently added)
            let newestIndex1 = album1.managedObject.newestIndex
            let newestIndex2 = album2.managedObject.newestIndex
            
            // If either has a newestIndex, prioritize non-zero values
            if newestIndex1 > 0 && newestIndex2 == 0 {
              return true // album1 comes first
            } else if newestIndex1 == 0 && newestIndex2 > 0 {
              return false // album2 comes first
            } else if newestIndex1 > 0 && newestIndex2 > 0 {
              return newestIndex1 < newestIndex2 // Standard newest sort
            }
            
            // Then fallback to chronological order by year
            let year1 = album1.managedObject.year
            let year2 = album2.managedObject.year
            if year1 != 0 || year2 != 0 {
              return year1 > year2
            }
            return album1.name < album2.name // Alphabetical as final fallback
          }
          
          // Clear loading indicator
          for view in classicCarouselStackView.arrangedSubviews {
            classicCarouselStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
          }
          
          if sortedFilmyAlbums.isEmpty {
            // If no Filmi albums found, show message
            let emptyLabel = UILabel()
            emptyLabel.text = "No Classic Bollywood albums found in your library. Please sync your library or add albums with 'Filmi' genre."
            emptyLabel.textAlignment = .center
            emptyLabel.textColor = .systemGray
            emptyLabel.numberOfLines = 0
            classicCarouselStackView.addArrangedSubview(emptyLabel)
            
            // Add note on how to get Filmi albums
            let noteLabel = UILabel()
            noteLabel.text = "To display Classic Bollywood albums, tag your albums with the 'Filmi' genre on your server."
            noteLabel.textAlignment = .center
            noteLabel.textColor = .systemBlue
            noteLabel.font = .systemFont(ofSize: 12)
            noteLabel.numberOfLines = 0
            stackView.addArrangedSubview(noteLabel)
          } else {
            // Create a container stack view that will hold two horizontal rows
            let classicContainerStackView = UIStackView()
            classicContainerStackView.axis = .vertical
            classicContainerStackView.spacing = 15
            classicContainerStackView.distribution = .fillEqually
            classicContainerStackView.translatesAutoresizingMaskIntoConstraints = false
            classicCarouselStackView.addArrangedSubview(classicContainerStackView)
            
            // Create two horizontal stack views for the two rows
            let classicTopRowStackView = UIStackView()
            classicTopRowStackView.axis = .horizontal
            classicTopRowStackView.spacing = 15
            classicTopRowStackView.alignment = .center
            classicTopRowStackView.translatesAutoresizingMaskIntoConstraints = false
            
            let classicBottomRowStackView = UIStackView()
            classicBottomRowStackView.axis = .horizontal
            classicBottomRowStackView.spacing = 15
            classicBottomRowStackView.alignment = .center
            classicBottomRowStackView.translatesAutoresizingMaskIntoConstraints = false
            
            // Add the rows to the container
            classicContainerStackView.addArrangedSubview(classicTopRowStackView)
            classicContainerStackView.addArrangedSubview(classicBottomRowStackView)
            
            // Sort albums into two rows
            var currentRow = classicTopRowStackView
            
            // Add the albums to the carousel - divide them between two rows
            for (index, album) in sortedFilmyAlbums.enumerated() {
              // Switch to bottom row after half the albums
              if index == Int(ceil(Double(sortedFilmyAlbums.count) / 2.0)) {
                currentRow = classicBottomRowStackView
              }
              
              let itemView = UIView()
              itemView.translatesAutoresizingMaskIntoConstraints = false
              // Set fixed size for the item - increased size to match Punjabi Grooves carousel
              itemView.heightAnchor.constraint(equalToConstant: 220).isActive = true
              itemView.widthAnchor.constraint(equalToConstant: 170).isActive = true
              
              // Album artwork
              let imageView = UIImageView()
              imageView.translatesAutoresizingMaskIntoConstraints = false
              imageView.backgroundColor = .systemGray5
              imageView.layer.cornerRadius = 8
              imageView.clipsToBounds = true
              imageView.contentMode = .scaleAspectFill
              
              // If artwork exists, use it, otherwise use placeholder
              if let artwork = album.artwork, let image = artwork.image {
                imageView.image = image
              } else {
                imageView.image = UIImage(systemName: "music.note")
                imageView.tintColor = .systemGray
              }
              
              itemView.addSubview(imageView)
              
              // Create title label with limited height to avoid overflow
              let titleLabel = UILabel()
              titleLabel.translatesAutoresizingMaskIntoConstraints = false
              titleLabel.text = album.name
              titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
              titleLabel.textAlignment = .left
              titleLabel.textColor = .label
              titleLabel.numberOfLines = 2
              titleLabel.lineBreakMode = .byTruncatingTail
              
              // Artist label
              let artistLabel = UILabel()
              artistLabel.translatesAutoresizingMaskIntoConstraints = false
              
              // Use the album's subtitle property which is defined to return artist name
              // This ensures consistency with how other views display artist information
              artistLabel.text = album.subtitle ?? album.artist?.name ?? "Unknown Artist"
              
              // Improve visibility of artist name
              artistLabel.font = .systemFont(ofSize: 12)
              artistLabel.textColor = .secondaryLabel
              artistLabel.textAlignment = .left
              artistLabel.numberOfLines = 1
              artistLabel.lineBreakMode = .byTruncatingTail
              artistLabel.isHidden = false
              
              // Add subviews to the item view
              itemView.addSubview(imageView)
              itemView.addSubview(titleLabel)
              itemView.addSubview(artistLabel)
              
              
              // Set up constraints for the image view and labels - increased image size to match Punjabi Grooves
              NSLayoutConstraint.activate([
                imageView.topAnchor.constraint(equalTo: itemView.topAnchor),
                imageView.leadingAnchor.constraint(equalTo: itemView.leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: itemView.trailingAnchor),
                imageView.heightAnchor.constraint(equalToConstant: 170),
                imageView.widthAnchor.constraint(equalToConstant: 170),
                
                titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 6),
                titleLabel.leadingAnchor.constraint(equalTo: itemView.leadingAnchor, constant: 8),
                titleLabel.trailingAnchor.constraint(equalTo: itemView.trailingAnchor, constant: -8),
                
                artistLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
                artistLabel.leadingAnchor.constraint(equalTo: itemView.leadingAnchor, constant: 8),
                artistLabel.trailingAnchor.constraint(equalTo: itemView.trailingAnchor, constant: -8),
                artistLabel.bottomAnchor.constraint(equalTo: itemView.bottomAnchor, constant: -6)
              ])
              
              // Store album hashValue as tag
              itemView.tag = album.managedObject.hashValue
              
              // Add tap gesture
              let tapGesture = UITapGestureRecognizer(target: newVC, action: #selector(UIViewController.albumTapped(_:)))
              itemView.addGestureRecognizer(tapGesture)
              itemView.isUserInteractionEnabled = true
              
              // Add the item to the current row stack
              currentRow.addArrangedSubview(itemView)
            }
            
            // Calculate and set the content size for proper scrolling - based on half the albums per row
            let albumsPerRow = Int(ceil(Double(sortedFilmyAlbums.count) / 2.0))
            let totalWidth = CGFloat(albumsPerRow * 185) // 170 width + 15 spacing - matched with Punjabi Grooves
            
            // Critical: Set the content view's width - this is key to making horizontal scrolling work
            let contentWidthConstraint = classicContentView.widthAnchor.constraint(equalToConstant: totalWidth)
            contentWidthConstraint.priority = .required
            contentWidthConstraint.isActive = true
            
            // Make sure content view's width can be greater than the scroll view's width
            // This is what enables scrolling
            let contentMinWidthConstraint = classicContentView.widthAnchor.constraint(greaterThanOrEqualTo: classicCarouselScrollView.widthAnchor)
            contentMinWidthConstraint.priority = .defaultHigh
            contentMinWidthConstraint.isActive = true
            
            // Force layout to ensure proper sizing
            classicCarouselScrollView.layoutIfNeeded()
          }
        } catch {
          // Clear any existing views
          for view in classicCarouselStackView.arrangedSubviews {
            classicCarouselStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
          }
          
          // Show error message
          let errorLabel = UILabel()
          errorLabel.text = "Error fetching Classic Bollywood albums: \(error.localizedDescription)"
          errorLabel.textAlignment = .center
          errorLabel.numberOfLines = 0
          errorLabel.textColor = .systemRed
          classicCarouselStackView.addArrangedSubview(errorLabel)
          
          print("Error fetching Classic Bollywood albums: \(error)")
        }
      }
      
      // Old is Gold Carousel Section
      let oldIsGoldCarouselLabel = UILabel()
      oldIsGoldCarouselLabel.text = "Old is Gold"
      oldIsGoldCarouselLabel.font = .systemFont(ofSize: 20, weight: .bold)
      stackView.addArrangedSubview(oldIsGoldCarouselLabel)
      
      // Create a horizontal scroll view for the Old is Gold carousel
      let oldIsGoldCarouselScrollView = UIScrollView()
      oldIsGoldCarouselScrollView.showsHorizontalScrollIndicator = true
      oldIsGoldCarouselScrollView.translatesAutoresizingMaskIntoConstraints = false
      oldIsGoldCarouselScrollView.alwaysBounceHorizontal = true
      oldIsGoldCarouselScrollView.clipsToBounds = true
      stackView.addArrangedSubview(oldIsGoldCarouselScrollView)
      
      // Set fixed height for the carousel - matching the Punjabi Grooves for consistency
      oldIsGoldCarouselScrollView.heightAnchor.constraint(equalToConstant: 460).isActive = true
      
      // Create content view for the scroll view
      let oldIsGoldContentView = UIView()
      oldIsGoldContentView.translatesAutoresizingMaskIntoConstraints = false
      oldIsGoldCarouselScrollView.addSubview(oldIsGoldContentView)
      
      // Setup content view constraints
      NSLayoutConstraint.activate([
        oldIsGoldContentView.topAnchor.constraint(equalTo: oldIsGoldCarouselScrollView.topAnchor),
        oldIsGoldContentView.leadingAnchor.constraint(equalTo: oldIsGoldCarouselScrollView.leadingAnchor),
        oldIsGoldContentView.trailingAnchor.constraint(equalTo: oldIsGoldCarouselScrollView.trailingAnchor),
        oldIsGoldContentView.bottomAnchor.constraint(equalTo: oldIsGoldCarouselScrollView.bottomAnchor),
        oldIsGoldContentView.heightAnchor.constraint(equalTo: oldIsGoldCarouselScrollView.heightAnchor)
      ])
      
      // Create a horizontal stack view to hold carousel items
      let oldIsGoldCarouselStackView = UIStackView()
      oldIsGoldCarouselStackView.axis = .horizontal
      oldIsGoldCarouselStackView.spacing = 15
      oldIsGoldCarouselStackView.alignment = .center
      oldIsGoldCarouselStackView.translatesAutoresizingMaskIntoConstraints = false
      oldIsGoldContentView.addSubview(oldIsGoldCarouselStackView)
      
      // Setup stack view constraints
      NSLayoutConstraint.activate([
        oldIsGoldCarouselStackView.topAnchor.constraint(equalTo: oldIsGoldContentView.topAnchor, constant: 10),
        oldIsGoldCarouselStackView.leadingAnchor.constraint(equalTo: oldIsGoldContentView.leadingAnchor, constant: 10),
        oldIsGoldCarouselStackView.trailingAnchor.constraint(equalTo: oldIsGoldContentView.trailingAnchor, constant: -10),
        oldIsGoldCarouselStackView.bottomAnchor.constraint(equalTo: oldIsGoldContentView.bottomAnchor, constant: -10)
      ])
      
      // Add a loading label
      let oldIsGoldLoadingLabel = UILabel()
      oldIsGoldLoadingLabel.text = "Loading Old is Gold albums..."
      oldIsGoldLoadingLabel.textAlignment = .center
      oldIsGoldLoadingLabel.textColor = .systemGray
      oldIsGoldCarouselStackView.addArrangedSubview(oldIsGoldLoadingLabel)
      
      // Fetch albums with genre "Old is Gold"
      Task { @MainActor in
        do {
          // Display loading indicator
          for view in oldIsGoldCarouselStackView.arrangedSubviews {
            if !(view is UILabel && (view as! UILabel).text == "Loading Old is Gold albums...") {
              oldIsGoldCarouselStackView.removeArrangedSubview(view)
              view.removeFromSuperview()
            }
          }
          
          // Get the storage instance
          let storage = appDelegate.storage
          
          // Check if we need to sync the library first
          if !storage.isLibrarySynced {
            try await appDelegate.librarySyncer.syncInitial(statusNotifyier: nil)
          }
          
          // Find and add Old is Gold albums to the carousel
          let allAlbums = storage.main.library.getAlbums()
          let oldIsGoldAlbums = allAlbums.filter { 
            ($0.genre?.name.lowercased() == "old is gold") || 
            ($0.genre?.name.lowercased() == "oldies") ||
            ($0.genre?.name.lowercased() == "retro")
          }
          
          // Sort albums to show recently added first, then follow chronological order
          let sortedOldIsGoldAlbums = oldIsGoldAlbums.sorted { album1, album2 in
            // First sort by newest (recently added)
            let newestIndex1 = album1.managedObject.newestIndex
            let newestIndex2 = album2.managedObject.newestIndex
            
            // If either has a newestIndex, prioritize non-zero values
            if newestIndex1 > 0 && newestIndex2 == 0 {
              return true // album1 comes first
            } else if newestIndex1 == 0 && newestIndex2 > 0 {
              return false // album2 comes first
            } else if newestIndex1 > 0 && newestIndex2 > 0 {
              return newestIndex1 < newestIndex2 // Standard newest sort
            }
            
            // Then fallback to chronological order by year
            let year1 = album1.managedObject.year
            let year2 = album2.managedObject.year
            if year1 != 0 || year2 != 0 {
              return year1 > year2
            }
            return album1.name < album2.name // Alphabetical as final fallback
          }
          
          // Clear loading indicator
          for view in oldIsGoldCarouselStackView.arrangedSubviews {
            oldIsGoldCarouselStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
          }
          
          if sortedOldIsGoldAlbums.isEmpty {
            // If no Old is Gold albums found, show message
            let emptyLabel = UILabel()
            emptyLabel.text = "No Old is Gold albums found in your library. Please sync your library or add albums with 'Old is Gold', 'Oldies' or 'Retro' genre."
            emptyLabel.textAlignment = .center
            emptyLabel.textColor = .systemGray
            emptyLabel.numberOfLines = 0
            oldIsGoldCarouselStackView.addArrangedSubview(emptyLabel)
            
            // Add note on how to get Old is Gold albums
            let noteLabel = UILabel()
            noteLabel.text = "To display Old is Gold albums, tag your albums with the 'Old is Gold', 'Oldies' or 'Retro' genre on your server."
            noteLabel.textAlignment = .center
            noteLabel.textColor = .systemBlue
            noteLabel.font = .systemFont(ofSize: 12)
            noteLabel.numberOfLines = 0
            stackView.addArrangedSubview(noteLabel)
          } else {
            // Create a container stack view that will hold two horizontal rows
            let oldIsGoldContainerStackView = UIStackView()
            oldIsGoldContainerStackView.axis = .vertical
            oldIsGoldContainerStackView.spacing = 15
            oldIsGoldContainerStackView.distribution = .fillEqually
            oldIsGoldContainerStackView.translatesAutoresizingMaskIntoConstraints = false
            oldIsGoldCarouselStackView.addArrangedSubview(oldIsGoldContainerStackView)
            
            // Create two horizontal stack views for the two rows
            let oldIsGoldTopRowStackView = UIStackView()
            oldIsGoldTopRowStackView.axis = .horizontal
            oldIsGoldTopRowStackView.spacing = 15
            oldIsGoldTopRowStackView.alignment = .center
            oldIsGoldTopRowStackView.translatesAutoresizingMaskIntoConstraints = false
            
            let oldIsGoldBottomRowStackView = UIStackView()
            oldIsGoldBottomRowStackView.axis = .horizontal
            oldIsGoldBottomRowStackView.spacing = 15
            oldIsGoldBottomRowStackView.alignment = .center
            oldIsGoldBottomRowStackView.translatesAutoresizingMaskIntoConstraints = false
            
            // Add the rows to the container
            oldIsGoldContainerStackView.addArrangedSubview(oldIsGoldTopRowStackView)
            oldIsGoldContainerStackView.addArrangedSubview(oldIsGoldBottomRowStackView)
            
            // Sort albums into two rows
            var currentRow = oldIsGoldTopRowStackView
            
            // Add the albums to the carousel - divide them between two rows
            for (index, album) in sortedOldIsGoldAlbums.enumerated() {
              // Switch to bottom row after half the albums
              if index == Int(ceil(Double(sortedOldIsGoldAlbums.count) / 2.0)) {
                currentRow = oldIsGoldBottomRowStackView
              }
              
              // Create a container view for each album
              let itemView = UIView()
              itemView.translatesAutoresizingMaskIntoConstraints = false
              
              // Set fixed size for the item - matching Punjabi Grooves carousel
              itemView.heightAnchor.constraint(equalToConstant: 220).isActive = true
              itemView.widthAnchor.constraint(equalToConstant: 170).isActive = true
              
              // Create the image view for album artwork
              let imageView = UIImageView()
              imageView.translatesAutoresizingMaskIntoConstraints = false
              imageView.contentMode = .scaleAspectFill
              imageView.clipsToBounds = true
              imageView.layer.cornerRadius = 8
              
              // If artwork exists, use it, otherwise use placeholder
              if let artwork = album.artwork, let image = artwork.image {
                imageView.image = image
              } else {
                imageView.image = UIImage(systemName: "music.note")
                imageView.tintColor = .systemGray
              }
              
              itemView.addSubview(imageView)
              
              // Create title label with limited height to avoid overflow
              let titleLabel = UILabel()
              titleLabel.translatesAutoresizingMaskIntoConstraints = false
              titleLabel.text = album.name
              titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
              titleLabel.textColor = .label
              titleLabel.numberOfLines = 2
              titleLabel.textAlignment = .left
              itemView.addSubview(titleLabel)
              
              // Create artist label
              let artistLabel = UILabel()
              artistLabel.translatesAutoresizingMaskIntoConstraints = false
              artistLabel.text = album.artist?.name ?? "Unknown Artist"
              artistLabel.font = .systemFont(ofSize: 12)
              artistLabel.textColor = .secondaryLabel
              artistLabel.numberOfLines = 1
              artistLabel.textAlignment = .left
              itemView.addSubview(artistLabel)
              
              // Set up constraints - matching Punjabi Grooves carousel
              NSLayoutConstraint.activate([
                imageView.topAnchor.constraint(equalTo: itemView.topAnchor),
                imageView.leadingAnchor.constraint(equalTo: itemView.leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: itemView.trailingAnchor),
                imageView.heightAnchor.constraint(equalToConstant: 170),
                imageView.widthAnchor.constraint(equalToConstant: 170),
                
                titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 6),
                titleLabel.leadingAnchor.constraint(equalTo: itemView.leadingAnchor, constant: 8),
                titleLabel.trailingAnchor.constraint(equalTo: itemView.trailingAnchor, constant: -8),
                
                artistLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
                artistLabel.leadingAnchor.constraint(equalTo: itemView.leadingAnchor, constant: 8),
                artistLabel.trailingAnchor.constraint(equalTo: itemView.trailingAnchor, constant: -8),
                artistLabel.bottomAnchor.constraint(equalTo: itemView.bottomAnchor, constant: -6)
              ])
              
              // Store album hashValue as tag
              itemView.tag = album.managedObject.hashValue
              
              // Add tap gesture
              let tapGesture = UITapGestureRecognizer(target: newVC, action: #selector(UIViewController.albumTapped(_:)))
              itemView.addGestureRecognizer(tapGesture)
              itemView.isUserInteractionEnabled = true
              
              // Add the item to the current row stack
              currentRow.addArrangedSubview(itemView)
            }
            
            // Calculate and set the content size for proper scrolling - based on half the albums per row
            let albumsPerRow = Int(ceil(Double(sortedOldIsGoldAlbums.count) / 2.0))
            let totalWidth = CGFloat(albumsPerRow * 185) // 170 width + 15 spacing - matching Punjabi Grooves
            
            // Critical: Set the content view's width - this is key to making horizontal scrolling work
            let contentWidthConstraint = oldIsGoldContentView.widthAnchor.constraint(equalToConstant: totalWidth)
            contentWidthConstraint.priority = .required
            contentWidthConstraint.isActive = true
            
            // Make sure content view's width can be greater than the scroll view's width
            // This is what enables scrolling
            let contentMinWidthConstraint = oldIsGoldContentView.widthAnchor.constraint(greaterThanOrEqualTo: oldIsGoldCarouselScrollView.widthAnchor)
            contentMinWidthConstraint.priority = .defaultHigh
            contentMinWidthConstraint.isActive = true
            
            // Force layout to ensure proper sizing
            oldIsGoldCarouselScrollView.layoutIfNeeded()
          }
        } catch {
          // Clear any existing views
          for view in oldIsGoldCarouselStackView.arrangedSubviews {
            oldIsGoldCarouselStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
          }
          
          // Show error message
          let errorLabel = UILabel()
          errorLabel.text = "Error fetching Old is Gold albums: \(error.localizedDescription)"
          errorLabel.textAlignment = .center
          errorLabel.numberOfLines = 0
          errorLabel.textColor = .systemRed
          oldIsGoldCarouselStackView.addArrangedSubview(errorLabel)
          
          print("Error fetching Old is Gold albums: \(error)")
        }
      }
      
      // Ghazals Carousel Section
      let ghazalsCarouselLabel = UILabel()
      ghazalsCarouselLabel.text = "Ghazals"
      ghazalsCarouselLabel.font = .systemFont(ofSize: 20, weight: .bold)
      stackView.addArrangedSubview(ghazalsCarouselLabel)
      
      // Create a horizontal scroll view for the ghazals carousel
      let ghazalsCarouselScrollView = UIScrollView()
      ghazalsCarouselScrollView.showsHorizontalScrollIndicator = true
      ghazalsCarouselScrollView.translatesAutoresizingMaskIntoConstraints = false
      ghazalsCarouselScrollView.alwaysBounceHorizontal = true
      ghazalsCarouselScrollView.clipsToBounds = true
      stackView.addArrangedSubview(ghazalsCarouselScrollView)
      
      // Set fixed height for the carousel - increased to accommodate two rows 
      ghazalsCarouselScrollView.heightAnchor.constraint(equalToConstant: 460).isActive = true
      
      // Create content view for the scroll view
      let ghazalsContentView = UIView()
      ghazalsContentView.translatesAutoresizingMaskIntoConstraints = false
      ghazalsCarouselScrollView.addSubview(ghazalsContentView)
      
      // Setup content view constraints
      NSLayoutConstraint.activate([
        ghazalsContentView.topAnchor.constraint(equalTo: ghazalsCarouselScrollView.topAnchor),
        ghazalsContentView.leadingAnchor.constraint(equalTo: ghazalsCarouselScrollView.leadingAnchor),
        ghazalsContentView.trailingAnchor.constraint(equalTo: ghazalsCarouselScrollView.trailingAnchor),
        ghazalsContentView.bottomAnchor.constraint(equalTo: ghazalsCarouselScrollView.bottomAnchor),
        ghazalsContentView.heightAnchor.constraint(equalTo: ghazalsCarouselScrollView.heightAnchor)
      ])
      
      // Create a horizontal stack view to hold carousel items
      let ghazalsCarouselStackView = UIStackView()
      ghazalsCarouselStackView.axis = .horizontal
      ghazalsCarouselStackView.spacing = 15
      ghazalsCarouselStackView.alignment = .center
      ghazalsCarouselStackView.translatesAutoresizingMaskIntoConstraints = false
      ghazalsContentView.addSubview(ghazalsCarouselStackView)
      
      // Setup stack view constraints
      NSLayoutConstraint.activate([
        ghazalsCarouselStackView.topAnchor.constraint(equalTo: ghazalsContentView.topAnchor, constant: 10),
        ghazalsCarouselStackView.leadingAnchor.constraint(equalTo: ghazalsContentView.leadingAnchor, constant: 10),
        ghazalsCarouselStackView.trailingAnchor.constraint(equalTo: ghazalsContentView.trailingAnchor, constant: -10),
        ghazalsCarouselStackView.bottomAnchor.constraint(equalTo: ghazalsContentView.bottomAnchor, constant: -10)
      ])
      
      // Add a loading label
      let ghazalsLoadingLabel = UILabel()
      ghazalsLoadingLabel.text = "Loading Ghazals albums..."
      ghazalsLoadingLabel.textAlignment = .center
      ghazalsLoadingLabel.textColor = .systemGray
      ghazalsCarouselStackView.addArrangedSubview(ghazalsLoadingLabel)
      
      // Fetch albums with genre "Ghazals"
      Task { @MainActor in
        do {
          // Display loading indicator
          for view in ghazalsCarouselStackView.arrangedSubviews {
            if !(view is UILabel && (view as! UILabel).text == "Loading Ghazals albums...") {
              ghazalsCarouselStackView.removeArrangedSubview(view)
              view.removeFromSuperview()
            }
          }
          
          // Get the storage instance
          let storage = appDelegate.storage
          
          // Check if we need to sync the library first
          if !storage.isLibrarySynced {
            try await appDelegate.librarySyncer.syncInitial(statusNotifyier: nil)
          }
          
          // Find and add Ghazals albums to the carousel
          let allAlbums = storage.main.library.getAlbums()
          let ghazalsAlbums = allAlbums.filter { 
            ($0.genre?.name.lowercased() == "ghazals") || 
            ($0.name.lowercased().contains("ghazal"))
          }
          
          // Sort albums to show recently added first, then follow chronological order
          let sortedGhazalsAlbums = ghazalsAlbums.sorted { album1, album2 in
            // First sort by newest (recently added)
            let newestIndex1 = album1.managedObject.newestIndex
            let newestIndex2 = album2.managedObject.newestIndex
            
            // If either has a newestIndex, prioritize non-zero values
            if newestIndex1 > 0 && newestIndex2 == 0 {
              return true // album1 comes first
            } else if newestIndex1 == 0 && newestIndex2 > 0 {
              return false // album2 comes first
            } else if newestIndex1 > 0 && newestIndex2 > 0 {
              return newestIndex1 < newestIndex2 // Standard newest sort
            }
            
            // Then fallback to chronological order by year
            let year1 = album1.managedObject.year
            let year2 = album2.managedObject.year
            if year1 != 0 || year2 != 0 {
              return year1 > year2
            }
            return album1.name < album2.name // Alphabetical as final fallback
          }
          
          // Clear loading indicator
          for view in ghazalsCarouselStackView.arrangedSubviews {
            ghazalsCarouselStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
          }
          
          if sortedGhazalsAlbums.isEmpty {
            // If no Ghazals albums found, show message
            let emptyLabel = UILabel()
            emptyLabel.text = "No Ghazals albums found in your library. Please sync your library or add albums with 'Ghazals' genre."
            emptyLabel.textAlignment = .center
            emptyLabel.textColor = .systemGray
            emptyLabel.numberOfLines = 0
            ghazalsCarouselStackView.addArrangedSubview(emptyLabel)
            
            // Add note on how to get Ghazals albums
            let noteLabel = UILabel()
            noteLabel.text = "To display Ghazals albums, tag your albums with the 'Ghazals' genre on your server."
            noteLabel.textAlignment = .center
            noteLabel.textColor = .systemBlue
            noteLabel.font = .systemFont(ofSize: 12)
            noteLabel.numberOfLines = 0
            stackView.addArrangedSubview(noteLabel)
          } else {
            // Create a container stack view that will hold two horizontal rows
            let ghazalsContainerStackView = UIStackView()
            ghazalsContainerStackView.axis = .vertical
            ghazalsContainerStackView.spacing = 15
            ghazalsContainerStackView.distribution = .fillEqually
            ghazalsContainerStackView.translatesAutoresizingMaskIntoConstraints = false
            ghazalsCarouselStackView.addArrangedSubview(ghazalsContainerStackView)
            
            // Create two horizontal stack views for the two rows
            let ghazalsTopRowStackView = UIStackView()
            ghazalsTopRowStackView.axis = .horizontal
            ghazalsTopRowStackView.spacing = 15
            ghazalsTopRowStackView.alignment = .center
            ghazalsTopRowStackView.translatesAutoresizingMaskIntoConstraints = false
            
            let ghazalsBottomRowStackView = UIStackView()
            ghazalsBottomRowStackView.axis = .horizontal
            ghazalsBottomRowStackView.spacing = 15
            ghazalsBottomRowStackView.alignment = .center
            ghazalsBottomRowStackView.translatesAutoresizingMaskIntoConstraints = false
            
            // Add the rows to the container
            ghazalsContainerStackView.addArrangedSubview(ghazalsTopRowStackView)
            ghazalsContainerStackView.addArrangedSubview(ghazalsBottomRowStackView)
            
            // Sort albums into two rows
            var currentRow = ghazalsTopRowStackView
            
            // Add the albums to the carousel - divide them between two rows
            for (index, album) in sortedGhazalsAlbums.enumerated() {
              // Alternate between top and bottom rows
              currentRow = index % 2 == 0 ? ghazalsTopRowStackView : ghazalsBottomRowStackView
              
              let itemView = UIView()
              itemView.translatesAutoresizingMaskIntoConstraints = false
              // Set fixed size for the item - increased size to match Punjabi Grooves carousel
              itemView.heightAnchor.constraint(equalToConstant: 220).isActive = true
              itemView.widthAnchor.constraint(equalToConstant: 170).isActive = true
              
              // Album artwork
              let imageView = UIImageView()
              imageView.translatesAutoresizingMaskIntoConstraints = false
              imageView.contentMode = .scaleAspectFill
              imageView.clipsToBounds = true
              imageView.layer.cornerRadius = 8
              
              // If artwork exists, use it, otherwise use placeholder
              if let artwork = album.artwork, let image = artwork.image {
                imageView.image = image
              } else {
                imageView.image = UIImage(systemName: "music.note")
              }
              
              itemView.addSubview(imageView)
              
              // Create title label with limited height to avoid overflow
              let titleLabel = UILabel()
              titleLabel.translatesAutoresizingMaskIntoConstraints = false
              titleLabel.text = album.name
              titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
              titleLabel.textColor = .label
              titleLabel.numberOfLines = 2
              titleLabel.textAlignment = .left
              itemView.addSubview(titleLabel)
              
              // Create artist label
              let artistLabel = UILabel()
              artistLabel.translatesAutoresizingMaskIntoConstraints = false
              artistLabel.text = album.artist?.name ?? "Unknown Artist"
              artistLabel.font = .systemFont(ofSize: 12)
              artistLabel.textColor = .secondaryLabel
              artistLabel.numberOfLines = 1
              artistLabel.textAlignment = .left
              itemView.addSubview(artistLabel)
              
              // Set up constraints - increased image size to match Punjabi Grooves carousel
              NSLayoutConstraint.activate([
                imageView.topAnchor.constraint(equalTo: itemView.topAnchor),
                imageView.leadingAnchor.constraint(equalTo: itemView.leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: itemView.trailingAnchor),
                imageView.heightAnchor.constraint(equalToConstant: 170),
                imageView.widthAnchor.constraint(equalToConstant: 170),
                
                titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 6),
                titleLabel.leadingAnchor.constraint(equalTo: itemView.leadingAnchor, constant: 8),
                titleLabel.trailingAnchor.constraint(equalTo: itemView.trailingAnchor, constant: -8),
                
                artistLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
                artistLabel.leadingAnchor.constraint(equalTo: itemView.leadingAnchor, constant: 8),
                artistLabel.trailingAnchor.constraint(equalTo: itemView.trailingAnchor, constant: -8),
                artistLabel.bottomAnchor.constraint(equalTo: itemView.bottomAnchor, constant: -6)
              ])
              
              // Store album hashValue as tag
              itemView.tag = album.managedObject.hashValue
              
              // Add tap gesture
              let tapGesture = UITapGestureRecognizer(target: newVC, action: #selector(UIViewController.albumTapped(_:)))
              itemView.addGestureRecognizer(tapGesture)
              itemView.isUserInteractionEnabled = true
              
              // Add the item to the current row stack
              currentRow.addArrangedSubview(itemView)
            }
            
            // Calculate and set the content size for proper scrolling - based on half the albums per row
            let albumsPerRow = Int(ceil(Double(sortedGhazalsAlbums.count) / 2.0))
            let totalWidth = CGFloat(albumsPerRow * 185) // 170 width + 15 spacing - updated to match Punjabi Grooves
            
            
            // Critical: Set the content view's width - this is key to making horizontal scrolling work
            let contentWidthConstraint = ghazalsContentView.widthAnchor.constraint(equalToConstant: totalWidth)
            contentWidthConstraint.priority = .required
            contentWidthConstraint.isActive = true
            
            // Make sure content view's width can be greater than the scroll view's width
            // This is what enables scrolling
            let contentMinWidthConstraint = ghazalsContentView.widthAnchor.constraint(greaterThanOrEqualTo: ghazalsCarouselScrollView.widthAnchor)
            contentMinWidthConstraint.priority = .defaultHigh
            contentMinWidthConstraint.isActive = true
            
            // Force layout to ensure proper sizing
            ghazalsCarouselScrollView.layoutIfNeeded()
          }
        } catch {
          // Clear any existing views
          for view in ghazalsCarouselStackView.arrangedSubviews {
            ghazalsCarouselStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
          }
          
          // Show error message
          let errorLabel = UILabel()
          errorLabel.text = "Error fetching Ghazals albums: \(error.localizedDescription)"
          errorLabel.textAlignment = .center
          errorLabel.numberOfLines = 0
          errorLabel.textColor = .systemRed
          ghazalsCarouselStackView.addArrangedSubview(errorLabel)
          
          print("Error fetching Ghazals albums: \(error)")
        }
      }
      
      // Jatbeats Special Carousel Section
      let jatbeatsCarouselLabel = UILabel()
      jatbeatsCarouselLabel.text = "Jatbeats Special"
      jatbeatsCarouselLabel.font = .systemFont(ofSize: 20, weight: .bold)
      stackView.addArrangedSubview(jatbeatsCarouselLabel)
      
      // Create a horizontal scroll view for the jatbeats carousel
      let jatbeatsCarouselScrollView = UIScrollView()
      jatbeatsCarouselScrollView.showsHorizontalScrollIndicator = true
      jatbeatsCarouselScrollView.translatesAutoresizingMaskIntoConstraints = false
      jatbeatsCarouselScrollView.alwaysBounceHorizontal = true
      jatbeatsCarouselScrollView.clipsToBounds = true
      stackView.addArrangedSubview(jatbeatsCarouselScrollView)
      
      // Set fixed height for the carousel - increased to accommodate two rows
      jatbeatsCarouselScrollView.heightAnchor.constraint(equalToConstant: 460).isActive = true
      
      // Create content view for the scroll view
      let jatbeatsContentView = UIView()
      jatbeatsContentView.translatesAutoresizingMaskIntoConstraints = false
      jatbeatsCarouselScrollView.addSubview(jatbeatsContentView)
      
      // Setup content view constraints
      NSLayoutConstraint.activate([
        jatbeatsContentView.topAnchor.constraint(equalTo: jatbeatsCarouselScrollView.topAnchor),
        jatbeatsContentView.leadingAnchor.constraint(equalTo: jatbeatsCarouselScrollView.leadingAnchor),
        jatbeatsContentView.trailingAnchor.constraint(equalTo: jatbeatsCarouselScrollView.trailingAnchor),
        jatbeatsContentView.bottomAnchor.constraint(equalTo: jatbeatsCarouselScrollView.bottomAnchor),
        jatbeatsContentView.heightAnchor.constraint(equalTo: jatbeatsCarouselScrollView.heightAnchor)
      ])
      
      // Create a horizontal stack view to hold carousel items
      let jatbeatsCarouselStackView = UIStackView()
      jatbeatsCarouselStackView.axis = .horizontal
      jatbeatsCarouselStackView.spacing = 15
      jatbeatsCarouselStackView.alignment = .center
      jatbeatsCarouselStackView.translatesAutoresizingMaskIntoConstraints = false
      jatbeatsContentView.addSubview(jatbeatsCarouselStackView)
      
      // Setup stack view constraints
      NSLayoutConstraint.activate([
        jatbeatsCarouselStackView.topAnchor.constraint(equalTo: jatbeatsContentView.topAnchor, constant: 10),
        jatbeatsCarouselStackView.leadingAnchor.constraint(equalTo: jatbeatsContentView.leadingAnchor, constant: 10),
        jatbeatsCarouselStackView.trailingAnchor.constraint(equalTo: jatbeatsContentView.trailingAnchor, constant: -10),
        jatbeatsCarouselStackView.bottomAnchor.constraint(equalTo: jatbeatsContentView.bottomAnchor, constant: -10)
      ])
      
      // Add a loading label
      let jatbeatsLoadingLabel = UILabel()
      jatbeatsLoadingLabel.text = "Loading Haryanvi albums..."
      jatbeatsLoadingLabel.textAlignment = .center
      jatbeatsLoadingLabel.textColor = .systemGray
      jatbeatsCarouselStackView.addArrangedSubview(jatbeatsLoadingLabel)
      
      // Fetch albums with genre "Haryanvi"
      Task { @MainActor in
        do {
          // Display loading indicator
          for view in jatbeatsCarouselStackView.arrangedSubviews {
            if !(view is UILabel && (view as! UILabel).text == "Loading Haryanvi albums...") {
              jatbeatsCarouselStackView.removeArrangedSubview(view)
              view.removeFromSuperview()
            }
          }
          
          // Get the storage instance
          let storage = appDelegate.storage
          
          // Check if we need to sync the library first
          if !storage.isLibrarySynced {
            try await appDelegate.librarySyncer.syncInitial(statusNotifyier: nil)
          }
          
          // Find and add Haryanvi albums to the carousel
          let allAlbums = storage.main.library.getAlbums()
          let haryanviAlbums = allAlbums.filter { 
            ($0.genre?.name.lowercased() == "haryanvi")
          }
          
          // Sort albums to show recently added first, then follow chronological order
          let sortedHaryanviAlbums = haryanviAlbums.sorted { album1, album2 in
            // First sort by newest (recently added)
            let newestIndex1 = album1.managedObject.newestIndex
            let newestIndex2 = album2.managedObject.newestIndex
            
            // If either has a newestIndex, prioritize non-zero values
            if newestIndex1 > 0 && newestIndex2 == 0 {
              return true // album1 comes first
            } else if newestIndex1 == 0 && newestIndex2 > 0 {
              return false // album2 comes first
            } else if newestIndex1 > 0 && newestIndex2 > 0 {
              return newestIndex1 < newestIndex2 // Standard newest sort
            }
            
            // Then fallback to chronological order by year
            let year1 = album1.managedObject.year
            let year2 = album2.managedObject.year
            if year1 != 0 || year2 != 0 {
              return year1 > year2
            }
            return album1.name < album2.name // Alphabetical as final fallback
          }
          
          // Clear loading indicator
          for view in jatbeatsCarouselStackView.arrangedSubviews {
            jatbeatsCarouselStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
          }
          
          if sortedHaryanviAlbums.isEmpty {
            // If no Haryanvi albums found, show message
            let emptyLabel = UILabel()
            emptyLabel.text = "No Haryanvi albums found in your library. Please sync your library or add albums with 'Haryanvi' genre."
            emptyLabel.textAlignment = .center
            emptyLabel.textColor = .systemGray
            emptyLabel.numberOfLines = 0
            jatbeatsCarouselStackView.addArrangedSubview(emptyLabel)
            
            // Add note on how to get Haryanvi albums
            let noteLabel = UILabel()
            noteLabel.text = "To display Haryanvi albums, tag your albums with the 'Haryanvi' genre on your server."
            noteLabel.textAlignment = .center
            noteLabel.textColor = .systemBlue
            noteLabel.font = .systemFont(ofSize: 12)
            noteLabel.numberOfLines = 0
            stackView.addArrangedSubview(noteLabel)
          } else {
            // Create a container stack view that will hold two horizontal rows
            let jatbeatsContainerStackView = UIStackView()
            jatbeatsContainerStackView.axis = .vertical
            jatbeatsContainerStackView.spacing = 15
            jatbeatsContainerStackView.distribution = .fillEqually
            jatbeatsContainerStackView.translatesAutoresizingMaskIntoConstraints = false
            jatbeatsCarouselStackView.addArrangedSubview(jatbeatsContainerStackView)
            
            // Create two horizontal stack views for the two rows
            let jatbeatsTopRowStackView = UIStackView()
            jatbeatsTopRowStackView.axis = .horizontal
            jatbeatsTopRowStackView.spacing = 15
            jatbeatsTopRowStackView.alignment = .center
            jatbeatsTopRowStackView.translatesAutoresizingMaskIntoConstraints = false
            
            let jatbeatsBottomRowStackView = UIStackView()
            jatbeatsBottomRowStackView.axis = .horizontal
            jatbeatsBottomRowStackView.spacing = 15
            jatbeatsBottomRowStackView.alignment = .center
            jatbeatsBottomRowStackView.translatesAutoresizingMaskIntoConstraints = false
            
            // Add the rows to the container
            jatbeatsContainerStackView.addArrangedSubview(jatbeatsTopRowStackView)
            jatbeatsContainerStackView.addArrangedSubview(jatbeatsBottomRowStackView)
            
            // Sort albums into two rows
            var currentRow = jatbeatsTopRowStackView
            
            // Add the albums to the carousel - divide them between two rows
            for (index, album) in sortedHaryanviAlbums.enumerated() {
              // Switch to second row for half the albums
              if index == Int(ceil(Double(sortedHaryanviAlbums.count) / 2.0)) {
                currentRow = jatbeatsBottomRowStackView
              }
              
              // Create container for each album item
              let itemView = UIView()
              itemView.translatesAutoresizingMaskIntoConstraints = false
              
              // Set fixed size for the item - increased size to match Punjabi Grooves carousel
              itemView.heightAnchor.constraint(equalToConstant: 220).isActive = true
              itemView.widthAnchor.constraint(equalToConstant: 170).isActive = true
              
              // Create the image view for album artwork
              let imageView = UIImageView()
              imageView.translatesAutoresizingMaskIntoConstraints = false
              imageView.contentMode = .scaleAspectFill
              imageView.clipsToBounds = true
              imageView.layer.cornerRadius = 8
              
              // If artwork exists, use it, otherwise use placeholder
              if let artwork = album.artwork, let image = artwork.image {
                imageView.image = image
              } else {
                imageView.image = UIImage(systemName: "music.note")
                imageView.tintColor = .systemGray2
              }
              
              itemView.addSubview(imageView)
              
              // Create title label with limited height to avoid overflow
              let titleLabel = UILabel()
              titleLabel.translatesAutoresizingMaskIntoConstraints = false
              titleLabel.text = album.name
              titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
              titleLabel.textColor = .label
              titleLabel.numberOfLines = 2
              titleLabel.lineBreakMode = .byTruncatingTail
              itemView.addSubview(titleLabel)
              
              // Create artist label
              let artistLabel = UILabel()
              artistLabel.translatesAutoresizingMaskIntoConstraints = false
              artistLabel.text = album.subtitle ?? album.artist?.name ?? "Unknown Artist"
              artistLabel.font = .systemFont(ofSize: 12)
              artistLabel.textColor = .secondaryLabel
              artistLabel.textAlignment = .left
              artistLabel.numberOfLines = 1
              artistLabel.lineBreakMode = .byTruncatingTail
              itemView.addSubview(artistLabel)
              
              // Set up constraints - increased image size to match Punjabi Grooves carousel
              NSLayoutConstraint.activate([
                imageView.topAnchor.constraint(equalTo: itemView.topAnchor),
                imageView.leadingAnchor.constraint(equalTo: itemView.leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: itemView.trailingAnchor),
                imageView.heightAnchor.constraint(equalToConstant: 170),
                imageView.widthAnchor.constraint(equalToConstant: 170),
                
                titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 6),
                titleLabel.leadingAnchor.constraint(equalTo: itemView.leadingAnchor, constant: 8),
                titleLabel.trailingAnchor.constraint(equalTo: itemView.trailingAnchor, constant: -8),
                artistLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
                artistLabel.leadingAnchor.constraint(equalTo: itemView.leadingAnchor, constant: 8),
                artistLabel.trailingAnchor.constraint(equalTo: itemView.trailingAnchor, constant: -8),
                artistLabel.bottomAnchor.constraint(equalTo: itemView.bottomAnchor, constant: -6)
              ])
              
              // Store album hashValue as tag
              itemView.tag = album.managedObject.hashValue
              
              // Add tap gesture
              let tapGesture = UITapGestureRecognizer(target: newVC, action: #selector(UIViewController.albumTapped(_:)))
              itemView.addGestureRecognizer(tapGesture)
              itemView.isUserInteractionEnabled = true
              
              // Add the item to the current row stack
              currentRow.addArrangedSubview(itemView)
            }
            
            // Calculate and set the content size for proper scrolling - based on half the albums per row
            let albumsPerRow = Int(ceil(Double(sortedHaryanviAlbums.count) / 2.0))
            let totalWidth = CGFloat(albumsPerRow * 185) // 170 width + 15 spacing - updated to match Punjabi Grooves
            
            // Critical: Set the content view's width - this is key to making horizontal scrolling work
            let contentWidthConstraint = jatbeatsContentView.widthAnchor.constraint(equalToConstant: totalWidth)
            contentWidthConstraint.priority = .required
            contentWidthConstraint.isActive = true
            
            // Make sure content view's width can be greater than the scroll view's width
            // This is what enables scrolling
            let contentMinWidthConstraint = jatbeatsContentView.widthAnchor.constraint(greaterThanOrEqualTo: jatbeatsCarouselScrollView.widthAnchor)
            contentMinWidthConstraint.priority = .defaultHigh
            contentMinWidthConstraint.isActive = true
            
            // Force layout to ensure proper sizing
            jatbeatsCarouselScrollView.layoutIfNeeded()
          }
        } catch {
          // Clear any existing views
          for view in jatbeatsCarouselStackView.arrangedSubviews {
            jatbeatsCarouselStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
          }
          
          // Show error message
          let errorLabel = UILabel()
          errorLabel.text = "Error fetching Haryanvi albums: \(error.localizedDescription)"
          errorLabel.textAlignment = .center
          errorLabel.numberOfLines = 0
          errorLabel.textColor = .systemRed
          jatbeatsCarouselStackView.addArrangedSubview(errorLabel)
          
          print("Error fetching Haryanvi albums: \(error)")
        }
      }
      
      // 80's Disco Fever : NonStop Carousel Section
      let discoCarouselLabel = UILabel()
      discoCarouselLabel.text = "80's Disco Fever : NonStop"
      discoCarouselLabel.font = .systemFont(ofSize: 20, weight: .bold)
      stackView.addArrangedSubview(discoCarouselLabel)
      
      // Create a horizontal scroll view for the disco carousel
      let discoCarouselScrollView = UIScrollView()
      discoCarouselScrollView.showsHorizontalScrollIndicator = true
      discoCarouselScrollView.translatesAutoresizingMaskIntoConstraints = false
      discoCarouselScrollView.alwaysBounceHorizontal = true
      discoCarouselScrollView.clipsToBounds = true
      stackView.addArrangedSubview(discoCarouselScrollView)
      
      // Set fixed height for the carousel - increased to accommodate two rows
      discoCarouselScrollView.heightAnchor.constraint(equalToConstant: 460).isActive = true
      
      // Create content view for the scroll view
      let discoContentView = UIView()
      discoContentView.translatesAutoresizingMaskIntoConstraints = false
      discoCarouselScrollView.addSubview(discoContentView)
      
      // Setup content view constraints
      NSLayoutConstraint.activate([
        discoContentView.topAnchor.constraint(equalTo: discoCarouselScrollView.topAnchor),
        discoContentView.leadingAnchor.constraint(equalTo: discoCarouselScrollView.leadingAnchor),
        discoContentView.trailingAnchor.constraint(equalTo: discoCarouselScrollView.trailingAnchor),
        discoContentView.bottomAnchor.constraint(equalTo: discoCarouselScrollView.bottomAnchor),
        discoContentView.heightAnchor.constraint(equalTo: discoCarouselScrollView.heightAnchor)
      ])
      
      // Create a horizontal stack view to hold carousel items
      let discoCarouselStackView = UIStackView()
      discoCarouselStackView.axis = .horizontal
      discoCarouselStackView.spacing = 15
      discoCarouselStackView.alignment = .center
      discoCarouselStackView.translatesAutoresizingMaskIntoConstraints = false
      discoContentView.addSubview(discoCarouselStackView)
      
      // Setup stack view constraints
      NSLayoutConstraint.activate([
        discoCarouselStackView.topAnchor.constraint(equalTo: discoContentView.topAnchor, constant: 10),
        discoCarouselStackView.leadingAnchor.constraint(equalTo: discoContentView.leadingAnchor, constant: 10),
        discoCarouselStackView.trailingAnchor.constraint(equalTo: discoContentView.trailingAnchor, constant: -10),
        discoCarouselStackView.bottomAnchor.constraint(equalTo: discoContentView.bottomAnchor, constant: -10)
      ])
      
      // Add a loading label
      let discoLoadingLabel = UILabel()
      discoLoadingLabel.text = "Loading NonStop Disco albums..."
      discoLoadingLabel.textAlignment = .center
      discoLoadingLabel.textColor = .systemGray
      discoCarouselStackView.addArrangedSubview(discoLoadingLabel)
      
      // Fetch albums with genre "Nonstop"
      Task { @MainActor in
        do {
          // Display loading indicator
          for view in discoCarouselStackView.arrangedSubviews {
            if !(view is UILabel && (view as! UILabel).text == "Loading NonStop Disco albums...") {
              discoCarouselStackView.removeArrangedSubview(view)
              view.removeFromSuperview()
            }
          }
          
          // Get the storage instance
          let storage = appDelegate.storage
          
          // Check if we need to sync the library first
          if !storage.isLibrarySynced {
            try await appDelegate.librarySyncer.syncInitial(statusNotifyier: nil)
          }
          
          // Find and add NonStop albums to the carousel
          let allAlbums = storage.main.library.getAlbums()
          let discoAlbums = allAlbums.filter { 
            ($0.genre?.name.lowercased() == "nonstop")
          }
          
          // Sort albums to show recently added first, then follow chronological order
          let sortedDiscoAlbums = discoAlbums.sorted { album1, album2 in
            // First sort by newest (recently added)
            let newestIndex1 = album1.managedObject.newestIndex
            let newestIndex2 = album2.managedObject.newestIndex
            
            // If either has a newestIndex, prioritize non-zero values
            if newestIndex1 > 0 && newestIndex2 == 0 {
              return true // album1 comes first
            } else if newestIndex1 == 0 && newestIndex2 > 0 {
              return false // album2 comes first
            } else if newestIndex1 > 0 && newestIndex2 > 0 {
              return newestIndex1 < newestIndex2 // Standard newest sort
            }
            
            // Then fallback to chronological order by year
            let year1 = album1.managedObject.year
            let year2 = album2.managedObject.year
            if year1 != 0 || year2 != 0 {
              return year1 > year2
            }
            return album1.name < album2.name // Alphabetical as final fallback
          }
          
          // Clear loading indicator
          for view in discoCarouselStackView.arrangedSubviews {
            discoCarouselStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
          }
          
          if sortedDiscoAlbums.isEmpty {
            // If no NonStop albums found, show message
            let emptyLabel = UILabel()
            emptyLabel.text = "No NonStop Disco albums found in your library. Please sync your library or add albums with 'Nonstop' genre."
            emptyLabel.textAlignment = .center
            emptyLabel.textColor = .systemGray
            emptyLabel.numberOfLines = 0
            discoCarouselStackView.addArrangedSubview(emptyLabel)
            
            // Add note on how to get NonStop albums
            let noteLabel = UILabel()
            noteLabel.text = "To display NonStop Disco albums, tag your albums with the 'Nonstop' genre on your server."
            noteLabel.textAlignment = .center
            noteLabel.textColor = .systemBlue
            noteLabel.font = .systemFont(ofSize: 12)
            noteLabel.numberOfLines = 0
            stackView.addArrangedSubview(noteLabel)
          } else {
            // Create a container stack view that will hold two horizontal rows
            let discoContainerStackView = UIStackView()
            discoContainerStackView.axis = .vertical
            discoContainerStackView.spacing = 15
            discoContainerStackView.distribution = .fillEqually
            discoContainerStackView.translatesAutoresizingMaskIntoConstraints = false
            discoCarouselStackView.addArrangedSubview(discoContainerStackView)
            
            // Create two horizontal stack views for the two rows
            let discoTopRowStackView = UIStackView()
            discoTopRowStackView.axis = .horizontal
            discoTopRowStackView.spacing = 15
            discoTopRowStackView.alignment = .center
            discoTopRowStackView.translatesAutoresizingMaskIntoConstraints = false
            
            let discoBottomRowStackView = UIStackView()
            discoBottomRowStackView.axis = .horizontal
            discoBottomRowStackView.spacing = 15
            discoBottomRowStackView.alignment = .center
            discoBottomRowStackView.translatesAutoresizingMaskIntoConstraints = false
            
            // Add the rows to the container
            discoContainerStackView.addArrangedSubview(discoTopRowStackView)
            discoContainerStackView.addArrangedSubview(discoBottomRowStackView)
            
            // Sort albums into two rows
            var currentRow = discoTopRowStackView
            
            // Add the albums to the carousel - divide them between two rows
            for (index, album) in sortedDiscoAlbums.enumerated() {
              // Switch to bottom row after half the albums
              if index == Int(ceil(Double(sortedDiscoAlbums.count) / 2.0)) {
                currentRow = discoBottomRowStackView
              }
              
              // Create a container view for each album
              let itemView = UIView()
              itemView.translatesAutoresizingMaskIntoConstraints = false
              
              // Set fixed size for the item - increased size to match Punjabi Grooves carousel
              itemView.heightAnchor.constraint(equalToConstant: 220).isActive = true
              itemView.widthAnchor.constraint(equalToConstant: 170).isActive = true
              
              // Create the image view for album artwork
              let imageView = UIImageView()
              imageView.translatesAutoresizingMaskIntoConstraints = false
              imageView.contentMode = .scaleAspectFill
              imageView.clipsToBounds = true
              imageView.layer.cornerRadius = 8
              
              // If artwork exists, use it, otherwise use placeholder
              if let artwork = album.artwork, let image = artwork.image {
                imageView.image = image
              } else {
                imageView.image = UIImage(systemName: "music.note")
              }
              
              itemView.addSubview(imageView)
              
              // Create title label with limited height to avoid overflow
              let titleLabel = UILabel()
              titleLabel.translatesAutoresizingMaskIntoConstraints = false
              titleLabel.text = album.name
              titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
              titleLabel.textColor = .label
              titleLabel.numberOfLines = 2
              titleLabel.textAlignment = .left
              itemView.addSubview(titleLabel)
              
              // Create artist label
              let artistLabel = UILabel()
              artistLabel.translatesAutoresizingMaskIntoConstraints = false
              artistLabel.text = album.artist?.name ?? "Unknown Artist"
              artistLabel.font = .systemFont(ofSize: 12)
              artistLabel.textColor = .secondaryLabel
              artistLabel.numberOfLines = 1
              artistLabel.textAlignment = .left
              itemView.addSubview(artistLabel)
              
              // Set up constraints - increased image size to match Punjabi Grooves carousel
              NSLayoutConstraint.activate([
                imageView.topAnchor.constraint(equalTo: itemView.topAnchor),
                imageView.leadingAnchor.constraint(equalTo: itemView.leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: itemView.trailingAnchor),
                imageView.heightAnchor.constraint(equalToConstant: 170),
                imageView.widthAnchor.constraint(equalToConstant: 170),
                
                titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 6),
                titleLabel.leadingAnchor.constraint(equalTo: itemView.leadingAnchor, constant: 8),
                titleLabel.trailingAnchor.constraint(equalTo: itemView.trailingAnchor, constant: -8),
                
                artistLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
                artistLabel.leadingAnchor.constraint(equalTo: itemView.leadingAnchor, constant: 8),
                artistLabel.trailingAnchor.constraint(equalTo: itemView.trailingAnchor, constant: -8),
                artistLabel.bottomAnchor.constraint(equalTo: itemView.bottomAnchor, constant: -6)
              ])
              
              // Store album hashValue as tag
              itemView.tag = album.managedObject.hashValue
              
              // Add tap gesture
              let tapGesture = UITapGestureRecognizer(target: newVC, action: #selector(UIViewController.albumTapped(_:)))
              itemView.addGestureRecognizer(tapGesture)
              itemView.isUserInteractionEnabled = true
              
              // Add the item to the current row stack
              currentRow.addArrangedSubview(itemView)
            }
            
            // Calculate and set the content size for proper scrolling - based on half the albums per row
            let albumsPerRow = Int(ceil(Double(sortedDiscoAlbums.count) / 2.0))
            let totalWidth = CGFloat(albumsPerRow * 185) // 170 width + 15 spacing - updated to match Punjabi Grooves
            
            // Critical: Set the content view's width - this is key to making horizontal scrolling work
            let contentWidthConstraint = discoContentView.widthAnchor.constraint(equalToConstant: totalWidth)
            contentWidthConstraint.priority = .required
            contentWidthConstraint.isActive = true
            
            // Make sure content view's width can be greater than the scroll view's width
            // This is what enables scrolling
            let contentMinWidthConstraint = discoContentView.widthAnchor.constraint(greaterThanOrEqualTo: discoCarouselScrollView.widthAnchor)
            contentMinWidthConstraint.priority = .defaultHigh
            contentMinWidthConstraint.isActive = true
            
            // Force layout to ensure proper sizing
            discoCarouselScrollView.layoutIfNeeded()
          }
        } catch {
          // Clear any existing views
          for view in discoCarouselStackView.arrangedSubviews {
            discoCarouselStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
          }
          
          // Show error message
          let errorLabel = UILabel()
          errorLabel.text = "Error fetching NonStop Disco albums: \(error.localizedDescription)"
          errorLabel.textAlignment = .center
          errorLabel.numberOfLines = 0
          errorLabel.textColor = .systemRed
          discoCarouselStackView.addArrangedSubview(errorLabel)
          
          print("Error fetching NonStop Disco albums: \(error)")
        }
      }
      
      // Punjabi Grooves Carousel Section
      let punjabiCarouselLabel = UILabel()
      punjabiCarouselLabel.text = "Punjabi Grooves"
      punjabiCarouselLabel.font = .systemFont(ofSize: 20, weight: .bold)
      stackView.addArrangedSubview(punjabiCarouselLabel)
      
      // Create a horizontal scroll view for the Punjabi Grooves carousel
      let punjabiCarouselScrollView = UIScrollView()
      punjabiCarouselScrollView.showsHorizontalScrollIndicator = true
      punjabiCarouselScrollView.translatesAutoresizingMaskIntoConstraints = false
      punjabiCarouselScrollView.alwaysBounceHorizontal = true
      punjabiCarouselScrollView.clipsToBounds = true
      stackView.addArrangedSubview(punjabiCarouselScrollView)
      
      // Set fixed height for the carousel - increased to accommodate larger album cards
      punjabiCarouselScrollView.heightAnchor.constraint(equalToConstant: 460).isActive = true
      
      // Create content view for the scroll view
      let punjabiContentView = UIView()
      punjabiContentView.translatesAutoresizingMaskIntoConstraints = false
      punjabiCarouselScrollView.addSubview(punjabiContentView)
      
      // Setup content view constraints
      NSLayoutConstraint.activate([
        punjabiContentView.topAnchor.constraint(equalTo: punjabiCarouselScrollView.topAnchor),
        punjabiContentView.leadingAnchor.constraint(equalTo: punjabiCarouselScrollView.leadingAnchor),
        punjabiContentView.trailingAnchor.constraint(equalTo: punjabiCarouselScrollView.trailingAnchor),
        punjabiContentView.bottomAnchor.constraint(equalTo: punjabiCarouselScrollView.bottomAnchor),
        punjabiContentView.heightAnchor.constraint(equalTo: punjabiCarouselScrollView.heightAnchor)
      ])
      
      // Create a horizontal stack view to hold carousel items
      let punjabiCarouselStackView = UIStackView()
      punjabiCarouselStackView.axis = .horizontal
      punjabiCarouselStackView.spacing = 15
      punjabiCarouselStackView.alignment = .center
      punjabiCarouselStackView.translatesAutoresizingMaskIntoConstraints = false
      punjabiContentView.addSubview(punjabiCarouselStackView)
      
      // Setup stack view constraints
      NSLayoutConstraint.activate([
        punjabiCarouselStackView.topAnchor.constraint(equalTo: punjabiContentView.topAnchor, constant: 10),
        punjabiCarouselStackView.leadingAnchor.constraint(equalTo: punjabiContentView.leadingAnchor, constant: 10),
        punjabiCarouselStackView.trailingAnchor.constraint(equalTo: punjabiContentView.trailingAnchor, constant: -10),
        punjabiCarouselStackView.bottomAnchor.constraint(equalTo: punjabiContentView.bottomAnchor, constant: -10)
      ])
      
      // Add a loading label
      let punjabiLoadingLabel = UILabel()
      punjabiLoadingLabel.text = "Loading Punjabi Grooves albums..."
      punjabiLoadingLabel.textAlignment = .center
      punjabiLoadingLabel.textColor = .systemGray
      punjabiCarouselStackView.addArrangedSubview(punjabiLoadingLabel)
      
      
      // Fetch albums with genre "Punjabi"
      Task { @MainActor in
        do {
          // Display loading indicator
          for view in punjabiCarouselStackView.arrangedSubviews {
            if !(view is UILabel && (view as! UILabel).text == "Loading Punjabi Grooves albums...") {
              punjabiCarouselStackView.removeArrangedSubview(view)
              view.removeFromSuperview()
            }
          }
          
          // Get the storage instance
          let storage = appDelegate.storage
          
          // Check if we need to sync the library first
          if !storage.isLibrarySynced {
            try await appDelegate.librarySyncer.syncInitial(statusNotifyier: nil)
          }
          
          // Find and add Punjabi albums to the carousel
          let allAlbums = storage.main.library.getAlbums()
          let punjabiAlbums = allAlbums.filter { 
            ($0.genre?.name == "Punjabi") // Case sensitive as requested
          }
          
          // Sort albums to show recently added first, then follow chronological order
          let sortedPunjabiAlbums = punjabiAlbums.sorted { album1, album2 in
            // First sort by newest (recently added)
            let newestIndex1 = album1.managedObject.newestIndex
            let newestIndex2 = album2.managedObject.newestIndex
            
            // If either has a newestIndex, prioritize non-zero values
            if newestIndex1 > 0 && newestIndex2 == 0 {
              return true // album1 comes first
            } else if newestIndex1 == 0 && newestIndex2 > 0 {
              return false // album2 comes first
            } else if newestIndex1 > 0 && newestIndex2 > 0 {
              return newestIndex1 < newestIndex2 // Standard newest sort
            }
            
            // Then fallback to chronological order by year
            let year1 = album1.managedObject.year
            let year2 = album2.managedObject.year
            if year1 != 0 || year2 != 0 {
              return year1 > year2
            }
            return album1.name < album2.name // Alphabetical as final fallback
          }
          
          // Clear loading indicator
          for view in punjabiCarouselStackView.arrangedSubviews {
            punjabiCarouselStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
          }
          
          if sortedPunjabiAlbums.isEmpty {
            // If no Punjabi albums found, show message
            let emptyLabel = UILabel()
            emptyLabel.text = "No Punjabi albums found in your library. Please sync your library or add albums with 'Punjabi' genre."
            emptyLabel.textAlignment = .center
            emptyLabel.textColor = .systemGray
            emptyLabel.numberOfLines = 0
            punjabiCarouselStackView.addArrangedSubview(emptyLabel)
            
            // Add note on how to get Punjabi albums
            let noteLabel = UILabel()
            noteLabel.text = "To display Punjabi albums, tag your albums with the 'Punjabi' genre on your server."
            noteLabel.textAlignment = .center
            noteLabel.textColor = .systemBlue
            noteLabel.font = .systemFont(ofSize: 12)
            noteLabel.numberOfLines = 0
            stackView.addArrangedSubview(noteLabel)
          } else {
            // Create a container stack view that will hold two horizontal rows
            let punjabiContainerStackView = UIStackView()
            punjabiContainerStackView.axis = .vertical
            punjabiContainerStackView.spacing = 15
            punjabiContainerStackView.distribution = .fillEqually
            punjabiContainerStackView.translatesAutoresizingMaskIntoConstraints = false
            punjabiCarouselStackView.addArrangedSubview(punjabiContainerStackView)
            
            // Create two horizontal stack views for the two rows
            let punjabiTopRowStackView = UIStackView()
            punjabiTopRowStackView.axis = .horizontal
            punjabiTopRowStackView.spacing = 15
            punjabiTopRowStackView.alignment = .center
            punjabiTopRowStackView.translatesAutoresizingMaskIntoConstraints = false
            
            let punjabiBottomRowStackView = UIStackView()
            punjabiBottomRowStackView.axis = .horizontal
            punjabiBottomRowStackView.spacing = 15
            punjabiBottomRowStackView.alignment = .center
            punjabiBottomRowStackView.translatesAutoresizingMaskIntoConstraints = false
            
            // Add the rows to the container
            punjabiContainerStackView.addArrangedSubview(punjabiTopRowStackView)
            punjabiContainerStackView.addArrangedSubview(punjabiBottomRowStackView)
            
            // Sort albums into two rows
            var currentRow = punjabiTopRowStackView
            
            // Add the albums to the carousel - divide them between two rows
            for (index, album) in sortedPunjabiAlbums.enumerated() {
              // Switch to bottom row after half the albums
              if index == Int(ceil(Double(sortedPunjabiAlbums.count) / 2.0)) {
                currentRow = punjabiBottomRowStackView
              }
              
              // Create a container view for each album
              let itemView = UIView()
              itemView.translatesAutoresizingMaskIntoConstraints = false
              
              // Set fixed size for the item - increased size for Punjabi Grooves carousel only
              itemView.heightAnchor.constraint(equalToConstant: 220).isActive = true
              itemView.widthAnchor.constraint(equalToConstant: 170).isActive = true
              
              // Create the image view for album artwork
              let imageView = UIImageView()
              imageView.translatesAutoresizingMaskIntoConstraints = false
              imageView.contentMode = .scaleAspectFill
              imageView.clipsToBounds = true
              imageView.layer.cornerRadius = 8
              
              // If artwork exists, use it, otherwise use placeholder
              if let artwork = album.artwork, let image = artwork.image {
                imageView.image = image
              } else {
                imageView.image = UIImage(systemName: "music.note")
              }
              
              itemView.addSubview(imageView)
              
              // Create title label with limited height to avoid overflow
              let titleLabel = UILabel()
              titleLabel.translatesAutoresizingMaskIntoConstraints = false
              titleLabel.text = album.name
              titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
              titleLabel.textColor = .label
              titleLabel.numberOfLines = 2
              titleLabel.textAlignment = .left
              itemView.addSubview(titleLabel)
              
              // Create artist label
              let artistLabel = UILabel()
              artistLabel.translatesAutoresizingMaskIntoConstraints = false
              artistLabel.text = album.artist?.name ?? "Unknown Artist"
              artistLabel.font = .systemFont(ofSize: 12)
              artistLabel.textColor = .secondaryLabel
              artistLabel.numberOfLines = 1
              artistLabel.textAlignment = .left
              itemView.addSubview(artistLabel)
              
              // Set up constraints - increased image size for Punjabi Grooves carousel
              NSLayoutConstraint.activate([
                imageView.topAnchor.constraint(equalTo: itemView.topAnchor),
                imageView.leadingAnchor.constraint(equalTo: itemView.leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: itemView.trailingAnchor),
                imageView.heightAnchor.constraint(equalToConstant: 170),
                imageView.widthAnchor.constraint(equalToConstant: 170),
                
                titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 6), // Increased from 4 to 6
                titleLabel.leadingAnchor.constraint(equalTo: itemView.leadingAnchor, constant: 8), // Increased left padding
                titleLabel.trailingAnchor.constraint(equalTo: itemView.trailingAnchor, constant: -8), // Increased right padding
                
                artistLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4), // Increased from 2 to 4
                artistLabel.leadingAnchor.constraint(equalTo: itemView.leadingAnchor, constant: 8), // Increased left padding
                artistLabel.trailingAnchor.constraint(equalTo: itemView.trailingAnchor, constant: -8), // Increased right padding
                artistLabel.bottomAnchor.constraint(equalTo: itemView.bottomAnchor, constant: -6) // Increased bottom padding from 4 to 6
              ])
              
              // Store album hashValue as tag
              itemView.tag = album.managedObject.hashValue
              
              // Add tap gesture
              let tapGesture = UITapGestureRecognizer(target: newVC, action: #selector(UIViewController.albumTapped(_:)))
              itemView.addGestureRecognizer(tapGesture)
              itemView.isUserInteractionEnabled = true
              
              // Add the item to the current row stack
              currentRow.addArrangedSubview(itemView)
            }
            
            // Calculate and set the content size for proper scrolling - based on half the albums per row
            let albumsPerRow = Int(ceil(Double(sortedPunjabiAlbums.count) / 2.0))
            let totalWidth = CGFloat(albumsPerRow * 185) // 170 width + 15 spacing - increased for Punjabi Grooves
            
            // Critical: Set the content view's width - this is key to making horizontal scrolling work
            let contentWidthConstraint = punjabiContentView.widthAnchor.constraint(equalToConstant: totalWidth)
            contentWidthConstraint.priority = .required
            contentWidthConstraint.isActive = true
            
            // Make sure content view's width can be greater than the scroll view's width
            // This is what enables scrolling
            let contentMinWidthConstraint = punjabiContentView.widthAnchor.constraint(greaterThanOrEqualTo: punjabiCarouselScrollView.widthAnchor)
            contentMinWidthConstraint.priority = .defaultHigh
            contentMinWidthConstraint.isActive = true
            
            // Force layout to ensure proper sizing
            punjabiCarouselScrollView.layoutIfNeeded()
          }
        } catch {
          // Clear any existing views
          for view in punjabiCarouselStackView.arrangedSubviews {
            punjabiCarouselStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
          }
          
          // Show error message
          let errorLabel = UILabel()
          errorLabel.text = "Error fetching Punjabi Grooves albums: \(error.localizedDescription)"
          errorLabel.textAlignment = .center
          errorLabel.numberOfLines = 0
          errorLabel.textColor = .systemRed
          punjabiCarouselStackView.addArrangedSubview(errorLabel)
          
          print("Error fetching Punjabi Grooves albums: \(error)")
        }
      }
      
      // Sizzling Bollywood Carousel Section
      let sizzlingBollywoodLabel = UILabel()
      sizzlingBollywoodLabel.text = "Sizzling Bollywood"
      sizzlingBollywoodLabel.font = .systemFont(ofSize: 20, weight: .bold)
      stackView.addArrangedSubview(sizzlingBollywoodLabel)
      
      // Create a horizontal scroll view for the Sizzling Bollywood carousel
      let sizzlingBollywoodScrollView = UIScrollView()
      sizzlingBollywoodScrollView.showsHorizontalScrollIndicator = true
      sizzlingBollywoodScrollView.translatesAutoresizingMaskIntoConstraints = false
      sizzlingBollywoodScrollView.alwaysBounceHorizontal = true
      sizzlingBollywoodScrollView.clipsToBounds = true
      stackView.addArrangedSubview(sizzlingBollywoodScrollView)
      
      // Set fixed height for the carousel - slightly larger than Punjabi Grooves carousel
      sizzlingBollywoodScrollView.heightAnchor.constraint(equalToConstant: 240).isActive = true
      
      // Create content view for the scroll view
      let sizzlingBollywoodContentView = UIView()
      sizzlingBollywoodContentView.translatesAutoresizingMaskIntoConstraints = false
      sizzlingBollywoodScrollView.addSubview(sizzlingBollywoodContentView)
      
      // Setup content view constraints
      NSLayoutConstraint.activate([
        sizzlingBollywoodContentView.topAnchor.constraint(equalTo: sizzlingBollywoodScrollView.topAnchor),
        sizzlingBollywoodContentView.leadingAnchor.constraint(equalTo: sizzlingBollywoodScrollView.leadingAnchor),
        sizzlingBollywoodContentView.trailingAnchor.constraint(equalTo: sizzlingBollywoodScrollView.trailingAnchor),
        sizzlingBollywoodContentView.bottomAnchor.constraint(equalTo: sizzlingBollywoodScrollView.bottomAnchor),
        sizzlingBollywoodContentView.heightAnchor.constraint(equalTo: sizzlingBollywoodScrollView.heightAnchor)
      ])
      
      // Create a horizontal stack view to hold carousel items
      let sizzlingBollywoodStackView = UIStackView()
      sizzlingBollywoodStackView.axis = .horizontal
      sizzlingBollywoodStackView.spacing = 15
      sizzlingBollywoodStackView.alignment = .center
      sizzlingBollywoodStackView.translatesAutoresizingMaskIntoConstraints = false
      sizzlingBollywoodContentView.addSubview(sizzlingBollywoodStackView)
      
      // Setup stack view constraints
      NSLayoutConstraint.activate([
        sizzlingBollywoodStackView.topAnchor.constraint(equalTo: sizzlingBollywoodContentView.topAnchor, constant: 10),
        sizzlingBollywoodStackView.leadingAnchor.constraint(equalTo: sizzlingBollywoodContentView.leadingAnchor, constant: 10),
        sizzlingBollywoodStackView.trailingAnchor.constraint(equalTo: sizzlingBollywoodContentView.trailingAnchor, constant: -10),
        sizzlingBollywoodStackView.bottomAnchor.constraint(equalTo: sizzlingBollywoodContentView.bottomAnchor, constant: -10)
      ])
      
      // Add a loading label
      let sizzlingBollywoodLoadingLabel = UILabel()
      sizzlingBollywoodLoadingLabel.text = "Loading Sizzling Bollywood albums..."
      sizzlingBollywoodLoadingLabel.textAlignment = .center
      sizzlingBollywoodLoadingLabel.textColor = .systemGray
      sizzlingBollywoodStackView.addArrangedSubview(sizzlingBollywoodLoadingLabel)
      
      // Fetch albums with genre "Item" (case sensitive)
      Task { @MainActor in
        do {
          // Display loading indicator
          for view in sizzlingBollywoodStackView.arrangedSubviews {
            if !(view is UILabel && (view as! UILabel).text == "Loading Sizzling Bollywood albums...") {
              sizzlingBollywoodStackView.removeArrangedSubview(view)
              view.removeFromSuperview()
            }
          }
          
          // Get the storage instance
          let storage = appDelegate.storage
          
          // Check if we need to sync the library first
          if !storage.isLibrarySynced {
            try await appDelegate.librarySyncer.syncInitial(statusNotifyier: nil)
          }
          
          // Find and add Item genre albums to the carousel
          let allAlbums = storage.main.library.getAlbums()
          let itemAlbums = allAlbums.filter { 
            ($0.genre?.name == "Item") // Case sensitive as requested
          }
          
          // Sort albums to show recently added first, then follow chronological order
          let sortedItemAlbums = itemAlbums.sorted { album1, album2 in
            // First sort by newest (recently added)
            let newestIndex1 = album1.managedObject.newestIndex
            let newestIndex2 = album2.managedObject.newestIndex
            
            // If either has a newestIndex, prioritize non-zero values
            if newestIndex1 > 0 && newestIndex2 == 0 {
              return true // album1 comes first
            } else if newestIndex1 == 0 && newestIndex2 > 0 {
              return false // album2 comes first
            } else if newestIndex1 > 0 && newestIndex2 > 0 {
              return newestIndex1 < newestIndex2 // Standard newest sort
            }
            
            // Then fallback to chronological order by year
            let year1 = album1.managedObject.year
            let year2 = album2.managedObject.year
            if year1 != 0 || year2 != 0 {
              return year1 > year2
            }
            return album1.name < album2.name // Alphabetical as final fallback
          }
          
          // Clear loading indicator
          for view in sizzlingBollywoodStackView.arrangedSubviews {
            sizzlingBollywoodStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
          }
          
          if sortedItemAlbums.isEmpty {
            // If no Item albums found, show message
            let emptyLabel = UILabel()
            emptyLabel.text = "No Sizzling Bollywood albums found in your library. Please sync your library or add albums with 'Item' genre."
            emptyLabel.textAlignment = .center
            emptyLabel.textColor = .systemGray
            emptyLabel.numberOfLines = 0
            sizzlingBollywoodStackView.addArrangedSubview(emptyLabel)
            
            // Add note on how to get Item albums
            let noteLabel = UILabel()
            noteLabel.text = "To display Sizzling Bollywood albums, tag your albums with the 'Item' genre on your server."
            noteLabel.textAlignment = .center
            noteLabel.textColor = .systemBlue
            noteLabel.font = .systemFont(ofSize: 12)
            noteLabel.numberOfLines = 0
            stackView.addArrangedSubview(noteLabel)
          } else {
            // Add the albums to the carousel - single row
            for album in sortedItemAlbums {
              // Create a container view for each album
              let itemView = UIView()
              itemView.translatesAutoresizingMaskIntoConstraints = false
              
              // Set fixed size for the item - larger than Punjabi Grooves carousel
              itemView.heightAnchor.constraint(equalToConstant: 230).isActive = true
              itemView.widthAnchor.constraint(equalToConstant: 180).isActive = true
              
              // Create the image view for album artwork
              let imageView = UIImageView()
              imageView.translatesAutoresizingMaskIntoConstraints = false
              imageView.contentMode = .scaleAspectFill
              imageView.clipsToBounds = true
              imageView.layer.cornerRadius = 8
              
              // If artwork exists, use it, otherwise use placeholder
              if let artwork = album.artwork, let image = artwork.image {
                imageView.image = image
              } else {
                imageView.image = UIImage(systemName: "music.note")
              }
              
              itemView.addSubview(imageView)
              
              // Create title label with limited height to avoid overflow
              let titleLabel = UILabel()
              titleLabel.translatesAutoresizingMaskIntoConstraints = false
              titleLabel.text = album.name
              titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
              titleLabel.textColor = .label
              titleLabel.numberOfLines = 2
              titleLabel.textAlignment = .left
              itemView.addSubview(titleLabel)
              
              // Create artist label
              let artistLabel = UILabel()
              artistLabel.translatesAutoresizingMaskIntoConstraints = false
              artistLabel.text = album.artist?.name ?? "Unknown Artist"
              artistLabel.font = .systemFont(ofSize: 12)
              artistLabel.textColor = .secondaryLabel
              artistLabel.numberOfLines = 1
              artistLabel.textAlignment = .left
              itemView.addSubview(artistLabel)
              
              // Set up constraints - larger image size than Punjabi Grooves carousel
              NSLayoutConstraint.activate([
                imageView.topAnchor.constraint(equalTo: itemView.topAnchor),
                imageView.leadingAnchor.constraint(equalTo: itemView.leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: itemView.trailingAnchor),
                imageView.heightAnchor.constraint(equalToConstant: 180),
                imageView.widthAnchor.constraint(equalToConstant: 180),
                
                titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 6),
                titleLabel.leadingAnchor.constraint(equalTo: itemView.leadingAnchor, constant: 8),
                titleLabel.trailingAnchor.constraint(equalTo: itemView.trailingAnchor, constant: -8),
                
                artistLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
                artistLabel.leadingAnchor.constraint(equalTo: itemView.leadingAnchor, constant: 8),
                artistLabel.trailingAnchor.constraint(equalTo: itemView.trailingAnchor, constant: -8),
                artistLabel.bottomAnchor.constraint(equalTo: itemView.bottomAnchor, constant: -6)
              ])
              
              // Store album hashValue as tag
              itemView.tag = album.managedObject.hashValue
              
              // Add tap gesture
              let tapGesture = UITapGestureRecognizer(target: newVC, action: #selector(UIViewController.albumTapped(_:)))
              itemView.addGestureRecognizer(tapGesture)
              itemView.isUserInteractionEnabled = true
              
              // Add the item to the stack
              sizzlingBollywoodStackView.addArrangedSubview(itemView)
            }
            
            // Calculate and set the content size for proper scrolling
            let totalWidth = CGFloat(sortedItemAlbums.count * 195) // 180 width + 15 spacing - larger than Punjabi Grooves
            
            // Critical: Set the content view's width - this is key to making horizontal scrolling work
            let contentWidthConstraint = sizzlingBollywoodContentView.widthAnchor.constraint(equalToConstant: totalWidth)
            contentWidthConstraint.priority = .required
            contentWidthConstraint.isActive = true
            
            // Make sure content view's width can be greater than the scroll view's width
            // This is what enables scrolling
            let contentMinWidthConstraint = sizzlingBollywoodContentView.widthAnchor.constraint(greaterThanOrEqualTo: sizzlingBollywoodScrollView.widthAnchor)
            contentMinWidthConstraint.priority = .defaultHigh
            contentMinWidthConstraint.isActive = true
            
            // Force layout to ensure proper sizing
            sizzlingBollywoodScrollView.layoutIfNeeded()
          }
        } catch {
          // Clear any existing views
          for view in sizzlingBollywoodStackView.arrangedSubviews {
            sizzlingBollywoodStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
          }
          
          // Show error message
          let errorLabel = UILabel()
          errorLabel.text = "Error fetching Sizzling Bollywood albums: \(error.localizedDescription)"
          errorLabel.textAlignment = .center
          errorLabel.numberOfLines = 0
          errorLabel.textColor = .systemRed
          sizzlingBollywoodStackView.addArrangedSubview(errorLabel)
          
          print("Error fetching Sizzling Bollywood albums: \(error)")
        }
      }
      
      // Global Rhythms Carousel Section
      let globalRhythmsLabel = UILabel()
      globalRhythmsLabel.text = "Global Rhythms"
      globalRhythmsLabel.font = .systemFont(ofSize: 20, weight: .bold)
      stackView.addArrangedSubview(globalRhythmsLabel)
      
      // Create a horizontal scroll view for the Global Rhythms carousel
      let globalRhythmsScrollView = UIScrollView()
      globalRhythmsScrollView.showsHorizontalScrollIndicator = true
      globalRhythmsScrollView.translatesAutoresizingMaskIntoConstraints = false
      globalRhythmsScrollView.alwaysBounceHorizontal = true
      globalRhythmsScrollView.clipsToBounds = true
      stackView.addArrangedSubview(globalRhythmsScrollView)
      
      // Set fixed height for the carousel - slightly larger than Punjabi Grooves carousel
      globalRhythmsScrollView.heightAnchor.constraint(equalToConstant: 260).isActive = true
      
      // Create content view for the scroll view
      let globalRhythmsContentView = UIView()
      globalRhythmsContentView.translatesAutoresizingMaskIntoConstraints = false
      globalRhythmsScrollView.addSubview(globalRhythmsContentView)
      
      // Setup content view constraints
      NSLayoutConstraint.activate([
        globalRhythmsContentView.topAnchor.constraint(equalTo: globalRhythmsScrollView.topAnchor),
        globalRhythmsContentView.leadingAnchor.constraint(equalTo: globalRhythmsScrollView.leadingAnchor),
        globalRhythmsContentView.trailingAnchor.constraint(equalTo: globalRhythmsScrollView.trailingAnchor),
        globalRhythmsContentView.bottomAnchor.constraint(equalTo: globalRhythmsScrollView.bottomAnchor),
        globalRhythmsContentView.heightAnchor.constraint(equalTo: globalRhythmsScrollView.heightAnchor)
      ])
      
      // Create a horizontal stack view to hold carousel items
      let globalRhythmsStackView = UIStackView()
      globalRhythmsStackView.axis = .horizontal
      globalRhythmsStackView.spacing = 15
      globalRhythmsStackView.alignment = .center
      globalRhythmsStackView.translatesAutoresizingMaskIntoConstraints = false
      globalRhythmsContentView.addSubview(globalRhythmsStackView)
      
      // Setup stack view constraints
      NSLayoutConstraint.activate([
        globalRhythmsStackView.topAnchor.constraint(equalTo: globalRhythmsContentView.topAnchor, constant: 10),
        globalRhythmsStackView.leadingAnchor.constraint(equalTo: globalRhythmsContentView.leadingAnchor, constant: 10),
        globalRhythmsStackView.trailingAnchor.constraint(equalTo: globalRhythmsContentView.trailingAnchor, constant: -10),
        globalRhythmsStackView.bottomAnchor.constraint(equalTo: globalRhythmsContentView.bottomAnchor, constant: -10)
      ])
      
      // Add a loading label
      let globalRhythmsLoadingLabel = UILabel()
      globalRhythmsLoadingLabel.text = "Loading Global Rhythms albums..."
      globalRhythmsLoadingLabel.textAlignment = .center
      globalRhythmsLoadingLabel.textColor = .systemGray
      globalRhythmsStackView.addArrangedSubview(globalRhythmsLoadingLabel)
      
      // Fetch albums with genre "Arabic" or "Soca" (case sensitive)
      Task { @MainActor in
        do {
          // Display loading indicator
          for view in globalRhythmsStackView.arrangedSubviews {
            if !(view is UILabel && (view as! UILabel).text == "Loading Global Rhythms albums...") {
              globalRhythmsStackView.removeArrangedSubview(view)
              view.removeFromSuperview()
            }
          }
          
          // Get the storage instance
          let storage = appDelegate.storage
          
          // Check if we need to sync the library first
          if !storage.isLibrarySynced {
            try await appDelegate.librarySyncer.syncInitial(statusNotifyier: nil)
          }
          
          // Find and add Arabic and Soca genre albums to the carousel
          let allAlbums = storage.main.library.getAlbums()
          let globalRhythmsAlbums = allAlbums.filter { 
            ($0.genre?.name == "Arabic" || $0.genre?.name == "Soca") // Case sensitive as requested
          }
          
          // Sort albums to show recently added first, then follow chronological order
          let sortedGlobalRhythmsAlbums = globalRhythmsAlbums.sorted { album1, album2 in
            // First sort by newest (recently added)
            let newestIndex1 = album1.managedObject.newestIndex
            let newestIndex2 = album2.managedObject.newestIndex
            
            // If either has a newestIndex, prioritize non-zero values
            if newestIndex1 > 0 && newestIndex2 == 0 {
              return true // album1 comes first
            } else if newestIndex1 == 0 && newestIndex2 > 0 {
              return false // album2 comes first
            } else if newestIndex1 > 0 && newestIndex2 > 0 {
              return newestIndex1 < newestIndex2 // Standard newest sort
            }
            
            // Then fallback to chronological order by year
            let year1 = album1.managedObject.year
            let year2 = album2.managedObject.year
            if year1 != 0 || year2 != 0 {
              return year1 > year2
            }
            return album1.name < album2.name // Alphabetical as final fallback
          }
          
          // Clear loading indicator
          for view in globalRhythmsStackView.arrangedSubviews {
            globalRhythmsStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
          }
          
          if sortedGlobalRhythmsAlbums.isEmpty {
            // If no Arabic or Soca albums found, show message
            let emptyLabel = UILabel()
            emptyLabel.text = "No Global Rhythms albums found in your library. Please sync your library or add albums with 'Arabic' or 'Soca' genre."
            emptyLabel.textAlignment = .center
            emptyLabel.textColor = .systemGray
            emptyLabel.numberOfLines = 0
            globalRhythmsStackView.addArrangedSubview(emptyLabel)
            
            // Add note on how to get Global Rhythms albums
            let noteLabel = UILabel()
            noteLabel.text = "To display Global Rhythms albums, tag your albums with the 'Arabic' or 'Soca' genre on your server."
            noteLabel.textAlignment = .center
            noteLabel.textColor = .systemBlue
            noteLabel.font = .systemFont(ofSize: 12)
            noteLabel.numberOfLines = 0
            stackView.addArrangedSubview(noteLabel)
          } else {
            // Add the albums to the carousel - single row
            for album in sortedGlobalRhythmsAlbums {
              // Create a container view for each album
              let itemView = UIView()
              itemView.translatesAutoresizingMaskIntoConstraints = false
              
              // Set fixed size for the item - larger than Punjabi Grooves carousel
              itemView.heightAnchor.constraint(equalToConstant: 250).isActive = true
              itemView.widthAnchor.constraint(equalToConstant: 200).isActive = true
              
              // Create the image view for album artwork
              let imageView = UIImageView()
              imageView.translatesAutoresizingMaskIntoConstraints = false
              imageView.contentMode = .scaleAspectFill
              imageView.clipsToBounds = true
              imageView.layer.cornerRadius = 8
              
              // If artwork exists, use it, otherwise use placeholder
              if let artwork = album.artwork, let image = artwork.image {
                imageView.image = image
              } else {
                imageView.image = UIImage(systemName: "music.note")
              }
              
              itemView.addSubview(imageView)
              
              // Create title label with limited height to avoid overflow
              let titleLabel = UILabel()
              titleLabel.translatesAutoresizingMaskIntoConstraints = false
              titleLabel.text = album.name
              titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
              titleLabel.textColor = .label
              titleLabel.numberOfLines = 2
              titleLabel.textAlignment = .left
              itemView.addSubview(titleLabel)
              
              // Create artist label
              let artistLabel = UILabel()
              artistLabel.translatesAutoresizingMaskIntoConstraints = false
              artistLabel.text = album.artist?.name ?? "Unknown Artist"
              artistLabel.font = .systemFont(ofSize: 12)
              artistLabel.textColor = .secondaryLabel
              artistLabel.numberOfLines = 1
              artistLabel.textAlignment = .left
              itemView.addSubview(artistLabel)
              
              // Set up constraints - larger image size than Punjabi Grooves carousel
              NSLayoutConstraint.activate([
                imageView.topAnchor.constraint(equalTo: itemView.topAnchor),
                imageView.leadingAnchor.constraint(equalTo: itemView.leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: itemView.trailingAnchor),
                imageView.heightAnchor.constraint(equalToConstant: 200),
                imageView.widthAnchor.constraint(equalToConstant: 200),
                
                titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 6),
                titleLabel.leadingAnchor.constraint(equalTo: itemView.leadingAnchor, constant: 8),
                titleLabel.trailingAnchor.constraint(equalTo: itemView.trailingAnchor, constant: -8),
                
                artistLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
                artistLabel.leadingAnchor.constraint(equalTo: itemView.leadingAnchor, constant: 8),
                artistLabel.trailingAnchor.constraint(equalTo: itemView.trailingAnchor, constant: -8),
                artistLabel.bottomAnchor.constraint(equalTo: itemView.bottomAnchor, constant: -6)
              ])
              
              // Store album hashValue as tag
              itemView.tag = album.managedObject.hashValue
              
              // Add tap gesture
              let tapGesture = UITapGestureRecognizer(target: newVC, action: #selector(UIViewController.albumTapped(_:)))
              itemView.addGestureRecognizer(tapGesture)
              itemView.isUserInteractionEnabled = true
              
              // Add the item to the stack
              globalRhythmsStackView.addArrangedSubview(itemView)
            }
            
            // Calculate and set the content size for proper scrolling
            let totalWidth = CGFloat(sortedGlobalRhythmsAlbums.count * 215) // 200 width + 15 spacing - larger than others
            
            // Critical: Set the content view's width - this is key to making horizontal scrolling work
            let contentWidthConstraint = globalRhythmsContentView.widthAnchor.constraint(equalToConstant: totalWidth)
            contentWidthConstraint.priority = .required
            contentWidthConstraint.isActive = true
            
            // Make sure content view's width can be greater than the scroll view's width
            // This is what enables scrolling
            let contentMinWidthConstraint = globalRhythmsContentView.widthAnchor.constraint(greaterThanOrEqualTo: globalRhythmsScrollView.widthAnchor)
            contentMinWidthConstraint.priority = .defaultHigh
            contentMinWidthConstraint.isActive = true
            
            // Force layout to ensure proper sizing
            globalRhythmsScrollView.layoutIfNeeded()
          }
        } catch {
          // Clear any existing views
          for view in globalRhythmsStackView.arrangedSubviews {
            globalRhythmsStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
          }
          
          // Show error message
          let errorLabel = UILabel()
          errorLabel.text = "Error fetching Global Rhythms albums: \(error.localizedDescription)"
          errorLabel.textAlignment = .center
          errorLabel.numberOfLines = 0
          errorLabel.textColor = .systemRed
          globalRhythmsStackView.addArrangedSubview(errorLabel)
          
          print("Error fetching Global Rhythms albums: \(error)")
        }
      }
      
      // Set up constraints
      NSLayoutConstraint.activate([
        scrollView.topAnchor.constraint(equalTo: newVC.view.safeAreaLayoutGuide.topAnchor),
        scrollView.leadingAnchor.constraint(equalTo: newVC.view.leadingAnchor),
        scrollView.trailingAnchor.constraint(equalTo: newVC.view.trailingAnchor),
        scrollView.bottomAnchor.constraint(equalTo: newVC.view.bottomAnchor),
        
        stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
        stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
        stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
        stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
        stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40),
      ])
      
      let newNavController = UINavigationController(rootViewController: newVC)
      return newNavController
    }
  }
}

// Extensions for album tap handling
extension UIViewController {
  @objc func albumTapped(_ sender: UITapGestureRecognizer) {
    guard let tappedView = sender.view else { return }
    
    Task { @MainActor in
      let storage = appDelegate.storage
      
      // Get the hashValue from the tapped view's tag
      let albumHashValue = tappedView.tag
      
      // Find the album with this hashValue by searching through all albums
      let allAlbums = storage.main.library.getAlbums()
      let album = allAlbums.first { $0.managedObject.hashValue == albumHashValue }
      
      if let album = album {
        // Present the album detail view
        let albumViewController = AlbumDetailVC.instantiateFromAppStoryboard()
        albumViewController.album = album
        
        // Present the album detail view
        if let navigationController = self.navigationController {
          navigationController.pushViewController(albumViewController, animated: true)
        } else {
          present(albumViewController, animated: true)
        }
      } else {
        // Show error alert if album not found
        let alertController = UIAlertController(
          title: "Album Not Found",
          message: "Could not find the selected album in your library.",
          preferredStyle: .alert
        )
        
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        present(alertController, animated: true)
      }
    }
  }
  
  @objc func radioArtistCardTapped(_ sender: UITapGestureRecognizer) {
    guard let tappedView = sender.view else { return }
    
    Task { @MainActor in
      let storage = appDelegate.storage
      
      // Get the hashValue from the tapped view's tag
      let artistHashValue = tappedView.tag
      
      // Find the artist name based on hashValue
      let artistNames = ["Suresh Sehrawat", "Kishore Kumar", "Mohammed Rafi", "Lata Mangeshkar", "Asha Bhosle", "Kumar Sanu", "Sonu Nigam", "K K", "Badshah", "Neha Kakkar", "Udit Narayan", "Shaan"]
      var selectedArtistName: String?
      for artistName in artistNames {
        if artistName.hashValue == artistHashValue {
          selectedArtistName = artistName
                    break
                }

            }
      
      guard let artistName = selectedArtistName else {
        // Show error alert if artist not found
        let alertController = UIAlertController(
          title: "Artist Not Found",
          message: "Could not find the selected artist in your library.",
          preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        present(alertController, animated: true)
        return
      }
      
      // Find songs by this artist
      var artistsToSearch = [artistName]
      
      // For Mohammed Rafi, also search for Mohd Rafi and vice versa
      if artistName == "Mohammed Rafi" {
        artistsToSearch.append("Mohd Rafi")
      }
      
      // For K K, also search for KK (without spaces)
      if artistName == "K K" {
        artistsToSearch.append("KK")
      }
      
      // Find songs by the selected artist
      var selectedSongs: [Song] = []
      
      // Special handling for Suresh Sehrawat - find songs with genre "Nonstop"
      if artistName == "Suresh Sehrawat" {
        let allSongs = storage.main.library.getSongs()
        for song in allSongs {
          if let genre = song.genre, genre.name.lowercased() == "nonstop".lowercased() {
            selectedSongs.append(song)
          }
        }
      }
      // Special handling for Sonu Nigam - only exact artist match, no fuzzy search
      else if artistName == "Sonu Nigam" {
        let sonuArtists = storage.main.library.getArtists().filter { 
          $0.name.lowercased() == "sonu nigam".lowercased() 
        }
        
        for artist in sonuArtists {
          let songs = storage.main.library.getSongs(whichContainsSongsWithArtist: artist)
          selectedSongs.append(contentsOf: songs)
        }
      } 
      // Special handling for K K - search for both "K K" and "KK"
      else if artistName == "K K" {
        // Try exact artist matches for both "K K" and "KK"
        let kkArtists = storage.main.library.getArtists().filter {
          $0.name.lowercased() == "k k".lowercased() || 
          $0.name.lowercased() == "kk".lowercased()
        }
        
        for artist in kkArtists {
          let songs = storage.main.library.getSongs(whichContainsSongsWithArtist: artist)
          selectedSongs.append(contentsOf: songs)
        }
        
        // If no direct matches, try fuzzy match in song creators
        if selectedSongs.isEmpty {
          let allSongs = storage.main.library.getSongs()
          for song in allSongs {
            if let artistForSong = song.artist?.name,
               (artistForSong.lowercased() == "k k".lowercased() || artistForSong.lowercased() == "kk".lowercased()) ||
               (song.creatorName.lowercased() == "k k".lowercased() || song.creatorName.lowercased() == "kk".lowercased()) {
              selectedSongs.append(song)
            }
          }
        }
      }
      // Special handling for Badshah and Neha Kakkar - case insensitive exact match
      else if artistName == "Badshah" || artistName == "Neha Kakkar" || artistName == "Udit Narayan" || artistName == "Shaan" {
        let matchingArtists = storage.main.library.getArtists().filter {
          $0.name.lowercased() == artistName.lowercased()
        }
        
        for artist in matchingArtists {
          let songs = storage.main.library.getSongs(whichContainsSongsWithArtist: artist)
          selectedSongs.append(contentsOf: songs)
        }
        
        // If no direct artist matches, try song creators
        if selectedSongs.isEmpty {
          let allSongs = storage.main.library.getSongs()
          for song in allSongs {
            if let artistForSong = song.artist?.name,
               artistForSong.lowercased() == artistName.lowercased() ||
               song.creatorName.lowercased() == artistName.lowercased() {
              selectedSongs.append(song)
            }
          }
        }
      }
      else {
        // For other artists, use the normal search logic
        for name in artistsToSearch {
          // Search for exact artist name matches
          let artists = storage.main.library.getArtists().filter { 
            $0.name.lowercased() == name.lowercased() 
          }
          
          for artist in artists {
            let songs = storage.main.library.getSongs(whichContainsSongsWithArtist: artist)
            selectedSongs.append(contentsOf: songs)
          }
          
          // If no direct artist matches, try fuzzy search on songs
          if selectedSongs.isEmpty {
            let allSongs = storage.main.library.getSongs()
            for song in allSongs {
              if let artistForSong = song.artist?.name, 
                 artistForSong.lowercased().contains(name.lowercased()) ||
                 song.creatorName.lowercased().contains(name.lowercased()) {
                selectedSongs.append(song)
              }
            }
          }
        }
      }
      
      if !selectedSongs.isEmpty {
        // Sort songs alphabetically
        selectedSongs.sort { $0.title < $1.title }
        
        // Create a shuffled play context with random starting index
        let shuffledSongs = selectedSongs.prefix(appDelegate.player.maxSongsToAddOnce).map { $0 }.shuffled()
        let randomIndex = Int.random(in: 0 ..< shuffledSongs.count)
        
        let playContext = PlayContext(
          name: "\(artistName) Songs (Shuffled)",
          index: randomIndex,
          playables: shuffledSongs
        )
        
        // Play the songs in shuffle mode
        appDelegate.player.play(context: playContext)
      } else {
        // Show alert if no songs found
        let alertController = UIAlertController(
          title: "No Songs Found",
          message: "Could not find any songs by \(artistName) in your library.",
          preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        present(alertController, animated: true)
      }
    }
  }
  
  @objc func moreArtistsCardTapped(_ sender: UITapGestureRecognizer) {
    guard let tappedView = sender.view else { return }
    
    Task { @MainActor in
      let storage = appDelegate.storage
      
      // Get the hashValue from the tapped view's tag
      let artistHashValue = tappedView.tag
      
      // Find the artist name based on hashValue
      let moreArtistNames = ["Donna Summer", "Sade", "Phil Collins", "Pet Shop Boys", "Artbat", "Andy Bros", "Blondie", "Boney M", "Cerrone", "Purple Disco"]
      var selectedArtistName: String?
      for artistName in moreArtistNames {
        if artistName.hashValue == artistHashValue {
          selectedArtistName = artistName
          break
        }
      }
      
      guard let artistName = selectedArtistName else {
        // Show error alert if artist not found
        let alertController = UIAlertController(
          title: "Artist Not Found",
          message: "Could not find the selected artist in your library.",
          preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        present(alertController, animated: true)
        return
      }
      
      // Find songs by this artist
      var selectedSongs: [Song] = []
      
      // Search for artists with exact or partial name match
      let artists = storage.main.library.getArtists().filter { 
        $0.name.lowercased().contains(artistName.lowercased())
      }
      
      for artist in artists {
        let songs = storage.main.library.getSongs(whichContainsSongsWithArtist: artist)
        selectedSongs.append(contentsOf: songs)
      }
      
      // If no direct artist matches, try fuzzy search on songs
      if selectedSongs.isEmpty {
        let allSongs = storage.main.library.getSongs()
        for song in allSongs {
          if let artistForSong = song.artist?.name, 
             artistForSong.lowercased().contains(artistName.lowercased()) ||
             song.creatorName.lowercased().contains(artistName.lowercased()) {
            selectedSongs.append(song)
          }
        }
      }
      
      // If songs were found, create a play context and start playing
      if !selectedSongs.isEmpty {
        // Create a play context with the selected songs
        let playContext = PlayContext(
          name: "\(artistName) Songs",
          playables: selectedSongs
        )
        
        // Use shuffle function to play the songs in random order
        appDelegate.player.play(context: playContext.getWithShuffledIndex())
      } else {
        // Try to search for and sync this artist from the server
        Task {
          do {
            try await appDelegate.librarySyncer.searchArtists(searchText: artistName)
            // After sync, try to find songs again
            let freshArtists = storage.main.library.getArtists().filter { 
              $0.name.lowercased().contains(artistName.lowercased())
            }
            
            var freshSongs: [Song] = []
            for artist in freshArtists {
              let songs = storage.main.library.getSongs(whichContainsSongsWithArtist: artist)
              freshSongs.append(contentsOf: songs)
            }
            
            if !freshSongs.isEmpty {
              // Create a play context with the selected songs
              let playContext = PlayContext(
                name: "\(artistName) Songs",
                playables: freshSongs
              )
              
              // Use shuffle function to play the songs in random order
              appDelegate.player.play(context: playContext.getWithShuffledIndex())
            }
          } catch {
            appDelegate.eventLogger.report(topic: "Artist Search", error: error)
          }
        }
      }
    }
  }

  @objc func moodTapped(_ sender: UITapGestureRecognizer) {
    guard let tappedView = sender.view else { return }
    
    Task { @MainActor in
      let storage = appDelegate.storage
      
      // Get the hashValue from the tapped view's tag
      let moodHashValue = tappedView.tag
      
      // Determine which mood was tapped
      let moodName: String
      if moodHashValue == "Chill".hashValue {
        moodName = "Chill"
      } else if moodHashValue == "Workout".hashValue {
        moodName = "Workout"
      } else if moodHashValue == "Focus".hashValue {
        moodName = "Focus"
      } else if moodHashValue == "Party".hashValue {
        moodName = "Party"
      } else if moodHashValue == "Relaxing".hashValue {
        moodName = "Relaxing"
      } else if moodHashValue == "Romantic".hashValue {
        moodName = "Romantic"
      } else if moodHashValue == "MorningVibes".hashValue {
        moodName = "Morning Vibes"
      } else if moodHashValue == "AfternoonChill".hashValue {
        moodName = "Afternoon Chill"
      } else {
        return
      }
      
      // Find songs appropriate for the selected mood
      var selectedSongs: [Song] = []
      let allSongs = storage.main.library.getSongs()
      
      var moodKeywords: [String] = []
      var moodGenres: [String] = []
      
      switch moodName {
      case "Chill":
        moodKeywords = ["chill", "relax", "lounge", "smooth", "cool", "groove", "mellow", "flow", "laid-back"]
        moodGenres = ["Chill", "Lounge", "Ambient", "Downtempo"]
      case "Workout":
        moodKeywords = ["workout", "fitness", "gym", "energy", "power", "strong", "training", "exercise", "pump"]
        moodGenres = ["Electronic", "Dance", "Hip-Hop", "Rock", "Pop"]
      case "Focus":
        moodKeywords = ["focus", "study", "concentration", "deep", "thought", "brain", "mind", "calm", "quiet"]
        moodGenres = ["Classical", "Ambient", "Instrumental", "Electronic"]
      case "Party":
        moodKeywords = ["party", "dance", "fun", "celebration", "club", "night", "beat", "groove", "upbeat"]
        moodGenres = ["Dance", "Pop", "Electronic", "Hip-Hop", "R&B"]
      case "Relaxing":
        moodKeywords = ["relax", "calm", "peaceful", "gentle", "soft", "soothing", "quiet", "tranquil", "meditative"]
        moodGenres = ["Ambient", "Classical", "Acoustic", "New Age"]
      case "Romantic":
        moodKeywords = ["love", "romance", "heart", "passion", "intimate", "sweet", "emotional", "tender", "affection"]
        moodGenres = ["R&B", "Soul", "Jazz", "Pop", "Classical"]
      case "Morning Vibes":
        moodKeywords = ["morning", "sunrise", "wake", "day", "light", "calm", "peaceful", "relax", "fresh", "begin"]
        moodGenres = ["Jazz", "Classical", "Ambient", "Acoustic"]
      case "Afternoon Chill":
        moodKeywords = ["chill", "relax", "lounge", "smooth", "cool", "groove", "mellow", "flow", "afternoon", "laid-back"]
        moodGenres = ["Jazz", "R&B", "Soul", "Lounge", "Chill"]
      default:
        break
      }
      
      // Filter songs by relevant metadata
      for song in allSongs {
        // Check song title for mood-related keywords
        let songTitle = song.title.lowercased()
        if moodKeywords.contains(where: songTitle.contains) {
          selectedSongs.append(song)
          continue
        }
        
        // Check album title for mood-related keywords
        if let album = song.album, 
           moodKeywords.contains(where: album.name.lowercased().contains) {
          selectedSongs.append(song)
          continue
        }
        
        // Check genre
        if let genre = song.genre?.name {
          let genreLowercase = genre.lowercased()
          if moodGenres.contains(where: { $0.lowercased() == genreLowercase }) {
            selectedSongs.append(song)
            continue
          }
        }
      }
      
      // If songs were found, create a play context and start playing in shuffle mode
      if !selectedSongs.isEmpty {
        // Create a play context with the selected songs
        let playContext = PlayContext(
          name: moodName,
          playables: selectedSongs
        )
        
        // Use shuffle function to play the songs in random order
        appDelegate.player.play(context: playContext.getWithShuffledIndex())
      } else {
        // Show error alert if no songs found
        let alertController = UIAlertController(
          title: "No Songs Found",
          message: "Could not find any songs suitable for \(moodName).",
          preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        present(alertController, animated: true)
      }
    }
  }
  
  @objc func genreTapped(_ sender: UITapGestureRecognizer) {
    guard let tappedView = sender.view else { return }
    
    Task { @MainActor in
      let storage = appDelegate.storage
      
      // Get the hashValue from the tapped view's tag
      let genreHashValue = tappedView.tag
      
      // Determine which genre was tapped
      let genreName: String
      if genreHashValue == "Disco".hashValue {
        genreName = "Disco"
      } else if genreHashValue == "Bollywood".hashValue {
        genreName = "Bollywood"
      } else if genreHashValue == "House".hashValue {
        genreName = "House"
      } else if genreHashValue == "Filmi".hashValue {
        genreName = "Filmi"
      } else if genreHashValue == "Punjabi".hashValue {
        genreName = "Punjabi"
      } else if genreHashValue == "Haryanvi".hashValue {
        genreName = "Haryanvi"
      } else {
        return
      }
      
      // Find songs with this genre
      var selectedSongs: [Song] = []
      let allSongs = storage.main.library.getSongs()
      
      // Filter songs by genre
      for song in allSongs {
        if let songGenre = song.genre?.name,
           songGenre.lowercased() == genreName.lowercased() {
          selectedSongs.append(song)
        }
      }
      
      // If no songs found for the exact genre, try to search for songs with similar metadata
      if selectedSongs.isEmpty {
        for song in allSongs {
          // Check if song metadata (like album name) contains references to the genre
          if let album = song.album,
             album.name.lowercased().contains(genreName.lowercased()) {
            selectedSongs.append(song)
          }
        }
      }
      
      // If songs were found, create a play context and start playing in shuffle mode
      if !selectedSongs.isEmpty {
        // Create a play context with the selected songs
        let playContext = PlayContext(
          name: "\(genreName) Music",
          playables: selectedSongs
        )
        
        // Use shuffle function to play the songs in random order
        appDelegate.player.play(context: playContext.getWithShuffledIndex())
      } else {
        // Show error alert if no songs found
        let alertController = UIAlertController(
          title: "No Songs Found",
          message: "Could not find any songs in the \(genreName) genre.",
          preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        present(alertController, animated: true)
      }
    }
  }
  
  @objc func decadeCardTapped(_ sender: UITapGestureRecognizer) {
    guard let tappedView = sender.view else { return }
    
    Task { @MainActor in
      let storage = appDelegate.storage
      
      // Get the hashValue from the tapped view's tag
      let decadeHashValue = tappedView.tag
      
      // Find the decade name based on hashValue
      let decadeNames = ["1960", "1970", "1980", "1990", "2000", "2010", "2020", "2025"]
      var selectedDecadeName: String?
      for decadeName in decadeNames {
        if decadeName.hashValue == decadeHashValue {
          selectedDecadeName = decadeName
          break
        }
      }
      
      guard let decadeName = selectedDecadeName else {
        // Show error alert if decade not found
        let alertController = UIAlertController(
          title: "Decade Not Found",
          message: "Could not find songs for the selected decade.",
          preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        present(alertController, animated: true)
        return
      }
      
      // Find songs from this decade
      var selectedSongs: [Song] = []
      let allSongs = storage.main.library.getSongs()
      
      // Define the decade range (e.g., 1960-1969 for "1960")
      let decadeStartYear = Int(decadeName) ?? 0
      let decadeEndYear = decadeName == "2025" ? decadeStartYear : decadeStartYear + 9
      
      // Filter songs by year
      for song in allSongs {
        let songYear = song.year
        if songYear >= decadeStartYear && songYear <= decadeEndYear {
          selectedSongs.append(song)
        }
      }
      
      // If no songs found for the exact decade, try to search for songs with similar metadata
      if selectedSongs.isEmpty {
        for song in allSongs {
          // Check if song metadata (like genre or album name) contains references to the decade
          if let album = song.album, album.name.contains(decadeName) ||
             song.genre?.name.contains(decadeName) == true {
            selectedSongs.append(song)
          }
        }
      }
      
      // If songs were found, create a play context and start playing in shuffle mode
      if !selectedSongs.isEmpty {
        // Create a play context with the selected songs
        let playContext = PlayContext(
          name: "\(decadeName)s Music",
          playables: selectedSongs
        )
        
        // Use shuffle function to play the songs in random order
        appDelegate.player.play(context: playContext.getWithShuffledIndex())
      } else {
        // Show alert if no songs found
        let alertController = UIAlertController(
          title: "No Songs Found",
          message: "No songs found for the \(decadeName)s decade in your library.",
          preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        present(alertController, animated: true)
      }
    }
  }
}

#if targetEnvironment(macCatalyst)
  class SearchNavigationItemContentView: UISearchBar, UIContentView, UISearchBarDelegate {
    private var currentConfiguration: SearchNavigationItemConfiguration
    var configuration: UIContentConfiguration {
      get { currentConfiguration }
      set {
        guard let config = newValue as? SearchNavigationItemConfiguration else { return }
        apply(config)
      }
    }

    init(configuration: SearchNavigationItemConfiguration) {
      self.currentConfiguration = configuration
      super.init(frame: CGRect(x: 0, y: 0, width: 100, height: 100))

      // We add the scope buttons, but never show them to the user. The user uses the navigatonbar items instead.
      self.showsScopeBar = false
      self.scopeButtonTitles = ["All", "Cached"]
      self.searchBarStyle = .minimal
      self.placeholder = "Search"
      self.delegate = self

      apply(configuration)

      NotificationCenter.default.addObserver(
        self,
        selector: #selector(handleSearchRequest(notification:)),
        name: .RequestSearchUpdate,
        object: nil
      )
    }

    @objc
    func handleSearchRequest(notification: Notification) {
      guard let window = notification.object as? UIWindow, window == self.window else { return }
      let userInfo = ["searchText": text ?? ""]
      NotificationCenter.default.post(name: .SearchChanged, object: window, userInfo: userInfo)
    }

    required init(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    private func apply(_ config: SearchNavigationItemConfiguration) {
      guard config != currentConfiguration else { return }

      currentConfiguration = config
      isUserInteractionEnabled = config.selected

      Task { @MainActor in
        try await Task.sleep(nanoseconds: 100_000_000)
        if config.selected {
          self.becomeFirstResponder()
        } else {
          self.resignFirstResponder()
        }
      }
    }

    // MARK: - Delegate

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
      // Inform all SearchVC about the new search string
      guard let sender = window else { return }
      NotificationCenter.default.post(
        name: .SearchChanged,
        object: sender,
        userInfo: ["searchText": searchText]
      )
    }
  }

  struct SearchNavigationItemConfiguration: UIContentConfiguration, Hashable {
    var selected: Bool = false

    func updated(for state: any UIConfigurationState) -> SearchNavigationItemConfiguration {
      let cellState = state as? UICellConfigurationState
      var newState = self
      newState.selected = cellState?.isSelected ?? false
      return newState
    }

    func makeContentView() -> UIView & UIContentView {
      SearchNavigationItemContentView(configuration: self)
    }
  }
#endif

typealias SideBarDiffableDataSource = UICollectionViewDiffableDataSource<Int, LibraryNavigatorItem>

// MARK: - LibraryNavigatorConfigurator

@MainActor
class LibraryNavigatorConfigurator: NSObject {
  static let sectionHeaderElementKind = "section-header-element-kind"

  private var data = [LibraryNavigatorItem]()
  private let offsetData: [LibraryNavigatorItem]
  private var collectionView: UICollectionView!
  private var dataSource: SideBarDiffableDataSource!
  private let layoutConfig: UICollectionLayoutListConfiguration
  private let pressedOnLibraryItemCB: (_: LibraryNavigatorItem) -> ()

  #if targetEnvironment(macCatalyst)
    private var preEditItem: LibraryNavigatorItem?
  #endif

  private var editButton: UIBarButtonItem!
  private var librarySettings = LibraryDisplaySettings.defaultSettings
  private var libraryInUse = [LibraryNavigatorItem]()
  private var libraryNotUsed = [LibraryNavigatorItem]()

  init(
    offsetData: [LibraryNavigatorItem],
    librarySettings: LibraryDisplaySettings,
    layoutConfig: UICollectionLayoutListConfiguration,
    pressedOnLibraryItemCB: @escaping (@MainActor (_: LibraryNavigatorItem) -> ())
  ) {
    self.offsetData = offsetData
    self.librarySettings = librarySettings
    self.layoutConfig = layoutConfig
    self.pressedOnLibraryItemCB = pressedOnLibraryItemCB
  }

  @MainActor
  func viewDidLoad(navigationItem: UINavigationItem, collectionView: UICollectionView) {
    self.collectionView = collectionView
    #if !targetEnvironment(macCatalyst)
      editButton = UIBarButtonItem(
        title: "Edit",
        style: .plain,
        target: self,
        action: #selector(editingPressed)
      )
      navigationItem.rightBarButtonItems = [editButton]
    #endif
    libraryInUse = librarySettings.inUse.map { LibraryNavigatorItem(
      title: $0.displayName,
      library: $0
    ) }
    libraryNotUsed = librarySettings.notUsed.map { LibraryNavigatorItem(
      title: $0.displayName,
      library: $0
    ) }
    self.collectionView.delegate = self
    self.collectionView.collectionViewLayout = createLayout() // 1 Configure the layout
    configureDataSource() // 2 configure the data Source
    applyInitialSnapshots() // 3 Apply the snapshots.
  }

  func viewIsAppearing(navigationItem: UINavigationItem, collectionView: UICollectionView) {
    #if targetEnvironment(macCatalyst)
      if self.collectionView.indexPathsForSelectedItems?.first == nil {
        self.collectionView.selectItem(at: .zero, animated: false, scrollPosition: .top)
      }
    #endif
  }

  @MainActor @objc
  private func editingPressed() {
    let isInEditMode = !collectionView.isEditing
    #if !targetEnvironment(macCatalyst)
      editButton.title = isInEditMode ? "Done" : "Edit"
      editButton.style = isInEditMode ? .done : .plain
    #endif

    if isInEditMode {
      #if targetEnvironment(macCatalyst)
        let selectedIndexPath = collectionView.indexPathsForSelectedItems?.first ?? .zero
        preEditItem = dataSource.itemIdentifier(for: selectedIndexPath)
      #endif

      collectionView.isEditing.toggle()
      var snapshot = dataSource.snapshot(for: 0)
      snapshot.append(libraryNotUsed)
      dataSource.apply(snapshot, to: 0, animatingDifferences: true)
    } else {
      collectionView.isEditing.toggle()
      var snapshot = dataSource.snapshot(for: 0)
      let inUse = snapshot.items.filter { $0.isSelected && ($0.library != nil) }.compactMap { $0 }
      struct Temp {
        let indexPath: IndexPath
        let item: LibraryNavigatorItem
      }
      let inUseItems = inUse.compactMap {
        if let indexPath = dataSource.indexPath(for: $0) {
          return Temp(indexPath: indexPath, item: $0)
        } else {
          return nil
        }
      }
      .sorted(by: { $0.indexPath < $1.indexPath })
      .compactMap { $0.item }
      libraryInUse = inUseItems

      var snapshot2 = dataSource.snapshot(for: 0)
      if !offsetData.isEmpty {
        let offsetItems = Array(snapshot.items[0 ... (offsetData.count - 1)])
        snapshot2.delete(offsetItems)
      }
      snapshot2.delete(libraryInUse)
      libraryNotUsed = snapshot2.items
      snapshot.delete(libraryNotUsed)
      appDelegate.storage.settings
        .libraryDisplaySettings = LibraryDisplaySettings(
          inUse: libraryInUse
            .compactMap { $0.library }
        )
      dataSource.apply(snapshot, to: 0, animatingDifferences: true)

      // Restore selection after editing endet on macOS
      #if targetEnvironment(macCatalyst)
        let indexPath = preEditItem != nil ? dataSource.indexPath(for: preEditItem!) : .zero
        collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .top)
      #endif
    }
  }

  private func createLayout() -> UICollectionViewLayout {
    let sectionProvider = { (
      sectionIndex: Int,
      layoutEnvironment: NSCollectionLayoutEnvironment
    ) -> NSCollectionLayoutSection? in
      let section = NSCollectionLayoutSection.list(
        using: self.layoutConfig,
        layoutEnvironment: layoutEnvironment
      )
      let headerFooterSize = NSCollectionLayoutSize(
        widthDimension: .fractionalWidth(1.0),
        heightDimension: .estimated(.leastNonzeroMagnitude)
      )
      let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
        layoutSize: headerFooterSize,
        elementKind: Self.sectionHeaderElementKind, alignment: .top
      )
      section.boundarySupplementaryItems = [sectionHeader]

      return section
    }
    return UICollectionViewCompositionalLayout(sectionProvider: sectionProvider)
  }

  @MainActor
  private func configureDataSource() {
    let cellRegistration = UICollectionView.CellRegistration<
      UICollectionViewListCell,
      LibraryNavigatorItem
    > { cell, indexPath, item in
      if !item.isInteractable {
        var content = cell.defaultContentConfiguration()
        content.text = item.title
        content.textProperties.font = .preferredFont(forTextStyle: .headline)

        #if targetEnvironment(macCatalyst)
          content.textProperties.color = .secondaryLabel
          // show edit on the right-hand side of the header
          cell.accessories = [
            .customView(configuration: .createEdit(
              target: self,
              action: #selector(self.editingPressed)
            )),
            .customView(configuration: .createDone(
              target: self,
              action: #selector(self.editingPressed)
            )),
          ]
        #else
          cell.accessories = []
        #endif
        cell.contentConfiguration = content
      } else if let libraryItem = item.library {
        var content = cell.defaultContentConfiguration()
        Self.configureForLibrary(contentView: &content, libraryItem: libraryItem)

        #if targetEnvironment(macCatalyst)
          cell.accessories = [.reorder()]
        #else
          cell.accessories = [.disclosureIndicator(displayed: .whenNotEditing), .reorder()]
        #endif

        if item.isSelected {
          cell.accessories.append(.customView(configuration: .createIsSelected()))
        } else {
          cell.accessories.append(.customView(configuration: .createUnSelected()))
        }
        cell.contentConfiguration = content
      } else if let tabItem = item.tab {
        #if targetEnvironment(macCatalyst)
          cell.accessories = []
          if tabItem == .search {
            let content = SearchNavigationItemConfiguration()
            cell.contentConfiguration = content
            cell.backgroundConfiguration = UIBackgroundConfiguration.clear()
          } else {
            var content = cell.defaultContentConfiguration()
            content.text = tabItem.title
            content.image = tabItem.icon
            cell.contentConfiguration = content
          }
        #else
          cell.accessories = [.disclosureIndicator()]
          var content = cell.defaultContentConfiguration()
          content.text = tabItem.title
          content.image = tabItem.icon
          cell.contentConfiguration = content
        #endif
      }
      cell.indentationLevel = 0
    }

    /// 1 - header registration
    let headerRegistration = UICollectionView.SupplementaryRegistration
    <UICollectionViewListCell>(elementKind: Self.sectionHeaderElementKind) {
      (supplementaryView, string, indexPath) in
      supplementaryView.isHidden = true
    }
    // 2 - data source
    dataSource = SideBarDiffableDataSource(collectionView: collectionView) {
      collectionView, indexPath, item -> UICollectionViewCell? in
      return collectionView.dequeueConfiguredReusableCell(
        using: cellRegistration,
        for: indexPath,
        item: item
      )
    }
    /// 3 - data source supplementaryViewProvider
    dataSource.supplementaryViewProvider = { view, kind, index in
      self.collectionView.dequeueConfiguredReusableSupplementary(
        using: headerRegistration,
        for: index
      )
    }

    /// 4 - data source reordering
    dataSource.reorderingHandlers.canReorderItem = { [weak self] item in
      let isEdit = self?.collectionView.isEditing ?? false
      return isEdit && (item.tab == nil)
    }

    // Somehow, this fixes a crash when trying to reorder the sidebar in catalyst. Leave it in.
    #if targetEnvironment(macCatalyst)
      dataSource.reorderingHandlers.didReorder = { _ in }
    #endif
  }

  @MainActor
  static func configureForLibrary(
    contentView: inout UIListContentConfiguration,
    libraryItem: LibraryDisplayType
  ) {
    contentView.text = libraryItem.displayName
    contentView.image = libraryItem.image.withRenderingMode(.alwaysTemplate)
    var imageSize = CGSize(width: 35.0, height: 25.0)
    if !libraryItem.image.isSymbolImage {
      // special case for podcast icon
      imageSize = CGSize(width: imageSize.width, height: imageSize.height - 2)
    }
    contentView.imageProperties.maximumSize = imageSize
    contentView.imageProperties.reservedLayoutSize = imageSize
  }

  private func applyInitialSnapshots() {
    var snapshot = NSDiffableDataSourceSnapshot<Int, LibraryNavigatorItem>()
    snapshot.appendSections([0])
    dataSource.apply(snapshot, animatingDifferences: false)

    data.append(contentsOf: offsetData)
    let libraryItems = librarySettings.inUse.map { LibraryNavigatorItem(
      title: $0.displayName,
      library: $0,
      isSelected: true
    ) }
    data.append(contentsOf: libraryItems)

    var outlineSnapshot = NSDiffableDataSourceSectionSnapshot<LibraryNavigatorItem>()
    outlineSnapshot.append(data)
    dataSource.apply(outlineSnapshot, to: 0, animatingDifferences: false)
  }
}

// MARK: UICollectionViewDelegate

extension LibraryNavigatorConfigurator: UICollectionViewDelegate {
  func collectionView(
    _ collectionView: UICollectionView,
    shouldSelectItemAt indexPath: IndexPath
  )
    -> Bool {
    if collectionView.isEditing {
      return indexPath.row >= offsetData.count
    } else if let item = dataSource.itemIdentifier(for: indexPath) {
      #if targetEnvironment(macCatalyst)
        // Do not allow reselecting an already selected cell
        guard let alreadySelected = collectionView.indexPathsForSelectedItems?.contains(indexPath),
              !alreadySelected else {
          return false
        }
      #endif
      return item.isInteractable
    } else {
      return false
    }
  }

  func collectionView(
    _ collectionView: UICollectionView,
    canEditItemAt indexPath: IndexPath
  )
    -> Bool {
    collectionView.isEditing
  }

  func collectionView(
    _ collectionView: UICollectionView,
    targetIndexPathForMoveOfItemFromOriginalIndexPath originalIndexPath: IndexPath,
    atCurrentIndexPath currentIndexPath: IndexPath,
    toProposedIndexPath proposedIndexPath: IndexPath
  )
    -> IndexPath {
    if proposedIndexPath.row >= offsetData.count {
      return proposedIndexPath
    } else {
      return IndexPath(row: offsetData.count, section: 0)
    }
  }

  func collectionView(
    _ collectionView: UICollectionView,
    didSelectItemAt indexPath: IndexPath
  ) {
    // handel selection
    guard !collectionView.isEditing else {
      collectionView.deselectItem(at: indexPath, animated: true)
      guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
      var snapshot = dataSource.snapshot()
      item.isSelected.toggle()
      snapshot.reconfigureItems([item])
      dataSource.apply(snapshot, animatingDifferences: false)
      return
    }
    // Retrieve the item identifier using index path.
    // The item identifier we get will be the selected data item

    guard let selectedItem = dataSource.itemIdentifier(for: indexPath) else {
      #if !targetEnvironment(macCatalyst)
        collectionView.deselectItem(at: indexPath, animated: true)
      #endif
      return
    }

    #if !targetEnvironment(macCatalyst)
      collectionView.deselectItem(at: indexPath, animated: false)
    #endif

    pressedOnLibraryItemCB(selectedItem)
  }
}

extension IndexPath {
  static let zero = IndexPath(row: 0, section: 0)
}

// Custom UIViewController subclass for Radio with vertical scrolling support
@MainActor
class RadioViewController: UIViewController {
  weak var mainScrollView: UIScrollView?
  weak var contentStackView: UIStackView?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Ensure scrolling is enabled
    mainScrollView?.isScrollEnabled = true
    mainScrollView?.bounces = true
    mainScrollView?.showsVerticalScrollIndicator = true
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    // Reset scroll position to top when page is navigated to
    mainScrollView?.setContentOffset(.zero, animated: false)
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    
    guard let scrollView = mainScrollView, let stackView = contentStackView else { return }
    
    // Set appropriate content insets for better scrolling
    let safeAreaInsets = view.safeAreaInsets
    scrollView.contentInset = UIEdgeInsets(
      top: 0,
      left: 0,
      bottom: safeAreaInsets.bottom + 20, // Extra padding at bottom
      right: 0
    )
    
    // Update content size for vertical scrolling
    let contentHeight = stackView.frame.size.height + 40 // Add some padding
    if contentHeight > scrollView.frame.size.height {
      scrollView.contentSize = CGSize(width: scrollView.frame.size.width, height: contentHeight)
    }
    
    // Force the scroll view to update its layout
    scrollView.layoutIfNeeded()
  }
}

// Custom UIViewController subclass for Discover More with vertical scrolling support
@MainActor
class DiscoverMoreViewController: UIViewController {
  weak var mainScrollView: UIScrollView?
  weak var contentStackView: UIStackView?
  private var profileImageButton: UIButton!
  private var profileImageView: UIImageView!
  private let profileImageSize: CGFloat = 36
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Ensure scrolling is enabled
    mainScrollView?.isScrollEnabled = true
    mainScrollView?.bounces = true
    mainScrollView?.showsVerticalScrollIndicator = true
    
    // Setup profile picture
    setupProfilePicture()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    // Reset scroll position to top when page is navigated to
    mainScrollView?.setContentOffset(.zero, animated: false)
    
    // Update profile picture
    updateProfilePicture()
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    
    guard let scrollView = mainScrollView, let stackView = contentStackView else { return }
    
    // Set appropriate content insets for better scrolling
    let safeAreaInsets = view.safeAreaInsets
    scrollView.contentInset = UIEdgeInsets(
      top: 0,
      left: 0,
      bottom: safeAreaInsets.bottom + 20, // Extra padding at bottom
      right: 0
    )
    
    // Update content size for vertical scrolling
    let contentHeight = stackView.frame.size.height + 40 // Add some padding
    if contentHeight > scrollView.frame.size.height {
      scrollView.contentSize = CGSize(width: scrollView.frame.size.width, height: contentHeight)
    }
    
    // Force the scroll view to update its layout
    scrollView.layoutIfNeeded()
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
    
    // Make sure the image view is centered in the button
    profileImageView.center = CGPoint(x: profileImageButton.bounds.width/2, y: profileImageButton.bounds.height/2)
    
    profileImageButton.addTarget(self, action: #selector(profilePictureTapped), for: .touchUpInside)
    
    // Create a UIBarButtonItem with the profile button
    let profileButtonItem = UIBarButtonItem(customView: profileImageButton)
    
    // Add profile button to the right of navigation bar - make it the rightmost item
    navigationItem.rightBarButtonItem = profileButtonItem
    
    // Update profile picture if exists
    updateProfilePicture()
  }
  
  private func updateProfilePicture() {
    if let appDelegate = UIApplication.shared.delegate as? AppDelegate,
       let profilePicturePath = appDelegate.storage.settings.profilePicturePath,
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
    if let appDelegate = UIApplication.shared.delegate as? AppDelegate,
       appDelegate.storage.settings.profilePicturePath != nil {
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
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate,
           let oldPath = appDelegate.storage.settings.profilePicturePath {
          try? FileManager.default.removeItem(atPath: oldPath)
        }
        
        // Save the new path
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
          appDelegate.storage.settings.profilePicturePath = fileURL.path
        }
        
        // Update the UI
        updateProfilePicture()
      } catch {
        print("Error saving profile picture: \(error)")
      }
    }
  }
  
  private func removeProfilePicture() {
    if let appDelegate = UIApplication.shared.delegate as? AppDelegate,
       let profilePicturePath = appDelegate.storage.settings.profilePicturePath {
      // Remove the file
      try? FileManager.default.removeItem(atPath: profilePicturePath)
      
      // Clear the path
      appDelegate.storage.settings.profilePicturePath = nil
      
      // Update UI with placeholder
      profileImageView.image = UIImage(systemName: "person.crop.circle.fill")
      profileImageView.tintColor = .systemGray2
    }
  }
}

// MARK: - UIImagePickerControllerDelegate for DiscoverMoreViewController
extension DiscoverMoreViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
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

// MARK: - PHPickerViewControllerDelegate for DiscoverMoreViewController
@available(iOS 14, *)
extension DiscoverMoreViewController: PHPickerViewControllerDelegate {
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
        
