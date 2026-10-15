B=http://localhost:8065/api/v4
TOK=$(curl -si -X POST $B/users/login -d '{"login_id":"admin","password":"Passw0rd1234!"}' | tr -d '\r' | awk -F': ' 'tolower($1)=="token"{print $2}')
CH=$(curl -s -H "Authorization: Bearer $TOK" $B/teams/name/t1/channels/name/town | jq -r .id)
curl -s -H "Authorization: Bearer $TOK" -X POST $B/posts -d "{\"channel_id\":\"$CH\",\"message\":\"seed post before upgrade\"}" | jq -r .id
echo "$CH" > /opt/mm/ch
