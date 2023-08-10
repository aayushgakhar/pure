function _pure_prompt_k8s
    if $pure_enable_k8s
        set -l context (_pure_set_color $pure_color_k8s_context)(_pure_k8s_context)
        set -l namespace (_pure_set_color $pure_color_k8s_namespace)(_pure_k8s_namespace)
        echo "$pure_symbol_k8s_prefix $context/$namespace"
    end
end