/*
    DSClickableURLTextField
    
    Copyright (c) 2006 - 2007 Night Productions, by Darkshadow. All Rights Reserved.
    http://www.nightproductions.net/developer.htm
    darkshadow@nightproductions.net
    
    May be used freely, but keep my name/copyright in the header.
    
    There is NO warranty of any kind, express or implied; use at your own risk.
    Responsibility for damages (if any) to anyone resulting from the use of this
    code rests entirely with the user.
    
    ------------------------------------
    
    * August 25, 2006 - initial release
    * August 30, 2006
        • Fixed a bug where cursor rects would be enabled even if the
          textfield wasn't visible.  i.e. it's in a scrollview, but the
          textfield isn't scrolled to where it's visible.
        • Fixed an issue where mouseUp wouldn't be called and so clicking
          on the URL would have no effect when the textfield is a subview
          of a splitview (and maybe some other certain views).  I did this
          by NOT calling super in -mouseDown:.  Since the textfield is
          non-editable and non-selectable, I don't believe this will cause
          any problems.
        • Fixed the fact that it was using the textfield's bounds rather than
          the cell's bounds to calculate rects.
    * May 25, 2007
        Contributed by Jens Miltner:
            • Fixed a problem with the text storage and the text field's
              attributed string value having different lengths, causing
              range exceptions.
            • Added a delegate method allowing custom handling of URLs.
            • Tracks initially clicked URL at -mouseDown: to avoid situations
              where dragging would end up in a different URL at -mouseUp:, opening
              that URL. This includes situations where the user clicks on an empty
              area of the text field, drags the mouse, and ends up on top of a
              link, which would then erroneously open that link.
            • Fixed to allow string links to work as well as URL links.
        Changes by Darkshadow:
            • Overrode -initWithCoder:, -initWithFrame:, and -awakeFromNib to
              explicitly set the text field to be non-editable and
              non-selectable.  Now you don't need to remember to set this up,
              and the class will work correctly regardless.
            • Added in the ability for the user to copy URLs to the clipboard.
              Note that this is off by default.
            • Some code clean up.
    * Nov 6, 2022
        Changes by Christopher Atlan:
            • Replace soft deprecated API usage with modern replacements
            • For container size take cell.wraps into account
            • Update container size before updating tracking area
            • Overrode isEditable and isSelectable to explicitly set
              non-editable and non-selectable.
            • Swift
*/

import AppKit

@objc public protocol DSClickableURLTextFieldDelegate : NSTextFieldDelegate {
    @objc optional func textField(_ textField: NSTextField, openURL: URL)
}

