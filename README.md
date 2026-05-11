# homebrew-tap

Homebrew tap for CodeEntire.

## Install

```bash
brew tap codeentire/tap
brew install entire
```

This single command installs **4 binaries** in one shot:

| Binary | From archive |
|---|---|
| `entire` | `code-entire_${os}_${arch}.tar.gz` |
| `code-entire` | `code-entire_${os}_${arch}.tar.gz` |
| `entire-agent-codebuddy-ide` | `codebuddy-plugin_${os}_${arch}.tar.gz` |
| `entire-agent-codebuddy-plugin-internal` | `codebuddy-plugin_${os}_${arch}.tar.gz` |

Equivalent to running:

```bash
curl -fsSL https://git.tencent.com/CodeEntire/install.sh | bash
```

> ⚠️ The upstream archives are hosted on `git.tencent.com`. You must be on a
> network that can reach the corp intranet for `brew install entire` to
> succeed. Out-of-network users should keep using the curl-pipe-bash flow.

## Quick start

```bash
cd your-project
entire enable
entire status
```

Shell completions for `entire` are installed automatically by Homebrew (bash
/ zsh / fish are all picked up via the `*_completion` install paths in the
Formula).

## Upgrading

```bash
brew update
brew upgrade entire
```

## Uninstall

```bash
brew uninstall entire
brew untap codeentire/tap
```

## Maintainers — releasing a new version

1. Make sure you're on a machine that can reach `git.tencent.com`.
2. Run the bump helper with the new version number:

   ```bash
   ./scripts/bump.sh 1.0.1
   ```

   It will:

   - download all 8 archives (4 platforms × CLI + plugin) and compute their
     sha256
   - rewrite the 8 `sha256 "..."` lines in `Formula/entire.rb`
   - bump the `version` field

3. Review and commit:

   ```bash
   git diff Formula/entire.rb
   git add Formula/entire.rb
   git commit -m "entire 1.0.1"
   git push
   ```

4. (Optional) Local sanity check before pushing:

   ```bash
   brew install --build-from-source ./Formula/entire.rb
   brew test entire
   brew audit --strict --new-formula entire
   ```

## Layout

```
homebrew-tap/
├── Formula/
│   └── entire.rb       # the one-shot Formula
├── scripts/
│   └── bump.sh             # refresh sha256 + bump version
├── .gitignore
└── README.md
```
