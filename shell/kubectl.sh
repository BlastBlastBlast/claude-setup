# kubectl shell integration — source from your ~/.zshrc:
#     source /path/to/claude-setup/shell/kubectl.sh
# Requires: kubectl, jq. Provides `kc` (switch context, tab-completable),
# `kcns` (switch namespace on the current context), and `k` (kubectl alias).

# ── kc — switch kube context, or list contexts when called bare ──────────────
kc() {
    local context="$1"
    if [[ -z "$context" ]]; then
        kubectl config get-contexts
    else
        kubectl config use-context "$@"
    fi
}

# Tab-complete kc with available context names (zsh).
if [[ -n "$ZSH_VERSION" ]]; then
    _kc_complete() {
        local -a contexts
        contexts=(${(f)"$(kubectl config get-contexts -o name 2>/dev/null | sort)"})
        compadd -a contexts
    }
    compdef _kc_complete kc
fi

# ── kcns — switch namespace by deriving a new context from the current one ───
kcns() {
    local ns="$1"
    shift
    local context="$(kubectl config current-context)"
    local context_json="$(kubectl config view -o json | jq --arg context "$context" '.contexts[]|select(.name==$context)')"
    local cluster="$(echo "$context_json" | jq -r .context.cluster)"
    local user="$(echo "$context_json" | jq -r .context.user)"
    local current_ns="$(echo "$context_json" | jq -r '.context.namespace // "default"')"
    local new_context
    if [[ "$context" == *"$current_ns"* ]]; then
        new_context="${context/$current_ns/$ns}"
    else
        new_context="${context}/${ns}"
    fi
    kubectl config set-context "$new_context" --cluster="$cluster" --user="$user" --namespace="$ns"
}

# ── Alias ─────────────────────────────────────────────────────────────────────
alias k=kubectl
