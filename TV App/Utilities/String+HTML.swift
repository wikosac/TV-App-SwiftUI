//
//  String+HTML.swift
//  TV App
//
//  Created by Dwiko Indrawansyah on 10/09/26.
//

import Foundation
import UIKit

extension String {
    /// Strips HTML tags and decodes entities, returning plain text.
    /// Used for the share sheet, where we want clean text, not markup.
    var strippingHTML: String {
        guard let data = self.data(using: .utf8) else { return self }
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue,
        ]
        guard
            let attributed = try? NSAttributedString(
                data: data,
                options: options,
                documentAttributes: nil
            )
        else {
            // Fallback: naive tag stripping if HTML parsing fails.
            return self.replacingOccurrences(
                of: "<[^>]+>",
                with: "",
                options: .regularExpression
            )
        }
        return attributed.string.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Renders as an AttributedString for display, preserving bold/paragraph styling.
    var htmlToAttributedString: AttributedString {
        guard let data = self.data(using: .utf8) else {
            return AttributedString(self)
        }
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue,
        ]
        guard
            let nsAttributed = try? NSAttributedString(
                data: data,
                options: options,
                documentAttributes: nil
            )
        else {
            return AttributedString(self.strippingHTML)
        }
        var attributed = AttributedString(nsAttributed)
        // NSAttributedString(html:) applies its own font/size (usually Times).
        // Reset to nil so it inherits SwiftUI's font modifiers instead.
        attributed.font = nil
        attributed.foregroundColor = nil
        return attributed
    }
}
