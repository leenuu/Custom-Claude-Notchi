# Notchi

A macOS notch companion that reacts to Claude Code activity in real time.

Original project: [sk-ruban/notchi](https://github.com/sk-ruban/notchi)

## 한국어

### 소개

Notchi는 Claude Code 활동에 실시간으로 반응하는 macOS 노치 컴패니언 앱입니다.

원작자의 `v1.0.0`을 기반으로, 내 입맛대로 커스텀하고 싶어서 만든 `v1.1.0` notch fix 버전입니다.

### 원본 프로젝트

- 원본 저장소: [sk-ruban/notchi](https://github.com/sk-ruban/notchi)
- 원작자 버전: `v1.0.0`
- 현재 커스텀 버전: `v1.1.0`

### 주요 기능

- Claude Code 이벤트를 실시간으로 감지하고 반응
- 대화 분위기를 분석해 감정 표현 표시
- 노치를 클릭해 세션 시간과 사용량 확인
- 여러 Claude Code 세션을 동시에 표시
- 사운드 효과 지원
- Sparkle 기반 자동 업데이트 지원

### 패치 노트

#### `v1.1.0` - Notch Fix

- `v1.0.0` 원작자 버전을 기반으로 한 커스텀 버전
- 노치 관련 수정 사항을 반영한 버전
  - 노치가 없는 환경(외부 모니터)에서 macOS 상단 바에 맞게 자동 조절

## English

### Overview

Notchi is a macOS notch companion app that reacts to Claude Code activity in real time.

This repository contains `v1.1.0`, a customized notch fix release based on the original author's `v1.0.0`, created because I wanted a version tailored to my own preferences.

### Upstream Project

- Original repository: [sk-ruban/notchi](https://github.com/sk-ruban/notchi)
- Original author version: `v1.0.0`
- Current custom version: `v1.1.0`

### Features

- Reacts to Claude Code events in real time
- Analyzes conversation sentiment for emotional reactions
- Click the notch to view session time and usage
- Supports multiple concurrent Claude Code sessions
- Includes optional sound effects
- Supports auto-updates via Sparkle

### Patch Notes

#### `v1.1.0` - Notch Fix

- Custom release based on the original `v1.0.0`
- Includes notch-related fixes for this repository
  - Automatically adjusts to the macOS menu bar in environments without a notch, such as external monitors
