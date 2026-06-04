# 수행 방법 2. Vagrant 기반 Ubuntu VM

이 문서는 B1-1 미션을 **로컬 Vagrant + VirtualBox** 기반 Ubuntu 22.04 VM에서 재현하기 위한 가이드입니다.

## 목적

- `git clone` 후 `vagrant up` 만으로 동일한 Ubuntu 실습 환경을 다시 만들 수 있도록 합니다.
- 미션 요구사항(SSH, UFW, 계정/그룹, 디렉토리/권한, cron)을 Vagrant 프로비저닝 스크립트에서 기본 세팅해 둡니다.

## 사전 준비

- VirtualBox (또는 Vagrant가 지원하는 하이퍼바이저)
- Vagrant
- Git

## 실행 방법

```bash
git clone https://github.com/0802222/Codyssey.git
cd Codyssey

vagrant up         # Ubuntu 22.04 VM 생성 + provision.sh 실행
vagrant ssh        # VM 접속
```

접속 후에는 메인 `README.md`의 순서를 따라 SSH 설정, 방화벽, 계정/그룹, 앱 실행, monitor.sh, crontab 설정 상태를 검증하고, 필요 시 수동으로 조정합니다.

## Vagrantfile 개요

프로젝트 루트에 있는 `Vagrantfile`은 다음과 같은 역할을 합니다.

- `bento/ubuntu-22.04` 박스 기반 VM 생성
- 포트 포워딩
  - 호스트 20022 → 게스트 20022 (SSH)
  - 호스트 15034 → 게스트 15034 (APP)
- CPU/메모리 설정
- 최초 부팅 시 `scripts/provision.sh` 실행

## 프로비저닝 스크립트 개요 (`scripts/provision.sh`)

프로비저닝 스크립트는 다음 작업을 자동으로 수행합니다.

- 필수 패키지 설치 (ufw, cron, acl, net-tools 등)
- `agent-admin`, `agent-dev`, `agent-test` 계정 및 `agent-common`, `agent-core` 그룹 생성
- 디렉토리 구조 생성
  - `/home/agent-admin/agent-app`
  - `/home/agent-admin/agent-app/upload_files`
  - `/home/agent-admin/agent-app/api_keys`
  - `/var/log/agent-app`
- 권한/ACL 설정
  - `upload_files` → `agent-common` 쓰기 가능
  - `api_keys`, `/var/log/agent-app` → `agent-core`만 접근
- `AGENT_*` 환경 변수 설정 (`/etc/profile.d/agent-app.sh`)
- `sshd_config` 수정
  - `Port 20022`
  - `PermitRootLogin no`
- UFW 초기화 및 규칙 설정
  - 기본 deny incoming
  - 20022/tcp, 15034/tcp 허용
- `monitor.sh` 템플릿 생성 및 권한 설정
- `agent-admin` crontab에 `monitor.sh` 매분 실행 등록

자세한 내용과 실제 스크립트는 `scripts/provision.sh` 파일을 참고합니다.