# 명함 · 명찰 제작 관리 시스템 (껍데기)

Supabase를 DB로 사용하는 정적 HTML 2개입니다. 지점/부서/직급 등 **데이터 값은 전부 Supabase에서 로드**하며 코드에 하드코딩되어 있지 않습니다.

## 파일 구성 (HTML 2개)
- `supabase_schema.sql` — Supabase SQL Editor에서 1회 실행할 테이블 생성 스크립트
- `card_application_form.html` — **명함신청서** : 신청자 전용 폼. 관리 기능 없음. 지점/부서/이름/직급/입사일 + 휴대폰번호/이메일 입력 후 신청
- `nametag_admin.html` — **명찰·명함 통합 관리(인사담당자 / 디자인담당자)** : 명찰 등록·입퇴사관리 + 명함 신청 확인을 한 화면에서 처리

## 설정 순서
1. Supabase 프로젝트 생성 후 SQL Editor에서 `supabase_schema.sql` 실행 (RLS 정책까지 포함되어 있음)
2. `branches`(지점), `departments`(부서) 테이블에 실제 지점/부서명 직접 입력
   (파일 하단 예시 주석 참고, 지점·부서가 바뀌어도 이 테이블만 수정하면 됨)
3. `config.example.js`를 같은 폴더에 `config.js`로 복사한 뒤 실제 Supabase URL / anon
   publishable key / EmailJS 값을 채워 넣기. **`config.js`는 `.gitignore`에 등록되어 있어
   git에는 올라가지 않으므로, 리포지토리 소스에는 실제 키가 남지 않습니다.**
   배포할 때(GitHub Pages, Vercel 등) `config.js`를 HTML 파일과 같은 위치에 함께 올려야 동작합니다.
4. (선택) 관리자 개인 기기에서 다른 Supabase 프로젝트를 쓰고 싶다면 각 화면의
   **"DB 연결 설정"**에서 URL/Key를 입력 — 브라우저 localStorage에만 저장되고 `config.js`보다 우선 적용됨
   - `card_application_form.html`은 하단 "관리자용 DB 설정" 링크에 숨겨져 있음 (신청자 화면에 노출 안 되도록)
5. 두 파일을 같은 도메인에 배포하면 설정값(`hr_supabase_cfg`)이 공유됨

## 명함신청서 (card_application_form.html)
- 신청자가 직접 지점/부서/이름/직급/입사일 + 휴대폰번호/이메일을 입력해 신청
- 관리 기능(확인·발급)은 전혀 없음 — 직원들에게 이 링크만 공유하면 됨

## 명찰·명함 통합 관리 (nametag_admin.html)
- **인사담당자 탭**
  - 명찰: 입사자 등록(+버튼), 재직상태 변경, 인사확인 체크
  - 명함: 신청 접수 목록 확인, 재직상태 변경, 인사확인 체크
- **디자인담당자 탭**
  - 명찰 / 명함 각각: 디자인확인 체크 → 인사확인·디자인확인 둘 다 완료돼야 발급완료 체크 가능
- 명찰은 퇴사 처리 후 발급된 상태면 "회수(퇴사)"로 자동 표시

## 교차체크 로직
- 명찰: `hr_checked` / `design_checked`, 명함: `hr_verified` / `design_verified` — 서로 다른 담당자가 각자 체크. 한쪽 탭에서는 상대방 체크 여부를 "읽기 전용"으로만 확인 가능
- 두 체크가 모두 완료되어야 "발급완료" 체크박스가 활성화됨 (실수 방지)
- 체크 시 확인자 이름을 입력받아 누가 확인했는지 기록

## 보안 상태 (중요)
- `supabase_schema.sql`에 RLS 정책이 포함되어 있어, `branches`/`departments`(지점·부서 마스터
  데이터)는 anon key로 조회만 가능하고 변조는 막혀 있습니다.
- 다만 이 앱은 로그인이 없어 신청서 화면과 관리자 화면이 **같은 anon key**를 씁니다. 따라서
  `card_applications`(신청자 이름/전화번호/이메일)와 `name_tags`는 RLS로도 "관리자만" 접근하게
  제한할 수 없고, anon key를 아는 사람이면 누구나 조회/등록/수정/삭제가 가능합니다.
  - anon key는 배포된 페이지 소스(`config.js`)에 그대로 노출되므로, **개인정보를 진짜로
    보호하려면 Supabase Auth 로그인을 관리자 화면에 추가**해야 합니다. 필요하면 별도로 요청하세요.
- 현재는 프롬프트(prompt)로 확인자 이름을 받는 임시 방식입니다. 로그인 붙이면 자동으로 대체하시면 됩니다.
