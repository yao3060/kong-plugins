# Kubernetes 安装指南

本指南介绍如何在 Kubernetes 环境中安装 `lua-jwt-headers-extract` Kong 插件。

## 前置要求

- Kubernetes 集群
- 已安装 Kong Ingress Controller
- `kubectl` 命令行工具
- 访问 Kubernetes 集群的权限

## 安装方式：ConfigMap + 挂载（推荐）

如果您已经克隆了仓库，可以使用本地文件安装：

这种方式无需重新构建镜像，通过 ConfigMap 将插件文件挂载到 Kong 容器中，适合快速部署和更新。

### 步骤 1: 创建 ConfigMap

**文件说明：**
- `handler.lua` 和 `schema.lua` 是插件的源代码文件
- `k8s/configmap.yaml` 是用于 Kubernetes 部署的配置文件，包含上述 Lua 文件的内容

如果源代码已更新，建议从源文件重新生成 ConfigMap：

```bash
# 使用脚本自动生成
./scripts/generate-configmap.sh kong

# 然后应用
kubectl apply -f k8s/configmap.yaml
```

如果 `k8s/configmap.yaml` 已存在且与源代码同步，直接使用：

```bash
kubectl apply -f k8s/configmap.yaml
```

验证 ConfigMap 已创建：

```bash
kubectl get configmap kong-plugin-lua-jwt-headers-extract -n kong
```

### 步骤 2: 更新 Kong Gateway 部署

使用 Helm 更新部署（推荐方式）：

```bash
helm upgrade kong kong/kong -f k8s/helm-values-patch.yaml -n kong
```

### 步骤 3: 等待 Pod 重启

部署更新后，Kong Gateway Pod 会自动重启以应用新的挂载配置：

```bash
# 查看 Pod 状态
kubectl get pods -n kong -w

# 等待所有 Pod 就绪
kubectl rollout status deployment/kong-gateway -n kong
```

### 步骤 4: 验证安装

1. 检查插件文件是否已挂载：

```bash
# 进入 Kong Pod
kubectl exec -it -n kong <kong-pod-name> -- /bin/sh

# 检查插件目录
ls -la /usr/local/share/lua/5.1/kong/plugins/lua-jwt-headers-extract/

# 应该能看到 handler.lua 和 schema.lua
cat /usr/local/share/lua/5.1/kong/plugins/lua-jwt-headers-extract/handler.lua
cat /usr/local/share/lua/5.1/kong/plugins/lua-jwt-headers-extract/schema.lua
```

2. 验证插件在 Kong 中可用：

```bash
# 在 Pod 内执行配置解析测试
kong config -c /etc/kong/kong.conf parse

# 或者通过 Admin API（如果已启用）
kubectl port-forward -n kong <kong-pod-name> 8001:8001
curl http://localhost:8001/plugins/enabled | grep lua-jwt-headers-extract
```

### 步骤 5: 配置和使用插件

插件安装后，需要创建 `KongPlugin` 资源来配置插件，然后在 Ingress 或 Service 中引用它。

#### 创建 KongPlugin 资源

首先创建 `KongPlugin` 资源来配置插件：

```yaml
apiVersion: configuration.konghq.com/v1
kind: KongPlugin
metadata:
  name: lua-jwt-headers-extract
  namespace: default  # 与您的 Ingress/Service 在同一 namespace
plugin: lua-jwt-headers-extract
config:
  header_prefix: "X-JWT-"
  sub_header_name: "Sub"
  roles_header_name: "Roles"
  permissions_header_name: "Permissions"
  scopes_header_name: "Scopes"
```

应用配置：

```bash
kubectl apply -f - <<EOF
apiVersion: configuration.konghq.com/v1
kind: KongPlugin
metadata:
  name: lua-jwt-headers-extract
  namespace: default
plugin: lua-jwt-headers-extract
config:
  header_prefix: "X-JWT-"
  sub_header_name: "Sub"
  roles_header_name: "Roles"
  permissions_header_name: "Permissions"
  scopes_header_name: "Scopes"
EOF
```

#### 在 Ingress 中启用插件

在 Ingress 的注解中引用上面创建的 `KongPlugin` 资源名称：

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-ingress
  namespace: default
  annotations:
    konghq.com/plugins: lua-jwt-headers-extract  # 引用 KongPlugin 资源的名称
spec:
  rules:
  - host: example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-service
            port:
              number: 80
```

**重要说明：**
- `konghq.com/plugins` 注解中使用 `KongPlugin` 资源的名称（`lua-jwt-headers-extract`）
- `KongPlugin` 资源必须与 Ingress/Service 在同一个 namespace 中
- 如果使用默认配置，可以省略 `config` 部分

## 配置选项

插件支持以下配置参数：

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `header_prefix` | string | `"X-JWT-"` | 请求头前缀 |
| `sub_header_name` | string | `"Sub"` | sub 字段的请求头名称 |
| `roles_header_name` | string | `"Roles"` | roles 字段的请求头名称 |
| `permissions_header_name` | string | `"Permissions"` | permissions 字段的请求头名称 |
| `scopes_header_name` | string | `"Scopes"` | scopes 字段的请求头名称 |

## 故障排查

### ConfigMap 未创建

```bash
# 检查 ConfigMap 是否存在
kubectl get configmap -n kong | grep lua-jwt-headers-extract

# 查看 ConfigMap 内容
kubectl get configmap kong-plugin-lua-jwt-headers-extract -n kong -o yaml
```

### 插件文件未挂载

1. 检查部署配置中的 volumeMounts：

```bash
kubectl get deployment kong-gateway -n kong -o yaml | grep -A 10 volumeMounts
```

2. 检查 Pod 中的挂载：

```bash
kubectl describe pod <kong-pod-name> -n kong | grep -A 5 Mounts
```

3. 验证挂载路径：

```bash
kubectl exec -it -n kong <kong-pod-name> -- ls -la /usr/local/share/lua/5.1/kong/plugins/lua-jwt-headers-extract/
```

### 插件未加载

1. 检查 Kong 日志：

```bash
kubectl logs -n kong <kong-pod-name> | grep -i plugin
kubectl logs -n kong <kong-pod-name> | grep -i error
```

2. 检查文件权限：

```bash
kubectl exec -it -n kong <kong-pod-name> -- ls -la /usr/local/share/lua/5.1/kong/plugins/lua-jwt-headers-extract/
```

文件权限应为 `-rw-r--r--` 或 `-rwxr-xr-x`。

### 插件配置错误

检查 KongPlugin 资源的配置语法：

```bash
kubectl get kongplugin lua-jwt-headers-extract -o yaml
```

## 升级插件

当插件更新时：

1. 重新生成并更新 ConfigMap：

```bash
# 从源文件重新生成 ConfigMap
./scripts/generate-configmap.sh kong

# 应用更新
kubectl apply -f k8s/configmap.yaml
```

2. 滚动重启 Kong Gateway Pod 以加载新配置：

```bash
kubectl rollout restart deployment/kong-gateway -n kong
kubectl rollout status deployment/kong-gateway -n kong
```

3. 验证新版本：

```bash
kubectl exec -it -n kong <kong-gateway-pod-name> -- cat /usr/local/share/lua/5.1/kong/plugins/lua-jwt-headers-extract/handler.lua | grep VERSION
```

## 相关资源

- [Kong Ingress Controller 文档](https://docs.konghq.com/kubernetes-ingress-controller/)
- [Kong 插件开发指南](https://docs.konghq.com/gateway/latest/plugin-development/)
- [Kubernetes ConfigMap 文档](https://kubernetes.io/docs/concepts/configuration/configmap/)
