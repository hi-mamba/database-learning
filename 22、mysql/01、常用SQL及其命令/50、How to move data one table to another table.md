
## [原文](https://stackoverflow.com/questions/26008598/how-to-move-data-one-table-to-another-table-older-than-30-days-record)

# How to move data one table to another table 

```java
INSERT INTO message_archives (user_id, friend_id, message, is_view, created)
SELECT user_id, user_id, message, 0, created
FROM messages 
WHERE created < DATE_SUB(curdate(), INTERVAL 30 DAY)

DELETE FROM messages 
WHERE created < DATE_SUB(curdate(), INTERVAL 30 DAY)
```