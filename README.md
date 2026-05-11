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
