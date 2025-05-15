if !Rails.env.test?
  schedule_file = Rails.root.join('config/sidekiq.yml')
  schedule = YAML.load_file(schedule_file)[:scheduler][:schedule]
  Sidekiq.schedule = schedule
end
