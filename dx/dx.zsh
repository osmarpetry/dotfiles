# dx - docs offline versionados pelo projeto. Carregado pelo ~/.zshrc.

# Aviso ao entrar num projeto. Nunca calcula no shell: le um cache de 16ms.
# Quando o cache esta velho, `dx doctor -q` recalcula em background e o aviso
# aparece na proxima vez - o prompt nunca espera.
typeset -g _DX_LAST=""
_dx_hint() {
  (( $+commands[dx] )) || return
  local out
  out=$(dx doctor -q 2>/dev/null)
  [[ "$out" == "$_DX_LAST" ]] && return
  _DX_LAST="$out"
  [[ -n "$out" ]] && print -P "%F{yellow}${out}%f"
}
autoload -Uz add-zsh-hook
add-zsh-hook chpwd _dx_hint
_dx_hint

# O refresh diario e do launchd. Isto so cobre a maquina ter dormido no horario.
if (( $+commands[dx] )) && [[ -z $(print -rn -- ~/.cache/dx/man-index.tsv(Nmh-48)) ]]; then
  ( dx refresh >/dev/null 2>&1 & ) 2>/dev/null
fi
