local ucursor = require"luci.model.uci".cursor()
local json = require "luci.jsonc"
local server_section = arg[1]
local server = ucursor:get_all("v2ray_server", server_section)

local clients = {}

if server.VMess_id then
    for i = 1, #server.VMess_id do
        clients[i] = {
            id = server.VMess_id[i],
            level = tonumber(server.VMess_level),
            alterId = tonumber(server.VMess_alterId)
        }
    end
end

local v2ray = {
    log = {
        -- error = "/var/log/v2ray.log",
        loglevel = "warning"
    },
    -- 传入连接
    inbound = {
        port = tonumber(server.port),
        protocol = server.protocol,
        settings = {clients = clients},
        -- 底层传输配置
        streamSettings = {
            network = server.transport,
            security = (server.tls == '1') and "tls" or "none",
            kcpSettings = (server.transport == "mkcp") and {
                mtu = tonumber(server.mkcp_mtu),
                tti = tonumber(server.mkcp_tti),
                uplinkCapacity = tonumber(server.mkcp_uplinkCapacity),
                downlinkCapacity = tonumber(server.mkcp_downlinkCapacity),
                congestion = (server.mkcp_congestion == "1") and true or false,
                readBufferSize = tonumber(server.mkcp_readBufferSize),
                writeBufferSize = tonumber(server.mkcp_writeBufferSize),
                header = {type = server.mkcp_guise}
            } or nil,
            wsSettings = (server.transport == "ws") and {
                headers = (server.ws_host) and {Host = server.ws_host} or nil,
                path = server.ws_path
            } or nil,
            httpSettings = (server.transport == "h2") and
                {path = server.h2_path, host = server.h2_host} or nil,
            quicSettings = (server.transport == "quic") and {
                security = server.quic_security,
                key = server.quic_key,
                header = {type = server.quic_guise}
            } or nil
        },
        tlsSettings = (server.tlsSettingsEnable == '1') and {
            serverName = (server.tls_serverName),
            certificates = {
                {
                    certificateFile = server.tls_certificateFile,
                    keyFile = server.tls_keyFile
                }
            }
        } or nil
    },
    -- 传出连接
    outbound = {protocol = "freedom"},
    -- 额外传出连接
    outboundDetour = {{protocol = "blackhole", tag = "blocked"}}
}
print(json.stringify(v2ray, 1))
