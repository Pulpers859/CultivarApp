No shared hooks are committed for this project by design.

Why:
- The repo includes a checked-in Xcode project, but Apple build/test hooks are still noisy and unreliable without a real Xcode environment.
- Hidden mutating hooks are low trust and low ROI for a data-sensitive app.
- Product risk here is better handled by explicit review commands and narrow skills than by background automation.
