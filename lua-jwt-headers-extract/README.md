# lua-jwt-headers-extract (Kong Lua plugin)

This plugin extracts `sub`, `roles`, `permissions`, and `scopes` from a JWT (from Authorization header) and injects them into upstream request headers.

Supported JWT fields: `sub`, `roles`, `permissions`, `scopes`.

## 文件结构

- `handler.lua` - 插件的主要逻辑实现（源代码）
- `schema.lua` - 插件的配置模式定义（源代码）
- `k8s/configmap.yaml` - Kubernetes ConfigMap 配置文件，包含上述 Lua 文件的内容
- `k8s/helm-values-patch.yaml` - Helm values 补丁配置（推荐使用）
- `k8s/install-kong-plugin.yaml` - KongPlugin 资源配置文件，用于在 Ingress/Service 中启用插件
- `scripts/generate-configmap.sh` - 从源文件自动生成 ConfigMap 的脚本

**注意：** 如果修改了 `handler.lua` 或 `schema.lua`，建议运行 `./scripts/generate-configmap.sh` 重新生成 `k8s/configmap.yaml`，确保两者同步。

## 安装

### Kubernetes 环境（推荐：ConfigMap 方式）

在 Kubernetes 环境中安装此插件，推荐使用 ConfigMap + 挂载方式，无需重新构建镜像。

快速开始：

1. 创建 ConfigMap：
```bash
kubectl apply -f k8s/configmap.yaml
```

2. 更新 Kong Gateway 部署：
```bash
helm upgrade kong kong/kong -f k8s/helm-values-patch.yaml -n kong
```

3. 创建 KongPlugin 资源（在需要使用插件的 namespace 中）：
```bash
# 修改 namespace（如果需要）
sed 's/namespace: default/namespace: your-namespace/' k8s/install-kong-plugin.yaml | kubectl apply -f -

# 或直接使用（如果使用 default namespace）
kubectl apply -f k8s/install-kong-plugin.yaml
```

4. 在 Ingress 中启用插件：
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-ingress
  annotations:
    konghq.com/plugins: lua-jwt-headers-extract
spec:
  # ...
```

详细安装说明、配置选项和故障排查请查看 [INSTALL.md](./INSTALL.md)。

### 其他环境

对于非 Kubernetes 环境，将插件文件复制到 Kong 的插件目录：

```bash
cp -r lua-jwt-headers-extract /usr/local/share/lua/5.1/kong/plugins/
```

然后重启 Kong 服务。
