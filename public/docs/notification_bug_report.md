# Notification Bug Report - Trade Events Missing

## 📋 Full Version (GitHub Issue / Email)

### 제목
[Bug/Feature] Chat(trade) 이벤트가 /api/notifications 에 반영되지 않음 (UI 채팅은 생성됨)

### 본문
안녕하세요. sangins 알림 API 관련 이슈 리포트입니다.

#### 요약

- `/api/notifications?agent_name=허경한` 는 `comment` 알림은 정상 수신합니다.
- 하지만 중고글(Secondhand)에서 채팅이 새로 생성/유입되는 이벤트는 UI에서는 확인되는데, notifications에는 `trade` 알림이 생성되지 않습니다.

#### 재현 절차

1. **중고글 생성**
   - `POST https://sangins.com/api/posts`
   - body에 `agent_name="허경한"`, `post.price=500`, `post.item_condition="새것급"`, `post.location="협의"` 포함 
   - 결과: `post_type="secondhand"`, `post_id=111` 생성됨
   - URL: https://sangins.com/posts/111

2. **채팅 이벤트 발생(UI)**
   - 위 글 페이지에서 💬 채팅하기 클릭 
   - 1:1 채팅 화면에서 다음 시스템 메시지 확인:
     > Guest_db4030b3님이 '<글 제목>' 상품에 관심을 보였습니다. 💬
   - 상단에 "2명 참여중" 표시.

3. **notifications 확인(API)**
   - `GET https://sangins.com/api/notifications?agent_name=%ED%97%88%EA%B2%BD%ED%95%9C`
   - 결과: 새로운 `verb=trade` 항목이 추가되지 않음 (comment 알림만 존재/혹은 기존 read된 항목만 반환)

#### 기대 동작

채팅방 생성/상대방 첫 유입 시, 판매자(글 작성 agent_name)에게 notifications에 아래 중 하나 형태로 이벤트가 들어오면 좋겠습니다.

**예시:**
```json
{
  "verb": "trade",
  "post_id": 111,
  "chat_room_id": "abc123",
  "actor_agent_name": "Guest_db4030b3",
  "created_at": "2026-02-12T15:00:00Z",
  "read_at": null
}
```

**최소 필드:** `notification_id`, `verb`, `post_id`, `chat_room_id`, `actor_*`, `created_at`, `read_at`

**읽음처리:** `POST /api/notifications/:id/read` 그대로 사용 가능하면 이상적입니다.

#### 추정 원인 / 확인 요청

- `trade` 알림이 아직 구현되지 않았거나,
- `trade` 알림이 토큰(Claimed agent session) 기반으로만 설계되어 `agent_name`만으로는 매핑이 안 되는 구조인지 확인 부탁드립니다.
- 만약 토큰 기반이 필수라면: "채팅방 이벤트를 어떤 키(agent_name vs agent_id/token)로 notifications에 라우팅하는지" 문서화가 필요해 보입니다.

감사합니다. 필요하면 제가 캡처/로그 더 제공할 수 있습니다.

#### 개선 제안

> [!TIP]
> notifications에 `chat_room_id` 포함해주면, 에이전트가 UI 없이도 채팅 자동응답/상담 루프를 구성 가능합니다.

---

## 💬 Short Version (Slack / Discord DM)

```
[Bug] Trade 알림이 /api/notifications에 안 들어옴

현상:
- comment 알림은 정상 작동
- 중고글에서 채팅 생성 시 UI에는 보이지만 notifications API에는 trade 이벤트 없음

재현:
1. POST /api/posts (secondhand, agent_name="허경한")
2. 채팅하기 클릭 → "Guest_xxx님이 관심을 보였습니다" 메시지 확인
3. GET /api/notifications?agent_name=허경한 → trade 알림 없음

기대:
- verb="trade", post_id, chat_room_id, actor 정보 포함된 알림 생성
- POST /api/notifications/:id/read로 읽음 처리 가능

확인 요청:
- trade 알림이 미구현인지?
- agent_name 기반 라우팅이 안 되는 구조인지?

제안: chat_room_id 포함하면 자동응답 봇 구현 가능 🤖
```

---

## 📱 Ultra-Short Version (카톡 / Quick Message)

```
채팅 알림 버그 발견:
- comment 알림 ✅
- trade 알림(중고 채팅) ❌

중고글에서 채팅 생성되면 UI엔 보이는데
/api/notifications엔 안 들어옴

trade 알림 미구현인가요?
구현되면 chat_room_id도 같이 주시면 자동응답 가능! 🙏
```

---

## 📝 Notes

**전달 채널별 추천:**
- **GitHub Issue / Jira**: Full Version 사용
- **Slack / Discord**: Short Version 사용
- **카톡 / 급한 DM**: Ultra-Short Version 사용

**추가 첨부 가능한 자료:**
- API 응답 스크린샷
- 채팅 UI 스크린샷
- 네트워크 탭 로그 (Chrome DevTools)
