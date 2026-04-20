# 0. 프로젝트 개요

## 1) 뭘 배우나요?
###  개발 환경 학습 및 세팅
- 로컬 개발 환경 세팅
- 재현 가능한 실행 환경 공유
- 협업 기반 소스코드 관리

## 2) 어떤 Tool 을 사용 하나요?
###  CLI (terminal)

- 작업 디렉토리
- 권한

### Docker

- 설치 및 점검
- 컨테이너 실행 및 관리
- 포트 매핑
- 바인드 마운트/볼륨 으로 `변경 반영`과 `데이터 영속성` 검증

### Git / GitHub

- 협업기반 소스코드 관리


<br>
<br>
<br>


# 1. 실행 환경

### OS: macOS 15.7.4

``` bash
# sw_vers

$ c08022220523@c6r7s8 Codyssey % sw_vers
ProductName:            macOS
ProductVersion:         15.7.4
BuildVersion:           24G517
```

### Shell: bash

``` bash
# bash

$ c08022220523@c6r7s8 Codyssey % bash --version
GNU bash, version 3.2.57(1)-release (x86_64-apple-darwin24)
Copyright (C) 2007 Free Software Foundation, Inc.
```

### Docker: 28.5.2

``` bash
# docker --version

$ c08022220523@c6r7s8 Codyssey % docker --version
Docker version 28.5.2, build ecc6942
```

### git: 2.53.0

``` bash
# git --version

$ c08022220523@c6r7s8 Codyssey % git --version
git version 2.53.0
```

<br>
<br>
<br>

# 2. 수행 항목 체크리스트

- [x] 터미널 기본 조작 및 폴더 구성
- [x] 권한 변경 실습
- [x] Docker 설치/점검
- [x] hello-world 실행
- [x] Dockerfile 빌드/실행
- [x] 포트 매핑 접속(2회)
- [x] 바인드 마운트 반영
- [x] 볼륨 영속성
- [x] Git 설정 + VSCode GitHub 연동

<br>
<br>
<br>

# 3. 수행 로그

## 3-1) 터미널 조작 로그

### 현재 위치 확인

``` bash $
# pwd

$ c08022220523@c6r7s8 Codyssey % pwd
/Users/08022220523/Documents/Codyssey
```

### 목록 확인(숨김 파일 포함)

``` bash $
# ls -a

$ c08022220523@c6r7s8 Desktop % ls -a
.  ..  .DS_Store .localized
```

### 이동

``` bash $
# cd

$ c08022220523@c6r7s8 Desktop % cd testDir
```

### 생성

``` bash $
# touch test.txt

$ c08022220523@c6r7s8 Desktop % touch test.txt

$ c08022220523@c6r7s8 Desktop % ls
test.txt
```

### 복사

``` bash $
# cp <기존 파일명> <복사할 위치/파일명>

$ c08022220523@c6r7s8 Desktop % cp test.txt test-copy.txt

$ c08022220523@c6r7s8 Desktop % ls
test-copy.txt test.txt testDir
```

### 이동/이름변경

``` bash $
# mv <기존 파일명> <변경/이동할 파일명>

$ c08022220523@c6r7s8 Desktop % mv test-copy.txt test-new.txt

$ c08022220523@c6r7s8 Desktop % ls
test-new.txt test.txt testDir
```

### 삭제

``` bash $
# rm

$ c08022220523@c6r7s8 Desktop % rm test-new.txt

$ c08022220523@c6r7s8 Desktop % ls
test.txt testDir
```

### 파일 내용 확인

``` bash $
# cat

$ c08022220523@c6r7s8 Desktop % cat test.txt
test 파일의 내용 입니다.
```

### 빈 파일 생성

``` bash $
# touch

$ c08022220523@c6r7s8 Desktop % touch emptyfile.txt

$ c08022220523@c6r7s8 Desktop % ls
emptyfile.txt test.txt testDir

$ c08022220523@c6r7s8 Desktop % cat emptyfile.txt
# 출력 없음 (빈 파일)

```

