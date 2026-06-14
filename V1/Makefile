default: all

# all: ensure-homebrew ensure-gem ensure-bundler ensure-bundle-install ensure-fastlane download-privates fetch-certificates install-templates


# # -----------------------------
# # 🛠 Homebrew 설치 확인
# # -----------------------------
# ensure-homebrew:
# 	@echo "🔍 Checking for Homebrew..."
# 	@command -v brew >/dev/null 2>&1 && echo "✅ Homebrew already installed." || { \
# 		echo "🍺 Homebrew not found. Installing..."; \
# 		/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; \
# 		echo "✅ Homebrew installed."; \
# 	}
# 	@echo ""

# # -----------------------------
# # 💎 RubyGems 설치 확인
# # -----------------------------
# ensure-gem:
# 	@echo "🔍 Checking for RubyGems..."
# 	@command -v gem >/dev/null 2>&1 && echo "✅ gem already installed." || { \
# 		echo "❌ gem not found. Ruby가 시스템에 설치되어 있어야 합니다."; \
# 		echo "➡️  macOS라면: Xcode Command Line Tools를 설치하세요 (xcode-select --install)"; \
# 		exit 1; \
# 	}
# 	@echo ""

# # -----------------------------
# # 📦 Bundler 설치 확인
# # -----------------------------
# ensure-bundler: ensure-gem
# 	@echo "🔍 Checking for Bundler..."
# 	@command -v bundle >/dev/null 2>&1 && echo "✅ Bundler already installed." || { \
# 		echo "📦 Bundler not found. Installing..."; \
# 		sudo gem install bundler; \
# 		echo "✅ Bundler installed."; \
# 	}
# 	@echo ""

# # -----------------------------
# # 📦 bundle install 자동 실행
# # -----------------------------
# ensure-bundle-install: ensure-bundler
# 	@if [ -f "Gemfile" ]; then \
# 		echo "📦 Running bundle install..."; \
# 		bundle check >/dev/null 2>&1 || bundle install; \
# 		echo "✅ Bundle install complete."; \
# 	else \
# 		echo "ℹ️  No Gemfile found. Skipping bundle install."; \
# 	fi
# 	@echo ""

# # -----------------------------
# # 🛫 Fastlane 설치 확인
# # -----------------------------
# ensure-fastlane:
# 	@echo "🔍 Checking for fastlane..."
# 	@command -v fastlane >/dev/null 2>&1 && echo "✅ Fastlane already installed." || { \
# 		echo "🚀 Fastlane not found. Installing..."; \
# 		sudo gem install fastlane -NV; \
# 		echo "✅ Fastlane installed."; \
# 	}
# 	@echo ""

# # -----------------------------
# # 🔐 Private 파일 다운로드
# # -----------------------------
# # 🔐 private 저장소 정보
# Private_Repository=team-PopPang/PopPang-Private
# Private_Branch=iOS
# BASE_URL=https://raw.githubusercontent.com/$(Private_Repository)/$(Private_Branch)

# # ✅ 파일 다운로드 함수 (Authorization 헤더에 Bearer 적용)
# # 사용법: $(call download_private_file,private_repo_path,local_destination_path)
# define download_private_file
# 	mkdir -p "$$(dirname "$(2)")" && \
# 	curl -fL -H "Authorization: Bearer $(GITHUB_ACCESS_TOKEN)" -o "$(2)" "$(BASE_URL)/$(1)"
# endef

# # ✅ .env 파일 없을 경우 GitHub 토큰을 받아 저장
# download-privates:
# 	@echo "🔐 Downloading private files..."
# 	@if [ ! -f .env ]; then \
# 		read -p "Enter your GitHub access token: " token; \
# 		echo "GITHUB_ACCESS_TOKEN=$$token" > .env; \
# 	fi
# 	@set -a && . .env && set +a && \
# 	$(MAKE) _download-privates-real
# 	@echo ""

# # ✅ 실제 다운로드 로직 (여러 파일 추가 가능)
# # private repo는 모듈러 repo 경로를 그대로 미러링한다.
# # 예: PopPang-Private(iOS branch)/Projects/App/Resources/GoogleService-Info.plist
# _download-privates-real:
# 	$(call download_private_file,Projects/App/Secrets.xcconfig,Projects/App/Secrets.xcconfig)
# 	$(call download_private_file,Projects/App/Resources/GoogleService-Info.plist,Projects/App/Resources/GoogleService-Info.plist)


# # -----------------------------
# # 🔐 인증서 불러오기 
# # -----------------------------
# fetch-certificates:
# 	@echo "🔐 Fetching signing certificates using fastlane match..."
# 	@export MATCH_PASSWORD=$$(grep MATCH_PASSWORD .env | cut -d '=' -f2) && \
# 	bundle exec fastlane match development --readonly --app_identifier kr.co.poppang.PopPang && \
# 	bundle exec fastlane match appstore --readonly --app_identifier kr.co.poppang.PopPang
# 	@echo ""


