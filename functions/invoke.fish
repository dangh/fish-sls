function invoke -d "invoke lambda function"
    set -l startTime (date -u "+%Y%m%dT%H%M%S")
    set -l function
    set -l aws_profile $AWS_PROFILE
    set -l stage (string lower -- (string replace -r '.*@' '' -- $AWS_PROFILE))
    set -l region $AWS_DEFAULT_REGION

    argparse -n 'sls invoke' \
        'aws-profile=' \
        'f/function=' \
        's/stage=' \
        'r/region=' \
        'q/qualifier=' \
        'p/path=' \
        't/type=' \
        l/log \
        'd/data=' \
        raw \
        'context=' \
        'contextPath=' \
        'app=' \
        'org=' \
        'c/config=' \
        -- $ts_default_argv_invoke $argv
    or return 1

    if test "$stage" = prod
        while true
            read -l -P 'Do you want to continue invoking function on PROD? [y/N] ' confirm
            switch $confirm
                case Y y
                    break
                case '' N n
                    return
            end
        end
    end

    # function is the first positional argument
    set -q argv[1] && set function $argv[1]

    set -q _flag_function && set function $_flag_function
    set -q _flag_aws_profile && set aws_profile $_flag_aws_profile
    set -q _flag_stage && set stage $_flag_stage
    set -q _flag_region && set region $_flag_region
    set -q _flag_startTime && set startTime $_flag_startTime

    if test -z "$function"
        _ts_log function is required
        return 1
    end

    if string match -q -- '-*' "$function"
        _ts_log invalid function: (red $function)
        return 1
    end

    set -l invoke_cmd sls invoke
    test -n "$function" && set -a invoke_cmd -f $function
    test -n "$aws_profile" && set -a invoke_cmd --aws-profile $aws_profile
    test -n "$stage" && set -a invoke_cmd -s $stage
    test -n "$region" && set -a invoke_cmd -r $region
    test -n "$_flag_type" && set -a invoke_cmd -t $_flag_type
    test -n "$_flag_qualifier" && set -a invoke_cmd -q $_flag_qualifier
    test -n "$_flag_path" && set -a invoke_cmd -p $_flag_path
    set -q _flag_log && set -a invoke_cmd --log
    test -n "$_flag_data" && begin
        set -l data_path (mktemp -t sls-invoke-data-)
        echo $_flag_data >$data_path
        set -a invoke_cmd -p $data_path
    end
    set -q _flag_raw && set -a invoke_cmd --raw
    test -n "$_flag_context" && set -a invoke_cmd --context $_flag_context
    test -n "$_flag_contextPath" && set -a invoke_cmd --contextPath $_flag_contextPath
    test -n "$_flag_app" && set -a invoke_cmd --app $_flag_app
    test -n "$_flag_org" && set -a invoke_cmd --org $_flag_org
    test -n "$_flag_config" && set -a invoke_cmd -c $_flag_config

    set -l awk_cmd LC_CTYPE=C awk -f $__fish_config_dir/functions/logs.awk

    test function = (type -t ts_styles) && ts_styles

    _ts_log execute command: (green (string join ' ' -- (_ts_env --mode=env) $invoke_cmd \| $awk_cmd))
    eval (_ts_env --mode=env) command $invoke_cmd \| $awk_cmd
end
