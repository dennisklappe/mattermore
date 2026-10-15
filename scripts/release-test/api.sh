B=http://localhost:8065/api/v4
ok(){ echo "PASS $1"; }; bad(){ echo "FAIL $1: $2"; }
login(){ curl -si -X POST $B/users/login -d "{\"login_id\":\"$1\",\"password\":\"Passw0rd1234!\"}" | tr -d '\r' | awk -F': ' 'tolower($1)=="token"{print $2}'; }
A=$(login admin); U1=$(login u1); [ -n "$A" ] && [ -n "$U1" ] && ok "login admin+u1 after upgrade" || bad login "$A $U1"
H="Authorization: Bearer $A"
CH=$(cat /opt/mm/ch)
curl -s -H "$H" "$B/channels/$CH/posts" | jq -r '.posts[].message' | grep -q "seed post before upgrade" && ok "pre-upgrade post survived" || bad post missing
P=$(curl -s -H "Authorization: Bearer $U1" -X POST $B/posts -d "{\"channel_id\":\"$CH\",\"message\":\"hello from u1\"}" | jq -r .id); [ ${#P} = 26 ] && ok "member posts" || bad post "$P"
curl -s -H "Authorization: Bearer $U1" -X POST $B/reactions -d "{\"user_id\":\"$(curl -s -H "Authorization: Bearer $U1" $B/users/me|jq -r .id)\",\"post_id\":\"$P\",\"emoji_name\":\"+1\"}" | jq -e .emoji_name >/dev/null && ok reaction || bad reaction
echo "file body" > /tmp/f.txt
curl -s -H "$H" -F "files=@/tmp/f.txt" -F "channel_id=$CH" $B/files | jq -e '.file_infos[0].id' >/dev/null && ok "file upload" || bad upload
# guests
curl -s -H "$H" -X POST $B/users -d '{"email":"g@example.com","username":"guest1","password":"Passw0rd1234!"}' | jq -r .id > /tmp/gid
curl -s -H "$H" -X POST $B/users/$(cat /tmp/gid)/demote | jq -r '.roles' | grep -q guest && ok "demote to guest account" || bad guest "$(curl -s -H "$H" -X POST $B/users/$(cat /tmp/gid)/demote)"
# config
CFG=$(curl -s -H "$H" $B/config)
echo "$CFG" | jq -r '.GuestAccountsSettings.Enable' | grep -q true && ok "guest accounts enabled" || echo "INFO guest accounts enable=$(echo "$CFG" | jq -r .GuestAccountsSettings.Enable)"
echo "INFO sitename=$(echo "$CFG" | jq -r .TeamSettings.SiteName) agents/ai plugin enable=$(echo "$CFG" | jq -r '.PluginSettings.PluginStates["mattermost-ai"].Enable // .PluginSettings.PluginStates["mattermost-agents"].Enable')"
curl -s -H "$H" $B/license/client?format=old | jq -c '{IsLicensed,SkuShortName}'
curl -s -H "$H" $B/plugins | jq -c '[.active[]|{id,version}]'
# calls
C=$(curl -s -H "$H" $B/plugins/com.mattermost.calls/config); echo "INFO calls config: $(echo "$C"|jq -c '{AllowEnableCalls,DefaultEnabled,GroupCallsAllowed,EnableRecordings,EnableTranscriptions,JobServiceURL}' 2>/dev/null)"
curl -s -H "$H" $B/plugins/com.mattermost.calls/version | head -c 200; echo
curl -s -H "$H" $B/plugins/com.mattermost.calls/channels/$CH | head -c 300; echo
curl -s -H "$H" $B/plugins/com.mattermost.calls/calls/$CH | head -c 200; echo
echo "INFO plugin settings:"; echo "$CFG" | jq -c '.PluginSettings.Plugins["com.mattermost.calls"]'
