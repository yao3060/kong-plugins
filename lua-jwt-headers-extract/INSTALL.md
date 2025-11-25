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
kubectl get deployment kong-kong -n kong -o yaml | grep -A 10 volumeMounts
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
kubectl rollout restart deployment/kong-kong -n kong
kubectl rollout status deployment/kong-kong -n kong
```

3. 验证新版本：

```bash
kubectl exec -it -n kong <kong-kong-pod-name> -- cat /usr/local/share/lua/5.1/kong/plugins/lua-jwt-headers-extract/handler.lua | grep VERSION
```

## 相关资源

- [Kong Ingress Controller 文档](https://docs.konghq.com/kubernetes-ingress-controller/)
- [Kong 插件开发指南](https://docs.konghq.com/gateway/latest/plugin-development/)
- [Kubernetes ConfigMap 文档](https://kubernetes.io/docs/concepts/configuration/configmap/)
