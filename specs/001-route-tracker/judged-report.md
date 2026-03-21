---
generated_by: sdr:judge-review
source_report: specs/001-route-tracker/review-report.md
source_spec: specs/001-route-tracker/spec.md
generated_at: 2026-03-20T00:02:00+09:00
status: verified
---

## Spec Review Report（検証済み）

**対象**: `specs/001-route-tracker/spec.md`
**日時**: 2026-03-20
**ステータス**: Needs Attention
**検証元**: `specs/001-route-tracker/review-report.md`

### 指摘一覧

| ID | Category | Severity | Confidence | Verdict | Location(s) | Summary | Recommendation |
|----|----------|----------|------------|---------|-------------|---------|----------------|
| A1 | 明確性 | HIGH | High | Verified | FR-011 (L95) | 「移動速度や状況に応じて」の「状況」が曖昧。何を基準に頻度を変えるか不明 | 「移動速度・加速度・GPS精度」など具体的なパラメータを列挙するか、判定条件テーブルを追加する |
| A2 | 明確性 | HIGH | High | Verified | FR-012 (L96) | 「自動的にストレージ管理を行う」の具体的な管理方法が不明 | 管理ルールを明示する（例: 「30日以上経過したデータを自動削除」「ストレージ使用量がNMBを超えた場合に古いデータから削除」） |
| A3 | 明確性 | MEDIUM | High | Verified | 受入シナリオ 2-2 (L37) | 「適切に表示される」は定量基準のない曖昧な形容詞 | 「経路線が途切れず、地図の縮尺に比例した太さで表示される」など具体的な検証可能条件に置き換える |
| T1 | テスト可能性 | HIGH | High | Verified | FR-011 (L95) | 位置情報取得頻度の自動調整ルールが未定義のため、正しく動作しているかテストできない | 速度帯ごとの取得間隔（例: 静止時60秒、歩行時10秒、車両移動時30秒）を定義する |
| T2 | テスト可能性 | HIGH | High | Verified | FR-012 (L96) | ストレージ管理の閾値・ルールが未定義のためテスト不可 | Assumptions の「30日間」を FR-012 本文に反映し、具体的な削除条件を記述する |
| T3 | テスト可能性 | MEDIUM | Medium | Verified | FR-003 (L87) | 「同一地点」の判定基準（半径何メートル以内か）が未定義 | 「半径Nメートル以内」など空間的な閾値を明示する |
| T4 | テスト可能性 | MEDIUM | High | Verified | Edge Cases (L76) | 「バッテリー残量が一定以下」の「一定」が未定義 | 具体的な閾値（例: 残量20%以下）を明示する |
| AI2 | AI親和性 | MEDIUM | Medium | Verified | FR-005 (L89), FR-010 (L94) | 1つのFRに複数の独立した要求が混在。FR-005は「ローカル保存」と「外部送信禁止」、FR-010は「精度情報保持」と「低精度区間の視覚的区別」 | 各FRを単一責任に分割する（例: FR-005→FR-005a「ローカル保存」+FR-005b「外部送信禁止」） |
| AI3 | AI親和性 | MEDIUM | Medium | Verified | 全体 | FR とユーザーストーリー間の相互参照（トレーサビリティ）がない | 各 FR に対応するユーザーストーリー番号を付記する（例: FR-001 → US-1） |
| G1 | 粒度一貫性 | MEDIUM | Medium | Verified | FR全体 | Feature レベル（FR-001, FR-002, FR-010, FR-011, FR-012）と Story レベル（FR-006, FR-007, FR-008, FR-009）が混在 | Feature レベルに統一するか、Story レベルの FR を親 Feature FR のサブ項目として構造化する |

### 品質次元スコアサマリー

| 品質次元 | スコア | 指摘数 | 主な懸念 |
|----------|--------|--------|----------|
| 完全性 (C) | PASS | 0 | なし |
| 明確性 (A) | WARN | 3 | FR-011, FR-012 の曖昧表現、受入シナリオの「適切に」 |
| テスト可能性 (T) | WARN | 4 | FR-011, FR-012 の判定条件未定義、FR-003 の空間閾値未定義 |
| 用語一貫性 (TM) | PASS | 0 | Key Entities の用語が本文中で一貫して使用されている |
| 要件間整合性 (IC) | PASS | 0 | FR間の矛盾なし、優先度依存も問題なし |
| AI親和性 (AI) | PASS | 2 | 複数要求混在、相互参照なし |
| 粒度一貫性 (G) | PASS | 1 | Feature/Story の2種混在（隣接レベル） |
| ドメイン適合性 (D) | N/A | - | ドメイン固有チェック: N/A — 汎用ドキュメント |

### メトリクス

- 総要件数 (FR): 12
- 総ユーザーストーリー数: 4
- 総受入シナリオ数: 11
- 総指摘数: 10 (CRITICAL: 0, HIGH: 4, MEDIUM: 6, LOW: 0)
- アクション付き指摘率: 100%
- 検証率: Verified 10 / Inferred 0 / Unverified（除外） 1

### 推奨アクション

- 粒度が混在しています（Feature, Story）。以下の対応を推奨します:
  - **粒度リファクタリング**: Story レベルの FR（FR-006〜FR-009）を親 Feature FR のサブ項目に統合し、FR は Feature レベルに統一する

---

## 検証サマリー

| 判定 | 件数 |
|------|------|
| Verified | 10 |
| Inferred | 0 |
| Unverified（除外） | 1 |

### 除外された指摘

| ID | Summary | 除外理由 |
|----|---------|---------|
| AI1 | Edge Cases に EC-NNN 形式のIDが付与されていない | spec.md には既に EC-001〜EC-005 が付番済み（`/sdr:assign-ids` が review-spec 後に実行されたため、レビュー時点の指摘は現在の仕様に該当しない） |

※ 除外された指摘が気になる場合は review-report.md を参照してください。
