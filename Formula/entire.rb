# typed: false
# frozen_string_literal: true

# Mirrors scripts/install-all-cos.sh end-to-end:
#   - downloads code-entire_${os}_${arch}.tar.gz   (CLI: entire + code-entire)
#   - downloads codebuddy-plugin_${os}_${arch}.tar.gz
#       (agents: entire-agent-codebuddy-ide + entire-agent-codebuddy-plugin-internal)
#   - verifies sha256 (Homebrew enforces the field below)
#   - installs all 4 binaries + shell completions for `entire`
#
# NOTE: the upstream URLs live on git.tencent.com, so this Formula only
# works from a network that can reach the corp intranet.
class Entire < Formula
  desc     "CodeEntire CLI + CodeBuddy plugin agents (4 binaries, one shot)"
  homepage "https://git.tencent.com/CodeEntire/Entire"
  version  "v0.8.42-codeentire.1-9bac5df66" # bump on every release; refresh sha256 fields below
  license  "MIT"

  livecheck do
    skip "Internal release; bump version + sha256 manually"
  end

  # -- Main archive: CLI package (entire + code-entire + completions/) --
  on_macos do
    if Hardware::CPU.arm?
      url "https://git.tencent.com/CodeEntire/Entire/code-entire_darwin_arm64.tar.gz"
      sha256 "e5454b4457d84e2222baa4f054e3256bdd25c1650c29db04e5aef114bb68e457"

      resource "codebuddy-plugin" do
        url "https://git.tencent.com/CodeEntire/CodeBuddyPlugin/codebuddy-plugin_darwin_arm64.tar.gz"
        sha256 "55909fe1e1a2257df414dfb401879c1f49b6c190024307df0a9fd797e7273626"
      end
    else
      url "https://git.tencent.com/CodeEntire/Entire/code-entire_darwin_amd64.tar.gz"
      sha256 "c0ea5bc55d8a06eeb4b364fb27e1ef713297769b7866372279a08698d1c689e2"

      resource "codebuddy-plugin" do
        url "https://git.tencent.com/CodeEntire/CodeBuddyPlugin/codebuddy-plugin_darwin_amd64.tar.gz"
        sha256 "27afea17a89d2f77c665c9168c6b16c248cb0a6223b9d4ddd32389c0327c42f9"
      end
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://git.tencent.com/CodeEntire/Entire/code-entire_linux_arm64.tar.gz"
      sha256 "bb37bf3d9b4f2ba240316b9def64cf754fec649a723df5ccc65e5231f0258e08"

      resource "codebuddy-plugin" do
        url "https://git.tencent.com/CodeEntire/CodeBuddyPlugin/codebuddy-plugin_linux_arm64.tar.gz"
        sha256 "d17472ce563368ba499aafffdeb1b6002754f923f201b2b3132e4977257bae5e"
      end
    else
      url "https://git.tencent.com/CodeEntire/Entire/code-entire_linux_amd64.tar.gz"
      sha256 "c98c6706fb36aa6e9c77a5738f968689a39716738942e4d15c65d82181a42522"

      resource "codebuddy-plugin" do
        url "https://git.tencent.com/CodeEntire/CodeBuddyPlugin/codebuddy-plugin_linux_amd64.tar.gz"
        sha256 "a7bdbc3b6fc8cd2fb65d0fab96eac8268d66cf818e3219dd168b10d437192087"
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
    end
  end

  def caveats
    <<~EOS
      Installed 4 binaries:
        - entire
        - code-entire
        - entire-agent-codebuddy-ide
        - entire-agent-codebuddy-plugin-internal

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
  end
end
