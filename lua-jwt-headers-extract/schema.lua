return {
    name = "lua-jwt-headers-extract",
    fields = {
        {
            config = {
                type = "record",
                fields = {
                    {header_prefix = {type = "string", default = "X-JWT-"}},
                    {sub_header_name = {type = "string", default = "Sub"}},
                    {roles_header_name = {type = "string", default = "Roles"}},
                    {permissions_header_name = {type = "string", default = "Permissions"}},
                    {scopes_header_name = {type = "string", default = "Scopes"}}
                }
            }
        }
    }
}
