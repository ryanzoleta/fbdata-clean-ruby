# FB Data Uploader

Processes a facebook data archive and uploads all messages to a mysql database.

### Usage

```
ruby main.rb
```

### Data Model

Messages are uploaded to the following tables

#### Thread

- `id`
- `title`

#### Message

- `id`
- `name`
- `content`
- `timestamp`
- `thread_id`
