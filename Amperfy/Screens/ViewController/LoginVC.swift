//
//  LoginVC.swift
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

extension String {
  var isHyperTextProtocolProvided: Bool {
    hasPrefix("https://") || hasPrefix("http://")
  }
}

// MARK: - LoginVC

class LoginVC: UIViewController {
  var backendApi: BackendApi!
  var selectedApiType: BackenApiType = .notDetected
  // Hardcoded server URL for JatBeats
  private let jatBeatsServerUrl = "https://beats.jatcloud.com"

  @IBOutlet
  weak var serverUrlTF: UITextField!
  @IBOutlet
  weak var usernameTF: UITextField!
  @IBOutlet
  weak var passwordTF: UITextField!
  @IBOutlet
  weak var apiSelectorButton: BasicButton!

  @IBAction
  func serverUrlActionPressed() {
    serverUrlTF.resignFirstResponder()
    login()
  }

  @IBAction
  func usernameActionPressed() {
    usernameTF.resignFirstResponder()
    login()
  }

  @IBAction
  func passwordActionPressed() {
    passwordTF.resignFirstResponder()
    login()
  }

  @IBAction
  func loginPressed() {
    serverUrlTF.resignFirstResponder()
    usernameTF.resignFirstResponder()
    passwordTF.resignFirstResponder()
    login()
  }

  func login() {
    // Use hardcoded JatBeats URL instead of text field
    let serverUrl = jatBeatsServerUrl
    
    guard serverUrl.isHyperTextProtocolProvided else {
      showErrorMsg(message: "Please provide either 'https://' or 'http://' in your server URL.")
      return
    }
    guard let username = usernameTF.text, !username.isEmpty else {
      showErrorMsg(message: "No username given!")
      return
    }
    guard let password = passwordTF.text, !password.isEmpty else {
      showErrorMsg(message: "No password given!")
      return
    }

    var credentials = LoginCredentials(serverUrl: serverUrl, username: username, password: password)
    Task { @MainActor in
      do {
        let authenticatedApiType = try await self.appDelegate.backendApi.login(
          apiType: selectedApiType,
          credentials: credentials
        )
        self.appDelegate.backendApi.selectedApi = authenticatedApiType
        credentials.backendApi = authenticatedApiType
        self.appDelegate.storage.loginCredentials = credentials
        self.appDelegate.backendApi.provideCredentials(credentials: credentials)
        self.performSegue(withIdentifier: "toSync", sender: self)
      } catch {
        if error is AuthenticationError {
          self.showErrorMsg(message: error.localizedDescription)
        } else {
          self.showErrorMsg(message: "Not able to login!")
        }
      }
    }
  }

  func showErrorMsg(message: String) {
    let alert = UIAlertController(title: "Login failed", message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default))
    present(alert, animated: true, completion: nil)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    backendApi = appDelegate.backendApi
    
    // Always use subsonic as the API type
    selectedApiType = .subsonic
    
    // Hide server URL input and API selector
    serverUrlTF.isHidden = true
    apiSelectorButton.isHidden = true
    
    // The following commented out code is preserved for reference but not used
    /*
    apiSelectorButton.showsMenuAsPrimaryAction = true
    apiSelectorButton.menu = UIMenu(title: "Select API", children: [
      UIAction(title: BackenApiType.notDetected.selectorDescription, handler: { _ in
        self.selectedApiType = .notDetected
        self.updateApiSelectorText()
      }),
      UIAction(title: BackenApiType.ampache.selectorDescription, handler: { _ in
        self.selectedApiType = .ampache
        self.updateApiSelectorText()
      }),
      UIAction(title: BackenApiType.subsonic.selectorDescription, handler: { _ in
        self.selectedApiType = .subsonic
        self.updateApiSelectorText()
      }),
      UIAction(title: BackenApiType.subsonic_legacy.selectorDescription, handler: { _ in
        self.selectedApiType = .subsonic_legacy
        self.updateApiSelectorText()
      }),
    ])
    
    // Format button to ensure text is fully visible
    formatApiSelectorButton()
    */
  }

  override func viewIsAppearing(_ animated: Bool) {
    super.viewIsAppearing(animated)
    if let credentials = appDelegate.storage.loginCredentials {
      // Don't set server URL from credentials, use our hardcoded one
      usernameTF.text = credentials.username
    }
  }

  func updateApiSelectorText() {
    apiSelectorButton.setTitle("\(selectedApiType.selectorDescription)", for: .normal)
    // Size to fit to ensure text is fully visible
    apiSelectorButton.sizeToFit()
  }
  
  // Update API selector button title with better formatting
  func formatApiSelectorButton() {
    // Update button appearance
    apiSelectorButton.contentHorizontalAlignment = .center
    apiSelectorButton.titleLabel?.lineBreakMode = .byTruncatingTail
    apiSelectorButton.titleLabel?.adjustsFontSizeToFitWidth = true
    
    if #available(iOS 15.0, *) {
      // Use modern button configuration
      var config = UIButton.Configuration.plain()
      config.titlePadding = 20
      config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)
      apiSelectorButton.configuration = config
    } else {
      // For older iOS versions
      let buttonPadding: CGFloat = 20
      apiSelectorButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: buttonPadding, bottom: 0, right: buttonPadding)
    }
    
    // Ensure text is fully visible
    updateApiSelectorText()
  }
}
