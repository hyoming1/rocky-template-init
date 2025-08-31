#!/bin/bash

FLAG="/tmp/template_reboot_done"

# -----------------------------
# 재부팅 전 작업
# -----------------------------
if [ ! -f $FLAG ]; then
    # 1. 필요한 패키지 설치
    # - bash-completion: 자동완성
    # - epel-release: 추가 패키지 저장소
    # - qemu-guest-agent: VM 상태 통신용
    # - cloud-init: VM 초기화 자동화
    dnf install -y bash-completion epel-release qemu-guest-agent cloud-init

    # 2. QEMU Guest Agent 활성화
    systemctl enable qemu-guest-agent

    # 3. 방화벽 삭제
    dnf remove -y firewalld

    # 4. 시스템 패키지 최신화
    dnf update -y

    # 재부팅 플래그 생성 후 재부팅
    touch $FLAG
    reboot

# -----------------------------
# 재부팅 후 작업
# -----------------------------
else
    # 1. 이전 커널 제거
    dnf remove -y $(dnf repoquery --installonly --latest-limit=-1 -q)

    # 2. 고유 머신 ID 초기화
    rm -f /etc/machine-id && touch /etc/machine-id

    # 3. SSH 호스트 키 삭제
    rm -f /etc/ssh/ssh_host_*

    # 4. DNF 캐시 정리
    dnf clean all
    
    # 5. Cloud-init 초기화
    cloud-init clean --logs
    rm -rf /var/lib/cloud/*
     
    # 6. 저널 로그 전체 삭제 (완전 초기화)
    rm -rf /var/log/journal/*

    # 7. 임시파일 정리
    rm -rf /tmp/* /var/tmp/*

    # 8. 네트워크 정보 삭제
    rm -f /etc/NetworkManager/system-connections/*

    # 9. root 계정 비활성화
    passwd -l root
    
    # 10. 셸 히스토리 초기화
    cat /dev/null > ~/.bash_history
    history -c

    # 11. 재부팅 플래그 제거
    rm -f $FLAG

    # 12. 스크립트 자체 삭제
    rm -- "$0"

    # 13. 시스템 종료
    poweroff
fi
