#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
TFVARS_PATH="${ROOT_DIR}/env/dev.tfvars"
TFVARS_TEMPLATE="${ROOT_DIR}/env/dev.tfvars.example"
PLAN_FILE="${ROOT_DIR}/.terraform/last-plan.tfplan"
OUTPUT_DIR="${ROOT_DIR}/outputs"

main() {
  confirm_prerequisites
  ensure_dependencies

  while true; do
    show_menu
    read -rp "원하는 작업을 선택하세요: " choice
    case "${choice}" in
      1) setup_environment ;;
      2) prompt_tfvars_generation ;;
      3) ensure_tfvars && run_plan ;;
      4) ensure_tfvars && run_plan_and_apply ;;
      5) ensure_tfvars && run_destroy ;;
      6) ensure_tfvars && show_and_maybe_save_outputs ;;
      0) echo "종료합니다."; exit 0 ;;
      *) echo "알 수 없는 선택입니다." ;;
    esac
    echo ""
    read -rp "계속하려면 Enter를 누르세요..." _
  done
}

show_menu() {
  cat <<'MENU'
================ Terraform Helper ================
1) 환경 준비 (npm install + terraform init)
2) tfvars 생성/갱신
3) terraform plan
4) terraform apply (plan 확인 후 진행)
5) terraform destroy
6) 주요 출력 보기 및 저장
0) 종료
=================================================
MENU
}

confirm_prerequisites() {
  local questions=(
    "AWS 자격 증명(AWS_PROFILE 또는 환경변수)이 올바르게 구성되어 있습니까? (yes/no): "
    "Terraform 1.3+ 과 npm이 설치되어 있고 버전을 확인했습니까? (yes/no): "
    "이 구성이 생성할 리소스 비용과 권한에 대해 사전 승인을 받았습니까? (yes/no): "
  )

  for prompt in "${questions[@]}"; do
    read -rp "${prompt}" answer
    if [[ "${answer,,}" != "yes" ]]; then
      echo "필수 준비 사항이 완료되지 않았습니다. 스크립트를 종료합니다."
      exit 1
    fi
  done
}

ensure_dependencies() {
  local missing=0
  for cmd in terraform npm; do
    if ! command -v "${cmd}" >/dev/null 2>&1; then
      echo "필수 명령어 '${cmd}' 를 찾을 수 없습니다."
      missing=1
    fi
  done
  if [[ "${missing}" -eq 1 ]]; then
    exit 1
  fi
}

setup_environment() {
  echo "[1/2] npm install"
  if [[ -f "${ROOT_DIR}/package.json" ]]; then
    (cd "${ROOT_DIR}" && npm install)
  else
    echo "package.json 이 없어 npm install을 건너뜁니다."
  fi

  echo "[2/2] terraform init"
  terraform -chdir="${ROOT_DIR}" init -input=false
}

prompt_tfvars_generation() {
  echo "tfvars 생성 방법을 선택하세요."
  echo "1) 템플릿 복사 (env/dev.tfvars.example)"
  echo "2) Node 스크립트로 자동 생성"
  echo "0) 취소"
  read -rp "선택: " tchoice
  case "${tchoice}" in
    1) generate_tfvars_from_template ;;
    2) generate_tfvars_via_script ;;
    0) echo "취소했습니다." ;;
    *) echo "잘못된 선택입니다." ;;
  esac
}

generate_tfvars_from_template() {
  if [[ ! -f "${TFVARS_TEMPLATE}" ]]; then
    echo "템플릿 ${TFVARS_TEMPLATE} 가 없습니다."
    return
  fi
  mkdir -p "$(dirname "${TFVARS_PATH}")"
  cp "${TFVARS_TEMPLATE}" "${TFVARS_PATH}"
  echo "복사 완료: ${TFVARS_PATH}"
}

generate_tfvars_via_script() {
  if [[ ! -f "${ROOT_DIR}/package.json" ]]; then
    echo "package.json 이 없어 스크립트를 실행할 수 없습니다."
    return
  fi
  (cd "${ROOT_DIR}" && npm install && npm run generate:tfvars -- "${TFVARS_PATH}")
}

