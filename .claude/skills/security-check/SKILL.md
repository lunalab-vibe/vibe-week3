---
name: security-check
description: HTML/JS 파일을 4가지 보안 관점(하드코딩된 비밀번호·API 키 / escape 없이 innerHTML에 넣는 사용자 입력 XSS / console.log의 민감 정보 노출 / http:// 로 시작하는 외부 요청)으로 점검하고 결과를 🔴심각·🟡주의·🟢제안 + 파일:라인 근거로 보고한다. 트리거 문구는 "보안 점검", "security check". 사용자가 HTML·JavaScript 코드의 취약점, 노출된 비밀키, XSS, 안전하지 않은 요청을 확인·감사하려 할 때 사용한다. "이 코드 안전한지 봐줘", "취약점 점검", "보안 감사"처럼 명시적으로 스킬명을 말하지 않아도 웹 코드의 보안 상태를 묻는 상황이면 적극적으로 사용한다.
---

# security-check

HTML/JS 파일을 4가지 보안 관점으로 점검하고, 발견한 문제를 심각도별로 분류해 **파일:라인 근거와 함께** 한국어로 보고하는 스킬.

이 스킬의 목적은 "완벽한 정적 분석기"가 되는 게 아니라, 사람이 흔히 놓치는 대표적인 웹 보안 실수 4가지를 빠르게 짚어 주는 것이다. 그래서 오탐(false positive)을 줄이는 판단이 중요하다 — 근거 없는 경고를 남발하면 진짜 문제가 묻힌다.

## 언제 사용하나

- 사용자가 "보안 점검", "security check" 라고 요청할 때
- HTML·JavaScript 코드의 취약점, 노출된 키, XSS, 안전하지 않은 요청을 확인하고 싶을 때
- 명시적으로 스킬명을 말하지 않아도 "이 코드 안전해?", "취약점 있나 봐줘" 같은 보안 관련 질문이면 사용

## 점검 대상 선정

1. 사용자가 파일 경로를 지정하면 그 파일을 점검한다.
2. 지정이 없으면 프로젝트에서 `.html`·`.js` 파일을 찾는다. 여러 개면 사용자에게 어떤 파일(들)인지 확인한다.
3. HTML 파일 안의 인라인 `<script>`도 점검 범위에 포함한다.

## 4가지 점검 항목

각 항목을 순서대로 확인한다. 아래는 **기본 심각도**이며, 정황에 따라 올리거나 내릴 수 있다 — 판단 근거를 보고에 함께 적는다.

### 1. 하드코딩된 비밀번호·API 키 — 🔴 심각

소스에 박아 넣은 비밀은 저장소·브라우저 소스보기·배포 번들에 그대로 노출된다. 유출되면 되돌릴 수 없으므로 가장 위험하다.

- 찾는 신호:
  - 변수/속성 이름이 비밀을 암시: `password`, `passwd`, `pwd`, `secret`, `apiKey`, `api_key`, `token`, `accessToken`, `privateKey`, `clientSecret`, `auth` 등에 문자열 리터럴이 대입된 경우.
  - 잘 알려진 키 형태의 문자열: AWS `AKIA…`, `sk-…`/`sk-ant-…`(API 키), `ghp_…`(GitHub 토큰), `AIza…`(Google), `Bearer <긴 문자열>`, 긴 hex/base64 시크릿.
- 판정:
  - 실제 값처럼 보이면 🔴.
  - 명백한 자리표시자(`""`, `"your-api-key-here"`, `"changeme"`, `"xxxx"`)는 문제로 보지 않되, "실제 키로 대체 시 노출 주의"를 🟢 제안으로 언급.
- 오탐 주의: 단순히 `password`라는 **입력 필드 name/id**(`<input name="password">`)나 라벨 텍스트는 비밀 값이 아니다. **값이 대입된 리터럴**인지 확인한다.

**예시**
- 🔴 `const apiKey = "sk-ant-abc123realkey...";` — expense.html:12
- 🟢 `const apiKey = "";` — 자리표시자로 보이나, 실제 키를 넣게 되면 클라이언트에 노출됨

### 2. escape 없이 innerHTML에 넣는 사용자 입력 (XSS) — 🔴 심각

사용자가 넣은 값을 그대로 HTML로 해석시키면 스크립트가 실행될 수 있다(저장형/반사형 XSS). `textContent`는 안전하지만 `innerHTML` 계열은 위험하다.

- 찾는 신호(위험한 싱크):
  - `.innerHTML =`, `.outerHTML =`, `insertAdjacentHTML(...)`, `document.write(...)`, jQuery `.html(...)`.
- 그 값에 **사용자 입력 소스**가 섞였는지 확인:
  - `.value`(입력창), `location`/`location.hash`/`location.search`, `URLSearchParams`, `document.cookie`, `localStorage`/`sessionStorage`, `fetch()`/응답 데이터, 이벤트 객체, 서버에서 온 값 등.
  - 문자열 연결(`+`)이나 템플릿 리터럴(`` `...${userVal}...` ``)로 사용자 값을 끼워 넣으면 특히 위험.
- 판정:
  - 사용자 입력이 escape 없이 위험한 싱크로 들어가면 🔴.
  - `innerHTML = ''` 또는 **고정 문자열 리터럴**만 넣는 경우는 안전 — 문제 아님.
  - 동적이지만 사용자 출처가 불분명한 값이면 🟡로 낮추고 "출처 확인 필요"를 적는다.
- 안전한 대안을 수정 방법으로 제시: `textContent` 사용, 또는 값 escape/sanitize.

**예시**
- 🔴 `list.innerHTML = '<li>' + nameInput.value + '</li>';` — expense.html:210 → `textContent`로 값 설정 권장
- ✅ `list.innerHTML = '';` (초기화) 또는 `el.textContent = item.name;` — 안전

### 3. console.log의 민감 정보 노출 — 🟡 주의

`console.log`는 브라우저 콘솔·수집 로그에 값을 남긴다. 비밀번호·토큰·개인정보가 찍히면 어깨너머·로그수집·확장프로그램을 통해 샐 수 있다.

- 찾는 신호:
  - `console.log/​warn/​error/​info/​debug(...)` 안에 민감해 보이는 대상: `password`, `token`, `secret`, `apiKey`, `email`, `card`, `ssn`, 주민번호, `user`/`account` 객체 전체 등.
- 판정:
  - 민감 정보를 찍으면 기본 🟡.
  - 명백한 자격증명(비밀번호·API 키·토큰)을 그대로 찍으면 🔴로 올린다.
  - 디버깅용으로 남은 것으로 보이면 "배포 전 제거" 제안을 함께 적는다.
- 오탐 주의: `console.log('로그인 성공')`처럼 **리터럴 메시지만** 찍는 것은 문제 아님.

**예시**
- 🔴 `console.log('pw:', passwordInput.value);` — login.js:34
- 🟡 `console.log('user:', currentUser);` — 사용자 객체에 개인정보 포함 가능

### 4. http:// 로 시작하는 외부 요청 — 🟡 주의

`http://`는 평문 전송이라 중간자(MITM)가 가로채거나 변조할 수 있다. https 페이지에서는 혼합 콘텐츠로 차단되기도 한다.

- 찾는 신호:
  - `fetch("http://…")`, `XMLHttpRequest.open(..., "http://…")`, `axios`, WebSocket `ws://`.
  - 태그 속성: `<script src="http://…">`, `<img src="http://…">`, `<link href="http://…">`, `<iframe src="http://…">`, `<form action="http://…">`.
- 판정:
  - 평문 외부 요청은 기본 🟡. 수정 방법은 `https://`로 변경.
  - 그 요청에 **자격증명·개인정보가 실려** 나가면(예: 비밀번호를 http `form`으로 전송, 토큰을 http로 fetch) 🔴로 올린다.
- 오탐 주의 (중요): 아래는 실제 네트워크 요청이 아니므로 **제외**한다.
  - XML/SVG 네임스페이스: `xmlns="http://www.w3.org/2000/svg"`, `http://www.w3.org/1999/xhtml` 등.
  - DTD/스키마 식별자, 주석 안의 URL, 문서에 표시만 되는 텍스트 링크.
  - `http://localhost`·`http://127.0.0.1`(로컬 개발)은 🟢 제안 수준으로만 언급.

**예시**
- 🔴 `<form action="http://example.com/login" method="post">` — 비밀번호가 평문 전송됨
- 🟡 `fetch('http://api.example.com/data')` — `https://`로 변경 권장
- ✅ `xmlns="http://www.w3.org/2000/svg"` — 네임스페이스, 요청 아님

## 점검 방법

- 파일 내용은 Read 도구로 읽어 문맥(변수 출처, 값의 흐름)을 파악한다 — 단순 grep만으로는 오탐이 많다.
- 패턴 후보를 빠르게 모을 때는 Grep을 쓰되(`innerHTML`, `console.log`, `http://`, `apiKey` 등), **최종 판정은 반드시 코드 문맥을 읽고** 내린다.
- 줄 번호는 근거로 반드시 표기한다.
- 점검만 하고, 사용자가 요청하지 않는 한 파일을 직접 수정하지 않는다. 마지막에 수정 여부를 물어본다.

## 결과 보고 형식

한국어로, 아래 형식에 맞춰 보고한다. 심각도 순(🔴 → 🟡 → 🟢)으로 정렬한다.

```
# 보안 점검 결과: <파일명>

## 🔴 심각 (N건)
- [항목명] 문제 설명 — 파일:라인. 왜 위험한지 한 줄 + 수정 방법 한 줄.

## 🟡 주의 (N건)
- [항목명] 문제 설명 — 파일:라인. 수정 방법 한 줄.

## 🟢 제안 (N건)
- [항목명] 개선 제안 — 파일:라인.

## 요약
🔴 N건 · 🟡 N건 · 🟢 N건 — 한 줄 총평.
```

- 각 지적에는 **파일:라인**과 **구체적 수정 방법**을 함께 적는다.
- 4개 항목 중 문제없는 항목은 "✅ [항목명] 통과"로 요약에 간단히 표기한다.
- 문제가 하나도 없으면 4개 항목 모두 ✅ 통과로 보고하고 "🔴 0건" 을 명시한다.
