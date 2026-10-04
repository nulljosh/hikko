import SwiftUI

/// The three screens a first-time, signed-out visitor sees. Shared by iOS and macOS.
let sparkOnboardingSlides = [
    OnboardingSlide(symbol: "lightbulb",
                    title: "Ideas, out loud",
                    body: "Hikko is a running feed of startup and project ideas. Read one, riff on it, or post your own."),
    OnboardingSlide(symbol: "arrow.up.circle",
                    title: "Vote the good ones up",
                    body: "Every idea can be upvoted and argued about in the comments. The best rise to the top of the feed."),
    OnboardingSlide(symbol: "hammer",
                    title: "Build one for real",
                    body: "Claim an idea, track what you ship, and let the rest of the jar follow along."),
]