ensure_tfvars() {
  if [[ ! -f "${TFVARS_PATH}" ]]; then
    echo "tfvars 파일(${TFVARS_PATH})이 없습니다. 먼저 생성해주세요."
    prompt_tfvars_generation
    if [[ ! -f "${TFVARS_PATH}" ]]; then
      echo "tfvars가 아직 없습니다. 작업을 중단합니다."
      return 1
    fi
  fi
}

run_plan() {
  terraform -chdir="${ROOT_DIR}" plan -var-file="${TFVARS_PATH}"
}

run_plan_and_apply() {
  rm -f "${PLAN_FILE}"
  terraform -chdir="${ROOT_DIR}" plan -var-file="${TFVARS_PATH}" -out="${PLAN_FILE}"
  echo ""
  read -rp "지금 apply 할까요? (y/N): " answer
  case "${answer}" in
    [Yy]*)
      terraform -chdir="${ROOT_DIR}" apply "${PLAN_FILE}"
      ;;
    *)
      echo "apply 를 취소했습니다."
      ;;
  esac
  rm -f "${PLAN_FILE}"
}

run_destroy() {
  read -rp "정말 destroy 하시겠습니까? (type 'destroy'): " confirm
  if [[ "${confirm}" != "destroy" ]]; then
    echo "destroy 를 취소했습니다."
    return
  fi
  terraform -chdir="${ROOT_DIR}" destroy -var-file="${TFVARS_PATH}"
}

show_and_maybe_save_outputs() {
  if ! terraform -chdir="${ROOT_DIR}" output >/dev/null 2>&1; then
    echo "출력을 가져오는 데 실패했습니다. 먼저 apply 했는지 확인하세요."
    return
  fi

  local output_text
  output_text="$(terraform -chdir="${ROOT_DIR}" output)"
  echo "----- Terraform Outputs -----"
  echo "${output_text}"
  echo "-----------------------------"

  read -rp "파일로 저장할까요? (y/N): " save_answer
  case "${save_answer}" in
    [Yy]*)
      save_outputs_to_file "${output_text}"
      ;;
    *)
      echo "저장을 건너뜁니다."
      ;;
  esac
}

save_outputs_to_file() {
  local output_text="$1"
  mkdir -p "${OUTPUT_DIR}"
  local timestamp
  timestamp="$(date +"%Y%m%d-%H%M%S")"
  local default_path="${OUTPUT_DIR}/summary-${timestamp}.txt"
  read -rp "저장 경로를 입력하세요 [${default_path}]: " custom_path
  local target="${custom_path:-$default_path}"

  local bastion_ip private_ip alb_dns key_path
  bastion_ip="$(safe_tf_output "bastion_public_ip")"
  private_ip="$(safe_tf_output "private_instance_private_ip")"
  alb_dns="$(safe_tf_output "alb_dns_name")"
  key_path="$(extract_tfvar_value "ssh_private_key_path")"

  cat >"${target}" <<EOF
Terraform Outputs (generated $(date))
====================================
${output_text}

접속 명령어
-----------
배스천 접속:
ssh -i ${key_path:-<ssh_key_path>} ubuntu@${bastion_ip:-<bastion_ip>}

프라이빗 서버 (배스천 경유):
ssh -i ${key_path:-<ssh_key_path>} \\
    -o ProxyCommand="ssh -i ${key_path:-<ssh_key_path>} ubuntu@${bastion_ip:-<bastion_ip>} -W %h:%p" \\
    ubuntu@${private_ip:-<private_ip>}

ALB 주소: ${alb_dns:-<alb_dns_name>}
EOF

  echo "저장 완료: ${target}"
}

safe_tf_output() {
  local name="$1"
  if terraform -chdir="${ROOT_DIR}" output -raw "${name}" >/dev/null 2>&1; then
    terraform -chdir="${ROOT_DIR}" output -raw "${name}"
  else
    echo ""
  fi
}

extract_tfvar_value() {
  local key="$1"
  if [[ ! -f "${TFVARS_PATH}" ]]; then
    echo ""
    return
  fi
  awk -F'=' -v name="${key}" '
    $1 ~ /^[[:space:]]*name[[:space:]]*$/ {
      val=$2
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", val)
      gsub(/^"/, "", val); gsub(/"$/, "", val)
      print val
      exit
    }
  ' "${TFVARS_PATH}" || true
}

main "$@"