## 3-2) 권한 실습 및 증거 기록

### 권한 확인

``` bash $
# 권한 확인 (변경 전)
$ c08022220523@c6r7s8 Desktop % ls -al
  total 16
  drwx------+  6 c08022220523  c08022220523   192  4 18 16:02 .
  drwxr-x---+ 20 c08022220523  c08022220523   640  4 18 15:58 ..
  -rw-r--r--@  1 c08022220523  c08022220523  6148  4 18 15:59 .DS_Store
  -rw-r--r--   1 c08022220523  c08022220523     0  4  1 18:01 .localized
  -rw-r--r--   1 c08022220523  c08022220523     0  4 18 15:59 test.txt
  drwxr-xr-x   2 c08022220523  c08022220523    64  4 18 16:02 testDir
```

### 권한 변경

``` bash $
# 소유자에게 실행 권한 추가
$ c08022220523@c6r7s8 Desktop % chmod u+x test.txt

# 기타사용자에게 실행 권한 제거
$ c08022220523@c6r7s8 Desktop % chmod o-x testDir

# 권한 확인 (변경 후)
$ c08022220523@c6r7s8 Desktop % ls -al           
total 16
drwx------+  6 c08022220523  c08022220523   192  4 18 16:02 .
drwxr-x---+ 20 c08022220523  c08022220523   640  4 18 15:58 ..
-rw-r--r--@  1 c08022220523  c08022220523  6148  4 18 15:59 .DS_Store
-rw-r--r--   1 c08022220523  c08022220523     0  4  1 18:01 .localized
-rwxr--r--   1 c08022220523  c08022220523     0  4 18 15:59 test.txt
drwxr-xr--   2 c08022220523  c08022220523    64  4 18 16:02 testDir
```

## 3-3) Docker 설치 및 기본 점검

### Docker 버전 확인 결과

``` bash $
# docker --version

$ c08022220523@c6r7s8 Codyssey % docker --version
Docker version 28.5.2, build ecc6942
```

### Docker 데몬 동작 여부 확인 결과를 기록