# -----------------------------
# 🧱 Tuist Module Scaffold
# -----------------------------
LAYER ?=
NAME ?=
INTERFACE ?= false

module-help:
	@echo "Usage:"
	@echo "  make module LAYER=feature NAME=Home"
	@echo "  make module LAYER=feature NAME=PopupDetail INTERFACE=true"
	@echo "  make regen"
	@echo "  make trash"
	@echo "  make clean"
	@echo "  make reinstall"
	@echo ""
	@echo "Available layers:"
	@echo "  app, coordinator, feature, domain, data, thirdparty, core, dskit, shared"
	@echo ""
	@echo "Examples:"
	@echo "  make module LAYER=app NAME=AppSession"
	@echo "  make module LAYER=coordinator NAME=Root"
	@echo "  make module LAYER=feature NAME=Home"
	@echo "  make module LAYER=feature NAME=PopupDetail INTERFACE=true"
	@echo "  make module LAYER=domain NAME=Popup"
	@echo "  make module LAYER=data NAME=Popup"
	@echo "  make module LAYER=thirdparty NAME=Firebase"
	@echo "  make module LAYER=core NAME=HTTPClient"
	@echo "  make module LAYER=dskit NAME=DSKit"
	@echo "  make module LAYER=shared NAME=UIComponents"
	@echo "  make regen"
	@echo "  make trash"
	@echo "  make clean"
	@echo "  make reinstall"

module:
	@if [ -z "$(LAYER)" ] || [ -z "$(NAME)" ]; then \
		echo "❌ LAYER and NAME are required."; \
		echo ""; \
		$(MAKE) module-help; \
		exit 1; \
	fi
	@case "$(LAYER)" in \
		app) TEMPLATE="app-module" ;; \
		coordinator) TEMPLATE="coordinator-module" ;; \
		feature) TEMPLATE="feature-module" ;; \
		domain) TEMPLATE="domain-module" ;; \
		data) TEMPLATE="data-module" ;; \
		thirdparty) TEMPLATE="third-party-module" ;; \
		core) TEMPLATE="core-module" ;; \
		dskit) TEMPLATE="dskit-module" ;; \
		shared) TEMPLATE="shared-module" ;; \
		*) \
			echo "❌ Unsupported layer: $(LAYER)"; \
			echo ""; \
			$(MAKE) module-help; \
			exit 1; \
			;; \
	esac; \
	echo "🧱 Scaffolding $$TEMPLATE with NAME=$(NAME)"; \
	if [ "$(LAYER)" = "feature" ]; then \
		tuist scaffold $$TEMPLATE --name $(NAME) --include-interface $(INTERFACE); \
	else \
		tuist scaffold $$TEMPLATE --name $(NAME); \
	fi

# -----------------------------
# ♻️ Regenerate Tuist Projects
# -----------------------------
regen:
	@echo "♻️ Removing generated xcodeproj/Derived artifacts..."
	@find Projects -name '*.xcodeproj' -type d -prune -exec rm -rf {} +
	@find Projects -name 'Derived' -type d -prune -exec rm -rf {} +
	@echo "🧱 Running tuist generate..."
	@tuist generate

# -----------------------------
# 🗑 Remove Build Outputs Only
# -----------------------------
trash:
	@echo "🗑 Removing local build outputs..."
	@rm -rf build
	@rm -rf /tmp/poppang-*-dd
	@find Projects -name 'Derived' -type d -prune -exec rm -rf {} +
	@find Projects -name 'build' -type d -prune -exec rm -rf {} +
	@find ~/Library/Developer/Xcode/DerivedData -maxdepth 1 -name 'PopPang-*' -type d -prune -exec rm -rf {} +
	@echo "✅ Local build outputs removed."

# -----------------------------
# 🧹 Clean Local Build Artifacts
# -----------------------------
clean:
	@echo "🧹 Removing generated workspace/project artifacts..."
	@rm -rf PopPang.xcworkspace
	@find Projects -name '*.xcodeproj' -type d -prune -exec rm -rf {} +
	@find Projects -name 'Derived' -type d -prune -exec rm -rf {} +
	@find Projects -name 'build' -type d -prune -exec rm -rf {} +
	@echo "🧹 Removing local Xcode DerivedData for PopPang..."
	@find ~/Library/Developer/Xcode/DerivedData -maxdepth 1 -name 'PopPang-*' -type d -prune -exec rm -rf {} +
	@echo "🧹 Cleaning Tuist local cache..."
	@tuist clean
	@echo "✅ Local build artifacts and Tuist caches removed."

# -----------------------------
# 🔄 Reinstall Tuist Dependencies and Regenerate
# -----------------------------
reinstall: clean
	@echo "📦 Reinstalling Tuist dependencies..."
	@tuist install
	@echo "🧱 Running tuist generate..."
	@tuist generate
	@echo "✅ Tuist dependencies reinstalled and workspace regenerated."
