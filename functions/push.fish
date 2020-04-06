function sls_deploy --description "deploy CF stack/lambda function"
  if count $argv > /dev/null
    for name in $argv
      switch $name
        case libs
          build_libs
          __sls_deploy_module $name
        case templates
          __sls_deploy_module $name
        case \*
          __sls_deploy_function $name
      end
    end
  else
    __sls_deploy
  end
end

function __sls_deploy_module --argument-names module_name --description "deploy single module"
  echo (set_color --background green)(set_color black)deploying module $module_name(set_color normal)

  set --local current_dir (pwd)
  set --local project_dir (git rev-parse --show-toplevel)

  function on_ctrl_c --on-job-exit %self --inherit-variable current_dir
    functions --erase on_ctrl_c
    cd "$current_dir"
  end

  cd "$project_dir/modules/$module_name"
  __sls_deploy
  cd "$current_dir"

  functions --erase on_ctrl_c
end

function __sls_deploy_function --argument-names function_name --description "deploy single function in current stack"
  echo (set_color --background green)(set_color black)deploying function $function_name(set_color normal)
  __sls_deploy --function $function_name
end

function __sls_deploy --description "wrap around sls deploy command"
  set --local  command "sls deploy --stage $AWS_PROFILE $argv --verbose"

  echo (set_color blue)(pwd)(set_color normal)
  echo (set_color green)$command(set_color normal)

  set --local --export SLS_DEBUG \*
  eval $command

  if test $status -eq 0
    __notify "🎉 𝚜𝚞𝚌𝚌𝚎𝚜𝚜" "$command" tink
  else
    __notify "🤡 𝚏𝚊𝚒𝚕𝚎𝚍" "$command" basso
  end
end

function __notify --argument-names title message sound --description "send notification to system"
  osascript -e "display notification \"$message\" with title \"$title\"" &
  afplay "/System/Library/Sounds/$sound.aiff" &
end

alias push=sls_deploy
