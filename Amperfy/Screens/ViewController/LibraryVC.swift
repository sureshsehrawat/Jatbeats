//
//  LibraryVC.swift
//  Amperfy
//
//  Created by Maximilian Bauer on 09.03.19.
//  Copyright (c) 2019 Maximilian Bauer. All rights reserved.
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
import PhotosUI

@MainActor
class LibraryVC: KeyCommandCollectionViewController {
  private var offsetData = [LibraryNavigatorItem]()
  private var headerView: UIView?
  private var profileImageButton: UIButton!
  private var profileImageView: UIImageView!
  private let profileImageSize: CGFloat = 36

  lazy var layoutConfig = {
    var config = UICollectionLayoutListConfiguration(appearance: .sidebarPlain)
    config.backgroundColor = .systemBackground
    config.headerMode = .supplementary
    return config
  }()

  lazy var libraryItemConfigurator = LibraryNavigatorConfigurator(
    offsetData: offsetData,
    librarySettings: appDelegate.storage.settings.libraryDisplaySettings,
    layoutConfig: self.layoutConfig,
    pressedOnLibraryItemCB: self.pushedOn
  )

  override func viewDidLoad() {
    super.viewDidLoad()
    libraryItemConfigurator.viewDidLoad(
      navigationItem: navigationItem,
      collectionView: collectionView
    )
    setupLogo()
    setupProfilePicture()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    updateProfilePicture()
  }
  
  private func setupLogo() {
    // Create logo image view
    let logoImageView = UIImageView(image: UIImage(named: "logo"))
    logoImageView.contentMode = .scaleAspectFit
    
    // Make the logo bigger
    let logoHeight: CGFloat = 56
    let logoWidth: CGFloat = 180
    
    // Create a properly sized container view
    let containerView = UIView(frame: CGRect(x: 0, y: 0, width: logoWidth, height: logoHeight))
    containerView.backgroundColor = .clear
    
    // Configure logo with constraints for proper centering
    logoImageView.translatesAutoresizingMaskIntoConstraints = false
    containerView.addSubview(logoImageView)
    
    NSLayoutConstraint.activate([
        logoImageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
        logoImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
        logoImageView.heightAnchor.constraint(equalToConstant: logoHeight),
        logoImageView.widthAnchor.constraint(equalToConstant: logoWidth)
    ])
    
    // Set the container as the titleView of the navigation item
    navigationItem.titleView = containerView
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
    profileImageButton.addTarget(self, action: #selector(profilePictureTapped), for: .touchUpInside)
    
    // Create a UIBarButtonItem with the profile button
    let profileButtonItem = UIBarButtonItem(customView: profileImageButton)
    
    // Create a fixed space bar button item to add spacing
    let spacerItem = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
    spacerItem.width = 12 // Adjust this value to increase/decrease spacing
    
    // Get the existing right bar button items (should have the edit button)
    if let rightBarButtonItems = navigationItem.rightBarButtonItems {
      // Add the profile button to the left of the edit button with spacing in between
      navigationItem.rightBarButtonItems = [rightBarButtonItems[0], spacerItem, profileButtonItem]
    } else {
      navigationItem.rightBarButtonItems = [profileButtonItem]
    }
    
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

  public func pushedOn(selectedItem: LibraryNavigatorItem) {
    guard let splitVC = splitViewController as? SplitVC,
          splitVC.isCollapsed,
          let libraryItem = selectedItem.library
    else { return }
    splitVC
      .pushReplaceNavLibrary(vc: libraryItem.controller(settings: appDelegate.storage.settings))
  }
}

// MARK: - UIImagePickerControllerDelegate
extension LibraryVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
    picker.dismiss(animated: true)
    
    if let editedImage = info[.editedImage] as? UIImage {
      saveProfilePicture(editedImage)
    } else if let originalImage = info[.originalImage] as? UIImage {
      saveProfilePicture(originalImage)
    }
  }
  
  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    picker.dismiss(animated: true)
  }
}

// MARK: - PHPickerViewControllerDelegate
@available(iOS 14, *)
extension LibraryVC: PHPickerViewControllerDelegate {
  func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
    picker.dismiss(animated: true)
    
    guard let result = results.first else { return }
    
    result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
      if let error = error {
        print("Error loading image: \(error)")
        return
      }
      
      guard let image = object as? UIImage else { return }
      
      DispatchQueue.main.async {
        self?.saveProfilePicture(image)
      }
    }
  }
}