``` bash $
# docker info

$ c08022220523@c6r7s8 Desktop % docker info
Client:
Version:    28.5.2
Context:    orbstack
Debug Mode: false
Plugins:
buildx: Docker Buildx (Docker Inc.)
    Version:  v0.29.1
    Path: /Users/08022220523/.docker/cli-plugins/docker-buildx
    compose: Docker Compose (Docker Inc.)
    Version:  v2.40.3
    Path:     /Users/08022220523/.docker/cli-plugins/docker-compose
....
```
<details>
    <summary>docker info-logs</summary>

    Client:
        Version:    28.5.2
        Context:    orbstack
        Debug Mode: false
        Plugins:
        buildx: Docker Buildx (Docker Inc.)
            Version:  v0.29.1
            Path:     /Users/08022220523/.docker/cli-plugins/docker-buildx
        compose: Docker Compose (Docker Inc.)
            Version:  v2.40.3
            Path:     /Users/08022220523/.docker/cli-plugins/docker-compose

        Server:
         Containers: 5
             Running: 1
             Paused: 0
             Stopped: 4
         Images: 4
     Server Version: 28.5.2
     Storage Driver: overlay2
         Backing Filesystem: btrfs
         Supports d_type: true
         Using metacopy: false
         Native Overlay Diff: true
         userxattr: false
     Logging Driver: json-file
     Cgroup Driver: cgroupfs
     Cgroup Version: 2
     Plugins:
         Volume: local
         Network: bridge host ipvlan macvlan null overlay
         Log: awslogs fluentd gcplogs gelf journald json-file local splunk syslog
         CDI spec directories:
         /etc/cdi
         /var/run/cdi
     Swarm: inactive
     Runtimes: io.containerd.runc.v2 runc
     Default Runtime: runc
     Init Binary: docker-init
     containerd version: 1c4457e00facac03ce1d75f7b6777a7a851e5c41
     runc version: d842d7719497cc3b774fd71620278ac9e17710e0
     init version: de40ad0
     Security Options:
         seccomp
             Profile: builtin
         cgroupns
     Kernel Version: 6.17.8-orbstack-00308-g8f9c941121b1
     Operating System: OrbStack
     OSType: linux
     Architecture: x86_64
     CPUs: 6
     Total Memory: 15.67GiB
     Name: orbstack
     ID: 3bdf0073-f402-4564-bc91-3d5b19b82bd9
     Docker Root Dir: /var/lib/docker
     Debug Mode: false
     Experimental: false
     Insecure Registries:
         ::1/128
         127.0.0.0/8
     Live Restore Enabled: false
     Product License: Community Engine
     Default Address Pools:
         Base: 192.168.97.0/24, Size: 24
         Base: 192.168.107.0/24, Size: 24
         Base: 192.168.117.0/24, Size: 24
         Base: 192.168.147.0/24, Size: 24
         Base: 192.168.148.0/24, Size: 24
         Base: 192.168.155.0/24, Size: 24
         Base: 192.168.156.0/24, Size: 24
         Base: 192.168.158.0/24, Size: 24
         Base: 192.168.163.0/24, Size: 24
         Base: 192.168.164.0/24, Size: 24
         Base: 192.168.165.0/24, Size: 24
         Base: 192.168.166.0/24, Size: 24
         Base: 192.168.167.0/24, Size: 24
         Base: 192.168.171.0/24, Size: 24
         Base: 192.168.172.0/24, Size: 24
         Base: 192.168.181.0/24, Size: 24
         Base: 192.168.183.0/24, Size: 24
         Base: 192.168.186.0/24, Size: 24
         Base: 192.168.207.0/24, Size: 24
         Base: 192.168.214.0/24, Size: 24
         Base: 192.168.215.0/24, Size: 24
         Base: 192.168.216.0/24, Size: 24
         Base: 192.168.223.0/24, Size: 24
         Base: 192.168.227.0/24, Size: 24
         Base: 192.168.228.0/24, Size: 24
         Base: 192.168.229.0/24, Size: 24
         Base: 192.168.237.0/24, Size: 24
         Base: 192.168.239.0/24, Size: 24
         Base: 192.168.242.0/24, Size: 24
         Base: 192.168.247.0/24, Size: 24
         Base: fd07:b51a:cc66:d000::/56, Size: 64

     WARNING: DOCKER_INSECURE_NO_IPTABLES_RAW is set
</details>

## 3-4) Docker 기본 운영 명령 수행
### 이미지: 다운로드/목록 확인

``` bash $
# docker images

$ c08022220523@c6r7s8 Desktop % docker images
REPOSITORY   TAG       IMAGE ID   CREATED   SIZE
```

### 컨테이너: 실행/중지/목록 확인

``` bash $
# docker ps

$ c08022220523@c6r7s8 Codyssey % docker ps
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```

``` bash $
# docker ps -a

$ c08022220523@c6r7s8 Desktop % docker ps -a
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```


### 운영: 로그 확인, 리소스 확인

``` bash $
# docker logs
$ c08022220523@c6r7s8 mission1 % docker logs custom-nginx-container
```

