from pathlib import Path

share = Path("ios/Runner/NativeShareChannel.swift").read_text()
app = Path("ios/Runner/AppDelegate.swift").read_text()

assert "enum NativePresentationResolver" in share
assert "scene.activationState == .foregroundActive" in share
assert "originatingFrom: presenter" in share
assert "window.windowScene" in share
assert "isKeyWindow && !$0.isHidden" in share
assert "windowLevel == .normal" in share
assert "split.viewControllers.reversed()" in share
assert "NativePresentationResolver.isPresentationReady(presenter)" in share
assert "NativePresentationResolver.activePresenter(originatingFrom: presenter)" in app
assert app.count("NativePresentationResolver.isPresentationReady(presenter)") >= 2
assert "private func topPresenter(from controller:" not in app
print("iPad presentation contract OK")
