function update_aws_credentials
  pbpaste | read -z creds
  _ts_aws_creds $creds
end
