class MarkCartAsAbandonedJob
  include Sidekiq::Job

  def perform(*args)
    # TODO Impletemente um Job para gerenciar, marcar como abandonado. E remover carrinhos sem interação. 
  end
end