<details>
    <summary>docker logs</summary>
    
    /docker-entrypoint.sh: /docker-entrypoint.d/ is not empty, will attempt to perform configuration
    /docker-entrypoint.sh: Looking for shell scripts in /docker-entrypoint.d/
    /docker-entrypoint.sh: Launching /docker-entrypoint.d/10-listen-on-ipv6-by-default.sh
    10-listen-on-ipv6-by-default.sh: info: Getting the checksum of /etc/nginx/conf.d/default.conf
    10-listen-on-ipv6-by-default.sh: info: Enabled listen on IPv6 in /etc/nginx/conf.d/default.conf
    /docker-entrypoint.sh: Sourcing /docker-entrypoint.d/15-local-resolvers.envsh
    /docker-entrypoint.sh: Launching /docker-entrypoint.d/20-envsubst-on-templates.sh
    /docker-entrypoint.sh: Launching /docker-entrypoint.d/30-tune-worker-processes.sh
    /docker-entrypoint.sh: Configuration complete; ready for start up
    2026/04/18 08:34:06 [notice] 1#1: using the "epoll" event method
    2026/04/18 08:34:06 [notice] 1#1: nginx/1.29.8
    2026/04/18 08:34:06 [notice] 1#1: built by gcc 14.2.0 (Debian 14.2.0-19)
    2026/04/18 08:34:06 [notice] 1#1: OS: Linux 6.17.8-orbstack-00308-g8f9c941121b1
    2026/04/18 08:34:06 [notice] 1#1: getrlimit(RLIMIT_NOFILE): 20480:1048576
    2026/04/18 08:34:06 [notice] 1#1: start worker processes
    2026/04/18 08:34:06 [notice] 1#1: start worker process 29
    2026/04/18 08:34:06 [notice] 1#1: start worker process 30
    2026/04/18 08:34:06 [notice] 1#1: start worker process 31
    2026/04/18 08:34:06 [notice] 1#1: start worker process 32
    2026/04/18 08:34:06 [notice] 1#1: start worker process 33
    2026/04/18 08:34:06 [notice] 1#1: start worker process 34
    192.168.215.1 - - [18/Apr/2026:08:34:20 +0000] "GET / HTTP/1.1" 200 258 "-" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.6 Safari/605.1.15" "-"
    2026/04/18 08:34:20 [error] 29#29: *1 open() "/usr/share/nginx/html/favicon.ico" failed (2: No such file or directory), client: 192.168.215.1, server: localhost, request: "GET /favicon.ico HTTP/1.1", host: "localhost:8080", referrer: "http://localhost:8080/"
    192.168.215.1 - - [18/Apr/2026:08:34:20 +0000] "GET /favicon.ico HTTP/1.1" 404 153 "http://localhost:8080/" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.6 Safari/605.1.15" "-"
    192.168.215.1 - - [18/Apr/2026:11:09:53 +0000] "GET / HTTP/1.1" 200 258 "-" "curl/8.7.1" "-"
    192.168.215.1 - - [18/Apr/2026:11:31:01 +0000] "GET / HTTP/1.1" 304 0 "-" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.6 Safari/605.1.15" "-"
</details>



``` bash $
# docker stats

$ c08022220523@c6r7s8 mission1 % docker stats
CONTAINER ID   NAME                     CPU %     MEM USAGE / LIMIT    MEM %     NET I/O           BLOCK I/O         PIDS 
4e85902eda75   custom-nginx-container   0.00%     5.18MiB / 15.67GiB   0.03%     4.51kB / 2.87kB   27.8MB / 8.19kB   7 

```

### 3-5) Dockerfile 기반 웹 서버 컨테이너

### hello-world 실행 성공을 기록한다.

``` bash $
# docker run hello-world
$ c08022220523@c6r7s8 Desktop % docker run hello-world
```
<details>
    <summary>hello-world 실행</summary>
    
    Unable to find image 'hello-world:latest' locally
    latest: Pulling from library/hello-world
    4f55086f7dd0: Pull complete 
    Digest: sha256:f9078146db2e05e794366b1bfe584a14ea6317f44027d10ef7dad65279026885
    Status: Downloaded newer image for hello-world:latest

    Hello from Docker!
    This message shows that your installation appears to be working correctly.

    To generate this message, Docker took the following steps:
    1. The Docker client contacted the Docker daemon.
    2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
        (amd64)
    3. The Docker daemon created a new container from that image which runs the
        executable that produces the output you are currently reading.
    4. The Docker daemon streamed that output to the Docker client, which sent it
        to your terminal.

    To try something more ambitious, you can run an Ubuntu container with:
    $ docker run -it ubuntu bash

    Share images, automate workflows, and more with a free Docker ID:
    https://hub.docker.com/

    For more examples and ideas, visit:
    https://docs.docker.com/get-started/
