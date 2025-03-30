//
//  TabBarVC.swift
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

class TabBarVC: UITabBarController {
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Configure tab bar with all available tabs from TabNavigatorItem
    configureTabBar()
  }

  override func viewIsAppearing(_ animated: Bool) {
    super.viewIsAppearing(animated)
  }
  
  private func configureTabBar() {
    // Get existing view controllers (first two should be Library and Player)
    let viewControllers = self.viewControllers ?? []
    
    // If we already have all tabs configured, don't add them again
    if viewControllers.count >= 5 {
      return
    }
    
    // Make sure we have at least the first two tabs (Library and Player)
    guard viewControllers.count >= 2 else { return }
    
    // Set custom icon for the library tab
    if let libraryVC = viewControllers[0] as? UINavigationController {
      libraryVC.tabBarItem = UITabBarItem(
        title: "Library",
        image: UIImage(named: "library_icon"),
        tag: 0
      )
    }
    
    // Add the Discover More and Settings tabs from TabNavigatorItem
    // (Removing the duplicate search tab)
    let newTab = TabNavigatorItem.new.controller
    newTab.tabBarItem = UITabBarItem(
      title: TabNavigatorItem.new.title,
      image: UIImage(systemName: "square.grid.2x2.fill"),
      selectedImage: UIImage(systemName: "square.grid.2x2.fill")
    )
    
    let radioTab = TabNavigatorItem.radio.controller
    radioTab.tabBarItem = UITabBarItem(
      title: "Radio",
      image: UIImage(systemName: "dot.radiowaves.left.and.right"),
      selectedImage: UIImage(systemName: "dot.radiowaves.left.and.right.fill")
    )
    
    let settingsTab = TabNavigatorItem.settings.controller
    settingsTab.tabBarItem = UITabBarItem(
      title: TabNavigatorItem.settings.title,
      image: TabNavigatorItem.settings.icon,
      tag: TabNavigatorItem.settings.rawValue
    )
    
    // Preserve the Library and Player tabs at positions 0 and 1
    // Then insert New tab at position 2 (after Library and Player)
    let libraryTab = viewControllers[0]
    let playerTab = viewControllers[1]
    
    // Set the complete list of view controllers in the desired order
    // Removed the searchTab from the list to avoid duplication
    self.viewControllers = [
      libraryTab,
      newTab,
      playerTab,
      radioTab,
      settingsTab
    ]
  }
}
