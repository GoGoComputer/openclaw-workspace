# typed: false
# frozen_string_literal: true

# Homebrew Formula for openclaw-workspace
# Tap: gogocomputer/openclaw   (repo: github.com/GoGoComputer/homebrew-openclaw)
#
# Install:
#   brew tap gogocomputer/openclaw
#   brew install openclaw-workspace
#
# After install:
#   openclaw                # interactive menu
#   openclaw doctor         # diagnose
#   openclaw install        # auto-install Docker / Ollama / OpenClaw container
#
# Note: This Formula installs the *manager* (bash launcher + scripts).
# Docker Desktop (cask) and Ollama (formula) are auto-installed by `openclaw install`
# on first run, so no Homebrew dependency is hard-required here.
class OpenclawWorkspace < Formula
  desc "macOS self-host automation for OpenClaw (one-line install/maintain/uninstall)"
  homepage "https://github.com/GoGoComputer/openclaw-workspace"
  url "https://github.com/GoGoComputer/openclaw-workspace/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "092243532ec1d02f720f4f1ebe1ea9efe4dca58aa601cb0d6e87ff81aeca5b14"
  license "MIT"
  version "0.1.0"

  # macOS only (uses Docker Desktop, launchd, `open`, `purge`)
  depends_on :macos
  # bash 3.2 ships with macOS, but recommend a modern bash via brew
  depends_on "bash" => :recommended

  def install
    # Install the entire openclaw-mgr tree under libexec
    libexec.install Dir["openclaw-mgr/*"]
    libexec.install Dir["openclaw-mgr/.env.example"] if File.exist?("openclaw-mgr/.env.example")

    # Wrapper in bin/ — invokes the dispatcher with the user's CWD preserved
    (bin/"openclaw").write <<~SH
      #!/bin/bash
      exec "#{libexec}/openclaw" "$@"
    SH
    chmod 0755, bin/"openclaw"

    # Documentation under share/doc
    doc.install "README.md", "README.en.md", "LICENSE", "SECURITY.md"
    (doc/"docs").install Dir["docs/*"]
  end

  def caveats
    <<~EOS
      🦞 openclaw-workspace installed!

      Run the interactive menu (auto-detects Korean/English):
        openclaw

      Or invoke subcommands directly:
        openclaw doctor          # diagnose
        openclaw install         # auto-install Docker / Ollama / OpenClaw

      First run auto-creates ~/.openclaw-mgr/.env from the template.
      State is kept in ~/.openclaw-mgr/   (not in the Cellar — survives upgrades).

      Docker Desktop and Ollama are auto-installed by `openclaw install`
      if missing — no need to brew them yourself.

      Docs:  #{HOMEBREW_PREFIX}/share/doc/openclaw-workspace/
      Repo:  https://github.com/GoGoComputer/openclaw-workspace
    EOS
  end

  test do
    # Smoke test: dispatcher must respond to --version
    assert_match "openclaw-mgr", shell_output("#{bin}/openclaw --version")
    # Help must list core subcommands
    help = shell_output("#{bin}/openclaw help")
    %w[doctor install start stop logs update backup restore schedule network clean uninstall].each do |sub|
      assert_match sub, help
    end
  end
end
