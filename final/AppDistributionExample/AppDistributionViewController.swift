// Copyright 2020 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import UIKit
import Firebase

class AppDistributionViewController: UIViewController {
  var checkForUpdateButton: UIButton?
  var signInOutButton: UIButton?
  var signedInStatus: UILabel?
  var currentVersion: UILabel?
  let primaryButtonColor: UIColor = .init(red: 0.10, green: 0.44, blue: 0.91, alpha: 1)
  let secondaryButtonColor: UIColor = .init(red: 0.40, green: 0.23, blue: 0.71, alpha: 1)

  override func viewDidLoad() {
    super.viewDidLoad()
    configureNavigationBar()

    currentVersion = UILabel(frame: CGRect(x: 50, y: 150, width: 400, height: 50))
    let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")
    let build = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String)
    currentVersion!.text = "App Info: Version - \(version ?? ""), Build - \(build ?? "")"
    currentVersion!.textColor = .orange
    currentVersion!.font = .systemFont(ofSize: 18.0)
    view.addSubview(currentVersion!)

    // Show check for update button only if tester is signed in
    checkForUpdateButton = UIButton(frame: CGRect(x: 50, y: 300, width: 300, height: 50))
    configureCheckForUpdateButton()
    view.addSubview(checkForUpdateButton!)

    // Toggle sign in and sign out based on whether tester is signed in
    signInOutButton = UIButton(frame: CGRect(x: 50, y: 400, width: 300, height: 50))
    configureSignInSignOutButton()
    signInOutButton!.addTarget(self, action: #selector(signInOutButtonClicked), for: .touchUpInside)
    view.addSubview(signInOutButton!)

    // Toggle sign in status based on whether tester is signed in or nor
    signedInStatus = UILabel(frame: CGRect(x: 120, y: 500, width: 400, height: 50))
    configureSignInStatus()
    view.addSubview(signedInStatus!)
  }

  override func viewDidAppear(_ animated: Bool) {
    // checkForUpdate()
  }

  // MARK: - Firebase 🔥
  private func checkForUpdate() {
    AppDistribution.appDistribution().checkForUpdate(completion: { [self] release, error in
      var uiAlert: UIAlertController

      if error != nil {
        uiAlert = UIAlertController(title: "Error", message: "Error Checking for update! \(error?.localizedDescription ?? "")", preferredStyle: .alert)
      } else if release == nil {
        uiAlert = UIAlertController(title: "Check for Update", message: "No releases found!!", preferredStyle: .alert)
        uiAlert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default))
      } else {
        guard let release = release else { return }

        let title = "New Version Available"
        let message = "Version \(release.displayVersion)(\(release.buildVersion)) is available."
        uiAlert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        uiAlert.addAction(UIAlertAction(title: "Update", style: UIAlertAction.Style.default) {
          _ in
          UIApplication.shared.open(release.downloadURL)
        })
        uiAlert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel) {
          _ in
        })
      }
      self.present(uiAlert, animated: true, completion: nil)
    })
  }

  @objc func checkForUpdateButtonClicked() {
    checkForUpdate()
  }

  private func isTesterSignedIn() -> Bool {
    return AppDistribution.appDistribution().isTesterSignedIn
  }

  @objc func signInOutButtonClicked() {
    if isTesterSignedIn() {
      AppDistribution.appDistribution().signOutTester()

      self.configureCheckForUpdateButton()
      self.configureSignInSignOutButton()
      self.configureSignInStatus()

    } else {
      AppDistribution.appDistribution().signInTester(completion: { error in
        if error == nil {
          self.configureCheckForUpdateButton()
          self.configureSignInSignOutButton()
          self.configureSignInStatus()
        } else {
          let uiAlert = UIAlertController(title: "Custom:Error", message: "Error during tester sign in! \(error?.localizedDescription ?? "")", preferredStyle: .alert)
          uiAlert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default) {
            _ in
          })

          self.present(uiAlert, animated: true, completion: nil)
        }
      })
    }
  }



  // MARK: - Private Helpers
  private func configureCheckForUpdateButton() {
    checkForUpdateButton!.backgroundColor = primaryButtonColor
    checkForUpdateButton!.setTitle("Check for Update Manually", for: .normal)
    checkForUpdateButton!.addTarget(self, action: #selector(checkForUpdateButtonClicked), for: .touchUpInside)
    checkForUpdateButton!.isHidden = !isTesterSignedIn()
  }

  private func configureSignInSignOutButton() {
    signInOutButton!.backgroundColor = isTesterSignedIn() ? secondaryButtonColor : primaryButtonColor
    signInOutButton!.setTitleColor(.white, for: .normal)
    let title = isTesterSignedIn() ? "Sign Out" : "Sign In"
    signInOutButton!.setTitle(title, for: .normal)
    signInOutButton!.setTitleColor(.white, for: .normal)
    signInOutButton!.isHidden = false
  }

  private func configureSignInStatus() {
    signedInStatus!.textColor = isTesterSignedIn() ? .green : .orange
    signedInStatus!.font = .boldSystemFont(ofSize: 20.0)
    signedInStatus!.text = isTesterSignedIn() ? "Tester is signed in" : "Tester is signed out"
  }

  private func configureNavigationBar() {
    navigationItem.title = "Firebase App Distribution"
    guard let navigationBar = navigationController?.navigationBar else { return }
    navigationBar.prefersLargeTitles = true
    navigationBar.titleTextAttributes = [.foregroundColor: UIColor.systemOrange]
    navigationBar.largeTitleTextAttributes = [.foregroundColor: UIColor.systemOrange]
  }
}
