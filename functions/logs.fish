function logs --description "watch lambda function logs"
  set --local function
  set --local profile $AWS_PROFILE
  set --local stage (string lower -- (string replace --regex '.*@' '' -- $AWS_PROFILE))
  set --local region $AWS_DEFAULT_REGION
  set --local startTime 2m

  argparse --name='sls logs' (_ts_opt \
    'f/function=?' \
    'profile=?' \
    's/stage=?' \
    'r/region=?' \
    't/tail' \
    'startTime=?' \
    'filter=?' \
    'i/interval=?' \
    'app=?' \
    'org=?' \
    'c/config=?' \
  ) -- $ts_default_argv_logs $argv
  or return 1

  # function as the the first positional argument
  set --query argv[1] && set function $argv[1]

  set --query _flag_function && set function $_flag_function
  set --query _flag_profile && set profile $_flag_profile
  set --query _flag_stage && set stage $_flag_stage
  set --query _flag_region && set region $_flag_region
  set --query _flag_type && set type $_flag_type
  set --query _flag_startTime && set startTime $_flag_startTime

  if test -z "$function"
    _ts_log function is required
    return 1
  end

  if string match --quiet -- '-*' "$function"
    _ts_log invalid function: (set_color red)$function(set_color normal)
    return 1
  end

  set --local cmd sls logs
  test -n "$function" && set --append cmd --function=(string escape "$function")
  test -n "$profile" && set --append cmd --profile=(string escape "$profile")
  test -n "$stage" && set --append cmd --stage=(string escape "$stage")
  test -n "$region" && set --append cmd --region=(string escape "$region")
  set --query _flag_tail && set --append cmd --tail
  test -n "$startTime" && set --append cmd --startTime=(string escape "$startTime")
  test -n "$_flag_filter" && set --append cmd --filter=(string escape "$_flag_filter")
  test -n "$_flag_interval" && set --append cmd --interval=(string escape "$_flag_interval")
  test -n "$_flag_app" && set --append cmd --app=(string escape "$_flag_app")
  test -n "$_flag_org" && set --append cmd --org=(string escape "$_flag_org")
  test -n "$_flag_config" && set --append cmd --config=(string escape "$_flag_config")

  echo (set_color green)$cmd(set_color normal)
  test "$TERM_PROGRAM" = iTerm.app && functions --query iterm2_prompt_mark && set --local sls_request_mark (iterm2_prompt_mark)
  command $cmd | awk -v REQUEST_MARK="$sls_request_mark" -f (dirname (status --current-filename))/logs.awk
end