@objc public class DSClickableURLTextField: NSTextField {
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        isEditable = false
        isSelectable = false
    }
    
    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        isEditable = false
        isSelectable = false
    }
    
    /* Enforces that the text field be non-editable and
        non-selectable. Probably not needed, but I always
        like to be cautious.
    */
    public override func awakeFromNib() {
        isEditable = false
        isSelectable = false
    }
    
    override public var isEditable: Bool {
        get {
            return super.isEditable
        }
        set {
            if newValue {
                NSLog("Warning: DSClickableURLTextField enforces that the text field be non-editable and  non-selectable")
            }
            super.isEditable = false
        }
    }
    
    override public var isSelectable: Bool {
        get {
            return super.isSelectable
        }
        set {
            if newValue {
                NSLog("Warning: DSClickableURLTextField enforces that the text field be non-editable and  non-selectable")
            }
            super.isSelectable = false
        }
    }
    
    public override var stringValue: String {
        get {
            return super.stringValue
        }
        set {
            attributedStringValue = NSAttributedString(string: newValue)
        }
    }
    
    public override var attributedStringValue: NSAttributedString {
        get {
            return super.attributedStringValue
        }
        set {
            shadowTextStorage.setAttributedString(newValue)
            super.attributedStringValue = newValue
            updateURLTrackingAreas()
        }
    }
    
    let shadowLayoutManager = NSLayoutManager.init()
    
    var shadowTextContainerSize: NSSize {
        guard let cell else { return NSSize.zero }
        let cellBounds = cell.drawingRect(forBounds: bounds)
        let cellWraps = (cell.isScrollable || cell.wraps)
        let containerSize: NSSize
        if cellWraps {
            containerSize = NSSize.init(width: cellBounds.width, height: CGFloat.greatestFiniteMagnitude)
        } else {
            containerSize = NSSize.init(width: CGFloat.greatestFiniteMagnitude, height: cellBounds.height)
        }
        return containerSize
    }
    
    lazy var shadowTextContainer: NSTextContainer = {
        let containerSize = shadowTextContainerSize
        return NSTextContainer.init(containerSize: containerSize)
    }()
    
    lazy var shadowTextStorage: NSTextStorage = {
        let textStorage = NSTextStorage.init()
        
        textStorage.addLayoutManager(shadowLayoutManager)
        shadowLayoutManager.addTextContainer(shadowTextContainer)
        shadowTextContainer.lineFragmentPadding = 2.0
        
        textStorage.setAttributedString(attributedStringValue)
        
        return textStorage
    }()
    
    var URLTrackingAreas = [NSTrackingArea]()
    
    var clickedURL: URL? = nil
    
    func updateURLTrackingAreas() {
        let cellBounds = cell?.drawingRect(forBounds: bounds) ?? NSRect.zero
        let superVisRect = convert(superview!.visibleRect, from: superview)
        var newTrackingAreas = [NSTrackingArea]()
        
        shadowTextContainer.containerSize = shadowTextContainerSize
        
        shadowTextStorage.enumerateAttribute(NSAttributedString.Key.link, in: NSRange.init(location: 0, length: shadowTextStorage.length)) { value, range, stop in
            if value != nil {
                let glyphRange = shadowLayoutManager.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
                shadowLayoutManager.enumerateEnclosingRects(forGlyphRange: glyphRange, withinSelectedGlyphRange: glyphRange, in: shadowTextContainer) { rect, stop in
                    
                    let glyphRect = rect.insetBy(dx: cellBounds.origin.x, dy: cellBounds.origin.y)
                    let textRect = glyphRect.intersection(cellBounds)
                    let cursorRect = glyphRect.intersection(superVisRect)
                    if textRect.intersects(superVisRect) {
                        let trackingArea = NSTrackingArea.init(rect: cursorRect, options: [.activeInKeyWindow, .cursorUpdate], owner: nil)
                        newTrackingAreas.append(trackingArea)
                    }
                }
            }
        }
        for trackingArea in URLTrackingAreas {
            removeTrackingArea(trackingArea)
        }
        for trackingArea in newTrackingAreas {
            addTrackingArea(trackingArea)
        }
        URLTrackingAreas = newTrackingAreas
    }
    
    func URLForMouseEvent(_ event: NSEvent) -> URL? {
        let mousePoint = convert(event.locationInWindow, from: nil)
        let cellBounds = cell?.drawingRect(forBounds: bounds) ?? NSRect.zero
        guard shadowTextStorage.length > 0 else { return nil }
        guard isMousePoint(mousePoint, in: cellBounds) else { return nil }
        
        var url: URL? = nil
        let glyphIndex = shadowLayoutManager.glyphIndex(for: mousePoint, in: shadowTextContainer)
        let charIndex = shadowLayoutManager.characterIndexForGlyph(at: glyphIndex)
        var returnRange = NSRange(location: 0, length: 0)
        if let value = shadowTextStorage.attribute(NSAttributedString.Key.link, at: charIndex, effectiveRange: &returnRange) {
            let glyphRange = shadowLayoutManager.glyphRange(forCharacterRange: returnRange, actualCharacterRange: nil)
            shadowLayoutManager.enumerateEnclosingRects(forGlyphRange: glyphRange, withinSelectedGlyphRange: glyphRange, in: shadowTextContainer) { rect, stop in
                let testHit = rect.insetBy(dx: cellBounds.origin.x, dy: cellBounds.origin.y)
                if self.isMousePoint(mousePoint, in: testHit.intersection(cellBounds)) {
                    if let value = value as? URL {
                        url = value
                    } else if let value = value as? String {
                        url = URL(string: value)
                    }
                    stop.pointee = true
                }
            }
        }
        return url
    }
    
    public override func updateTrackingAreas() {
        super.updateTrackingAreas()
        updateURLTrackingAreas()
    }

    public override func cursorUpdate(with event: NSEvent) {
        let mousePoint = convert(event.locationInWindow, from: nil)
        var inTrackingArea = false
        for tracking in URLTrackingAreas {
            if isMousePoint(mousePoint, in: tracking.rect) {
                inTrackingArea = true
                break
            }
        }
        if inTrackingArea {
            NSCursor.pointingHand.set()
        } else {
            super.cursorUpdate(with: event)
        }
    }
    
    public var canCopyURLs: Bool = false
    
    public override func menu(for event: NSEvent) -> NSMenu? {
        if !canCopyURLs {
            return super.menu(for: event)
        }
        
        let aClickedURL = URLForMouseEvent(event)
        if let aClickedURL {
            let aMenu = NSMenu.init()
            let anItem = NSMenuItem(title: NSLocalizedString("Copy URL", comment: "Copy URL"), action: #selector(self.copyURL(_:)), keyEquivalent: "")
            anItem.target = self
            anItem.representedObject = aClickedURL
            aMenu.addItem(anItem)
            return aMenu
        }
        
        return super.menu(for: event)
    }
    
    @objc public func copyURL(_ sender: NSMenuItem) {
        if let url = sender.representedObject as? URL {
            let copyBoard = NSPasteboard(name: .general)
            copyBoard.prepareForNewContents()
            copyBoard.writeObjects([url as NSURL])
        }
    }
    
    public override func mouseDown(with event: NSEvent) {
        /* Not calling [super mouseDown:] because there are some situations where
            the mouse tracking is ignored otherwise. */
        
        /* Remember which URL was clicked originally, so we don't end up opening
            the wrong URL accidentally.
        */
        clickedURL = URLForMouseEvent(event)
    }
    
    public override func mouseUp(with event: NSEvent) {
        let aClickedURL = URLForMouseEvent(event)
        if let aClickedURL {
            if aClickedURL == clickedURL {
                if let delegate = delegate as? DSClickableURLTextFieldDelegate {
                    delegate.textField?(self, openURL: aClickedURL)
                } else {
                    NSWorkspace.shared.open(aClickedURL)
                }
            }
        }
        clickedURL = nil
        super.mouseUp(with: event)
    }
}
