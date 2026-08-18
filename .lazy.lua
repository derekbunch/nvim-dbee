return {
  {
    "kndndrj/nvim-dbee",
    dir = "/Users/derekbunch/personal/nvim-dbee",
    dependencies = {
      "MunifTanjim/nui.nvim",
    },
    build = function()
      require("dbee").install("go")
    end,
    opts = function()
      local dbee_sources = require("dbee.sources")
      local dbee_layouts = require("dbee.layouts")

      return {
        window_layout = dbee_layouts.Default:new {
          drawer_width = 60,
          call_log_height = 3,
        },
        sources = {
          dbee_sources.MemorySource:new({
            {
              id = "snowflake_key_pair",
              name = "Snowflake Key Pair",
              type = "snowflake",
              url = table.concat({
                [[DEREK.BUNCH%40RECHARGEAPPS.COM]], -- username
                [[@fh34327.us-east-1.snowflakecomputing.com:443]], -- host and port
                [[?]], -- query params
                [[warehouse=DBUNCH_WH]], -- warehouse
                [[&role=DBUNCH_ROLE]], -- role
                -- key pair
                [[&privateKeyPath=~/.ssh/snowflake_rsa.pem]], -- private key path
                -- oauth
                -- [[&authenticator=oauth_authorization_code]], -- authenticator
                -- [[&oauthClientId=Vz0c67VFJUvcGSzfTv3urSF6mHY%3D]], -- client id
                -- [[&oauthClientSecret=CHH51R%2FLVEb6uJlecYFtl5CuNzf1YeDN%2BB2j9QgwfSo%3D]], -- client secret
                -- [[&oauthTokenRequestUrl=https%3A%2F%2Ffh34327.us-east-1.snowflakecomputing.com%2Foauth%2Ftoken-request]], -- token url
                -- [[&oauthScope=session%3Arole%3ADBUNCH_ROLE]], -- scope
                -- [[&oauthAuthorizationUrl=https%3A%2F%2Ffh34327.us-east-1.snowflakecomputing.com%2Foauth%2Fauthorize]], -- authorization url
                -- [[&oauthRedirectUri=http%3A%2F%2Flocalhost%3A8080]], -- redirect uri
              }, ""),
            },
          }, "snowflake"),
        },
      }
    end,
  },
}
