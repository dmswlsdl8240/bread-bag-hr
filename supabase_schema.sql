-- =========================================================
-- 명함 / 명찰 제작 관리 시스템 DB 스키마
-- Supabase SQL Editor에서 그대로 실행하세요.
-- =========================================================

-- 1) 마스터 테이블 (지점 / 부서) -----------------------------
-- 지점, 부서 목록은 화면에 하드코딩하지 않고 여기서 관리합니다.
-- 지점/부서가 늘거나 바뀌면 코드 수정 없이 이 테이블만 수정하면 됩니다.

create table if not exists branches (
  id           uuid primary key default gen_random_uuid(),
  name         text not null unique,        -- 예: 부평본점
  sort_order   int  not null default 0,
  is_active    boolean not null default true,
  created_at   timestamptz not null default now()
);

create table if not exists departments (
  id           uuid primary key default gen_random_uuid(),
  name         text not null unique,        -- 예: 홀, 주방, 관리
  sort_order   int  not null default 0,
  is_active    boolean not null default true,
  created_at   timestamptz not null default now()
);

-- 2) 명함 신청 테이블 -----------------------------------------
-- 신청자가 직접 입력 (지점/부서/이름/입사일/직급/휴대폰/이메일)
-- 이후 인사담당자, 디자인담당자가 각자 독립적으로 크로스체크

create table if not exists card_applications (
  id                 uuid primary key default gen_random_uuid(),

  -- 신청자 입력 항목
  branch_id          uuid references branches(id),
  department_id      uuid references departments(id),
  name               text not null,
  hire_date          date not null,
  job                text,
  position           text not null,
  phone              text not null,
  email              text not null,

  -- 인사담당자 체크 (재직/입퇴사 여부 확인)
  hr_verified        boolean not null default false,
  hr_verified_by     text,
  hr_verified_at     timestamptz,
  employment_status  text not null default '재직중' check (employment_status in ('재직중','퇴사')),
  resigned_at        date,

  -- 디자인담당자 체크 (발급 처리)
  design_verified    boolean not null default false,
  design_verified_by text,
  design_verified_at timestamptz,
  issued             boolean not null default false,
  issued_by          text,
  issued_at          timestamptz,

  status             text not null default '신청접수'
                       check (status in ('신청접수','확인중','발급완료','보류','반려')),
  note               text,

  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now()
);

-- 3) 명찰 제작 테이블 -------------------------------------------
-- 명함과 달리 신청자 입력이 아니라 인사담당자가 재직자 기준으로 직접 등록/관리
-- (휴대폰, 이메일 불필요)

create table if not exists name_tags (
  id                 uuid primary key default gen_random_uuid(),

  branch_id          uuid references branches(id),
  department_id      uuid references departments(id),
  name               text not null,
  hire_date          date not null,
  position           text not null,

  employment_status  text not null default '재직중' check (employment_status in ('재직중','퇴사')),
  resigned_at        date,

  -- 인사담당자 체크 (입퇴사 인원 체크)
  hr_checked         boolean not null default false,
  hr_checked_by      text,
  hr_checked_at      timestamptz,

  -- 디자인담당자 체크 (발급 완료 처리)
  design_checked     boolean not null default false,
  design_checked_by  text,
  design_checked_at  timestamptz,
  issued             boolean not null default false,
  issued_by          text,
  issued_at          timestamptz,

  status             text not null default '등록'
                       check (status in ('등록','확인중','발급완료','회수(퇴사)')),
  note               text,

  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now()
);

-- 4) updated_at 자동 갱신 트리거 -------------------------------
create or replace function set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_card_applications_updated_at on card_applications;
create trigger trg_card_applications_updated_at
  before update on card_applications
  for each row execute function set_updated_at();

drop trigger if exists trg_name_tags_updated_at on name_tags;
create trigger trg_name_tags_updated_at
  before update on name_tags
  for each row execute function set_updated_at();

-- 5) 참고: 지점/부서 데이터는 실제 운영 값으로 직접 입력하세요.
-- 예시)
-- insert into branches (name, sort_order) values ('부평본점', 1), ('강남점', 2);
-- insert into departments (name, sort_order) values ('홀', 1), ('주방', 2), ('관리', 3);

-- 5-1) 실제 운영 지점 / 부서 (최초 1회 실행) -----------------------
insert into branches (name, sort_order) values
  ('본사', 1), ('빵백이네', 2), ('계양구청점', 3), ('신중동점', 4),
  ('마곡점', 5), ('송도점', 6), ('청라점', 7)
on conflict (name) do nothing;

insert into departments (name, sort_order) values
  ('운영부', 1), ('사업부', 2), ('생산부', 3)
on conflict (name) do nothing;

-- 5-2) 기존에 이미 스키마를 실행한 적이 있다면 job 컬럼만 추가 -------
alter table card_applications add column if not exists job text;

-- 6) RLS(행 단위 보안)는 별도 시스템 코드 작업 시 설계에 맞춰 설정하세요.
-- 지금은 개발 편의를 위해 비활성 상태로 둡니다. 운영 전 반드시 정책을 설정하세요.
alter table branches disable row level security;
alter table departments disable row level security;
alter table card_applications disable row level security;
alter table name_tags disable row level security;
