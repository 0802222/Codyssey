# B1-1 시스템 관제 자동화 스크립트 개발
- 안정적인 서버 운영 환경 직접 구축
- 다중 사용자 환경에서의 권한관리와 네트워크 보안 설정
- 시스템 리소스 관제와 로그 관리를 자동화하는 쉘 스크립트 개발 수행
<br>
<br>

## 핵심 개념
1. SSH 포트변경 & Root 차단
2. 방화벽 (네트워크 보안)
3. 계정/그룹/권한 관리 (최소 권한 원칙)
4. 환경 변수
5. 시스템 모니터링 스크립트
6. 자동 실행 (Crontab)
<br>
<br>

## 수행 방법1. docker container 이용
이 문서는 B1-1 미션을 Docker 컨테이너 기반으로 수행한 과정을 정리한 것입니다.

### 공통 - Docker / Container 준비
Codyssey 실습환경은 프로그램 설치가 제한되어 있어서, 제공된 `OrbStack` 을 통해 `Docker` 를 사용한다.
- docker version 확인
    ```bash
    # docker --version
    docker --version
    
    Docker version 28.5.2, build ecc6942
    ```

- 컨테이너 생성 (linux-ubuntu)

    컨테이너를 띄울 때 `네트워크/iptabls` 를 만질 수 있는 커널 `capability` 를 열어준다.

    ```bash
    # docker run
    docker run -it --name mission-b1-1 --cap-add=NET_ADMIN ubuntu:latest /bin/bash
    ```
    - 기본 도커 컨테이너는 NET_ADMIN 같은 네트워크 관리 capability 가 막혀 있어서 `iptables-restore` 가 Permission denied 가 난다.
    - `--cap-add=NET_ADMIN` 을 주면 해당 컨테이너에 "네트워크 관리" 권한이 붙고, 그안에서 iptables/ufw 명령이 통과 할 수 있게 된다.

- 패키지 설치 - `apt`
    
    `apt` 는 인터랙티브 사용을 기준으로 설계돼서, 일반 `사용자들이 터미널에서` 쓰기 좋다.

    cf. 컨테이너 내부 진입 후 실행 (프롬프트가 `#` 으로 표시되면 진입된 것 이다.) 
    
    ```bash
    # 설치 가능한 패키지 목록 받아오기
    apt update
  
    # 최신 버전으로 업그레이드 하기 (-y : 업그레이드 중 Yes/No 질문에 자동으로 Yes라고 답하는 옵션)
    apt upgrade -y

    # 4개의 패키지를 설치하고 자동으로 Yes 라고 답하기
    # nano : 텍스트 에디터
    # openssh-server : ssh 서버
    # ufw : 방화벽
    # cron : 스케쥴 실행 도구
    apt install -y nano openssh-server ufw cron
    ```
    
- 패키지 설치 - `apt-get`

    `apt-get` 은 출력이 심플해서, `스크립트/자동화`에서 파싱하기 좋고, 오래전부터 쓰여왔기 때문에 호환성과 안정성이 높다.
    
    ```bash
    # 업그레이드
    apt-get update

    # 패키지 설치
    # iproute2 : IP 주소, 라우팅, 네트워크 인터페이스 등을 관리하는 네트워크 유틸리티 모음
    # net-tools : ifconfig, netstat 같은 구버전 네트워크 도구 모음
    # acl : 파일/디렉토리 접근권한을 세밀하게 제어하기 위한 Access Control List 도구
    # sudo : 일반 사용자가 제한된 범위에서 root 권한 명령을 실행할 수 있게 해주는 권한 상승 도구
    apt-get install -y iproute2 net-tools acl sudo
  
    ```

- 컨테이너 나가기 (혹은 Ctrl + D) 
    ```bash
    root@abc123:/# exit
    ```

- 컨테이너 실행만 하기 (백그라운드)
    ```bash
    docker start mission-b1-1
    ```

- 컨테이너에 접속해서 작업하기
    ```bash
    docker exec -it mission-b1-1 /bin/bash
    ```
<br>
<br>

# 1. 기본 보안 설정
## 1-1. SSH Port 변경 (22 -> 20022)
### 포트를 왜 바꿔야 하나요?
기본 포트(22)는 봇 스캐닝, 무차별 대입 공격이 제일 많이 들어오기때문에, 포트를 바꾸는 것 만으로도 노이즈 트래픽을 크게 줄일 수 있다.

### 어디서 바꾸나요?
SSH Port 는 `sshd_config` 에서 수정할 수 있고, 

그 외 서버 데몬도 설정도 (외부 서버 -> 내 서버 SSH 접속 시) 할 수 있다.

- `Port`: SSH가 사용할 포트 번호 (기본값 22) -> `20022 로 변경`
- `PermitRootLogin`: root 계정의 원격 로그인 허용 여부 -> `no 로 차단`
- `PasswordAuthentication`: 비밀번호 인증 허용 여부
- `PubkeyAuthentication`: 공개키 인증 허용 여부
- `Protocol`: SSH 프로토콜 버전 선택 (보안상 2 권장)
- `ListenAddress`: SSH 서버가 특정 IP 주소로만 접속 받도록 설정

(cf. `ssh_config` : 클라이언트 설정 (내 서버 -> 외부 서버 접속 시))
<br>
<br>



### 1. Port 변경
이미 컨테이너의 `root 권한`을 가지고 있기 때문에 `sudo` 명령어 없이 바로 편집할 수 있다.
- `sshd_config` 파일 열기
    ```bash
    nano /etc/ssh/sshd_config
    ```
- 포트 변경

    Port `22` 를 주석 해제 하고, Port `20022` 로 변경한다.
    ![alt text](docs/screenshots/b1-1_포트%20변경%20전.png)


- 포트 변경 확인
    ```bash
    cat /etc/ssh/sshd_config
    ```
    
    포트 변경 후 SSH 데몬이 `20022` 포트로 리스닝하도록 설정되었다. 

    ![alt text](docs/screenshots/b1-1_포트%20변경%20후.png)
<br>
<br>

### 2. SSH 재시작
변경사항 적용을 위해 데몬을 재시작 한다.
```bash
# service ssh restart
root@abc123:/# service ssh restart
    
* Restarting OpenBSD Secure Shell server sshd  
```
<br>

