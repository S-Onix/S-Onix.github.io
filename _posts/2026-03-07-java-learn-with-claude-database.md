---
title: Transaction, Isolation Level, DB 내부 구조
date: 2026-03-06 17:11:06 +0900
categories: [자바, 클로드, F-lab]  # 예: [개발, Python]
tags: [자바, 스프링, Web, database]        # 예: [python, tutorial]
---

## 📌 소개

- 소개 : 클로드 문답형식을 활용한 데이터베이스
- 목표 : 데이터베이스를 학습한다

## 📝 본문

## 1. Transaction

여러 DB 작업을 하나의 논리적 단위로 묶어서, **전부 성공하거나 전부 실패**하게 만드는 것입니다.

java

```java
@Transactional
public void transfer(Long fromId, Long toId, int amount) {
    accountRepository.withdraw(fromId, amount);   // 출금
    accountRepository.deposit(toId, amount);       // 입금
    // 정상 종료 → COMMIT (전부 확정)
    // RuntimeException → ROLLBACK (전부 취소)
}
```

------



## 2. ACID

트랜잭션이 보장해야 하는 4가지 속성입니다.

```
A (Atomicity, 원자성):    전부 성공 or 전부 실패 → Undo Log로 보장
C (Consistency, 일관성):  트랜잭션 전후로 DB 규칙 항상 만족 → 제약 조건으로 보장
I (Isolation, 격리성):    동시 트랜잭션이 서로 간섭하지 않음 → Lock + MVCC로 보장
D (Durability, 지속성):   커밋되면 영구 저장 → WAL(Redo Log)로 보장
```

------



## 3. Commit과 Rollback

**Commit**: 트랜잭션의 모든 변경 사항을 영구적으로 DB에 반영. Redo Log를 디스크에 flush하고 Lock을 해제합니다.

**Rollback**: 트랜잭션의 모든 변경 사항을 원래 상태로 되돌림. Undo Log를 읽어서 변경 전 데이터를 복구합니다.

------



## 4. Isolation Level

동시에 실행되는 트랜잭션 간에 서로의 변경을 얼마나 볼 수 있는지 결정하는 수준입니다.

```
격리 강함 ←──────────────────────────→ 격리 약함
SERIALIZABLE  REPEATABLE READ  READ COMMITTED  READ UNCOMMITTED
  안전 ⬆️                                        성능 ⬆️
```

### 격리가 안 되면 생기는 3가지 문제

**Dirty Read**: 다른 트랜잭션이 아직 커밋하지 않은 데이터를 읽는 현상. READ COMMITTED 이상이면 방지.

**Non-Repeatable Read**: 같은 트랜잭션 내에서 같은 데이터를 두 번 읽었는데 값이 달라지는 현상. REPEATABLE READ 이상이면 방지.

**Phantom Read**: 같은 조건으로 조회했는데 행의 수가 달라지는 현상. SERIALIZABLE이면 방지. MySQL InnoDB는 REPEATABLE READ에서도 Gap Lock으로 대부분 방지.

### 4가지 Isolation Level

| Level                | Dirty Read | Non-Repeatable Read | Phantom Read | 성능      |
| -------------------- | ---------- | ------------------- | ------------ | --------- |
| **READ UNCOMMITTED** | ⚠️ 발생     | ⚠️ 발생              | ⚠️ 발생       | 가장 빠름 |
| **READ COMMITTED**   | ✅ 방지     | ⚠️ 발생              | ⚠️ 발생       | 빠름      |
| **REPEATABLE READ**  | ✅ 방지     | ✅ 방지              | ⚠️ 발생       | 보통      |
| **SERIALIZABLE**     | ✅ 방지     | ✅ 방지              | ✅ 방지       | 가장 느림 |

**MySQL(InnoDB) 기본값**: REPEATABLE READ **PostgreSQL 기본값**: READ COMMITTED

------



## 5. MVCC (Multi-Version Concurrency Control)

데이터의 여러 버전을 동시에 유지하여, **읽기와 쓰기가 서로 차단하지 않게** 하는 동시성 제어 메커니즘입니다.