</details>

```
# docker ps -a
$ c08022220523@c6r7s8 Desktop % docker ps -a

CONTAINER ID   IMAGE         COMMAND    CREATED          STATUS                      PORTS     NAMES
c995dfea2517   hello-world   "/hello"   13 seconds ago   Exited (0) 12 seconds ago             recursing_leavitt
```

### ubuntu 컨테이너를 실행하고 내부 진입 후 간단 명령(예: ls, echo) 수행 결과를 기록한다.

``` bash $
# docker run ubuntu
$ c08022220523@c6r7s8 Desktop % docker run ubuntu

Unable to find image 'ubuntu:latest' locally
latest: Pulling from library/ubuntu
b40150c1c271: Pull complete 
Digest: sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b
Status: Downloaded newer image for ubuntu:latest

#docker ps -a
$ c08022220523@c6r7s8 Desktop % docker ps -a

CONTAINER ID   IMAGE         COMMAND       CREATED         STATUS                     PORTS     NAMES
a3cc35a72b5e   ubuntu        "/bin/bash"   9 seconds ago   Exited (0) 8 seconds ago             wonderful_hugle
c995dfea2517   hello-world   "/hello"      2 minutes ago   Exited (0) 2 minutes ago             recursing_leavitt

# ubuntu 내부 진입
$ c08022220523@c6r7s8 Desktop % docker run -it ubuntu

# ubuntu 내부 - 명령어 ls
$ root@8458d01297f3:/# ls
bin   dev  home  lib64  mnt  proc  run   srv  tmp  var
boot  etc  lib   media  opt  root  sbin  sys  usr

# ubuntu 내부 - 명령어 echo
$ root@8458d01297f3:/# echo "hi"
hi
```


### 컨테이너 종료/유지(attach/exec 등)의 차이를 스스로 관찰하고 간단히 정리한다.

``` bash $
# 컨테이너는 호스트 쉘에서 다루거나, 컨테이너 내부로 진입해서 다룬다. 이를 나눠서 설명하겠다.

# 1. 컨테이너 내부
$ docker run -it ubuntu bash

# 1-1. 컨테이너 유지 (detach)
# Ctrl + P, 바로 이어서 Q

# 1-2. 컨테이너 종료
$ exit # 또는 Ctrl + D (컨테이너 프로세스 종료, 상태 Exited)


# 2. 호스트 쉘
# 2-1. 컨테이너 정상 종료 (유지 가능)
$ docker stop <컨테이너 이름> # SIGTERM 으로 안전하게 종료, 상태 Exited, 이후 docker start로 재실행 가능

## 백그라운드로 실행 예시
$ docker run -d --name my-nginx nginx 

# 2-2. 컨테이너 강제 종료
$ docker kill <컨테이너 이름> # SIGKILL, 강제 종료


```

### 3-6) 기존 Dockerfile 기반 커스텀 이미지 제작

### 어떤 “기존 베이스(이미지/예시 Dockerfile)”를 선택했는지
  - (A) 웹 서버 베이스 이미지 활용(`NGINX`) + 정적 콘텐츠/설정만 교체
### 내가 적용한 커스텀 포인트 각각의 목적
  - `FROM nginx:latest`  
    - 검증된 공식 `NGINX 이미지`를 기반으로 사용하여, 기본 웹 서버 기능을 그대로 활용한다.
  - `COPY index.html /usr/share/nginx/html/index.html`  
    - 기본 NGINX 환영 페이지 대신, 내가 작성한 정적 HTML 페이지를 제공하기 위해 index.html을 교체한다.
  - `LABEL maintainer`, `LABEL description`  
    - 이미지 메타데이터를 추가해 이미지의 목적과 작성자를 식별하기 쉽게 한다.
