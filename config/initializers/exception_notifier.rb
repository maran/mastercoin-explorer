RailsMastercoin::Application.config.middleware.use ExceptionNotification::Rack,
  :email => {
  :email_prefix => "[Mastercoin-explorer] ",
  :sender_address => %{"notifier" <notifier@mastercoin-explorer.com>},
  :exception_recipients => %w{maran.hidskes@gmail.com}
}