### 구글 독스로 비유하면

```
MVCC 없는 세상 (Word 파일 공유폴더):
  철수: "보고서 열어서 읽을게" → 파일 열림 → 🔒 잠김!
  영희: "나도 열고 싶은데..." → "다른 사용자가 편집 중입니다" → 대기...
  → 하나의 파일을 한 명만 사용 가능 → 나머지는 줄 서서 대기

MVCC 있는 세상 (구글 독스의 버전 기록):
  10:00 철수: 보고서를 열어서 읽기 시작 (이 시점의 버전을 봄)
  10:01 영희: 보고서의 내용을 수정 → 새로운 버전 생성!
  10:02 민수: 보고서를 열어서 읽음 (최신 버전을 봄)
  → 3명이 동시에 작업! 아무도 기다리지 않음!
```

### MVCC 없이 vs 있으면

```
MVCC 없이 (Lock만 사용):
  트랜잭션A: 읽는 중 (Read Lock)
  트랜잭션B: 수정하고 싶음 → A의 Lock 때문에 대기...
  트랜잭션C: 읽고 싶음 → A의 Lock 때문에 대기...
  → 읽기끼리도 차단! 성능 저하!

MVCC 있으면:
  트랜잭션A: 이전 버전(v1)을 읽음 (Lock 없음!)
  트랜잭션B: 현재 버전(v2)으로 수정 (A와 충돌 없음!)
  트랜잭션C: v2를 읽음 (Lock 없음!)
  → 아무도 기다리지 않음! 동시 처리 성능 높음!
```

### 구체적 동작 방식

데이터가 변경되면 이전 버전을 Undo Log에 보관합니다. 각 트랜잭션은 자신의 시작 시점에 맞는 버전을 읽습니다.

```
테이블: orders (id=1, status='PENDING')

① 트랜잭션 A 시작 (10:00) → 이 시점의 스냅샷 생성

② 트랜잭션 B 시작 (10:01) → status를 'PAID'로 변경 + 커밋!

   DB 내부:
   ┌──────────────────────────────────────────┐
   │ 현재 버전 (v2): status = 'PAID'           │ ← B가 수정한 최신 값
   │ 이전 버전 (v1): status = 'PENDING'        │ ← Undo Log에 보관
   └──────────────────────────────────────────┘

③ 트랜잭션 A가 조회: → v1('PENDING')을 읽음 (A는 10:00에 시작했으니까)
④ 새 트랜잭션 C 시작 (10:02): → v2('PAID')를 읽음 (B 커밋 이후에 시작했으니까)
```

### Isolation Level에 따른 차이

```
READ COMMITTED:
  매번 쿼리 실행 시점의 최신 커밋된 버전을 읽음
  → 같은 트랜잭션 안에서도 쿼리마다 다른 값이 나올 수 있음 (Non-Repeatable Read)

REPEATABLE READ:
  트랜잭션 시작 시점의 스냅샷을 고정하여 읽음
  → 같은 트랜잭션 안에서 항상 같은 값 (Non-Repeatable Read 방지)
10:00 트랜잭션 A 시작
10:01 트랜잭션 B가 500→300으로 변경 + 커밋

READ COMMITTED인 경우:
  A가 10:02에 조회 → 300 (B가 커밋했으므로 최신값)

REPEATABLE READ인 경우:
  A가 10:02에 조회 → 500 (A 시작 시점의 스냅샷)
```

### MVCC와 Lock의 역할 분담

```
MVCC가 해결:  읽기 ↔ 쓰기 충돌 (이전 버전으로 해결)
Lock이 해결:  쓰기 ↔ 쓰기 충돌 (Lock으로 순서 보장)
```

### Undo Log와의 관계

