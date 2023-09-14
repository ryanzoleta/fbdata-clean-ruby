# frozen_string_literal: true

require 'pathname'
require 'json'
require 'mysql'
require 'dotenv/load'

all_messages = []
all_threads = []

pathlist = Pathname.new('./').glob('**/*.json')

pathlist.each do |path|
  path_str = path.to_path

  next unless path_str.start_with?('messages_1/inbox') || path_str.start_with?('messages_2/inbox')

  next unless path.split[-1].to_path.start_with?('message_')

  thread_id = path.split[0].to_path.split('/')[-1].split('_')[0]

  data = JSON.parse(File.read(path_str))

  title = data['title']

  data['messages'].each do |message|
    next unless message.keys.include?('content')

    name = message['sender_name']
    content = message['content']
    timestamp = message['timestamp_ms']

    all_messages.push({
                        'name' => name,
                        'content' => content,
                        'timestamp' => timestamp,
                        'thread_id' => thread_id
                      })
  end

  next if all_threads.map { |t| t['id'] }.include?(thread_id)

  all_threads.push({
                     'id' => thread_id,
                     'title' => title
                   })
end

puts 'Connecting to DB...'
conn = Mysql.connect(ENV['MYSQL_URL'])

puts 'Clearing tables...'
delete_statement = conn.prepare('delete from thread where 1=1')
delete_statement.execute

delete_statement = conn.prepare('delete from message where 1=1')
delete_statement.execute

puts 'Inserting threads...'

all_threads.each do |thread|
  insert_stmt = conn.prepare('INSERT INTO thread (id, title) VALUES (?, ?)')
  insert_stmt.execute(thread['id'], thread['title'])
end
puts 'Inserting messages...'

all_messages.each do |message|
  datetime = DateTime.parse(Time.at(message['timestamp'].to_i / 1000).to_s)

  insert_stmt = conn.prepare('INSERT INTO message (name, content, timestamp, threadId) VALUES (?, ?, ?, ?)')
  insert_stmt.execute(message['name'], message['content'], datetime, message['thread_id'])
end