### 3. Port 변경 확인
- 확인 방법1. `netstat` (Network Statistics)
    
    현재 LISTEN 중인 TCP/UDP 포트 목록 + 그 포트를 잡고 있는 프로세스(PID/이름)를 보여준다.
    ```bash
    netstat -tulnp | grep 20022

    tcp        0      0 0.0.0.0:20022           0.0.0.0:*               LISTEN      4552/sshd: /usr/sbi 
    tcp6       0      0 :::20022                :::*                    LISTEN      4552/sshd: /usr/sbi 
    ```

- 확인 방법2. `ss` (Socket Statistics)

    netstat의 최신 버전같은 도구, LISTEN 포트와 프로세스 정보를 더 빠르게 보여준다.
    ```bash
    ss -tulnp | grep 20022

    Netid   State    Recv-Q   Send-Q     Local Address:Port      Peer Address:Port  Process                                                                         
    tcp     LISTEN   0        128              0.0.0.0:20022          0.0.0.0:*      users:(("sshd",pid=4552,fd=6))                                                 
    tcp     LISTEN   0        128                 [::]:20022             [::]:*      users:(("sshd",pid=4552,fd=7))   
    ```

- 확인 방법3. `ps aux | grep` 프로세스
    
    시스템의 모든 실행중인 프로세스 + 동작 모드 상세 표시 명령어
    ```bash
    ps aux | grep sshd

    root        4552  0.0  0.0  10736  2400 ?        Ss   18:42   0:00 sshd: /usr/sbin/sshd [listener] 0 of 10-100 startups
    root        4625  0.0  0.0   3692  2096 pts/0    S+   18:47   0:00 grep --color=auto sshd
    ```

<br>
<br>



## 1-2. ROOT 로그인 차단 (prohibit-password -> no)
`root` 는 시스템 전체 권한이라 한번 탈취되면 방어수단이 거의 없어서, 일반 계정(`agent-admin`)으로 접속하고 `필요한 경우에만 sudo` 로 실행한다.

Root 로그인도 `sshd_config` 파일에서 수정할 수 있다.
### 1. 권한 변경 (전)
    
`PermitRootLogin` 의 주석을 해제하고, `prohibit-password` 를 `no` 로 변경한다.
```bash
nano /etc/ssh/sshd_config
```

![alt text](docs/screenshots/b1-1_PermitRootLogin%20변경%20전.png)


### 2. 권한 변경 (후)
```bash
root@abc123:/# cat /etc/ssh/sshd_config | grep PermitRootLogin
    
PermitRootLogin no

# the setting of "PermitRootLogin prohibit-password".
```

![alt text](docs/screenshots/b1-1_PermitRootLogin%20변경%20후.png)

### cf. PermitRootLogin 의 옵션
    - yes : Root 로그인 허용 (비밀번호 가능)  
    - no : Root 로그인 차단 (완전히 차단)
    - prohibit-password : Root 로그인은 허용하되, 비밀번호 인증은 금지한다. (공개키 인증으로만 접속가능)

### 3. 서비스 재시작
```bash
root@abc123:/# service ssh restart
    
* Restarting OpenBSD Secure Shell server sshd   
```


<br>
<br>

# 2. 방화벽 설정
### 방화벽 종류
1. `UFW` (Uncomplicated Firewall) -> 이걸로 진행
- iptables 래퍼
- Ubuntu, Debian
- 초보자 친화적

2. `Firewalld`
- iptables/nftables 래퍼
- RedHat, CentOS, Fedora
- 고급 기능 많음


## 방화벽 설정
`최소 권한 원칙`에 따라 미션에서 요구하는 서비스 2개 (SSH 20022/tcp, 앱 15034/tcp) 만 인바운드 허용하고, 나머지는 기본정책으로 불필요한 포트 노출을 차단한다.

- UFW 활성화
    ```bash
    # ufw enable
    root@abc123:/# ufw enable
    
    Firewall is active and enabled on system startup
    ```
- SSH 포트 허용 (20022)
    ```bash
    # ufw allow 20022/tcp
    root@abc123:/# ufw allow 20022/tcp
    
    Rule added
    Rule added (v6)
    ```
- APP 포트 허용 (15034)
    ```bash
    # ufw allow 15034/tcp
    root@abc123:/# ufw allow 15034/tcp

    Rule added
    Rule added (v6)
    ```

### 방화벽 상태 확인
- ufw status (20022/tcp ALLOW, 15034/tcp ALLOW)
![alt text](docs/screenshots/b1-1_방화벽%20상태%20확인.png)

<br>
<br>

# 3. 계정/그룹/권한 설정

### 그룹 생성
그룹을 `common`, `core` 로 나누어 생성하여, 테스트 계정은 앱 로그나 키 파일에는 접근하지 못하고, 업로드용 경로만 사용할 수 있도록 제한한다.
- `agent-common` 그룹: `admin`/`dev`/`test` 모두 포함 
    → `upload_files` 같이 같이 쓰는 경로에 `R`/`W` 권한 부여

- `agent-core` 그룹: `admin`/`dev`만 포함 
    → `api_keys`, `/var/log/agent-app` 같이 민감한 정보/운영 로그에는 이 그룹 사용자만 접근 가능하게 설정

```bash
# 그룹 생성
root@abc123:/# groupadd agent-common
root@abc123:/# groupadd agent-core

# 그룹 생성 확인
root@abc123:/# getent group | grep agent

agent-common:x:1001:
agent-core:x:1002:
```

### 계정 생성
- agent-admin : 관리자
- agent-dev : 스크립트 작성, 실행
- agent-test : 테스트 수행

    ```bash
    root@abc123:/# useradd -m -s /bin/bash agent-admin
    root@abc123:/# useradd -m -s /bin/bash agent-dev  
    root@abc123:/# useradd -m -s /bin/bash agent-test
    ```


### 그룹 소속 시키기
- `-aG` : 기존 그룹을 유지하면서 보조그룹(G)에 추가(a)
- `-G` : 기존 그룹을 현재 그룹으로 완전히 교체

    ```bash
    # agent-common
    root@abc123:/# usermod -aG agent-common agent-admin
    root@abc123:/# usermod -aG agent-common agent-dev  
    root@abc123:/# usermod -aG agent-common agent-test

    # agent-core
    root@abc123:/# usermod -aG agent-core agent-admin 
    root@abc123:/# usermod -aG agent-core agent-dev 
    ```