```
원본 데이터: status = 'PENDING' (v1)

트랜잭션 B가 UPDATE:
  현재 데이터: status = 'PAID' (v2)     ← 실제 테이블
  Undo Log:   status = 'PENDING' (v1)  ← 이전 버전 보관

Undo Log의 두 가지 역할:
  ① 롤백: ROLLBACK하면 Undo Log에서 이전 값을 복구
  ② MVCC: 다른 트랜잭션이 이전 버전을 읽을 때 Undo Log에서 제공
```

### 자주 헷갈리는 포인트 (FAQ)

**Q: 이전 버전을 영원히 보관해?** → 아닙니다. 그 버전을 읽는 트랜잭션이 전부 끝나면 삭제합니다.

**Q: Lock을 아예 안 쓰는 거야?** → 읽기(SELECT)는 Lock 없이 이전 버전을 읽습니다. 쓰기(UPDATE)끼리는 여전히 Lock을 사용합니다. MVCC는 "읽기 vs 쓰기"의 충돌만 해결합니다.

------



## 6. DB 내부 구조 — 쿼리 처리 과정

```
SQL 쿼리
  ↓
① Parser: SQL 문법 검사 + 파싱 트리 생성
  ↓
② Optimizer: 최적의 실행 계획 수립 (어떤 인덱스를 쓸까?)
  ↓
③ Execution Engine: 실행 계획대로 Storage Engine에 데이터 요청, 결과 조합
  ↓
④ Storage Engine (InnoDB):
   → Buffer Pool(메모리 캐시) 확인 → 있으면 바로 반환
   → 없으면 디스크에서 읽어서 Buffer Pool에 적재 후 반환
```

### Parser

SQL 문법을 검사하고 파싱 트리(AST)를 생성합니다. 문법이 틀리면 여기서 에러가 발생합니다.

### Optimizer

여러 실행 방법 중 비용이 가장 낮은 실행 계획을 수립합니다. EXPLAIN 명령어로 실행 계획을 확인할 수 있습니다.

```sql
EXPLAIN SELECT * FROM orders WHERE user_id = 1 AND status = 'PAID';

-- type: ALL(Full Scan, 느림) / ref(인덱스, 빠름) / const(PK, 가장 빠름)
-- key: 실제 사용된 인덱스
-- rows: 예상 읽기 행 수 (적을수록 좋음)
```

### Execution Engine

Optimizer가 결정한 실행 계획대로 Storage Engine에 데이터를 요청하고, JOIN, 정렬(ORDER BY), 그룹핑(GROUP BY) 등을 수행합니다.

### Storage Engine (InnoDB)

실제 데이터를 디스크에 저장하고 읽어오는 컴포넌트입니다.

```
InnoDB 특징:
  ✅ 트랜잭션 지원 (ACID)
  ✅ 행 레벨 락 (높은 동시성)
  ✅ MVCC 지원
  ✅ Foreign Key 지원
  ✅ Crash Recovery (WAL)
```

------



## 7. Buffer Pool

디스크에서 읽은 데이터 페이지를 메모리에 캐시하여 빠르게 접근하는 영역입니다. 디스크 읽기는 메모리 읽기보다 약 1000배 느리므로, Buffer Pool로 디스크 접근을 최소화합니다.

```
Buffer Pool에 있으면 (Cache Hit):  메모리에서 바로 반환 → 0.01ms
Buffer Pool에 없으면 (Cache Miss): 디스크에서 읽기 → 10ms
```

Buffer Pool이 가득 차면 LRU(Least Recently Used) 알고리즘으로 오래 안 쓴 데이터를 밀어내고 새 데이터를 적재합니다. 실무에서는 서버 전체 메모리의 70~80%를 Buffer Pool에 할당합니다.

------



## 8. WAL (Write-Ahead Log)

데이터를 변경할 때 실제 데이터 파일에 바로 반영하지 않고, **먼저 로그(Redo Log)에 기록**하는 방식입니다. "Write-Ahead"란 "미리 쓴다"는 뜻으로, 실제 데이터보다 로그를 먼저 쓴다는 의미입니다.

### 편의점 비유로 이해하기

