# 미션 소개
- 안정적인 서버 운영 환경 직접 구축
- 다중 사용자 환경에서의 권한관리와 네트워크 보안 설정
- 시스템 리소스 관제와 로그 관리를 자동화하는 쉘 스크립트 개발 수행
<br>
<br>

# 핵심 개념
1. SSH 포트변경 & Root 차단
2. 방화벽 (네트워크 보안)
3. 계정/그룹/권한 관리 (최소 권한 원칙)
4. 환경 변수
5. 시스템 모니터링 스크립트
6. 자동 실행 (Crontab)
<br>
<br>

# 공통 - Docker / Container 준비
Codyssey 실습환경은 프로그램 설치가 제한되어 있어서,
제공된 OrbStack 을 사용하여 Docker 를 사용한다.
- docker version 확인
    ```bash
    # docker --version
    c08022220523@c3r2s1 ~ % docker --version
    
    Docker version 28.5.2, build ecc6942
    ```

- 컨테이너 생성 (linux-ubuntu)
    ```bash
    # docker run
    c08022220523@c3r2s1 ~ % docker run -it --name mission-b1-1 ubuntu:latest /bin/bash
    ```
- apt 패키지 의존성 관리
    
    컨테이너 내부 진입 후 실행 (프롬프트가 '#' 으로 표시되면 진입된 것 임) 
    ```bash
    root@abc123:/# apt update
    # apt update : 인터넷 저장소에서 설치 가능한 패키지 목록을 받아오기
  
    root@abc123:/# apt upgrade -y
    # 설치된 패키지들을 최신 버전으로 업그레이드 하기 (-y : 업그레이드 후 Yes/No 를 묻는데, 자동으로 Yes 라고 답하는 옵션)

  
    root@abc123:/# apt install -y nano openssh-server ufw cron
    # 4개의 패키지를 설치하고 자동으로 Yes 라고 답하기 (nano : 텍스트 에디터, openssh-server : ssh 서버, ufw : 방화벽, cron : 스케쥴 실행 도구)
    ```
- 컨테이너 나가기 (혹은 Ctrl + D) 
    ```bash
    root@a1b2c3d4e5f6:/# exit
    ```
- 컨테이너 실행만 하기 (백그라운드)
    ```bash
    docker start mission-b1-1
    ```
- 컨테이너에 접속해서 작업하기
    ```bash
    docker start -ai mission-b1-1
    # -i : Interactive,입력받기
    # -a : Attach, 컨테이너의 stdout/stderr를 현재 터미널에 연결해서 출력을 본다
    # -ai : 둘 다
    ```
<br>
<br>

# SSH
## SSH Port 변경
### 참고 : 설정 파일
`sshd_config` : 서버 데몬 설정 (외부 서버 -> 내 서버 접속 시)

(cf. `ssh_config` : 클라이언트 설정 (내 서버 -> 외부 서버 접속 시))
- SSH Daemon의 설정파일로, 외부에서 서버로 SSH 접속할 때의 동작을 제어한다.
- `sshd` 는 리눅스에서 항상 실행되고 있는 백그라운드 프로그램이다.
<br>
<br>

[ `sshd_config` 주요 내용 ]
- `Port`: SSH가 사용할 포트 번호 (기본값 22)
- `PermitRootLogin`: root 계정의 원격 로그인 허용 여부
- `PasswordAuthentication`: 비밀번호 인증 허용 여부
- `PubkeyAuthentication`: 공개키 인증 허용 여부
- `Protocol`: SSH 프로토콜 버전 선택 (보안상 2 권장)
- `ListenAddress`: SSH 서버가 특정 IP 주소로만 접속 받도록 설정
<br>
<br>

### 1. 설정파일에서 Port 변경
이미 컨테이너의 **root 권한**을 가지고 있기 때문에 **sudo** 명령어 없이 바로 편집할 수 있다.
```bash
nano /etc/ssh/sshd_config
```
- 포트 변경 전 (22)
![alt text](docs/screenshots/b1-1_포트%20변경%20전.png)
<br>
<br>

### 2. SSH 재시작
```bash
# service ssh restart
root@945e0b2ff039:/# service ssh restart
 
 * Restarting OpenBSD Secure Shell server sshd  
```

### 3. Port 변경 확인
```bash
# netstat 사용을 위한 apt 업그레이드
apt-get update

# netstat 사용을 위한 net-tools 설치
apt-get install net-tools

# 방법1. 변경 확인 (netstat : Network Statistics, N/W Interface or Protocol 상에서 통계를 보여주는 도구)
netstat -tulnp | grep 20022

# 방법2. 변경 확인 (ss : Socket Statistics, N/W Socket 정보 표시 유틸리티, 최신 리눅스에서 권장)
ss -tulnp | grep 20022

# 방법3. 변경 확인 (프로세스, aux : 시스템의 모든 실행중인 프로세스 상세 표시 명령어)
ps aux | grep sshd

# 방법4. 변경 확인 (SSH 포트)
cat /proc/net/tcp

# 방법 5. 컨테이너 내부에서 SSH 연결 테스트
ssh -p 20022 localhost
```


포트 변경 후 SSH 데몬이 20022 포트로 리스닝하도록 설정되었다. 

- 포트 변경 후 (20022)
![alt text](docs/screenshots/b1-1_포트%20변경%20후.png)
<br>
<br>



### ROOT 로그인 차단
<br>
<br>

### 방화벽 설정
<br>
<br>


<br>
<br>

# 트러블 슈팅
# 1. SSH 에서 포트 변경 후 재시작이 안됨

## 문제
컨테이너 환경에서 SSH 포트 변경 후 systemd 재시작을 명령했지만, 진행되지 않음
```bash
root@945e0b2ff039:/# systemctl restart ssh

System has not been booted with systemd as init system (PID 1). Can't operate.
Failed to connect to system scope bus via local transport: Host is down
```
<br>
<br>

## 원인
Docker 컨테이너는 systemd 가 기본적으로 실행되지 않기 때문이다.

컨테이너는 호스트의 커널을 공유하지만 systemd 같은 초기화 시스템은 컨테이너 내부에서 실행되지 않아서 `systemctl` 명령어를 사용할 수 없다.

<br>
<br>

## 해결
컨테이너에서는 systemctl 대신 SSH 데몬을 직접 실행해야 한다.

Ubuntu / Debian 계열
- SSH 데몬 재실행
    ```bash
    # service ssh restart
    root@945e0b2ff039:/# service ssh restart
    
    * Restarting OpenBSD Secure Shell server sshd
    ```

- 직접 실행 방법
    ```bash
    /usr/sbin/sshd
    ```

- 백그라운드 실행
    ```bash
    nohup /usr/sbin/sshd &
    ```

- 변경 확인
    ```bash
    # 방법1. netstat -nlp | grep sshd
    root@945e0b2ff039:/# netstat -nlp | grep sshd

    tcp        0      0 0.0.0.0:20022           0.0.0.0:*               LISTEN      30/sshd: /usr/sbin/ 
    tcp6       0      0 :::20022                :::*                    LISTEN      30/sshd: /usr/sbin/

    # 방법2. netstat -tulnp | grep 20022
    root@945e0b2ff039:/# netstat -tulnp | grep 20022

    tcp        0      0 0.0.0.0:20022           0.0.0.0:*               LISTEN      30/sshd: /usr/sbin/ 
    tcp6       0      0 :::20022                :::*                    LISTEN      30/sshd: /usr/sbin/ 
    ```