- 핵심 결과(출력/스크린샷)
    - ![alt text](../mission1/dockerfile custom image.png)
### 빌드/실행 명령
```bash
# docker build
$ c08022220523@c6r7s8 mission1 % docker build -t custom-nginx:v1 .
```

<details>
    <summary>docker build - console log</summary>
        
    [+] Building 8.4s (7/7) FINISHED                                docker:orbstack
    => [internal] load build definition from Dockerfile                       0.2s
    => => transferring dockerfile: 176B                                       0.0s
    => [internal] load metadata for docker.io/library/nginx:latest            2.8s
    => [internal] load .dockerignore                                          0.1s
    => => transferring context: 2B                                            0.0s
    => [internal] load build context                                          0.2s
    => => transferring context: 297B                                          0.0s
    => [1/2] FROM docker.io/library/nginx:latest@sha256:7f0adca1fc6c29c8dc49  4.4s
    => => resolve docker.io/library/nginx:latest@sha256:7f0adca1fc6c29c8dc49  0.2s
    => => sha256:7f0adca1fc6c29c8dc49a2e90037a10ba20dc266b 10.23kB / 10.23kB  0.0s
    => => sha256:f1e4ce3095f46ab65fd053991508a2433e2d7b45f6d 2.29kB / 2.29kB  0.0s
    => => sha256:a716c9c12c382ab51a71127f1dd9440af118939b92a 9.09kB / 9.09kB  0.0s
    => => sha256:5435b2dcdf5cb7faa0d5b1d4d54be2c72a776fab9 29.78MB / 29.78MB  0.9s
    => => sha256:054715a6bffa715b31d05aa5cf6aac8423bd97a19 33.16MB / 33.16MB  1.3s
    => => sha256:88d1d984b765ca06bdffb2c450ede950034501dad795362 628B / 628B  1.0s
    => => extracting sha256:5435b2dcdf5cb7faa0d5b1d4d54be2c72a776fab9a605336  1.1s
    => => sha256:84e114c2bb367b07ccb9aff4dbc37d7a0f119884219f2ef 404B / 404B  1.5s
    => => sha256:4a038fd18db12b39452e6f5f883577e987b3ff96e8e5553 955B / 955B  1.4s
    => => sha256:7b5d674621c2c637ede5eb94b8ac1a844d84d9231ae 1.21kB / 1.21kB  1.8s
    => => sha256:448ea5cac5d5181193a0d6e6106ea1673e3713f929b 1.40kB / 1.40kB  1.9s
    => => extracting sha256:054715a6bffa715b31d05aa5cf6aac8423bd97a1981d1d69  0.7s
    => => extracting sha256:88d1d984b765ca06bdffb2c450ede950034501dad7953624  0.0s
    => => extracting sha256:4a038fd18db12b39452e6f5f883577e987b3ff96e8e55537  0.0s
    => => extracting sha256:84e114c2bb367b07ccb9aff4dbc37d7a0f119884219f2efc  0.0s
    => => extracting sha256:7b5d674621c2c637ede5eb94b8ac1a844d84d9231ae61df7  0.0s
    => => extracting sha256:448ea5cac5d5181193a0d6e6106ea1673e3713f929b4bb91  0.0s
    => [2/2] COPY index.html /usr/share/nginx/html/index.html                 0.4s
    => exporting to image                                                     0.2s
    => => exporting layers                                                    0.1s
    => => writing image sha256:b3c704709af4b3c425eda65875704687ce9587fa281ba  0.0s
    => => naming to docker.io/library/custom-nginx:v1                         0.0s
</details>

``` bash
# docker run
$ c08022220523@c6r7s8 mission1 % docker run -d --name custom-nginx-container -p 8080:80 custom-nginx:v1
4e85902eda758b756713ee26c966d3807cfbd1ad1278bf8a9f0735da147602cf
```

