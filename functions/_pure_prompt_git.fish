function _pure_prompt_git \
    --description 'Print git repository informations: branch name, dirty, upstream ahead/behind'

    set ABORT_FEATURE 2

    if set --query pure_enable_git; and test "$pure_enable_git" != true
        return
    end

    set -f git_enhanced false
    if set --query pure_enable_git_enhanced
        set -f git_enhanced $pure_enable_git_enhanced
    end

    if not type -q --no-functions git  # skip git-related features when `git` is not available
        return $ABORT_FEATURE
    end

    set --local is_git_repository (command git rev-parse --is-inside-work-tree 2>/dev/null)

    if test -n "$is_git_repository"
        git rev-parse --git-dir --is-inside-git-dir --short HEAD | read -fL gdir in_gdir location
        test $in_gdir = true && set -l _set_dir_opt -C $gdir/..
        # Suppress errors in case we are in a bare repo or there is no upstream
        git rev-list --count --left-right @{upstream}...HEAD 2>/dev/null | read -f behind ahead
        if test -d $gdir/rebase-merge
            # Turn ANY into ALL, via double negation
            if not path is -v $gdir/rebase-merge/{msgnum,end}
                read -f step <$gdir/rebase-merge/msgnum
                read -f total_steps <$gdir/rebase-merge/end
            end
            test -f $gdir/rebase-merge/interactive && set -f operation rebase-i || set -f operation rebase-m
        else if test -d $gdir/rebase-apply
            if not path is -v $gdir/rebase-apply/{next,last}
                read -f step <$gdir/rebase-apply/next
                read -f total_steps <$gdir/rebase-apply/last
            end
            if test -f $gdir/rebase-apply/rebasing
                set -f operation rebase
            else if test -f $gdir/rebase-apply/applying
                set -f operation am
            else
                set -f operation am/rebase
            end
        else if test -f $gdir/MERGE_HEAD
            set -f operation merge
        else if test -f $gdir/CHERRY_PICK_HEAD
            set -f operation cherry-pick
        else if test -f $gdir/REVERT_HEAD
            set -f operation revert
        else if test -f $gdir/BISECT_LOG
            set -f operation bisect
        end
        
        echo -ns (_pure_prompt_git_branch $location)

        set -f color_normal $pure_color_mute
        set -f git_color_operation brred
        set -f git_color_conflicted brred

        if set -q operation
            echo -ns (set_color $git_color_operation) ' ' $operation (set_color $color_normal)
        end
        if set -q step
            echo -ns (set_color $git_color_operation) ' ' $step/$total_steps (set_color $color_normal)
        end
        echo -ns (_pure_prompt_git_pending_commits $ahead $behind)

        if test $git_enhanced = true
            set -l stat (git $_set_dir_opt --no-optional-locks status --porcelain 2>/dev/null)
            set -l stash (git $_set_dir_opt stash list 2>/dev/null | count)
            set -l conflicted (string match -r ^UU $stat | count)
            set -l staged (string match -r ^[ADMR] $stat | count)
            set -l dirty (string match -r ^.[ADMR] $stat | count)
            set -l untracked (string match -r '^\?\?' $stat | count)
            if test $stash -ne 0
                echo -ns (_pure_prompt_git_stash $stash)
            end
            if test $conflicted -ne 0
                echo -ns (set_color $git_color_conflicted) ' ~'$conflicted (set_color $color_normal)
            end
            if test $staged -ne 0
                echo -ns ' +'$staged
            end
            if test $dirty -ne 0
                echo -ns ' '$pure_symbol_git_dirty$dirty
            end
            if test $untracked -ne 0
                echo -ns ' ?'$untracked
            end
        else
            echo -ns (_pure_prompt_git_dirty)
        end

    end
end
