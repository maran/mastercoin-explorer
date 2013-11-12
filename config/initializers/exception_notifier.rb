RailsMastercoin::Application.config.middleware.use ExceptionNotification::Rack,
  :email => {
  :email_prefix => "[Mastercion-explorer] ",
  :sender_address => %{"notifier" <notifier@mastercoin-explorer.com>},
  :exception_recipients => %w{youremail@gmail.com}
}
