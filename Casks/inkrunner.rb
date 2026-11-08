cask "inkrunner" do
  # The release workflow replaces both values before publishing.
  version "0.0.0"
  sha256 "0000000000000000000000000000000000000000000000000000000000000000"

  url "https://dl.repl.net/inkrunner/InkRunner-#{version}.dmg"
  name "Ink Runner"
  desc "Menu bar app for managing GitHub Actions self-hosted runners"
  homepage "https://github.com/replworks/inkrunner"

  depends_on macos: :ventura

  app "InkRunner.app"
  binary "#{appdir}/InkRunner.app/Contents/MacOS/InkRunner", target: "inkrunner"

  # `zap` is a blunt, whole-directory removal of the invoking user's files, which is
  # what `brew zap` is for. `inkrunner uninstall` is the surgical path: it deregisters
  # runners from GitHub, reaches service-user workspaces under /Users/<service-user>,
  # and preserves anything inside ~/.inkrunner it does not recognise as its own.
  zap trash: [
    # Runner workspaces live outside Application Support because the GitHub runner
    # scripts break on paths containing spaces. This is by far the largest artifact:
    # each configured runner holds an extracted runner release plus its _work checkout.
    "~/.inkrunner",
    "~/Library/Application Support/InkRunner",
    "~/Library/Application Support/CrashReporter/InkRunner_*.plist",
    "~/Library/Application Support/CrashReporter/inkrunner_*.plist",
    "~/Library/Logs/DiagnosticReports/InkRunner-*.ips",
    "~/Library/Logs/DiagnosticReports/inkrunner-*.ips",
    "~/Library/Caches/net.repl.inkrunner",
    "~/Library/HTTPStorages/net.repl.inkrunner",
    "~/Library/HTTPStorages/net.repl.inkrunner.binarycookies",
    "~/Library/HTTPStorages/inkrunner",
    "~/Library/HTTPStorages/InkRunner",
    "~/Library/Preferences/net.repl.inkrunner.plist",
    "~/Library/Preferences/inkrunner.plist",
    "~/Library/Saved Application State/net.repl.inkrunner.savedState",
  ]

  caveats <<~EOS
    To get started:

    1. Install and authenticate the GitHub CLI: brew install gh && gh auth login
    2. Launch from Applications or run: open /Applications/InkRunner.app
    3. Click the runner icon in the menu bar and add a runner
    4. Or use the CLI: inkrunner add owner/repo --name my-runner

    For help: https://github.com/replworks/inkrunner

    To uninstall, run this first:

        inkrunner uninstall

    It deregisters your runners from GitHub - otherwise they linger in the
    repository's Actions settings as permanently offline runners - and removes
    workspaces owned by a dedicated service user, which live outside your home
    directory and are not reachable by `brew zap`.
  EOS
end
