# Dynamic Island 스타일 패널 모드

## 요약

Notchi 앱에 "아일랜드" 패널 스타일을 추가한다. 기존 노치 스타일은 그대로 유지하고, 설정에서 전환 가능하게 한다.

## 배경

현재 비노치 모니터에서도 노치 형태(상단에 붙은 검은 필)로 표시되어 어색하다. iPhone Dynamic Island처럼 메뉴바 아래에 떠있는 둥근 캡슐 형태를 추가하여, 사용자가 선호하는 스타일을 선택할 수 있게 한다.

## 디자인

### 접힌 상태 (Collapsed)

- 메뉴바 아래에 약간의 갭(~5pt)을 두고 떠있는 둥근 캡슐
- 모든 모서리가 둥글다 (RoundedRectangle, cornerRadius ~18pt)
- 미세한 border(rgba(255,255,255,0.06))와 그림자(shadow)로 떠있는 느낌
- 스프라이트는 캡슐 안에 가로로 배치 (기존 비노치 헤더 로직 재활용)
- 클릭 시 확장

### 펼친 상태 (Expanded)

- 캡슐이 아래로 부드럽게 커지는 spring 애니메이션
- 모든 모서리 둥글게 유지 (RoundedRectangle, cornerRadius ~20pt)
- 그림자와 border 유지 — 떠있는 느낌 그대로
- 내부 콘텐츠(잔디, 세션 목록, 사용량 바 등)는 기존과 동일

### 설정 UI

- `PanelSettingsView`에 세그먼트 선택 추가: [ 노치 ] [ 아일랜드 ]
- `AppSettings`에 `panelStyle` 저장 (UserDefaults)
- 기본값: `notch` (기존 동작)

## 변경 파일

### AppSettings.swift
- `panelStyle: PanelStyle` enum 추가 (`notch`, `island`)
- UserDefaults 저장/로드

### PanelSettingsView.swift
- 세그먼트 Picker 추가 (노치 / 아일랜드)

### NotchPanel.swift
- 아일랜드 모드: `.statusBar` 레벨 사용
- 아일랜드 모드: `.stationary` 제거

### NotchContentView.swift
- 아일랜드 모드: `NotchShape` 대신 `RoundedRectangle` 클립
- 아일랜드 모드: 상단 padding 추가 (메뉴바 아래 갭)
- 아일랜드 모드: 그림자와 border 추가
- 아일랜드 모드: 접힌 상태 헤더에서 스프라이트를 캡슐 중앙에 배치

### NotchPanelManager.swift
- 아일랜드 모드: notchRect/panelRect 계산 시 메뉴바 아래 위치로 조정

### NSScreen+Notch.swift
- 아일랜드 모드: notchWindowFrame 계산 시 메뉴바 높이만큼 아래로 오프셋

## 기존 코드 영향 없음

- 노치 스타일 코드는 수정하지 않음
- `panelStyle == .notch`일 때 현재 동작 100% 유지
- 아일랜드 모드는 분기 처리로 추가

## 범위 외

- 아일랜드 전용 애니메이션 (추후 개선 가능)
- 아일랜드 크기 커스터마이징
- 다크/라이트 모드별 아일랜드 색상 변경
