function rename_modules
    # ensure we're inside workspace
    test -d $$_ts_project_dir || exit 1

    argparse -i f/force -- $argv

    set -l action $argv[1]
    set -l suffix

    switch "$action"
        case off
            set suffix
        case on
            set suffix (_ts_module_get_suffix)
        case toggle
            # if any module already has suffix
            if _ts_modules_have_suffix
                # toggle off suffix
                set suffix
            else
                set suffix (_ts_module_get_suffix)
            end
        case \*
            set suffix (_ts_module_get_suffix $action)
    end

    # rename modules
    test -n "$suffix" && set suffix "-$suffix"

    if test -z "$suffix"
        # clean all suffix
        sed -i '' -E 's/module-([a-z]+)([^$]*)(-\$.*)?$/module-\1\3/g' \
            $$_ts_project_dir/modules/*/serverless.yml \
            $$_ts_project_dir/services/serverless-layers.yml \
            $$_ts_project_dir/admin/services/serverless-layers.yml
    else if set -q _flag_force
        # add suffix to all modules
        sed -i '' -E 's/module-([a-z]+)([^$]*)(-\$.*)?$/module-\1'"$suffix"'\3/g' \
            $$_ts_project_dir/modules/*/serverless.yml \
            $$_ts_project_dir/services/serverless-layers.yml \
            $$_ts_project_dir/admin/services/serverless-layers.yml
    else
        # add suffix to changed modules

        set -l changed_modules
        set -l services_dirs
        set -l merge_base (git merge-base origin/master HEAD)

        # find changed modules
        git diff --name-only $merge_base -- $$_ts_project_dir/{modules,services,admin/services,lib,schema}/ | while read -l -L file
            switch $file
                case \*/package-lock.json
                    # ignore it
                case lib/\* schema/\*
                    contains libs $changed_modules || set -a changed_modules libs
                case modules/\*
                    string match -q -r '^modules/(?<module_name>[^/]+)' $file
                    contains $module_name $changed_modules || set -a changed_modules $module_name
                case services/\* admin/services/\*
                    string match -q -r '(?<services_dir>.*\bservices\b)' $file
                    contains $services_dir $services_dirs || set -a services_dirs $services_dir
            end
        end

        if test -n "$changed_modules"
            sed -i '' -E 's/module-([a-z]+)([^$]*)(-\$.*)?$/module-\1'"$suffix"'\3/g' $$_ts_project_dir/modules/$changed_modules/serverless.yml
            if test -n "$services_dirs"
                sed -i '' -E 's/module-('(string join '|' $changed_modules)')([^$]*)(-\$.*)?$/module-\1'"$suffix"'\3/g' $$_ts_project_dir/$services_dirs/serverless-layers.yml
            end
        end
    end
end

function _ts_modules_have_suffix -d 'check if any module already has suffix'
    for dir in $$_ts_project_dir/modules/*/
        string match -q -r '^service:\s*(?<service_name>[^\s]+)' <$dir/serverless.yml
        if test "$service_name" != "module-$dir"
            return 0
        end
    end
    return 1
end

function _ts_module_get_suffix -a name -d 'get module name suffix'
    if test -z "$name"
        set -l branch (git branch --show-current)
        if test "$branch" != master
            set name $branch
        end
    end
    string replace -a -r '\W+' - -- $name
end
