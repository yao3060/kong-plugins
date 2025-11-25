# kong-plugins

Read More (https://developer.konghq.com/kubernetes-ingress-controller/custom-plugins/)

## Lua JWT Headers Extract

**1. Create a ConfigMap**

```bash
kubectl create configmap kong-plugin-lua-jwt-headers-extract --from-file=lua-jwt-headers-extract -n kong
```

**2. Deploy your custom plugin**

Upgrade Kong Ingress Controller with the new values.

```bash
helm upgrade --install kong kong/ingress -n kong --create-namespace --values lua-jwt-headers-extract/k8s/helm-values.yaml --reuse-values
```
> --reuse-values: reuse history values

**3. Using custom plugins**

```bash
kubectl apply -f lua-jwt-headers-extract/k8s/install-kong-plugin.yaml
```