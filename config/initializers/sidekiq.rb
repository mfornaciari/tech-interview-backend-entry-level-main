if defined?(Sidekiq::Scheduler) && !Rails.env.test?
  Sidekiq.configure_client do |config|
    schedule_file = Rails.root.join('config/sidekiq.yml')
    schedule = YAML.load_file(schedule_file).dig(':scheduler', ':schedule')
    Sidekiq.schedule = schedule
  end
end
