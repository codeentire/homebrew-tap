# typed: false
# frozen_string_literal: true

# Mirrors scripts/install-all-cos.sh end-to-end:
#   - downloads code-entire_${os}_${arch}.tar.gz   (CLI: entire + code-entire)
#   - downloads codebuddy-plugin_${os}_${arch}.tar.gz
#       (agents: entire-agent-codebuddy-ide + entire-agent-codebuddy-plugin-internal + entire-agent-with)
#   - verifies sha256 (Homebrew enforces the field below)
#   - installs all 5 binaries + shell completions for `entire`
#
# NOTE: the upstream URLs live on git.tencent.com, so this Formula only
# works from a network that can reach the corp intranet.
class Entire < Formula
  desc     "CodeEntire CLI + CodeBuddy plugin agents (5 binaries, one shot)"
  homepage "https://git.tencent.com/CodeEntire/Entire"
  version  "v0.9.0-codeentire.1-9b9d1efe7" # bump on every release; refresh sha256 fields below
  license  "MIT"

  livecheck do
    skip "Internal release; bump version + sha256 manually"
  end

  # -- Main archive: CLI package (entire + code-entire + completions/) --
  on_macos do
    if Hardware::CPU.arm?
      url "https://git.tencent.com/CodeEntire/Entire/code-entire_darwin_arm64.tar.gz"
      sha256 "72050d11227d821f092fb5a8095cbf4a37e7fd9dadfe561ae45bbaaa1f89a5cd"

      resource "codebuddy-plugin" do
        url "https://git.tencent.com/CodeEntire/CodeBuddyPlugin/codebuddy-plugin_darwin_arm64.tar.gz"
        sha256 "ec64bddc9fc15fa653082de255f358cba844d1630b5d96205234d3236b4b92f8"
      end
    else
      url "https://git.tencent.com/CodeEntire/Entire/code-entire_darwin_amd64.tar.gz"
      sha256 "ead5eb15dc46b80d840caf4a475427c4b03ce3fab528493e0a2f41de1885e30e"

      resource "codebuddy-plugin" do
        url "https://git.tencent.com/CodeEntire/CodeBuddyPlugin/codebuddy-plugin_darwin_amd64.tar.gz"
        sha256 "dd13e084acb3f2b6b032f0cf5710f661e4985693ccad46b1bfe501227ba513e6"
      end
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://git.tencent.com/CodeEntire/Entire/code-entire_linux_arm64.tar.gz"
      sha256 "efbd5fb06cc7ca48e9326fdb520bc020874a33f66c260ab1ded47079056874da"

      resource "codebuddy-plugin" do
        url "https://git.tencent.com/CodeEntire/CodeBuddyPlugin/codebuddy-plugin_linux_arm64.tar.gz"
        sha256 "32dc2e7a4048ab9a920e0155b74e4034dde8081eec19054699f96471c9f42007"
      end
    else
      url "https://git.tencent.com/CodeEntire/Entire/code-entire_linux_amd64.tar.gz"
      sha256 "91b7f01a84327c02f8d971fd4e6e0c386667239bfda82bd4e1a30154cdd1ccfa"

      resource "codebuddy-plugin" do
        url "https://git.tencent.com/CodeEntire/CodeBuddyPlugin/codebuddy-plugin_linux_amd64.tar.gz"
        sha256 "b8d7ce6dd125834f831b53ec88a83a70167b9cfde12fc3bfa6d4357038bb7ec2"
      end
    end
  end

  def install
    # -- Main archive is auto-extracted into the staging dir --
    # CLI: entire + code-entire
    bin.install "entire"
    bin.install "code-entire"

    # CLI archive ships completions/entire.{bash,zsh,fish}
    if Dir.exist?("completions")
      if File.exist?("completions/entire.bash")
        bash_completion.install "completions/entire.bash" => "entire"
      end
      if File.exist?("completions/entire.zsh")
        zsh_completion.install "completions/entire.zsh" => "_entire"
      end
      fish_completion.install "completions/entire.fish" if File.exist?("completions/entire.fish")
    end

    # -- Second archive: CodeBuddy plugin agents --
    resource("codebuddy-plugin").stage do
      bin.install "entire-agent-codebuddy-ide"
      bin.install "entire-agent-codebuddy-plugin-internal"
      bin.install "entire-agent-with"
    end
  end

  def caveats
    <<~EOS
      Installed 5 binaries:
        - entire
        - code-entire
        - entire-agent-codebuddy-ide
        - entire-agent-codebuddy-plugin-internal
        - entire-agent-with

      Quick start:
        cd your-project
        entire enable
        entire status

      Shell completions for `entire` are wired up automatically by Homebrew.

      Source archives are pulled from git.tencent.com (intranet only).
    EOS
  end

  test do
    # Equivalent to install-all-cos.sh's post-install self-check
    assert_match(/entire/i, shell_output("#{bin}/entire version"))
    assert_predicate bin/"code-entire",                            :executable?
    assert_predicate bin/"entire-agent-codebuddy-ide",             :executable?
    assert_predicate bin/"entire-agent-codebuddy-plugin-internal", :executable?
    assert_predicate bin/"entire-agent-with",                      :executable?
  end
end
