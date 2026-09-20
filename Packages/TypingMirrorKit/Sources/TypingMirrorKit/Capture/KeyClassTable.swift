import Carbon.HIToolbox
import Foundation

/// Maps a virtual keycode to a key class.
///
/// Built once, off the hot path, by asking the current keyboard layout what each
/// key produces — and then throwing that character away, keeping only its class.
/// The callback is therefore a single array lookup, and the app never calls the
/// API that would hand it the text the user typed.
struct KeyClassTable: Sendable {
    private let classes: [UInt8]

    static let tableSize = 128

    init(classes: [UInt8]) { self.classes = classes }

    func classify(keyCode: UInt16, hasCommandOrControl: Bool) -> KeyClass {
        if hasCommandOrControl { return .shortcut }
        guard keyCode < Self.tableSize else { return .unknown }
        return KeyClass(rawValue: classes[Int(keyCode)]) ?? .unknown
    }

    /// Reads the active layout, classifies every key, and discards the characters.
    static func forCurrentInputSource() -> KeyClassTable {
        var classes = [UInt8](repeating: KeyClass.unknown.rawValue, count: tableSize)

        for keyCode in 0..<tableSize {
            classes[keyCode] = fixedClass(for: UInt16(keyCode))?.rawValue
                ?? classify(keyCode: UInt16(keyCode))
        }
        return KeyClassTable(classes: classes)
    }

    /// Keys whose meaning does not depend on the layout.
    ///
    /// Pure and free of any system call, so it stays testable without a window
    /// server connection.
    static func fixedClass(for keyCode: UInt16) -> KeyClass? {
        switch Int(keyCode) {
        case kVK_Delete: .backspace
        case kVK_ForwardDelete: .forwardDelete
        case kVK_Space: .space
        case kVK_Return, kVK_ANSI_KeypadEnter: .returnEnter
        case kVK_Tab: .tab
        case kVK_Escape: .escape
        case kVK_LeftArrow, kVK_RightArrow, kVK_UpArrow, kVK_DownArrow,
             kVK_Home, kVK_End, kVK_PageUp, kVK_PageDown: .navigation
        case kVK_Shift, kVK_RightShift, kVK_Command, kVK_RightCommand,
             kVK_Option, kVK_RightOption, kVK_Control, kVK_RightControl,
             kVK_CapsLock, kVK_Function: .modifierChange
        // Function-key codes are neither contiguous nor ascending, so they are
        // listed rather than expressed as a range.
        case kVK_F1, kVK_F2, kVK_F3, kVK_F4, kVK_F5, kVK_F6, kVK_F7, kVK_F8,
             kVK_F9, kVK_F10, kVK_F11, kVK_F12, kVK_F13, kVK_F14, kVK_F15,
             kVK_F16, kVK_F17, kVK_F18, kVK_F19, kVK_F20: .functionKey
        default: nil
        }
    }

    private static func classify(keyCode: UInt16) -> UInt8 {
        guard let source = TISCopyCurrentKeyboardLayoutInputSource()?.takeRetainedValue(),
              let pointer = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData)
        else {
            return KeyClass.unknown.rawValue
        }

        let data = Unmanaged<CFData>.fromOpaque(pointer).takeUnretainedValue() as Data
        var deadKeyState: UInt32 = 0
        var length = 0
        var characters = [UniChar](repeating: 0, count: 4)

        let status = data.withUnsafeBytes { buffer -> OSStatus in
            guard let layout = buffer.baseAddress?.assumingMemoryBound(to: UCKeyboardLayout.self)
            else { return -1 }
            return UCKeyTranslate(
                layout,
                keyCode,
                UInt16(kUCKeyActionDown),
                0,
                UInt32(LMGetKbdType()),
                UInt32(kUCKeyTranslateNoDeadKeysBit),
                &deadKeyState,
                characters.count,
                &length,
                &characters
            )
        }

        guard status == noErr, length > 0,
              let scalar = String(utf16CodeUnits: characters, count: length).unicodeScalars.first
        else {
            return KeyClass.unknown.rawValue
        }

        // The character is inspected here and never leaves this function.
        let character = Character(scalar)
        if character.isLetter { return KeyClass.letter.rawValue }
        if character.isNumber { return KeyClass.digit.rawValue }
        if character.isWhitespace { return KeyClass.space.rawValue }
        if character.isPunctuation || character.isSymbol { return KeyClass.punctuation.rawValue }
        return KeyClass.unknown.rawValue
    }
}
