No shared hooks are committed for this project by design.

Why:
- The repo does not include a checked-in Xcode project, so automatic build/test hooks would be noisy and unreliable.
- Hidden mutating hooks are low trust and low ROI for a data-sensitive app.
- Product risk here is better handled by explicit review commands and narrow skills than by background automation.
