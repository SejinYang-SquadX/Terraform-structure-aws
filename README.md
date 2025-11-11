# Terraform VPC 모듈 구성 안내

## 1. 명령어 정리

- `terraform fmt -recursive` : 전체 디렉터리의 HCL 포맷을 자동 정렬합니다.
- `terraform init` : 필요한 플러그인과 모듈을 다운로드하여 작업 디렉터리를 초기화합니다.
- `terraform validate` : 현재 설정이 문법적으로 유효한지 검사합니다.
- `terraform plan [-var-file=<path>]` : 실제 적용 전에 생성/수정/삭제될 리소스를 미리 확인합니다. 환경별 tfvars 파일을 전달해 변수를 덮어쓸 수 있습니다.
- `terraform apply [-var-file=<path>]` : 계획된 변경 사항을 실제 AWS에 반영합니다. 실행 중 출력되는 plan을 확인 후 `yes`로 승인합니다.
- `terraform destroy [-var-file=<path>]` : 동일한 변수 구성을 사용해 생성된 리소스를 한 번에 삭제합니다.

## 2. 테라폼 사용 가이드

### 폴더 구조
```
run-terraform/
├── main.tf              # 프로바이더 설정과 VPC 모듈 호출
├── variables.tf         # 루트 모듈 입력값 정의(리전, CIDR, 서브넷, 태그 등)
├── outputs.tf           # 하위 모듈에서 전달받은 VPC/서브넷 ID 출력
├── terraform.tf         # required_version, provider 버전 고정
└── modules/
    └── vpc/
        ├── main.tf      # VPC, IGW, Public/Private 서브넷, NAT, 라우팅 구성
        ├── variables.tf # 모듈 입력값 정의(name, CIDR, 서브넷 리스트 등)
        └── outputs.tf   # VPC 및 서브넷/NAT 식별자 출력
```

### 변수와 모듈 입력
- 루트 `variables.tf`에서 기본값을 제공하며, 실제 환경에서는 `terraform.tfvars` 또는 `*.auto.tfvars` 파일로 값을 재정의합니다.
- 주요 변수
  - `aws_region` : 배포 리전
  - `project_name` : 리소스 이름/태그 접두사
  - `vpc_cidr` : VPC CIDR
  - `public_subnets` / `private_subnets` : `{ cidr, az }` 객체 리스트
  - `nat_gateway_enabled` : NAT Gateway 생성 여부
  - `tags` : 공통 태그 맵

### 예시 tfvars
```hcl
aws_region   = "ap-northeast-2"
project_name = "dev-app"
vpc_cidr     = "10.10.0.0/16"

public_subnets = [
  { cidr = "10.10.1.0/24", az = "ap-northeast-2a" },
  { cidr = "10.10.2.0/24", az = "ap-northeast-2c" }
]

private_subnets = [
  { cidr = "10.10.11.0/24", az = "ap-northeast-2a" },
  { cidr = "10.10.12.0/24", az = "ap-northeast-2c" }
]

nat_gateway_enabled = true
tags = {
  Environment = "dev"
  Owner       = "yang"
}
```

### 실행 절차
1. 필요한 값을 담은 tfvars 파일을 준비합니다. (`env/dev.tfvars` 등)
2. `terraform init`
3. `terraform plan -var-file=env/dev.tfvars`
4. 변경 사항을 확인하고 `terraform apply -var-file=env/dev.tfvars`로 배포합니다.
5. 리소스를 정리할 때는 동일한 tfvars를 사용하여 `terraform destroy -var-file=env/dev.tfvars`를 실행합니다.

이 가이드를 기반으로 VPC 구성 후, 추후 EC2 모듈 등을 추가하여 `module.network.vpc_id`, `module.network.public_subnet_ids`, `module.network.private_subnet_ids` 출력값을 활용하면 됩니다.