### 그룹 설정 후 계정 확인 - `id <계정 명>`
```bash
# id <계정 명>
root@abc123:/# id agent-admin
uid=1001(agent-admin) gid=1003(agent-admin) groups=1003(agent-admin),1001(agent-common),1002(agent-core)

root@abc123:/# id agent-dev  
uid=1002(agent-dev) gid=1004(agent-dev) groups=1004(agent-dev),1001(agent-common),1002(agent-core)

root@abc123:/# id agent-test
uid=1003(agent-test) gid=1005(agent-test) groups=1005(agent-test),1001(agent-common)
```
![alt text](docs/screenshots/b1-1%20그룹설정%20후%20계정%20확인.png)

---

## 미션 외
### 계정 수정
- 계정 이름 + 홈 디렉토리 같이 변경
- `-l` : 로그인 이름 변경 (old -> new)
- `-d <경로>` : 홈 디렉토리도 새 계정 명으로 변경
- `-m <경로>` : 기존 홈 내용을 새 경로로 이동
    ```bash
    # usermod -l <새 계정 명> -d <새 경로> -m <새 경로>
    usermod -l agent-new -d /home/agent-new -m agent-old
    ```

### 계정 삭제
- `-r` : 설정했던 하위 옵션까지 삭제

    ```bash
    # userdel -r <계정 명>
    userderl -r agent-admin

    # userdel 만 실행할 경우 남아 있는 홈 디렉터리 삭제 필요
    rm -rf /hone/agent-admin
    ```


### 그룹 수정
- 현재 그룹 확인
    ```bash
    # getent group <기존 계정 명>
- 그룹 수정

    ```bash
    # groupmod -n <새 계정 명> <기존 계정 명>
    groupmod -n agent-new agent-old
    ```


### 그룹 삭제 
- 그룹이 실제로 존재하는지 확인
    ```bash
    # getent group <그룹 명>
    getent group agent-old
    ```
- 이 그룹을 기본 그룹으로 쓰는 사용자가 있는지 확인
    ```bash
    # grep <그룹 명> /etc/passwd
    grep agent-old /etc/passwd
    ```
- 기본 그룹으로 사용중이라면 새그룹을 만들고, 사용자 기본그룹을 새 그룹으로 변경
    ```bash
    # usermod -g <새 그룹 명> <사용자 명>
    groupadd agent-new
    ```
- 그룹 삭제
    ```bash
    # groupdel <그룹 명>
    groupdel agent-old
    ```

<br>

---

## 디렉토리
### 디렉토리 생성 및 확인

```bash
# 디렉토리 생성
mkdir -p /home/agent-admin/agent-app
mkdir -p /home/agent-admin/agent-app/bin
mkdir -p /home/agent-admin/agent-app/upload_files
mkdir -p /home/agent-admin/agent-app/api_keys

