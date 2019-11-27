## [原文](https://stackoverflow.com/questions/10177208/update-a-column-value-replacing-part-of-a-string)

# Update a column value, replacing part of a string

```mysql
UPDATE urls
SET url = REPLACE(url, 'domain1.com/images/', 'domain2.com/otherfolder/')
```