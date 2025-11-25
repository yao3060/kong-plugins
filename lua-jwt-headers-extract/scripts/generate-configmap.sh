#!/bin/bash

# 从源文件自动生成 ConfigMap YAML
# 使用方法: ./scripts/generate-configmap.sh [namespace]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
NAMESPACE="${1:-kong}"

echo "生成 ConfigMap YAML..."
echo "命名空间: ${NAMESPACE}"
echo ""

# 检查源文件是否存在
if [ ! -f "${PLUGIN_DIR}/handler.lua" ] || [ ! -f "${PLUGIN_DIR}/schema.lua" ]; then
    echo "错误: 未找到 handler.lua 或 schema.lua"
    exit 1
fi

# 生成 ConfigMap YAML
cat > "${PLUGIN_DIR}/k8s/configmap.yaml" <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: kong-plugin-lua-jwt-headers-extract
  namespace: ${NAMESPACE}
  labels:
    app: kong
data:
  handler.lua: |
$(sed 's/^/    /' "${PLUGIN_DIR}/handler.lua")
  schema.lua: |
$(sed 's/^/    /' "${PLUGIN_DIR}/schema.lua")
EOF

echo "✓ ConfigMap YAML 已生成: ${PLUGIN_DIR}/k8s/configmap.yaml"
echo ""
echo "应用 ConfigMap:"
echo "  kubectl apply -f ${PLUGIN_DIR}/k8s/configmap.yaml"