```
편의점 알바:

1단계 (판매 시): 물건을 팔 때마다 메모장에 기록
  "콜라 1개 팔림, 삼각김밥 2개 팔림"
  → 메모장 끝에 한 줄씩 추가 → 빠름!
  → 손님에게 "결제 완료!" 응답

2단계 (한가한 시간에): 메모장을 보고 재고 장부를 업데이트
  → 콜라 칸 찾아서 -1, 삼각김밥 칸 찾아서 -2
  → 여기저기 찾아가며 수정 → 느리지만 바쁜 시간이 아니니까 괜찮음

메모장 = WAL (Redo Log)     → 빠르게 기록만
재고 장부 = 실제 데이터 파일   → 나중에 천천히 반영
```

### 두 단계로 쓰기

```
1단계 (커밋 시):
  WAL(Redo Log)에 순차 쓰기 (Sequential I/O, 빠름!) → 커밋 완료!
  실제 데이터 파일은 아직 안 바꿈

2단계 (나중에, 백그라운드 — Checkpoint):
  WAL에 기록된 내용을 실제 데이터 파일에 반영 (Random I/O, 느림)
  → 백그라운드에서 천천히 하면 됨!
```

### WAL이 빠른 이유 — Sequential I/O vs Random I/O

```
직접 데이터 파일에 쓰기 (Random I/O):
  "책의 32쪽 수정 → 157쪽 수정 → 8쪽 수정 → 241쪽 수정"
  → 디스크 헤드가 여기저기 이동해야 함 → 느림!

WAL에 쓰기 (Sequential I/O):
  "노트 끝에 한 줄씩 추가: ①32쪽 변경 ②157쪽 변경 ③8쪽 변경"
  → 항상 파일 끝에만 쓰면 됨, 이동 필요 없음 → 빠름!
속도 비교:
  Random I/O:     약 100~200 작업/초
  Sequential I/O: 약 10,000~100,000 작업/초
  → 수십~수백 배 차이!
```

디스크(HDD)의 물리적 구조 때문입니다. Random I/O는 디스크 헤드가 여기저기 이동해야 하고(Seek Time), Sequential I/O는 현재 위치에서 바로 다음에 쓰면 됩니다. SSD에서도 Random보다 Sequential이 빠릅니다.

### 장애 복구

```
1단계: WAL에 기록 완료 ✅ (커밋됨)
       아직 실제 데이터 파일에는 미반영
       → 정전! 💥

서버 재시작:
  → WAL을 읽음
  → "이 변경은 커밋됐는데 데이터 파일에 아직 반영 안 됐네"
  → WAL 내용을 데이터 파일에 다시 적용 → 복구 완료!
```

WAL에 기록만 되어있으면 언제든 복구할 수 있기 때문에, 1단계만 끝나면 커밋이 보장됩니다.

### Redo Log와 Undo Log

```
Redo Log (WAL):  "이 변경을 다시 적용해"
  → 장애 복구 시 커밋된 변경을 재적용 → ACID의 D(Durability) 보장

Undo Log:        "이 변경을 되돌려"
  → 롤백 시 이전 상태로 복구 → ACID의 A(Atomicity) 보장
  → MVCC에서 이전 버전 보관 → ACID의 I(Isolation) 보장
UPDATE orders SET status='PAID' WHERE id=1;  (이전 값: 'PENDING')

Redo Log에 기록: "id=1의 status를 'PAID'로 변경해"
  → 장애 복구 시: Redo Log를 읽고 변경을 다시 적용

Undo Log에 기록: "id=1의 이전 status는 'PENDING'이었어"
  → 롤백 시: Undo Log를 읽고 'PENDING'으로 복구
  → MVCC: 다른 트랜잭션이 이전 버전('PENDING')을 읽을 때 사용
```

### Checkpoint

Buffer Pool의 변경된 데이터(Dirty Page)를 디스크에 반영하는 시점입니다.

```
커밋 시:      Redo Log만 디스크에 flush (빠름, Sequential I/O)
Checkpoint:  Buffer Pool의 Dirty Page를 디스크에 반영 (느림, Random I/O)
             → Checkpoint 이후에는 해당 Redo Log가 필요 없어짐 → 재사용 가능
```

