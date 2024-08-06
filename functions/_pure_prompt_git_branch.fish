function _pure_prompt_git_branch --argument-names location
    set -f git_branch (_pure_parse_git_branch) # current git branch
    if test $git_branch = undefined
        set -f git_branch '@'$location
    end
    set -f git_branch_color (_pure_set_color $pure_color_git_branch)

    echo "$git_branch_color$git_branch"
end
