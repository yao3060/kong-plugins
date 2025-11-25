# lua-jwt-headers-extract (Kong Lua plugin)

This plugin extracts `sub`, `roles`, `permissions`, and `scopes` from a JWT (from Authorization header) and injects them into upstream request headers.

Supported JWT fields: `sub`, `roles`, `permissions`, `scopes`.
