B=http://localhost:8065/api/v4
for u in admin u1 u2; do
 R=$(curl -si -X POST $B/users/login -d "{\"login_id\":\"$u\",\"password\":\"Passw0rd1234!\"}" | tr -d '\r'); T=$(echo "$R"|awk -F': ' 'tolower($1)=="token"{print $2}'); ID=$(echo "$R"|tail -1|jq -r .id)
 curl -s -X PUT -H "Authorization: Bearer $T" $B/users/$ID/preferences -d "[{\"user_id\":\"$ID\",\"category\":\"recommended_next_steps\",\"name\":\"hide\",\"value\":\"true\"},{\"user_id\":\"$ID\",\"category\":\"recommended_next_steps\",\"name\":\"skip\",\"value\":\"true\"},{\"user_id\":\"$ID\",\"category\":\"onboarding_task_list\",\"name\":\"onboarding_task_list_show\",\"value\":\"false\"},{\"user_id\":\"$ID\",\"category\":\"onboarding_task_list\",\"name\":\"onboarding_task_list_open\",\"value\":\"false\"},{\"user_id\":\"$ID\",\"category\":\"tutorial_step\",\"name\":\"$ID\",\"value\":\"999\"}]" -o /dev/null -w "$u %{http_code}\n"
done
