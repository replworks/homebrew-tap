# replworks/homebrew-tap

[![pages](https://github.com/replworks/homebrew-tap/actions/workflows/pages.yml/badge.svg)](https://github.com/replworks/homebrew-tap/actions/workflows/pages.yml)

replworks 도구를 macOS에서 `brew`로 설치하기 위한 Homebrew tap.
각 프로젝트가 릴리스할 때 goreleaser가 `Casks/<이름>.rb`를 이 저장소에 자동으로 커밋한다.

## 동작 방식

1. 각 프로젝트가 태그를 푸시하면 프로젝트의 `release.yml`이 goreleaser를 돌린다.
2. goreleaser가 GitHub Release를 만들고, `homebrew_casks` 설정대로 이 저장소의 `Casks/<이름>.rb`를 **자동으로 만들거나 갱신하고 커밋**한다. (`HOMEBREW_TAP_GITHUB_TOKEN`으로 push)
3. 이 저장소에 push가 생기면 `pages.yml`이 돌아서 `Casks/*.rb`를 읽고 랜딩 페이지의 패키지 목록을 다시 만든다.

## 구조

```
.
├── Casks/                        # goreleaser가 자동으로 관리 (직접 수정하지 않는다)
├── tap_migrations.json           # 패키지 이름을 바꾸거나 다른 tap으로 옮길 때 쓰는 Homebrew 파일
├── index.html                    # 랜딩 페이지 템플릿 (<!--PACKAGES--> 자리를 워크플로가 채움)
└── .github/workflows/pages.yml   # Casks를 읽어 랜딩 페이지를 만들고 Pages에 배포
```

## 새 저장소(패키지) 추가하는 법

이 저장소는 건드릴 필요 없다. 추가할 프로젝트 쪽에서 아래 3가지만 하면 첫 릴리스 때 `Casks/`에 자동 등록된다.
추가할 프로젝트를 `replworks/repo`라고 하자.

### 1. `.goreleaser.yaml`에 `homebrew_casks` 추가

```yaml
homebrew_casks:
  - repository:
      owner: replworks
      name: homebrew-tap
      token: "{{ .Env.HOMEBREW_TAP_GITHUB_TOKEN }}"

    homepage: "https://github.com/replworks/{{ .ProjectName }}"
    description: "<설명>"
    custom_block: |
      on_macos do
        postflight_steps do
          run "/usr/bin/xattr", args: ["-dr", "com.apple.quarantine", "{{ "{{" }}staged_path{{ "}}" }}/<바이너리 이름>"]
        end
      end
```

- `homepage`와 `description`은 랜딩 페이지 카드에 그대로 나온다. 꼭 채운다.
- `custom_block`은 서명 안 된 바이너리가 macOS Gatekeeper에 막히지 않게 quarantine 속성을 지우는 부분이다. 바이너리 이름만 바꿔서 쓴다.
- `builds`에 `darwin`(amd64, arm64)이 들어 있어야 한다.

`goreleaser release --snapshot --clean` 으로 로컬에서 돌려서 `dist/` 아래에 cask 파일이 만들어지는지 확인한다.

### 2. `HOMEBREW_TAP_TOKEN` 시크릿 등록

- organization 시크릿으로 한 번 등록해뒀으면 그 저장소에 접근 권한만 열어주면 된다.
- 토큰을 새로 만들 때: fine-grained PAT, Repository access는 `replworks/homebrew-tap`만, Permissions는 Contents → Read and write.

### 3. `release.yml`의 goreleaser 스텝에 환경변수 추가

```yaml
- uses: goreleaser/goreleaser-action@v7
  with:
    version: latest
    args: release --clean
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    HOMEBREW_TAP_GITHUB_TOKEN: ${{ secrets.HOMEBREW_TAP_TOKEN }}
```

### 4. 확인

- 프로젝트에 새 태그를 푸시한다.
- 이 저장소에 `Casks/<이름>.rb` 커밋이 생겼는지 본다.
- Actions 탭에서 `pages`가 돌았는지, 랜딩 페이지에 카드가 생겼는지 본다.
- macOS에서 `brew tap replworks/tap && brew install --cask <이름>`으로 설치해본다.

> `Casks/<이름>.rb`는 직접 만들지 않는다. goreleaser가 릴리스할 때마다 덮어쓰기 때문에 직접 고친 내용은 사라진다.
> 설정을 바꾸고 싶으면 프로젝트의 `.goreleaser.yaml`을 고친다.

## 사용자 설치 방법

```bash
brew tap replworks/tap
brew install --cask <패키지 이름>
```

- `brew tap replworks/tap`은 이 저장소(`replworks/homebrew-tap`)를 등록하는 명령이다. 처음 한 번만 하면 된다.
- 등록 없이 한 줄로도 된다: `brew install --cask replworks/tap/<패키지 이름>`
- 업데이트는 `brew upgrade --cask <패키지 이름>`, 저장소 등록 해제는 `brew untap replworks/tap`.
- Cask는 macOS 전용이다. Debian / Ubuntu는 [apt.repl.net](https://apt.repl.net)을 쓴다.

## 한 번만 해둔 설정 (참고)

- **Pages**: Settings → Pages → Source는 **GitHub Actions**. 도메인을 붙이면 Custom domain과 Enforce HTTPS도 여기서 설정한다.
- **브랜치 보호**: main에 걸어두지 않는다. goreleaser가 main에 직접 push한다.

## 문제 생겼을 때

| 증상                                             | 확인할 것                                                                               |
| ------------------------------------------------ | --------------------------------------------------------------------------------------- |
| goreleaser 로그에서 tap push 실패 (403 등)       | `HOMEBREW_TAP_TOKEN` 권한(Contents: Read and write), 만료일, 저장소 범위                |
| `Casks/`에 파일이 안 생김                        | `homebrew_casks` 블록이 있는지, release.yml에 `HOMEBREW_TAP_GITHUB_TOKEN`이 들어 있는지 |
| `pages`가 안 돎                                  | Pages Source가 GitHub Actions인지, 커밋이 `Casks/**`를 건드렸는지                       |
| 랜딩 페이지 카드에 버전/설명이 빔                | `Casks/<이름>.rb`에 `version`, `desc`, `homepage`가 한 줄씩 있는지                      |
| `brew install`에서 "unidentified developer" 경고 | `custom_block`의 `xattr` 스텝과 바이너리 이름이 맞는지                                  |
| Linux에서 `brew install` 실패                    | Cask는 macOS 전용이다. Linux는 apt 저장소를 쓴다                                        |

## 제한

- Homebrew는 이 저장소를 git으로 직접 받아 쓴다. 랜딩 페이지는 안내용이라서, 페이지가 꺼져 있어도 `brew tap`은 동작한다.
- Cask는 macOS 전용이다.