# 디렉토리 확인
root@abc123:/# cd /home/agent-admin/agent-app
root@abc123:/home/agent-admin/agent-app# ls   
api_keys  bin  upload_files
```

### 디렉토리 소유자 변경 - `agent-app`
- 변경 전 : 소유자 agent-admin, 그룹 `agent-admin (admin)`

    ```bash
    chown -R agent-admin:agent-core /home/agent-admin/agent-app
    ```

    - `chown` : change owner, 파일/ 디렉토리 소유자와 그룹 변경
    - `R` : Recursive(재귀적) 옵션, 지정 디렉토리 및 그 안의 하위 디렉토리/파일까지 일괄 변경
    
- 변경 후 : 소유자 agent-admin, 그룹 `agent-core (admin, dev)`
    
    ```bash
    root@abc123:/home/agent-admin/agent-app# ls -al
    total 0
    drwxr-xr-x 1 agent-admin agent-core  46 May 27 14:04 .            # agent-core 로 변경
    drwxr-x--- 1 agent-admin agent-admin 72 May 27 14:03 ..
    drwxr-xr-x 1 agent-admin agent-core   0 May 27 14:04 api_keys     # agent-core 로 변경
    drwxr-xr-x 1 agent-admin agent-core   0 May 27 14:03 bin          # agent-core 로 변경
    drwxr-xr-x 1 agent-admin agent-core   0 May 27 14:03 upload_files # agent-core 로 변경
    ```


### 디렉토리 권한 변경 - `upload_files` (agent-common 모두 접근 가능)
소유/그룹을 `agent-admin:agent-common`으로 두고, 그룹에 쓰기 권한을 줘서 모든 역할이 업로드 가능하게 한다.
- 변경 전 : 디렉토리 권한 `755(drwxr-xr-x)`, 디렉토리 그룹 `agent-core`

    ```bash
    # 디렉토리의 권한 변경
    chmod 770 /home/agent-admin/agent-app/upload_files

    # 디렉토리의 그룹 변경
    chgrp agent-common /home/agent-admin/agent-app/upload_files
    ```


- 변경 후 : 디렉토리 권한 `770(drwxrwx---)`, 디렉토리 그룹 `agent-common`
    ```bash
    root@abc123:/home/agent-admin/agent-app# ls -al
    total 0
    drwxr-xr-x 1 agent-admin agent-core   46 May 27 14:04 .
    drwxr-x--- 1 agent-admin agent-admin  72 May 27 14:03 ..
    drwxr-xr-x 1 agent-admin agent-core    0 May 27 14:04 api_keys
    drwxr-xr-x 1 agent-admin agent-core    0 May 27 14:03 bin
    drwxrwx--- 1 agent-admin agent-common  0 May 27 14:03 upload_files # 770, agent-common 으로 변경
    ```

### 디렉토리 권한 변경 - `api_keys` (agent-core만 접근)
`agent-admin:agent-core`와 그룹 쓰기로 묶어서, admin/dev만 내용을 보고 쓸 수 있게 한다.
- 변경 전 : 디렉토리 권한 `755(drwxr-xr-x)`, 디렉토리 그룹 agent-core
    ```bash
    # 디렉토리의 권한 변경
    chmod 750 /home/agent-admin/agent-app/api_keys

    # 디렉토리의 그룹 변경
    chgrp agent-core /home/agent-admin/agent-app/api_keys
    ```
- 변경 후 : 디렉토리 권한 `750(drwxr-x---)`, 디렉토리 그룹 agent-core

    ```bash
    root@abc123:/home/agent-admin/agent-app# ls -al
    total 0
    drwxr-xr-x 1 agent-admin agent-core   46 May 27 14:04 .
    drwxr-x--- 1 agent-admin agent-admin  72 May 27 14:03 ..
    drwxr-x--- 1 agent-admin agent-core    0 May 27 14:04 api_keys # 750으로 변경
    drwxr-xr-x 1 agent-admin agent-core    0 May 27 14:03 bin
    drwxrwx--- 1 agent-admin agent-common  0 May 27 14:03 upload_files
    ```

---

## 로그 디렉토리
- 로그 디렉토리 생성
    ```bash
    mkdir -p /var/log/agent-app
    ```

- 로그 디렉토리 소유자 및 권한 변경
    ```bash
    # 디렉토리의 소유자 변경
    chown agent-admin:agent-core /var/log/agent-app

    # 디렉토리의 권한 변경
    chmod 770 /var/log/agent-app
    ```

- 변경 전 : 디렉토리 소유자 `root:root` , 디렉토리 권한 `755(drwxr-xr-x)`
    ```bash
    root@abc123:/var/log/agent-app# ls -al
    total 0
    drwxr-xr-x 1 root root   0 May 27 14:36 .
    drwxr-xr-x 1 root root 112 May 27 14:36 ..
    ```

- 변경 후 : 디렉토리 소유자 `agent-admin:agent-core` , 디렉토리 권한 `770(drwxrwx---)`
    ```bash
    root@abc123:/var/log/agent-app# ls -al
    total 0
    drwxrwx--- 1 agent-admin agent-core   0 May 27 14:36 .  # 770, agent-admin:agent-core 로 변경
    drwxr-xr-x 1 root        root       112 May 27 14:36 ..
    ```

### ACL 의존성 설치 및 설정 확인
- `ACL` 이란?

     : Access Control List, **기본권한(rwx)보다 상세한 권한 설정을 가능**하게하는 시스템
    - `setfacl` : 파일이나 디렉토리의 ACL 설정
    - `getfacl` : 파일이나 디렉토리의 ACL 설정 확인


- `agent-app` 디렉토리 권한 확인
    ```bash
    root@abc123:/var/log/agent-app# ls -l /home/agent-admin/agent-app/
    total 0
    drwxr-x--- 1 agent-admin agent-core   0 May 27 14:04 api_keys
    drwxr-xr-x 1 agent-admin agent-core   0 May 27 14:03 bin
    drwxrwx--- 1 agent-admin agent-common 0 May 27 14:03 upload_files
    ```

- ACL 설정 확인 - `upload_files`
    ```bash
    root@abc123:/var/log/agent-app# getfacl /home/agent-admin/agent-app/upload_files/
    getfacl: Removing leading '/' from absolute path names
    # file: home/agent-admin/agent-app/upload_files/
    # owner: agent-admin
    # group: agent-common
    user::rwx
    group::rwx
    other::---
    ```

- ACL 설정 확인 - `api_keys`
    ```bash
    root@abc123:/var/log/agent-app# getfacl /home/agent-admin/agent-app/api_keys
    getfacl: Removing leading '/' from absolute path names
    # file: home/agent-admin/agent-app/api_keys
    # owner: agent-admin
    # group: agent-core
    user::rwx
    group::r-x
    other::---
    ```
<br>
<br>

# 4. 환경변수
앱이 부팅할 때 아래 환경변수 값을 기준으로 경로와 포트를 검증한다.
환경변수로 경로를 고정해두면, 디렉토리 구조가 바뀌어도 스크립트만 수정하면 전체동작을 일관되게 유지할 수 있기 때문에 사용성 면에서 편리하다.

### 환경변수 설정
`agent-admin`의 bash 프로필에 환경 변수 추가
```bash
nano /home/agent-admin/.bashrc
```

- `/.bashrc` 파일 맨 끝에 추가
    ```bash
    export AGENT_HOME=/home/agent-admin/agent-app
    export AGENT_PORT=15034
    export AGENT_UPLOAD_DIR=$AGENT_HOME/upload_files
    export AGENT_KEY_PATH=$AGENT_HOME/api_keys/t_secret.key
    export AGENT_LOG_DIR=/var/log/agent-app
    ```

- 저장
    ```bash
    source /home/agent-admin/.bashrc
    ```

- 확인
    ```bash
    # echo $환경변수명

    root@abc123:~# echo $AGENT_HOME, $AGENT_PORT, $AGENT_UPLOAD_DIR, $AGENT_KEY_PATH, $AGENT_LOG_DIR

    /home/agent-admin/agent-app, 15034, /home/agent-admin/agent-app/upload_files, /home/agent-admin/agent-app/api_keys/t_secret.key, /var/log/agent-app
    ```


## API 키 생성

- 사용자 전환 (root -> agent-admin)
    ```bash
    root@abc123:~# su - agent-admin
    agent-admin@abc123:~$
    ```
    - `su` : Switch User, 다른 사용자로 전환하되 기존 사용자의 환경변수 유지 (옵션없이 su 만 입력하면 root 로 전환)
    - `su -` :다른 사용자로 완전히 전환하며, 환경변수와 홈 디렉토리 까지 변경 됨 (사용자명 없으면 root로 완전히 전환)
    - `sudo` : SuperUser Do, 권한만 빌려서 단일 명령어 실행

    - `exit` : exit 명령으로 logout 후 원래 계정으로 돌아온다.

- 키 파일 생성
    
    ```bash
    echo "agent_api_key_test" > /home/agent-admin/agent-app/api_keys/t_secret.key
    ```

- 컨테이너로 나가서 권한 설정
    소유자(`agent-admin`)만 `읽기/쓰기` 가 가능하게 하고, `그룹`은 내용 `확인`, `기타` 사용자는 `접근 불가`로 한다.
    ```bash
    exit
    chmod 640 /home/agent-admin/agent-app/api_keys/t_secret.key
    ```

- 확인
    ```bash
    cat /home/agent-admin/agent-app/api_keys/t_secret.key
    ```
![alt text](docs/screenshots/b1-1_사용자%20전환(root%20->%20agent-admin).png)

## 앱 실행 (./agent-app-linux-x86)
### 앱 실행 준비
- 호스트 터미널에서 `agent-app.zip` 다운로드 후 컨테이너의 `$AGENT_HOME`에 복사
    ```bash
    cd Downloads
    docker cp agent-app mission-b1-1:/home/agent-admin
    
    Successfully copied 14MB to mission-b1-1:/home/agent-admin
    ```
- 컨테이너 접속
    ```bash
    docker exec -it mission-b1-1 /bin/bash
    ```
- agent-admin으로 실행
    ```bash
    su - agent-admin
    cd $AGENT_HOME
    ./agent-app-linux-x86
    ```
### Error - `AGENT_KEY_PATH` 변경   
최초 요구사항인 `t_secret.key` 로 앱실행 시 아래와 같은 에러 발생하여 이에 맞게 `secret.key` 로 이름을 바꿔준다.
- 변경 전 : $AGENT_HOME/api_keys/`t_secret.key`
- 변경 후 : $AGENT_HOME/api_keys/`secret.key`

    ```bash
    agent-admin@abc123:~/agent-app$ ./agent-app-linux-x86 

    >>> Starting Agent Boot Sequence...
    [1/5] Checking User Account               [OK]
    ... Running as service user 'agent-admin' (uid=1001)
    [2/5] Verifying Environment Variables     [OK]
    ... All required Envs correct
    [3/5] Checking Required Files             [FAIL]
    >>> Missing File: secret.key
    >>>    (Expected location: /home/agent-admin/agent-app/api_keys/secret.key) # 요구사항 : secret.key 로 이름 바꾸기
    [4/5] Checking Port Availability          [FAIL]
    >>> Skipped due to previous critical failure.
    [5/5] Verifying Log Permission            [FAIL]
    >>> Skipped due to previous critical failure.
    --------------------------------------------------
    System Boot Failed. Process Terminated.
    
    ```
- `agent-admin`의 `~/.bashrc`에서 `AGENT_KEY_PATH` 변경
    ```bash
    mv /home/agent-admin/agent-app/api_keys/t_secret.key \
   /home/agent-admin/agent-app/api_keys/secret.key
    ```
- 변경 후 정상 호출
    ```bash
    agent-admin@abc123:~/agent-app$ echo agent_api_key_test
    
    agent_api_key_test
    ```



### 앱실행 & 정상 출력 확인

- agent-admin 으로 실행할 때 (정상 출력)
    ```bash
    agent-admin@abc123:~/agent-app$ ./agent-app-linux-x86
    >>> Starting Agent Boot Sequence...
    [1/5] Checking User Account               [OK]
    ... Running as service user 'agent-admin' (uid=1001)
    [2/5] Verifying Environment Variables     [OK]
    ... All required Envs correct
    [3/5] Checking Required Files             [OK]
    ... Verified 'secret.key' with correct key string.
    [4/5] Checking Port Availability          [OK]
    ... Port 15034 is available. # 포트 리슨
    [5/5] Verifying Log Permission            [OK]
    ... Log directory is writable: /var/log/agent-app
    ------------------------------------------------------------
    All Boot Checks Passed!
    Agent READY
    ```
    ![alt text](docs/screenshots/b1-1_secret.key%20이름변경%20후%20앱%20정상%20실행.png)

- root 로 실행할 때 (권한을 agent-admin 만 줬기 때문에 차단됨)
    ```bash
    root@abc123:/home/agent-admin/agent-app# ./agent-app-linux-x86 
    >>> Starting Agent Boot Sequence...
    [1/5] Checking User Account               [FAIL]
    >>> Error: Running as 'root' is forbidden.
    [2/5] Verifying Environment Variables     [FAIL]
    >>> Skipped due to previous critical failure.
    [3/5] Checking Required Files             [FAIL]
    >>> Skipped due to previous critical failure.
    [4/5] Checking Port Availability          [FAIL]
    >>> Skipped due to previous critical failure.
    [5/5] Verifying Log Permission            [FAIL]
    >>> Skipped due to previous critical failure.
    --------------------------------------------------
    System Boot Failed. Process Terminated.
    ```


### 앱 : 부하시뮬레이션
앱이 실행되고, `Agent READY` 상태가 되면 자동으로 `CPU 레벨`과 `메모리 사용량`을 25MB 씩 주기적으로 올렸다가(`UP`), 최대치에서 다시 내려오는(`DOWN`) 부하 시뮬레이션 진행

```bash
# UP
2026-05-29 15:48:27,665 [INFO] [SafetyGuard] Process priority lowered (nice=10).
2026-05-29 15:48:27,666 [INFO] Agent listening at port 15034
2026-05-29 15:48:27,666 [INFO] === Agent Worker Started ===
2026-05-29 15:48:27,666 [INFO]    > Cycle: 0 -> 256MB/Lv10 -> 0
2026-05-29 15:48:27,666 [INFO] --- Step Info: Mode=UP, CPU Lv=1, Mem=0MB ---
2026-05-29 15:48:27,704 [INFO] [Memory] Increasing... (+25 MB) Total: 25 MB
2026-05-29 15:48:27,705 [INFO] [CPU] Occupy core for 1s (Level 1)
2026-05-29 15:48:29,713 [INFO] --- Step Info: Mode=UP, CPU Lv=2, Mem=25MB ---
2026-05-29 15:48:29,752 [INFO] [Memory] Increasing... (+25 MB) Total: 50 MB
2026-05-29 15:48:29,752 [INFO] [CPU] Occupy core for 2s (Level 2)
2026-05-29 15:48:32,759 [INFO] --- Step Info: Mode=UP, CPU Lv=3, Mem=50MB ---
2026-05-29 15:48:32,778 [INFO] [Memory] Increasing... (+25 MB) Total: 75 MB
2026-05-29 15:48:32,778 [INFO] [CPU] Occupy core for 3s (Level 3)
2026-05-29 15:48:36,786 [INFO] --- Step Info: Mode=UP, CPU Lv=4, Mem=75MB ---
2026-05-29 15:48:36,828 [INFO] [Memory] Increasing... (+25 MB) Total: 100 MB
2026-05-29 15:48:36,828 [INFO] [CPU] Occupy core for 4s (Level 4)
2026-05-29 15:48:41,836 [INFO] --- Step Info: Mode=UP, CPU Lv=5, Mem=100MB ---
2026-05-29 15:48:41,877 [INFO] [Memory] Increasing... (+25 MB) Total: 125 MB
2026-05-29 15:48:41,877 [INFO] [CPU] Occupy core for 5s (Level 5)
2026-05-29 15:48:47,884 [INFO] --- Step Info: Mode=UP, CPU Lv=6, Mem=125MB ---
2026-05-29 15:48:47,924 [INFO] [Memory] Increasing... (+25 MB) Total: 150 MB
2026-05-29 15:48:47,924 [INFO] [CPU] Occupy core for 5s (Level 6)
2026-05-29 15:48:53,931 [INFO] --- Step Info: Mode=UP, CPU Lv=7, Mem=150MB ---
2026-05-29 15:48:53,972 [INFO] [Memory] Increasing... (+25 MB) Total: 175 MB
2026-05-29 15:48:53,972 [INFO] [CPU] Occupy core for 5s (Level 7)
2026-05-29 15:48:59,980 [INFO] --- Step Info: Mode=UP, CPU Lv=8, Mem=175MB ---
2026-05-29 15:49:00,023 [INFO] [Memory] Increasing... (+25 MB) Total: 200 MB
2026-05-29 15:49:00,023 [INFO] [CPU] Occupy core for 5s (Level 8)
2026-05-29 15:49:06,029 [INFO] --- Step Info: Mode=UP, CPU Lv=9, Mem=200MB ---
2026-05-29 15:49:06,072 [INFO] [Memory] Increasing... (+25 MB) Total: 225 MB
2026-05-29 15:49:06,072 [INFO] [CPU] Occupy core for 5s (Level 9)
2026-05-29 15:49:12,078 [INFO] --- Step Info: Mode=UP, CPU Lv=10, Mem=225MB ---
2026-05-29 15:49:12,120 [INFO] [Memory] Increasing... (+25 MB) Total: 250 MB
2026-05-29 15:49:12,120 [INFO] [CPU] Occupy core for 5s (Level 10)
2026-05-29 15:49:18,127 [INFO] --- Step Info: Mode=UP, CPU Lv=10, Mem=250MB ---
2026-05-29 15:49:18,135 [INFO] [Memory] Increasing... (+25 MB) Total: 275 MB
2026-05-29 15:49:18,135 [INFO] [CPU] Occupy core for 5s (Level 10)
# DOWN
2026-05-29 15:49:24,142 [INFO] >>> PEAK REACHED (Max Load). Switching to RAMP DOWN. ▼ <<<
2026-05-29 15:49:24,146 [INFO] --- Step Info: Mode=DOWN, CPU Lv=9, Mem=275MB ---
2026-05-29 15:49:24,147 [INFO] [Memory] Releasing... (-25MB) Total: 250MB
2026-05-29 15:49:24,147 [INFO] [CPU] Occupy core for 5s (Level 9)
2026-05-29 15:49:30,153 [INFO] --- Step Info: Mode=DOWN, CPU Lv=8, Mem=250MB ---
2026-05-29 15:49:30,154 [INFO] [Memory] Releasing... (-25MB) Total: 225MB
2026-05-29 15:49:30,154 [INFO] [CPU] Occupy core for 5s (Level 8)
2026-05-29 15:49:36,161 [INFO] --- Step Info: Mode=DOWN, CPU Lv=7, Mem=225MB ---
2026-05-29 15:49:36,162 [INFO] [Memory] Releasing... (-25MB) Total: 200MB
2026-05-29 15:49:36,162 [INFO] [CPU] Occupy core for 5s (Level 7)
2026-05-29 15:49:42,170 [INFO] --- Step Info: Mode=DOWN, CPU Lv=6, Mem=200MB ---
2026-05-29 15:49:42,171 [INFO] [Memory] Releasing... (-25MB) Total: 175MB
2026-05-29 15:49:42,171 [INFO] [CPU] Occupy core for 5s (Level 6)
2026-05-29 15:49:48,178 [INFO] --- Step Info: Mode=DOWN, CPU Lv=5, Mem=175MB ---
2026-05-29 15:49:48,179 [INFO] [Memory] Releasing... (-25MB) Total: 150MB
2026-05-29 15:49:48,179 [INFO] [CPU] Occupy core for 5s (Level 5)
2026-05-29 15:49:54,187 [INFO] --- Step Info: Mode=DOWN, CPU Lv=4, Mem=150MB ---
2026-05-29 15:49:54,188 [INFO] [Memory] Releasing... (-25MB) Total: 125MB
2026-05-29 15:49:54,188 [INFO] [CPU] Occupy core for 4s (Level 4)
2026-05-29 15:49:59,196 [INFO] --- Step Info: Mode=DOWN, CPU Lv=3, Mem=125MB ---
2026-05-29 15:49:59,196 [INFO] [Memory] Releasing... (-25MB) Total: 100MB
2026-05-29 15:49:59,197 [INFO] [CPU] Occupy core for 3s (Level 3)
2026-05-29 15:50:03,204 [INFO] --- Step Info: Mode=DOWN, CPU Lv=2, Mem=100MB ---
2026-05-29 15:50:03,205 [INFO] [Memory] Releasing... (-25MB) Total: 75MB
2026-05-29 15:50:03,205 [INFO] [CPU] Occupy core for 2s (Level 2)
2026-05-29 15:50:06,213 [INFO] --- Step Info: Mode=DOWN, CPU Lv=1, Mem=75MB ---
2026-05-29 15:50:06,214 [INFO] [Memory] Releasing... (-25MB) Total: 50MB
2026-05-29 15:50:06,214 [INFO] [CPU] Occupy core for 1s (Level 1)
2026-05-29 15:50:08,222 [INFO] --- Step Info: Mode=DOWN, CPU Lv=0, Mem=50MB ---
2026-05-29 15:50:08,223 [INFO] [Memory] Releasing... (-25MB) Total: 25MB
2026-05-29 15:50:09,229 [INFO] --- Step Info: Mode=DOWN, CPU Lv=0, Mem=25MB ---
2026-05-29 15:50:09,230 [INFO] [Memory] Releasing... (-25MB) Total: 0MB
# 다시 UP
2026-05-29 15:50:10,236 [INFO] >>> BOTTOM REACHED (Idle). Switching to RAMP UP. ▲ <<<
2026-05-29 15:50:10,236 [INFO] --- Step Info: Mode=UP, CPU Lv=1, Mem=0MB ---
2026-05-29 15:50:10,274 [INFO] [Memory] Increasing... (+25 MB) Total: 25 MB
2026-05-29 15:50:10,275 [INFO] [CPU] Occupy core for 1s (Level 1)

