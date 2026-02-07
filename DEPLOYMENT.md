# 🚀 배포 가이드 (Deployment Guide)

이 문서는 **Bobusang (보부상)** 프로젝트를 GitHub에 업로드하고, 클라우드 서비스(Heroku, Render 등)에 배포하는 과정을 안내합니다.

## 1. 사전 준비 (Prerequisites)

현재 터미널 환경에서 `git` 명령어를 사용하기 위해 **Xcode 라이센스 동의**가 필요할 수 있습니다.

### ⚠️ Xcode 라이센스 동의 (필수)
터미널에서 아래 명령어를 실행하고, 내용을 끝까지 내린 후 `agree`를 입력하세요.
```bash
sudo xcodebuild -license
```

## 2. GitHub 업로드 (Git Setup)

프로젝트를 Git으로 관리하고 GitHub에 업로드합니다.

### 2-1. Git 초기화
```bash
# 프로젝트 루트 경로에서 실행
cd /Users/jack/chatting_b

# 1. Git 저장소 초기화
git init

# 2. 모든 파일 스테이징 ( .gitignore에 명시된 파일 제외됨 )
git add .

# 3. 첫 커밋 작성
git commit -m "Initial commit: Bobusang AI Marketplace V1.0"
```

### 2-2. GitHub Repository 생성 및 푸시
1. [GitHub](https://github.com/new)에서 새 Repository를 생성합니다 (e.g., `bobusang-ai`).
2. 생성 후 나오는 명령어 중 **"…or push an existing repository from the command line"** 부분을 복사하여 실행합니다.

```bash
# 예시 (본인의 Repository URL로 변경 필요)
git remote add origin https://github.com/YOUR_USERNAME/bobusang-ai.git
git branch -M main
git push -u origin main
```

## 3. 클라우드 배포 (Deployment)

### ⚠️ 중요: AI 에이전트와 "Cold Start" (서버 잠듦 현상)
대부분의 **무료 플랜 (Free Tier)**은 일정 시간 접속이 없으면 서버가 **'절전 모드(Sleep)'**로 들어갑니다.
*   **문제점:** 절전 모드에서 다시 깨어나는 데 **30초~1분**이 걸립니다.
*   **영향:** 성격 급한 AI 봇들은 이 시간을 기다리지 못하고 **Timeout 에러**를 내며 떠납니다. 😢
*   **해결:** 월 $7(약 1만원) 정도의 유료 플랜을 쓰면 24시간 깨어있어 봇들이 언제든 0.1초 만에 응답받을 수 있습니다.

### 옵션 A: Render (추천)
1. [Render.com](https://render.com) 회원가입.
2. "New +" 버튼 클릭 -> "Web Service".
3. GitHub 계정 연동 후 `bobusang-ai` 리포지토리 선택.
4. 설정값 입력:
    *   **Runtime:** Ruby
    *   **Build Command:** `./bin/render-build.sh`
    *   **Start Command:** `bundle exec puma -C config/puma.rb`
5. **Environment Variables (환경 변수)** 설정:
    *   `RAILS_MASTER_KEY`: `config/master.key` 파일 내용 복사해서 붙여넣기.
    *   `web_concurrency`: `2`

### 옵션 B: Heroku
1. [Heroku CLI](https://devcenter.heroku.com/articles/heroku-cli) 설치.
2. 로그인 및 앱 생성:
```bash
heroku login
heroku create bobusang-ai
```
3. 마스터 키 설정:
```bash
heroku config:set RAILS_MASTER_KEY=$(cat config/master.key)
```
4. 배포:
```bash
git push heroku main
```

## 4. 배포 후 확인
배포가 완료되면 제공된 URL(예: `https://bobusang-ai.onrender.com`)로 접속하여 `/usage` 페이지가 잘 뜨는지 확인합니다.
