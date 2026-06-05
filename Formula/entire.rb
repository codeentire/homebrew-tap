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
  version  "v0.7.5-66c00b236" # bump on every release; refresh sha256 fields below
  license  "MIT"

  livecheck do
    skip "Internal release; bump version + sha256 manually"
  end

  # -- Main archive: CLI package (entire + code-entire + completions/) --
  on_macos do
    if Hardware::CPU.arm?
      url "https://git.tencent.com/CodeEntire/Entire/code-entire_darwin_arm64.tar.gz"
      sha256 "4b3766612c98b2d21b5f59077e9c1b11f80b4b6e92b8e6d2b20cc5099ac5be63"

      resource "codebuddy-plugin" do
        url "https://git.tencent.com/CodeEntire/CodeBuddyPlugin/codebuddy-plugin_darwin_arm64.tar.gz"
        sha256 "96b0865dbf0411bec647ab68e452aa82cfc16f864abd3bf91fef6e5e2beed6b7"
      end
    else
      url "https://git.tencent.com/CodeEntire/Entire/code-entire_darwin_amd64.tar.gz"
      sha256 "a8ad83414748f3c6390048e22f7c9f2df52447d9ae19e72d6e5473347a191d52"

      resource "codebuddy-plugin" do
        url "https://git.tencent.com/CodeEntire/CodeBuddyPlugin/codebuddy-plugin_darwin_amd64.tar.gz"
        sha256 "c132a64bff89b6f0a33b31f8d8705f937889e212f2da40d867d9dfa42cf025fe"
      end
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://git.tencent.com/CodeEntire/Entire/code-entire_linux_arm64.tar.gz"
      sha256 "8309d879de62d9b42d8c505bf40100cdaf7c15fea622f7b31754b876ce39930f"

      resource "codebuddy-plugin" do
        url "https://git.tencent.com/CodeEntire/CodeBuddyPlugin/codebuddy-plugin_linux_arm64.tar.gz"
        sha256 "ab6bccb37b8c5825c02df71db2e8739ba34a407b13a686c3f27775906acca70e"
      end
    else
      url "https://git.tencent.com/CodeEntire/Entire/code-entire_linux_amd64.tar.gz"
      sha256 "249952b2b65839d543a5ed91fe6c70cd70f4b38836e48108170cd16389d14814"

      resource "codebuddy-plugin" do
        url "https://git.tencent.com/CodeEntire/CodeBuddyPlugin/codebuddy-plugin_linux_amd64.tar.gz"
        sha256 "7e9d080780cc2d676ec91bea5a5e546615e9f8fb866df0f2a40f07dd98f8fdb4"
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
