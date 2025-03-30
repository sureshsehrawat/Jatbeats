//
//  DeveloperView.swift
//  Amperfy
//
//  Created by Maximilian Bauer on 14.06.24.
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
import SwiftUI
import UIKit

// MARK: - DeveloperView

struct DeveloperView: View {
  @EnvironmentObject
  private var settings: Settings
  
  // Helper to access AmperfyKit bundle
  private var amperfyKitBundle: Bundle {
    return Bundle(for: AmperfyKit.AmperKit.self)
  }

  var body: some View {
    ZStack {
      SettingsList {
        SettingsSection(content: {
          VStack(spacing: 16) {
            // Profile card
            ZStack {
              RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.systemGray6))
                .shadow(radius: 2)
              
              VStack(spacing: 12) {
                // Load image from assets
                Image("suresh", bundle: Bundle(for: AmperfyKit.AmperKit.self))
                  .resizable()
                  .aspectRatio(contentMode: .fit)
                  .frame(width: 320, height: 320)
                  .clipShape(RoundedRectangle(cornerRadius: 8))
                  .shadow(radius: 2)
                
                // Name text
                Text("Suresh Sehrawat")
                  .font(.headline)
                  .foregroundColor(.primary)
              }
              .padding()
            }
            .frame(maxWidth: .infinity)
            
            // Copyright text in a separate container
            ZStack {
              RoundedRectangle(cornerRadius: 8)
                .fill(Color(UIColor.systemGray6))
              
              Text("Designed and developed by Suresh Sehrawat @ 2025 Jatbeats. All rights reserved.")
                .font(.caption)
                .multilineTextAlignment(.center)
                .padding()
                .foregroundColor(.secondary)
            }
          }
          .padding(.vertical, 8)
        })
      }
    }
    .navigationTitle("Developer")
    .navigationBarTitleDisplayMode(.inline)
  }
}

// MARK: - DeveloperView_Previews

struct DeveloperView_Previews: PreviewProvider {
  @State
  static var settings = Settings()

  static var previews: some View {
    DeveloperView().environmentObject(settings)
  }
}
