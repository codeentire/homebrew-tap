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
  version  "1.0.0" # bump on every release; refresh sha256 fields below
  license  "MIT"

  livecheck do
    skip "Internal release; bump version + sha256 manually"
  end

  # -- Main archive: CLI package (entire + code-entire + completions/) --
  on_macos do
    if Hardware::CPU.arm?
      url "https://git.tencent.com/CodeEntire/Entire/code-entire_darwin_arm64.tar.gz"
      sha256 "bdc1bd5dd9e433dc60088e99d845ccf094058cee5ccb0363995a85e2b74488b5"

      resource "codebuddy-plugin" do
        url "https://git.tencent.com/CodeEntire/CodeBuddyPlugin/codebuddy-plugin_darwin_arm64.tar.gz"
        sha256 "807b7b198cedb5664650f464896ccf506570e7cbad33a0fd9713df02c36832d4"
      end
    else
      url "https://git.tencent.com/CodeEntire/Entire/code-entire_darwin_amd64.tar.gz"
      sha256 "257ed9912baa30e000ab1c63cabfb672e4741f62fcd0262000bc3c0a72a81870"

      resource "codebuddy-plugin" do
        url "https://git.tencent.com/CodeEntire/CodeBuddyPlugin/codebuddy-plugin_darwin_amd64.tar.gz"
        sha256 "eaae276640106715ba8cb9645b1aacae2ff0751191b1f69ba52f12fb70bed0e7"
      end
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://git.tencent.com/CodeEntire/Entire/code-entire_linux_arm64.tar.gz"
      sha256 "311dd471901dd82eb8fd22cf85a9f8de6fdca9066d877370156bd6df59b36159"

      resource "codebuddy-plugin" do
        url "https://git.tencent.com/CodeEntire/CodeBuddyPlugin/codebuddy-plugin_linux_arm64.tar.gz"
        sha256 "d65abe44ae4fad990b166b817401bfaddbdf6485b9f22bc70239c1bfc2e7b5dd"
      end
    else
      url "https://git.tencent.com/CodeEntire/Entire/code-entire_linux_amd64.tar.gz"
      sha256 "756822a08c50b05338afdfb466ef85518c52239a8d7b2abe1606417cc6b77b1a"

      resource "codebuddy-plugin" do
        url "https://git.tencent.com/CodeEntire/CodeBuddyPlugin/codebuddy-plugin_linux_amd64.tar.gz"
        sha256 "fd9292cc95bf8d18f7705201db352719f4b2f97285537d6627a0f28cc2e697ba"
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

  # The `entire` CLI hard-codes "$HOME/.local/bin" as the canonical install
  # location for its companion binaries. Ideally we'd auto-create those
  # symlinks here, BUT Homebrew 4.x+ runs `post_install` inside a strict
  # macOS Sandbox that DENIES every write outside the Cellar -- including
  # `$HOME`. There is no Formula-level escape hatch (see
  # Library/Homebrew/formula_installer.rb#run_postinstall in Homebrew 5.x).
  #
  # We therefore expose the same logic as a one-liner in `caveats`, which
  # the user can copy-paste once. `ln -sfn` is idempotent, so re-running
  # it after upgrades is safe.

  def caveats
    bins = %w[
      entire
      code-entire
      entire-agent-codebuddy-ide
      entire-agent-codebuddy-plugin-internal
    ]
    link_cmd = "mkdir -p ~/.local/bin && " +
               bins.map { |b| "ln -sfn #{bin}/#{b} ~/.local/bin/#{b}" }.join(" && ")

    <<~EOS
      Installed 4 binaries under #{bin}:
        - entire
        - code-entire
        - entire-agent-codebuddy-ide
        - entire-agent-codebuddy-plugin-internal

      ⚠️  ONE-TIME SETUP REQUIRED  ⚠️
      The `entire` CLI expects its companion binaries under ~/.local/bin.
      Homebrew's sandbox forbids us from writing there during install,
      so please run this one-liner once (safe to re-run):

        #{link_cmd}

      Quick start (after running the one-liner above):
        cd your-project
        entire enable
        entire status

      Shell completions for `entire` are wired up automatically by Homebrew.

      Uninstall note:
        `brew uninstall entire` does NOT remove the ~/.local/bin symlinks.
        Clean them up manually if needed:
          rm -f ~/.local/bin/{#{bins.join(",")}}

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
