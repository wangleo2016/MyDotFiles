function proxy_on
    set -gx http_proxy http://127.0.0.1:7897
    set -gx https_proxy http://127.0.0.1:7897
    set -gx all_proxy socks5://127.0.0.1:7897
    set -gx HTTP_PROXY http://127.0.0.1:7897
    set -gx HTTPS_PROXY http://127.0.0.1:7897
    set -gx ALL_PROXY socks5://127.0.0.1:7897
    echo "Proxy ON -> Clash 127.0.0.1:7897"
end
