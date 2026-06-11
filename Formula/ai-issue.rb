class AiIssue < Formula
  desc "AI-powered GitHub issue helper"
  homepage "https://github.com/replworks/ai-issue"
  version "1.0.0"

  on_macos do
    on_arm do
      url "https://github.com/replworks/ai-issue/releases/download/v1.0.0/ai-issue_1.0.0_darwin_arm64.tar.gz"
      sha256 "sha256:9c6e778e12eb0e6cf03b95b1f38e7f5ac6cc758d42c6b539fbb1b49fc7e06cf0"
    end

    on_intel do
      url "https://github.com/replworks/ai-issue/releases/download/v1.0.0/ai-issue_1.0.0_darwin_amd64.tar.gz"
      sha256 "sha256:607642a33d436c9221456f6516e94a616c79dba60cd11f33ce3c6bf46bea9907"
    end
  end

  def install
    bin.install "ai-issue"
  end

  test do
    system "#{bin}/ai-issue", "--version"
  end
end