``` bash
# docker ps
$ c08022220523@c6r7s8 mission1 % docker ps
CONTAINER ID   IMAGE             COMMAND                   CREATED         STATUS         PORTS                                     NAMES
4e85902eda75   custom-nginx:v1   "/docker-entrypoint.…"   4 seconds ago   Up 3 seconds   0.0.0.0:8080->80/tcp, [::]:8080->80/tcp   custom-nginx-container
```

      

## 3-7) 포트 매핑 및 접속 증거
### 포트 매핑
```bash
# 1. docker build (이미 custom image 제작 시 수행함)
$ docker build -t custom-nginx:v1 .

# 2. 컨테이너 실행 + 포트 매핑
#   - -d                        : 백그라운드(detach) 모드로 실행
#   - -p 8080:80                : 호스트 8080 포트 -> 컨테이너 80 (nginx) 포트로 포워딩
#   - --name custom-nginx-container : 컨테이너 이름을 지정
#   - custom-nginx:v1           : 위에서 빌드한 커스텀 nginx 이미지 사용
$ docker run -d -p 8080:80 --name custom-nginx-container custom-nginx:v1
```

### 서버 응답 확인 (curl http://localhost:8080)
- curl : client url (브라우저를 켜지않고도 cli로 html이나 데이터 내용을 확인 할 수 있음)
    
- 아래 주소로 접속하면 컨테이너의 80번 포트(nginx)로 요청이 전달됨

``` bash
$ c08022220523@c6r7s8 mission1 % curl http://localhost:8080
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <title>Custom Nginx Image</title>
</head>
<body>
    <h1>Hello from Custom Docker Image</h1>
    <p>기존 nginx 이미지를 기반으로 만든 커스텀 이미지입니다.</p>
</body>
</html>%
```

## 3-8) Docker 바인드 마운트 반영 & 볼륨 영속성 검증
### 바인드 마운트 반영 (실시간 코드 수정 확인)
- 로컬 호스트의 소스 코드를 컨테이너 내부로 직접 연결하여, 별도의 빌드 과정 없이 변경 사항이 즉시 반영되는지 검증합니다.
``` bash
# 1. 로컬에 테스트용 HTML 파일 생성
$ echo "<h1>바인드 마운트 확인용 파일</h1>" > $(pwd)/index.html

# 2. 바인드 마운트를 사용하여 컨테이너 실행 (로컬의 index.html 파일을 nginx 기본경로에 연결, 외부 8081 포트로 매핑)
$ docker run -d --name bind-test -p 8081:80 -v $(pwd)/index.html:/usr/share/nginx/html/index.html nginx

# 3. docker ps
$ c08022220523@c6r7s8 mission1 % docker ps
CONTAINER ID   IMAGE     COMMAND                   CREATED              STATUS              PORTS                                     NAMES
2ffecabe8973   nginx     "/docker-entrypoint.…"   About a minute ago   Up About a minute   0.0.0.0:8081->80/tcp, [::]:8081->80/tcp   bind-test

# 4. 초기 응답 확인 (curl)
$ c08022220523@c6r7s8 mission1 % curl http://localhost:8081
<h1>바인드 마운트 확인용 파일</h1>

# 5. 로컬에서 파일 내용 수정 (컨테이너 재시작 없음)
$ echo "<h1>바인드 마운트 확인용-수정되었습니다.</h1>" > $(pwd)/index.html

# 6. 변경 사항 즉시 반영 확인 (curl) 별도의 docker build나 restart 없이도 내용이 바뀐 것을 확인할 수 있다.
$ c08022220523@c6r7s8 mission1 % curl http://localhost:8081
<h1>바인드 마운트 확인용-수정되었습니다.</h1>
```
### 볼륨 영속성 검증 (컨테이너가 사라져도 데이터는 남음)
``` bash
# 1. 볼륨 생성 (데이터 저장용도)
$ docker volume create mydata

# 2. 컨테이너-1 실행
## 내가 만든 mydata 볼륨과 컨테이너의 /data 폴더와 마운트
## sleep infinity : ubuntu같은 이미지는 실행할 명령이 없으면 바로 종료되기 때문에, 꺼지지 않게 무한대기 시킴

$ docker run -d --name vol-test -v mydata:/data ubuntu sleep infinity

# 3. 컨테이너-1 안에서 볼륨에 데이터 쓰기/읽기
## exec : 이미 실행중인 컨테이너에 들어가서 추가 명령을 내릴 때 사용
## -it : 터미널 대화하듯 명령을 주고받음
$ docker exec -it vol-test bash -lc "echo hi > /data/hello.txt && cat /data/hello.txt"
hi

# 4. 컨테이너-1 삭제 (볼륨은 그대로 남아 있음)
$ docker rm -f vol-test

# 5. 컨테이너-2 실행 (같은 볼륨 재사용)
$ docker run -d --name vol-test2 -v mydata:/data ubuntu sleep infinity

# 6. 컨테이너-2 안에서 만든 hello.txt 확인
$ docker exec -it vol-test2 bash -lc "cat /data/hello.txt"
hi
```