```

### 다른 터미널에서 포트 확인
```bash
agent-admin@abc123:/var/log/agent-app$ ss -tulnp | grep 15034
tcp   LISTEN 0      1            0.0.0.0:15034      0.0.0.0:*    users:(("agent-app-linux",pid=1097,fd=4))

# 결과: 0.0.0.0:15034 LISTEN
```
<br>
<br>

# 5. 모니터링 스크립트
자동으로 시스템의 상태를 체크하고 기록한다.

`수동 모니터링` 시 매 분 체크가 불가능하며, 실수하기 쉽고 기록이 없는 반면,
`자동 모니터링` 시 24/7 감시 가능하며, 휴먼에러가 없고 기록이 남아 데이터 기반 분석이 가능하다.


### monitor.sh 의 5가지 기능
1. 헬스 체크 (실패 시 종료)
    - 프로세스 : `agent-app-linux-x86` 이 실행중 인지 확인
    - 포트 : 15034 수신중 인지 확인
    
    비정상 상태에서 리포트를 만들어 내는 것보다는 바로 종료하고, 실패 로그만 남기는 쪽이 문제를 추적하기 좋다고 판단해서 `exit 1`로 끝내도록 한다.

2. 경고 체크 (경고만 출력)
    - 방화벽 활성화 상태 확인
    - 비활성 상태이거나 도구가 없으면 `[WARNING]` 만 남기고 스크립트는 계속 진행

3. 자원 수집
    - CPU 사용률(%) : `top -bn1`의 `Cpu(s)` 라인에서 idle 퍼센트를 뽑고, `100 - idle`로 사용률을 계산
    - 메모리 사용률(%) : `free` 명령의 `Mem`: 라인에서 `used/total * 100`으로 계산
    - 디스크 사용률(%) ; `df -P /`로 `루트 파티션`을 기준으로 사용률(%)을 가져옴
4. 임계값 경고
    - `CPU > 20%: [WARNING] CPU threshold exceeded`
    - `MEM > 10%: [WARNING] MEM threshold exceeded`
    - `DISK_USED > 80%: [WARNING] DISK threshold exceeded`
5. 로그 기록
    - `/var/log/agent-app/monitor.log` 에 한줄씩 누적 기록 됨
    - 포맷 : `[YYYY-MM-DD HH:MM:SS] PID:.. CPU:..% MEM:..% DISK_USED:..%`

### 스크립트 생성
- 파일 생성
    ```bash
    nano /home/agent-admin/agent-app/bin/monitor.sh
    ```

- 권한 설정
    ```bash
    # 소유자 설정
    chown agent-dev:agent-core /home/agent-admin/agent-app/bin/monitor.sh
    
    # 권한 설정
    chmod 750 /home/agent-admin/agent-app/bin/monitor.sh
    ```

### 모니터링 수동 실행 테스트
- 수동 실행
    
    `agent-admin`(일반 사용자) 실행 시 권한 에러로 방화벽 확인 불가 문제(`UFW is inactive`) 발생
    ```bash
    # ./monitor.sh 
    agent-admin@abc123:~/agent-app/bin$ ./monitor.sh 
    ERROR: You need to be root to run this script
    ====== SYSTEM MONITOR RESULT ======

    [HEALTH CHECK]
    Checking process 'agent-app-linux-x86'... [OK] (PID: 231)
    Checking port 15034... [OK]

    [RESOURCE MONITORING]
    CPU Usage : 5%
    MEM Usage : 5%
    DISK Used : 1%

    [WARNING] UFW is inactive

    [INFO] Log appended: /var/log/agent-app/monitor.log
    ```

- log 확인
    ```bash
    # ./monitor.log 
    agent-admin@abc123:/var/log/agent-app$ cat ./monitor.log 

    [2026-05-29 16:41:16] PID:231 CPU:5% MEM:5% DISK_USED:1%
    ```

- 위에서 발생한 문제(`UFW is inactive`)를 해결하기 위해 `/etc/sudoers` 에 `admin-agent`의 `User privilege` 추가
    
    
    ```bash
    # visudo 실행
    visudo

    # User privilege 에 agent-admin 이 ufw status 를 확인 할 수 있도록 추가

    # User privilege specification
    root    ALL=(ALL:ALL) ALL
    
    agent-admin ALL=(ALL) NOPASSWD: /usr/sbin/ufw status, /usr/sbin/ufw status verbose
    ```

- 방화벽 활성화 완료
    ![alt text](docs/screenshots/b1-1_agent-admin에게%20ufw%20status%20조회%20권한%20추가.png)

### `monitor.sh` 실행
- `sudoers` 에서 허용한 명령으로 정확히 호출 및 문제 해결(방화벽 활성화) 됨
    ```bash
    agent-admin@abc123:~/agent-app/bin$ ./monitor.sh

    ====== SYSTEM MONITOR RESULT ======

    [HEALTH CHECK]
    Checking process 'agent-app-linux-x86'... [OK] (PID: 806)
    Checking port 15034... [OK]

    [RESOURCE MONITORING]
    CPU Usage : 3%
    MEM Usage : 5%
    DISK Used : 1%


    [INFO] Log appended: /var/log/agent-app/monitor.log

    ```

- 방화벽 활성화 후 log 확인
    ```bash
    agent-admin@abc123:/var/log/agent-app$ cat ./monitor.log 
    [2026-05-29 16:41:16] PID:231 CPU:5% MEM:5% DISK_USED:1%
    [2026-05-29 16:53:43] PID:231 CPU:3% MEM:5% DISK_USED:1%
    [2026-05-29 17:33:59] PID:231 CPU:6% MEM:5% DISK_USED:1%
    [2026-05-29 17:34:23] PID:806 CPU:5% MEM:4% DISK_USED:1%
    [2026-05-29 17:43:50] PID:806 CPU:3% MEM:5% DISK_USED:1%
    ```
<br>
<br>

# 6. 자동 실행 설정
매분마다 자동으로 모니터링 스크립트 실행

### crontab 등록
- cron 서비스 켜져있는지 확인
    ```bash
    root@abc123:/# service cron status
    * cron is not running
    ```

- cron 서비스 시작
    ```bash
    root@abc123:/# service cron start
    * Starting periodic command scheduler cron                              [ OK ]

    # 켜졌는지 확인
    root@abc123:/# service cron status
    * cron is running
    ```
- crontab 열기
    ```bash
    su - agent-admin
    crontab -e
    
    # monitor.sh` 매분 실행 & 로그 저장하기
    # >> 추가하기, > 덮어쓰기
    
    * * * * * /home/agent-admin/agent-app/bin/monitor.sh >> /var/log/agent-app/monitor.cron.log 2>&1
    ```

### cron 잘 설정되었는지 확인
```bash
# 설정파일 확인
crontab -l

