//
//  AlbumCollectionCell.swift
//  Amperfy
//
//  Created by Maximilian Bauer on 21.01.22.
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

import AmperfyKit
import UIKit

class AlbumCollectionCell: BasicCollectionCell {
  @IBOutlet
  weak var titleLabel: UILabel!
  @IBOutlet
  weak var subtitleLabel: UILabel!
  @IBOutlet
  weak var entityImage: EntityImageView!
  @IBOutlet
  weak var artworkImageWidthConstraint: NSLayoutConstraint!

  static let maxWidth: CGFloat = 250.0

  private var container: PlayableContainable?
  private var rootView: UICollectionViewController?
  private var rootFlowLayout: UICollectionViewDelegateFlowLayout?

  // Store the last computed size to avoid redundant calculations
  private var lastCalculatedItemSize: CGSize?
  private var lastCalculatedIndexPath: IndexPath?

  func display(
    container: PlayableContainable,
    rootView: UICollectionViewController,
    rootFlowLayout: UICollectionViewDelegateFlowLayout,
    initialIndexPath: IndexPath
  ) {
    self.container = container
    self.rootView = rootView
    self.rootFlowLayout = rootFlowLayout
    
    // Apple Music style: bold title and limited to 1 line, smaller height
    titleLabel.text = container.name
    titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
    titleLabel.lineBreakMode = .byTruncatingTail
    titleLabel.numberOfLines = 1
    
    // Apple Music style: gray artist name and limited to 1 line, smaller font
    subtitleLabel.text = container.subtitle
    subtitleLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
    subtitleLabel.textColor = .secondaryLabel
    subtitleLabel.lineBreakMode = .byTruncatingTail
    subtitleLabel.numberOfLines = 1
    
    // Apple Music style artwork with rounded corners
    entityImage.display(
      theme: appDelegate.storage.settings.themePreference,
      container: container,
      cornerRadius: .appleMusic
    )
    
    updateArtworkImageConstraint(indexPath: initialIndexPath)
    
    // Adding this to avoid layout thrashing during scrolling
    setNeedsLayout()
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    
    // Only update constraints when needed, not during every scroll
    if let indexPath = rootView?.collectionView.indexPath(for: self),
       lastCalculatedIndexPath != indexPath || lastCalculatedItemSize == nil {
      updateArtworkImageConstraint(indexPath: indexPath)
      lastCalculatedIndexPath = indexPath
    }
  }

  func updateArtworkImageConstraint(indexPath: IndexPath) {
    if let rootView = rootView,
       let rootFlowLayout = rootFlowLayout {
      
      // Use cached size if available for the same collection view width
      var itemSize: CGSize?
      
      if let lastSize = lastCalculatedItemSize, 
         rootView.collectionView.bounds.width == lastSize.width {
        itemSize = lastSize
      } else {
        itemSize = rootFlowLayout.collectionView?(
          rootView.collectionView,
          layout: rootView.collectionView.collectionViewLayout,
          sizeForItemAt: indexPath
        )
        if let size = itemSize {
          lastCalculatedItemSize = size
        }
      }
      
      if let size = itemSize {
        let newImageWidth = min(size.width, size.height)
        // Only update constraint if the width actually changed
        if artworkImageWidthConstraint.constant != newImageWidth {
          artworkImageWidthConstraint.constant = newImageWidth
        }
      }
    }
  }
}
