function bgutil
    set -l server_dir /Users/leo/Documents/Youtube/bgutil-ytdlp-pot-provider/server
    set -l log_file "/tmp/bgutil-provider.log"

    switch "$argv[1]"
        case on
            # 检查 4416 是否已经被监听
            set -l pid (lsof -tiTCP:4416 -sTCP:LISTEN)

            if test -n "$pid"
                echo "bgutil server is already running (PID $pid)"
                return 0
            end

            echo "Starting bgutil server..."

            cd "$server_dir/node_modules"; or return 1

            deno run \
                --allow-env \
                --allow-net \
                --allow-ffi=. \
                --allow-read=. \
                ../src/main.ts >$log_file 2>&1 &

            sleep 1

            set pid (lsof -tiTCP:4416 -sTCP:LISTEN)

            if test -n "$pid"
                echo "bgutil server started (PID $pid)"
                echo "Log: $log_file"
            else
                echo "Failed to start bgutil server"
                echo "Check: $log_file"
                return 1
            end

        case off
            set -l pid (lsof -tiTCP:4416 -sTCP:LISTEN)

            if test -z "$pid"
                echo "bgutil server is not running"
                return 0
            end

            echo "Stopping bgutil server (PID $pid)..."

            kill $pid
            sleep 1

            # 确认端口真的释放
            set pid (lsof -tiTCP:4416 -sTCP:LISTEN)

            if test -z "$pid"
                echo "bgutil server stopped"
            else
                echo "Server still running (PID $pid)"
                echo "Force stopping..."
                kill -9 $pid
            end

        case status
            set -l pid (lsof -tiTCP:4416 -sTCP:LISTEN)

            if test -n "$pid"
                echo "bgutil server is running (PID $pid)"
            else
                echo "bgutil server is stopped"
            end

        case '*'
            echo "Usage:"
            echo "  bgutil on"
            echo "  bgutil off"
            echo "  bgutil status"
    end
end
