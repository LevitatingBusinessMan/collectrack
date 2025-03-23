activate_control_app "unix://#{ENV["XDG_RUNTIME_DIR"]}/collectrack_puma.sock", { no_token: true }
port 3344, "localhost"
