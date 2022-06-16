## 쿠버네티스 인증

1. X.509 Client Certs: X.509 인증서를 이용한 상호 TLS 인증
2. HTTP Authentication: HTTP Authentication을 이용한 사용자 인증
3. OpenID Connect: Google OAuth와 같은 인증 provider를 이용한 인증
4. Webhook 인증: Webhook 인증서버를 통한 사용자 인증
5. Proxy Auth: Proxy 서버를 통한 대리 인증

### 쿠버네티스 접근제어 체계

![ex_screenshot](../접근제어체계_01.png)

* Authentication: 접속한 사람의 신분을 시스템이 인증하는 단계입니다. (신분증 확인)
* Authorization: 누가 어떤 권한을 가지고 어떤 행동을 할 수 있는지 확인하는 단계입니다. (view권한, create권한 등)
* Admission Control: 인증과 권한확인 이후에 추가적으로 요청 내용에 대한 검증이나 요청 내용을 강제로 변경할 때 사용합니다.

### 쿠버네티스 유저 저장소 부재

* 쿠버네티스에서는 내부적으로 유저 인증 정보를 저장하지 않음.
* 각 인증 시스템에서 제공해주는 신원 확인 기능을 활용하여 사용자 인증 및 인식
* 외부 시스템에 의존 (X.509, HTTP Auth, Proxy Authentication 등)

### 쿠버네티스 그룹

* 실제로 그룹이라는 리소스가 존재하진 않음
* RoleBinding 또는 ClusterRoleBinding 리소스 내부에서 string match로 그룹에 따른 권한 부여 가능

  * system:autheniticated : 사용자 인증을 통과한 그룹
  * system:anonymous : 사용자 인증을 하지 않은 익명 그룹
  * system:masters : 쿠버네티스의 전체 접근 권한을 가진 그룹 (admin)