------



## 9. Lock

여러 트랜잭션이 같은 데이터에 동시에 접근할 때 충돌을 방지하는 메커니즘입니다.

### 비관적 락 vs 낙관적 락

**비관적 락**: "충돌이 일어날 거야" 가정 → 미리 잠금. `SELECT FOR UPDATE` 사용. 충돌이 많은 환경에 적합.

**낙관적 락**: "충돌이 안 일어날 거야" 가정 → 수정 시 version 검증. 충돌이 적은 환경에 적합.

### InnoDB Lock 종류

```
Row Lock:      특정 행만 잠금 → 동시성 높음
Gap Lock:      인덱스 사이의 간격을 잠금 → Phantom Read 방지
Next-Key Lock: Row Lock + Gap Lock → InnoDB REPEATABLE READ의 기본
Table Lock:    테이블 전체 잠금 → 동시성 낮음
```

------



## 10. 앞서 배운 내용과의 연결

```
@Transactional     → AOP Proxy가 트랜잭션 시작/커밋/롤백을 자동 관리
Checked Exception  → 기본적으로 롤백 안 됨, rollbackFor 필요
Propagation        → REQUIRED(기존 참여), REQUIRES_NEW(새 트랜잭션)
Saga 패턴          → MSA에서 분산 트랜잭션을 보상 트랜잭션으로 해결
MVCC               → 읽기가 쓰기를 차단하지 않음 → DB 높은 동시 처리 성능
Buffer Pool        → 메모리 캐시 → 디스크 I/O 최소화
WAL                → Sequential I/O로 성능 확보 + 장애 복구 보장
TCP Flow Control   → Backpressure의 네트워크 버전 (소비자가 속도 제어)
```

------

## 핵심 키워드

| 카테고리            | 키워드                                                       |
| ------------------- | ------------------------------------------------------------ |
| **Transaction**     | ACID, Commit, Rollback, @Transactional                       |
| **ACID 보장**       | Undo Log(A), 제약 조건(C), Lock+MVCC(I), WAL/Redo Log(D)     |
| **Isolation Level** | READ UNCOMMITTED, READ COMMITTED, REPEATABLE READ, SERIALIZABLE |
| **Read 문제**       | Dirty Read, Non-Repeatable Read, Phantom Read                |
| **MVCC**            | Multi-Version, Undo Log, 스냅샷, 읽기/쓰기 상호 비차단       |
| **DB 내부**         | Parser, Optimizer, Execution Engine, Storage Engine          |
| **Storage Engine**  | InnoDB, Buffer Pool, WAL, Redo Log, Undo Log                 |
| **Buffer Pool**     | 메모리 캐시, LRU, Cache Hit/Miss, 70~80% 메모리 할당         |
| **WAL**             | Write-Ahead Log, Sequential I/O, Checkpoint, 장애 복구       |
| **Lock**            | 비관적 락, 낙관적 락, Row Lock, Gap Lock                     |
| **도구**            | EXPLAIN, type, key, rows                                     |



## 🎯 면접 예상 질문

### Q1. Transaction이란 무엇이며, ACID를 설명해주세요.

**모범 답안:**

> Transaction은 여러 DB 작업을 하나의 논리적 단위로 묶어서, 전부 성공하거나 전부 실패하게 만드는 것입니다. 트랜잭션은 ACID 4가지 속성을 보장합니다. Atomicity(원자성)는 전부 성공 또는 전부 실패, Consistency(일관성)는 트랜잭션 전후로 DB 규칙을 항상 만족, Isolation(격리성)은 동시 트랜잭션이 서로 간섭하지 않음, Durability(지속성)는 커밋되면 영구 저장입니다.

**암기:** "전부 아니면 전무(A), 규칙 준수(C), 서로 간섭 없음(I), 영구 저장(D)"

### Q2. Isolation Level 4가지를 설명하고, MySQL과 PostgreSQL의 기본값은 무엇인가요?

**모범 답안:**

