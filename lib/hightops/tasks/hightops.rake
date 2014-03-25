namespace :deploy do
  desc 'Start hightops'
  task :start_hightops do
    on roles fetch(:hightops_roles, :app) do
      within release_path do
        execute 'echo Starting Hightops'
        execute :bundle, :exec, :hightops, 'start', fetch(:hightops_workers).join(','), "--environment=#{fetch(:rails_env, 'production')} --pid_path=#{fetch(:hightops_pid)}"
      end
    end
  end

  desc 'Stop hightops'
  task :stop_hightops do
    on roles fetch(:hightops_role, :app) do
      if test("[ -f #{fetch(:hightops_pid)} ]") && test("kill -0 `cat #{fetch(:hightops_pid)}` > /dev/null 2>&1")
        within current_path do
          execute 'echo Stopping Hightops'
          execute :kill, "-TERM `cat #{fetch(:hightops_pid)}`"
        end
      else
        execute 'echo Hightops is not running'
      end
    end
  end

  after 'deploy:started', 'deploy:stop_hightops'
  after 'deploy:updated', 'deploy:start_hightops'
end