agent-admin@abc123:~$ crontab -e
no crontab for agent-admin - using an empty one
crontab: installing new crontab
agent-admin@abc123:~$ crontab -l
# Edit this file to introduce tasks to be run by cron.
# 
# Each task to run has to be defined through a single line
# indicating with different fields when the task will be run
# and what command to run for the task
# 
# To define the time you can provide concrete values for
# minute (m), hour (h), day of month (dom), month (mon),
# and day of week (dow) or use '*' in these fields (for 'any').
# 
# Notice that tasks will be started based on the cron's system
# daemon's notion of time and timezones.
# 
# Output of the crontab jobs (including errors) is sent through
# email to the user the crontab file belongs to (unless redirected).
# 
# For example, you can run a backup of all your user accounts
# at 5 a.m every week with:
# 0 5 * * 1 tar -zcf /var/backups/home.tgz /home/
# 
# For more information see the manual pages of crontab(5) and cron(8)
# 
# m h  dom mon dow   command

* * * * * /home/agent-admin/agent-app/bin/monitor.sh >> /var/log/agent-app/monitor.cron.log 2>&1
```

### 자동 실행 확인
의도대로 매분마다 로그가 쌓임

```bash
# 최근 로그 5개 확인
tail /var/log/agent-app/monitor.log
```
![alt text](docs/screenshots/b1-1_cron%20매분%20간격%20tail%20-n.png)
<br>
<br>


# 트러블 슈팅
# 1. SSH 에서 포트 변경 후 재시작이 안됨

## 문제
컨테이너 환경에서 SSH 포트 변경 후 systemd 재시작을 명령했지만, 진행되지 않음
```bash
root@abc123:/# systemctl restart ssh

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
컨테이너에서는 systemctl 대신 `SSH 데몬`을 직접 실행해야 한다.