> Isolation Level은 SERIALIZABLE, REPEATABLE READ, READ COMMITTED, READ UNCOMMITTED 4가지입니다. SERIALIZABLE이 가장 안전하지만 느리고, READ UNCOMMITTED가 가장 빠르지만 Dirty Read가 발생합니다. READ COMMITTED는 커밋된 데이터만 읽어 Dirty Read를 방지하고, REPEATABLE READ는 트랜잭션 시작 시점의 스냅샷을 읽어 Non-Repeatable Read까지 방지합니다. MySQL(InnoDB)의 기본값은 REPEATABLE READ, PostgreSQL의 기본값은 READ COMMITTED입니다.

### Q3. Dirty Read, Non-Repeatable Read, Phantom Read의 차이를 설명해주세요.

**모범 답안:**

> Dirty Read는 다른 트랜잭션이 아직 커밋하지 않은 데이터를 읽는 현상입니다. Non-Repeatable Read는 같은 트랜잭션 내에서 같은 데이터를 두 번 읽었는데 값이 달라지는 현상입니다. Phantom Read는 같은 조건으로 조회했는데 다른 트랜잭션이 행을 추가하여 행의 수가 달라지는 현상입니다.

### Q4. MVCC란 무엇이며, 왜 필요한가요?

**모범 답안:**

> MVCC는 데이터의 여러 버전을 동시에 유지하여, 읽기와 쓰기가 서로 차단하지 않게 하는 동시성 제어 메커니즘입니다. 데이터가 변경되면 이전 버전을 Undo Log에 보관하고, 각 트랜잭션은 자신의 시작 시점에 맞는 버전을 읽습니다. READ COMMITTED에서는 매번 쿼리 시점의 최신 커밋된 버전을, REPEATABLE READ에서는 트랜잭션 시작 시점의 스냅샷을 읽습니다. MVCC 덕분에 읽기는 쓰기를 차단하지 않고, 쓰기는 읽기를 차단하지 않아 높은 동시 처리 성능을 얻을 수 있습니다.

**암기:** "여러 버전 유지 + Undo Log에 이전 버전 + 읽기/쓰기 상호 비차단"

### Q5. WAL(Write-Ahead Log)이란 무엇이며, 왜 사용하나요?

**모범 답안:**

> WAL은 데이터를 변경할 때 실제 데이터 파일에 바로 반영하지 않고, 먼저 로그(Redo Log)에 기록하는 방식입니다. 커밋 시 Redo Log만 디스크에 flush하면 Durability가 보장되므로, 정전 같은 장애 발생 시 로그에서 복구할 수 있습니다. WAL이 빠른 이유는 로그 파일 끝에 순서대로 추가하는 Sequential I/O이기 때문입니다. 실제 데이터 파일에 직접 쓰는 것은 여기저기 찾아가며 쓰는 Random I/O라 수십~수백 배 느립니다.

**암기:** "먼저 로그에 기록 → Sequential I/O(빠름) → 나중에 데이터 파일 반영 → 장애 시 로그에서 복구"

### Q6. SQL 쿼리가 DB 내부에서 처리되는 과정을 설명해주세요.

**모범 답안:**

> SQL 쿼리가 들어오면 먼저 Parser가 SQL 문법을 검사하고 파싱 트리를 생성합니다. 다음으로 Optimizer가 여러 실행 방법 중 비용이 가장 낮은 실행 계획을 수립합니다. 그 다음 Execution Engine이 실행 계획대로 Storage Engine에 데이터를 요청하고, JOIN이나 정렬 등의 작업을 수행합니다. 마지막으로 Storage Engine(InnoDB)이 실제 데이터를 가져오는데, 먼저 Buffer Pool(메모리 캐시)을 확인하고 있으면 바로 반환하고, 없으면 디스크에서 읽어와 Buffer Pool에 적재한 뒤 반환합니다.

**암기:** "Parser(문법) → Optimizer(실행 계획) → Execution Engine(실행) → Storage Engine(Buffer Pool → 디스크)"