## 3-9) Git 설정 및 GitHub 연동
- Git 의 설정 상태를 확인
``` bash
# git congif --list

$ c08022220523@c6r7s8 Codyssey % git config --list
# macOS의 키체인 기능을 통해 깃허브 비밀번호, 토큰을 매번 입력하지않게 설정함
credential.helper=osxkeychain
user.name=0802222
user.email=0802222@naver.com
core.repositoryformatversion=0
core.filemode=true
core.bare=false
core.logallrefupdates=true
core.ignorecase=true
core.precomposeunicode=true

# 어떤 저장소와 연결되어 있는지
remote.origin.url=http://github.com/0802222/Codyssey.git
remote.origin.fetch=+refs/heads/*:refs/remotes/origin/*
branch.main.remote=origin
branch.main.merge=refs/heads/main
branch.mission1.vscode-merge-base=origin/main
branch.mission1.remote=origin
branch.mission1.merge=refs/heads/mission1
```

## 3-10) 보안 및 개인정보
  ### [x] 토큰, 비밀번호, 개인키, 인증코드 등이 포함되지 않도록 마스킹한다.

<br>
<br>
<br>

# 4. 트러블 슈팅 
(문제 -> 원인 가설 -> 확인 -> 해결/대안)

## 4-1) 트러블 슈팅_1

### 문제

``` text

```

### 원인 가설

``` text

```

### 확인

``` text

```

### 해결 / 대안

``` text

```

## 4-2) 트러블 슈팅_2

### 문제

``` text

```

### 원인 가설

``` text

```

### 확인

``` text

```

### 해결 / 대안

``` text

```

<br>
<br>
<br>

# 5. 보너스 과제

## 5-1) Docker Compose 기초

- docker-compose.yml의 기본 구조를 학습하고, 단일 서비스를 Compose로 실행한다.
- 배움 포인트: 컨테이너 실행 명령이 “문서화된 실행 설정”으로 바뀌는 이유

## 5-2) Docker Compose 멀티 컨테이너

- 웹 서버 + (임의의 보조 서비스) 2개 이상을 Compose로 함께 실행한다.
- 컨테이너 간 네트워크 통신이 가능한지 확인한다.
- 배움 포인트: 네트워크/서비스 디스커버리 개념 맛보기

## 5-3) Compose 운영 명령어 습득

- up, down, ps, logs를 사용해 실행/종료/상태/로그를 관리한다.
- 배움 포인트: 운영 관점의 “상태 확인 루틴” 만들기

## 5-4) 환경 변수 활용

- Dockerfile 또는 Compose에서 환경 변수를 주입해 서버 포트/모드를 바꿔본다.
- 배움 포인트: 설정과 코드의 분리

## 5-5) GitHub SSH 키 설정

- HTTPS 대신 SSH로 푸시가 가능하도록 키를 등록하고 동작을 확인한다.
- 배움 포인트: 인증 방식 차이와 보안 습관