`Ubuntu / Debian` 계열
- SSH 데몬 재실행
    ```bash
    # service ssh restart
    root@abc123:/# service ssh restart
    
    * Restarting OpenBSD Secure Shell server sshd
    ```

- 기타 방법 1. 직접 실행 방법
    ```bash
    /usr/sbin/sshd
    ```

- 기타 방법 2. 백그라운드 실행
    ```bash
    nohup /usr/sbin/sshd &
    ```

- 변경 완료 (port 가 22 -> 20022 로 변경 됨)
    ```bash
    # 방법1. netstat -nlp | grep sshd
    root@abc123:/# netstat -nlp | grep sshd

    tcp        0      0 0.0.0.0:20022           0.0.0.0:*               LISTEN      30/sshd: /usr/sbin/ 
    tcp6       0      0 :::20022                :::*                    LISTEN      30/sshd: /usr/sbin/

    # 방법2. netstat -tulnp | grep 20022
    root@abc123:/# netstat -tulnp | grep 20022

    tcp        0      0 0.0.0.0:20022           0.0.0.0:*               LISTEN      30/sshd: /usr/sbin/ 
    tcp6       0      0 :::20022                :::*                    LISTEN      30/sshd: /usr/sbin/ 
    ```
<br>
<br>

# 트러블 슈팅
# 2. sudo / root 권한이 필요한 작업 수행 문제

