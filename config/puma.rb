environment = ENV["APP_ENV"] || ENV["RACK_ENV"] || ENV["RAILS_ENV"]
if environment == "development"
  activate_control_app "unix://#{ENV["XDG_RUNTIME_DIR"]}/collectrack_puma.sock", { no_token: true }
end
