//
//  AppDelegate.swift
//  DSClickableURLTextField
//
//  Created by Christopher Atlan on 06.11.22.
//

import Cocoa
import DSClickableURLTextField

@main
class AppDelegate: NSObject, NSApplicationDelegate, DSClickableURLTextFieldDelegate {

    @IBOutlet var window: NSWindow!
    @IBOutlet var buildinLabel: NSTextField!
    @IBOutlet var clickableLabel: DSClickableURLTextField!
    @IBOutlet var termsAndPolicyLabel: NSTextField!

    override func awakeFromNib() {
        clickableLabel.canCopyURLs = true
        clickableLabel.delegate = self
        
        let crazyOnes = "Here’s to the crazy ones. The misfits. The rebels. The square pegs in the round holes.\nThe ones who see things differently. They’re [not fond of rules](https://www.youtube.com/watch?v=E4WlUXrJgy4)."
        let termsAndPolicy = "[Terms of Service](https://example.com) | [Privacy Policy](https://example.com)"
        do {
            buildinLabel.attributedStringValue = try NSAttributedString(markdown: crazyOnes)
            clickableLabel.attributedStringValue = try NSAttributedString(markdown: crazyOnes)
            termsAndPolicyLabel.attributedStringValue = try NSAttributedString(markdown: termsAndPolicy)
        } catch {
        }
    }
    
    func textField(_ textField: NSTextField, openURL: URL) {
        let alert = NSAlert()
        alert.messageText = "textField(_:openURL:) delegate example"
        alert.informativeText = "Are you sure you want to open the link?"
        alert.addButton(withTitle: "Open")
        alert.addButton(withTitle: "Cancel")
        let result = alert.runModal()
        if result == .alertFirstButtonReturn {
            NSWorkspace.shared.open(openURL)
        }
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }


}

