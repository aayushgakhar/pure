function _pure_prompt_git \
    --description 'Print git repository informations: branch name, dirty, upstream ahead/behind'

    set ABORT_FEATURE 2

    if set --query pure_enable_git; and test "$pure_enable_git" != true
        return
    end

    if not type -q --no-functions git  # skip git-related features when `git` is not available
        return $ABORT_FEATURE
    end

    set --local is_git_repository (command git rev-parse --is-inside-work-tree 2>/dev/null)

    if test -n "$is_git_repository"
        git rev-parse --git-dir --is-inside-git-dir | read -fL gdir in_gdir
        test $in_gdir = true && set -l _set_dir_opt -C $gdir/..
        # Suppress errors in case we are in a bare repo or there is no upstream
        set -l stat (git $_set_dir_opt --no-optional-locks status --porcelain 2>/dev/null)
        string match -qr '(0|(?<stash>.*))\n(0|(?<conflicted>.*))\n(0|(?<staged>.*))
    (0|(?<dirty>.*))\n(0|(?<untracked>.*))(\n(0|(?<behind>.*))\t(0|(?<ahead>.*)))?' \
            "$(git $_set_dir_opt stash list 2>/dev/null | count
            string match -r ^UU $stat | count
            string match -r ^[ADMR] $stat | count
            string match -r ^.[ADMR] $stat | count
            string match -r '^\?\?' $stat | count
            git rev-list --count --left-right @{upstream}...HEAD 2>/dev/null)"
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
        set --local git_prompt (_pure_prompt_git_branch)' '$operation' '$step/$total_steps(_pure_prompt_git_stash $stash)' ~'$conflicted' +'$staged' '(_pure_prompt_git_dirty $dirty)' ?'$untracked
        set --local git_pending_commits (_pure_prompt_git_pending_commits $ahead $behind)

        if test (_pure_string_width $git_pending_commits) -ne 0
            set --append git_prompt $git_pending_commits
        end

        echo $git_prompt
    end
end