## 문제
미션을 수행하는 과정에서 `sudo` 또는 `root` 권한이 필요한 작업이 여러 번 발생했다. 대표적으로 SSH 설정 변경, 방화벽(UFW) 활성화, 계정/그룹 생성, 시스템 디렉토리 권한 설정 같은 작업은 일반 사용자 권한만으로 수행하기 어렵다.

하지만 교육장 실습 환경에는 다음과 같은 제약이 있었다.
- iMac 호스트 환경에서 프로그램 설치가 불가능했다.
- 호스트 터미널 계정은 sudoers에 포함되어 있지 않아 `sudo` 명령을 사용할 수 없었다.
- 이를 우회하기 위해 Docker 컨테이너를 생성해 내부에서 작업을 진행했지만, 컨테이너 기본 권한만으로는 방화벽 설정이 정상 동작하지 않았다.

## 원인
Docker 컨테이너 내부의 root 사용자는 호스트 운영체제의 진짜 root와 다르다. 컨테이너 안에서 root 프롬프트를 사용하더라도, 호스트 커널의 네트워크 필터링 기능(iptables/nftables)을 직접 제어할 권한은 기본적으로 제한된다.

`UFW`는 내부적으로 `iptables` 계열 명령을 사용해 방화벽 규칙을 적용한다. 따라서 일반적인 Docker 컨테이너에서는 네트워크 관리 capability가 없기 때문에 ufw enable 실행 시 `Permission denied` 또는 `problem running ufw-init` 같은 오류가 발생한다.

## 해결
방법 1. Docker 컨테이너 생성 시 NET_ADMIN 권한 추가

컨테이너를 생성할 때 `--cap-add=NET_ADMIN` 옵션을 추가하면 네트워크 관리 capability가 부여되어, 컨테이너 내부에서도 UFW 또는 iptables 기반 명령이 동작할 수 있다.

예시:

```bash
docker run -it --name mission-b1-1 --cap-add=NET_ADMIN ubuntu:latest /bin/bash
```

이 방식은 필요한 네트워크 권한만 추가하는 방법이라, `--privileged`보다 범위를 좁게 제어할 수 있다는 장점이 있다.

방법 2. `OrbStack` 등 가상화 환경에서 작업

OrbStack, VM, 또는 별도의 Ubuntu 실습 환경처럼 사용자가 root 권한을 직접 제어할 수 있는 가상화 환경에서는 방화벽 설정, 계정 생성, 시스템 디렉토리 권한 변경 같은 작업을 더 자연스럽게 수행할 수 있다.

특히 이번 미션은 “Ubuntu 22.04 LTS 또는 동등 리눅스 환경”을 전제로 하고 있으므로, 컨테이너/VM을 하나의 독립된 리눅스 서버처럼 구성해 실습하는 방식이 과제 의도와도 잘 맞는다. 
