function rename_modules -a suffix
  # ensure we're inside workspace
  test -d $$_ts_project_dir || exit 1

  # given no suffix, and there's no suffix currently,
  # use current git branch as suffix
  if test -z "$suffix" && string match -q -r 'module-libs$' -- (cat $$_ts_project_dir/modules/libs/serverless.yml)
    set -l branch (git branch --show-current)
    if test "$branch" != 'master'
      set suffix (string replace -a -r '\W+' '-' -- $branch)
    end
  end

  test -n "$suffix" && set suffix "-$suffix"

  sed -i '' -E 's/module-(libs|templates)([^$]*)(-\$.*)?$/module-\1'"$suffix"'\3/g' \
    $$_ts_project_dir/modules/libs/serverless.yml \
    $$_ts_project_dir/modules/templates/serverless.yml \
    $$_ts_project_dir/services/serverless-layers.yml \
    $$_ts_project_dir/admin/services/serverless-layers.yml
end
